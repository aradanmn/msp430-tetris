# Tutorial 13-2 · Transmit, Receive, and String Output

## Transmitting a Byte

Check `UCA0TXIFG` (bit 1) in `IFG2` before writing to `UCA0TXBUF`. The flag is 1
when the transmit buffer is empty and ready for new data.

```asm
; Send one byte (poll TXIFG)
; Input: R12 = byte to send
uart_putc:
wait_tx:
        bit.b   #UCA0TXIFG, &IFG2   ; test bit 1 of IFG2
        jz      wait_tx              ; loop until buffer empty
        mov.b   R12, &UCA0TXBUF     ; load byte → starts transmission
        ret
```

Writing to `UCA0TXBUF` automatically clears `UCA0TXIFG`.

---

## Transmitting a String

Point R14 at a null-terminated string in `.rodata`, call `uart_putc` for each
character until the null terminator is reached.

```asm
; Send null-terminated string
; Input: R14 = address of string
uart_puts:
        push    R12
_puts_loop:
        mov.b   @R14+, R12      ; load byte, advance pointer
        tst.b   R12             ; is it 0x00?
        jz      _puts_done
        call    #uart_putc
        jmp     _puts_loop
_puts_done:
        pop     R12
        ret
```

Place strings in the ROM section:

```asm
        .section ".rodata"
hello_str:
        .byte 'H','e','l','l','o','!','\r','\n',0
```

---

## Receiving a Byte (Polling)

`UCA0RXIFG` (bit 0 of `IFG2`) is set when a byte arrives in `UCA0RXBUF`. Reading
`UCA0RXBUF` automatically clears the flag.

```asm
; Wait for and return one received byte in R12
uart_getc:
wait_rx:
        bit.b   #UCA0RXIFG, &IFG2
        jz      wait_rx
        mov.b   &UCA0RXBUF, R12
        ret
```

---

## Receiving via ISR (Interrupt-Driven)

For non-blocking receive, enable the RX interrupt and handle it in an ISR.  The
USCI_A0 RX vector is at **0xFFEC**.

```asm
; In setup:
        bis.b   #UCA0RXIE, &IE2     ; enable USCI_A0 RX interrupt
        bis.w   #GIE, SR            ; global enable

; ISR:
USCI_RX_ISR:
        mov.b   &UCA0RXBUF, R12     ; read clears flag
        ; process R12 …
        reti

        .section ".vectors","ax",@progbits
        .org    0xFFEC
        .word   USCI_RX_ISR
        .org    0xFFFE
        .word   main
```

The MSP430G2552 combines USCI_A0/B0 RX at 0xFFEC and TX at 0xFFEE.

---

## Echo Example — Putting It Together

```asm
main:
        ; (WDT stop, DCO 1MHz, UART init omitted — see tutorial-01)

        mov.w   #hello_str, R14
        call    #uart_puts          ; send greeting

echo_loop:
        call    #uart_getc          ; block until char received
        call    #uart_putc          ; echo it back
        jmp     echo_loop
```

---

## IFG2 Quick Reference

| Symbol      | Bit | Set when…                              | Cleared by…         |
|-------------|-----|----------------------------------------|---------------------|
| UCA0RXIFG   | 0   | Byte received in RXBUF                 | Reading UCA0RXBUF   |
| UCA0TXIFG   | 1   | TXBUF empty (ready for next byte)      | Writing UCA0TXBUF   |
| UCB0RXIFG   | 2   | I2C/SPI byte received (Lesson 15)      | Reading UCB0RXBUF   |
| UCB0TXIFG   | 3   | I2C/SPI TX buffer empty (Lesson 15)    | Writing UCB0TXBUF   |

---

## Next

The example `uart_hello.s` sends a greeting and echoes received characters.
Exercises build a hex printer, interrupt-driven receiver, and a command
interpreter.
