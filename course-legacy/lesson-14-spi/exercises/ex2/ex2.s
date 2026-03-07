;******************************************************************************
; Lesson 14 - Exercise 2: SPI with GPIO Chip-Select, Multi-byte Transfer
;
; Use P2.0 as CS (active-low).
; Send 4-byte command sequence: 0x02, 0x00, 0x00, 0xAB every 500ms.
; Toggle LED1 each iteration.
;******************************************************************************
#include "../../../common/msp430g2552-defs.s"

        .equ    SPI_CLK,  BIT5
        .equ    SPI_SOMI, BIT6
        .equ    SPI_SIMO, BIT7
        .equ    SPI_CS,   BIT0      ; P2.0 = chip select

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        bis.b   #LED1, &P1DIR
        bic.b   #LED1, &P1OUT

        ; CS on P2.0 — output, start deasserted (high)
        bis.b   #SPI_CS, &P2DIR
        bis.b   #SPI_CS, &P2OUT

        ; TODO: init USCI_B0 SPI (same as ex1)

main_loop:
        ; TODO: assert CS (P2OUT &= ~SPI_CS)
        ; TODO: send 0x02, 0x00, 0x00, 0xAB (call spi_transfer for each)
        ; TODO: deassert CS (P2OUT |= SPI_CS)

        xor.b   #LED1, &P1OUT
        mov.w   #500, R12
        call    #delay_ms
        jmp     main_loop

;----------------------------------------------------------------------
; spi_transfer — send R12, discard received byte
;----------------------------------------------------------------------
spi_transfer:
        ; TODO
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
