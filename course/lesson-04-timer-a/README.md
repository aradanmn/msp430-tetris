# Lesson 04 — Timer_A: Hardware Timing

**Goal:** Replace software delay loops with Timer_A, the MSP430's built-in
16-bit hardware counter. Learn to derive multiple independent timing rates
from a single timer tick.

**Game connection:** Tetris needs a reliable heartbeat — piece fall rate,
lock delay, line-clear flash timing. All of those come from one timer tick
counter running in the background. After this lesson you have that heartbeat.

---

## What You'll Learn

- Why software delay loops are wasteful and when to replace them
- Timer_A registers: `TACTL`, `TACCR0`, `TAR`
- Up mode: count 0 → TACCR0, set `TAIFG`, reset and repeat
- Polling `TAIFG` — the hardware equivalent of `delay_ms`
- The **tick-counter pattern**: derive multiple rates from one hardware tick
- Timer-based button edge detection (sample on each tick, compare to previous)

---

## Hardware

**MSP-EXP430G2 LaunchPad** — USB only, no extra components.

| Signal | Pin | Notes |
|--------|-----|-------|
| LED1 | P1.0 | Red |
| LED2 | P1.6 | Green |
| S2 (BTN) | P1.3 | Active LOW (Ex3 only) |

---

## Files

```
lesson-04-timer-a/
├── README.md                           ← you are here
├── tutorial-01-timer-a-basics.md       ← Timer_A registers, up mode, TAIFG poll
├── tutorial-02-timing-patterns.md      ← tick counting, multiple rates, button sampling
├── examples/
│   ├── Makefile
│   └── timer.s                         ← two LEDs at different rates from one timer
└── exercises/
    ├── README.md
    ├── ex1/   ex1/solution/            ← hardware blink at 2 Hz
    ├── ex2/   ex2/solution/            ← dual-rate blinker
    └── ex3/   ex3/solution/            ← adjustable speed (button + timer together)
```

---

## Suggested Path

1. Read `tutorial-01-timer-a-basics.md`
2. Read `tutorial-02-timing-patterns.md`
3. Run the example: `cd examples && make flash`
   - Watch LED1 (2 Hz) and LED2 (5 Hz) blink at different rates simultaneously
4. Attempt exercises **before** looking at solutions

---

## Key Facts to Memorize

```
Timer_A up mode setup (3 steps):
  1. mov.w  #PERIOD, &TACCR0               ; set period first
  2. mov.w  #(TASSEL_2|MC_1|TACLR), &TACTL ; start: SMCLK, up, clear
  3. ; timer is now running — TAR counts 0 → PERIOD, then resets

Period formula (SMCLK = 1 MHz):
  TACCR0 = (milliseconds × 1000) − 1
  1 ms  → TACCR0 =   999
  5 ms  → TACCR0 =  4999
  10 ms → TACCR0 =  9999

Polling one tick:
  wait:  bit.w  #TAIFG, &TACTL   ; test overflow flag
         jz     wait              ; not yet — keep waiting
         bic.w  #TAIFG, &TACTL   ; clear flag (required before next period)

Tick counter pattern (drive LED at N ticks per toggle):
  dec.w  R6              ; count down
  jnz    .Lskip          ; not time yet
  xor.b  #LED1, &P1OUT   ; toggle
  mov.w  #N_TICKS, R6    ; reload
.Lskip:
```

| Timer constant | Meaning |
|----------------|---------|
| `TASSEL_2` | Clock source = SMCLK (1 MHz after calibration) |
| `MC_1` | Up mode: count 0 → TACCR0, repeat |
| `TACLR` | Clear TAR to 0 at startup |
| `TAIFG` | Overflow flag: set when TAR resets from TACCR0 to 0 |
