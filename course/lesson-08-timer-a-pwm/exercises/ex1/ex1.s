;******************************************************************************
; Lesson 08 - Exercise 1: Fixed 25% Duty Cycle PWM
;
; LED2 (P1.6) = hardware PWM at 500Hz, 25% duty cycle
; LED1 (P1.0) = 1Hz GPIO blink showing CPU is free
;******************************************************************************
#include "../../../common/msp430g2552-defs.s"

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        ; LED1 as GPIO output
        bis.b   #LED1, &P1DIR

        ; TODO: Route P1.6 to TA0.2 PWM output
        ;   Set P1DIR, P1SEL, P1SEL2 for BIT6

        ; TODO: Set TACCR0 for 500Hz (2ms period at 1MHz)
        ;   TACCR0 = 1999

        ; TODO: Set TACCR2 for 25% duty cycle
        ;   TACCR2 = 499

        ; TODO: Set TACCTL2 = OUTMOD_7

        ; TODO: Start Timer_A (SMCLK, no divider, Up mode)

loop:
        xor.b   #LED1, &P1OUT       ; toggle LED1 every 500ms
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
