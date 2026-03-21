;******************************************************************************
; Lesson 04 — Exercise 2 Solution: Dual-Rate Blinker
;******************************************************************************

#include "../../../../common/msp430g2553-defs.s"

    .text
    .global _start

;==============================================================================
; Timing constants
;==============================================================================
.equ TICK_PERIOD,   4999    ; 5 ms at 1 MHz
.equ LED1_TICKS,     100    ; 100 × 5 ms = 500 ms  → 1 Hz
.equ LED2_TICKS,      25    ; 25  × 5 ms = 125 ms  → 4 Hz

_start:
    mov.w   #0x0400, SP
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1
    mov.b   &CALDCO_1MHZ, &DCOCTL

    bis.b   #(LED1|LED2), &P1DIR
    bic.b   #(LED1|LED2), &P1OUT

    mov.w   #TICK_PERIOD, &TACCR0
    mov.w   #(TASSEL_2|MC_1|TACLR), &TACTL

    mov.w   #LED1_TICKS, R6
    mov.w   #LED2_TICKS, R7

main_loop:
    bit.w   #TAIFG, &TACTL
    jz      main_loop
    bic.w   #TAIFG, &TACTL

    ; --- LED1 channel ---
    dec.w   R6
    jnz     .Lled1_skip
    xor.b   #LED1, &P1OUT
    mov.w   #LED1_TICKS, R6
.Lled1_skip:

    ; --- LED2 channel ---
    dec.w   R7
    jnz     .Lled2_skip
    xor.b   #LED2, &P1OUT
    mov.w   #LED2_TICKS, R7
.Lled2_skip:

    jmp     main_loop

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .word   _start
    .end
