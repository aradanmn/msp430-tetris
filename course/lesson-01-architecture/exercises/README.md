# Lesson 01 Exercises

Read both tutorials and flash the example first (`cd examples && make flash`).
Study the example code — understand every line before starting.

These exercises are pure fundamentals. No milestone yet — that starts in Lesson 02.

---

## Exercise 1 — First Light

**Requires:** Tutorial 01 (GPIO section)

**File:** `ex1/ex1.s`

Write a program from scratch that turns on LED1. That's it — LED on, stay on.

The startup boilerplate is provided (stack pointer, watchdog, DCO calibration).
You figure out the rest. LED1 is on P1.0.

Questions to answer before writing code:
- What register controls whether a pin is an input or output?
- What register controls the output level of a pin?
- What instruction sets a single bit without changing the others?

**Success criteria:** LED1 turns on after flashing. It stays on.

---

## Exercise 2 — Timing by Counting

**Requires:** Tutorial 01 (delay loop section) + Exercise 1

**File:** `ex2/ex2.s`

Make LED1 blink at approximately 2 Hz (toggle every ~250 ms) using a software
delay loop.

The startup boilerplate and LED setup are provided. You write:
1. A `delay_ms` subroutine that waits approximately R12 milliseconds
2. A main loop that toggles LED1 and calls your delay

To build the delay, you need to figure out:
- How many CPU cycles is 1 millisecond at 1 MHz?
- How many cycles does one iteration of a `dec` + `jnz` loop consume?
- How do you nest an inner loop (1 ms) inside an outer loop (R12 ms)?

Look up instruction cycle counts in the MSP430 instruction set reference if needed.
Do the math yourself. Don't look at the example's `delay_ms` until you've tried.

**Success criteria:** LED1 blinks at roughly 2 Hz. Timing doesn't need to be exact —
within 20% is fine for a software loop.

---

## Exercise 3 — SOS Morse Code

**Requires:** Tutorial 01 + Exercises 1–2

**File:** `ex3/ex3.s`

Blink LED1 in the SOS Morse code pattern, then repeat.

```
S = · · ·     (3 short flashes)
O = — — —     (3 long flashes)
S = · · ·     (3 short flashes)
              [long pause before repeating]
```

**Timing (standard Morse, simplified):**
- Dot:  LED ON 150 ms, OFF 150 ms
- Dash: LED ON 450 ms, OFF 150 ms
- Between letters (S→O, O→S): 450 ms total off-time
- After full SOS: 1000 ms off before repeating

Design the program yourself. Consider:
- Should you write the same on/off/delay sequence 9 times, or create subroutines?
- If subroutines, what interface? What goes in R12?
- How do you handle the different gap lengths between symbols, letters, and words?

The startup boilerplate and your `delay_ms` from Ex2 are provided. Everything
else is yours to design.

**Success criteria:** A recognizable SOS pattern that repeats indefinitely.
