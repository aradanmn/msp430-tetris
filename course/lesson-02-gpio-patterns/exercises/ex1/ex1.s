;******************************************************************************
; Lesson 02 — Exercise 1: Counted Flash
;
; Flash LED1 exactly 4 times (150ms on, 150ms off),
; then pause 800ms, then repeat forever.
;
; Hints:
;   - Use R7 as your flash counter: mov.w #4, R7
;   - Loop body: LED on, delay, LED off, delay, dec R7, jnz
;   - delay_ms takes its argument in R12 (it clobbers R12 and R13)
;   - R7 is safe across delay_ms calls — use it freely as your counter
;******************************************************************************

#include "../../../common/msp430g2553-defs.s"

    .text
    .global _start

_start:
    ; --- 0. Initialize Stack Pointer ---
    mov.w   #0x0400, SP

    mov.w   #(WDTPW|WDTHOLD), &WDTCTL

    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1
    mov.b   &CALDCO_1MHZ, &DCOCTL

    ; TODO: configure LED1 as output, start with LED off
    bis.b   #LED1, &P1DIR
    bic.b   #LED1, &P1OUT

main_loop:
    ; TODO: flash LED1 exactly 4 times (150ms on, 150ms off)
    call #toggle_led

    ; TODO: pause 800ms
    mov.w #800, R12
    call #delay_ms

    jmp     main_loop

toggle_led:
    mov.w #4, R7
.Ltled_inner:
    bis.b   #LED1, &P1OUT
    mov.w   #150, R12
    call    #delay_ms
    bic.b   #LED1, & P1OUT
    mov.w   #150, R12
    call    #delay_ms
    dec.w R7
    jnz .Ltled_inner
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
