;******************************************************************************
; Lesson 04 — Exercise 2: Dual-Rate Blinker
;
; Behaviour:
;   LED1 toggles every 500 ms  (1 Hz)
;   LED2 toggles every 125 ms  (4 Hz)
;   Both blink simultaneously, driven from one Timer_A tick.
;
; Requirements:
;   - Choose a tick period that divides evenly into both 500 ms and 125 ms
;   - Define TICK_PERIOD, LED1_TICKS, LED2_TICKS as .equ constants
;   - Two independent tick-down counters in separate registers
;   - Main loop: one TAIFG poll, then service both channels
;   - No magic numbers
;
; Choosing your tick:
;   GCD(500, 125) = 125 ms — but TACCR0 = 124999 which fits in 16 bits (max 65535).
;   5 ms also works: 500/5 = 100, 125/5 = 25. TACCR0 = 4999. Either is fine.
;
; Structure hint:
;
;   main_loop:
;       poll TAIFG → jz main_loop
;       clear TAIFG
;
;       ; LED1 channel
;       dec.w   R6
;       jnz     .Lled1_skip
;       ; toggle LED1, reload R6
;   .Lled1_skip:
;
;       ; LED2 channel
;       dec.w   R7
;       jnz     .Lled2_skip
;       ; toggle LED2, reload R7
;   .Lled2_skip:
;
;       jmp     main_loop
;
; Registers: R6 = LED1 countdown, R7 = LED2 countdown
; (R4–R9 are caller-saved general purpose — choose any unused pair)
;******************************************************************************

#include "../../../common/msp430g2553-defs.s"

    .text
    .global _start

;==============================================================================
; Timing constants — fill in the values
;==============================================================================
.equ TICK_PERIOD,   0       ; TODO: TACCR0 for your chosen tick
.equ LED1_TICKS,    0       ; TODO: ticks per 500 ms
.equ LED2_TICKS,    0       ; TODO: ticks per 125 ms

_start:
    mov.w   #0x0400, SP
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1
    mov.b   &CALDCO_1MHZ, &DCOCTL

    ; TODO: configure LED1 and LED2 as outputs, both OFF
    bis.b   #(LED1|LED2), &P1DIR
    bic.b   #(LED1|LED2), &P1OUT

    ; TODO: configure Timer_A (TACCR0 then TACTL)

    ; TODO: load both tick-down counters (R6 = LED1, R7 = LED2)

; TODO: main loop
main_loop:

    jmp     main_loop       ; placeholder — replace with your implementation

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .word   _start
    .end
