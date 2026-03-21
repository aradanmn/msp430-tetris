;******************************************************************************
; Lesson 03 — Exercise 1: Button Lamp
;
; Behaviour:
;   LED1 is ON  while S2 is held down.
;   LED1 is OFF while S2 is released.
;   No debounce required — this is level detection, not edge detection.
;
; Requirements:
;   - Configure P1.3 as input with internal pull-up (all three registers)
;   - Configure P1.0 (LED1) as output, start OFF
;   - Main loop reads the button and updates LED1 every pass
;   - No magic numbers: use BTN, LED1 from the defs file
;   - No delays — respond instantly to the button
;
; Hint: the button is active LOW
;   pin = 0 (LOW)  → button pressed  → LED on
;   pin = 1 (HIGH) → button released → LED off
;   bit.b + jz branches when the bit is 0 (pressed)
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

    ; TODO: configure LED1 as output, start OFF
    bis.b   #LED1, &P1DIR
    bic.b   #LED1, &P1OUT
    ; TODO: configure BTN (P1.3) as input with pull-up
    ;   Hint: three instructions, three registers (P1DIR, P1REN, P1OUT)
    bic.b   #BTN,   &P1DIR  ; clear bit3 in Port1 register
    bis.b   #BTN,   &P1REN  ; set bit3 (enable Pull Resistor)
    bis.b   #BTN,   &P1OUT  ; set bit3 (setup pull resistor as a pull up)
main_loop:
    ; TODO: read BTN state and update LED1
    ;   If pressed  (bit = 0): LED1 on
    ;   If released (bit = 1): LED1 off
    bit.b #BTN, &P1IN
    jz pressed
    jnz released
    jmp     main_loop

pressed:
    bis.b #LED1, &P1OUT
    jmp main_loop
released:
    bic.b #LED1, &P1OUT
    jmp main_loop
;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .word   _start
    .end
