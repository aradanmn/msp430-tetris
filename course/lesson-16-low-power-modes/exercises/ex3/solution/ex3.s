;******************************************************************************
; Lesson 16 - Exercise 3 SOLUTION: LPM0 + Timer_A Tick Scheduler
;******************************************************************************
#include "../../../../common/msp430g2552-defs.s"

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

        ; Timer_A: SMCLK/1, Up, 1ms tick
        mov.w   #999, &TACCR0
        mov.w   #CCIE, &TACCTL0
        mov.w   #(TASSEL_2|MC_1|TACLR), &TACTL

        bis.w   #GIE, SR

main_loop:
        bis.w   #(GIE|CPUOFF), SR       ; LPM0
        nop

        ; Task A: 250ms
        mov.w   &ms_tick, R12
        sub.w   &t_last_a, R12
        cmp.w   #250, R12
        jl      check_b
        xor.b   #LED1, &P1OUT
        mov.w   &ms_tick, &t_last_a

check_b:
        ; Task B: 1000ms
        mov.w   &ms_tick, R12
        sub.w   &t_last_b, R12
        cmp.w   #1000, R12
        jl      main_loop
        xor.b   #LED2, &P1OUT
        mov.w   &ms_tick, &t_last_b
        jmp     main_loop

TIMERA_ISR:
        inc.w   &ms_tick
        bic.w   #CPUOFF, 0(SP)
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
