;******************************************************************************
; Lesson 10 Example — GPIO Interrupts
;
; Button S2 (P1.3, active-low) generates a falling-edge interrupt.
; PORT1_ISR debounces and toggles LED1 on each confirmed press.
; Main sleeps in LPM0 between presses.
;
; Debounce strategy: disable P1IE, delay 20ms, re-check, clear IFG, re-enable.
;
; Hardware: MSP430G2552 LaunchPad
;   S2  = P1.3 (button, active-low, needs pull-up)
;   LED1 = P1.0 (toggles on each confirmed button press)
;
; Build:  make
; Flash:  make flash
;******************************************************************************

#include "../../common/msp430g2552-defs.s"

        .text
        .global main

;==============================================================================
; main
;==============================================================================
main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL

        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        ; LED1 output
        bis.b   #LED1, &P1DIR
        bic.b   #LED1, &P1OUT

        ; Button S2: input, pull-up, falling edge, interrupt enabled
        bic.b   #BTN, &P1DIR        ; input
        bis.b   #BTN, &P1REN        ; pull resistor enable
        bis.b   #BTN, &P1OUT        ; pull-up (P1OUT=1 when P1REN=1)
        bis.b   #BTN, &P1IES        ; falling edge (high→low = press)
        bic.b   #BTN, &P1IFG        ; clear any stale flag
        bis.b   #BTN, &P1IE         ; enable interrupt

        ; Global interrupts on
        bis.w   #GIE, SR

main_loop:
        bis.w   #(GIE|CPUOFF), SR  ; LPM0 — wait for button press
        nop
        jmp     main_loop

;==============================================================================
; PORT1_ISR — button press detected
;
; Debounce strategy:
;   1. Disable P1IE immediately (prevent re-triggering during bounce)
;   2. Clear P1IFG
;   3. Toggle LED1
;   4. Wait 20ms (bounce settles)
;   5. Clear P1IFG again (clear any bounced edges)
;   6. Re-enable P1IE
;==============================================================================
PORT1_ISR:
        ; Disable interrupt to avoid multiple triggers during bounce
        bic.b   #BTN, &P1IE
        bic.b   #BTN, &P1IFG        ; clear the flag

        ; Confirm it's our button (could be other P1 pins)
        ; (In this program only BTN is enabled, so no check needed)

        ; Action: toggle LED1
        xor.b   #LED1, &P1OUT

        ; Debounce delay: ~20ms
        push    R12
        push    R15
        mov.w   #20, R12
        call    #dbounce_delay
        pop     R15
        pop     R12

        ; Clear any bounce-generated flags
        bic.b   #BTN, &P1IFG

        ; Re-enable interrupt
        bis.b   #BTN, &P1IE

        reti

;==============================================================================
; dbounce_delay — ~N ms delay (for use inside ISR)
; Input: R12 = milliseconds
; Clobbers: R12, R15 (caller must push/pop)
;==============================================================================
dbounce_delay:
        mov.w   #250, R15
_dbd:   dec.w   R15
        jnz     _dbd
        dec.w   R12
        jnz     dbounce_delay
        ret

;==============================================================================
; Interrupt Vector Table
;==============================================================================

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
