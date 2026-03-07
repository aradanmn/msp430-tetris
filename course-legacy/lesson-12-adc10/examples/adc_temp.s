;******************************************************************************
; Lesson 12 Example — ADC10 Internal Temperature Sensor
;
; Reads the internal temperature sensor every 500ms.
; LED1 turns ON if temperature reading exceeds WARM_THRESHOLD counts.
; LED2 blinks every reading to show program is alive.
;
; ADC configuration:
;   Channel: A10 (internal temperature sensor)
;   Reference: 1.5V internal (SREF_1 + REFON)
;   Sample time: 64 ADC10CLK cycles (ADC10SHT_3) — required for temp sensor
;   Mode: single channel, single conversion (CONSEQ_0)
;   Clock: SMCLK (ADC10SSEL_3)
;
; Hardware: MSP430G2552 LaunchPad
;   LED1 = P1.0  (on = above WARM_THRESHOLD)
;   LED2 = P1.6  (blinks every reading)
;******************************************************************************

#include "../../common/msp430g2552-defs.s"

; Temperature threshold: approximate room temperature + a few degrees
; At 1.5V ref, 25°C ≈ 733 counts.  Threshold at 760 ≈ ~27°C
.equ    WARM_THRESHOLD, 760

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL

        ; 1MHz calibrated DCO
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        ; LEDs as outputs
        bis.b   #(LED1|LED2), &P1DIR
        bic.b   #(LED1|LED2), &P1OUT

        ;----------------------------------------------------------------------
        ; Configure ADC10 for internal temperature sensor
        ;----------------------------------------------------------------------
        ; CTL1: channel A10, SMCLK, single conversion
        mov.w   #(INCH_10|ADC10SSEL_3|CONSEQ_0), &ADC10CTL1

        ; CTL0: 1.5V internal ref, 64-cycle sample, power on
        mov.w   #(SREF_1|ADC10SHT_3|REFON|ADC10ON), &ADC10CTL0

        ; Wait for internal reference to stabilize (~30µs at 1MHz)
        mov.w   #1000, R15
ref_settle:
        dec.w   R15
        jnz     ref_settle

        ;----------------------------------------------------------------------
        ; Main sampling loop
        ;----------------------------------------------------------------------
measure_loop:
        ; Trigger conversion: set ENC then ADC10SC
        bis.w   #(ENC|ADC10SC), &ADC10CTL0

        ; Wait for conversion to complete
adc_wait:
        bit.w   #ADC10BUSY, &ADC10CTL1
        jnz     adc_wait

        ; Read result
        mov.w   &ADC10MEM, R12         ; R12 = 0-1023

        ; Clear ENC before next conversion (for single-conversion mode)
        bic.w   #ENC, &ADC10CTL0

        ; Toggle LED2 to indicate a reading was taken
        xor.b   #LED2, &P1OUT

        ; Compare against threshold
        cmp.w   #WARM_THRESHOLD, R12
        jlo     below_threshold

        ; Above threshold: LED1 on
        bis.b   #LED1, &P1OUT
        jmp     wait_next

below_threshold:
        ; Below threshold: LED1 off
        bic.b   #LED1, &P1OUT

wait_next:
        ; Wait 500ms before next reading
        mov.w   #500, R12
        call    #delay_ms
        jmp     measure_loop

;----------------------------------------------------------------------
; delay_ms — software delay
; Input: R12 = ms  (clobbers R12, R15)
;----------------------------------------------------------------------
delay_ms:
        mov.w   #250, R15
_d:     dec.w   R15
        jnz     _d
        dec.w   R12
        jnz     delay_ms
        ret

        ; Reset vector

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
