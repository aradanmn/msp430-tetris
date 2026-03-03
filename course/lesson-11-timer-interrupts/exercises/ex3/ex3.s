;******************************************************************************
; Lesson 11 - Exercise 3: Stopwatch
;
; S2 press 1: start counting ms
; S2 press 2: stop; blink LED1 once per accumulated second
;
; States: 0=idle, 1=running, 2=display
;******************************************************************************
#include "../../../common/msp430g2552-defs.s"

.equ    STATE_IDLE,     0
.equ    STATE_RUN,      1
.equ    STATE_DISPLAY,  2

        .data
ms_tick:    .word 0
sw_state:   .word STATE_IDLE
start_tick: .word 0         ; ms_tick at start of timing
elapsed_ms: .word 0         ; total ms measured

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        bis.b   #LED1, &P1DIR
        bic.b   #LED1, &P1OUT

        ; Button
        bic.b   #BTN, &P1DIR
        bis.b   #BTN, &P1REN
        bis.b   #BTN, &P1OUT
        bis.b   #BTN, &P1IES
        bic.b   #BTN, &P1IFG
        bis.b   #BTN, &P1IE

        ; Timer
        mov.w   #999, &TACCR0
        mov.w   #CCIE, &TACCTL0
        mov.w   #(TASSEL_2|ID_0|MC_1|TACLR), &TACTL

        bis.w   #GIE, SR

main_loop:
        bis.w   #(GIE|CPUOFF), SR
        nop

        ; TODO: Check sw_state
        ; STATE_DISPLAY: blink LED1 elapsed_ms/1000 times, reset to IDLE
        ; Other states: main has nothing to do (ISRs handle transitions)

        jmp     main_loop

;----------------------------------------------------------------------
; PORT1_ISR — button press advances state
; IDLE → RUN (record start_tick)
; RUN  → DISPLAY (compute elapsed_ms)
;----------------------------------------------------------------------
PORT1_ISR:
        bic.b   #BTN, &P1IE
        bic.b   #BTN, &P1IFG

        ; TODO: implement state transitions

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
