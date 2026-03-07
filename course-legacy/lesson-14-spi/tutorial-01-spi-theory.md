# Tutorial 14-1 · SPI Theory and USCI_B0 Registers

## What Is SPI?

**Serial Peripheral Interface** is a synchronous, full-duplex bus with four
signals:

```
Master          Slave
  SCLK ──────► SCLK   (clock — master drives)
  MOSI ──────► MOSI   (Master-Out Slave-In)
  MISO ◄────── MISO   (Master-In Slave-Out)
  CS̄   ──────► CS̄     (chip select, active-low)
```

Unlike UART, SPI is **synchronous**: the master generates a clock and data is
sampled on a specific clock edge.  Only one slave is active at a time (CS̄ low
selects it).

---

## Clock Polarity and Phase (CPOL / CPHA)

| Mode | CPOL | CPHA | Clock idle | Sample on |
|------|------|------|-----------|-----------|
| 0    | 0    | 0    | LOW        | Rising edge |
| 1    | 0    | 1    | LOW        | Falling edge |
| 2    | 1    | 0    | HIGH       | Falling edge |
| 3    | 1    | 1    | HIGH       | Rising edge |

Most common devices use **Mode 0** (CPOL=0, CPHA=0).

---

## USCI_B0 SPI Registers

USCI_B0 is shared between SPI (this lesson) and I2C (Lesson 15). The operating
mode is selected by bits in UCB0CTL0.

| Register  | Address | Purpose |
|-----------|---------|---------|
| UCB0CTL0  | 0x0068  | Mode, CPOL, CPHA, MSB/LSB, master |
| UCB0CTL1  | 0x0069  | Clock source, UCSWRST |
| UCB0BR0   | 0x006A  | Baud rate divisor low byte |
| UCB0BR1   | 0x006B  | Baud rate divisor high byte |
| UCB0STAT  | 0x006D  | Status (UCBUSY, error flags) |
| UCB0RXBUF | 0x006E  | Received byte |
| UCB0TXBUF | 0x006F  | Byte to transmit |

**UCB0CTL0 bits for SPI master, Mode 0, MSB-first:**

| Bit(s) | Name    | Value | Meaning |
|--------|---------|-------|---------|
| 7      | UCCKPH  | 0     | Clock phase (CPHA=0) |
| 6      | UCCKPL  | 0     | Clock polarity (CPOL=0) |
| 5      | UCMSB   | 1     | MSB first |
| 4      | UC8BIT  | 0     | 8-bit data |
| 3      | UCMST   | 1     | Master mode |
| 2-1    | UCMODE  | 00    | SPI 3-wire (no STE pin) |
| 0      | UCSYNC  | 1     | Synchronous (SPI/I2C) |

So: `UCB0CTL0 = UCMSB | UCMST | UCSYNC` = `0b00101001` = `0x29`

---

## IFG2 Flags for USCI_B0

| Flag      | Bit | Meaning |
|-----------|-----|---------|
| UCB0RXIFG | 2   | Received byte ready in UCB0RXBUF |
| UCB0TXIFG | 3   | UCB0TXBUF empty — ready for next byte |

These share IFG2 with USCI_A0 (UCA0RXIFG bit 0, UCA0TXIFG bit 1).

---

## SPI vs UART vs I2C Quick Comparison

| Feature      | UART      | SPI        | I2C         |
|--------------|-----------|------------|-------------|
| Wires        | 2 (TX/RX) | 4+         | 2 (SDA/SCL) |
| Clock        | None (async) | Master  | Master      |
| Speed        | 115200 baud | MHz range | 100k/400k  |
| Multi-slave  | No        | One CS per slave | 127 addresses |
| Full-duplex  | Yes       | Yes        | No (half)   |

---

## Next

Tutorial 02 shows the initialization sequence and how to send/receive bytes.
