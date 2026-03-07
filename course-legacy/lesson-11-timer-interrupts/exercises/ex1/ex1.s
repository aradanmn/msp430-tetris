;******************************************************************************
; Lesson 11 - Exercise 1: 1ms Tick, LED at 500ms
;
; Timer_A CC0 ISR increments ms_tick every 1ms.
; Main wakes, checks if 500ms elapsed, toggles LED1, back to sleep.
;******************************************************************************
#include "../../../common/msp430g2552-defs.s"

        .data
ms_tick:    .word 0
t_last:     .word 0

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        bis.b   #LED1, &P1DIR
        bic.b   #LED1, &P1OUT

        ; TODO: Configure Timer_A for 1ms CC0 interrupt
        ;   TACCR0 = 999, TACCTL0 = CCIE
        ;   TACTL = SMCLK | no divider | Up mode

        bis.w   #GIE, SR

main_loop:
        bis.w   #(GIE|CPUOFF), SR  ; sleep
        nop

        ; TODO: check if 500ms have elapsed
        ;   elapsed = ms_tick - t_last
        ;   if elapsed < 500: go back to sleep
        ;   if elapsed >= 500: update t_last, toggle LED1

        jmp     main_loop

;----------------------------------------------------------------------
; TIMERA_CC0_ISR
; TODO: increment ms_tick, wake main if 500ms are due
;----------------------------------------------------------------------
TIMERA_CC0_ISR:
        reti    ; placeholder

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
