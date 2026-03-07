;******************************************************************************
; Lesson 08 Example — Timer_A Hardware PWM
;
; Breathing LED effect on P1.6 (LED2 / TA0.2):
;   - PWM frequency: 1kHz (SMCLK=1MHz, TACCR0=999, no divider)
;   - Duty cycle ramps 0→100% then 100→0%, creating a smooth breath
;
; Hardware: MSP430G2552 LaunchPad
;   LED2 (green) = P1.6 = TA0.2 output
;   LED1 (red)   = P1.0  (shows CPU is alive — toggles each breath)
;
; Build:  make
; Flash:  make flash
;******************************************************************************

#include "../../common/msp430g2552-defs.s"

; PWM period constant: 1kHz at 1MHz SMCLK
.equ    PWM_PERIOD, 999         ; TACCR0 value → period = 1000 ticks = 1ms

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL

        ; 1MHz calibrated DCO
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        ;----------------------------------------------------------------------
        ; Configure P1.6 as TA0.2 PWM output
        ;----------------------------------------------------------------------
        bis.b   #LED2, &P1DIR       ; P1.6 = output
        bis.b   #LED2, &P1SEL       ; P1SEL[6] = 1
        bis.b   #LED2, &P1SEL2      ; P1SEL2[6] = 1  → TA0.2

        ; LED1 as GPIO output (CPU activity indicator)
        bis.b   #LED1, &P1DIR
        bic.b   #LED1, &P1OUT

        ;----------------------------------------------------------------------
        ; Configure Timer_A for PWM
        ;   TACCR0  = period (999 = 1ms at 1MHz)
        ;   TACCR2  = duty cycle (0 to 999)
        ;   TACCTL2 = OUTMOD_7 (Reset/Set = standard PWM)
        ;   TACTL   = SMCLK source, no divider, Up mode
        ;----------------------------------------------------------------------
        mov.w   #PWM_PERIOD, &TACCR0
        mov.w   #0, &TACCR2                    ; start at 0% duty cycle
        mov.w   #OUTMOD_7, &TACCTL2            ; Reset/Set PWM mode
        mov.w   #(TASSEL_2|ID_0|MC_1|TACLR), &TACTL   ; start timer

        ;----------------------------------------------------------------------
        ; Breathing loop: ramp up then ramp down
        ;----------------------------------------------------------------------
breathe_loop:
        ; Ramp UP: duty 0% → 100% (TACCR2: 0 → PWM_PERIOD)
        clr.w   R12
ramp_up:
        mov.w   R12, &TACCR2        ; update duty cycle
        call    #step_delay         ; small delay between steps
        inc.w   R12
        cmp.w   #PWM_PERIOD+1, R12  ; stop when R12 > PWM_PERIOD
        jlo     ramp_up

        ; Ramp DOWN: duty 100% → 0% (TACCR2: PWM_PERIOD → 0)
        mov.w   #PWM_PERIOD, R12
ramp_down:
        mov.w   R12, &TACCR2
        call    #step_delay
        dec.w   R12
        cmp.w   #0xFFFF, R12        ; dec.w 0 → 0xFFFF (underflow)
        jne     ramp_down

        ; Toggle LED1 to show CPU activity (one toggle per breath cycle)
        xor.b   #LED1, &P1OUT

        jmp     breathe_loop

;----------------------------------------------------------------------
; step_delay — small delay between each PWM step
; Each breath cycle has 2×1000 steps.  At 2ms per step: ~4 second breath.
; Clobbers: R14, R15
;----------------------------------------------------------------------
step_delay:
        mov.w   #2, R14             ; 2ms
        mov.w   #250, R15
_d:     dec.w   R15
        jnz     _d
        dec.w   R14
        jnz     step_delay
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
