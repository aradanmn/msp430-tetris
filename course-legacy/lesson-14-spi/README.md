# Lesson 14 · SPI with USCI_B0

## Learning Objectives

- Understand SPI framing: clock polarity, phase, bit order
- Configure USCI_B0 as SPI master on the MSP430G2552
- Transfer bytes using polling (TXIFG/RXIFG in IFG2)
- Control a chip-select line manually with GPIO
- Verify transfers with loopback (MOSI tied to MISO)

## Prerequisites

Lessons 01-13 — especially UART (Lesson 13) for communication patterns.

## Lessons

| File | Topic |
|------|-------|
| tutorial-01-spi-theory.md | SPI bus, CPOL/CPHA, USCI_B0 SPI registers |
| tutorial-02-spi-transfer.md | TX/RX, chip select, multi-byte transfers |

## Hardware

USCI_B0 SPI pins on MSP430G2552:

| Pin  | Signal    | Note |
|------|-----------|------|
| P1.5 | UCB0CLK   | SPI clock |
| P1.6 | UCB0SOMI  | MISO (Master-In, Slave-Out) |
| P1.7 | UCB0SIMO  | MOSI (Master-Out, Slave-In) |

> **Note:** P1.6 is also LED2 on the LaunchPad.  Disconnect or leave the > LED2
jumper open when using SPI.

Any spare GPIO pin can serve as chip-select (active-low).

## Exercises

| Exercise | Topic |
|----------|-------|
| ex1 | SPI loopback — send byte, verify received byte matches |
| ex2 | SPI with GPIO chip-select, multi-byte transfer |
| ex3 | Drive a 74HC595 shift register — display 8-bit pattern on LEDs |
