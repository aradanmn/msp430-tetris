;******************************************************************************
; Lesson 08 - Exercise 2 SOLUTION: Button-Controlled Brightness
;******************************************************************************
#include "../../../../common/msp430g2552-defs.s"

        .data
brightness_table:
        .word   0, 249, 499, 749, 999   ; 0%,25%,50%,75%,100%

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        bic.b   #BTN,  &P1DIR
        bis.b   #BTN,  &P1REN
        bis.b   #BTN,  &P1OUT

        bis.b   #LED2, &P1DIR
        bis.b   #LED2, &P1SEL
        bis.b   #LED2, &P1SEL2

        mov.w   #999, &TACCR0
        mov.w   #OUTMOD_7, &TACCTL2
        mov.w   #(TASSEL_2|ID_0|MC_1|TACLR), &TACTL

        mov.w   #0, R4              ; step = 0
        mov.w   #0, &TACCR2        ; 0% initially

loop:
        ; Wait for button press
wait_press:
        bit.b   #BTN, &P1IN
        jnz     wait_press

        ; Debounce 20ms
        mov.w   #20, R12
        call    #delay_ms

        ; Confirm still pressed
        bit.b   #BTN, &P1IN
        jnz     loop               ; spurious, ignore

        ; Wait for release
wait_release:
        bit.b   #BTN, &P1IN
        jz      wait_release

        ; Advance step (0→1→2→3→4→0)
        inc.w   R4
        cmp.w   #5, R4
        jlo     update_duty
        clr.w   R4

update_duty:
        ; R5 = R4 × 2 (byte offset into word table)
        mov.w   R4, R5
        rla.w   R5                 ; shift left 1 = ×2
        mov.w   brightness_table(R5), &TACCR2

        jmp     loop

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
