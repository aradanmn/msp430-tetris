# Lesson 02 Exercises

Work through these in order. Attempt each one **without** looking at the solution.

---

## Exercise 1 — Counted Flash (Easy)

**Problem:** Flash LED1 exactly 4 times (150ms on, 150ms off), then pause 800ms, then repeat forever.

**What you need to know:**
- Use a register (R7) as a counter.
- Load it with `mov.w #4, R7`, then `dec.w R7` / `jnz` to loop.
- `delay_ms` takes its argument in R12 and clobbers R12 and R13.
  Keep your counter in R7 — it won't be touched by `delay_ms`.

**Pass condition:** LED1 flashes 4 times, then goes dark for ~800ms, then repeats.

**File:** `ex1/ex1.s`

---

## Exercise 2 — Dual Throb (Medium)

**Problem:** LED1 flashes 3 times fast (100ms on/off), then LED2 flashes 3 times fast (100ms on/off), then both are off for 500ms. Repeat forever.

**What you need to know:**
- You need two separate counted loops — one for each LED.
- Use R7 as the counter for the LED1 burst, then reload R7 for the LED2 burst.
- Make sure the other LED is off while the active one is flashing.

**Pass condition:** LED1 throbs 3 times, then LED2 throbs 3 times, then a 500ms dark gap. Clearly sequential, never both on at the same time.

**File:** `ex2/ex2.s`

---

## Exercise 3 — Mini State Machine (Hard)

**Problem:** Implement a 3-state LED machine that advances automatically through states:

- **State 0 (ATTRACT):** LED1 blinks 3 times at 400ms. Then advance to State 1.
- **State 1 (RUNNING):** LED1 and LED2 alternate 6 times at 120ms. Then advance to State 2.
- **State 2 (GAME OVER):** Both LEDs flash 4 times at 60ms, then 1s dark. Then back to State 0.

**What you need to know:**
- Store the current state in R8 (e.g. 0, 1, 2).
- Use `cmp.w` and `jeq` to dispatch to the right state handler.
- At the end of each state handler, update R8 and jump to the dispatcher.

```asm
; Dispatcher skeleton:
state_dispatch:
    cmp.w   #0, R8
    jeq     state_attract
    cmp.w   #1, R8
    jeq     state_running
    jmp     state_game_over
```

**Pass condition:** The three phases cycle continuously. State transitions are clean — no leftover LEDs on between phases.

**File:** `ex3/ex3.s`

---

## Solutions

Solutions are in `exN/solution/`. Only look after you've made a genuine attempt.
