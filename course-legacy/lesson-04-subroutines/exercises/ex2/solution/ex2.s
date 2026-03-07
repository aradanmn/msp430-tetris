;******************************************************************************
; Lesson 04 - Exercise 2 SOLUTION: blink_n Subroutine
;******************************************************************************
#include "../../../../common/msp430g2552-defs.s"

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        bis.b   #LED1, &P1DIR
        bic.b   #LED1, &P1OUT

        mov.w   #1, R12
        call    #blink_n

        mov.w   #1000, R12
        call    #delay_ms

        mov.w   #2, R12
        call    #blink_n

        mov.w   #1000, R12
        call    #delay_ms

        mov.w   #3, R12
        call    #blink_n

halt:   jmp     halt

;----------------------------------------------------------------------
; delay_ms — approximate millisecond software delay
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
; blink_n — blink LED1 exactly R12 times
; Input:  R12 = count
; Clobbers: R12, R13, R15
;
; Strategy: move count into R13 (loop counter).
; Each iteration we set R12=150 for delay_ms (clobbering R12 is fine
; since we moved the count to R13).  After the loop restores nothing
; because R12 is a scratch register — the caller doesn't expect it back.
;----------------------------------------------------------------------
blink_n:
        mov.w   R12, R13        ; R13 = blink count (our loop counter)
                                ; R12 is now free to use for delay_ms arg

blink_n_loop:
        bis.b   #LED1, &P1OUT  ; LED1 ON
        mov.w   #150, R12
        call    #delay_ms       ; 150ms on

        bic.b   #LED1, &P1OUT  ; LED1 OFF
        mov.w   #150, R12
        call    #delay_ms       ; 150ms off

        dec.w   R13
        jnz     blink_n_loop

        ret

; Note: We could also have done this with PUSH/POP:
;
;   blink_n:
;       push    R12         ; save count (R12 is argument AND loop counter here)
;       ...
;   loop:
;       pop     R12         ; restore count
;       push    R12         ; re-save it before delay_ms clobbers it
;       mov.w   #150, R12
;       call    #delay_ms
;       bis.b   #LED1, ...  ; etc.
;
; But moving to R13 is simpler.  Both approaches are valid.

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
