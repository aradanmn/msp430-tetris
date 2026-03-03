;******************************************************************************
; button.s — Lesson 03: GPIO Input
;
; Button (P1.3) toggles LED1 (P1.0). Uses internal pull-up and software debounce.
; Press the S2 button on your LaunchPad to toggle the red LED.
;******************************************************************************
#include "../../common/msp430g2552-defs.s"

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL

        ;--- LED1 as output ---
        bis.b   #LED1, &P1DIR

        ;--- Button P1.3 as input with pull-up ---
        ; P1REN=1 enables the pull resistor
        ; P1OUT=1 (when DIR=0) selects pull-UP → pin is HIGH when button not pressed
        ; Button connects P1.3 to GND → pressing makes pin LOW (active-low)
        bic.b   #BTN, &P1DIR            ; P1.3 as input (clear direction bit)
        bis.b   #BTN, &P1REN            ; Enable pull resistor on P1.3
        bis.b   #BTN, &P1OUT            ; Select pull-UP (not pull-down)

loop:
        ; Poll: wait until button is pressed
        ; BIT.B tests the bit — if P1.3 is LOW (button pressed), bit.b sets Z=1
wait_press:
        bit.b   #BTN, &P1IN             ; Test P1.3
        jnz     wait_press              ; If not zero (pin HIGH = not pressed), loop

        ; Button is pressed — debounce: wait ~20ms for bounce to settle
        call    #debounce

        ; Toggle LED1
        xor.b   #LED1, &P1OUT

        ; Wait for button to be released before looping
wait_release:
        bit.b   #BTN, &P1IN
        jz      wait_release            ; If zero (still pressed), wait

        ; Short debounce on release too
        call    #debounce

        jmp     loop

;--- ~20ms debounce delay at 1MHz ---
debounce:
        push    R15
        mov.w   #6667, R15              ; ~20ms at 1MHz (3 cycles/iteration)
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
