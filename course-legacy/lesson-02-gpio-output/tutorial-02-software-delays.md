# Tutorial 02 — Software Delays

## Why Delays?

Without a delay, the CPU can toggle an LED millions of times per second — far
too fast to see. At 1MHz, each clock cycle takes 1 microsecond. A simple `xor.b`
instruction takes about 4 clock cycles, toggling the LED every 4 microseconds.
The human eye cannot perceive changes faster than about 15–20ms (50–67 Hz). To
make a 1Hz blink (LED changes state twice per second), we need approximately
500ms between state changes.

The simplest way to create a delay is a tight counting loop that burns clock
cycles doing nothing useful.

---

## The Delay Loop Pattern

```asm
; Software delay — approximately 150ms at 1MHz DCO
; Each iteration: DEC (1 cycle) + JNZ (2 cycles when taken) = 3 cycles
; 50000 iterations × 3 cycles = 150,000 cycles = 150ms at 1MHz
delay:
        push    R15                 ; Save R15 (caller might be using it)
        mov.w   #50000, R15         ; Load counter
delay_loop:
        dec.w   R15                 ; Decrement counter (1 cycle)
        jnz     delay_loop          ; 2 cycles taken, 1 on fall-through
        pop     R15                 ; Restore R15
        ret                         ; Return to caller
```

To use the delay:
```asm
call    #delay          ; Suspends main loop for ~150ms
```

The `push R15` / `pop R15` pattern preserves the caller's R15 value. The
subroutine can use R15 as a counter internally without affecting the caller's
code. This is called "callee-saves" convention and is covered in depth in Lesson
04.

---

## Timing Calculation

At 1MHz DCO clock:
- 1 clock cycle = 1 µs
- `dec.w R15` = 1 cycle
- `jnz delay_loop` = 2 cycles when the branch is taken (all iterations except
  last)
- `jnz delay_loop` = 1 cycle on the final iteration (branch not taken)

So each iteration costs approximately 3 cycles (1 + 2 = 3). The last iteration
costs 2 cycles (1 + 1 = 2), but this is a negligible correction for large
counts.

Formula: `count = desired_time_us / 3`

| Desired Delay | Count | Notes |
|---------------|-------|-------|
| ~10ms | 3,333 | Fits in R15 (max 65535) |
| ~30ms | 10,000 | Fits in R15 |
| ~100ms | 33,333 | Fits in R15 |
| ~150ms | 50,000 | Fits in R15 |
| ~196ms | 65,535 | Maximum single-loop delay |
| ~500ms | — | Requires nested loops |
| ~1 second | — | Requires nested loops |

---

## Delays Longer than ~196ms

R15 is a 16-bit register. The maximum value is 65535. At 3 cycles/iteration and
1MHz:

```
65535 × 3 cycles = 196,605 µs ≈ 196ms
```

For longer delays, use one of two approaches:

**Approach 1: Call the delay multiple times**
```asm
; ~500ms = call delay_150ms 3 times (with a bit extra)
call    #delay_150ms
call    #delay_150ms
call    #delay_150ms
```

**Approach 2: Nested loop**
```asm
; ~1 second delay at 1MHz
delay_1s:
        push    R14
        push    R15
        mov.w   #7, R14             ; Outer loop: 7 iterations
d1s_outer:
        mov.w   #50000, R15         ; Inner loop: ~150ms each
d1s_inner:
        dec.w   R15
        jnz     d1s_inner
        dec.w   R14
        jnz     d1s_outer
        pop     R15
        pop     R14
        ret
```

This gives approximately 7 × 150ms = 1.05 seconds.

**Approach 3: Parameterized delay (Lesson 04 exercise)**
```asm
; Call delay_100ms N times:
mov.w   #10, R14
delay_1s:
        call    #delay_100ms
        dec.w   R14
        jnz     delay_1s
```

---

## The push/pop Convention for Subroutines

Every subroutine that uses registers should save and restore them:

```asm
my_subroutine:
        push    R15         ; Save R15 before using it
        push    R14         ; Save R14 before using it
        ; ... use R14 and R15 ...
        pop     R14         ; Must restore in REVERSE order (LIFO stack)
        pop     R15
        ret
```

The stack is Last-In-First-Out (LIFO). If you push R15 first, then R14, you must
pop R14 first, then R15. Getting the order wrong is a common bug that corrupts
the stack and causes mysterious crashes.

---

## The DCO Clock at Reset

At power-on reset, the MSP430G2552 runs from the internally calibrated DCO
(Digitally Controlled Oscillator). Without explicit configuration, the DCO runs
at approximately 1.1MHz (the exact frequency varies by device, temperature, and
voltage).

The G2552's flash memory contains factory-calibrated constants for precise
frequencies:
- `CALBC1_1MHZ` / `CALDCO_1MHZ` — calibration values for 1.000MHz
- `CALBC1_8MHZ` / `CALDCO_8MHZ` — calibration values for 8.000MHz
- `CALBC1_12MHZ` / `CALDCO_12MHZ` — calibration values for 12.000MHz
- `CALBC1_16MHZ` / `CALDCO_16MHZ` — calibration values for 16.000MHz

For now, we use the default uncalibrated DCO (~1.1MHz) and treat it as
"approximately 1MHz." Our delay calculations will be slightly off, but close
enough for blinking LEDs.

Lesson 05 (Clock System) will show how to use the calibration constants for
precise timing.

---

## Important Limitation of Software Delays

Software delays are simple to write but have serious drawbacks:

1. **Clock-dependent**: If you change the DCO frequency, all your delays change
   proportionally. A delay tuned for 1MHz will run 8× faster at 8MHz.

2. **Blocking**: The CPU does nothing useful during a delay loop. No interrupts
   can be serviced (unless GIE is set), no other work can happen.

3. **Inaccurate**: Interrupts (when enabled) can extend a delay unpredictably.

4. **Not power-efficient**: The CPU stays awake burning current in the delay
   loop.

Hardware timers (covered in Lessons 07–08) solve all of these problems by using
dedicated timer hardware to count time, freeing the CPU to sleep or do other
work. For now, software delays are fine for simple LED demonstrations.
