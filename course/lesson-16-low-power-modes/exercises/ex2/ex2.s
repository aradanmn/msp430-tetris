;******************************************************************************
; Lesson 16 - Exercise 2: LPM4 + Button Wakeup
;
; Enter deepest sleep (LPM4 — everything off).
; Button press (P1.3 falling edge) wakes CPU, blinks LED1, returns to LPM4.
;******************************************************************************
#include "../../../common/msp430g2552-defs.s"

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL

        bis.b   #LED1, &P1DIR
        bic.b   #LED1, &P1OUT

        ; Button: input, pull-up, falling edge interrupt
        bic.b   #BTN, &P1DIR
        bis.b   #BTN, &P1REN
        bis.b   #BTN, &P1OUT
        bis.b   #BTN, &P1IES        ; falling edge
        bic.b   #BTN, &P1IFG
        bis.b   #BTN, &P1IE

main_loop:
        ; TODO: enter LPM4
        ;   bis.w #(GIE|CPUOFF|SCG0|SCG1|OSCOFF), SR
        nop

        ; Woken by PORT1_ISR — blink LED1 once
        ; Note: DCO needs time to stabilize after LPM4 exit
        ; TODO: brief blink (LED1 on, delay, LED1 off)
        ; TODO: re-enable button interrupt if disabled in ISR
        jmp     main_loop

;----------------------------------------------------------------------
; PORT1 ISR
;----------------------------------------------------------------------
PORT1_ISR:
        ; TODO: clear P1IFG for BTN
        ; TODO: exit LPM4 (bic.w #(CPUOFF|SCG0|SCG1|OSCOFF), 0(SP))
        reti

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
