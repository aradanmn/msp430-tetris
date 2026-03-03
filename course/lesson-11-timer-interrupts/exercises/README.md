# Lesson 11 Exercises — Timer_A Interrupts

---

## Exercise 1 · 1ms Tick, LED at 500ms

**File:** `ex1/ex1.s`

Create a 1ms system tick using the Timer_A CC0 ISR. Blink LED1 at exactly 500ms
(1Hz).

Requirements:
- CC0 ISR increments a `ms_tick` variable every 1ms
- Main wakes periodically and checks if 500ms have elapsed
- Use the timestamp pattern: `elapsed = ms_tick - last_toggle`
- Main sleeps in LPM0

---

## Exercise 2 · Traffic Light Sequencer

**File:** `ex2/ex2.s`

Implement a traffic light using the 1ms tick:

| Phase | LED | Duration |
|-------|-----|---------|
| Green | LED2 (green, P1.6) | 5000ms |
| Yellow | Both LEDs | 1000ms (simulate yellow with red+green) |
| Red | LED1 (red, P1.0) | 4000ms |

Use a state variable and the tick counter to advance states. The ISR only
increments `ms_tick`.  Main handles state transitions.

---

## Exercise 3 · Stopwatch

**File:** `ex3/ex3.s`

Build a simple stopwatch:

1. Press S2 to **start** counting milliseconds
2. Press S2 again to **stop**
3. LED1 blinks once per complete second accumulated (so if you held for 3.2
   seconds, LED1 blinks 3 times)

State machine:
- State 0 (idle): waiting for first press
- State 1 (running): counting ms since start press
- State 2 (display): blink count of seconds, then return to idle

Use PORT1 ISR for button, CC0 ISR for tick, main for blinking.
