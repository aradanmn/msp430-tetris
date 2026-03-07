;******************************************************************************
; Lesson 10 - Exercise 3 SOLUTION: Both Edges — Press and Release
;******************************************************************************
#include "../../../../common/msp430g2552-defs.s"

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        bis.b   #(LED1|LED2), &P1DIR
        bic.b   #LED1, &P1OUT
        bis.b   #LED2, &P1OUT       ; LED2 on = not pressed

        bic.b   #BTN, &P1DIR
        bis.b   #BTN, &P1REN
        bis.b   #BTN, &P1OUT
        bis.b   #BTN, &P1IES        ; start: detect falling (press)
        bic.b   #BTN, &P1IFG
        bis.b   #BTN, &P1IE
        bis.w   #GIE, SR

main_loop:
        bis.w   #(GIE|CPUOFF), SR
        nop
        jmp     main_loop

PORT1_ISR:
        bic.b   #BTN, &P1IE

        ; Toggle edge select to detect the opposite edge next time
        xor.b   #BTN, &P1IES

        ; Clear flag AFTER toggling edge select
        bic.b   #BTN, &P1IFG

        ; Determine what we JUST detected:
        ; If P1IES now has BTN bit SET → it was just set to falling
        ;   → we JUST handled a rising edge → button was RELEASED
        ; If P1IES now has BTN bit CLEAR → it was just set to rising
        ;   → we JUST handled a falling edge → button was PRESSED
        bit.b   #BTN, &P1IES
        jnz     released            ; P1IES=falling now → just saw rising (release)

pressed:
        ; Falling edge detected (press): LED1 ON, LED2 OFF
        bis.b   #LED1, &P1OUT
        bic.b   #LED2, &P1OUT
        jmp     isr_debounce

released:
        ; Rising edge detected (release): LED1 OFF, LED2 ON
        bic.b   #LED1, &P1OUT
        bis.b   #LED2, &P1OUT

isr_debounce:
        push    R12
        push    R15
        mov.w   #10, R12
        call    #delay_ms
        pop     R15
        pop     R12
        bic.b   #BTN, &P1IFG
        bis.b   #BTN, &P1IE
        reti

delay_ms:
        mov.w   #250, R15
_d:     dec.w   R15
        jnz     _d
        dec.w   R12
        jnz     delay_ms
        ret

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
