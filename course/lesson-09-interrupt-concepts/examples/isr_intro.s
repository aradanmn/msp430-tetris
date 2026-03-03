;******************************************************************************
; Lesson 09 Example — Interrupt Concepts
;
; Two ISRs running simultaneously, main sleeping in LPM0:
;
;   WDT interval ISR  (~32ms)  → counts to 31 → toggles LED1 (~1Hz)
;   Timer_A CC0 ISR   (250ms)  → toggles LED2 (2Hz)
;
; Main does NOTHING except enable everything and sleep.
; This is the canonical interrupt-driven MSP430 pattern.
;
; Hardware: MSP430G2552 LaunchPad
;   LED1 = P1.0  (1Hz — WDT interval)
;   LED2 = P1.6  (2Hz — Timer_A)
;
; Build:  make
; Flash:  make flash
;******************************************************************************

#include "../../common/msp430g2552-defs.s"

        .data
wdt_ticks:  .word 0     ; WDT tick counter (shared with WDT_ISR)

        .text
        .global main

;==============================================================================
; main — initialization only; then sleep forever
;==============================================================================
main:
        ; WDT in interval mode, ~32ms period
        mov.w   #(WDTPW|WDTTMSEL|WDTCNTCL), &WDTCTL

        ; 1MHz calibrated DCO
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        ; LEDs as outputs, off
        bis.b   #(LED1|LED2), &P1DIR
        bic.b   #(LED1|LED2), &P1OUT

        ;----------------------------------------------------------------------
        ; Timer_A: SMCLK/8 = 125kHz, Up mode, 250ms period
        ;   TACCR0 = 31249 (250ms × 125kHz = 31250 ticks)
        ;   CC0 interrupt enabled
        ;----------------------------------------------------------------------
        mov.w   #31249, &TACCR0
        mov.w   #CCIE, &TACCTL0                     ; enable CC0 interrupt
        mov.w   #(TASSEL_2|ID_3|MC_1|TACLR), &TACTL ; start timer

        ; Enable WDT interval interrupt (IE1 bit 0)
        bis.b   #0x01, &IE1

        ; Enable all interrupts
        bis.w   #GIE, SR

        ;----------------------------------------------------------------------
        ; Main loop: sleep in LPM0, wake briefly for each ISR, back to sleep
        ;----------------------------------------------------------------------
main_loop:
        bis.w   #(GIE|CPUOFF), SR  ; LPM0 — CPU off, SMCLK on
        nop                         ; required
        jmp     main_loop

;==============================================================================
; WDT_ISR — fires every ~32ms
; Counts to 31 then toggles LED1 (~1Hz)
;==============================================================================
WDT_ISR:
        push    R15

        mov.w   &wdt_ticks, R15
        inc.w   R15
        cmp.w   #31, R15
        jlo     wdt_done
        clr.w   R15
        xor.b   #LED1, &P1OUT

wdt_done:
        mov.w   R15, &wdt_ticks
        pop     R15
        reti

;==============================================================================
; TIMERA_CC0_ISR — fires every 250ms (Timer_A CC0 match)
; Toggles LED2 → 2Hz blink (on 250ms, off 250ms)
;==============================================================================
TIMERA_CC0_ISR:
        ; CCIFG is auto-cleared when the CC0 vector is fetched
        xor.b   #LED2, &P1OUT
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
        .word   WDT_ISR              ; 0xFFF6 - WDT
        .word   0                    ; 0xFFF8 - unused
        .word   0                    ; 0xFFFA - unused
        .word   0                    ; 0xFFFC - unused
        .word   main                 ; 0xFFFE - Reset
        .end
