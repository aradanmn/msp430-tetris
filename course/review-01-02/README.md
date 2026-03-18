# Review Exercises — Lessons 01 & 02

Two exercises using only concepts from Lessons 1 & 2. No new tools introduced.

---

## Exercise 1 — Alarm Signal

**What it targets:** Using `.equ` constants correctly (no magic numbers), and
subroutines that each do exactly one job.

Two-phase repeating alarm: 5 slow red pulses (ARMED), then 8 fast red/green
alternations (ALARM), then repeat. All timing values defined as `.equ`
constants — changing one number should adjust the entire program.

See `ex1/ex1.s`.

---

## Exercise 2 — Morse Code, Redesigned

**What it targets:** Subroutine responsibility — each subroutine should do
exactly one thing so its callers can compose cleanly.

In your L01-ex3 SOS solution, `dot` and `dash` embedded a trailing symbol gap.
That forced you to call `delay_ms` with `300` and `850` — manual offsets that
compensate for the gap already included, bypassing the `.equ` constants you
defined. The fix is to split responsibilities: symbol subroutines handle only
the ON pulse; gap subroutines handle only silence. Then the constants are used
directly everywhere, no mental arithmetic required.

See `ex2/ex2.s`.
