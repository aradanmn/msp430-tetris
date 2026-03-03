;******************************************************************************
; Lesson 06 - Exercise 2: WDT Interval Timer — 1Hz LED Toggle
;
; Use WDT in INTERVAL mode.  Count 31 ticks (31 × 32ms ≈ 992ms ≈ 1Hz)
; in the ISR, then toggle LED1.  Main sleeps in LPM0.
;******************************************************************************
#include "../../../common/msp430g2552-defs.s"

        .data
tick_count: .word 0

        .text
        .global main

main:
        ; TODO: Configure WDT in interval timer mode (~32ms)
        ;       mov.w #(WDTPW|WDTTMSEL|WDTCNTCL), &WDTCTL

        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        bis.b   #LED1, &P1DIR
        bic.b   #LED1, &P1OUT

        ; TODO: Enable WDT interval interrupt (bit 0 of IE1)
        ; TODO: Enable global interrupts (GIE in SR)

main_loop:
        bis.w   #(GIE|CPUOFF), SR  ; LPM0
        nop
        jmp     main_loop

;----------------------------------------------------------------------
; WDT_ISR — fires every ~32ms
; TODO: count ticks; toggle LED1 every 31 ticks (~1Hz)
;----------------------------------------------------------------------
WDT_ISR:
        push    R15

        ; TODO: increment tick_count
        ; TODO: if tick_count >= 31: reset to 0, toggle LED1

        pop     R15
        reti

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
        .word   WDT_ISR              ; 0xFFF6 - WDT
        .word   0                    ; 0xFFF8 - unused
        .word   0                    ; 0xFFFA - unused
        .word   0                    ; 0xFFFC - unused
        .word   main                 ; 0xFFFE - Reset
        .end
