# Lesson 04 Exercises

Run the example first (`cd examples && make flash`) and observe LED1 (2 Hz)
and LED2 (5 Hz) blinking independently — both driven by one 10 ms timer tick.

---

## Exercise 1 — Hardware Blink

**File:** `ex1/ex1.s`

Replace the `delay_ms` software loop with a Timer_A polling loop.
Blink LED1 at exactly **2 Hz** (toggle every 250 ms).

**What to implement:**
- Define `TICK_PERIOD` and `BLINK_TICKS` as `.equ` constants (compute the values)
- Write TACCR0 then TACTL to start Timer_A
- Load a tick countdown register
- Main loop: poll TAIFG, clear it, decrement counter, toggle + reload when zero
- No `delay_ms` or `call` instructions — this is a flat polling loop

**New instructions used:** `bit.w`, `bic.w` (same as `bit.b`/`bic.b` but 16-bit)

**Success criteria:** LED1 blinks visibly at 2 Hz. The rate doesn't drift.
Changing only `TICK_PERIOD` adjusts timing throughout with no other edits.

---

## Exercise 2 — Dual-Rate Blinker

**File:** `ex2/ex2.s`

Drive two LEDs at different rates from one timer:
- **LED1** toggles every **500 ms** (1 Hz)
- **LED2** toggles every **125 ms** (4 Hz)

**What to implement:**
- Choose a tick period that divides evenly into both intervals
- Define all four constants: `TICK_PERIOD`, `LED1_TICKS`, `LED2_TICKS`
- Two independent tick-down counters in separate registers
- Service both channels in the main loop after each tick

**Success criteria:** Both LEDs blink simultaneously at their target rates.
Neither LED affects the other. Changing one `*_TICKS` constant does not
disturb the other channel.

---

## Exercise 3 — Adjustable-Speed Blinker

**File:** `ex3/ex3.s`

LED1 blinks continuously. Each button press cycles through four blink speeds:

| Speed | Toggle period | Rate |
|-------|--------------|------|
| 0 (slow) | 500 ms | 1 Hz |
| 1 | 250 ms | 2 Hz |
| 2 | 100 ms | 5 Hz |
| 3 (fast) | 50 ms | 10 Hz |

LED2 flashes briefly (200 ms) to acknowledge each speed change.

**What to implement:**
- Timer_A 10 ms tick
- `apply_speed` subroutine: reads speed index in R8, sets tick count in R9
- Blink counter in R6, loaded from R9 via `apply_speed`
- Button edge detection on each tick (from Tutorial 02):
  - Store previous BTN sample in R10
  - On each tick: read BTN, compare to R10, detect falling edge
  - On press: advance R8 (wrap at `NUM_SPEEDS`), call `apply_speed`, reload R6
- LED2 acknowledgement counter in R7 (counts down from `ACK_TICKS`)

**New concept:** Timer-based button edge detection — no `delay_ms` debounce,
no blocking wait. The 10 ms sampling interval provides natural debounce.

**Success criteria:** Each button press advances the speed exactly once.
LED1 blink rate changes immediately. LED2 flashes briefly on each press.

---

## Common Traps

- Writing TACTL before TACCR0 — timer fires at rate zero
- Forgetting `bic.w #TAIFG, &TACTL` after detection — next poll fires instantly
- Using `jz` instead of `jnz` for the skip branch — fires every tick except the target
- Reloading the counter before the action (see Tutorial 02)
- Using `bit.b` instead of `bit.w` on TACTL — TACTL is 16-bit
