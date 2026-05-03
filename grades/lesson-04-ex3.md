# Lesson 04 — Exercise 3 Grade

**Score: 8/10 — Pass**

## What worked
- Timer_A tick, LED1 blink channel, `apply_speed` dispatch — all correct
- `change_speed` uses increment-and-wrap with `NUM_SPEEDS` — no dispatch needed
- Button edge detection — correct falling-edge logic, no blocking waits
- `SPD_STATE0–3` constants used in `apply_speed` only (correct placement)
- `.equ` arithmetic throughout

## Issues
- First attempt: `flash_led1` was inside the button-press branch — LED1 only
  blinked on button press. Required structural correction. (-1)
- LED2 `flash_led2`: label placement bug — `bic.b #LED2` was after `.Lled2_skip`
  label, so it fired every tick regardless of branch taken. LED2 never
  stayed lit. Required fix. (-1)

## Notes
- Session coaching contradicted itself on LED2 behaviour (xor vs bis/bic)
  three times — cost one full debugging session. Not charged to student.
- Student correctly identified that `#0` as a starting index is not a
  magic number.
