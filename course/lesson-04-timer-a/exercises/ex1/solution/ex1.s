;******************************************************************************
; Lesson 04 — Exercise 1 Solution: Hardware Blink
;******************************************************************************

#include "../../../../common/msp430g2553-defs.s"

    .text
    .global _start

;==============================================================================
; Timing constants
;==============================================================================
.equ TICK_PERIOD,   4999    ; 5 ms at 1 MHz  (counts 0–4999 = 5000 cycles)
.equ BLINK_TICKS,     50    ; 50 × 5 ms = 250 ms  → toggle every 250 ms = 2 Hz

_start:
    mov.w   #0x0400, SP
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1
    mov.b   &CALDCO_1MHZ, &DCOCTL

    bis.b   #LED1, &P1DIR
    bic.b   #LED1, &P1OUT

    ; Timer_A: 5 ms tick
    mov.w   #TICK_PERIOD, &TACCR0
    mov.w   #(TASSEL_2|MC_1|TACLR), &TACTL

    mov.w   #BLINK_TICKS, R6            ; tick countdown

main_loop:
    bit.w   #TAIFG, &TACTL              ; has one tick elapsed?
    jz      main_loop                   ; no — keep waiting
    bic.w   #TAIFG, &TACTL              ; yes — clear flag

    dec.w   R6
    jnz     main_loop                   ; not yet time to toggle

    xor.b   #LED1, &P1OUT               ; toggle LED1
    mov.w   #BLINK_TICKS, R6            ; reload counter

    jmp     main_loop

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .word   _start
    .end
