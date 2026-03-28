;******************************************************************************
; Lesson 01 — Exercise 3: SOS Morse Code
;
; Blink LED1 in the SOS pattern, repeat forever.
;
; Timing:
;   Dot:   ON 150 ms, OFF 150 ms
;   Dash:  ON 450 ms, OFF 150 ms
;   Letter gap: 450 ms total off (between S and O, between O and S)
;   Word gap:   1000 ms off (after SOS, before repeating)
;
; Design decisions (yours to make):
;   - Inline all 9 flashes, or write dot/dash subroutines?
;   - If subroutines, what interface?
;   - How do you handle the different gap lengths?
;
; delay_ms is provided (same as your Ex2 solution).
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

    bis.b   #LED1, &P1DIR
    bic.b   #LED1, &P1OUT

    ; Your SOS program here
main_loop:
    call    #dot        ; S
    call    #letter_gap ; 450ms total off
    call    #dash       ; O
    call    #letter_gap ; 450ms total off
    call    #dot        ; S
    call    #word_gap   ; 1s
    jmp main_loop
;==============================================================================
; dot - blink LED1 ON 150 ms, OFF 150 ms
; Input:    none, why would we pass the LED1 address
; Output:   blinks LED1 to dot time
;==============================================================================
dot:
.equ    dot_ms, 150
    mov.w   #2, R4          ; two loops
.Ldot_start:
    dec.w   R4
    jz .Ldot_done           ; on zero jump
    xor.b   #LED1,  &P1OUT  ; toggle LED1
    mov.w   #dot_ms,    R12 ; load delay time into register 12
    call    #delay_ms       ; run the delay timer
    jmp .Ldot_start           ; loop X times
.Ldot_done:
    bic.b   #LED1,  &P1OUT  ; set LED to off state
    ret
;==============================================================================
; dash - blink LED1 ON 450 ms, OFF 150 ms
; Input:    none, why would we pass the LED1 address
; Output:   blinks LED1 for dash time
;==============================================================================
dash:
.equ    dash_on,    300
.equ    dash_off,   150
    bis.b   #LED1,  &P1OUT  ; turn LED1 on
    mov.w   #dash_on, R12   ; set 300ms
    call    #delay_ms
    bic.b   #LED1,  &P1OUT  ; turn LED1 OFF
    mov.w   #dash_off, R12
    call    #delay_ms
    ret
;==============================================================================
; letter_gap - 450 ms total off (between S and O, between O and S)
; Input:    none
; Ouput:    delays program execution 450ms
;==============================================================================
letter_gap:
    mov.w   #450,   R12
    call    #delay_ms
    ret
;==============================================================================
; word_gap - 1000 ms off (after SOS, before repeating)
; Input:    none
; Output:   delays program execution 1s
;==============================================================================
word_gap:
    mov.w   #1000,  R12
    call    #delay_ms
    ret
;==============================================================================
; delay_ms — wait approximately R12 milliseconds (from your Ex2)
; Input:  R12 = milliseconds
; Clobbers: R12, R13
;==============================================================================
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
    .word   0,0,0,0, 0,0,0,0
    .word   0,0,0,0, 0,0,0
    .word   _start
    .end
