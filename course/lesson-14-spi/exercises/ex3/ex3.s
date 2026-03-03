;******************************************************************************
; Lesson 14 - Exercise 3: Drive a 74HC595 Shift Register
;
; Connections:
;   P1.5 (CLK)  → 74HC595 SRCLK
;   P1.7 (MOSI) → 74HC595 SER
;   P2.0        → 74HC595 RCLK  (latch)
;   P2.1        → 74HC595 /OE   (tie to GND for always-enabled)
;
; Cycle through knight-rider pattern on 8 outputs with 100ms delay.
;******************************************************************************
#include "../../../common/msp430g2552-defs.s"

        .equ    SPI_CLK,  BIT5
        .equ    SPI_SOMI, BIT6
        .equ    SPI_SIMO, BIT7
        .equ    HC595_LATCH, BIT0   ; P2.0 = RCLK

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        ; Latch pin on P2.0
        bis.b   #HC595_LATCH, &P2DIR
        bic.b   #HC595_LATCH, &P2OUT

        ; TODO: init USCI_B0 SPI master (same as ex1/ex2)

main_loop:
        ; TODO: send knight-rider pattern using shift_out
        ; Pattern: 0x01 → 0x02 → 0x04 → ... → 0x80 → 0x40 → ... → 0x02
        ; Each step: call shift_out, delay 100ms

        jmp     main_loop

;----------------------------------------------------------------------
; shift_out — send R12 to 74HC595 and latch output
; 1. Assert latch low
; 2. SPI transfer the byte
; 3. Pulse latch high then low
;----------------------------------------------------------------------
shift_out:
        ; TODO
        ret

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
