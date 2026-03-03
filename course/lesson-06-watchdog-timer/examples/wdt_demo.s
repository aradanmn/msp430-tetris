;******************************************************************************
; Lesson 06 Example — Watchdog Timer (WDT+)
;
; Demonstrates WDT in INTERVAL TIMER mode:
;   - WDT fires every ~32ms (SMCLK/32768 at 1MHz)
;   - ISR counts ticks and toggles LED1 every ~1 second (31 ticks)
;   - Main enters LPM0 (CPU off, SMCLK on) — ISR wakes it briefly
;
; Hardware: MSP430G2552 LaunchPad
;   LED1 = P1.0  (toggles ~1Hz)
;   LED2 = P1.6  (toggles every tick = ~32ms fast flash)
;
; Build:  make
; Flash:  make flash
;******************************************************************************

#include "../../common/msp430g2552-defs.s"

        .data
tick_count: .word 0             ; counts WDT interrupt ticks (in RAM)

        .text
        .global main

;==============================================================================
; main
;==============================================================================
main:
        ; WDT in interval timer mode, SMCLK/32768 ≈ 32ms period
        ; WDTTMSEL=1 (interval), WDTCNTCL=1 (clear counter), no WDTHOLD
        mov.w   #(WDTPW|WDTTMSEL|WDTCNTCL), &WDTCTL

        ; 1MHz calibrated DCO
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        ; LEDs as outputs, both off
        bis.b   #(LED1|LED2), &P1DIR
        bic.b   #(LED1|LED2), &P1OUT

        ; Enable WDT interval interrupt: IE1 bit 0 = WDTIE
        bis.b   #0x01, &IE1

        ; Global interrupts on
        bis.w   #GIE, SR

        ; Spin in LPM0 — CPU off but SMCLK running for WDT
        ; The WDT ISR will wake us briefly every 32ms
main_loop:
        bis.w   #(GIE|CPUOFF), SR  ; enter LPM0
        nop                         ; ISR exits here after reti
        jmp     main_loop

;==============================================================================
; WDT_ISR — fires every ~32ms
;
; - Toggles LED2 every tick (fast 32ms flash, visible as dim glow)
; - Toggles LED1 every 31 ticks (~992ms ≈ 1Hz)
;==============================================================================
WDT_ISR:
        ; No need to save SR — reti restores it
        ; But save any registers we use
        push    R15

        ; Fast indicator: toggle LED2 every ISR (every 32ms)
        xor.b   #LED2, &P1OUT

        ; Slow indicator: count to 31, toggle LED1 at ~1Hz
        mov.w   &tick_count, R15
        inc.w   R15
        cmp.w   #31, R15
        jlo     wdt_isr_done
        clr.w   R15                 ; reset count
        xor.b   #LED1, &P1OUT      ; toggle LED1 (~1Hz)

wdt_isr_done:
        mov.w   R15, &tick_count

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
        .word   0                    ; 0xFFF4 - Timer_A CC0
        .word   WDT_ISR              ; 0xFFF6 - WDT
        .word   0                    ; 0xFFF8 - unused
        .word   0                    ; 0xFFFA - unused
        .word   0                    ; 0xFFFC - unused
        .word   main                 ; 0xFFFE - Reset
        .end
