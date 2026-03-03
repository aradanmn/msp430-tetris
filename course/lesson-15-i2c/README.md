# Lesson 15 · I2C with USCI_B0

## Learning Objectives

- Understand the I2C protocol: addressing, START/STOP, ACK/NACK
- Configure USCI_B0 as I2C master on the MSP430G2552
- Perform a write transaction (master → slave)
- Perform a read transaction (slave → master)
- Handle NACK and bus-busy conditions

## Prerequisites

Lesson 14 (SPI) — USCI_B0 hardware; Lesson 13 (UART) — debug output.

## Lessons

| File | Topic |
|------|-------|
| tutorial-01-i2c-theory.md | I2C bus, addressing, START/STOP/ACK |
| tutorial-02-i2c-master.md | USCI_B0 I2C master registers and sequences |

## Hardware

USCI_B0 I2C pins on MSP430G2552:

| Pin  | Signal   | Note |
|------|----------|------|
| P1.6 | UCB0SDA  | Data (open-drain, needs 4.7kΩ pull-up to VCC) |
| P1.7 | UCB0SCL  | Clock (open-drain, needs 4.7kΩ pull-up to VCC) |

> **Note:** P1.6 is also LED2 on the LaunchPad.  Remove the LED2 > jumper when
using I2C, as the LED creates a load on the SDA line.

Both SDA and SCL require **external pull-up resistors** (4.7 kΩ typical).

## Exercises

| Exercise | Topic |
|----------|-------|
| ex1 | I2C bus scan — try all 127 addresses, report ACK/NACK via UART |
| ex2 | Write bytes to an I2C EEPROM (AT24C02 or similar) |
| ex3 | Read temperature from TMP102 / LM75 over I2C |
