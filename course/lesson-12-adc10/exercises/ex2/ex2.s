;******************************************************************************
; Lesson 12 - Exercise 2: Temperature Threshold Alarm
;
; If reading > WARM_THRESHOLD: LED1 on, LED2 blinks fast
; Otherwise: LED1 off, LED2 blinks slow
;******************************************************************************
#include "../../../common/msp430g2552-defs.s"

.equ    WARM_THRESHOLD, 780     ; adjust based on your room temperature

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

measure_loop:
        bis.w   #(ENC|ADC10SC), &ADC10CTL0
adc_busy:
        bit.w   #ADC10BUSY, &ADC10CTL1
        jnz     adc_busy
        mov.w   &ADC10MEM, R12
        bic.w   #ENC, &ADC10CTL0

        ; TODO: compare R12 with WARM_THRESHOLD
        ; TODO: if above: LED1 on, blink LED2 fast (5 times at 100ms)
        ; TODO: if below: LED1 off, single slow LED2 blink (500ms)

        jmp     measure_loop

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
