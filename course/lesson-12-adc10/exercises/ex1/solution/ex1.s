;******************************************************************************
; Lesson 12 - Exercise 1 SOLUTION: Busy-Wait ADC Read
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

        mov.w   #(INCH_10|ADC10SSEL_3|CONSEQ_0), &ADC10CTL1
        mov.w   #(SREF_1|ADC10SHT_3|REFON|ADC10ON), &ADC10CTL0

        mov.w   #1000, R15
ref_wait: dec.w R15
          jnz   ref_wait

read_loop:
        bis.w   #(ENC|ADC10SC), &ADC10CTL0
adc_busy:
        bit.w   #ADC10BUSY, &ADC10CTL1
        jnz     adc_busy
        mov.w   &ADC10MEM, R12
        bic.w   #ENC, &ADC10CTL0

        xor.b   #LED2, &P1OUT

        cmp.w   #512, R12
        jlo     led1_off
        bis.b   #LED1, &P1OUT
        jmp     next
led1_off:
        bic.b   #LED1, &P1OUT
next:
        mov.w   #250, R12
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
