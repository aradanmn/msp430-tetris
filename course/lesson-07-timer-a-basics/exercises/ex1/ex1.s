;******************************************************************************
; Lesson 07 - Exercise 1: Exact 1-Second Delay with Timer_A
;
; Timer_A Up mode, polling CCIFG.  Toggle LED1 every 1 second.
; No delay loops — timing from timer only.
;******************************************************************************
#include "../../../common/msp430g2552-defs.s"

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        bis.b   #LED1, &P1DIR
        bic.b   #LED1, &P1OUT

        ; TODO: Set TACCR0 for 500ms period (SMCLK=1MHz, divider /8)
        ;       Timer clock = 125kHz → 500ms = 62500 ticks → TACCR0 = 62499

        ; TODO: Start Timer_A in Up mode with SMCLK, /8 divider
        ;       mov.w #(TASSEL_2|ID_3|MC_1|TACLR), &TACTL

        ; R13 = period counter: count 2 timer periods = 1 second
        mov.w   #2, R13

loop:
        ; TODO: wait for CCIFG flag in TACCTL0
        ; TODO: clear CCIFG after detecting it
        ; TODO: decrement R13; if not zero, loop back to wait
        ;       if zero: toggle LED1, reset R13 to 2

halt:   jmp     halt    ; placeholder — remove once loop is implemented

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
