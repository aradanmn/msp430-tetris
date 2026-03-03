# Lesson 14 Exercises — SPI

> **Hardware note:** P1.6 is shared with LED2 on the LaunchPad. > Disconnect or
remove the LED2 jumper when using SPI.

---

## Exercise 1 · SPI Loopback Verification

**File:** `ex1/ex1.s`

Send a sequence of test patterns over SPI and verify the loopback:

1. Wire P1.6 (MISO) to P1.7 (MOSI) with a jumper wire.
2. Send each byte in the sequence: `0x00, 0x01, 0x55, 0xAA, 0xFF`
3. After each send, compare the received byte to the sent byte.
4. If all match: blink LED1 continuously.
5. If any mismatch: turn on LED2 and halt.

**Extend it:** use the `uart_puts` pattern from Lesson 13 to print "PASS" or
"FAIL" over UART as well.

---

## Exercise 2 · SPI with Chip-Select, Multi-byte Transfer

**File:** `ex2/ex2.s`

Simulate a multi-byte SPI transaction with a GPIO chip-select:

- Use P2.0 as the CS̄ pin (output, active-low).
- Send a 4-byte "command + data" sequence: `0x02, 0x00, 0x00, 0xAB` (simulating
  a write command to address 0x0000 with data 0xAB).
- Assert CS̄ (low) before the first byte, deassert (high) after the last.
- Repeat the transaction every 500 ms (use `delay_ms`).
- Toggle LED1 each iteration.

**Note:** Without a real slave device, use loopback to observe the bus.

---

## Exercise 3 · Drive a 74HC595 Shift Register

**File:** `ex3/ex3.s`

The 74HC595 is an 8-bit serial-in/parallel-out shift register, controlled by SPI
(CPOL=0, CPHA=0, MSB-first) with a separate latch (RCLK) pin:

```
MSP430 P1.5 (CLK)  ──► 74HC595 SRCLK
MSP430 P1.7 (MOSI) ──► 74HC595 SER
MSP430 P2.0         ──► 74HC595 RCLK  (latch)
MSP430 P2.1         ──► 74HC595 /OE   (output enable, tie low)
```

Sequence to display a byte:
1. Assert latch (RCLK) low.
2. SPI-send the byte (MSB first).
3. Pulse RCLK high then low — this transfers shift register to outputs.

Write a `shift_out` subroutine and cycle through the patterns: `0x01, 0x02,
0x04, 0x08, 0x10, 0x20, 0x40, 0x80` (knight-rider), with 100 ms between each.

**If you don't have a 74HC595:** substitute an LED bar graph or just run in
loopback and print each pattern over UART.
