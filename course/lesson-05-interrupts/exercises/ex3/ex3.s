;******************************************************************************
; Lesson 05 — Exercise 3: Interrupt-Driven Adjustable-Speed Blinker
;
; Builds on L04-Ex3 and L05-Exercises 1–2.
;
; Behaviour:
;   Identical to Lesson 04 Exercise 3 — adjustable LED1 speed via button,
;   LED2 acknowledgement flash — but the entire main loop runs inside the ISR.
;   The CPU sleeps in LPM0 between ticks.
;
; Requirements:
;   - All timing constants and register assignments carry over from L04-Ex3
;   - Main initializes state and enters LPM0
;   - timer_isr handles: LED1 blink, LED2 ack, button edge detection,
;     speed change on press
;   - apply_speed and change_speed subroutines remain unchanged
;   - No polling loop
;******************************************************************************

#include "../../../common/msp430g2553-defs.s"

    .text
    .global _start

; TODO: constants (carry over from L04-Ex3)

_start:
    mov.w   #0x0400, SP
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1
    mov.b   &CALDCO_1MHZ, &DCOCTL

    ; TODO: GPIO, timer, state initialization, enter LPM0

timer_isr:
    ; TODO: full tick body from L04-Ex3 main loop, ending with reti
    reti

; TODO: change_speed, apply_speed (carry over from L04-Ex3)

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
