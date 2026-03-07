# Lesson 13 Exercises — UART

These exercises build from single-byte polling to interrupt-driven receive and a
simple command interpreter.  Use `picocom -b 9600 /dev/ttyACM0` (or `screen
/dev/ttyACM0 9600`) to interact with the LaunchPad.

---

## Exercise 1 · Hex Byte Printer

**File:** `ex1/ex1.s`

Modify `uart_hello.s` so that instead of echoing received bytes as raw
characters, it prints each received byte as **two hexadecimal digits** followed
by a space.  For example, typing `A` (0x41) should output `41 `.

**Approach:**
1. Receive a byte into R12.
2. Extract the high nibble: `R13 = (R12 >> 4) & 0x0F`
3. Extract the low nibble:  `R14 = R12 & 0x0F`
4. Convert each nibble to ASCII: if nibble < 10 → add `'0'`, else add `'A'-10`
5. Send high-nibble char, low-nibble char, space.

Write a helper subroutine `nibble_to_ascii` that takes a nibble (0–15) in R12
and returns the ASCII character in R12.

---

## Exercise 2 · Interrupt-Driven Echo

**File:** `ex2/ex2.s`

Replace the polled `uart_getc` with an **RX interrupt ISR**:

- In the ISR, read `UCA0RXBUF` into a global byte variable `rx_char`.
- Set a flag byte `rx_ready` to 1.
- In `main_loop`, sleep in LPM0 (`bis.w #(GIE|CPUOFF), SR`).
- When woken by the ISR, if `rx_ready` is set: echo the char, clear the flag.

The USCI_A0 RX vector is at **0xFFEC**. Enable the interrupt with `bis.b
#UCA0RXIE, &IE2`.

**Key insight:** The ISR must exit LPM0 by clearing CPUOFF in the saved SR:
`bic.w #CPUOFF, 0(SP)` — executed inside the ISR before `reti`.

---

## Exercise 3 · Command Interpreter

**File:** `ex3/ex3.s`

Build a single-character command interpreter over UART:

| Key pressed | Action |
|-------------|--------|
| `1`         | Turn LED1 ON, send "LED1 ON\r\n" |
| `0`         | Turn LED1 OFF, send "LED1 OFF\r\n" |
| `t`         | Toggle LED1, send "TOGGLE\r\n" |
| `?`         | Send "Commands: 0 1 t ?\r\n" |
| anything else | Send "?\r\n" |

Use the interrupt-driven RX approach from Exercise 2.  Keep the ISR minimal —
just store the byte and wake `main`.

**Challenge:** Use a `.section ".rodata"` table of strings and a computed branch
(`add.w R12, PC` or `br.w`) if you want to avoid a long chain of `cmp`/`jz`
instructions.
