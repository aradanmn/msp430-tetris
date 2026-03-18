# Session 02 — Lesson 02 Complete, BOM Update, Repo Cleanup
_Date: 2026-03-18_

## What Was Done

### Lesson 02 — GPIO Output & Patterns
Created full lesson content:
- `tutorial-01-gpio-output.md` — P1DIR/P1OUT deep dive, all four bit-manipulation instructions (`bis.b`, `bic.b`, `xor.b`, `bit.b`) with binary diagrams, counted loops with `dec.w`/`jnz`, register conventions
- `tutorial-02-patterns-and-state.md` — `flash_leds` subroutine design, backward-jump loop vs recursion, phase sequencing, state machines with `cmp.w`/`jeq`
- `examples/patterns.s` — 3-phase game-state demo (ATTRACT → RUNNING → GAME OVER)
- Three exercises with solutions (ex1, ex2, ex3)

### Lesson 02 Exercises — Completed with Feedback

**Ex1 — Counted Flash:** Three iterations.
1. First attempt: `dec.w/jnz` loop ran before toggle (counter was a busy-wait, not a flash counter)
2. Second attempt: `jnz` placed after `call #delay_ms` — Zero flag clobbered by callee, loop exited after one iteration
3. Third attempt: `xor.b` with 4 toggles = 2 visible flashes (toggle ≠ flash)
4. Final fix: `bis.b`/`bic.b` inside the loop, `dec.w`/`jnz` after both delays — correct

**Key lesson:** `jnz` must immediately follow the instruction whose result you want to test. Never place `jnz` after a `call` — the callee destroys all flags.

**Ex2 — Dual Throb:** Mostly correct first attempt. Forgot `bic.b #LED1` guard before LED2 burst (not a visible bug here since `flash_leds` always ends with LED off, but important defensive habit).

**Ex3 — Mini State Machine:**
1. First attempt: `.equ` for register aliases (doesn't work — register names aren't numeric constants in GNU as). Fixed with `#define`.
2. Two logic bugs: (a) `jnz state_running` reset R7 each iteration — loop label must be after setup code; (b) `count` (R6) not reloaded before second `flash_leds` call, causing 65535-iteration runaway.
3. Final solution: correct `#define` aliases, local `.Lrunning_loop` label, `count` reloaded before each `flash_leds` call.

### Review Exercises — review-01-02

Two exercises targeting gaps identified from all L01+L02 work:

1. **Alarm Signal** — enforces `.equ` constants (zero magic numbers in code), subroutine-per-responsibility pattern. Two subroutines: `armed_pulse` (R5=count) and `alarm_burst` (R7=pair-count).

2. **Morse Code Redesigned** — fix the L01-ex3 SOS issue where `dot`/`dash` embedded trailing gaps, forcing manual offset arithmetic (850 instead of 1000, 300 instead of 450). New design: `dot`/`dash` = ON pulse only; `sym_gap`/`let_gap`/`word_gap` = separate gap subroutines. Constants used directly, no arithmetic.

### BOM Update
- Display: SSD1306 0.96" (Adafruit #326) → **SSD1309 2.42" (Adafruit #2719, DigiKey SAM1029-40-ND)**
- Headers: **Samtec TSW-140-07-G-S** long-pin breakaway for breadboard contact
- Init code change: `CMD_CHARGE_PUMP, 0x14` removed — SSD1309 uses external charge pump, not software-enabled
- New files: `docs/bom-structured.md`, `docs/bom-flat.md` (~$77 total BOM)
- Updated: `ROADMAP.md` display row, `docs/hardware/phase-2-oled-display.md`

### Repo Cleanup
Removed all VM/legacy content:
- `handheld-msp430/` — old KiCad scripts, old breadboard guide (had wrong I2C OLED wiring)
- `docs/sessions/` — UTM/VM-era session logs, no longer relevant
- `vm-setup/`, `vm.sh`, `sync.sh` — VM management scripts, replaced by `setup-mac.sh`

---

## Key Concepts Covered This Session

| Concept | Where |
|---------|-------|
| `bis.b`/`bic.b` vs `xor.b` — explicit set/clear vs toggle | L02-ex1 |
| Status flags clobbered by `call` — `jnz` must follow the tested instruction | L02-ex1 |
| `dec.w`/`jnz` loop structure — setup before label, `jnz` to inner label | L02-ex3 |
| Register aliases with `#define` (not `.equ`) for register names | L02-ex3 |
| Subroutine single-responsibility — one job per subroutine | review-ex2 |
| `.equ` constants — used directly, no manual offset arithmetic | review-ex1/ex2 |

---

## Current State

- Lessons 01 and 02 complete
- Review exercises created, partially in progress (alarm signal and morse redesign)
- Next: finish review exercises, then Lesson 03 — GPIO Input & Buttons

## Next Lesson Preview (Lesson 03)
- `P1IN`, `P1REN` (internal pull-ups), active-low button logic
- Polling loop for onboard S2 button (P1.3)
- `bit.b` for pin state testing — finally using it for input (not just flags)
- Game connection: "press button to start" → game state transition
