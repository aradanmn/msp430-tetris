;******************************************************************************
; Lesson 09 - Exercise 3 SOLUTION: Two ISRs Running Together
;******************************************************************************
#include "../../../../common/msp430g2552-defs.s"

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

        ; Timer_A: SMCLK/8=125kHz, 125ms period
        mov.w   #15624, &TACCR0
        mov.w   #CCIE, &TACCTL0
        mov.w   #(TASSEL_2|ID_3|MC_1|TACLR), &TACTL

        bis.b   #0x01, &IE1         ; WDTIE
        bis.w   #GIE, SR

main_loop:
        bis.w   #(GIE|CPUOFF), SR
        nop
        jmp     main_loop

WDT_ISR:
        push    R15
        mov.w   &wdt_ticks, R15
        inc.w   R15
        cmp.w   #31, R15
        jlo     wdt_done
        clr.w   R15
        xor.b   #LED1, &P1OUT
wdt_done:
        mov.w   R15, &wdt_ticks
        pop     R15
        reti

TIMERA_CC0_ISR:
        xor.b   #LED2, &P1OUT
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
        .word   TIMERA_CC0_ISR       ; 0xFFF4 - Timer_A CC0
        .word   WDT_ISR              ; 0xFFF6 - WDT
        .word   0                    ; 0xFFF8 - unused
        .word   0                    ; 0xFFFA - unused
        .word   0                    ; 0xFFFC - unused
        .word   main                 ; 0xFFFE - Reset
        .end
