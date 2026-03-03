;******************************************************************************
; Lesson 05 - Exercise 2 SOLUTION: MCLK Divide-by-8 Demo
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

        ; Part A: slow (MCLK = DCO/8 = 125kHz)
        mov.b   #DIVM_3, &BCSCTL2   ; divide MCLK by 8

        mov.w   #4, R13
slow_loop:
        bis.b   #LED1, &P1OUT
        call    #delay_250ms        ; actual delay ≈ 2000ms at 125kHz
        bic.b   #LED1, &P1OUT
        call    #delay_250ms
        dec.w   R13
        jnz     slow_loop

        ; Part B: fast (MCLK = DCO/1 = 1MHz)
        mov.b   #DIVM_0, &BCSCTL2   ; no divide

        mov.w   #8, R13
fast_loop:
        bis.b   #LED2, &P1OUT
        call    #delay_250ms        ; actual delay ≈ 250ms at 1MHz
        bic.b   #LED2, &P1OUT
        call    #delay_250ms
        dec.w   R13
        jnz     fast_loop

halt:   jmp     halt

delay_250ms:
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
