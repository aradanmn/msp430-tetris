;******************************************************************************
; Lesson 16 - Example: Low Power Mode Demonstration
;
; Demonstrates three LPM patterns:
;   Phase 1 (5 blinks): LPM0 + Timer_A 500ms tick
;   Phase 2 (5 blinks): LPM3 + WDT interval ~1Hz (VLO)
;   Phase 3: LPM4 + button wakeup
;
; LED1 blinks during Phase 1 and 2.
; LED2 toggles on button press in Phase 3.
;******************************************************************************
#include "../../common/msp430g2552-defs.s"

        .data
ms_tick:    .word   0
phase:      .byte   0
blink_cnt:  .byte   0

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL

        ; DCO = 1 MHz
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        ; VLO as ACLK
        mov.b   #LFXT1S_2, &BCSCTL3

        bis.b   #(LED1|LED2), &P1DIR
        bic.b   #(LED1|LED2), &P1OUT

        ; Button
        bic.b   #BTN, &P1DIR
        bis.b   #BTN, &P1REN
        bis.b   #BTN, &P1OUT

        clr.b   &phase
        mov.b   #10, &blink_cnt     ; 10 half-blinks = 5 blinks

        ;------------------------------------------------------------------
        ; Phase 1: LPM0 + Timer_A CC0 at 500ms
        ;------------------------------------------------------------------
        mov.w   #499, &TACCR0       ; 500ms at 1kHz... actually use 1MHz/2/1000
        ; SMCLK/1, Up mode → period at 1MHz needs TACCR0=499999 (too big for 16-bit)
        ; Use /8 divider: SMCLK/8=125kHz, TACCR0=62499 → 500ms
        mov.w   #62499, &TACCR0
        mov.w   #CCIE, &TACCTL0
        mov.w   #(TASSEL_2|ID_3|MC_1|TACLR), &TACTL    ; SMCLK/8

lpm0_loop:
        bis.w   #(GIE|CPUOFF), SR   ; LPM0
        nop

        ; Woken by Timer ISR
        tst.b   &blink_cnt
        jz      phase2_start
        jmp     lpm0_loop

        ;------------------------------------------------------------------
        ; Phase 2: LPM3 + WDT interval
        ;------------------------------------------------------------------
phase2_start:
        ; Stop Timer_A
        mov.w   #(WDTPW|WDTHOLD), &TACTL

        ; Reconfigure: WDT interval, ACLK/32768 (~2.7s at VLO, too slow)
        ; Use ACLK/512 ≈ 23ms, then count 43 ticks for ~1s
        mov.w   #(WDTPW|WDTTMSEL|WDTSSEL|WDTCNTCL|WDTIS1), &WDTCTL
        bis.b   #WDTIE, &IE1

        mov.b   #10, &blink_cnt
        inc.b   &phase

lpm3_loop:
        bis.w   #(GIE|CPUOFF|SCG0|SCG1), SR   ; LPM3
        nop

        tst.b   &blink_cnt
        jz      phase3_start
        jmp     lpm3_loop

        ;------------------------------------------------------------------
        ; Phase 3: LPM4 + GPIO wakeup
        ;------------------------------------------------------------------
phase3_start:
        ; Disable WDT interrupts
        bic.b   #WDTIE, &IE1
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL

        bic.b   #(LED1|LED2), &P1OUT
        inc.b   &phase

        ; Enable button interrupt
        bis.b   #BTN, &P1IES
        bic.b   #BTN, &P1IFG
        bis.b   #BTN, &P1IE

lpm4_loop:
        bis.w   #(GIE|CPUOFF|SCG0|SCG1|OSCOFF), SR     ; LPM4
        nop
        ; Woken by button press (handled in PORT1_ISR)
        jmp     lpm4_loop

;----------------------------------------------------------------------
; Timer_A CC0 ISR — Phase 1 half-blink
;----------------------------------------------------------------------
TIMERA_ISR:
        xor.b   #LED1, &P1OUT
        dec.b   &blink_cnt
        bic.w   #CPUOFF, 0(SP)
        reti

;----------------------------------------------------------------------
; WDT ISR — Phase 2 half-blink
;----------------------------------------------------------------------
WDT_ISR:
        xor.b   #LED1, &P1OUT
        dec.b   &blink_cnt
        bic.w   #(CPUOFF|SCG0|SCG1), 0(SP)
        reti

;----------------------------------------------------------------------
; Port 1 ISR — Phase 3 button toggle LED2
;----------------------------------------------------------------------
PORT1_ISR:
        bic.b   #BTN, &P1IFG
        xor.b   #LED2, &P1OUT
        bic.w   #(CPUOFF|SCG0|SCG1|OSCOFF), 0(SP)
        reti

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
        .word   TIMERA_ISR           ; 0xFFF4 - Timer_A CC0
        .word   WDT_ISR              ; 0xFFF6 - WDT
        .word   0                    ; 0xFFF8 - unused
        .word   0                    ; 0xFFFA - unused
        .word   0                    ; 0xFFFC - unused
        .word   main                 ; 0xFFFE - Reset
        .end
