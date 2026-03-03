# Lesson 04 Exercises — Subroutines & Stack

Work through these in order.  Each builds on the previous. Compile with `make`
from within an `exN/` directory (copy a Makefile from `examples/` and change
`TARGET`), or just study the code.

---

## Exercise 1 · `max(a, b)` Subroutine

**File:** `ex1/ex1.s`

Write a subroutine called `max` that:

- Takes two 16-bit values in **R12** and **R13**
- Returns the larger value in **R12**

Then call it from `main` with three different pairs and blink:
- LED1 once if the result is ≤ 5
- LED2 once if the result is > 5

**Hints:**
- Use `CMP R13, R12` which computes R12 − R13 and sets flags
- `JGE` branches if R12 ≥ R13 (signed)
- `JHS` branches if R12 ≥ R13 (unsigned — same thing for positive values)

---

## Exercise 2 · `blink_n` Subroutine

**File:** `ex2/ex2.s`

Write a subroutine called `blink_n` that:

- Takes a count in **R12**
- Blinks LED1 exactly that many times (on + off = 1 blink)
- Uses a `delay_ms` subroutine internally (write that too)

Then call `blink_n` from `main` with counts 1, 2, and 3, pausing 1 second
between each group.

**Key challenge:** `delay_ms` uses R12 as its argument.  `blink_n` uses R12 as
its loop counter.  You must `PUSH` and `POP` to preserve the counter across each
call to `delay_ms`.

---

## Exercise 3 · `mul(a, b)` Multiply by Repeated Addition

**File:** `ex3/ex3.s`

The MSP430G2552 has no hardware multiply instruction in the base CPU (there is a
separate hardware multiplier peripheral, but you haven't learned that yet).
Write a subroutine that multiplies two small unsigned integers using a loop:

```
mul(a, b):
    result = 0
    repeat b times:
        result += a
    return result
```

Interface:
- **R12** = a (multiplicand)
- **R13** = b (multiplier)
- **R12** = result on return

Then call `mul(3, 4)` and `mul(7, 5)` from `main` and blink LED1 the result
number of times (hint: call your `blink_n` from Exercise 2).

**Caution:** If the result overflows 16 bits, behavior is undefined. Keep inputs
small (≤ 10 each) for this exercise.
