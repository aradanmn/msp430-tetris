# Exercise 1 — First Light: Grade Report

**Grade: A**

## Functionality (Pass/Fail): PASS

LED1 turns on and stays on. Success criteria fully met.

## Concept Understanding

Demonstrates solid understanding of all three questions posed by the exercise:

1. **P1DIR** controls input vs output direction — correctly used `bis.b` to set P1.0 as output
2. **P1OUT** controls the output level — correctly used `bis.b` to drive P1.0 high
3. **`bis.b`** sets a single bit without disturbing others — used correctly in both cases

Using the `LED1` symbolic constant from `msp430g2553-defs.s` rather than a raw `#BIT0` or `#0x01` is good practice and shows you're working with the definitions file.

## Code Quality

- Clean and minimal — no unnecessary instructions
- Proper halt loop (`jmp halt`) to keep the CPU busy after setup
- Boilerplate is correct and complete (SP, WDT, DCO calibration)
- Vector table present and correct

## Comments

The template header comments were retained, which is fine. The inline comment `; Your code here: turn on LED1` could be replaced with something describing *what* the instructions do (e.g., `; P1.0 = output, drive high`), but for a two-instruction solution the code is self-documenting.

## Optimization Notes

None — this is already the minimal correct solution. There is no way to turn on an LED with fewer instructions on this architecture.

## Summary

Textbook solution. You identified the right registers, used the right instruction (`bis.b` instead of `mov.b`, which would clobber other bits), and stopped cleanly. Nothing to improve here.
