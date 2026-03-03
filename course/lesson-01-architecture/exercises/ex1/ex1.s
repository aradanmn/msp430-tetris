;******************************************************************************
; Lesson 01 - Exercise 1: Register Arithmetic
; TODO: Complete this program
;******************************************************************************
#include "../../../common/msp430g2552-defs.s"

        .text
        .global main

main:
        ; Step 1: Stop the watchdog timer
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL

        ; Step 2: Load 42 into R4
        ; YOUR CODE HERE: mov.w ...

        ; Step 3: Load 13 into R5
        ; YOUR CODE HERE: mov.w ...

        ; Step 4: Add R5 to R4
        ; YOUR CODE HERE: add.w ...

        ; Step 5: Store R4 to RAM address 0x0200
        ; YOUR CODE HERE: mov.w R4, &0x0200

        ; Step 6: Halt
halt:   jmp     halt

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
