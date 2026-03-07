;******************************************************************************
; Lesson 04 Example — Subroutines & Stack
;
; Demonstrates:
;   1. delay_ms  — argument in R12, no return value, uses PUSH/POP
;   2. blink_n   — argument in R12 (count), calls delay_ms nested
;   3. max       — two arguments (R12, R13), returns result in R12
;
; Hardware: MSP430G2552 LaunchPad
;   LED1 (red)   = P1.0
;   LED2 (green) = P1.6
;
; To build:  make
; To flash:  make flash
;******************************************************************************

#include "../../common/msp430g2552-defs.s"

        .text
        .global main

;==============================================================================
; main — entry point
;==============================================================================
main:
        ; Stop watchdog first
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL

        ; Configure DCO for 1MHz (calibrated)
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        ; Configure both LEDs as outputs
        bis.b   #(LED1|LED2), &P1DIR

        ; Turn both off to start
        bic.b   #(LED1|LED2), &P1OUT

        ;----------------------------------------------------------------------
        ; Demo 1: blink LED1 three times using blink_n
        ;----------------------------------------------------------------------
        mov.w   #3, R12
        call    #blink_n

        ; Short pause between demos
        mov.w   #500, R12
        call    #delay_ms

        ;----------------------------------------------------------------------
        ; Demo 2: use max to find the larger of two numbers,
        ;         then blink LED2 that many times
        ;----------------------------------------------------------------------
        mov.w   #2, R12         ; first value
        mov.w   #5, R13         ; second value
        call    #max            ; R12 = max(2,5) = 5

        ; Blink LED2 R12 times (we need to blink LED2, not LED1,
        ; so we'll do it inline here)
        mov.w   R12, R14        ; R14 = count (preserve R12 for demo)
blink_led2_loop:
        bis.b   #LED2, &P1OUT
        mov.w   #150, R12
        call    #delay_ms
        bic.b   #LED2, &P1OUT
        mov.w   #150, R12
        call    #delay_ms
        dec.w   R14
        jnz     blink_led2_loop

        ;----------------------------------------------------------------------
        ; Loop forever: alternate blink patterns
        ;----------------------------------------------------------------------
loop:
        ; Blink LED1 once
        mov.w   #1, R12
        call    #blink_n

        mov.w   #1000, R12
        call    #delay_ms

        jmp     loop

;==============================================================================
; delay_ms — software delay (approximate milliseconds at 1MHz)
;
; Input:  R12 = number of milliseconds to delay
; Output: none
; Clobbers: R12, R15
;
; At 1MHz, each iteration of the inner loop takes approximately 4 cycles
; (dec + jnz = 2 instructions ~ 2-3 cycles each).  We use 250 iterations
; per ms as a reasonable approximation.  Not cycle-exact, but close enough
; for LED blink timing.
;==============================================================================
delay_ms:
        ; R12 = outer loop (millisecond count)
        ; R15 = inner loop (~1ms per 250 iterations at 1MHz)
delay_ms_outer:
        mov.w   #250, R15
delay_ms_inner:
        dec.w   R15
        jnz     delay_ms_inner
        dec.w   R12
        jnz     delay_ms_outer
        ret

;==============================================================================
; blink_n — blink LED1 N times (on/off = one blink)
;
; Input:  R12 = number of blinks (1-based)
; Output: none
; Clobbers: R12, R13, R15 (via delay_ms)
; Saves:  nothing (R12 is a scratch register)
;==============================================================================
blink_n:
        push    R12             ; save blink count (delay_ms uses R12)
        mov.w   R12, R13        ; R13 = loop counter

blink_n_loop:
        bis.b   #LED1, &P1OUT  ; LED1 on
        mov.w   #150, R12
        call    #delay_ms       ; on for 150ms

        bic.b   #LED1, &P1OUT  ; LED1 off
        mov.w   #150, R12
        call    #delay_ms       ; off for 150ms

        dec.w   R13             ; decrement blink count
        jnz     blink_n_loop   ; loop until done

        pop     R12             ; restore caller's R12
        ret

;==============================================================================
; max — return the larger of two 16-bit values
;
; Input:  R12 = value A
;         R13 = value B
; Output: R12 = max(A, B)
; Clobbers: R12, R13
;==============================================================================
max:
        cmp     R13, R12        ; compare: sets flags for R12 - R13
        jge     max_done        ; if R12 >= R13, R12 is already max
        mov.w   R13, R12        ; else R13 is larger, move to R12
max_done:
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
