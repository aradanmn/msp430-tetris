;******************************************************************************
; Lesson 01 - Exercise 2: Status Register Flags
; TODO: Complete this program
;******************************************************************************
#include "../../../common/msp430g2552-defs.s"

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL

        ; Step 1: Load 0x1234 into R4
        ; YOUR CODE HERE

        ; Step 2: Subtract R4 from R4 (sets Zero flag if result is 0)
        ; Hint: sub.w src, dst  performs dst = dst - src
        ; YOUR CODE HERE: sub.w R4, R4

        ; Step 3: Branch based on Zero flag
        ; YOUR CODE HERE: jz zero_path / jmp non_zero_path

non_zero_path:
        ; Store 0x0000 to RAM 0x0202 (zero flag was NOT set)
        ; YOUR CODE HERE
        jmp     halt

zero_path:
        ; Store 0x0001 to RAM 0x0202 (zero flag WAS set)
        ; YOUR CODE HERE

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
