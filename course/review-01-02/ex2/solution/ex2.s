;******************************************************************************
; Review 01/02 — Exercise 2 Solution: Morse Code, Redesigned
;******************************************************************************

#include "../../../common/msp430g2553-defs.s"

    .text
    .global _start

.equ    T_DOT,      150
.equ    T_DASH,     450
.equ    T_SYM_GAP,  150
.equ    T_LET_GAP,  450
.equ    T_WORD_GAP, 1000

_start:
    mov.w   #0x0400, SP
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1
    mov.b   &CALDCO_1MHZ, &DCOCTL

    bis.b   #LED1, &P1DIR
    bic.b   #LED1, &P1OUT

main_loop:
    ; --- S ---
    call    #dot
    call    #sym_gap
    call    #dot
    call    #sym_gap
    call    #dot
    call    #let_gap

    ; --- O ---
    call    #dash
    call    #sym_gap
    call    #dash
    call    #sym_gap
    call    #dash
    call    #let_gap

    ; --- S ---
    call    #dot
    call    #sym_gap
    call    #dot
    call    #sym_gap
    call    #dot
    call    #word_gap

    jmp     main_loop

dot:
    bis.b   #LED1, &P1OUT
    mov.w   #T_DOT, R12
    call    #delay_ms
    bic.b   #LED1, &P1OUT
    ret

dash:
    bis.b   #LED1, &P1OUT
    mov.w   #T_DASH, R12
    call    #delay_ms
    bic.b   #LED1, &P1OUT
    ret

sym_gap:
    mov.w   #T_SYM_GAP, R12
    call    #delay_ms
    ret

let_gap:
    mov.w   #T_LET_GAP, R12
    call    #delay_ms
    ret

word_gap:
    mov.w   #T_WORD_GAP, R12
    call    #delay_ms
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
