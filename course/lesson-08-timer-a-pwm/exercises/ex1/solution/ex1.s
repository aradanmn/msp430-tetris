;******************************************************************************
; Lesson 08 - Exercise 1 SOLUTION: Fixed 25% Duty Cycle PWM
;******************************************************************************
#include "../../../../common/msp430g2552-defs.s"

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        bis.b   #LED1, &P1DIR           ; LED1 GPIO

        bis.b   #LED2, &P1DIR           ; P1.6 output
        bis.b   #LED2, &P1SEL           ; P1SEL[6]=1
        bis.b   #LED2, &P1SEL2          ; P1SEL2[6]=1 → TA0.2

        mov.w   #1999, &TACCR0          ; 500Hz: 2000 ticks at 1MHz
        mov.w   #499,  &TACCR2          ; 25%:   500/2000 = 25%
        mov.w   #OUTMOD_7, &TACCTL2     ; Reset/Set PWM
        mov.w   #(TASSEL_2|ID_0|MC_1|TACLR), &TACTL

loop:
        xor.b   #LED1, &P1OUT
        mov.w   #500, R12
        call    #delay_ms
        jmp     loop

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
