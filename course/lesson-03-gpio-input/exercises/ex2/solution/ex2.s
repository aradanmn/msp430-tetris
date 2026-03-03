;******************************************************************************
; Lesson 03 - Exercise 2 SOLUTION: Press Counter
;******************************************************************************
#include "../../../../common/msp430g2552-defs.s"

.equ    COUNTER, 0x0200

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        bis.b   #(LED1|LED2), &P1DIR
        bic.b   #BTN, &P1DIR
        bis.b   #BTN, &P1REN
        bis.b   #BTN, &P1OUT
        clr.w   &COUNTER

loop:
wait_press:
        bit.b   #BTN, &P1IN
        jnz     wait_press
        call    #debounce

        ; Brief LED1 flash as feedback
        bis.b   #LED1, &P1OUT
        call    #short_delay
        bic.b   #LED1, &P1OUT

        ; Increment counter
        inc.w   &COUNTER

        ; Toggle LED2 every 3 presses
        cmp.w   #3, &COUNTER
        jnz     skip_toggle
        xor.b   #LED2, &P1OUT
        clr.w   &COUNTER
skip_toggle:

wait_release:
        bit.b   #BTN, &P1IN
        jz      wait_release
        call    #debounce

        jmp     loop

short_delay:
        push    R15
        mov.w   #10000, R15
sd:     dec.w   R15
        jnz     sd
        pop     R15
        ret

debounce:
        push    R15
        mov.w   #6667, R15
d:      dec.w   R15
        jnz     d
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
