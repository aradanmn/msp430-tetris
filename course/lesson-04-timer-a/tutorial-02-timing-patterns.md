# Tutorial 02 — Timing Patterns

## The Tick-Counter Pattern

A single Timer_A period is rarely the right interval for everything in your
program. LED1 might need to toggle every 500 ms, LED2 every 125 ms, and a
score display might update every 1 second. You don't need three timers — you
need one fine-grained tick and a counter for each rate.

**The idea:** choose a tick period that divides evenly into all your target
intervals. Count ticks. When the count reaches the target, do the action and
reload the counter.

Example with a 10 ms tick:

| Target interval | Ticks needed | Register use |
|----------------|--------------|--------------|
| 100 ms | 10 | R6 counts 10 ticks |
| 250 ms | 25 | R7 counts 25 ticks |
| 500 ms | 50 | R8 counts 50 ticks |
| 1000 ms | 100 | R9 counts 100 ticks |

---

## Writing the Main Loop

The structure is always the same:

```
1. Wait for TAIFG (one tick has elapsed)
2. Clear TAIFG
3. For each channel: decrement its counter; if zero, fire and reload
4. Go to 1
```

In assembly:

```asm
; --- Initialization ---
mov.w   #9999, &TACCR0                  ; 10 ms tick
mov.w   #(TASSEL_2|MC_1|TACLR), &TACTL

mov.w   #LED1_TICKS, R6                 ; load tick counters
mov.w   #LED2_TICKS, R7

; --- Main loop ---
main_loop:
    ; Wait for next tick
    bit.w   #TAIFG, &TACTL
    jz      main_loop
    bic.w   #TAIFG, &TACTL

    ; --- LED1 channel ---
    dec.w   R6
    jnz     .Lled1_skip
    xor.b   #LED1, &P1OUT               ; action
    mov.w   #LED1_TICKS, R6             ; reload
.Lled1_skip:

    ; --- LED2 channel ---
    dec.w   R7
    jnz     .Lled2_skip
    xor.b   #LED2, &P1OUT               ; action
    mov.w   #LED2_TICKS, R7             ; reload
.Lled2_skip:

    jmp     main_loop
```

This loop runs exactly once per 10 ms tick. Both channels run independently —
changing `LED1_TICKS` or `LED2_TICKS` only affects that channel.

---

## Choosing a Tick Period

The tick period should be the **GCD** (greatest common divisor) of all the
intervals you need, or at least a value that divides evenly into all of them.

Example: you need 125 ms and 500 ms.
- GCD(125, 500) = 125 ms → TACCR0 = 124999 (too large for 16-bit: max 65535)
- Try 25 ms: 125/25 = 5, 500/25 = 20 → TACCR0 = 24999 ✓
- Try 5 ms: 125/5 = 25, 500/5 = 100 → TACCR0 = 4999 ✓ (finer, more flexibility)

Finer ticks give more flexibility but mean the loop runs more often. For this
course, **5 ms or 10 ms is a good default**. At 1 MHz with no other work in
the loop, the polling overhead is negligible.

---

## Timer-Based Button Edge Detection

In Lesson 03 you used a blocking debounce: poll until LOW, delay 20 ms,
re-read. That works great for simple programs but **blocks the timer loop**.
If you're inside `delay_ms` for 20 ms, you've missed two 10 ms ticks.

The solution: **sample the button on every tick and detect the edge by
comparing to the previous sample.**

```asm
; --- One-time initialization ---
mov.b   &P1IN, R10          ; seed previous state with current pin value
and.w   #BTN, R10           ; isolate BTN bit

; --- Inside the tick loop, after clearing TAIFG ---
mov.b   &P1IN, R11          ; read current button state
and.w   #BTN, R11           ; isolate BTN bit

; detect falling edge: previously HIGH (released), now LOW (pressed)
tst.w   R11                 ; is pin LOW now?
jnz     .Lbtn_update        ; no (HIGH) — skip press logic

cmp.w   #BTN, R10           ; was pin HIGH last tick?
jne     .Lbtn_update        ; no — already was pressed, this is a hold

; ---- PRESS CONFIRMED (falling edge, 10 ms natural debounce) ----
; ... your action here ...

.Lbtn_update:
mov.w   R11, R10            ; save current state as previous
```

Why is this debounced? Because two consecutive 10 ms samples must both
agree. A 1–2 ms bounce spike will be seen as HIGH on one sample and LOW
on the next, but the edge condition (`prev HIGH, curr LOW`) only fires
once when the pin truly settles LOW. This is **implicit debounce** from
the sampling rate — no separate delay needed.

**The tradeoff:** maximum response latency is one tick (10 ms). For a game
that's imperceptible. For a precision timing measurement you would use a
faster tick, but 10 ms is fine for all exercises in this course.

---

## Reloading the Tick Counter

When you change state — for example, changing a blink speed — also reset
the blink tick counter to the new value. Otherwise the LED finishes the
old period before the new rate takes effect.

```asm
; Speed change: update R8 (speed index) and reload blink counter R6
call    #set_speed          ; sets R9 to new tick count
mov.w   R9, R6              ; reset countdown immediately
```

---

## Common Mistakes

**Forgetting `jmp main_loop` at the bottom:**
The loop exits after one pass instead of running forever.

**Reloading the counter before the action:**
```asm
    mov.w   #N_TICKS, R6    ; ← reload first (WRONG — reloads before action)
    xor.b   #LED1, &P1OUT
```
Reload AFTER the action, not before. If you reload first, the counter fires
immediately on the next iteration instead of waiting N ticks.

**Using `jz` instead of `jnz` for the skip:**
```asm
    dec.w   R6
    jz      .Lskip          ; ← WRONG: fires when counter hits zero
    xor.b   #LED1, &P1OUT   ;   this toggles on EVERY tick except the target one
```
The skip branch should use `jnz` — jump when NOT zero (not yet time to fire):
```asm
    dec.w   R6
    jnz     .Lskip          ; ← CORRECT: skip until counter reaches zero
    xor.b   #LED1, &P1OUT
    mov.w   #N_TICKS, R6
.Lskip:
```

**Missing the TAIFG clear when changing modes:**
If you switch between two tick-counter configurations, clear TAIFG first
so you don't carry over a stale flag from the previous configuration.
