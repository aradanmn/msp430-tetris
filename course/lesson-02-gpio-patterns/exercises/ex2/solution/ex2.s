;******************************************************************************
; Lesson 02 — Exercise 2 Solution: Dual Throb
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

main_loop:
    ; --- LED1 burst: 3 flashes at 100ms (LED2 off) ---
    bic.b   #LED2, &P1OUT       ; ensure LED2 is off
    mov.w   #3, R7
led1_burst:
    bis.b   #LED1, &P1OUT
    mov.w   #100, R12
    call    #delay_ms
    bic.b   #LED1, &P1OUT
    mov.w   #100, R12
    call    #delay_ms
    dec.w   R7
    jnz     led1_burst

    ; --- LED2 burst: 3 flashes at 100ms (LED1 off) ---
    bic.b   #LED1, &P1OUT       ; ensure LED1 is off
    mov.w   #3, R7
led2_burst:
    bis.b   #LED2, &P1OUT
    mov.w   #100, R12
    call    #delay_ms
    bic.b   #LED2, &P1OUT
    mov.w   #100, R12
    call    #delay_ms
    dec.w   R7
    jnz     led2_burst

    ; --- 500ms dark gap ---
    mov.w   #500, R12
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
