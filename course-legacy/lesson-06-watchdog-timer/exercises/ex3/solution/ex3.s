;******************************************************************************
; Lesson 06 - Exercise 3 SOLUTION: Heartbeat Watchdog with ACLK
;******************************************************************************
#include "../../../../common/msp430g2552-defs.s"

        .text
        .global main

main:
        ; WDT watchdog mode, ACLK (VLO ~12kHz), /32768 ≈ 2.7s timeout
        mov.w   #(WDTPW|WDTCNTCL|WDTSSEL), &WDTCTL

        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        bis.b   #LED1, &P1DIR
        bic.b   #LED1, &P1OUT

loop:
        mov.w   #5, R13
blink5:
        bis.b   #LED1, &P1OUT
        mov.w   #50, R12
        call    #delay_ms
        bic.b   #LED1, &P1OUT
        mov.w   #50, R12
        call    #delay_ms
        dec.w   R13
        jnz     blink5

        ; Pet the watchdog — must write same config word
        mov.w   #(WDTPW|WDTCNTCL|WDTSSEL), &WDTCTL

        mov.w   #500, R12
        call    #delay_ms
        jmp     loop

delay_ms:
        mov.w   #250, R15
_dms:   dec.w   R15
        jnz     _dms
        dec.w   R12
        jnz     delay_ms
        ret

;==============================================================================
; Interrupt Vector Table  (16 entries × 2 bytes = 32 bytes at 0xFFE0-0xFFFF)
;==============================================================================
        .section ".vectors","ax",@progbits
        .word   0                    ; 0xFFE0 - unused
        .word   0                    ; 0xFFE2 - unused
        .word   0                    ; 0xFFE4 - Port 1
        .word   0                    ; 0xFFE6 - Port 2
        .word   0                    ; 0xFFE8 - unused
        .word   0                    ; 0xFFEA - ADC10
        .word   0                    ; 0xFFEC - USCI RX
        .word   0                    ; 0xFFEE - USCI TX
        .word   0                    ; 0xFFF0 - unused
        .word   0                    ; 0xFFF2 - Timer_A overflow
        .word   0                    ; 0xFFF4 - Timer_A CC0
        .word   0                    ; 0xFFF6 - WDT
        .word   0                    ; 0xFFF8 - unused
        .word   0                    ; 0xFFFA - unused
        .word   0                    ; 0xFFFC - unused
        .word   main                 ; 0xFFFE - Reset
        .end
