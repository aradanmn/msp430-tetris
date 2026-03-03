# Lesson 07 · Timer_A Basics

## What You'll Learn

- How Timer_A counts and what "Up mode" and "Continuous mode" mean
- How to generate precise time delays using the CCIFG flag (polling)
- How to use TACCR0 to set a repeating period
- Reading TAR to measure elapsed time

## Why This Matters

Software delay loops (Lessons 04–05) are MCLK-dependent and burn 100% CPU.
Timer_A runs **independently** of the CPU clock divider and frees the CPU to do
other work — or sleep.  It is the backbone of timing in the capstone project.

## Goals

1. Configure Timer_A in Up mode with a 50ms period (polling CCIFG)
2. Generate two independent LED rates using TAR comparison
3. Measure how long a button is held using Continuous mode

## Tutorials

| File | Topic |
|------|-------|
| `tutorial-01-timer-modes.md` | Up/Continuous/Up-Down modes, TACTL bits |
| `tutorial-02-polling-ccifg.md` | Polling CCIFG to wait for a period; reading TAR |

## Example

```
examples/
└── timer_basic.s   ← LED1 blinks at 2Hz using Timer_A Up mode (polling)
```

## Exercises

| Exercise | Task |
|----------|------|
| ex1 | Generate an exact 1-second delay using Timer_A polling |
| ex2 | Dual-rate: LED1 every 500ms, LED2 every 250ms from same timer |
| ex3 | Measure button hold time in ms; blink LED that many hundreds of ms |

## Capstone Connection

The capstone uses Timer_A CC0 ISR to generate a 1ms system tick. Lessons 07–08
build the foundation; Lesson 11 adds the ISR.
