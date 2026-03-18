;******************************************************************************
; Review 01/02 — Exercise 1 Solution: Alarm Signal
;******************************************************************************

#include "../../../common/msp430g2553-defs.s"

    .text
    .global _start

.equ    ARMED_HALF_MS,  400
.equ    ARMED_COUNT,    5
.equ    ALARM_HALF_MS,  80
.equ    ALARM_COUNT,    8

_start:
    mov.w   #0x0400, SP
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1
    mov.b   &CALDCO_1MHZ, &DCOCTL

    bis.b   #(LED1|LED2), &P1DIR
    bic.b   #(LED1|LED2), &P1OUT

main_loop:
    mov.w   #ARMED_COUNT, R5
    call    #armed_pulse
    mov.w   #ALARM_COUNT, R7
    call    #alarm_burst
    jmp     main_loop

; armed_pulse — flash LED1 R5 times at ARMED_HALF_MS on/off
armed_pulse:
    bis.b   #LED1, &P1OUT
    mov.w   #ARMED_HALF_MS, R12
    call    #delay_ms
    bic.b   #LED1, &P1OUT
    mov.w   #ARMED_HALF_MS, R12
    call    #delay_ms
    dec.w   R5
    jnz     armed_pulse
    ret

; alarm_burst — alternate LED1/LED2 for R7 pairs at ALARM_HALF_MS
alarm_burst:
    bis.b   #LED1, &P1OUT
    bic.b   #LED2, &P1OUT
    mov.w   #ALARM_HALF_MS, R12
    call    #delay_ms
    bic.b   #LED1, &P1OUT
    bis.b   #LED2, &P1OUT
    mov.w   #ALARM_HALF_MS, R12
    call    #delay_ms
    dec.w   R7
    jnz     alarm_burst
    bic.b   #(LED1|LED2), &P1OUT
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
