;******************************************************************************
; Lesson 16 - Exercise 3: LPM0 + Timer_A Tick Scheduler
;
; Timer_A CC0 at 1ms (1MHz SMCLK, TACCR0=999).
; ISR increments ms_tick and wakes main (LPM0).
; Main dispatches two tasks:
;   Task A: toggle LED1 every 250ms
;   Task B: toggle LED2 every 1000ms
;******************************************************************************
#include "../../../common/msp430g2552-defs.s"

        .data
ms_tick:    .word   0
t_last_a:   .word   0
t_last_b:   .word   0

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        bis.b   #(LED1|LED2), &P1DIR
        bic.b   #(LED1|LED2), &P1OUT

        ; TODO: Timer_A CC0 at 1ms
        ;   SMCLK/1, Up mode, TACCR0=999, CCIE enabled

        ; TODO: enable GIE

main_loop:
        ; TODO: enter LPM0 (bis.w #(GIE|CPUOFF), SR)
        nop

        ; Check Task A (250ms)
        ; TODO: elapsed_a = ms_tick - t_last_a
        ;       if elapsed_a >= 250: toggle LED1, t_last_a = ms_tick

        ; Check Task B (1000ms)
        ; TODO: elapsed_b = ms_tick - t_last_b
        ;       if elapsed_b >= 1000: toggle LED2, t_last_b = ms_tick

        jmp     main_loop

;----------------------------------------------------------------------
; Timer_A CC0 ISR
;----------------------------------------------------------------------
TIMERA_ISR:
        ; TODO: increment ms_tick
        ; TODO: exit LPM0 (bic.w #CPUOFF, 0(SP))
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
        .word   TIMERA_ISR           ; 0xFFF4 - Timer_A CC0
        .word   0                    ; 0xFFF6 - WDT
        .word   0                    ; 0xFFF8 - unused
        .word   0                    ; 0xFFFA - unused
        .word   0                    ; 0xFFFC - unused
        .word   main                 ; 0xFFFE - Reset
        .end
