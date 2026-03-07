# Tutorial 14-2 · SPI Initialization and Data Transfer

## Initialization Sequence

```asm
; Pins: P1.5=CLK, P1.6=MISO(SOMI), P1.7=MOSI(SIMO)
.equ SPI_CLK,  BIT5
.equ SPI_SOMI, BIT6
.equ SPI_SIMO, BIT7

; Step 1: Hold USCI_B0 in reset
bis.b   #UCSWRST, &UCB0CTL1

; Step 2: Configure — SPI master, 8-bit, MSB-first, Mode 0 (CPOL=CPHA=0)
mov.b   #(UCMSB|UCMST|UCSYNC), &UCB0CTL0   ; = 0x29

; Step 3: Clock source = SMCLK (1 MHz)
mov.b   #(UCSSEL_2|UCSWRST), &UCB0CTL1

; Step 4: Baud rate = SMCLK / 4 = 250 kHz
mov.b   #4, &UCB0BR0
mov.b   #0, &UCB0BR1

; Step 5: Route pins to USCI_B0
bis.b   #(SPI_CLK|SPI_SOMI|SPI_SIMO), &P1SEL
bis.b   #(SPI_CLK|SPI_SOMI|SPI_SIMO), &P1SEL2

; Step 6: Release from reset
bic.b   #UCSWRST, &UCB0CTL1
```

---

## Chip Select (CS̄)

USCI_B0 in 3-wire SPI mode does **not** drive a CS pin automatically. Use any
spare GPIO:

```asm
.equ CS_PIN, BIT0   ; example: P2.0

; In setup:
bis.b   #CS_PIN, &P2DIR    ; output
bis.b   #CS_PIN, &P2OUT    ; deassert (CS̄ = 1 = idle)

; Before transfer:
bic.b   #CS_PIN, &P2OUT    ; assert CS̄ = 0

; After transfer:
bis.b   #CS_PIN, &P2OUT    ; deassert
```

---

## Sending a Byte (polling)

In SPI, transmitting and receiving happen simultaneously.  Write to TXBUF to
start a transfer; when done, RXBUF holds whatever the slave sent back.

```asm
; spi_transfer — send R12, receive into R12
; Clobbers: R12
spi_transfer:
        ; Wait until TXBUF is empty
_spi_tx_wait:
        bit.b   #UCB0TXIFG, &IFG2
        jz      _spi_tx_wait

        mov.b   R12, &UCB0TXBUF     ; load byte → starts clock

        ; Wait until receive buffer has the echoed byte
_spi_rx_wait:
        bit.b   #UCB0RXIFG, &IFG2
        jz      _spi_rx_wait

        mov.b   &UCB0RXBUF, R12     ; read received byte (clears flag)
        ret
```

Checking for RXIFG after writing TXBUF ensures one complete 8-clock cycle has
elapsed before proceeding — this is the correct way to pace SPI transfers.

---

## Multi-byte Transfer

For burst transfers (e.g., sending N bytes to a display):

```asm
; R14 = pointer to data, R13 = count
spi_send_buf:
        push    R12
_spi_buf_loop:
        tst.w   R13
        jz      _spi_buf_done
        mov.b   @R14+, R12
        call    #spi_transfer       ; discards received byte
        dec.w   R13
        jmp     _spi_buf_loop
_spi_buf_done:
        pop     R12
        ret
```

---

## Loopback Test

Connect P1.6 (MISO/SOMI) to P1.7 (MOSI/SIMO) with a wire. Every byte sent should
be received back unchanged.

```asm
        mov.b   #0xA5, R12
        call    #spi_transfer
        ; R12 should now be 0xA5 if loopback is wired
        cmp.b   #0xA5, R12
        jnz     fail_blink
```

---

## Next

Exercises apply these patterns: loopback verify, CS-controlled transfer, and
driving a 74HC595 shift register.
