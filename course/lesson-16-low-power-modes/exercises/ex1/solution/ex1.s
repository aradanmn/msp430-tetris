;******************************************************************************
; Lesson 16 - Exercise 1 SOLUTION: LPM3 + WDT Interval ~1Hz Blink
;******************************************************************************
#include "../../../../common/msp430g2552-defs.s"

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL

        bis.b   #LED1, &P1DIR
        bic.b   #LED1, &P1OUT

        ; ACLK = VLO (~12 kHz)
        mov.b   #LFXT1S_2, &BCSCTL3

        ; WDT interval: ACLK/8192 ≈ 0.68 s
        mov.w   #(WDTPW|WDTTMSEL|WDTSSEL|WDTCNTCL|WDTIS1), &WDTCTL
        bis.b   #WDTIE, &IE1
        bis.w   #GIE, SR

main_loop:
        bis.w   #(GIE|CPUOFF|SCG0|SCG1), SR    ; LPM3
        nop                                      ; executes after wake
        jmp     main_loop

WDT_ISR:
        xor.b   #LED1, &P1OUT
        bic.w   #(CPUOFF|SCG0|SCG1), 0(SP)     ; exit LPM3
        reti

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
        .word   WDT_ISR              ; 0xFFF6 - WDT
        .word   0                    ; 0xFFF8 - unused
        .word   0                    ; 0xFFFA - unused
        .word   0                    ; 0xFFFC - unused
        .word   main                 ; 0xFFFE - Reset
        .end
