# Lesson 04 · Subroutines & Stack

## What You'll Learn

- How `CALL` and `RET` work under the hood
- How the stack grows and what `PUSH`/`POP` do
- How to write reusable subroutines with arguments and return values
- Nested calls and why register discipline matters

## Why This Matters

Every lesson from here on uses subroutines.  Delays, setup routines, ISR helpers
— they are all subroutines.  Without them, every program would be one long flat
sequence of code that's impossible to maintain.

## Goals

After this lesson you will be able to:

1. Write a subroutine that accepts arguments via registers
2. Call a subroutine from `main` and from another subroutine
3. Use `PUSH`/`POP` to save and restore registers inside a subroutine
4. Explain exactly what the stack pointer (SP/R1) contains at each step

## Tutorials

| File | Topic |
|------|-------|
| `tutorial-01-call-ret.md` | The CALL instruction, return address, and the stack |
| `tutorial-02-push-pop.md` | PUSH/POP, saving registers, nested calls |

## Example

```
examples/
└── subroutines.s   ← Three subroutines: delay, blink_n, and max
```

Build and run:

```bash
cd lesson-04-subroutines/examples
make
make flash
```

## Exercises

| Exercise | Task |
|----------|------|
| ex1 | `max(a, b)` — return the larger of two register values |
| ex2 | `blink_n` — blink LED1 exactly N times |
| ex3 | `mul(a, b)` — multiply by repeated addition |

See `exercises/README.md` for full descriptions.

## Capstone Connection

The capstone uses `uart_send_str`, `adc_sample`, `temp_to_ascii`, and `delay_ms`
— all subroutines you can build on the skills learned here.
