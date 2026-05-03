# Lesson 04 — Exercise 2 Grade

**Score: 9/10 — Pass**

## What worked
- Tick period chosen correctly (5 ms) — divides evenly into both 500 ms and 125 ms
- `LED1_TICKS = 100`, `LED2_TICKS = 25` — correct
- One TAIFG poll per loop iteration; both channels serviced after each tick
- Independent dec/jnz/toggle/reload per channel — neither affects the other
- Local labels used correctly

## Issues
- Leftover `; TODO:` comments on constant definitions in submitted file (-1)
