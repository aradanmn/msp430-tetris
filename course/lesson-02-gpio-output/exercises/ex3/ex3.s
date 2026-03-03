;******************************************************************************
; Lesson 02 - Exercise 3: Binary Counter on LEDs
; R4 = counter 0-3, shown on LED1 (bit 0) and LED2 (bit 1)
; TODO: Complete this program
;******************************************************************************
#include "../../../common/msp430g2552-defs.s"

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        bis.b   #(LED1|LED2), &P1DIR
        bic.b   #(LED1|LED2), &P1OUT    ; Both off

        mov.w   #0, R4                  ; Counter = 0

loop:
        ; TODO: Update LED output based on R4
        ; Hint: Use BIC.B to clear both LEDs, then
        ;       check R4 bit 0 → BIS.B LED1 if set
        ;       check R4 bit 1 → BIS.B LED2 if set
        ; Use: bit.w #1, R4 / jz skip_led1 / bis.b #LED1, &P1OUT / skip_led1:

        call    #delay

        ; Increment and wrap counter
        inc.w   R4
        ; TODO: if R4 == 4, reset to 0
        ; Hint: cmp.w #4, R4 / jnz loop

        jmp     loop

delay:
        push    R15
        mov.w   #50000, R15
dloop:  dec.w   R15
        jnz     dloop
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
