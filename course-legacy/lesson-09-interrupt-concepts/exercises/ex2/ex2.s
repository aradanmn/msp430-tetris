;******************************************************************************
; Lesson 09 - Exercise 2: Flag Signaling — ISR sets flag, main acts on it
;
; WDT ISR sets 'flag' on every 31st tick.
; Main checks flag after each wake, toggles LED1 if set.
;******************************************************************************
#include "../../../common/msp430g2552-defs.s"

        .data
wdt_ticks:  .word 0
flag:       .word 0     ; 0=nothing, 1=toggle LED1

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTTMSEL|WDTCNTCL), &WDTCTL
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        bis.b   #LED1, &P1DIR
        bic.b   #LED1, &P1OUT
        bis.b   #0x01, &IE1
        bis.w   #GIE, SR

main_loop:
        bis.w   #(GIE|CPUOFF), SR  ; sleep
        nop

        ; TODO: read 'flag'
        ; TODO: if flag == 0, jump back to main_loop
        ; TODO: clear flag
        ; TODO: toggle LED1

        jmp     main_loop

;----------------------------------------------------------------------
; WDT_ISR — counts ticks, sets flag every 31st tick
;----------------------------------------------------------------------
WDT_ISR:
        push    R15

        ; TODO: increment wdt_ticks
        ; TODO: if wdt_ticks >= 31: clear ticks, set flag=1

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
