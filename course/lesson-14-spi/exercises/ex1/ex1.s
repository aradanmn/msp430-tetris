;******************************************************************************
; Lesson 14 - Exercise 1: SPI Loopback Verification
;
; Wire P1.6 (MISO) to P1.7 (MOSI).
; Send test bytes 0x00, 0x01, 0x55, 0xAA, 0xFF.
; Blink LED1 on all-pass, LED2 on any failure.
;******************************************************************************
#include "../../../common/msp430g2552-defs.s"

        .equ    SPI_CLK,  BIT5
        .equ    SPI_SOMI, BIT6
        .equ    SPI_SIMO, BIT7

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        bis.b   #(LED1|LED2), &P1DIR
        bic.b   #(LED1|LED2), &P1OUT

        ; TODO: initialize USCI_B0 as SPI master
        ;   UCB0CTL0 = UCMSB|UCMST|UCSYNC
        ;   Clock = SMCLK/4
        ;   Route P1.5/6/7 to USCI_B0 (P1SEL + P1SEL2)

        ; Drain RXBUF
        mov.b   &UCB0RXBUF, R15

test_loop:
        ; TODO: send 0x00, verify receive = 0x00 (jump to fail if not)
        ; TODO: send 0x01, verify receive = 0x01
        ; TODO: send 0x55, verify receive = 0x55
        ; TODO: send 0xAA, verify receive = 0xAA
        ; TODO: send 0xFF, verify receive = 0xFF

        ; All passed — blink LED1
        bis.b   #LED1, &P1OUT
        mov.w   #200, R12
        call    #delay_ms
        bic.b   #LED1, &P1OUT
        mov.w   #200, R12
        call    #delay_ms
        jmp     test_loop

fail:
        bis.b   #LED2, &P1OUT
fail_loop:
        jmp     fail_loop

;----------------------------------------------------------------------
; spi_transfer — send R12, receive in R12
;----------------------------------------------------------------------
spi_transfer:
        ; TODO: poll UCB0TXIFG, write UCB0TXBUF, poll UCB0RXIFG, read UCB0RXBUF
        ret

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
