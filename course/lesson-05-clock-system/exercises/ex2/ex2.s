;******************************************************************************
; Lesson 05 - Exercise 2: MCLK Divide-by-8 Demo
;
; Set DCO to 1MHz, then set MCLK divider to /8.
; Run the SAME delay_250ms loop from Exercise 1.
; Observe: LED blinks ~8x slower (≈0.25Hz instead of 2Hz).
;
; Then clear the divider and show the fast rate again.
; This proves delay loops are MCLK-dependent.
;******************************************************************************
#include "../../../common/msp430g2552-defs.s"

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL

        ; Calibrated 1MHz DCO
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        bis.b   #(LED1|LED2), &P1DIR
        bic.b   #(LED1|LED2), &P1OUT

        ;------------------------------------------------------------------
        ; Part A: Slow blink (MCLK = DCO/8 = 125kHz)
        ; TODO: set BCSCTL2 to divide MCLK by 8 (DIVM_3)
        ;------------------------------------------------------------------

        ; Blink LED1 four times slowly to show the slow rate
        mov.w   #4, R13
slow_loop:
        bis.b   #LED1, &P1OUT
        call    #delay_250ms    ; same loop, but runs 8x slower
        bic.b   #LED1, &P1OUT
        call    #delay_250ms
        dec.w   R13
        jnz     slow_loop

        ;------------------------------------------------------------------
        ; Part B: Fast blink (MCLK = DCO/1 = 1MHz)
        ; TODO: restore BCSCTL2 to DIVM_0 (no divide)
        ;------------------------------------------------------------------

        ; Blink LED2 eight times fast
        mov.w   #8, R13
fast_loop:
        bis.b   #LED2, &P1OUT
        call    #delay_250ms    ; now 250ms again
        bic.b   #LED2, &P1OUT
        call    #delay_250ms
        dec.w   R13
        jnz     fast_loop

halt:   jmp     halt

;----------------------------------------------------------------------
; delay_250ms — ~250ms at 1MHz MCLK (2x slower at 125kHz MCLK)
; Clobbers: R14, R15
;----------------------------------------------------------------------
delay_250ms:
        mov.w   #2, R14
_outer:
        mov.w   #62500, R15
_inner:
        dec.w   R15
        jnz     _inner
        dec.w   R14
        jnz     _outer
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
