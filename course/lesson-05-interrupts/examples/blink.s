;******************************************************************************
; Lesson 05 — Example: Interrupt-Driven Blink
;
; LED1 blinks at 2 Hz (toggle every 250 ms) using the Timer_A CC0 interrupt.
; The CPU sleeps in LPM0 between ticks — it only runs during the ISR.
;
; Compare to Lesson 04: the polling loop is gone. main() ends with one
; instruction (the LPM0 entry). All work happens in timer_isr.
;******************************************************************************

#include "../../common/msp430g2553-defs.s"

    .text
    .global _start

.equ TICK_MS,       5
.equ TICK_PERIOD,   (TICK_MS * 1000) - 1    ; 4999 — 5 ms at 1 MHz
.equ BLINK_TICKS,   250 / TICK_MS           ; 50 ticks × 5 ms = 250 ms

_start:
    mov.w   #0x0400, SP
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1
    mov.b   &CALDCO_1MHZ, &DCOCTL

    ; Configure LED1 as output, start OFF
    bis.b   #LED1, &P1DIR
    bic.b   #LED1, &P1OUT

    ; Configure Timer_A: 5 ms tick, CC0 interrupt enabled
    mov.w   #TICK_PERIOD, &TACCR0
    mov.w   #CCIE, &TACCTL0             ; enable CC0 interrupt
    mov.w   #(TASSEL_2|MC_1|TACLR), &TACTL

    ; Initialize blink countdown
    mov.w   #BLINK_TICKS, R6

    ; Enter LPM0 — CPU sleeps, timer keeps running, ISR handles everything
    bis.w   #(GIE|CPUOFF), SR
    ; ← execution never passes this line

;==============================================================================
; Timer_A CC0 ISR — fires every 5 ms
;==============================================================================
timer_isr:
    dec.w   R6
    jnz     .Ldone
    xor.b   #LED1, &P1OUT               ; toggle LED1
    mov.w   #BLINK_TICKS, R6            ; reload countdown
.Ldone:
    reti                                ; restore SR → CPU goes back to sleep

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
