;******************************************************************************
; Lesson 06 - Exercise 1: Watchdog Mode — Pet It or Die
;
; WDT in watchdog mode.  Pet it in the loop.
; Hold button S2 to stop petting → system resets after ~32ms.
;******************************************************************************
#include "../../../common/msp430g2552-defs.s"

        .text
        .global main

main:
        ; TODO: Start WDT in watchdog mode (NOT interval, NOT held)
        ;       Use: mov.w #(WDTPW|WDTCNTCL), &WDTCTL

        ; 1MHz DCO
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        ; LED1 output, button S2 input with pull-up
        bis.b   #LED1, &P1DIR
        bic.b   #BTN, &P1DIR
        bis.b   #BTN, &P1REN
        bis.b   #BTN, &P1OUT

loop:
        xor.b   #LED1, &P1OUT       ; toggle LED to show activity

        ; TODO: Check button. If NOT pressed, pet the watchdog.
        ;       If button IS pressed, skip petting → system resets.
        ;
        ;       Hint: bit.b #BTN, &P1IN   sets Z if button pressed
        ;              jz skip_pet
        ;              mov.w #(WDTPW|WDTCNTCL), &WDTCTL
        ;       skip_pet:

        ; ~10ms delay
        mov.w   #10, R12
        call    #delay_ms
        jmp     loop

delay_ms:
        mov.w   #250, R15
_dms:   dec.w   R15
        jnz     _dms
        dec.w   R12
        jnz     delay_ms
        ret

        ; Reset vector (required even in watchdog-only programs)

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
