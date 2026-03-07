;******************************************************************************
; Lesson 10 - Exercise 2 SOLUTION: Press Counter
;******************************************************************************
#include "../../../../common/msp430g2552-defs.s"

        .data
press_count:    .word 0

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        bis.b   #LED1, &P1DIR
        bic.b   #LED1, &P1OUT

        bic.b   #BTN, &P1DIR
        bis.b   #BTN, &P1REN
        bis.b   #BTN, &P1OUT
        bis.b   #BTN, &P1IES
        bic.b   #BTN, &P1IFG
        bis.b   #BTN, &P1IE
        bis.w   #GIE, SR

main_loop:
        bis.w   #(GIE|CPUOFF), SR
        nop

        mov.w   &press_count, R13   ; read count
        tst.w   R13
        jz      main_loop           ; nothing to do

        clr.w   &press_count        ; clear count

blink_loop:
        bis.b   #LED1, &P1OUT
        mov.w   #200, R12
        call    #delay_ms
        bic.b   #LED1, &P1OUT
        mov.w   #200, R12
        call    #delay_ms
        dec.w   R13
        jnz     blink_loop

        ; Pause before accepting next presses
        mov.w   #500, R12
        call    #delay_ms
        jmp     main_loop

PORT1_ISR:
        bic.b   #BTN, &P1IE
        bic.b   #BTN, &P1IFG
        inc.w   &press_count
        push    R12
        push    R15
        mov.w   #20, R12
        call    #delay_ms
        pop     R15
        pop     R12
        bic.b   #BTN, &P1IFG
        bis.b   #BTN, &P1IE
        bic.w   #CPUOFF, 0(SP)     ; wake main
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
