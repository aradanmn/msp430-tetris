;******************************************************************************
; Lesson 11 - Exercise 2: Traffic Light Sequencer
;
; States: GREEN(5s) → YELLOW(1s) → RED(4s) → GREEN ...
; LED2=green, LED1=red, both=yellow (simulated)
;******************************************************************************
#include "../../../common/msp430g2552-defs.s"

.equ    STATE_GREEN,    0
.equ    STATE_YELLOW,   1
.equ    STATE_RED,      2

.equ    DUR_GREEN,      5000
.equ    DUR_YELLOW,     1000
.equ    DUR_RED,        4000

        .data
ms_tick:    .word 0
t_state:    .word 0     ; ms_tick at state entry
state:      .word 0     ; current state (0=green,1=yellow,2=red)

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        bis.b   #(LED1|LED2), &P1DIR
        bic.b   #(LED1|LED2), &P1OUT

        ; Start in GREEN state
        bis.b   #LED2, &P1OUT
        mov.w   #STATE_GREEN, &state

        mov.w   #999, &TACCR0
        mov.w   #CCIE, &TACCTL0
        mov.w   #(TASSEL_2|ID_0|MC_1|TACLR), &TACTL
        bis.w   #GIE, SR

main_loop:
        bis.w   #(GIE|CPUOFF), SR
        nop

        ; TODO: compute elapsed = ms_tick - t_state
        ; TODO: load current state
        ; TODO: check if elapsed >= state duration
        ; TODO: if yes: transition to next state, update LEDs, update t_state

        jmp     main_loop

;----------------------------------------------------------------------
; transition_state — advance to next traffic light state
; (You may implement this as part of main_loop instead)
;----------------------------------------------------------------------
; Hint: next state = (current + 1) % 3

TIMERA_CC0_ISR:
        push    R15
        inc.w   &ms_tick
        bic.w   #CPUOFF, 0(SP)     ; wake main every ms (simple approach)
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
