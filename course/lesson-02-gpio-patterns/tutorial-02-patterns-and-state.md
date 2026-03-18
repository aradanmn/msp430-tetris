# Tutorial 02 — Patterns and State

## Thinking in Phases

A main loop that does more than one thing needs to be broken into **phases**.
Each phase has a job, runs to completion, and then the next one starts:

```
main_loop:
    ; Phase 1 — ATTRACT (hardware is alive, waiting for player)
    ...
    ; Phase 2 — RUNNING (game in progress)
    ...
    ; Phase 3 — GAME OVER (player lost, dramatic flash)
    ...
    jmp main_loop
```

This is the skeleton of every game loop you'll ever write. For now the phases
are just LED patterns. Later they'll be "read buttons, move piece, redraw
screen, sleep until next tick."

---

## The `flash_leds` Subroutine

Repeating the same on/off/count sequence for every LED pattern gets tedious.
Factor it out into a subroutine:

```asm
; flash_leds — flash one or more LEDs a fixed number of times
;
; Args:   R4 = LED bitmask  (e.g. LED1, or LED2, or LED1|LED2)
;         R5 = flash count
;         R6 = half-period in ms  (on-time = off-time = R6 ms)
;
; Clobbers: R5 (counts down to 0), R12, R13 (used by delay_ms)
; Preserves: R4, R6
;
; Example — flash LED1 three times at 200ms on/off:
;   mov.w   #LED1, R4
;   mov.w   #3,    R5
;   mov.w   #200,  R6
;   call    #flash_leds

flash_leds:
    bis.b   R4, &P1OUT          ; LEDs on
    mov.w   R6, R12             ; copy half-period to R12 for delay_ms
    call    #delay_ms           ; wait (clobbers R12, R13; R4, R5, R6 safe)
    bic.b   R4, &P1OUT          ; LEDs off
    mov.w   R6, R12
    call    #delay_ms           ; wait
    dec.w   R5                  ; count--
    jnz     flash_leds          ; repeat if not done
    ret
```

Notice that `jnz flash_leds` is a **backward jump**, not a recursive call.
No new return address is pushed; the loop just repeats the body. The single
`ret` at the end returns to whoever called `flash_leds`.

Register choice matters here: R4, R5, R6 are not touched by `delay_ms`
(which uses R12 and R13), so the arguments stay intact across the delay calls.

---

## Register Conventions (Preview of Lesson 04)

The MSP430 GCC ABI defines:

| Registers | Role |
|-----------|------|
| R4–R11 | Caller-saved: subroutine may use them freely, caller must preserve if needed |
| R12–R15 | Argument/scratch: used for passing args and return values |

For this lesson, the rule of thumb is: **keep loop counters and state in
R4–R8**, and **pass `delay_ms` its argument in R12**. They won't collide.

Lesson 04 introduces `push` and `pop` for proper full register preservation.

---

## Sequencing Phases

With `flash_leds` available, a main loop becomes readable:

```asm
main_loop:
    ; ATTRACT — LED1 pulses slowly 3 times
    mov.w   #LED1,  R4
    mov.w   #3,     R5
    mov.w   #500,   R6
    call    #flash_leds
    mov.w   #500, R12 ; gap before next phase
    call    #delay_ms

    ; RUNNING — LED1/LED2 alternate 10 times fast
    mov.w   #10, R7
.Lrunning:
    bis.b   #LED1, &P1OUT
    bic.b   #LED2, &P1OUT
    mov.w   #100, R12
    call    #delay_ms
    bic.b   #LED1, &P1OUT
    bis.b   #LED2, &P1OUT
    mov.w   #100, R12
    call    #delay_ms
    dec.w   R7
    jnz     .Lrunning
    bic.b   #(LED1|LED2), &P1OUT
    mov.w   #500, R12
    call    #delay_ms

    ; GAME OVER — both flash 5 times fast
    mov.w   #(LED1|LED2), R4
    mov.w   #5,           R5
    mov.w   #80,          R6
    call    #flash_leds
    mov.w   #1000, R12
    call    #delay_ms

    jmp     main_loop
```

This is the example in `examples/patterns.s`. Run it and watch the LaunchPad
cycle through all three phases.

---

## State Variables

For more complex behavior, store the current state in a register and branch
on it. This is a **state machine**:

```asm
    mov.w   #0, R8          ; R8 = state (0=ATTRACT, 1=RUNNING, 2=GAME_OVER)

state_dispatch:
    cmp.w   #0, R8
    jeq     state_attract
    cmp.w   #1, R8
    jeq     state_running
    ; else fall through to state_game_over

state_game_over:
    ; ... flash pattern ...
    mov.w   #0, R8          ; reset state to ATTRACT
    jmp     state_dispatch

state_attract:
    ; ... slow pulse ...
    mov.w   #1, R8          ; advance to RUNNING
    jmp     state_dispatch

state_running:
    ; ... fast alternating ...
    mov.w   #2, R8          ; advance to GAME_OVER
    jmp     state_dispatch
```

`cmp.w` subtracts without storing, setting flags. `jeq` ("Jump if Equal")
branches when the Zero flag is set (i.e., the operands were equal).

This pattern scales to any number of states — you'll use the same idea in
the final game to track ATTRACT, PLAYING, PAUSED, and GAME_OVER.

---

## Why Not XOR for Phase Switching?

`xor.b` is tempting — one instruction to flip. But it has two problems:

1. **Unknown starting state.** If you don't know whether the LED is on or
   off, XOR will give you the wrong result half the time.
2. **No explicit state.** If your code has multiple paths that might reach
   the XOR instruction, you can't reason about what state you'll be in.

Use `bis.b`/`bic.b` whenever you need the LED to be in a *specific* state.
Use `xor.b` only for simple blink where the starting state doesn't matter
and both states are equivalent.

---

## Summary

- Factor repeated flash patterns into a `flash_leds` subroutine.
- Use R4–R8 for counters and state (they survive `delay_ms` calls).
- `jnz label` inside a subroutine is a backward jump, not recursion.
- `cmp.w` + `jeq`/`jne` is how you dispatch to different state handlers.
- `bis.b`/`bic.b` gives predictable LED state; `xor.b` just flips.
