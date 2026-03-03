# Lesson 16 · Low Power Modes

## Learning Objectives

- Understand LPM0 through LPM4 and what remains active in each
- Enter and exit low-power modes using the Status Register
- Wake from LPM3 using the WDT interval timer or GPIO interrupt
- Design battery-powered systems that minimize average current
- Combine LPM with the tick-scheduler from Lesson 11

## Prerequisites

All previous lessons, especially:
- Lesson 9 (Interrupt concepts, LPM0 entry/exit pattern)
- Lesson 10 (GPIO ISR)
- Lesson 11 (Timer ISR, tick scheduler)

## Lessons

| File | Topic |
|------|-------|
| tutorial-01-lpm-modes.md | LPM modes, current consumption, what stays active |
| tutorial-02-wake-sources.md | Timer, GPIO, UART, USCI wake-up sources |

## LPM Mode Summary

| Mode | CPU | MCLK | SMCLK | ACLK | DCOCLK | Typical I_cc |
|------|-----|------|-------|------|--------|-------------|
| Active | On | On | On | On | On | ~400 µA |
| LPM0  | Off | Off | On | On | On | ~60 µA |
| LPM1  | Off | Off | Off | On | On | ~17 µA |
| LPM2  | Off | Off | Off | On | Off | ~17 µA |
| LPM3  | Off | Off | Off | On | Off | ~1 µA |
| LPM4  | Off | Off | Off | Off | Off | ~0.1 µA |

> Values are approximate at 3.3 V.  SMCLK = DCO → LPM0 keeps DCO running. > LPM3
is the sweet spot for periodic wakeup from ACLK/VLO.

## Exercises

| Exercise | Topic |
|----------|-------|
| ex1 | LPM3 + WDT interval: 1Hz blink at ~1 µA average |
| ex2 | LPM4 + GPIO wakeup: deepest sleep, button wakes to blink then sleeps |
| ex3 | LPM0 + Timer ISR scheduler: same tick-blink from Lesson 11 but with idle LPM0 |
