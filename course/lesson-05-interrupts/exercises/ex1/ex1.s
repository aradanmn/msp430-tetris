;******************************************************************************
; Lesson 05 — Exercise 1: Interrupt-Driven Blink
;
; Builds on Lesson 04 Exercise 1 — same behaviour, different mechanism.
;
; Behaviour:
;   LED1 blinks at exactly 2 Hz (toggle every 250 ms).
;   No polling loop. CPU sleeps in LPM0 between ticks.
;
; Requirements:
;   - Reuse your TICK_PERIOD and BLINK_TICKS constants from L04-Ex1
;   - Enable the CC0 interrupt with CCIE in TACCTL0 (before TACTL)
;   - After initialization, enter LPM0: bis.w #(GIE|CPUOFF), SR
;   - timer_isr: decrement counter, toggle + reload when zero, end with reti
;   - Vector table: timer_isr at 0xFFF4
;
; New register: TACCTL0 — Timer_A capture/compare control 0
; New bit:      CCIE    — CC0 interrupt enable
; New instructions: reti (return from interrupt, restores SR)
;                   bis.w #(GIE|CPUOFF), SR  (enter LPM0)
;******************************************************************************

#include "../../../common/msp430g2553-defs.s"

    .text
    .global _start

.equ TICK_MS,       0       ; TODO
.equ TICK_PERIOD,   0       ; TODO: (TICK_MS * 1000) - 1
.equ BLINK_TICKS,   0       ; TODO: 250 / TICK_MS

_start:
    mov.w   #0x0400, SP
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1
    mov.b   &CALDCO_1MHZ, &DCOCTL

    ; TODO: configure LED1 as output, start OFF
    ; TODO: configure Timer_A with CC0 interrupt enabled
    ; TODO: initialize R6 = BLINK_TICKS
    ; TODO: enter LPM0

;==============================================================================
; Timer_A CC0 ISR
;==============================================================================
timer_isr:
    ; TODO: decrement R6, toggle LED1 and reload when zero
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
    .word   timer_isr   ; 0xFFF4  Timer_A CC0  ← fill this in
    .word   0           ; 0xFFF6  WDT
    .word   0           ; 0xFFF8  unused
    .word   0           ; 0xFFFA  unused
    .word   0           ; 0xFFFC  unused
    .word   _start      ; 0xFFFE  Reset
    .end
