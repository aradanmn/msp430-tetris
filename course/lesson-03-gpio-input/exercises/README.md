# Lesson 03 Exercises

Run the example first (`cd examples && make flash`) to see all three techniques
in action before writing your own.

---

## Exercise 1 — Button Lamp

**File:** `ex1/ex1.s`

LED1 is ON while the button is held and OFF when released. No debounce needed —
this is level detection.

**What to implement:**
- Configure BTN as input with pull-up (three registers)
- Configure LED1 as output, start OFF
- Main loop: read BTN, drive LED1 to match (on when pressed, off when released)

**Success criteria:** LED1 follows the button with no noticeable lag. No other
LEDs are affected.

---

## Exercise 2 — Toggle on Press

**File:** `ex2/ex2.s`

Each physical button press toggles LED1 (on→off→on→...). LED2 flashes 80ms
after each confirmed press as visual feedback.

**What to implement:**
- Full debounced edge detect: wait press → debounce 20ms → re-read → confirm
- Toggle LED1 on confirmed press
- Flash LED2 for 80ms (acknowledgement)
- Full debounced release wait: wait release → debounce 20ms → re-read → confirm
- All timings as `.equ` constants, no magic numbers

**Success criteria:** Exactly one toggle per physical press regardless of how
long you hold the button. No ghost presses. LED2 flashes exactly once per press.

---

## Exercise 3 — Press-to-Cycle Patterns

**File:** `ex3/ex3.s`

Button cycles through four LED states on each press:

| State | LED1 | LED2 |
|-------|------|------|
| 0 — IDLE  | OFF | OFF |
| 1 — RED   | ON  | OFF |
| 2 — GREEN | OFF | ON  |
| 3 — BOTH  | ON  | ON  |

Then wraps back to 0.

**What to implement:**
- State in R8, initialized to 0
- `apply_state` subroutine: reads R8, drives LEDs accordingly, ends with `ret`
- `inc.w R8` + wrap logic (compare to NUM_STATES, `clr.w R8` if equal)
- `call #apply_state` after each state change
- Full debounce on both press and release

**New instruction introduced:** `inc.w Rn` — increments Rn by 1.

**Success criteria:** Each press advances exactly one state. States cycle
cleanly 0→1→2→3→0. LEDs match the table above at all times.

---

## Common Traps

- Forgetting the three-register input setup (P1DIR + P1REN + P1OUT)
- `jz` vs `jnz` confusion: `jz` branches when the bit is 0 (pressed), `jnz` when 1 (released)
- Missing the re-read after debounce delay — without it you're not debouncing, just delaying
- Forgetting `ret` in `apply_state`
- Advancing state before OR after the wrong event (should be after confirmed press, before waiting for release)
