;******************************************************************************
; Review 01/02 — Exercise 2: Morse Code, Redesigned
;
; Transmit SOS in Morse code, but with a cleaner subroutine design than
; the L01-ex3 solution.
;
; The problem with the previous design:
;   dot and dash each appended a trailing T_SYMBOL_GAP after the pulse.
;   That meant callers could NOT use T_LETTER_GAP or T_WORD_GAP directly —
;   they had to subtract 150ms manually (300 = 450-150, 850 = 1000-150).
;   The .equ constants became misleading decoration.
;
; The fix — split every subroutine to do exactly one job:
;
;   dot       — LED ON for T_DOT ms,  then LED OFF.  No gap.
;   dash      — LED ON for T_DASH ms, then LED OFF.  No gap.
;   sym_gap   — silence for T_SYM_GAP ms   (between symbols in a letter)
;   let_gap   — silence for T_LET_GAP ms   (between letters)
;   word_gap  — silence for T_WORD_GAP ms  (between repetitions)
;
; Then SOS is spelled out explicitly:
;
;   S:  dot sym_gap dot sym_gap dot
;       let_gap
;   O:  dash sym_gap dash sym_gap dash
;       let_gap
;   S:  dot sym_gap dot sym_gap dot
;       word_gap
;
; Notice: after the last dot/dash in a letter, you call let_gap (not sym_gap).
; After the last dot in the final S, you call word_gap.
; Every constant is used exactly as defined — no mental arithmetic.
;
; Timing constants (do not change these values):
;   T_DOT      = 150 ms   dot on-time
;   T_DASH     = 450 ms   dash on-time (3 × dot)
;   T_SYM_GAP  = 150 ms   silence between symbols in the same letter
;   T_LET_GAP  = 450 ms   silence between letters
;   T_WORD_GAP = 1000 ms  silence after the full SOS before repeating
;
; Pass condition: SOS plays with correct proportions. If you count on/off
; periods with a stopwatch, a dot is 150ms, dash is 450ms, every gap matches
; its constant — no compensating offsets anywhere in the code.
;******************************************************************************

#include "../../common/msp430g2553-defs.s"

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
    ; --- S (dot dot dot) ---
    ; TODO: three dots with symbol gaps between them, then a letter gap
    call #dot
    call #sym_gap
    call #dot
    call #sym_gap
    call #dot
    call #let_gap

    ; --- O (dash dash dash) ---
    ; TODO: three dashes with symbol gaps between them, then a letter gap
    call #dash
    call #sym_gap
    call #dash
    call #sym_gap
    call #dash
    call #let_gap

    ; --- S (dot dot dot) ---
    ; TODO: three dots with symbol gaps between them, then a word gap
    call #dot
    call #sym_gap
    call #dot
    call #sym_gap
    call #dot
    call #word_gap
    jmp     main_loop

; TODO: implement dot, dash, sym_gap, let_gap, word_gap below
; Each subroutine should load R12 and call delay_ms — nothing else.
dot:
    mov.w #T_DOT, R12
    bis.b #LED1, &P1OUT
    call #delay_ms
    bic.b #LED1, &P1OUT
    ret
    
dash:
    mov.w #T_DASH, R12
    bis.b #LED1, &P1OUT
    call #delay_ms
    bic.b #LED1, &P1OUT
    ret
    
sym_gap:
    bic.b #LED1, &P1OUT
    mov.w #T_SYM_GAP, R12
    call #delay_ms
    ret
    
let_gap:
    bic.b #LED1, &P1OUT
    mov.w #T_LET_GAP, R12
    call #delay_ms
    ret
    
word_gap:
    bic.b #LED1, &P1OUT
    mov.w #T_WORD_GAP, R12
    call #delay_ms
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
