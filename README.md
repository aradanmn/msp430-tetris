# MSP430 Handheld Tetris

A 16-lesson MSP430 assembly course that builds toward a handheld Tetris console. Everything runs natively on macOS (Apple Silicon or Intel) — no VM required.

The course and the handheld project are integrated: lessons teach one peripheral at a time, and each lesson's final exercise (ex4) adds that peripheral's driver to a growing skeleton project in `handheld/`. By the end, the skeleton becomes a working game platform.

---

## Quick Start

```sh
./setup-mac.sh          # one-time: installs mspdebug + picocom via Homebrew
cd course/lesson-01-architecture/examples
make flash              # compile + flash to LaunchPad (USB must be connected)
```

Requires the [TI MSP430-GCC](https://www.ti.com/tool/MSP430-GCC-OPENSOURCE) full installer at `~/ti/msp430-gcc/`. See `setup-mac.sh` for details.

---

## Repository Structure

```
course/
├── common/
│   ├── msp430g2553-defs.s   ← register/bit definitions (included by every .s file)
│   ├── glossary.md          ← acronym & terminology reference
│   └── Makefile.template
├── lesson-01-architecture/  ← GPIO, memory map, toolchain
├── lesson-02-gpio-patterns/ ← bit manipulation, multi-LED patterns
├── lesson-03-gpio-input/    ← buttons, debounce, edge detection
├── lesson-04-timer-a/       ← Timer_A polling, timing patterns
├── lesson-05-interrupts/    ← Timer_A CC0 ISR, LPM0
└── lesson-06 through 16/    ← SPI, display, input, audio, game logic (planned)

handheld/                    ← growing skeleton project (the capstone)
├── main.s                   ← _start, init, LPM0, vector table
├── hal/                     ← hardware abstraction (timer, SPI, display, input, audio)
├── gfx/                     ← framebuffer, sprites
└── game/                    ← Tetris logic, UI

docs/
├── hardware/                ← breadboard guide, phase build docs
├── bom-structured.md        ← hierarchical bill of materials
└── bom-flat.md              ← flat BOM for ordering (~$117 excl. shipping)
```

Each lesson contains tutorials, a working example, and 4 exercises (ex1–ex3 are standalone concept practice with progressive scaffold reduction; ex4 is a project milestone that adds to `handheld/`).

---

## Hardware

- **MCU:** MSP430G2553 on the **MSP-EXP430G2 Rev 1.5** LaunchPad (eZ-FET lite, USB `2047:0013`)
- **Display:** 2.7" SSD1325 grayscale OLED 128×64 (SPI)
- **Input:** 8 buttons via SN74HC165N shift register (SPI)
- **Audio:** LM386N-1 amp + speaker (Timer_A PWM)
- **Power:** Adafruit 4410 USB-C LiPo charger + 3.7V 2Ah LiPo
- **Flash:** `make flash` uses `mspdebug tilib` with `DYLD_LIBRARY_PATH=~/.local/lib`

---

## Current Progress

Lessons 01–05 are written. The handheld skeleton has `main.s` and `hal/timer.s` (CC0 ISR + LPM0 game loop shell). Next up: lesson 06 (SPI) and the display driver.
