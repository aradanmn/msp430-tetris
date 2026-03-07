;******************************************************************************
; Lesson 08 - Exercise 3 SOLUTION: 1kHz Tone
;******************************************************************************
#include "../../../../common/msp430g2552-defs.s"

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        bis.b   #LED2, &P1DIR
        bis.b   #LED2, &P1SEL
        bis.b   #LED2, &P1SEL2

        mov.w   #999, &TACCR0               ; 1kHz period
        mov.w   #499, &TACCR2               ; 50% duty
        mov.w   #(TASSEL_2|ID_0|MC_1|TACLR), &TACTL

tone_loop:
        ; Tone ON: enable OUTMOD_7
        mov.w   #OUTMOD_7, &TACCTL2
        mov.w   #1000, R12
        call    #delay_ms

        ; Tone OFF: disable output mode, drive pin low
        mov.w   #0, &TACCTL2
        bic.b   #LED2, &P1OUT
        mov.w   #1000, R12
        call    #delay_ms

        jmp     tone_loop

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
