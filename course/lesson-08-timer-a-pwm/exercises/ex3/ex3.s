;******************************************************************************
; Lesson 08 - Exercise 3: 1kHz Tone (50% PWM)
;
; Generate a 1kHz square wave on P1.6 for a piezo buzzer.
; 1 second ON, 1 second OFF, repeating.
;******************************************************************************
#include "../../../common/msp430g2552-defs.s"

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        ; P1.6 → TA0.2
        bis.b   #LED2, &P1DIR
        bis.b   #LED2, &P1SEL
        bis.b   #LED2, &P1SEL2

        ; TODO: Configure 1kHz PWM
        ;   TACCR0 = 999  (1ms period at 1MHz SMCLK)
        ;   TACCR2 = 499  (50% duty cycle)
        ;   TACCTL2 = OUTMOD_7
        ;   TACTL = SMCLK | no divider | Up mode

tone_loop:
        ; TODO: Enable PWM output for 1 second
        ;       (write OUTMOD_7 to TACCTL2, set TACCR2=499)
        ;       Then delay 1000ms

        ; TODO: Disable PWM output for 1 second
        ;       (clear TACCTL2 output mode, e.g., mov.w #0, &TACCTL2)
        ;       Also drive pin low: bic.b #LED2, &P1OUT
        ;       Then delay 1000ms

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
