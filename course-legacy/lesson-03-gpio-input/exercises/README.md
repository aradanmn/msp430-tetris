# Lesson 03 Exercises

---

## Exercise 1 — Press/Release LED State

Write a program where:
- While the button IS HELD: LED1 is ON, LED2 is OFF
- While the button is NOT held: LED1 is OFF, LED2 is ON

This requires constantly reading the button state, not just detecting the edge.

---

## Exercise 2 — Press Counter

Count button presses. Toggle LED2 on every 3rd press. Use a RAM counter variable
(address 0x0200) to track presses.
- Each press increments the counter
- Every time counter reaches 3, reset to 0 and toggle LED2
- LED1 blinks briefly on every press to give feedback

---

## Exercise 3 — Reaction Test

1. LED2 turns on at a random-ish time (use a loop counter for "random" timing)
2. User must press button while LED2 is on
3. If pressed in time: LED1 blinks quickly 3 times (success!)
4. If too slow: LED2 turns off, LED1 blinks once slowly (fail)
5. Repeat
