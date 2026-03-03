;******************************************************************************
; Lesson 08 - Exercise 2: Button-Controlled Brightness
;
; Each press of S2 cycles LED2 through 5 brightness levels:
; 0% → 25% → 50% → 75% → 100% → 0% → ...
;******************************************************************************
#include "../../../common/msp430g2552-defs.s"

; Duty cycle table (TACCR2 values for 0%,25%,50%,75%,100% of TACCR0=999)
.equ    DUTY_0,     0
.equ    DUTY_25,    249
.equ    DUTY_50,    499
.equ    DUTY_75,    749
.equ    DUTY_100,   999

        .data
; Brightness step table (5 entries, each a 16-bit word)
brightness_table:
        .word   DUTY_0, DUTY_25, DUTY_50, DUTY_75, DUTY_100

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        ; Button S2 input with pull-up
        bic.b   #BTN,  &P1DIR
        bis.b   #BTN,  &P1REN
        bis.b   #BTN,  &P1OUT

        ; P1.6 → TA0.2 PWM
        bis.b   #LED2, &P1DIR
        bis.b   #LED2, &P1SEL
        bis.b   #LED2, &P1SEL2

        mov.w   #999, &TACCR0
        mov.w   #OUTMOD_7, &TACCTL2
        mov.w   #(TASSEL_2|ID_0|MC_1|TACLR), &TACTL

        ; R4 = current brightness step (0-4)
        ; TODO: initialize R4 to 0, set initial TACCR2 from table

loop:
        ; TODO: wait for button press (BTN low), debounce
        ; TODO: wait for button release
        ; TODO: increment R4, wrap to 0 if R4 >= 5
        ; TODO: load TACCR2 from brightness_table[R4]
        ;       Hint: each table entry is 2 bytes
        ;       mov.w brightness_table(R5), &TACCR2  (where R5 = R4 * 2)

        jmp     loop

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
