;******************************************************************************
; Review 01/02 — Exercise 1: Alarm Signal
;
; Implement a two-phase repeating alarm using only concepts from Lessons 1 & 2.
;
; Phase 1 — ARMED (LED1 slow pulse, 5 times):
;   LED1 blinks 5 times at 400ms on / 400ms off, then transitions.
;
; Phase 2 — ALARM (both LEDs alternate fast, 8 pairs):
;   LED1 and LED2 alternate at 80ms each for 8 full pairs, then transitions
;   back to ARMED.
;
; Requirements:
;   1. Define ALL timing values and counts as .equ constants at the top.
;      There must be zero magic numbers inside any subroutine or main_loop.
;
;   2. Factor into three subroutines, each doing exactly one job:
;        armed_pulse  — flash LED1 N times at the ARMED rate
;                       Args: R5 = count  (loaded by caller before call)
;        alarm_burst  — alternate LED1/LED2 N pairs at the ALARM rate
;                       Args: R7 = pair count  (loaded by caller before call)
;        delay_ms     — wait R12 milliseconds (provided below)
;
;   3. main_loop loads the argument register, calls the subroutine, repeats.
;      main_loop itself should be 6 lines or fewer.
;
; Pass condition:
;   Five slow red pulses, then eight fast red/green alternations, then repeat.
;   Changing a single .equ value adjusts the timing throughout with no other
;   edits required.
;******************************************************************************

#include "../../common/msp430g2553-defs.s"

    .text
    .global _start

; TODO: define your .equ constants here
; Suggested names:
;   ARMED_HALF_MS   — on-time and off-time for each armed pulse (400)
;   ARMED_COUNT     — number of armed pulses per phase (5)
;   ALARM_HALF_MS   — half-period for each alarm alternation (80)
;   ALARM_COUNT     — number of LED1/LED2 alternating pairs per phase (8)
.equ ARMED_HALF_MS, 400
.equ ARMED_COUNT, 5
.equ ALARM_HALF_MS, 80
.equ ALARM_COUNT, 8

_start:
    mov.w   #0x0400, SP
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1
    mov.b   &CALDCO_1MHZ, &DCOCTL

    bis.b   #(LED1|LED2), &P1DIR
    bic.b   #(LED1|LED2), &P1OUT

main_loop:
    ; TODO: load ARMED_COUNT into R5, call armed_pulse
    mov.w #ARMED_COUNT, R5
    call #armed_pulse
    ; TODO: load ALARM_COUNT into R7, call alarm_burst
    mov.w #ALARM_COUNT, R7
    call #alarm_burst
    jmp main_loop


; TODO: implement armed_pulse
; Args:   R5 = flash count
; Hint:   use bis.b/bic.b and dec.w/jnz — same pattern as ex1 and ex2 in L02
armed_pulse:

    bic.b #(LED1|LED2), &P1OUT
    bis.b #LED1, &P1OUT
    mov.w #ARMED_HALF_MS, R12
    call #delay_ms
    bic.b #LED1, &P1OUT
    mov.w #ARMED_HALF_MS, R12
    call #delay_ms
    dec.w R5
    jnz armed_pulse
    ret

; TODO: implement alarm_burst
; Args:   R7 = alternation pair count
; Hint:   each pair: LED1 on/LED2 off → delay → LED1 off/LED2 on → delay
;         clear both LEDs when done
alarm_burst:

    bis.b #LED1, &P1OUT
    bic.b #LED2, &P1OUT
    mov.w #ALARM_HALF_MS, R12
    call #delay_ms
    bis.b #LED2, &P1OUT
    bic.b #LED1, &P1OUT
    mov.w #ALARM_HALF_MS, R12
    call #delay_ms
    bic.b #(LED1|LED2), &P1OUT
    dec.w R7
    jnz alarm_burst
    ret

delay_ms:
    mov.w   #333, R13
.Ldms_inner:
    dec.w   R13
    jnz     .Ldms_inner
    dec.w   R12
    jnz     delay_ms
    ret

    .section ".vectors","ax",@progbits
    .word   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .word   _start
    .end
