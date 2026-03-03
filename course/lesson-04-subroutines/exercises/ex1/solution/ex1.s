;******************************************************************************
; Lesson 04 - Exercise 1 SOLUTION: max(a, b) Subroutine
;******************************************************************************
#include "../../../../common/msp430g2552-defs.s"

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        bis.b   #(LED1|LED2), &P1DIR
        bic.b   #(LED1|LED2), &P1OUT

        ; Test 1: max(3, 7) = 7 → LED2
        mov.w   #3, R12
        mov.w   #7, R13
        call    #max
        call    #show_result

        mov.w   #500, R12
        call    #delay_ms

        ; Test 2: max(9, 4) = 9 → LED2
        mov.w   #9, R12
        mov.w   #4, R13
        call    #max
        call    #show_result

        mov.w   #500, R12
        call    #delay_ms

        ; Test 3: max(2, 2) = 2 → LED1
        mov.w   #2, R12
        mov.w   #2, R13
        call    #max
        call    #show_result

halt:   jmp     halt

;----------------------------------------------------------------------
; show_result — blink LED1 if R12 <= 5, LED2 if R12 > 5
; Input: R12 = result to test
; Clobbers: R12, R13, R14, R15
;----------------------------------------------------------------------
show_result:
        push    R12             ; save result for comparison
        cmp     #5, R12         ; R12 - 5
        jgt     show_led2       ; jump if R12 > 5

show_led1:
        bis.b   #LED1, &P1OUT
        mov.w   #300, R12
        call    #delay_ms
        bic.b   #LED1, &P1OUT
        pop     R12
        ret

show_led2:
        bis.b   #LED2, &P1OUT
        mov.w   #300, R12
        call    #delay_ms
        bic.b   #LED2, &P1OUT
        pop     R12
        ret

;----------------------------------------------------------------------
; delay_ms — approximate millisecond delay
; Input:  R12 = milliseconds
; Clobbers: R12, R15
;----------------------------------------------------------------------
delay_ms:
        mov.w   #250, R15
delay_inner:
        dec.w   R15
        jnz     delay_inner
        dec.w   R12
        jnz     delay_ms
        ret

;----------------------------------------------------------------------
; max — return larger of R12 and R13 in R12
; Input:  R12 = value A,  R13 = value B
; Output: R12 = max(A, B)
;----------------------------------------------------------------------
max:
        cmp     R13, R12        ; compute R12 - R13 to set flags
        jge     max_done        ; if R12 >= R13, R12 is already max
        mov.w   R13, R12        ; else R13 is larger
max_done:
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
