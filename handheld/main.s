;******************************************************************************
; Handheld Gaming Platform — main.s
;
; This file grows with each lesson. It owns:
;   - _start (hardware init sequence)
;   - the game loop (LPM0 entry)
;   - the interrupt vector table
;
; Modules are pulled in via #include (same convention as msp430g2553-defs.s).
; Each module defines subroutines; main.s calls them from init and the ISR.
;
; See registers.md for the register allocation convention.
;******************************************************************************

#include "../course/common/msp430g2553-defs.s"

    .text
    .global _start

;==============================================================================
; _start — Hardware initialization
;==============================================================================
_start:
    mov.w   #0x0400, SP                 ; init stack pointer (top of RAM)
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL  ; disable watchdog
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1     ; calibrate DCO to 1 MHz
    mov.b   &CALDCO_1MHZ, &DCOCTL

    ; --- GPIO init ---
    ; LED1 (P1.0) and LED2 (P1.6) as outputs, both OFF
    bis.b   #(LED1|LED2), &P1DIR
    bic.b   #(LED1|LED2), &P1OUT

    ; --- Startup indicator: LED2 ON for 200 ms, then OFF ---
    ; (handled by timer_isr via startup countdown in R12 — see hal/timer.s)
    bis.b   #LED2, &P1OUT               ; LED2 ON now

    ; --- Peripheral init ---
    call    #timer_init

    ; --- Initialize registers ---
    ; R4 = tick counter for LED1 blink (250 ms = BLINK_TICKS)
    mov.w   #BLINK_TICKS, R4
    ; R12 = startup LED2 countdown (one-shot, 200 ms)
    mov.w   #STARTUP_TICKS, R12

    ; --- Enter LPM0 — ISR drives everything from here ---
    bis.w   #(GIE|CPUOFF), SR

;==============================================================================
; game_update — stub (called from ISR each frame)
;
; Will be filled in by later lessons.
; Uses R5–R11 for game state; R12–R15 as scratch.
;==============================================================================
game_update:
    ret

; --- Module includes (subroutines + ISRs, placed after main-line code) ---
#include "hal/timer.s"

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0               ; 0xFFE0  unused
    .word   0               ; 0xFFE2  unused
    .word   0               ; 0xFFE4  Port 1
    .word   0               ; 0xFFE6  unused
    .word   0               ; 0xFFE8  unused
    .word   0               ; 0xFFEA  ADC10
    .word   0               ; 0xFFEC  USCI RX
    .word   0               ; 0xFFEE  USCI TX
    .word   0               ; 0xFFF0  unused
    .word   0               ; 0xFFF2  Timer_A overflow
    .word   timer_isr       ; 0xFFF4  Timer_A CC0
    .word   0               ; 0xFFF6  WDT
    .word   0               ; 0xFFF8  unused
    .word   0               ; 0xFFFA  unused
    .word   0               ; 0xFFFC  unused
    .word   _start          ; 0xFFFE  Reset
    .end
