# Lesson 05 Exercises

Run the example first (`cd examples && make flash`). Notice: there is no
polling loop. The CPU sleeps. The ISR is the entire program.

Each exercise converts a Lesson 04 program from polling to interrupt-driven.
The behaviour is identical — only the mechanism changes.

---

## Exercise 1 — Interrupt-Driven Blink

**Requires:** Lessons 1–4 + Tutorial 01 (CC0 interrupt, CCIE, reti)

**File:** `ex1/ex1.s`

Convert your Lesson 04 Exercise 1 solution to use the Timer_A CC0 interrupt
instead of polling TAIFG. Behaviour is unchanged: LED1 blinks at 2 Hz.

**What changes from L04-Ex1:**
- Add `CCIE` to `TACCTL0` before starting the timer
- Replace the polling main loop with `bis.w #(GIE|CPUOFF), SR`
- Move the decrement/toggle/reload logic into a `timer_isr` subroutine ending with `reti`
- Update the vector table: put `timer_isr` at position 0xFFF4

**Success criteria:** LED1 blinks at 2 Hz. No polling loop exists in the code.

---

## Exercise 2 — Interrupt-Driven Dual-Rate Blinker

**Requires:** Lessons 1–4 + Exercise 1 (CC0 ISR structure)

**File:** `ex2/ex2.s`

Convert your Lesson 04 Exercise 2 solution to interrupt-driven. Both LED
channels move into the ISR. Main sleeps.

**Success criteria:** LED1 at 1 Hz, LED2 at 4 Hz, CPU in LPM0 between ticks.

---

## Exercise 3 — Interrupt-Driven Adjustable-Speed Blinker

**Requires:** Lessons 1–4 + Exercises 1–2 (full ISR-driven tick loop)

**File:** `ex3/ex3.s`

Convert your Lesson 04 Exercise 3 solution to interrupt-driven. The entire
main loop — LED1 blink, LED2 ack, button edge detection — moves into the ISR.
Main initializes registers and sleeps.

**Success criteria:** Behaviour identical to L04-Ex3. CPU sleeps between ticks.
No polling loop.
