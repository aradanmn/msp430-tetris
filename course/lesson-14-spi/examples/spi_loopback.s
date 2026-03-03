;******************************************************************************
; Lesson 14 - Example: SPI Loopback Test
;
; Configures USCI_B0 as SPI master and sends test bytes.
; Wire P1.6 (MISO) to P1.7 (MOSI) for loopback.
;
; LED1 (P1.0) blinks on success, stays on steady on mismatch failure.
;
; SPI clock = SMCLK/4 = 250 kHz
;******************************************************************************
#include "../../common/msp430g2552-defs.s"

        .equ    SPI_CLK,  BIT5      ; P1.5 = UCB0CLK
        .equ    SPI_SOMI, BIT6      ; P1.6 = UCB0SOMI (MISO)
        .equ    SPI_SIMO, BIT7      ; P1.7 = UCB0SIMO (MOSI)

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL

        ; DCO = 1 MHz
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        bis.b   #(LED1|LED2), &P1DIR
        bic.b   #(LED1|LED2), &P1OUT

        ;------------------------------------------------------------------
        ; USCI_B0 SPI master init
        ;------------------------------------------------------------------
        bis.b   #UCSWRST, &UCB0CTL1
        mov.b   #(UCMSB|UCMST|UCSYNC), &UCB0CTL0   ; Mode 0, 8-bit, master
        mov.b   #(UCSSEL_2|UCSWRST), &UCB0CTL1      ; SMCLK
        mov.b   #4, &UCB0BR0                         ; /4 = 250 kHz
        mov.b   #0, &UCB0BR1
        bis.b   #(SPI_CLK|SPI_SOMI|SPI_SIMO), &P1SEL
        bis.b   #(SPI_CLK|SPI_SOMI|SPI_SIMO), &P1SEL2
        bic.b   #UCSWRST, &UCB0CTL1
        ;------------------------------------------------------------------

        ; Drain any stale RXBUF
        mov.b   &UCB0RXBUF, R15

test_loop:
        ; Send 0xA5 and verify loopback
        mov.b   #0xA5, R12
        call    #spi_transfer
        cmp.b   #0xA5, R12
        jnz     fail

        ; Send 0x5A and verify loopback
        mov.b   #0x5A, R12
        call    #spi_transfer
        cmp.b   #0x5A, R12
        jnz     fail

        ; Send 0xFF
        mov.b   #0xFF, R12
        call    #spi_transfer
        cmp.b   #0xFF, R12
        jnz     fail

        ; All passed — blink LED1
        bis.b   #LED1, &P1OUT
        mov.w   #200, R12
        call    #delay_ms
        bic.b   #LED1, &P1OUT
        mov.w   #200, R12
        call    #delay_ms
        jmp     test_loop

fail:
        ; Mismatch — both LEDs on, halt
        bis.b   #(LED1|LED2), &P1OUT
fail_loop:
        jmp     fail_loop

;----------------------------------------------------------------------
; spi_transfer — send R12, receive response in R12
; Full-duplex: TXBUF loaded, then poll RXIFG
;----------------------------------------------------------------------
spi_transfer:
_spi_tx_wait:
        bit.b   #UCB0TXIFG, &IFG2
        jz      _spi_tx_wait
        mov.b   R12, &UCB0TXBUF
_spi_rx_wait:
        bit.b   #UCB0RXIFG, &IFG2
        jz      _spi_rx_wait
        mov.b   &UCB0RXBUF, R12
        ret

;----------------------------------------------------------------------
; delay_ms — R12 = milliseconds (approx at 1 MHz)
;----------------------------------------------------------------------
delay_ms:
        mov.w   #250, R15
_d:     dec.w   R15
        jnz     _d
        dec.w   R12
        jnz     delay_ms
        ret

;==============================================================================
; Interrupt Vector Table  (16 entries × 2 bytes = 32 bytes at 0xFFE0-0xFFFF)
;==============================================================================
        .section ".vectors","ax",@progbits
        .word   0                    ; 0xFFE0 - unused
        .word   0                    ; 0xFFE2 - unused
        .word   0                    ; 0xFFE4 - Port 1
        .word   0                    ; 0xFFE6 - Port 2
        .word   0                    ; 0xFFE8 - unused
        .word   0                    ; 0xFFEA - ADC10
        .word   0                    ; 0xFFEC - USCI RX
        .word   0                    ; 0xFFEE - USCI TX
        .word   0                    ; 0xFFF0 - unused
        .word   0                    ; 0xFFF2 - Timer_A overflow
        .word   0                    ; 0xFFF4 - Timer_A CC0
        .word   0                    ; 0xFFF6 - WDT
        .word   0                    ; 0xFFF8 - unused
        .word   0                    ; 0xFFFA - unused
        .word   0                    ; 0xFFFC - unused
        .word   main                 ; 0xFFFE - Reset
        .end
