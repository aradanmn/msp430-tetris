# Lesson 11 · Timer_A Interrupts

## What You'll Learn

- How to use the Timer_A CC0 ISR for precise periodic timing
- How CC0 differs from CC1/CC2 (separate vector vs shared TAIV)
- Building a 1ms system tick counter using Timer_A ISR
- Using tick counter to schedule multiple time-based events

## Why This Matters

A 1ms system tick is the foundation of nearly every real-time embedded system.
With a tick counter you can schedule tasks at arbitrary intervals without
polling loops.  The capstone project builds entirely on this pattern.

## Goals

1. Generate a 1ms CC0 interrupt from Timer_A at 1MHz
2. Use the tick counter to drive multiple LED patterns simultaneously
3. Read TAIV to handle CC1/CC2 and timer overflow interrupts

## Tutorials

| File | Topic |
|------|-------|
| `tutorial-01-cc0-isr.md` | CC0 interrupt, vector 0xFFF4, 1ms tick setup |
| `tutorial-02-scheduling.md` | Using tick counter for multi-rate scheduling |

## Example

```
examples/
└── timer_isr.s   ← 1ms tick; LED1 blinks at 1Hz, LED2 at 3Hz
```

## Exercises

| Exercise | Task |
|----------|------|
| ex1 | 1ms tick ISR; blink LED1 at exactly 500ms rate |
| ex2 | Traffic light: green 5s, yellow 1s, red 4s using tick counter |
| ex3 | Stopwatch: button starts/stops; LED1 blinks count of full seconds |

## Capstone Connection

The capstone uses a 1ms CC0 ISR as its core scheduling mechanism. Everything
else (ADC sampling, UART output, alarm timing) is measured in milliseconds
against this tick.
