;******************************************************************************
; Lesson 04 Example — Timer_A Dual-Rate Blinker
;
; Demonstrates Timer_A in up mode with two LEDs blinking at different rates,
; both driven from a single 10 ms hardware tick.
;
;   LED1 toggles every 250 ms  (2 Hz)
;   LED2 toggles every 100 ms  (5 Hz)
;
; Key ideas shown here:
;   1. Timer_A setup: set TACCR0 first, then TACTL to start.
;   2. Polling TAIFG — detect one period, clear the flag.
;   3. Tick-counter pattern — two independent rates from one timer.
;
; Hardware: MSP-EXP430G2 LaunchPad
;   LED1 = P1.0 (Red)    LED2 = P1.6 (Green)
; Clock: 1 MHz DCO (calibrated)
;******************************************************************************

#include "../../common/msp430g2553-defs.s"

    .text
    .global _start

;==============================================================================
; Timing constants
;==============================================================================
.equ TICK_PERIOD,   9999    ; TACCR0: 10 ms at 1 MHz  (counts 0–9999 = 10000 cycles)
.equ LED1_TICKS,      25    ; 25 × 10 ms = 250 ms  → LED1 toggles at 2 Hz
.equ LED2_TICKS,      10    ; 10 × 10 ms = 100 ms  → LED2 toggles at 5 Hz

;==============================================================================
; _start — one-time hardware init
;==============================================================================
_start:
    mov.w   #0x0400, SP
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1
    mov.b   &CALDCO_1MHZ, &DCOCTL

    ; --- Configure LEDs as outputs, both off ---
    bis.b   #(LED1|LED2), &P1DIR
    bic.b   #(LED1|LED2), &P1OUT

    ; --- Configure Timer_A ---
    ;
    ;  Rule: always write TACCR0 BEFORE setting MC bits in TACTL.
    ;  The timer starts the moment MC goes non-zero. If TACCR0 is
    ;  still 0 at that instant, the timer fires on every cycle.
    ;
    mov.w   #TICK_PERIOD, &TACCR0
    mov.w   #(TASSEL_2|MC_1|TACLR), &TACTL  ; SMCLK, up mode, clear TAR

    ; --- Load tick-down counters ---
    mov.w   #LED1_TICKS, R6     ; R6 = LED1 countdown
    mov.w   #LED2_TICKS, R7     ; R7 = LED2 countdown

;==============================================================================
; Main loop — executes once per 10 ms hardware tick
;
; Structure:
;   1. Block here until TAIFG signals end of one timer period.
;   2. Clear TAIFG — mandatory, must happen before next period check.
;   3. Service each channel: decrement, fire if zero, reload.
;   4. Repeat.
;==============================================================================
main_loop:

    ; --- Wait for TAIFG (end of 10 ms period) ---
    bit.w   #TAIFG, &TACTL
    jz      main_loop           ; flag not set — keep waiting
    bic.w   #TAIFG, &TACTL      ; clear flag immediately

    ; --- LED1 channel: toggle every LED1_TICKS ---
    dec.w   R6
    jnz     .Lled1_skip
    xor.b   #LED1, &P1OUT       ; toggle LED1
    mov.w   #LED1_TICKS, R6     ; reload counter
.Lled1_skip:

    ; --- LED2 channel: toggle every LED2_TICKS ---
    dec.w   R7
    jnz     .Lled2_skip
    xor.b   #LED2, &P1OUT       ; toggle LED2
    mov.w   #LED2_TICKS, R7     ; reload counter
.Lled2_skip:

    jmp     main_loop

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .word   _start
    .end
