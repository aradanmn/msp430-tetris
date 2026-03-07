;******************************************************************************
; Lesson 11 - Exercise 1 SOLUTION: 1ms Tick, LED at 500ms
;******************************************************************************
#include "../../../../common/msp430g2552-defs.s"

        .data
ms_tick:    .word 0
t_last:     .word 0

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        bis.b   #LED1, &P1DIR
        bic.b   #LED1, &P1OUT

        mov.w   #999, &TACCR0
        mov.w   #CCIE, &TACCTL0
        mov.w   #(TASSEL_2|ID_0|MC_1|TACLR), &TACTL

        bis.w   #GIE, SR

main_loop:
        bis.w   #(GIE|CPUOFF), SR
        nop

        mov.w   &ms_tick, R12
        sub.w   &t_last, R12        ; elapsed
        cmp.w   #500, R12
        jlo     main_loop

        mov.w   &ms_tick, &t_last
        xor.b   #LED1, &P1OUT
        jmp     main_loop

TIMERA_CC0_ISR:
        push    R15
        inc.w   &ms_tick
        mov.w   &ms_tick, R15
        sub.w   &t_last, R15
        cmp.w   #500, R15
        jlo     cc0_done
        bic.w   #CPUOFF, 0(SP)
cc0_done:
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
        .word   TIMERA_CC0_ISR       ; 0xFFF4 - Timer_A CC0
        .word   0                    ; 0xFFF6 - WDT
        .word   0                    ; 0xFFF8 - unused
        .word   0                    ; 0xFFFA - unused
        .word   0                    ; 0xFFFC - unused
        .word   main                 ; 0xFFFE - Reset
        .end
