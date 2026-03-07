;******************************************************************************
; Lesson 03 - Exercise 3: Reaction Test
;
; LED2 turns on after a pseudo-random delay.
; Press button while LED2 is on → success (LED1 blinks 3x fast)
; Too slow (LED2 turns off before press) → fail (LED1 blinks 1x slow)
;******************************************************************************
#include "../../../common/msp430g2552-defs.s"

.equ    WINDOW_COUNT, 20000     ; ~60ms window to press button

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        bis.b   #(LED1|LED2), &P1DIR
        bic.b   #(LED1|LED2), &P1OUT
        bic.b   #BTN, &P1DIR
        bis.b   #BTN, &P1REN
        bis.b   #BTN, &P1OUT

        mov.w   #1000, R12              ; "Random" seed (varies each run)

round:
        ; Wait for a "random" delay before turning on LED2
        ; TODO: use R12 as countdown loop for variable wait
        ; hint: dec.w R12 / jnz countdown / reload with some value

        ; Turn on LED2 — reaction window begins
        ; TODO: bis.b LED2

        ; Check for button press within window
        mov.w   #WINDOW_COUNT, R13
check_window:
        ; TODO: check if button pressed (Z flag) → jump to success
        ; dec.w R13 / jnz check_window

        ; If we get here, no press in time → fail
        ; TODO: bic.b LED2, call fail_blink, jmp round

        ; TODO: success path: bic.b LED2, call success_blink, jmp round

success_blink:
        ; Blink LED1 quickly 3 times
        ; TODO
        ret

fail_blink:
        ; Blink LED1 slowly once
        ; TODO
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
