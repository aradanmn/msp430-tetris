;******************************************************************************
; Lesson 04 - Exercise 2: blink_n Subroutine
;
; Write a subroutine called `blink_n` that blinks LED1 exactly N times.
; It must call an internal `delay_ms` subroutine.
;
; Challenge: delay_ms uses R12 as its argument, but blink_n also uses
; R12 as its loop counter.  Use PUSH/POP to protect the counter.
;******************************************************************************
#include "../../../common/msp430g2552-defs.s"

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        bis.b   #LED1, &P1DIR
        bic.b   #LED1, &P1OUT

        ; Blink 1 time
        mov.w   #1, R12
        call    #blink_n

        ; 1-second pause
        mov.w   #1000, R12
        call    #delay_ms

        ; Blink 2 times
        mov.w   #2, R12
        call    #blink_n

        ; 1-second pause
        mov.w   #1000, R12
        call    #delay_ms

        ; Blink 3 times
        mov.w   #3, R12
        call    #blink_n

halt:   jmp     halt

;----------------------------------------------------------------------
; delay_ms — approximate millisecond software delay
; Input:  R12 = milliseconds to wait
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
; blink_n — blink LED1 exactly R12 times
; Input:  R12 = number of blinks
; Clobbers: R12, R13, R15
;
; TODO: Implement this subroutine.
;
; Pseudocode:
;   save R12 on stack (delay_ms will clobber it)
;   R13 = R12  (use R13 as loop counter, or push R12 and use it via POP)
;   loop:
;     LED1 ON
;     delay_ms(150)   ← need R12 = 150 here, but that clobbers loop counter!
;     LED1 OFF
;     delay_ms(150)
;     loop counter -= 1
;     repeat
;----------------------------------------------------------------------
blink_n:
        ; TODO: implement here

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
