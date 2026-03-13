;******************************************************************************
; Lesson 01 Example — Blink
;
; Blinks LED1 (P1.0, Red) at 1 Hz using a software delay loop.
;
; Hardware: MSP-EXP430G2 LaunchPad (no extra components)
; Clock:    1 MHz (DCO calibrated)
;
; What to observe:
;   LED1 toggles every 500 ms → 1 complete blink per second.
;
; Game connection:
;   This is the simplest possible "draw something on screen" action —
;   turning a pin on or off. The full game loop will do thousands of these
;   per second to update the OLED display, but the principle is identical.
;******************************************************************************

#include "../../common/msp430g2553-defs.s"

    .text
    .global _start

;==============================================================================
; _start — runs once on power-up or reset
;==============================================================================
_start:
    ; --- 0. Initialize Stack Pointer ---
    mov.w   #0x0400, SP
    
    ; --- 1. Stop the watchdog timer ---
    ; The WDT resets the chip after ~32 ms if not serviced. Stop it now.
    ; The upper byte must be the password (0x5A); lower byte = WDTHOLD.
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL

    ; --- 2. Calibrate DCO to exactly 1 MHz ---
    ; TI burned factory-measured calibration bytes into Info Flash.
    ; clr.b first to avoid a momentary glitch during the change.
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1     ; set range
    mov.b   &CALDCO_1MHZ, &DCOCTL      ; set fine-tune → now running at 1 MHz

    ; --- 3. Configure LED1 (P1.0) as output ---
    ; P1DIR: 0 = input, 1 = output. We only change bit 0 using BIS.
    bis.b   #LED1, &P1DIR               ; P1.0 → output

    ; --- 4. Start with LED off ---
    bic.b   #LED1, &P1OUT               ; P1.0 → LOW → LED off
    
    ; --- 5. Configure LED2 (P1.6) as output ---
    ; P1DIR: 0 = input, 1 = output. We only change bit 0 using BIS.
    bis.b   #LED2, &P1DIR               ; P1.6 -> output
    
    ; --- 6. Start with LED off ---
    bis.b   #LED2, &P1OUT               ; P1.6 -> LOW -> LED off

;==============================================================================
; main_loop — toggle LED1 every 500 ms (= 1 Hz)
;==============================================================================
main_loop:
;    xor.b   #LED1, &P1OUT               ; flip LED1 (on→off or off→on)
;    xor.b   #LED2, &P1OUT               ; flip LED2 (off->on or on->off)
    
    ; Toggle BOTH pins at the exact same instant.
    xor.b   #(LED1|LED2), &P1OUT
    
    mov.w   #500, R12                   ; delay 500 ms
    call    #delay_ms

    jmp     main_loop                   ; repeat forever

;==============================================================================
; delay_ms — software delay
;
; Arg:     R12 = number of milliseconds to wait (consumed)
; Clobbers: R12, R13
;
; At 1 MHz: 1 cycle = 1 µs, so 1 ms = 1000 cycles.
; Inner loop: dec.w R13 (1 cycle) + jnz (2 cycles) = 3 cycles × 333 = 999 cycles
; Plus dec.w R12 (1) + jnz (2) = 3 cycles overhead per ms → total ≈ 1002 µs/ms
;==============================================================================
delay_ms:
    mov.w   #333, R13                   ; inner loop count
.Ldms_inner:
    dec.w   R13
    jnz     .Ldms_inner                 ; burn 333 × 3 = 999 cycles
    dec.w   R12                         ; one ms elapsed
    jnz     delay_ms                    ; keep going if more ms remain
    ret

;==============================================================================
; Interrupt Vector Table
;
; The MSP430 has 16 interrupt vectors, each a 2-byte address, at 0xFFE0-0xFFFF.
; We fill all unused slots with 0 and point the Reset vector at _start.
; The linker places this section at the correct address automatically.
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0                   ; 0xFFE0  unused
    .word   0                   ; 0xFFE2  unused
    .word   0                   ; 0xFFE4  Port 1
    .word   0                   ; 0xFFE6  Port 2
    .word   0                   ; 0xFFE8  unused
    .word   0                   ; 0xFFEA  ADC10
    .word   0                   ; 0xFFEC  USCI A0/B0 RX
    .word   0                   ; 0xFFEE  USCI A0/B0 TX
    .word   0                   ; 0xFFF0  unused
    .word   0                   ; 0xFFF2  Timer_A overflow
    .word   0                   ; 0xFFF4  Timer_A CC0
    .word   0                   ; 0xFFF6  WDT+
    .word   0                   ; 0xFFF8  unused
    .word   0                   ; 0xFFFA  unused
    .word   0                   ; 0xFFFC  unused
    .word   _start              ; 0xFFFE  Reset ← CPU jumps here on power-up
    .end
