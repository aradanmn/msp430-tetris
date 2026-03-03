;******************************************************************************
; Lesson 16 - Exercise 2 SOLUTION: LPM4 + Button Wakeup
;******************************************************************************
#include "../../../../common/msp430g2552-defs.s"

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL

        ; After LPM4 exit, DCO starts at default slow speed.
        ; Recalibrate to 1MHz for accurate timing.
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        bis.b   #LED1, &P1DIR
        bic.b   #LED1, &P1OUT

        ; Button setup
        bic.b   #BTN, &P1DIR
        bis.b   #BTN, &P1REN
        bis.b   #BTN, &P1OUT
        bis.b   #BTN, &P1IES
        bic.b   #BTN, &P1IFG
        bis.b   #BTN, &P1IE

main_loop:
        bis.w   #(GIE|CPUOFF|SCG0|SCG1|OSCOFF), SR     ; LPM4
        nop

        ; Woken — DCO running again (calibrated above at startup)
        ; Brief blink
        bis.b   #LED1, &P1OUT
        mov.w   #200, R12
        call    #delay_ms
        bic.b   #LED1, &P1OUT

        ; Re-arm button
        bic.b   #BTN, &P1IFG
        bis.b   #BTN, &P1IE
        jmp     main_loop

PORT1_ISR:
        bic.b   #BTN, &P1IE         ; disable until main re-arms
        bic.b   #BTN, &P1IFG
        bic.w   #(CPUOFF|SCG0|SCG1|OSCOFF), 0(SP)
        reti

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
        .word   PORT1_ISR            ; 0xFFE4 - Port 1
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
