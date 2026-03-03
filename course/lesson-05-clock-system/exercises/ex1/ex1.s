;******************************************************************************
; Lesson 05 - Exercise 1: Accurate 2Hz Blink at 1MHz DCO
;
; Goal: blink LED1 at 2Hz (250ms on, 250ms off) using the factory-
; calibrated 1MHz DCO and a software delay loop.
;
; Key insight: at 1MHz, each CPU cycle = 1µs.
; 250ms = 250,000µs.  A two-instruction dec+jnz loop ≈ 2 cycles,
; so you need ~125,000 inner iterations per 250ms quarter-period.
; Since 125,000 > 65535, you must use nested loops.
;******************************************************************************
#include "../../../common/msp430g2552-defs.s"

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL

        ; Set DCO to calibrated 1MHz
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        ; Configure LED1 as output
        bis.b   #LED1, &P1DIR

loop:
        bis.b   #LED1, &P1OUT   ; LED1 ON
        call    #delay_250ms
        bic.b   #LED1, &P1OUT   ; LED1 OFF
        call    #delay_250ms
        jmp     loop

;----------------------------------------------------------------------
; delay_250ms — approximately 250ms at 1MHz MCLK
;
; TODO: Implement this subroutine.
; Hint: use two nested registers for outer and inner loops.
;       At 1MHz, 2 cycles per inner iteration → need ~125,000 total.
;       Outer loop of 2 × inner loop of 62,500 = 125,000 iterations.
;----------------------------------------------------------------------
delay_250ms:
        ; TODO: implement nested delay loop here

        ret     ; placeholder

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
