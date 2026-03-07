;******************************************************************************
; Lesson 02 - Exercise 2: SOS Morse Code on LED1
;
; SOS = ... --- ...
; Dot  = 100ms on, 100ms off
; Dash = 300ms on, 100ms off
; Letter gap = 300ms
; Repeat gap = 600ms
;******************************************************************************
#include "../../../common/msp430g2552-defs.s"

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        bis.b   #LED1, &P1DIR           ; P1.0 output

sos_loop:
        ; S = dot dot dot
        ; TODO: send three dots using dot subroutine

        ; letter gap
        ; TODO: call gap

        ; O = dash dash dash
        ; TODO: send three dashes using dash subroutine

        ; letter gap
        ; TODO: call gap

        ; S = dot dot dot
        ; TODO: send three dots

        ; Repeat gap (~600ms)
        ; TODO: two gap calls
        jmp     sos_loop

; Flash LED1 for a dot (100ms on, 100ms off)
dot:
        ; YOUR CODE HERE
        ret

; Flash LED1 for a dash (300ms on, 100ms off)
; HINT: For 300ms, call delay_100ms three times
dash:
        ; YOUR CODE HERE
        ret

; Gap pause (~100ms off)
gap:
        call    #delay_100ms
        ret

; ~100ms delay at 1MHz
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
