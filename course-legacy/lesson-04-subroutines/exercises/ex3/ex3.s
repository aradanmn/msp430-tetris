;******************************************************************************
; Lesson 04 - Exercise 3: mul(a, b) — Multiply by Repeated Addition
;
; The MSP430G2552 CPU has no MUL instruction.  Implement multiplication
; using a loop that adds `a` to an accumulator `b` times.
;
; mul(R12=a, R13=b) → R12 = a * b
;
; Then call blink_n (from Exercise 2) with the product to show the result.
; Test with mul(3,4)=12 and mul(2,5)=10.
;******************************************************************************
#include "../../../common/msp430g2552-defs.s"

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        bis.b   #LED1, &P1DIR
        bic.b   #LED1, &P1OUT

        ; mul(3, 4) = 12 — blink 12 times
        mov.w   #3, R12
        mov.w   #4, R13
        call    #mul
        ; R12 now holds the product
        call    #blink_n

        ; 2-second pause between tests
        mov.w   #2000, R12
        call    #delay_ms

        ; mul(2, 5) = 10 — blink 10 times
        mov.w   #2, R12
        mov.w   #5, R13
        call    #mul
        call    #blink_n

halt:   jmp     halt

;----------------------------------------------------------------------
; delay_ms — approximate millisecond delay
; Input:  R12 = milliseconds
; Clobbers: R12, R15
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
; blink_n — blink LED1 R12 times (from Exercise 2)
; Input:  R12 = count
; Clobbers: R12, R13, R15
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
; mul — multiply R12 by R13 using repeated addition
; Input:  R12 = a, R13 = b
; Output: R12 = a * b
; Clobbers: R12, R13, R14
;
; TODO: Implement this subroutine.
;
; Algorithm:
;   result = 0
;   count  = b (use R13 as loop counter)
;   loop:
;     result += a
;     count  -= 1
;     if count != 0, loop
;   return result
;
; Hint: you need a third register to hold the accumulator (R14).
;       R12=a (addend), R13=count, R14=accumulator
;----------------------------------------------------------------------
mul:
        ; TODO: implement here

        ret     ; placeholder — replace with real code

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
