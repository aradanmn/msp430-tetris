; clock_demo.s — MSP430G2552 Clock System Demonstration
;
; Demonstrates calibrated DCO configuration and frequency-dependent delays.
;
; Hardware: MSP430G2552 LaunchPad
;   P1.0 = LED1 (Red)
;   P1.6 = LED2 (Green)
;
; Behavior:
;   LED1 (Red)  toggles every ~100ms -> blinks at ~5 Hz (fast)
;   LED2 (Green)toggles every ~1s   -> blinks at ~0.5 Hz (slow)
;
; Clock setup:
;   DCO calibrated to 1 MHz using TI Info Flash constants
;   MCLK = SMCLK = 1,000,000 Hz exactly (±1%)
;
; Timing calculation (delay_100ms):
;   Target: 100ms = 100,000 us = 100,000 cycles at 1 MHz
;   Loop body: dec.w (1 cycle) + jnz (2 cycles taken) = 3 cycles/iter
;   Iterations needed: 100,000 / 3 = 33,333
;   Actual time: 33,333 × 3 = 99,999 cycles = 99.999ms ≈ 100ms
;
; Timing calculation (delay_1s):
;   Calls delay_100ms 10 times = 10 × 100ms = 1 second
;
; #include "../../common/msp430g2552-defs.s"

    .equ    WDTCTL,     0x0120
    .equ    WDTPW,      0x5A00
    .equ    WDTHOLD,    0x0080

    .equ    BCSCTL1,    0x0057
    .equ    DCOCTL,     0x0056
    .equ    BCSCTL3,    0x0053

    ; TI factory calibration constants in Info Flash segment A
    .equ    CALBC1_1MHZ,  0x10FF   ; BCSCTL1 value for 1 MHz
    .equ    CALDCO_1MHZ,  0x10FE   ; DCOCTL  value for 1 MHz

    .equ    P1DIR,  0x0022
    .equ    P1OUT,  0x0021

    .equ    BIT0,   0x01            ; P1.0 = LED1 Red
    .equ    BIT6,   0x40            ; P1.6 = LED2 Green

    .text
    .global main

main:
    ; --- Disable watchdog timer ---
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL

    ; --- Configure DCO to 1 MHz ---
    ; Must clear DCOCTL before changing BCSCTL1 to avoid a frequency glitch
    clr.b   &DCOCTL                     ; Step 1: clear fine-tune register
    mov.b   &CALBC1_1MHZ, &BCSCTL1     ; Step 2: set range for 1 MHz
    mov.b   &CALDCO_1MHZ, &DCOCTL      ; Step 3: fine-tune for 1 MHz
    ; MCLK = SMCLK = 1,000,000 Hz (±1%)

    ; --- Configure GPIO ---
    bis.b   #(BIT0|BIT6), &P1DIR       ; P1.0 and P1.6 as outputs
    bic.b   #(BIT0|BIT6), &P1OUT       ; both LEDs off initially

    ; --- Initialize loop counter for LED2 ---
    ; R4 counts 100ms ticks; every 10 ticks (1 second) toggle LED2
    mov.w   #0, R4

main_loop:
    ; Toggle LED1 every 100ms
    xor.b   #BIT0, &P1OUT              ; toggle Red LED

    ; Wait 100ms
    call    #delay_100ms

    ; Increment 1-second counter
    inc.w   R4
    cmp.w   #10, R4                    ; reached 10 × 100ms = 1 second?
    jne     main_loop                  ; no — keep looping

    ; 1 second elapsed — toggle LED2 and reset counter
    xor.b   #BIT6, &P1OUT              ; toggle Green LED
    mov.w   #0, R4                     ; reset counter

    jmp     main_loop


; --- Subroutine: set_1mhz ---
; Sets DCO to 1 MHz using TI calibration constants from Info Flash.
; Modifies: DCOCTL, BCSCTL1
; Preserves: all registers
;
; Note: In main above we call this inline. This subroutine version is provided
; for reference and for use in other programs.
set_1mhz:
    clr.b   &DCOCTL                     ; clear before range change (avoids glitch)
    mov.b   &CALBC1_1MHZ, &BCSCTL1     ; coarse range for 1 MHz
    mov.b   &CALDCO_1MHZ, &DCOCTL      ; fine tune for 1 MHz
    ret


; --- Subroutine: delay_100ms ---
; Busy-wait delay of approximately 100 milliseconds at 1 MHz MCLK.
;
; Timing:
;   Loop count = 33,333 iterations
;   Cycles per iteration = 3 (dec.w = 1, jnz taken = 2)
;   Total cycles = 33,333 × 3 = 99,999
;   At 1,000,000 Hz: 99,999 / 1,000,000 = 0.099999s ≈ 100ms
;
; NOTE: If the clock speed changes, this count must be recalculated!
;   At 8 MHz the same count produces 12.5ms, not 100ms.
;
; Modifies: R5
; Preserves: all other registers
delay_100ms:
    mov.w   #33333, R5          ; iteration count for ~100ms at 1 MHz
delay_100ms_loop:
    dec.w   R5                  ; 1 cycle: decrement counter
    jnz     delay_100ms_loop    ; 2 cycles (taken): loop if not zero
    ret                         ; (branch not taken on exit = 1 cycle, negligible)


; --- Subroutine: delay_1s ---
; Busy-wait delay of approximately 1 second at 1 MHz MCLK.
; Implemented by calling delay_100ms 10 times.
;
; Timing: 10 × 100ms = 1,000ms = 1.0 seconds
;
; Modifies: R6 (loop counter), R5 (used by delay_100ms)
; Preserves: all other registers
delay_1s:
    mov.w   #10, R6             ; call delay_100ms 10 times
delay_1s_loop:
    call    #delay_100ms        ; ~100ms each call
    dec.w   R6                  ; decrement outer counter
    jnz     delay_1s_loop       ; loop until 10 calls done
    ret


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
