;******************************************************************************
; Lesson 09 - Exercise 3: Two ISRs Running Together
;
; WDT ISR (~1Hz) toggles LED1
; Timer_A CC0 ISR (4Hz, 125ms period) toggles LED2
; Main in LPM0
;******************************************************************************
#include "../../../common/msp430g2552-defs.s"

        .data
wdt_ticks: .word 0

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTTMSEL|WDTCNTCL), &WDTCTL
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        bis.b   #(LED1|LED2), &P1DIR
        bic.b   #(LED1|LED2), &P1OUT

        ; TODO: Configure Timer_A for 125ms period
        ;   SMCLK/8 = 125kHz; 125ms = 15625 ticks → TACCR0 = 15624
        ;   Enable CC0 interrupt: TACCTL0 = CCIE

        ; TODO: Enable WDT interrupt (IE1 bit 0)
        ; TODO: Enable global interrupts

main_loop:
        bis.w   #(GIE|CPUOFF), SR
        nop
        jmp     main_loop

;----------------------------------------------------------------------
; WDT_ISR — ~1Hz on LED1 (count 31 ticks × 32ms)
; TODO: implement
;----------------------------------------------------------------------
WDT_ISR:
        reti    ; placeholder

;----------------------------------------------------------------------
; TIMERA_CC0_ISR — 4Hz on LED2 (every 125ms)
; TODO: toggle LED2
;----------------------------------------------------------------------
TIMERA_CC0_ISR:
        reti    ; placeholder

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
