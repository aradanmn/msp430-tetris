;******************************************************************************
; Lesson 09 - Exercise 2 SOLUTION: Flag Signaling
;******************************************************************************
#include "../../../../common/msp430g2552-defs.s"

        .data
wdt_ticks:  .word 0
flag:       .word 0

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTTMSEL|WDTCNTCL), &WDTCTL
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        bis.b   #LED1, &P1DIR
        bic.b   #LED1, &P1OUT
        bis.b   #0x01, &IE1
        bis.w   #GIE, SR

main_loop:
        bis.w   #(GIE|CPUOFF), SR
        nop

        tst.w   &flag
        jz      main_loop           ; not set, back to sleep

        clr.w   &flag               ; clear flag
        xor.b   #LED1, &P1OUT       ; do work
        jmp     main_loop

WDT_ISR:
        push    R15
        mov.w   &wdt_ticks, R15
        inc.w   R15
        cmp.w   #31, R15
        jlo     wdt_done
        clr.w   R15
        mov.w   #1, &flag           ; signal main
wdt_done:
        mov.w   R15, &wdt_ticks
        pop     R15
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
