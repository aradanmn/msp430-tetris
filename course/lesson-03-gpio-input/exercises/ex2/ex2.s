;******************************************************************************
; Lesson 03 — Exercise 2: Toggle on Press
;
; Behaviour:
;   Each complete button press+release toggles LED1.
;   LED2 flashes briefly (80ms) to acknowledge each confirmed press.
;   Button bouncing must not cause multiple toggles per physical press.
;
; Requirements:
;   - Full debounce on both press AND release edges (20ms window + re-read)
;   - LED1 toggles exactly once per physical press — not per polling loop pass
;   - LED2 flashes 80ms immediately after each confirmed press (before waiting
;     for release)
;   - No magic numbers: use named constants for all timings
;   - All timing constants defined with .equ at the top
;
; Structure hint:
;   wait_press:   poll until LOW, debounce, re-read, confirm
;   act:          toggle LED1, flash LED2
;   wait_release: poll until HIGH, debounce, re-read, confirm
;   repeat
;
; Registers available: R4–R8 survive delay_ms. R12/R13 are clobbered by it.
;******************************************************************************

#include "../../../common/msp430g2553-defs.s"

    .text
    .global _start

;==============================================================================
; Timing constants — no magic numbers in the code below
;==============================================================================
.equ DEBOUNCE_MS,   20      ; debounce window (ms)
.equ ACK_FLASH_MS,  80      ; LED2 acknowledgement flash (ms)

_start:
    mov.w   #0x0400, SP
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1
    mov.b   &CALDCO_1MHZ, &DCOCTL

    ; TODO: configure LED1 and LED2 as outputs, both OFF
    bis.b #(LED1|LED2), &P1DIR
    bic.b #(LED1|LED2), &P1OUT
    ; TODO: configure BTN as input with pull-up
    bic.b #BTN, &P1DIR
    bis.b #BTN, &P1REN
    bis.b #BTN, &P1OUT

; TODO: implement the debounced edge-detect loop
;
; Template to complete:
;
; wait_press:
;     read BTN
;     branch if released → wait_press
;
;     debounce delay
;     re-read BTN
;     branch if released → wait_press   (was a glitch)
;
;     ; confirmed press
;     toggle LED1
;     flash LED2 ACK_FLASH_MS
;
; wait_release:
;     read BTN
;     branch if still pressed → wait_release
;
;     debounce delay
;     re-read BTN
;     branch if still pressed → wait_release  (was a glitch)
;
;     ; confirmed release
;     jmp wait_press
wait_press:
    bit.b #BTN, &P1IN
    jnz wait_press

    mov.w #DEBOUNCE_MS, R12
    call #delay_ms
    bit.b #BTN, &P1IN
    jnz wait_press

    xor.b #LED1, &P1OUT
    bis.b #LED2, &P1OUT
    mov.w #ACK_FLASH_MS, R12
    call #delay_ms

    bic.b #LED2, &P1OUT

wait_release:
    bit.b #BTN, &P1IN
    jz wait_release

    mov.w #DEBOUNCE_MS, R12
    call #delay_ms
    bit.b #BTN, &P1IN
    jz wait_release

    jmp wait_press
delay_ms:
    mov.w   #333, R13
.Ldms_inner:
    dec.w   R13
    jnz     .Ldms_inner
    dec.w   R12
    jnz     delay_ms
    ret

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .word   _start
    .end
