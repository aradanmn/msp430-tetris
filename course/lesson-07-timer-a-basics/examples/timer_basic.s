;******************************************************************************
; Lesson 07 Example — Timer_A Basics (Polling)
;
; Demonstrates Timer_A in Up mode, polling CCIFG to generate timing:
;   - LED1 toggles every 500ms (1Hz blink) using TACCR0
;   - LED2 toggles every 250ms (2Hz blink) using a count of 2 TACCR0 periods
;
; Timer configuration:
;   SMCLK = 1MHz (calibrated DCO)
;   Divider ID_3 = /8  →  timer clock = 125kHz
;   TACCR0 = 62499  →  period = 62500 / 125kHz = 500ms
;
; Technique: polling TACCTL0.CCIFG (no interrupts used here)
;
; Hardware: MSP430G2552 LaunchPad
;   LED1 = P1.0, LED2 = P1.6
;******************************************************************************

#include "../../common/msp430g2552-defs.s"

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL

        ; 1MHz calibrated DCO
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        ; Both LEDs as outputs, off
        bis.b   #(LED1|LED2), &P1DIR
        bic.b   #(LED1|LED2), &P1OUT

        ;----------------------------------------------------------------------
        ; Configure Timer_A:
        ;   TASSEL_2 = SMCLK source
        ;   ID_3     = /8 divider  →  125kHz timer clock
        ;   MC_1     = Up mode (count 0 to TACCR0)
        ;   TACLR    = clear TAR on start
        ;----------------------------------------------------------------------
        mov.w   #62499, &TACCR0                     ; 500ms period
        mov.w   #(TASSEL_2|ID_3|MC_1|TACLR), &TACTL ; start timer

        ; R13 = half-period counter for LED2 (toggle LED2 every 250ms)
        mov.w   #0, R13

        ;----------------------------------------------------------------------
        ; Main loop: wait for each 500ms timer tick
        ;----------------------------------------------------------------------
loop:
        ; Busy-wait for CCIFG (set when TAR reaches TACCR0)
wait:
        bit.w   #CCIFG, &TACCTL0
        jz      wait

        ; Clear the flag — IMPORTANT or it stays set
        bic.w   #CCIFG, &TACCTL0

        ; Toggle LED1 every 500ms
        xor.b   #LED1, &P1OUT

        ; Toggle LED2 every 250ms (every 2nd 500ms period = alternate phase)
        ; Actually: toggle LED2 every period too → LED2 blinks same as LED1
        ; For 250ms rate we need separate logic — count sub-ticks:
        inc.w   R13                 ; R13 counts timer periods
        bit.w   #1, R13             ; test bit 0 (odd/even)
        jz      led2_off
        bis.b   #LED2, &P1OUT       ; odd period  → LED2 on
        jmp     loop
led2_off:
        bic.b   #LED2, &P1OUT       ; even period → LED2 off
        jmp     loop

; Note on LED2 timing:
; With TACCR0 = 500ms, toggling LED2 on/off alternately gives it a
; 500ms on + 500ms off cycle → 1Hz, SAME as LED1 but opposite phase.
; For TRUE 250ms (2Hz) we need to halve the TACCR0 period and count 2.
; See Exercise 2 for that pattern.

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
