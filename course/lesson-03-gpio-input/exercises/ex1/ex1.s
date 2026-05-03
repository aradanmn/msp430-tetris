;******************************************************************************
; Lesson 03 — Exercise 1: Button Without Debounce
;
; Toggle LED1 on each button press — but WITHOUT debounce.
;
; You will observe: pressing the button sometimes toggles LED1 once,
; sometimes multiple times, leaving it in a random state.
; This is expected. Understand WHY before moving to Exercise 2.
;
; Implementation:
;   1. Configure BTN (P1.3) as input with pull-up
;   2. Configure LED1 as output
;   3. Main loop:
;      - Wait for press (P1.3 goes LOW)
;      - Toggle LED1
;      - Wait for release (P1.3 goes HIGH)
;      - Repeat
;
; Button is active LOW:
;   pressed  → P1IN bit 3 = 0 → bit.b + jz branches
;   released → P1IN bit 3 = 1 → bit.b + jnz branches
;******************************************************************************

#include "../../../common/msp430g2553-defs.s"

    .text
    .global _start

_start:
    mov.w   #0x0400, SP
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1
    mov.b   &CALDCO_1MHZ, &DCOCTL

    ; Your code here: configure LED1 output, BTN input with pull-up
    bis.b   #LED1, &P1DIR   ; Set P1.0 as an output
    bic.b   #LED1, &P1OUT   ; Set LED1 to OFF
    bic.b   #BTN, &P1DIR    ; Set P1.3 as an input
    bis.b   #BTN, &P1REN    ; Enable Resistor pullup on P1.3
    bis.b   #BTN, &P1OUT    ; Pull up High, low on press.
main_loop:
    ; Your code here: wait press → toggle LED1 → wait release → repeat
.Lbtn_press:
    bit.b   #BTN, &P1IN     ; test P1.3
    jnz     .Lbtn_press
    xor.b   #LED1, &P1OUT
.Lbtn_release:
    bit.b   #BTN, &P1IN
    jz      .Lbtn_release
    jmp     main_loop       ; loo

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0
    .word   0,0,0,0, 0,0,0
    .word   _start
    .end
