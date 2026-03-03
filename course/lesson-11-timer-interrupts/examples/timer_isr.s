;******************************************************************************
; Lesson 11 Example — Timer_A CC0 Interrupt (1ms System Tick)
;
; Timer_A CC0 ISR fires every 1ms and increments ms_tick.
; Main sleeps in LPM0, waking only when ISR signals a task is due.
;
; Tasks:
;   LED1 toggles every 1000ms (1Hz blink)
;   LED2 toggles every  333ms (~3Hz blink)
;
; Hardware: MSP430G2552 LaunchPad
;   LED1 = P1.0   LED2 = P1.6
;******************************************************************************

#include "../../common/msp430g2552-defs.s"

.equ    PERIOD_LED1,    1000    ; ms
.equ    PERIOD_LED2,     333    ; ms

        .data
ms_tick:    .word 0
t_led1:     .word 0
t_led2:     .word 0

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL

        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        bis.b   #(LED1|LED2), &P1DIR
        bic.b   #(LED1|LED2), &P1OUT

        ; Timer_A: SMCLK, no divider, Up mode, 1ms period
        mov.w   #999, &TACCR0
        mov.w   #CCIE, &TACCTL0
        mov.w   #(TASSEL_2|ID_0|MC_1|TACLR), &TACTL

        bis.w   #GIE, SR

main_loop:
        bis.w   #(GIE|CPUOFF), SR  ; LPM0 — woken by CC0 ISR
        nop

        mov.w   &ms_tick, R12       ; snapshot current tick

        ;----------------------------------------------------------------------
        ; Task 1: LED1 at 1Hz
        ;----------------------------------------------------------------------
        mov.w   R12, R13
        sub.w   &t_led1, R13        ; elapsed = now - last
        cmp.w   #PERIOD_LED1, R13
        jlo     check_led2
        mov.w   R12, &t_led1        ; update last timestamp
        xor.b   #LED1, &P1OUT

        ;----------------------------------------------------------------------
        ; Task 2: LED2 at ~3Hz
        ;----------------------------------------------------------------------
check_led2:
        mov.w   R12, R13
        sub.w   &t_led2, R13
        cmp.w   #PERIOD_LED2, R13
        jlo     main_loop
        mov.w   R12, &t_led2
        xor.b   #LED2, &P1OUT

        jmp     main_loop

;==============================================================================
; TIMERA_CC0_ISR — fires every 1ms
; Increments ms_tick; wakes main if any task is due
;==============================================================================
TIMERA_CC0_ISR:
        push    R15

        inc.w   &ms_tick

        ; Wake main if LED1 or LED2 task might be due
        ; (Check conservatively — main will re-check properly)
        mov.w   &ms_tick, R15

        sub.w   &t_led1, R15
        cmp.w   #PERIOD_LED1, R15
        jlo     check_led2_isr
        bic.w   #CPUOFF, 0(SP)      ; wake main for LED1 task
        jmp     cc0_done

check_led2_isr:
        sub.w   &t_led2, R15
        ; R15 was modified by LED1 check, reload
        mov.w   &ms_tick, R15
        sub.w   &t_led2, R15
        cmp.w   #PERIOD_LED2, R15
        jlo     cc0_done
        bic.w   #CPUOFF, 0(SP)      ; wake main for LED2 task

cc0_done:
        pop     R15
        reti

;==============================================================================
; Interrupt Vector Table
;==============================================================================

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
        .word   TIMERA_CC0_ISR       ; 0xFFF4 - Timer_A CC0
        .word   0                    ; 0xFFF6 - WDT
        .word   0                    ; 0xFFF8 - unused
        .word   0                    ; 0xFFFA - unused
        .word   0                    ; 0xFFFC - unused
        .word   main                 ; 0xFFFE - Reset
        .end
