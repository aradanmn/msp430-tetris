;******************************************************************************
; Lesson 04 - Exercise 1: max(a, b) Subroutine
;
; Write the `max` subroutine and call it from main.
; LED1 blinks once if result <= 5, LED2 blinks once if result > 5.
;******************************************************************************
#include "../../../common/msp430g2552-defs.s"

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        bis.b   #(LED1|LED2), &P1DIR
        bic.b   #(LED1|LED2), &P1OUT

        ; Test 1: max(3, 7) → expect 7 → LED2 blinks
        mov.w   #3, R12
        mov.w   #7, R13
        call    #max
        ; TODO: compare R12 to 5, blink LED1 or LED2

        ; Test 2: max(9, 4) → expect 9 → LED2 blinks
        mov.w   #9, R12
        mov.w   #4, R13
        call    #max
        ; TODO: compare R12 to 5, blink LED1 or LED2

        ; Test 3: max(2, 2) → expect 2 → LED1 blinks
        mov.w   #2, R12
        mov.w   #2, R13
        call    #max
        ; TODO: compare R12 to 5, blink LED1 or LED2

halt:   jmp     halt

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
; TODO: implement this subroutine
;----------------------------------------------------------------------
max:
        ; Hint: CMP R13, R12  computes (R12 - R13) and sets flags
        ; JGE branches if R12 >= R13

        ret     ; placeholder

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
