# Exercise 4 — Project Milestone: Handheld Skeleton

**Requires:** Lessons 1–5 tutorials + Exercises 1–3

This is the first **project milestone**. Instead of a standalone exercise, you
build the foundation of the handheld gaming platform in `handheld/`.

From this lesson onward, ex4 always adds to the same growing codebase.

---

## What to Create

```
handheld/
├── Makefile          ← already provided (TARGET=main)
├── registers.md      ← register convention reference (already provided)
├── main.s            ← _start, init, LPM0 entry, vector table, game_update stub
└── hal/
    └── timer.s       ← timer_init + timer_isr
```

## Behavioral Spec

1. **LED1 blinks at 2 Hz** (toggles every 250 ms) — proves the ISR + tick counter work
2. **LED2 pulses once on startup** (ON for 200 ms, then OFF permanently) — proves _start init runs
3. **CPU sleeps in LPM0** between interrupts (`bis.w #(GIE|CPUOFF), SR`)
4. **All timing via `.equ` arithmetic** — `TICK_MS`, `TICK_PERIOD`, `BLINK_TICKS`, `STARTUP_TICKS`
5. A **`game_update` stub** exists in `main.s` (just `ret`) — will be filled in by later lessons

## Architecture

- `main.s` includes `hal/timer.s` via `#include "hal/timer.s"` (same convention as defs.s)
- `timer_init` sets up Timer_A CC0 with 5 ms tick and enables the interrupt
- `timer_isr` fires every 5 ms; it decrements R4 and toggles LED1 on zero
- `main.s` owns the vector table (timer_isr at 0xFFF4, _start at 0xFFFE)

## Register Usage (First Use of Convention)

Read `handheld/registers.md` for the full convention. For this milestone:

| Register | Role |
|----------|------|
| **R4** | Blink tick counter — decremented each tick, reloaded to `BLINK_TICKS` on zero |
| **R12** | Startup countdown (one-shot) — decremented from `STARTUP_TICKS` to 0, then stays 0 |

R4 is a **persistent** register (ISR owns it). R12 is **scratch** but works here
because nothing else uses it yet. In later lessons, the startup pulse will move
to a RAM variable once R12 is needed for subroutine arguments.

## Build & Test

```sh
cd handheld
make              # should compile cleanly
make flash        # flash to LaunchPad
```

**Verify:**
- LED2 lights on reset, turns off after ~200 ms
- LED1 blinks steadily at 2 Hz
- No polling loop — CPU is in LPM0
