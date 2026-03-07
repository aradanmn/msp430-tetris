;******************************************************************************
; Lesson 04 - Exercise 3 SOLUTION: mul(a, b) by Repeated Addition
;******************************************************************************
#include "../../../../common/msp430g2552-defs.s"

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        bis.b   #LED1, &P1DIR
        bic.b   #LED1, &P1OUT

        ; mul(3, 4) = 12
        mov.w   #3, R12
        mov.w   #4, R13
        call    #mul
        call    #blink_n

        mov.w   #2000, R12
        call    #delay_ms

        ; mul(2, 5) = 10
        mov.w   #2, R12
        mov.w   #5, R13
        call    #mul
        call    #blink_n

halt:   jmp     halt

;----------------------------------------------------------------------
; delay_ms
;----------------------------------------------------------------------
delay_ms:
        mov.w   #250, R15
_dms_inner:
        dec.w   R15
        jnz     _dms_inner
        dec.w   R12
        jnz     delay_ms
        ret

;----------------------------------------------------------------------
; blink_n
;----------------------------------------------------------------------
blink_n:
        mov.w   R12, R13
blink_loop:
        bis.b   #LED1, &P1OUT
        mov.w   #100, R12
        call    #delay_ms
        bic.b   #LED1, &P1OUT
        mov.w   #100, R12
        call    #delay_ms
        dec.w   R13
        jnz     blink_loop
        ret

;----------------------------------------------------------------------
; mul — R12 = R12 * R13  (unsigned, no overflow check)
; Input:  R12 = a, R13 = b
; Output: R12 = a * b
; Clobbers: R12, R13, R14
;----------------------------------------------------------------------
mul:
        ; Edge case: if b == 0, result is 0
        tst.w   R13
        jnz     mul_loop
        clr.w   R12
        ret

mul_loop:
        clr.w   R14             ; R14 = accumulator = 0
mul_add:
        add.w   R12, R14        ; accumulator += a
        dec.w   R13             ; b -= 1
        jnz     mul_add         ; repeat until b == 0
        mov.w   R14, R12        ; return value in R12
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
