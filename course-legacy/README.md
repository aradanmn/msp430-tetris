# MSP430G2552 Assembly Programming Course

A complete, hands-on course for programming the MSP430G2552 in assembly language
using a LaunchPad development board and a Linux VM toolchain.

---

## Course Overview

This course teaches MSP430 assembly from zero to a real working project. Every
lesson builds on the last, and all lessons contribute components to the
**Capstone Project: Smart Environment Monitor** — a battery-friendly device
that:

- Reads temperature from the MSP430's internal sensor (ADC10)
- Sends readings over UART to your computer
- Blinks an LED every second to show it's alive
- Activates an alarm LED when temperature exceeds a threshold
- Accepts button input to arm/disarm the alarm
- Sleeps in LPM0 between events (very low power)
- Protected by the watchdog timer

When you finish this course, you will have written every line of that project
yourself — and understand exactly why each line is there.

---

## Prerequisites

- You have UTM installed with a Linux VM (see `../README.md` for setup)
- The MSP430 toolchain is installed inside the VM (`vm-setup.sh`)
- You have a **MSP430 LaunchPad** with a **G2552** chip installed
- Basic familiarity with hexadecimal and binary numbers is helpful

---

## Course Structure

```
Part 1 — Foundations (Lessons 01–04)
│
├── Lesson 01 · Architecture & Tools    ← registers, memory map, toolchain
├── Lesson 02 · GPIO Output             ← LEDs, bit manipulation, delays
├── Lesson 03 · GPIO Input              ← buttons, polling, debounce
└── Lesson 04 · Subroutines & Stack     ← call/ret, push/pop, structured code

Part 2 — Timing (Lessons 05–08)
│
├── Lesson 05 · Clock System               ← DCO calibration, MCLK, SMCLK, ACLK
├── Lesson 06 · Watchdog Timer             ← WDT watchdog vs timer modes
├── Lesson 07 · Timer_A Basics             ← Up/Continuous modes, polling CCIFG
└── Lesson 08 · Timer_A PWM               ← hardware PWM, duty cycle, fade

Part 3 — Interrupts (Lessons 09–11)
│
├── Lesson 09 · Interrupt Concepts         ← GIE, ISRs, vector table, LPM wakeup
├── Lesson 10 · GPIO Interrupts            ← P1IE, P1IFG, edge select, debounce
└── Lesson 11 · Timer Interrupts        ← CC0 ISR, TAIV ISR, multi-rate timing

Part 4 — Communication (Lessons 12–13)
│
├── Lesson 12 · ADC10                   ← analog/digital, internal temp sensor
└── Lesson 13 · UART                       ← serial output to computer, echo

Part 5 — Expansion (Lessons 14–16)
│
├── Lesson 14 · SPI                        ← USCI_B0, shift registers, sensors
├── Lesson 15 · I2C                        ← USCI_B0, addressing, I2C devices
└── Lesson 16 · Low Power Modes         ← LPM0-LPM4, VLO, interrupt-driven

Capstone — Smart Environment Monitor
└── Combines all 16 lessons into one real project
```

---

## How Each Lesson Is Organized

```
lesson-XX-name/
├── README.md               ← Lesson overview, goals, what to do
├── tutorial-01-*.md        ← First concept: theory + code examples
├── tutorial-02-*.md        ← Second concept (builds on tutorial 01)
├── examples/
│   ├── Makefile            ← Ready to build
│   └── *.s                 ← Fully-commented working example
└── exercises/
    ├── README.md           ← What each exercise asks you to build
    ├── ex1/
    │   ├── ex1.s           ← Starter file (skeleton with hints)
    │   └── solution/
    │       └── ex1.s       ← Complete solution (read after trying!)
    ├── ex2/  ...
    └── ex3/  ...
```

**Workflow for each lesson:**
1. Read `README.md` for the big picture
2. Read `tutorial-01-*.md` and `tutorial-02-*.md`
3. Build and flash the `examples/` code — watch it run on hardware
4. Read `exercises/README.md`, then attempt each exercise
5. Stuck? Peek at `exercises/exN/solution/` — no shame in reading working code

---

## Common Files

```
common/
├── msp430g2552-defs.s    ← All register addresses and bit definitions
│                            (included at top of every .s file)
└── Makefile.template     ← Makefile template for new projects
```

---

## Building and Flashing

Every `examples/` and `exercises/exN/` directory contains a `Makefile`.

```bash
# Inside the VM, navigate to a lesson example:
cd ~/course/lesson-02-gpio-output/examples

# Compile:
make

# Flash to LaunchPad (USB must be passed through in UTM):
make flash

# See disassembly (great for learning):
make disasm

# Remove compiled files:
make clean
```

The `make` output shows the flash/RAM usage. The G2552 has:
- **8192 bytes** of Flash (code + constants)
- **512 bytes** of RAM (variables, stack)

---

## LaunchPad Pin Reference

```
MSP430G2552 LaunchPad  (MSP-EXP430G2)
┌─────────────────────────────────────────┐
│  P1.0 ──── LED1  (Red)                  │
│  P1.1 ──── UART RXD (USB-to-UART chip)  │
│  P1.2 ──── UART TXD (USB-to-UART chip)  │
│             also: Timer_A TA0.1 (PWM)   │
│  P1.3 ──── Button S2  (active LOW)      │
│  P1.4 ──── SPI CLK  / T_CLK            │
│  P1.5 ──── SPI MOSI / UCA0SIMO         │
│  P1.6 ──── LED2  (Green)               │
│             also: SPI MISO / I2C SDA   │
│  P1.7 ──── I2C SCL                     │
└─────────────────────────────────────────┘
```

---

## MSP430G2552 Quick Reference

| Resource     | Value              |
|-------------|---------------------|
| Flash        | 8 KB               |
| RAM          | 512 B              |
| CPU          | 16-bit RISC        |
| Default clock| ~1.1 MHz (DCO)     |
| GPIO ports   | P1, P2, P3         |
| Timers       | Timer_A3           |
| ADC          | ADC10, 8 ch + temp |
| UART/SPI     | USCI_A0            |
| I2C/SPI      | USCI_B0            |
| Voltage      | 1.8–3.6V           |
| Package      | 20-pin DIP         |

---

## Capstone Project

```
capstone-smart-monitor/
├── README.md       ← Project overview and hardware notes
├── design.md       ← Architecture, memory map, interrupt plan
└── src/
    ├── Makefile
    └── monitor.s   ← Complete implementation
```

Start the capstone after completing at least lessons 01–13. Lessons 14–16 add
the SPI/I2C/LPM3 refinements covered in the design notes.

---

## Resources

| Document | Where to find it |
|---------|------------------|
| MSP430x2xx Family User Guide (SLAU144) | ti.com → search SLAU144 |
| MSP430G2552 Datasheet | ti.com → search MSP430G2552 |
| MSP430 Assembly Language Tools Guide | ti.com → search SLAU131 |
| mspdebug manual | `man mspdebug` or dlbeer.co.nz/mspdebug |
| LaunchPad User Guide | ti.com → search SLAU318 |
