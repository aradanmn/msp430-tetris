# Capstone · Smart Environment Monitor

## Overview

This capstone project brings together every major topic from the course into a
single, battery-capable embedded system.

The **Smart Environment Monitor** continuously reads the MSP430G2552's internal
temperature sensor, reports readings over UART, and raises a visual alarm when
the temperature exceeds a threshold.  A button arms or disarms the alarm.  The
WDT provides safety in case of firmware bugs.

## Features Integrated

| Feature | Lesson |
|---------|--------|
| GPIO output — LEDs | 02 |
| GPIO input — button | 03 |
| Subroutines, stack | 04 |
| WDT (safety reset) | 06 |
| Timer_A CC0 ISR (1ms tick) | 11 |
| ADC10 internal temperature | 12 |
| UART TX (report + alarm) | 13 |
| LPM0 (idle between ticks) | 16 |

## Hardware

MSP430G2552 LaunchPad (no additional components required).

| Pin | Function |
|-----|----------|
| P1.0 | LED1 — heartbeat (toggles every 500ms) |
| P1.6 | LED2 — alarm indicator (on when temp > threshold) |
| P1.3 | BTN  — press to toggle alarm arm/disarm |
| P1.1 | UCA0RXD — connect to emulator (LaunchPad jumper) |
| P1.2 | UCA0TXD — connect to emulator (LaunchPad jumper) |

## UART Output

Connect with: `picocom -b 9600 /dev/ttyACM0`

```
=== Smart Environment Monitor ===
Armed. Threshold: 30C
T=24C  [OK]
T=24C  [OK]
T=31C  [ALARM]
```

## System Architecture

```
Timer_A CC0 ISR (1ms)
  └─ inc ms_tick
  └─ wake main (LPM0)

main_loop (LPM0 between wakes):
  ├─ Every 2000ms: sample ADC10 temperature
  │     └─ convert raw → °C
  │     └─ send UART report
  │     └─ check threshold → set/clear alarm state
  ├─ Every 500ms: toggle LED1 heartbeat
  └─ On alarm state: LED2 on + "ALARM" prefix

PORT1_ISR (button):
  └─ toggle armed/disarmed state
  └─ send UART notification
```

## Files

```
capstone-smart-monitor/
├── README.md       ← this file
├── design.md       ← design decisions and register setup
└── src/
    ├── Makefile
    └── monitor.s   ← complete implementation
```

## Building and Flashing

```bash
cd src/
make
make flash
```
