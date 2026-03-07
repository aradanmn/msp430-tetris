# Lesson 09 · Interrupt Concepts

## What You'll Learn

- How hardware interrupts work at the CPU level (ISR, vector table, GIE)
- The difference between polling and interrupt-driven design
- How to write an ISR in GNU assembly
- How to place ISR vectors using the `.vectors` section
- How to enter and exit Low Power Mode (LPM0) safely

## Why This Matters

Interrupts are the foundation of all responsive, power-efficient embedded
systems.  Instead of spinning in a loop checking flags, the CPU sleeps and wakes
only when something needs attention.  Every lesson from here uses interrupts.

## Goals

1. Understand what the CPU does when an interrupt fires
2. Write a complete interrupt-driven program (WDT ISR + LPM0)
3. Understand why `RETI` must be used (not `RET`) in ISRs
4. Place the ISR address in the vector table correctly

## Tutorials

| File | Topic |
|------|-------|
| `tutorial-01-interrupt-mechanics.md` | What happens at the hardware level |
| `tutorial-02-isr-and-lpm.md` | Writing ISRs, LPM entry/exit, vector table |

## Example

```
examples/
└── isr_intro.s   ← WDT ISR toggles LED1; Timer_A ISR toggles LED2; main in LPM0
```

## Exercises

| Exercise | Task |
|----------|------|
| ex1 | Enable GIE and handle WDT interval interrupt — toggle LED1 |
| ex2 | Enter LPM0 in main; wake on WDT ISR; do work; return to LPM0 |
| ex3 | Two ISRs: WDT on LED1 (~1Hz), Timer_A CC0 on LED2 (2Hz) |

## Capstone Connection

The entire capstone is interrupt-driven.  This lesson explains the mechanism
every other ISR lesson relies on.
