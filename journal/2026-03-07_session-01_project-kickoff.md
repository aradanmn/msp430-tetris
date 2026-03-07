# Session 01 — Project Kickoff
**Date:** 2026-03-07
**Duration:** ~1 hour
**Phase:** Pre-work / Planning

---

## What Happened

First session. Reviewed the existing repo and designed the full course plan from scratch.

The goal is to learn MSP430G2553 assembly programming by building a Game Boy-style handheld Tetris clone — hardware assembled progressively on a breadboard as the course advances through new peripherals.

---

## Decisions Made

**Course rebuilt from scratch** around the Tetris project (20 lessons, 5 phases). The original 16-lesson course is preserved in `course-legacy/`.

**Two GitHub repos** stay separate:
- `aradanmn/msp430-dev-vm` — course content, journal, hardware guides
- `aradanmn/Handheld-MSP430` — KiCad schematic, breadboard layout, BOM

**Journal:** Written automatically at the end of each session, committed to `msp430-dev-vm/journal/`.

**Hardware build order:**
1. LaunchPad only (Lessons 1–5)
2. Add OLED display SPI (Lessons 6–10)
3. Add shift register + 8 buttons (Lessons 11–13)
4. Add LM386 amp + speaker (Lessons 14–15)
5. Full game + optional LiPo power (Lessons 16–20)

---

## Files Created This Session

- `ROADMAP.md` — 20-lesson course plan with hardware phases and shopping list
- `journal/` directory
- `sync.sh` — script to push both repos to GitHub
- `docs/hardware/` — hardware wiring guides (per phase)

---

## Current State

- Course plan exists in `ROADMAP.md`
- Old course content is in `course/` (to be renamed `course-legacy/`)
- New `course/` lessons 1–20 are pending creation
- No code written yet — that starts in the next session

---

## Next Session

Start **Lesson 01 — Architecture & Toolchain**:
- Write `course/lesson-01-architecture/README.md`
- Write tutorials: MSP430G2553 memory map, register file, instruction set overview
- Write `examples/blink.s` — blink LED1 at 1 Hz using a software delay loop
- Write 3 exercises with solutions

**Hardware needed for next session:** MSP-EXP430G2 LaunchPad (already owned).

---

## Questions / Blockers

- Old `course/` folder should be renamed to `course-legacy/` before lesson-01 is rebuilt — confirm with Scott before doing so.
- GitHub repos need an initial commit with the new files (`ROADMAP.md`, `journal/`, `sync.sh`).
