;******************************************************************************
; minimal.s — Lesson 01, Example: Minimal MSP430G2552 program
;
; This is the skeleton all future programs are based on.
; Every MSP430 program must:
;   1. Stop the Watchdog Timer (or CPU resets every ~32ms!)
;   2. Initialize what you need
;   3. Loop forever (never return from main)
;
; Build:   make
; Flash:   make flash
; Inspect: mspdebug rf2500  →  regs  →  md 0x0200 16
;******************************************************************************
#include "../../common/msp430g2552-defs.s"

        .text
        .global main

main:
        ;---------------------------------------------------------------------
        ; ALWAYS FIRST: Stop the Watchdog Timer
        ;
        ; The WDT resets the CPU if not periodically serviced.
        ; Until we learn to use it intentionally, we disable it.
        ;
        ; We write a 16-bit word: password (WDTPW=0x5A00) | hold (WDTHOLD=0x80)
        ; If you write the wrong password, the WDT triggers a reset immediately!
        ;---------------------------------------------------------------------
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL

        ;---------------------------------------------------------------------
        ; At this point:
        ;   - CPU running at default DCO frequency (~1.1 MHz)
        ;   - All GPIO pins are inputs (safe power-on default)
        ;   - Registers R4-R15 contain unknown values
        ;   - RAM (0x0200–0x03FF) contains unknown values
        ;
        ; Try these in mspdebug after flashing:
        ;   regs          — show all register values
        ;   md 0x0200 16  — show 16 bytes of RAM starting at 0x0200
        ;   md 0xFFE0 32  — show the interrupt vector table
        ;---------------------------------------------------------------------

        ; Loop forever — the CPU must never run off the end of your code
halt:
        jmp     halt

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
