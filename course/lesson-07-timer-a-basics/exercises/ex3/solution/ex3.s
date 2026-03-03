;******************************************************************************
; Lesson 07 - Exercise 3 SOLUTION: Measure Button Hold Time
;******************************************************************************
#include "../../../../common/msp430g2552-defs.s"

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        bis.b   #LED1, &P1DIR
        bic.b   #BTN,  &P1DIR
        bis.b   #BTN,  &P1REN
        bis.b   #BTN,  &P1OUT

        ; Continuous mode, SMCLK/8 = 125kHz
        mov.w   #(TASSEL_2|ID_3|MC_2|TACLR), &TACTL

measure_loop:
        ; Wait for press (BTN low)
wait_press:
        bit.b   #BTN, &P1IN
        jnz     wait_press          ; loop while BTN=1 (not pressed)

        ; Simple debounce: 10ms delay then re-check
        mov.w   #10, R12
        call    #delay_ms
        bit.b   #BTN, &P1IN
        jnz     wait_press          ; spurious glitch, retry

        mov.w   &TAR, R12           ; R12 = start_ticks

        ; Wait for release (BTN high)
wait_release:
        bit.b   #BTN, &P1IN
        jz      wait_release        ; loop while BTN=0 (still pressed)

        mov.w   &TAR, R13           ; R13 = end_ticks

        ; Elapsed ticks in R13 (R13 = end - start)
        sub.w   R12, R13            ; R13 = elapsed ticks

        ; Convert ticks to units of 100ms:
        ; 1 tick = 8µs; 100ms = 12500 ticks
        ; Divide elapsed by 12500: approximated as shift-right 14
        ; But that's too much precision loss.  Instead:
        ; elapsed_100ms = elapsed_ticks / 12500
        ; Use subtraction loop (simple but slow — works for ≤ 10 blinks)
        clr.w   R14                 ; R14 = blink count
count_100ms:
        cmp.w   #12500, R13
        jlo     done_count
        sub.w   #12500, R13
        inc.w   R14
        jmp     count_100ms
done_count:

        ; Clamp to 1 if no blinks (very short press)
        tst.w   R14
        jnz     do_blink
        mov.w   #1, R14
do_blink:
        ; Blink LED1 R14 times
        call    #blink_n

        ; Short pause before next measurement
        mov.w   #500, R12
        call    #delay_ms
        jmp     measure_loop

;----------------------------------------------------------------------
; blink_n — blink LED1 R14 times (200ms per blink)
; Clobbers: R12, R14, R15
;----------------------------------------------------------------------
blink_n:
blink_loop:
        bis.b   #LED1, &P1OUT
        mov.w   #100, R12
        call    #delay_ms
        bic.b   #LED1, &P1OUT
        mov.w   #100, R12
        call    #delay_ms
        dec.w   R14
        jnz     blink_loop
        ret

delay_ms:
        mov.w   #250, R15
_dms:   dec.w   R15
        jnz     _dms
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
