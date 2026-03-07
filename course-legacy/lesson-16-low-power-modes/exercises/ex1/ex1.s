;******************************************************************************
; Lesson 16 - Exercise 1: LPM3 + WDT Interval ~1Hz Blink
;
; Configure ACLK from VLO, WDT interval mode, enter LPM3.
; WDT ISR toggles LED1 and exits LPM3.
;******************************************************************************
#include "../../../common/msp430g2552-defs.s"

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL

        ; No DCO needed for LPM3 blink
        ; (WDT uses ACLK which runs independently)

        bis.b   #LED1, &P1DIR
        bic.b   #LED1, &P1OUT

        ; TODO: set ACLK source to VLO
        ;   mov.b #LFXT1S_2, &BCSCTL3

        ; TODO: configure WDT interval mode with ACLK source
        ;   WDT period: ACLK/8192 ≈ 0.68s at VLO 12kHz
        ;   Bits: WDTPW | WDTTMSEL | WDTSSEL | WDTCNTCL | WDTIS1

        ; TODO: enable WDT interrupt (bis.b #WDTIE, &IE1)
        ; TODO: enable GIE

main_loop:
        ; TODO: enter LPM3
        ;   bis.w #(GIE|CPUOFF|SCG0|SCG1), SR
        nop
        jmp     main_loop

;----------------------------------------------------------------------
; WDT ISR — vector at 0xFFF6
;----------------------------------------------------------------------
WDT_ISR:
        ; TODO: toggle LED1
        ; TODO: exit LPM3 (bic.w #(CPUOFF|SCG0|SCG1), 0(SP))
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
