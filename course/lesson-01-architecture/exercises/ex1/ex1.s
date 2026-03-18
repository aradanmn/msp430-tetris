;******************************************************************************
; Lesson 01 — Exercise 1: Faster Blink
;
; TODO: Change the blink rate from 1 Hz to 4 Hz.
;       LED1 should toggle every 125 ms.
;
; Hint: Only one number needs to change.
;******************************************************************************

#include "../../../common/msp430g2553-defs.s"

    .text
    .global _start

_start:
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL

    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1
    mov.b   &CALDCO_1MHZ, &DCOCTL

    bis.b   #LED1, &P1DIR
    bic.b   #LED1, &P1OUT

main_loop:
    xor.b   #LED1, &P1OUT

    mov.w   #125, R12               ; TODO: change this value
    call    #delay_ms

    jmp     main_loop

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
