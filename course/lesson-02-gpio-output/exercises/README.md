# Lesson 02 Exercises

---

## Exercise 1 — Explicit Set and Clear

Write a program that:
1. Turns on **both** LEDs (both P1.0 and P1.6 HIGH)
2. Waits ~150ms
3. Turns **both** LEDs off
4. Waits ~150ms
5. Repeats forever

Do NOT use XOR.B — use explicit BIS.B and BIC.B for each state change. This
reinforces the difference between setting, clearing, and toggling.

---

## Exercise 2 — SOS Morse Code

Blink LED1 in SOS pattern: `...  ---  ...` (dot-dot-dot dash-dash-dash
dot-dot-dot)
- Dot = LED on for ~100ms, off for ~100ms
- Dash = LED on for ~300ms, off for ~100ms
- Letter gap = ~300ms pause
- Pattern gap = ~600ms pause before repeating

---

## Exercise 3 — Binary Counter

Use R4 as a 2-bit counter (0-3). Display it on the two LEDs:
- 0 = both LEDs off
- 1 = LED1 on, LED2 off
- 2 = LED1 off, LED2 on
- 3 = both LEDs on

Increment the counter every ~300ms, wrapping from 3 back to 0.
