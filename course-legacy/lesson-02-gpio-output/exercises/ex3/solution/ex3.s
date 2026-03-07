;******************************************************************************
; Lesson 02 - Exercise 3 SOLUTION: Binary Counter
;******************************************************************************
#include "../../../../common/msp430g2552-defs.s"

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        bis.b   #(LED1|LED2), &P1DIR
        clr.w   R4                      ; Counter = 0

loop:
        ; Clear both LEDs before setting new state
        bic.b   #(LED1|LED2), &P1OUT

        ; Check bit 0 of R4 → LED1
        bit.w   #BIT0, R4
        jz      skip_led1
        bis.b   #LED1, &P1OUT
skip_led1:

        ; Check bit 1 of R4 → LED2
        bit.w   #BIT1, R4
        jz      skip_led2
        bis.b   #LED2, &P1OUT
skip_led2:

        call    #delay

        inc.w   R4                      ; Next state
        cmp.w   #4, R4                  ; Wrapped past 3?
        jnz     loop
        clr.w   R4                      ; Reset to 0
        jmp     loop

delay:
        push    R15
        mov.w   #50000, R15
dloop:  dec.w   R15
        jnz     dloop
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
