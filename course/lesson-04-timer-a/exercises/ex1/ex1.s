;******************************************************************************
; Lesson 04 — Exercise 1: Hardware Blink
;
; Behaviour:
;   LED1 blinks at exactly 2 Hz (toggle every 250 ms) using Timer_A.
;   No delay_ms. No call instructions in the main loop.
;
; Requirements:
;   - TICK_PERIOD: TACCR0 value for your chosen tick interval (compute it)
;   - BLINK_TICKS: number of ticks per LED toggle (compute it)
;   - Write TACCR0 first, then TACTL (SMCLK, up mode, clear)
;   - Main loop: poll TAIFG with bit.w, clear with bic.w, decrement
;     counter, toggle + reload when counter reaches zero
;   - All timing values as .equ constants — no magic numbers
;
; Period formula (SMCLK = 1 MHz):
;   TACCR0 = (tick_ms × 1000) − 1
;   e.g.  5 ms tick → TACCR0 = 4999
;
; Tick count formula:
;   BLINK_TICKS = target_ms / tick_ms
;   e.g.  250 ms / 5 ms = 50 ticks
;
; Hint — main loop structure:
;
;   main_loop:
;       poll TAIFG with bit.w → jz back to main_loop
;       clear TAIFG with bic.w
;       dec.w counter register
;       jnz main_loop          ← skip toggle if not yet time
;       toggle LED1
;       reload counter
;       jmp main_loop
;
; New instructions:
;   bit.w  src, dst   — same as bit.b but tests 16-bit registers
;   bic.w  src, dst   — same as bic.b but clears bits in 16-bit registers
;******************************************************************************

#include "../../../common/msp430g2553-defs.s"

    .text
    .global _start

;==============================================================================
; Timing constants — fill in the correct values
;==============================================================================
.equ TICK_PERIOD,   0       ; TODO: TACCR0 value for your chosen tick interval
.equ BLINK_TICKS,   0       ; TODO: number of ticks per 250 ms

_start:
    mov.w   #0x0400, SP
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1
    mov.b   &CALDCO_1MHZ, &DCOCTL

    ; TODO: configure LED1 as output, start OFF
    bis.b   #LED1, &P1DIR
    bic.b   #LED1, &P1OUT

    ; TODO: configure Timer_A
    ;   Step 1: set the period register
    ;   Step 2: start the timer (SMCLK, up mode, clear TAR)

    ; TODO: load tick-down counter into a register (R6 recommended)

; TODO: main loop — poll, clear, decrement, toggle, reload
main_loop:

    jmp     main_loop       ; placeholder — replace with your implementation

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .word   _start
    .end
