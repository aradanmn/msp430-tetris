;******************************************************************************
; Lesson 11 - Exercise 3 SOLUTION: Stopwatch
;******************************************************************************
#include "../../../../common/msp430g2552-defs.s"

.equ    STATE_IDLE,     0
.equ    STATE_RUN,      1
.equ    STATE_DISPLAY,  2

        .data
ms_tick:    .word 0
sw_state:   .word STATE_IDLE
start_tick: .word 0
elapsed_ms: .word 0

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

        mov.w   #999, &TACCR0
        mov.w   #CCIE, &TACCTL0
        mov.w   #(TASSEL_2|ID_0|MC_1|TACLR), &TACTL
        bis.w   #GIE, SR

main_loop:
        bis.w   #(GIE|CPUOFF), SR
        nop

        cmp.w   #STATE_DISPLAY, &sw_state
        jne     main_loop

        ; Display: blink LED1 (elapsed_ms / 1000) times
        ; Divide elapsed_ms by 1000 using subtraction loop
        mov.w   &elapsed_ms, R13
        clr.w   R14                 ; seconds count
div_loop:
        cmp.w   #1000, R13
        jlo     div_done
        sub.w   #1000, R13
        inc.w   R14
        jmp     div_loop
div_done:

        tst.w   R14
        jnz     blink_start
        mov.w   #1, R14             ; at least 1 blink for very short presses
blink_start:
        ; Blink R14 times
blink_loop:
        bis.b   #LED1, &P1OUT
        mov.w   #300, R12
        call    #delay_ms
        bic.b   #LED1, &P1OUT
        mov.w   #300, R12
        call    #delay_ms
        dec.w   R14
        jnz     blink_loop

        mov.w   #1000, R12
        call    #delay_ms
        mov.w   #STATE_IDLE, &sw_state
        jmp     main_loop

PORT1_ISR:
        bic.b   #BTN, &P1IE
        bic.b   #BTN, &P1IFG

        cmp.w   #STATE_IDLE, &sw_state
        jne     stop_watch

        ; Start
        mov.w   &ms_tick, &start_tick
        mov.w   #STATE_RUN, &sw_state
        jmp     port1_debounce

stop_watch:
        cmp.w   #STATE_RUN, &sw_state
        jne     port1_debounce
        ; Stop: compute elapsed
        mov.w   &ms_tick, R15
        sub.w   &start_tick, R15
        mov.w   R15, &elapsed_ms
        mov.w   #STATE_DISPLAY, &sw_state

port1_debounce:
        push    R12
        push    R15
        mov.w   #20, R12
        call    #delay_ms
        pop     R15
        pop     R12
        bic.b   #BTN, &P1IFG
        bis.b   #BTN, &P1IE
        bic.w   #CPUOFF, 0(SP)
        reti

TIMERA_CC0_ISR:
        push    R15
        inc.w   &ms_tick
        pop     R15
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
        .word   TIMERA_CC0_ISR       ; 0xFFF4 - Timer_A CC0
        .word   0                    ; 0xFFF6 - WDT
        .word   0                    ; 0xFFF8 - unused
        .word   0                    ; 0xFFFA - unused
        .word   0                    ; 0xFFFC - unused
        .word   main                 ; 0xFFFE - Reset
        .end
