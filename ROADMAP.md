# MSP430G2553 Handheld Tetris — Course Roadmap

Build a Game Boy-style handheld running Tetris, one lesson at a time. Every lesson teaches a new MSP430 concept and adds a working piece of the game or its hardware.

**Target hardware** (assembled progressively on a breadboard):

| Component | Part | ~Cost |
|-----------|------|-------|
| MCU | MSP-EXP430G2 LaunchPad (MSP430G2553) | ~$10 |
| Display | 2.42" OLED 128×64 SPI (SSD1309, Adafruit #2719) | ~$18 |
| Buttons | SN74HC165N 8-bit parallel-in shift register × 1 | ~$1 |
| Audio | LM386N-1 audio amp + 8Ω speaker | ~$3 |
| Power | Adafruit 4410 USB-C LiPo charger + 3.7V 2Ah LiPo | ~$15 |
| Passives | Breadboard, resistors, caps, diodes | ~$5 |

---

## Phase 1 — Foundation (Lessons 1–5)
*Hardware: LaunchPad only (LEDs + onboard button)*

**Lesson 01 — Architecture & Toolchain**
- MSP430G2553 memory map, register file, status register
- Instruction set overview: MOV, ADD, SUB, AND, OR, BIC, BIS, BIT
- Toolchain: msp430-elf-gcc, mspdebug, Makefile workflow
- Hello world: blink LED1 (P1.0) at 1 Hz
- *Game connection:* understand the canvas we'll draw on

**Lesson 02 — GPIO Output & Patterns**
- Port direction, output registers, toggle trick
- Bit manipulation idioms in MSP430 assembly
- Multi-LED patterns, software delay loops
- *Game connection:* represent game states with LED patterns (start, game-over flash)

**Lesson 03 — GPIO Input & Buttons**
- Input registers, internal pull-ups (P1REN)
- Active-low button logic, polling loop
- Onboard S2 button (P1.3)
- *Game connection:* "press button to start" → triggers game start later

**Lesson 04 — Subroutines & the Stack**
- CALL / RET, stack pointer mechanics, frame layout
- Passing arguments in registers (R12–R15 calling convention)
- Building reusable `delay_ms`, `led_set` routines
- *Game connection:* modular game functions — move_piece, draw_board, etc.

**Lesson 05 — Clock System & Precise Timing**
- DCO calibration to 1 MHz and 8 MHz
- SMCLK, MCLK, ACLK sources and dividers
- Calibrated software delays
- *Game connection:* game loop runs at a fixed tick — this is where that precision comes from

---

## Phase 2 — Display (Lessons 6–10)
*Hardware: Add 0.96" SSD1306 OLED (SPI) + breadboard*

**What to add:** Wire SSD1306 to P1.5 (SCLK), P1.7 (MOSI), P2.0 (CS), P2.1 (DC), P2.2 (RST). 3.3V from LaunchPad.

**Lesson 06 — Timer A & Game Tick**
- Timer A modes: stop, up, continuous, up/down
- CCR0 compare match → periodic interrupt
- Building a 60 Hz game loop heartbeat
- *Game connection:* Tetris gravity = piece drops one row every N ticks

**Lesson 07 — Interrupts**
- Interrupt vector table, ISR entry/exit
- GIE, CPUOFF, SR manipulation in ISRs
- Interrupt latency and priority
- *Game connection:* button presses and tick timer both use interrupts in the final game

**Lesson 08 — SPI with USCI_B0**
- USCI_B0 SPI master setup (CPOL=0, CPHA=0, MSB first)
- `spi_write_byte` subroutine
- Chip-select protocol, DC pin for SSD1306
- *Game connection:* every pixel sent to the display goes through this

**Lesson 09 — SSD1306 OLED Driver**
- SSD1306 initialization sequence (21 commands)
- Page-addressing mode, column/page addressing
- `oled_clear`, `oled_set_pixel`, `oled_flush`
- *Game connection:* draw a single pixel — foundation for everything visual

**Lesson 10 — Drawing Primitives**
- Framebuffer in RAM (128×64 / 8 = 1024 bytes = 2× the MSP430's RAM!)
- Column-based partial update strategy to fit in 512 B RAM
- Draw filled rectangle, draw horizontal/vertical line
- *Game connection:* draw the Tetris board border and a single tetromino block

---

## Phase 3 — Input (Lessons 11–13)
*Hardware: Add SN74HC165N shift register + 8 tactile buttons*

**What to add:** SN74HC165N PL to P2.3, CLK to P1.5 (shared SPI CLK), Q7 to P1.6 (MISO). 8 buttons to A–H inputs with pull-up resistors.

**Lesson 11 — SPI Input: Shift Register**
- SPI in receive mode; USCI_B0 MISO (P1.6)
- SN74HC165N protocol: pulse PL low, read 8 bits
- `buttons_read` → 8-bit button state in R12
- *Game connection:* read D-pad + A/B/Start/Select in one SPI transaction

**Lesson 12 — Debouncing & Button Events**
- Software debounce (tick-based, not delay-based)
- Edge detection: pressed, released, held
- Button map: Left, Right, Down, Rotate-CW, Rotate-CCW, Drop, Start, Pause
- *Game connection:* the input system the game will use

**Lesson 13 — Interrupt-Driven Input**
- Port 2 interrupt on button change (optional hardware INT line from 74HC165)
- Latency-sensitive input vs. polling in the game loop
- Input queue in RAM
- *Game connection:* sub-frame-latency button response

---

## Phase 4 — Audio (Lessons 14–15)
*Hardware: Add LM386N-1 + 8Ω speaker*

**What to add:** PWM output from P2.4 (TA1.2) → 10µF cap → LM386 pin 3, speaker on pins 5/GND, 250µF cap on pin 7. 9V or 5V supply to LM386 pin 6.

**Lesson 14 — PWM & Timer A CCR**
- Timer A up-mode with CCR1/CCR2 for PWM
- Duty cycle control, square wave generation
- `tone_play(freq, duration)` subroutine
- *Game connection:* piece-move blip, rotate click, line-clear jingle

**Lesson 15 — Sound Effects & Music**
- Frequency table in Flash (notes C4–B5)
- Sequence player: tempo, notes array
- Game sounds: move, rotate, soft-drop, line clear (1–4 lines), game over, level up
- *Game connection:* complete audio feedback system

---

## Phase 5 — Full Game (Lessons 16–20)
*Hardware: Optionally add LiPo power system for portable play*

**Lesson 16 — Game Board Representation**
- 10×20 board in RAM as a packed bit array (25 bytes)
- `board_get(row, col)`, `board_set(row, col, val)` subroutines
- Board rendering: map bit → pixel block on OLED
- *Game connection:* the core data structure of Tetris

**Lesson 17 — Tetrominos & Rotation**
- 7 pieces encoded as 4×4 bitmasks in Flash (4 rotations each = 28 words)
- `piece_get_block(piece, rotation, row, col)`
- Rotation state machine
- *Game connection:* every piece you'll drop

**Lesson 18 — Collision, Movement & Placement**
- `piece_can_move(dx, dy)`: bounds + board collision check
- `piece_place()`: stamp current piece onto board
- Hard drop (instant fall), soft drop (faster gravity)
- *Game connection:* the physics of Tetris

**Lesson 19 — Line Clear & Scoring**
- `board_check_lines()`: scan rows for full lines
- `board_clear_line(row)`: shift all rows down
- Scoring: 1 line=100, 2=300, 3=500, 4=800 (Tetris scoring)
- Level system: every 10 lines, gravity speeds up
- *Game connection:* the win condition and progression

**Lesson 20 — Complete Game + Polish**
- Title screen, "GAME OVER" animation
- High score stored in Flash (using BSL write or Info Flash segment)
- Pause menu
- Low-power idle between ticks (LPM0 + timer interrupt)
- *Game connection:* **ship it** — full playable Tetris on your handheld

---

## Repo Organization

```
msp430-dev-vm/          ← github.com/aradanmn/msp430-dev-vm
├── ROADMAP.md          ← this file
├── course/
│   ├── common/         ← shared defs, Makefile.template
│   ├── lesson-01-architecture/
│   │   ├── README.md
│   │   ├── tutorial-01-*.md
│   │   ├── examples/   ← working demo
│   │   └── exercises/  ← problems + solutions
│   └── ... (lesson-02 through lesson-20)
├── journal/            ← session-by-session learning log
│   └── 2026-03-07_session-01_kickoff.md
├── docs/
│   └── hardware/       ← wiring guides per phase
├── course-legacy/      ← archived original 16-lesson course
└── sync.sh             ← push both repos to GitHub

Handheld-MSP430/        ← github.com/aradanmn/Handheld-MSP430
├── schematic/          ← KiCad files
├── breadboard/         ← wiring guide, layout
├── bom/                ← bill of materials
└── firmware/ → points to msp430-dev-vm course
```

---

## What You Need Right Now (Phase 1)

Just the **MSP-EXP430G2 LaunchPad** — you likely already have it.

**To start Phase 2** (Lesson 6), order:
- 0.96" SSD1306 OLED SPI module (128×64, 7-pin) — ~$4 on Amazon/AliExpress
- Full-size breadboard + jumper wires

**To start Phase 3** (Lesson 11), order:
- SN74HC165N (DIP-16) × 1 — DigiKey or Mouser
- 6mm tactile push buttons × 8
- 10kΩ resistors × 8 (pull-ups)

**To start Phase 4** (Lesson 14), order:
- LM386N-1 (DIP-8) × 1
- 8Ω 0.5W speaker
- 10µF and 250µF electrolytic caps
- 9V battery + snap connector (or 5V USB)

---

## Where to Start

Open `course/lesson-01-architecture/` and read `README.md`. Every lesson has the same structure: read the tutorials, run the example, then attempt the exercises before peeking at solutions.
