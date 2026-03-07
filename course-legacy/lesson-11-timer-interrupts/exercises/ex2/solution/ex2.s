;******************************************************************************
; Lesson 11 - Exercise 2 SOLUTION: Traffic Light Sequencer
;******************************************************************************
#include "../../../../common/msp430g2552-defs.s"

.equ    STATE_GREEN,    0
.equ    STATE_YELLOW,   1
.equ    STATE_RED,      2
.equ    DUR_GREEN,      5000
.equ    DUR_YELLOW,     1000
.equ    DUR_RED,        4000

        .data
ms_tick:    .word 0
t_state:    .word 0
state:      .word STATE_GREEN

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        bis.b   #(LED1|LED2), &P1DIR
        bic.b   #LED1, &P1OUT
        bis.b   #LED2, &P1OUT       ; start GREEN

        mov.w   #999, &TACCR0
        mov.w   #CCIE, &TACCTL0
        mov.w   #(TASSEL_2|ID_0|MC_1|TACLR), &TACTL
        bis.w   #GIE, SR

main_loop:
        bis.w   #(GIE|CPUOFF), SR
        nop

        ; elapsed = ms_tick - t_state
        mov.w   &ms_tick, R12
        sub.w   &t_state, R12

        mov.w   &state, R13

        ; Check duration for current state
        cmp.w   #STATE_GREEN, R13
        jne     chk_yellow
        cmp.w   #DUR_GREEN, R12
        jlo     main_loop
        jmp     next_state

chk_yellow:
        cmp.w   #STATE_YELLOW, R13
        jne     chk_red
        cmp.w   #DUR_YELLOW, R12
        jlo     main_loop
        jmp     next_state

chk_red:
        cmp.w   #DUR_RED, R12
        jlo     main_loop

next_state:
        ; Advance state (0→1→2→0)
        inc.w   R13
        cmp.w   #3, R13
        jlo     set_state
        clr.w   R13
set_state:
        mov.w   R13, &state
        mov.w   &ms_tick, &t_state  ; reset state timer

        ; Update LEDs
        bic.b   #(LED1|LED2), &P1OUT
        cmp.w   #STATE_GREEN, R13
        jne     chk_yled
        bis.b   #LED2, &P1OUT       ; GREEN
        jmp     main_loop
chk_yled:
        cmp.w   #STATE_YELLOW, R13
        jne     set_red
        bis.b   #(LED1|LED2), &P1OUT ; YELLOW (both)
        jmp     main_loop
set_red:
        bis.b   #LED1, &P1OUT       ; RED
        jmp     main_loop

TIMERA_CC0_ISR:
        push    R15
        inc.w   &ms_tick
        bic.w   #CPUOFF, 0(SP)
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
