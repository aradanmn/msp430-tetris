;******************************************************************************
; Lesson 05 - Exercise 3 SOLUTION: Two-Speed Alternating Blink
;******************************************************************************
#include "../../../../common/msp430g2552-defs.s"

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        bis.b   #(LED1|LED2), &P1DIR
        bic.b   #(LED1|LED2), &P1OUT

loop:
        ; Fast: MCLK = 1MHz (delay_fixed ≈ 250ms)
        mov.b   #DIVM_0, &BCSCTL2

        mov.w   #4, R13
fast_phase:
        bis.b   #LED1, &P1OUT
        call    #delay_fixed
        bic.b   #LED1, &P1OUT
        call    #delay_fixed
        dec.w   R13
        jnz     fast_phase

        ; Slow: MCLK = 125kHz (delay_fixed ≈ 2000ms)
        mov.b   #DIVM_3, &BCSCTL2

        mov.w   #4, R13
slow_phase:
        bis.b   #LED2, &P1OUT
        call    #delay_fixed
        bic.b   #LED2, &P1OUT
        call    #delay_fixed
        dec.w   R13
        jnz     slow_phase

        jmp     loop

delay_fixed:
        mov.w   #2, R14
_outer:
        mov.w   #62500, R15
_inner:
        dec.w   R15
        jnz     _inner
        dec.w   R14
        jnz     _outer
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
