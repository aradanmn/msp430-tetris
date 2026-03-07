;******************************************************************************
; Lesson 06 - Exercise 1 SOLUTION: Watchdog Mode — Pet It or Die
;******************************************************************************
#include "../../../../common/msp430g2552-defs.s"

        .text
        .global main

main:
        ; Watchdog mode, 32ms timeout, start counting
        mov.w   #(WDTPW|WDTCNTCL), &WDTCTL

        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        bis.b   #LED1, &P1DIR
        bic.b   #BTN,  &P1DIR
        bis.b   #BTN,  &P1REN
        bis.b   #BTN,  &P1OUT

loop:
        xor.b   #LED1, &P1OUT

        ; If button is NOT pressed (BTN high = released), pet the watchdog
        bit.b   #BTN, &P1IN         ; Z=1 if bit is 0 (button pressed)
        jz      skip_pet            ; button pressed → skip petting → reset!
        mov.w   #(WDTPW|WDTCNTCL), &WDTCTL  ; pet the watchdog

skip_pet:
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
