;******************************************************************************
; Lesson 10 - Exercise 3: Both Edges — Press and Release
;
; Falling edge (press):  LED1 ON,  LED2 OFF
; Rising edge (release): LED1 OFF, LED2 ON
; Toggle P1IES in ISR to alternate between detecting press and release.
;******************************************************************************
#include "../../../common/msp430g2552-defs.s"

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        bis.b   #(LED1|LED2), &P1DIR
        bic.b   #LED1, &P1OUT
        bis.b   #LED2, &P1OUT           ; LED2 starts ON (not-pressed state)

        ; Button: falling edge to start
        bic.b   #BTN, &P1DIR
        bis.b   #BTN, &P1REN
        bis.b   #BTN, &P1OUT
        bis.b   #BTN, &P1IES            ; start with falling edge detect
        bic.b   #BTN, &P1IFG
        bis.b   #BTN, &P1IE
        bis.w   #GIE, SR

main_loop:
        bis.w   #(GIE|CPUOFF), SR
        nop
        jmp     main_loop

;----------------------------------------------------------------------
; PORT1_ISR — toggle edge detect, update LEDs
; TODO:
;   1. Disable P1IE
;   2. Toggle P1IES (xor.b #BTN, &P1IES) to switch edge
;   3. Clear P1IFG (AFTER toggling P1IES)
;   4. Toggle LEDs based on which edge we JUST detected
;      (if P1IES now = falling, we JUST handled a rising = release)
;      (if P1IES now = rising,  we JUST handled a falling = press)
;   5. Short debounce (~10ms)
;   6. Clear P1IFG again
;   7. Re-enable P1IE
;----------------------------------------------------------------------
PORT1_ISR:
        reti    ; placeholder

;==============================================================================
; Interrupt Vector Table  (16 entries × 2 bytes = 32 bytes at 0xFFE0-0xFFFF)
;==============================================================================
        .section ".vectors","ax",@progbits
        .word   0                    ; 0xFFE0 - unused
        .word   0                    ; 0xFFE2 - unused
        .word   PORT1_ISR            ; 0xFFE4 - Port 1
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
