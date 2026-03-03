;******************************************************************************
; Lesson 03 - Exercise 2: Press Counter
; Counter at RAM 0x0200, toggle LED2 every 3 presses
; TODO: Complete this program
;******************************************************************************
#include "../../../common/msp430g2552-defs.s"

.equ    COUNTER, 0x0200         ; Press counter in RAM

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        bis.b   #(LED1|LED2), &P1DIR
        bic.b   #BTN, &P1DIR
        bis.b   #BTN, &P1REN
        bis.b   #BTN, &P1OUT
        clr.w   &COUNTER                ; Initialize counter

loop:
        ; Wait for button press
wait_press:
        bit.b   #BTN, &P1IN
        jnz     wait_press

        call    #debounce

        ; Blink LED1 briefly (feedback)
        ; TODO: bis.b LED1, call delay, bic.b LED1

        ; Increment counter
        ; TODO: inc.w &COUNTER

        ; Check if counter == 3
        ; TODO: cmp, branch, toggle LED2, reset counter

        ; Wait for release
wait_release:
        bit.b   #BTN, &P1IN
        jz      wait_release
        call    #debounce

        jmp     loop

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
