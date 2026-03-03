# Tutorial 15-1 · I2C Theory and Bus Mechanics

## What Is I2C?

**Inter-Integrated Circuit** (I2C, pronounced "I-squared-C") is a two-wire,
half-duplex, synchronous bus originally designed by Philips (now NXP):

```
VCC
 ├─── 4.7kΩ ─── SDA ─── MCU SDA ─┬─ Slave1 SDA ─┬─ Slave2 SDA
 └─── 4.7kΩ ─── SCL ─── MCU SCL ─┴─ Slave1 SCL ─┴─ Slave2 SCL
```

Both lines are **open-drain**: devices can only pull the line low. The pull-up
resistors pull the line high when nobody drives it.

Key properties:
- 7-bit (or 10-bit) device addresses — up to 127 devices on one bus
- Master generates clock (SCL); all transfers are framed by START/STOP
- Each byte is acknowledged by the receiver (ACK = SDA low, NACK = SDA high)

---

## Bus Transaction Structure

A complete write transaction (master writes N bytes to slave):

```
S  ADDR  W  A   D0  A   D1  A  ...  DN  A   P
─────────────────────────────────────────────────
S  = START condition (SDA falls while SCL high)
ADDR = 7-bit slave address
W  = Write bit (0)
A  = ACK from slave (SDA pulled low by slave)
D0..DN = Data bytes from master
P  = STOP condition (SDA rises while SCL high)
```

A read transaction (master reads N bytes from slave):

```
S  ADDR  R  A   D0  A   D1  A  ...  DN  NA  P
```
`NA` = NACK from master on last byte (tells slave to release SDA).

---

## 7-bit Addressing

The address byte on the bus is `{ADDR[6:0], R/W̄}`:
- `W̄ = 0` → write (master sends data)
- `W̄ = 1` → read (slave sends data)

Common device addresses:
| Device | Address |
|--------|---------|
| AT24C02 EEPROM | 0x50–0x57 |
| TMP102 temp sensor | 0x48–0x4B |
| LM75 temp sensor | 0x48–0x4F |
| PCF8574 I/O expander | 0x20–0x27 |

Reserved addresses: 0x00 (general call), 0x01–0x07, 0x78–0x7F.

---

## Clock Speed

Standard mode: 100 kHz (`UCB0BR0 = 10` at 1 MHz SMCLK) Fast mode: 400 kHz
(`UCB0BR0 = 2.5` → use `UCB0BR0 = 3`)

The MSP430G2552 USCI_B0 I2C supports both.

---

## USCI_B0 I2C vs SPI

| Feature | SPI (Lesson 14) | I2C (This Lesson) |
|---------|-----------------|-------------------|
| UCB0CTL0 UCMODE | 00 (3-wire SPI) | 11 (I2C) |
| UCSYNC | 1 | 1 |
| Wire count | 4 | 2 |
| Addressing | CS pin per device | 7-bit in frame |
| Duplex | Full | Half |

---

## Next

Tutorial 02 covers the USCI_B0 I2C registers and master write/read sequences.
