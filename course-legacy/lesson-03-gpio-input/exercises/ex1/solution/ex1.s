;******************************************************************************
; Lesson 03 - Exercise 1 SOLUTION
;******************************************************************************
#include "../../../../common/msp430g2552-defs.s"

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        bis.b   #(LED1|LED2), &P1DIR
        bic.b   #BTN, &P1DIR
        bis.b   #BTN, &P1REN
        bis.b   #BTN, &P1OUT

loop:
        bit.b   #BTN, &P1IN             ; Test button
        jz      pressed                 ; Z=1 means bit was 0 (button pressed)

not_pressed:
        bic.b   #LED1, &P1OUT           ; LED1 OFF
        bis.b   #LED2, &P1OUT           ; LED2 ON
        jmp     loop

pressed:
        bis.b   #LED1, &P1OUT           ; LED1 ON
        bic.b   #LED2, &P1OUT           ; LED2 OFF
        jmp     loop

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
