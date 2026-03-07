;******************************************************************************
; Lesson 12 - Exercise 3: External Analog Channel (A4 / P1.4)
;
; Read P1.4 as analog input.  Display result on LEDs:
;   < 256: both off
;   256-511: LED1 on
;   512-767: LED2 on
;   >= 768: both on
;
; To test: connect P1.4 to GND (0) or 3.3V (1023), or use a potentiometer.
;******************************************************************************
#include "../../../common/msp430g2552-defs.s"

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        bis.b   #(LED1|LED2), &P1DIR
        bic.b   #(LED1|LED2), &P1OUT

        ; Enable P1.4 as analog input (disable digital buffer)
        bis.b   #BIT4, &ADC10AE0

        ; TODO: Configure ADC10CTL1 for channel A4 (INCH_4), SMCLK, single
        ; TODO: Configure ADC10CTL0 for VCC reference (SREF_0), power on
        ;   Note: no REFON needed for SREF_0 (uses VCC as reference)

read_loop:
        ; TODO: start conversion, poll busy, read ADC10MEM

        ; TODO: update LEDs based on R12:
        ;   R12 < 256:   both off
        ;   R12 256-511: LED1 on, LED2 off
        ;   R12 512-767: LED1 off, LED2 on
        ;   R12 >= 768:  both on

        mov.w   #100, R12
        call    #delay_ms
        jmp     read_loop

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
