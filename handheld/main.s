;******************************************************************************
; Handheld Gaming Platform — main.s
;
; This file grows with each lesson via milestone exercises (ex3).
; You build every module yourself. See registers.md for conventions.
;
; Current state: minimal stub (pre-lesson 02)
;******************************************************************************

#include "../course/common/msp430g2553-defs.s"

    .text
    .global _start

_start:

    mov.w   #0x0400, SP                 ; init stack pointer (top of RAM)
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL  ; disable watchdog
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1     ; calibrate DCO to 1 MHz
    mov.b   &CALDCO_1MHZ, &DCOCTL

    ; --- Your init code grows here via milestone exercises ---
    call #leds_init
    call #leds_test
halt:
    jmp     halt                        ; spin until you add LPM0 (L05)

;==============================================================================
; Included modules (after halt — only reached via call)
;==============================================================================
#include "hal/leds.s"

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0           ; 0xFFE0–0xFFEF  unused
    .word   0,0,0,0, 0,0,0             ; 0xFFF0–0xFFFC  unused
    .word   _start                      ; 0xFFFE  Reset
    .end
