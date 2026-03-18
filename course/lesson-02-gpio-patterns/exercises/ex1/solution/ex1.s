;******************************************************************************
; Lesson 02 — Exercise 1 Solution: Counted Flash
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

    bis.b   #LED1, &P1DIR
    bic.b   #LED1, &P1OUT

main_loop:
    mov.w   #4, R7              ; flash counter

flash_loop:
    bis.b   #LED1, &P1OUT       ; LED1 on
    mov.w   #150, R12
    call    #delay_ms
    bic.b   #LED1, &P1OUT       ; LED1 off
    mov.w   #150, R12
    call    #delay_ms
    dec.w   R7
    jnz     flash_loop          ; repeat until 4 flashes done

    mov.w   #800, R12           ; 800ms pause
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
