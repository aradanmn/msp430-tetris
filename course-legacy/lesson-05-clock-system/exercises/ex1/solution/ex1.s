;******************************************************************************
; Lesson 05 - Exercise 1 SOLUTION: Accurate 2Hz Blink at 1MHz DCO
;******************************************************************************
#include "../../../../common/msp430g2552-defs.s"

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL

        ; Calibrated 1MHz DCO
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        bis.b   #LED1, &P1DIR

loop:
        bis.b   #LED1, &P1OUT
        call    #delay_250ms
        bic.b   #LED1, &P1OUT
        call    #delay_250ms
        jmp     loop

;----------------------------------------------------------------------
; delay_250ms — ~250ms at 1MHz MCLK
;
; Analysis:
;   - Inner loop: dec.w R15 + jnz = 2 instructions ≈ 2 cycles = 2µs
;   - Target: 250,000µs → need 125,000 inner iterations
;   - 125,000 > 65535, so use R14 as outer counter:
;       outer=2, inner=62,500 → 2 × 62,500 = 125,000 iterations
;   - Each outer iteration also has: mov.w + dec.w + jnz ≈ 3 extra cycles
;     (negligible compared to 62,500 inner cycles)
;
; Clobbers: R14, R15
;----------------------------------------------------------------------
delay_250ms:
        mov.w   #2, R14             ; outer loop count
delay_outer:
        mov.w   #62500, R15         ; inner loop count
delay_inner:
        dec.w   R15
        jnz     delay_inner
        dec.w   R14
        jnz     delay_outer
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
