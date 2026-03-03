# Tutorial 13-1 · UART Basics

## What Is UART?

**Universal Asynchronous Receiver/Transmitter** sends data bit by bit over two
wires: TX (transmit) and RX (receive).  It is *asynchronous* — there is no
shared clock.  Both sides must agree on the same baud rate.

A UART frame (8-N-1 = 8 data bits, no parity, 1 stop bit):

```
Idle  Start  D0   D1   D2   D3   D4   D5   D6   D7  Stop  Idle
  1  |  0  | b0 | b1 | b2 | b3 | b4 | b5 | b6 | b7 |  1  |  1
```

The line idles HIGH.  Start bit = 0 (marks the beginning). Data LSB first.  Stop
bit = 1.  Total frame = 10 bits.

At 9600 baud: each bit = 1/9600 ≈ 104µs.  Full frame ≈ 1.04ms.

---

## LaunchPad UART Connection

The MSP430G2552 USCI_A0 connects to the emulator MCU on the LaunchPad:

```
MSP430 P1.1 (UCA0RXD) ──── Emulator ──── USB ──── PC /dev/ttyACM0
MSP430 P1.2 (UCA0TXD) ──── Emulator ──── USB ──── PC /dev/ttyACM0
```

On the host Linux VM:
```bash
picocom -b 9600 /dev/ttyACM0
# or
screen /dev/ttyACM0 9600
```

---

## USCI_A0 Registers (8-bit, 0x0060–0x0067)

| Register | Address | Purpose |
|----------|---------|---------|
| UCA0CTL0 | 0x0060 | Control 0 (mode, parity, data bits) |
| UCA0CTL1 | 0x0061 | Control 1 (clock source, software reset) |
| UCA0BR0 | 0x0062 | Baud rate low byte |
| UCA0BR1 | 0x0063 | Baud rate high byte |
| UCA0MCTL | 0x0064 | Modulation control |
| UCA0STAT | 0x0065 | Status |
| UCA0RXBUF | 0x0066 | Receive buffer (read to get received byte) |
| UCA0TXBUF | 0x0067 | Transmit buffer (write to send a byte) |

---

## Baud Rate Calculation

At SMCLK = 1MHz, for 9600 baud:

```
Divisor = 1,000,000 / 9600 = 104.17
UCA0BR0 = 104    (integer part)
UCA0BR1 = 0
UCA0MCTL = 0x02  (modulation to handle the 0.17 fractional part)
```

This is pre-computed from the MSP430 user guide Table 15-4.

---

## Configuration Sequence

```asm
; Step 1: Assert software reset (UCSWRST) before configuring
bis.b   #UCSWRST, &UCA0CTL1

; Step 2: Configure control registers
; UCA0CTL0 = 0x00 → 8-N-1 UART (all defaults: no parity, 8 bits, 1 stop)
mov.b   #0x00, &UCA0CTL0

; Step 3: Select clock source: SMCLK
mov.b   #UCSSEL_2, &UCA0CTL1   ; UCSWRST is still set (bit 0 stays)

; Wait — UCSSEL_2 is 0x80, but UCSWRST is 0x01 and we want both:
mov.b   #(UCSSEL_2|UCSWRST), &UCA0CTL1

; Step 4: Set baud rate
mov.b   #104, &UCA0BR0
mov.b   #0,   &UCA0BR1
mov.b   #0x02, &UCA0MCTL       ; UCBRS0: modulation stage 1

; Step 5: Route P1.1 and P1.2 to USCI_A0
bis.b   #(UART_RX|UART_TX), &P1SEL
bis.b   #(UART_RX|UART_TX), &P1SEL2

; Step 6: Release from reset (clear UCSWRST)
bic.b   #UCSWRST, &UCA0CTL1

; UART is now active
```

---

## Checking IFG2 Flags

| Flag | Bit | Meaning |
|------|-----|---------|
| UCA0RXIFG | 0x01 in IFG2 | A byte has been received and is in RXBUF |
| UCA0TXIFG | 0x02 in IFG2 | TXBUF is empty (ready to send next byte) |

On reset, `UCA0TXIFG` is already set (TXBUF is empty).

---

## Next

Tutorial 02 shows how to transmit a byte (polling TXIFG), receive a byte
(polling RXIFG or via ISR), and build a simple string output.
