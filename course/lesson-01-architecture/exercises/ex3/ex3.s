;******************************************************************************
; Lesson 01 — Exercise 3: SOS Morse Code
;
; Blink LED1 in SOS Morse code, then repeat.
;
; Pattern:  S=···  O=———  S=···  [pause]  [repeat]
;
; Timing:
;   Dot:   LED ON  150 ms, then OFF 150 ms
;   Dash:  LED ON  450 ms, then OFF 150 ms
;   Between letters: extra 300 ms off  (total 450 ms gap between S/O/S)
;   After full SOS: 1000 ms off before repeating
;
; Hints:
;   - Use bis.b to turn LED ON, bic.b to turn LED OFF
;   - You need delay_ms called with different values for each phase
;   - Write it out explicitly first (18 on/off calls for SOS), then
;     optionally refactor into helper subroutines
;******************************************************************************

#include "../../../common/msp430g2553-defs.s"

    .text
    .global _start

;==============================================================================
; Timing constants (milliseconds)
;==============================================================================
.equ    T_DOT,          150     ; dot on-time
.equ    T_DASH,         450     ; dash on-time (3× dot)
.equ    T_SYMBOL_GAP,   150     ; off-time between symbols in same letter
.equ    T_LETTER_GAP,   450     ; off-time between letters (150 + 300 extra)
.equ    T_WORD_GAP,     1000    ; off-time after full SOS before repeating

_start:
    mov.w   #0x0400, SP
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1
    mov.b   &CALDCO_1MHZ, &DCOCTL

    bis.b   #LED1, &P1DIR
    bic.b   #LED1, &P1OUT

main_loop:
    ; TODO: transmit S  (three dots)
    call #dot
    call #dot
    call #dot
    ; TODO: gap between S and O (300 ms extra = 450 ms total inter-letter gap)
    mov.w #300, R12
    call #delay_ms
    ; TODO: transmit O  (three dashes)
    call #dash
    call #dash
    call #dash
    ; TODO: gap between O and S
    mov.w   #300, R12
    call    #delay_ms
    ; TODO: transmit S  (three dots)
    call #dot
    call #dot
    call #dot
    ; TODO: end-of-word pause (1000 ms)
    mov.w   #850, R12
    call    #delay_ms
    
    jmp     main_loop
    
    
;==============================================================================
; dot - flash LED1 for T_DOT ms, then pause T_SYMBOL_GAP ms
;==============================================================================
dot:
    bis.b #LED1, &P1OUT
    mov.w #T_DOT, R12
    call #delay_ms
    
    bic.b #LED1, &P1OUT
    mov.w #T_SYMBOL_GAP, R12
    call #delay_ms
    ret

;==============================================================================
; dash — flash LED1 for T_DASH ms, then pause T_SYMBOL_GAP ms
;==============================================================================
dash:
    bis.b   #LED1, &P1OUT
    mov.w   #T_DASH, R12
    call    #delay_ms

    bic.b   #LED1, &P1OUT
    mov.w   #T_SYMBOL_GAP, R12
    call    #delay_ms
    ret

;==============================================================================
; delay_ms — wait approximately R12 milliseconds
;==============================================================================
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
