;******************************************************************************
; blink.s — Lesson 02: GPIO Output
;
; Alternates the Red LED (P1.0) and Green LED (P1.6) with a software delay.
; Demonstrates: P1DIR setup, BIS.B, BIC.B, XOR.B, delay subroutine.
;******************************************************************************
#include "../../common/msp430g2552-defs.s"

        .text
        .global main

main:
        ;--- Stop watchdog (ALWAYS FIRST) ---
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL

        ;--- Configure P1.0 and P1.6 as outputs ---
        ; BIS.B sets bits without affecting others (bit-set instruction)
        bis.b   #(LED1|LED2), &P1DIR    ; P1.0 and P1.6 are now outputs

        ;--- Initial state: LED1 on, LED2 off ---
        bis.b   #LED1, &P1OUT           ; LED1 (P1.0) HIGH → Red ON
        bic.b   #LED2, &P1OUT           ; LED2 (P1.6) LOW  → Green OFF

loop:
        call    #delay                  ; Wait ~150ms

        ; Toggle both LEDs simultaneously
        ; XOR.B flips the bit: if 1→0 (off), if 0→1 (on)
        xor.b   #(LED1|LED2), &P1OUT    ; Swap LED1 and LED2

        jmp     loop                    ; Repeat forever

;------------------------------------------------------------------------------
; delay — software delay, approximately 150ms at 1MHz DCO
; Uses: R15 (saved and restored)
;------------------------------------------------------------------------------
delay:
        push    R15                     ; Save R15 (caller might be using it)
        mov.w   #50000, R15             ; ~150ms at 1MHz: 50000 × 3 cycles
dloop:  dec.w   R15                     ; Decrement (1 cycle)
        jnz     dloop                   ; Loop if not zero (2 cycles)
        pop     R15                     ; Restore R15
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
