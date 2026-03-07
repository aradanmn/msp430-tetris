;******************************************************************************
; Lesson 12 - Exercise 1: Busy-Wait ADC Read
;
; Read internal temp sensor continuously (polling ADC10BUSY).
; LED1 on if ADC10MEM >= 512, LED2 toggles each reading.
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

        ; TODO: Configure ADC10CTL1 for channel A10, SMCLK, single conversion
        ; TODO: Configure ADC10CTL0 for 1.5V ref, 64-cycle sample, power on
        ; TODO: Wait for reference to settle (~1000 loop iterations)

read_loop:
        ; TODO: Start conversion (ENC | ADC10SC)
        ; TODO: Poll ADC10BUSY until zero
        ; TODO: Read ADC10MEM into R12
        ; TODO: Clear ENC

        ; Toggle LED2 each reading
        xor.b   #LED2, &P1OUT

        ; TODO: if R12 < 512: LED1 off; else LED1 on

        ; 250ms delay
        mov.w   #250, R12
        call    #delay_ms
        jmp     read_loop

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
