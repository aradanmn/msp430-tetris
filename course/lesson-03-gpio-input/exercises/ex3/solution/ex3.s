;******************************************************************************
; Lesson 03 - Exercise 3 SOLUTION: Reaction Test
;******************************************************************************
#include "../../../../common/msp430g2552-defs.s"

.equ    WINDOW_COUNT, 20000

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        bis.b   #(LED1|LED2), &P1DIR
        bic.b   #(LED1|LED2), &P1OUT
        bic.b   #BTN, &P1DIR
        bis.b   #BTN, &P1REN
        bis.b   #BTN, &P1OUT
        mov.w   #3721, R12              ; Pseudo-random seed

round:
        ; Variable wait before LED turns on
        mov.w   R12, R11
wait_random:
        dec.w   R11
        jnz     wait_random
        add.w   #1237, R12              ; Vary the "random" seed

        ; Turn on LED2
        bis.b   #LED2, &P1OUT

        ; Check for button within window
        mov.w   #WINDOW_COUNT, R13
check_window:
        bit.b   #BTN, &P1IN
        jz      success                 ; Button pressed!
        dec.w   R13
        jnz     check_window
        ; Time expired → fail
        bic.b   #LED2, &P1OUT
        call    #fail_blink
        jmp     round

success:
        bic.b   #LED2, &P1OUT
        call    #success_blink
        jmp     round

success_blink:
        mov.w   #3, R9
sb:     bis.b   #LED1, &P1OUT
        call    #fast_delay
        bic.b   #LED1, &P1OUT
        call    #fast_delay
        dec.w   R9
        jnz     sb
        ret

fail_blink:
        bis.b   #LED1, &P1OUT
        call    #slow_delay
        bic.b   #LED1, &P1OUT
        ret

fast_delay:
        push    R15
        mov.w   #16667, R15
fd:     dec.w   R15
        jnz     fd
        pop     R15
        ret

slow_delay:
        push    R15
        mov.w   #50000, R15
sd:     dec.w   R15
        jnz     sd
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
