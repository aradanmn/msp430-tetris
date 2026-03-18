# MSP430 Development Projects

Two projects using the MSP430 microcontroller family, targeting the TI MSP-EXP430G2 LaunchPad. Build and flash natively on macOS — no VM required.

---

## Projects

### 1. MSP430G2553 Assembly Course (`course/`)

A complete 16-lesson MSP430 assembly programming course. Builds and flashes natively on macOS.

- **16 lessons** — GPIO, interrupts, timers, ADC, UART, SPI, I2C, low-power modes
- **Each lesson** — 2 tutorials, 1 working example, 3 exercises with solutions
- **Capstone** — Smart environment monitor integrating all peripherals
- **Setup** — `./setup-mac.sh` (installs toolchain via Homebrew, ~2 min)

[Course README](course/README.md)

### 2. MSP430G2553 Handheld Console (`handheld-msp430/`)

DIY handheld game console hardware design — Game Boy style.

- **MCU** — MSP430G2553 (20-pin DIP on LaunchPad)
- **Input** — 8 buttons via SN74HC165N shift register (SPI)
- **Display** — 0.96" OLED 128×64 (SPI)
- **Audio** — LM386N-1 amp + speaker (PWM)
- **Power** — Adafruit 4410 USB-C LiPo charger + 3.7V 2Ah LiPo
- **BOM** — ~$53 (DigiKey)
- **Status** — Schematic complete (KiCad 9), breadboard layout done, PCB/firmware pending

[Handheld README](handheld-msp430/README.md)

---

## Session Notes

Design decisions and conversation summaries are in [`docs/sessions/`](docs/sessions/).

---

## Hardware

Both projects target the **MSP-EXP430G2 Rev 1.5** LaunchPad with the eZ-FET lite debugger (USB VID:PID `2047:0013`). Flash with `mspdebug ezfet` (via `make flash` or directly).
