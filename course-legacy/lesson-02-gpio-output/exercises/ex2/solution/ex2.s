;******************************************************************************
; Lesson 02 - Exercise 2 SOLUTION: SOS Morse Code
;******************************************************************************
#include "../../../../common/msp430g2552-defs.s"

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        bis.b   #LED1, &P1DIR

sos_loop:
        ; S = ...
        call    #dot
        call    #dot
        call    #dot
        call    #letter_gap

        ; O = ---
        call    #dash
        call    #dash
        call    #dash
        call    #letter_gap

        ; S = ...
        call    #dot
        call    #dot
        call    #dot

        ; Repeat gap (~600ms = 6 × 100ms)
        mov.w   #6, R4
rpt:    call    #delay_100ms
        dec.w   R4
        jnz     rpt

        jmp     sos_loop

dot:
        bis.b   #LED1, &P1OUT       ; ON 100ms
        call    #delay_100ms
        bic.b   #LED1, &P1OUT       ; OFF 100ms
        call    #delay_100ms
        ret

dash:
        bis.b   #LED1, &P1OUT       ; ON 300ms
        call    #delay_100ms
        call    #delay_100ms
        call    #delay_100ms
        bic.b   #LED1, &P1OUT       ; OFF 100ms
        call    #delay_100ms
        ret

letter_gap:
        call    #delay_100ms        ; Extra 200ms (+ dot OFF = 300ms total)
        call    #delay_100ms
        ret

delay_100ms:
        push    R15
        mov.w   #33333, R15
dl:     dec.w   R15
        jnz     dl
        pop     R15
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
