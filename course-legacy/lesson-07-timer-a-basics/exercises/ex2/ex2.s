;******************************************************************************
; Lesson 07 - Exercise 2: Dual-Rate Blink (LED1 @ 1Hz, LED2 @ 2Hz)
;
; One Timer_A in Up mode, 250ms period.
; LED1 toggles every 2 periods (500ms → 1Hz).
; LED2 toggles every period (250ms → 2Hz).
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
        bic.b   #(LED1|LED2), &P1OUT

        ; TODO: Set TACCR0 for 250ms period (SMCLK=1MHz, /8 → 125kHz)
        ;       250ms × 125kHz = 31250 ticks → TACCR0 = 31249

        ; TODO: Start Timer_A in Up mode

        ; R13 = LED1 period counter (count 2 timer ticks per LED1 toggle)
        mov.w   #2, R13

loop:
        ; TODO: wait for CCIFG, clear it

        ; Toggle LED2 every timer period (250ms)
        xor.b   #LED2, &P1OUT

        ; Toggle LED1 every 2 periods (500ms)
        dec.w   R13
        jnz     loop
        xor.b   #LED1, &P1OUT
        mov.w   #2, R13
        jmp     loop

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
