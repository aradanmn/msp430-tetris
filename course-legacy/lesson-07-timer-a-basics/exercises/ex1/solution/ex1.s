;******************************************************************************
; Lesson 07 - Exercise 1 SOLUTION: Exact 1-Second Delay with Timer_A
;******************************************************************************
#include "../../../../common/msp430g2552-defs.s"

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        bis.b   #LED1, &P1DIR
        bic.b   #LED1, &P1OUT

        ; Timer: SMCLK/8 = 125kHz; Up mode; 500ms period
        mov.w   #62499, &TACCR0
        mov.w   #(TASSEL_2|ID_3|MC_1|TACLR), &TACTL

        mov.w   #2, R13             ; count 2×500ms = 1 second

loop:
wait:
        bit.w   #CCIFG, &TACCTL0
        jz      wait
        bic.w   #CCIFG, &TACCTL0   ; clear flag

        dec.w   R13
        jnz     loop               ; keep counting

        xor.b   #LED1, &P1OUT      ; 1 second elapsed → toggle
        mov.w   #2, R13            ; reset counter
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
