;******************************************************************************
; Lesson 05 — Exercise 2: Interrupt-Driven Dual-Rate Blinker
;
; Builds on L04-Ex2 and L05-Ex1.
;
; Behaviour:
;   LED1 toggles every 500 ms (1 Hz)
;   LED2 toggles every 125 ms (4 Hz)
;   CPU sleeps in LPM0 between ticks.
;
; Requirements:
;   - Reuse your tick and LED tick constants from L04-Ex2
;   - Both LED channels serviced inside timer_isr
;   - Main initializes registers and enters LPM0
;   - No polling loop
;******************************************************************************

#include "../../../common/msp430g2553-defs.s"

    .text
    .global _start

.equ TICK_MS,       0       ; TODO
.equ TICK_PERIOD,   0       ; TODO
.equ LED1_TICKS,    0       ; TODO
.equ LED2_TICKS,    0       ; TODO

_start:
    mov.w   #0x0400, SP
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1
    mov.b   &CALDCO_1MHZ, &DCOCTL

    ; TODO: setup, initialize counters, enter LPM0

timer_isr:
    ; TODO: service both LED channels
    reti

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0           ; 0xFFE0  unused
    .word   0           ; 0xFFE2  unused
    .word   0           ; 0xFFE4  Port 1
    .word   0           ; 0xFFE6  unused
    .word   0           ; 0xFFE8  unused
    .word   0           ; 0xFFEA  ADC10
    .word   0           ; 0xFFEC  USCI RX
    .word   0           ; 0xFFEE  USCI TX
    .word   0           ; 0xFFF0  unused
    .word   0           ; 0xFFF2  Timer_A overflow
    .word   timer_isr   ; 0xFFF4  Timer_A CC0
    .word   0           ; 0xFFF6  WDT
    .word   0           ; 0xFFF8  unused
    .word   0           ; 0xFFFA  unused
    .word   0           ; 0xFFFC  unused
    .word   _start      ; 0xFFFE  Reset
    .end
