;******************************************************************************
; Lesson 07 - Exercise 3: Measure Button Hold Time
;
; Use Timer_A Continuous mode to measure how long S2 is held.
; Result: blink LED1 once per 100ms of measured hold time.
; (hold ~300ms → 3 blinks, hold ~500ms → 5 blinks)
;
; At SMCLK=1MHz, ID_3(/8) = 125kHz: 1 tick = 8µs
; Elapsed_ms ≈ ticks × 8 / 1000 = ticks / 125
;******************************************************************************
#include "../../../common/msp430g2552-defs.s"

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
        bis.b   #BTN,  &P1OUT      ; pull-up enabled

        ; TODO: Start Timer_A in Continuous mode, SMCLK/8
        ;       mov.w #(TASSEL_2|ID_3|MC_2|TACLR), &TACTL
        ;       No TACCR0 needed in continuous mode

measure_loop:
        ; Step 1: Wait for button press (BTN goes LOW)
        ; TODO: poll P1IN until BTN bit = 0
        ;       bit.b #BTN, &P1IN   → Z=1 if bit is 0 (pressed)

        ; Step 2: Capture TAR at press time
        ; TODO: mov.w &TAR, R12    ; save start_ticks in R12

        ; Step 3: Wait for button release (BTN goes HIGH)
        ; TODO: poll P1IN until BTN bit = 1

        ; Step 4: Capture TAR at release
        ; TODO: mov.w &TAR, R13   ; save end_ticks in R13

        ; Step 5: Compute elapsed ticks (R13 - R12)
        ; TODO: sub.w R12, R13    ; R13 = elapsed ticks

        ; Step 6: Convert to ms (divide by 125: each tick = 8µs)
        ; Simplified: divide by 128 (shift right 7 times) for close approximation
        ; TODO: rra.w R13 (×7 times) to get R13 ≈ elapsed_ms / 100

        ; Step 7: Blink LED1 R13 times (each blink = 100ms)
        ; Use your blink_n pattern from Lesson 04

        jmp     measure_loop    ; repeat

;----------------------------------------------------------------------
; blink_n — blink LED1 R13 times, 100ms on + 100ms off each
; TODO: implement using your Lesson 04 knowledge
;----------------------------------------------------------------------
blink_n:
        ; ... implement ...
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
