# Lesson 13 · UART Communication (USCI_A0)

## What You'll Learn

- How UART serial communication works (baud rate, 8-N-1 frame)
- How to configure USCI_A0 for 9600 baud UART at 1MHz
- How to transmit a byte and a string from the MSP430
- How to receive a byte and echo it back
- Using the LaunchPad's built-in USB-UART bridge

## Why This Matters

UART is the universal debug interface for embedded systems.  On the LaunchPad,
the MSP430's P1.1/P1.2 connect through the emulator chip to a USB-UART bridge —
your terminal (minicom, screen, picocom) sees it as a serial port at
`/dev/ttyACM0`.

## Goals

1. Configure USCI_A0 for 9600 baud, 8-N-1, SMCLK=1MHz
2. Send a string "Hello!\r\n" to the terminal
3. Echo received characters back (uppercase if lowercase)
4. Build a minimal command interface (press 'T' to print temperature)

## Tutorials

| File | Topic |
|------|-------|
| `tutorial-01-uart-basics.md` | UART framing, USCI_A0 registers, baud rate |
| `tutorial-02-tx-rx.md` | Sending bytes, polling TXIFG, receiving with RXIFG ISR |

## Example

```
examples/
└── uart_hello.s   ← Sends "Hello!\r\n" then echoes received characters
```

Connect your terminal: `picocom -b 9600 /dev/ttyACM0`

## Exercises

| Exercise | Task |
|----------|------|
| ex1 | Transmit a string character by character |
| ex2 | Echo: receive a byte, send it back uppercase |
| ex3 | Command interface: 'T'=print temp, 'L'=toggle LED, '?'=help |

## Capstone Connection

The capstone UART module sends temperature readings as formatted ASCII strings
every second.  This lesson gives you that exact skill.
