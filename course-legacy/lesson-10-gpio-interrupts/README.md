# Lesson 10 · GPIO Interrupts

## What You'll Learn

- How Port 1 interrupts work (P1IE, P1IES, P1IFG)
- Edge selection: falling vs rising edge trigger
- How to handle and clear GPIO interrupt flags in an ISR
- Software debouncing inside an ISR

## Why This Matters

Polling a button wastes power and CPU cycles.  A GPIO interrupt lets the CPU
sleep until the button is pressed — the ideal pattern for battery-powered
devices.  This is also the basis for external sensors that signal "data ready"
via an interrupt pin.

## Goals

1. Configure P1.3 (button S2) to generate a falling-edge interrupt
2. Write a PORT1_ISR that clears P1IFG and toggles LED1
3. Add software debounce inside the ISR
4. Combine GPIO interrupt with LPM0 sleep in main

## Tutorials

| File | Topic |
|------|-------|
| `tutorial-01-port-interrupts.md` | P1IE, P1IES, P1IFG registers and edge select |
| `tutorial-02-debouncing.md` | Bounce phenomenon and ISR debounce strategies |

## Example

```
examples/
└── gpio_isr.s   ← Button S2 interrupt: toggle LED1 on each press
```

## Exercises

| Exercise | Task |
|----------|------|
| ex1 | Button press ISR, toggle LED1 each press |
| ex2 | Press counter: track count in RAM, blink count-many times on release |
| ex3 | Toggle LED1 on press, toggle LED2 on release (both edges) |

## Capstone Connection

The capstone uses a PORT1 interrupt on S2 to arm/disarm the temperature alarm
without polling.
