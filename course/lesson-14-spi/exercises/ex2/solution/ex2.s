;******************************************************************************
; Lesson 14 - Exercise 2 SOLUTION: SPI with GPIO CS, Multi-byte Transfer
;******************************************************************************
#include "../../../../common/msp430g2552-defs.s"

        .equ    SPI_CLK,  BIT5
        .equ    SPI_SOMI, BIT6
        .equ    SPI_SIMO, BIT7
        .equ    SPI_CS,   BIT0      ; P2.0

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        bis.b   #LED1, &P1DIR
        bic.b   #LED1, &P1OUT

        bis.b   #SPI_CS, &P2DIR
        bis.b   #SPI_CS, &P2OUT     ; CS deasserted

        ; USCI_B0 SPI master
        bis.b   #UCSWRST, &UCB0CTL1
        mov.b   #(UCMSB|UCMST|UCSYNC), &UCB0CTL0
        mov.b   #(UCSSEL_2|UCSWRST), &UCB0CTL1
        mov.b   #4, &UCB0BR0
        mov.b   #0, &UCB0BR1
        bis.b   #(SPI_CLK|SPI_SOMI|SPI_SIMO), &P1SEL
        bis.b   #(SPI_CLK|SPI_SOMI|SPI_SIMO), &P1SEL2
        bic.b   #UCSWRST, &UCB0CTL1
        mov.b   &UCB0RXBUF, R15     ; drain

main_loop:
        ; Assert CS
        bic.b   #SPI_CS, &P2OUT

        ; Send 4-byte transaction: WRITE cmd, addr_hi, addr_lo, data
        mov.b   #0x02, R12
        call    #spi_transfer
        mov.b   #0x00, R12
        call    #spi_transfer
        mov.b   #0x00, R12
        call    #spi_transfer
        mov.b   #0xAB, R12
        call    #spi_transfer

        ; Deassert CS
        bis.b   #SPI_CS, &P2OUT

        xor.b   #LED1, &P1OUT
        mov.w   #500, R12
        call    #delay_ms
        jmp     main_loop

;----------------------------------------------------------------------
; spi_transfer — send R12, receive in R12
;----------------------------------------------------------------------
spi_transfer:
_tx:    bit.b   #UCB0TXIFG, &IFG2
        jz      _tx
        mov.b   R12, &UCB0TXBUF
_rx:    bit.b   #UCB0RXIFG, &IFG2
        jz      _rx
        mov.b   &UCB0RXBUF, R12
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
