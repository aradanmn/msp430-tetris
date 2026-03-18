;******************************************************************************
; Lesson 02 — Exercise 3 Solution: Mini State Machine
;******************************************************************************

#include "../../../../common/msp430g2553-defs.s"

    .text
    .global _start

_start:
    mov.w   #0x0400, SP
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1
    mov.b   &CALDCO_1MHZ, &DCOCTL

    bis.b   #(LED1|LED2), &P1DIR
    bic.b   #(LED1|LED2), &P1OUT

    mov.w   #0, R8              ; R8 = current state (0/1/2)

state_dispatch:
    cmp.w   #0, R8
    jeq     state_attract
    cmp.w   #1, R8
    jeq     state_running
    jmp     state_game_over

;------------------------------------------------------------------------------
; State 0: ATTRACT — LED1 blinks 3× at 400ms, then advance to State 1
;------------------------------------------------------------------------------
state_attract:
    bic.b   #(LED1|LED2), &P1OUT    ; clear both LEDs on entry
    mov.w   #3, R7
.Lattract_loop:
    bis.b   #LED1, &P1OUT
    mov.w   #400, R12
    call    #delay_ms
    bic.b   #LED1, &P1OUT
    mov.w   #400, R12
    call    #delay_ms
    dec.w   R7
    jnz     .Lattract_loop
    mov.w   #1, R8                  ; advance to State 1
    jmp     state_dispatch

;------------------------------------------------------------------------------
; State 1: RUNNING — LED1/LED2 alternate 6× at 120ms, then advance to State 2
;------------------------------------------------------------------------------
state_running:
    bic.b   #(LED1|LED2), &P1OUT
    mov.w   #6, R7
.Lrunning_loop:
    bis.b   #LED1, &P1OUT
    bic.b   #LED2, &P1OUT
    mov.w   #120, R12
    call    #delay_ms
    bic.b   #LED1, &P1OUT
    bis.b   #LED2, &P1OUT
    mov.w   #120, R12
    call    #delay_ms
    dec.w   R7
    jnz     .Lrunning_loop
    bic.b   #(LED1|LED2), &P1OUT
    mov.w   #2, R8                  ; advance to State 2
    jmp     state_dispatch

;------------------------------------------------------------------------------
; State 2: GAME OVER — both flash 4× at 60ms, 1s dark, back to State 0
;------------------------------------------------------------------------------
state_game_over:
    bic.b   #(LED1|LED2), &P1OUT
    mov.w   #4, R7
.Lgameover_loop:
    bis.b   #(LED1|LED2), &P1OUT
    mov.w   #60, R12
    call    #delay_ms
    bic.b   #(LED1|LED2), &P1OUT
    mov.w   #60, R12
    call    #delay_ms
    dec.w   R7
    jnz     .Lgameover_loop
    mov.w   #1000, R12              ; 1s dark
    call    #delay_ms
    mov.w   #0, R8                  ; back to State 0
    jmp     state_dispatch

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
