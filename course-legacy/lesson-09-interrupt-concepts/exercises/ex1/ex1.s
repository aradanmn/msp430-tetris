;******************************************************************************
; Lesson 09 - Exercise 1: Your First ISR — WDT Interval Toggle
;
; WDT interval ISR toggles LED1 every ~32ms.
; Main sleeps in LPM0.
;******************************************************************************
#include "../../../common/msp430g2552-defs.s"

        .text
        .global main

main:
        ; TODO: Configure WDT in interval mode
        ;       mov.w #(WDTPW|WDTTMSEL|WDTCNTCL), &WDTCTL

        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        bis.b   #LED1, &P1DIR
        bic.b   #LED1, &P1OUT

        ; TODO: Enable WDT interrupt (bit 0 of IE1)
        ; TODO: Enable global interrupts (GIE)

main_loop:
        ; TODO: Enter LPM0 (bis.w #(GIE|CPUOFF), SR)
        nop
        jmp     main_loop

;----------------------------------------------------------------------
; WDT_ISR — called every ~32ms
; TODO: toggle LED1, save/restore any registers used, use RETI
;----------------------------------------------------------------------
WDT_ISR:
        ; TODO: implement
        reti    ; placeholder — RETI is correct (not RET)

;----------------------------------------------------------------------
; Vector table
;----------------------------------------------------------------------

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
