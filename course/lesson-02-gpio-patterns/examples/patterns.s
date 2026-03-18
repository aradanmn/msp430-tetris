;******************************************************************************
; Lesson 02 Example — Patterns
;
; Cycles through three game-state simulations forever:
;
;   ATTRACT   — LED1 pulses slowly 3× (hardware alive, waiting for player)
;   RUNNING   — LED1 and LED2 alternate fast 10× (game in progress)
;   GAME OVER — both LEDs flash 5× rapidly, then 1s dark
;
; Key techniques demonstrated:
;   - flash_leds subroutine: R4=mask, R5=count, R6=half-period(ms)
;   - dec.w / jnz counted loop (no stack push/pop needed)
;   - bis.b / bic.b for explicit on/off (predictable state at every step)
;   - clean phase sequencing in main_loop
;
; Hardware: MSP-EXP430G2 LaunchPad  (LED1=P1.0 Red, LED2=P1.6 Green)
; Clock:    1 MHz (DCO calibrated)
;******************************************************************************

#include "../../common/msp430g2553-defs.s"

    .text
    .global _start

;==============================================================================
; _start — one-time initialization
;==============================================================================
_start:
    ; --- 0. Initialize Stack Pointer ---
    mov.w   #0x0400, SP

    ; --- 1. Stop watchdog ---
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL

    ; --- 2. Calibrate DCO to 1 MHz ---
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1
    mov.b   &CALDCO_1MHZ, &DCOCTL

    ; --- 3. Configure LED1 and LED2 as outputs, both off ---
    bis.b   #(LED1|LED2), &P1DIR
    bic.b   #(LED1|LED2), &P1OUT

;==============================================================================
; main_loop — cycle through three game-state phases indefinitely
;==============================================================================
main_loop:

    ; -----------------------------------------------------------------------
    ; Phase 1: ATTRACT — LED1 pulses slowly (3 flashes, 500ms on/off)
    ; -----------------------------------------------------------------------
    mov.w   #LED1,  R4          ; bitmask
    mov.w   #3,     R5          ; flash count
    mov.w   #500,   R6          ; half-period: 500ms on, 500ms off
    call    #flash_leds

    mov.w   #500, R12           ; 500ms dark gap before next phase
    call    #delay_ms

    ; -----------------------------------------------------------------------
    ; Phase 2: RUNNING — LED1/LED2 alternate fast (10 pairs, 100ms each)
    ;
    ; Alternating requires explicit set/clear on each half-cycle so the two
    ; LEDs are always in opposite states.
    ; -----------------------------------------------------------------------
    mov.w   #10, R7             ; R7 = iteration counter
.Lrunning:
    bis.b   #LED1, &P1OUT       ; LED1 on
    bic.b   #LED2, &P1OUT       ; LED2 off
    mov.w   #100, R12
    call    #delay_ms
    bic.b   #LED1, &P1OUT       ; LED1 off
    bis.b   #LED2, &P1OUT       ; LED2 on
    mov.w   #100, R12
    call    #delay_ms
    dec.w   R7
    jnz     .Lrunning

    bic.b   #(LED1|LED2), &P1OUT ; both off before next phase
    mov.w   #500, R12
    call    #delay_ms

    ; -----------------------------------------------------------------------
    ; Phase 3: GAME OVER — both LEDs flash rapidly 5×, then 1s dark
    ; -----------------------------------------------------------------------
    mov.w   #(LED1|LED2), R4    ; both LEDs
    mov.w   #5,           R5    ; 5 flashes
    mov.w   #80,          R6    ; 80ms on, 80ms off
    call    #flash_leds

    mov.w   #1000, R12          ; 1 second dark
    call    #delay_ms

    jmp     main_loop

;==============================================================================
; flash_leds — flash one or more LEDs a fixed number of times
;
; Args:   R4 = LED bitmask  (e.g. LED1, LED2, or LED1|LED2)
;         R5 = number of flashes
;         R6 = half-period in ms  (on-time = off-time = R6 ms)
;
; Clobbers: R5 (counts down to 0), R12, R13 (used by delay_ms)
; Preserves: R4, R6
;
; Implementation note:
;   "jnz flash_leds" is a backward conditional JUMP, not a recursive call.
;   No extra return address is pushed. The single "ret" returns to the
;   original caller after all flashes are done.
;==============================================================================
flash_leds:
    bis.b   R4, &P1OUT          ; LEDs on
    mov.w   R6, R12             ; load half-period into R12 for delay_ms
    call    #delay_ms           ; wait  (clobbers R12, R13; R4/R5/R6 safe)
    bic.b   R4, &P1OUT          ; LEDs off
    mov.w   R6, R12
    call    #delay_ms           ; wait
    dec.w   R5                  ; flash count--
    jnz     flash_leds          ; repeat if more flashes remain
    ret

;==============================================================================
; delay_ms — software delay
;
; Arg:     R12 = milliseconds to wait
; Clobbers: R12, R13
;
; At 1 MHz: inner loop = 333 × 3 cycles ≈ 999 µs ≈ 1 ms
;==============================================================================
delay_ms:
    mov.w   #333, R13
.Ldms_inner:
    dec.w   R13
    jnz     .Ldms_inner
    dec.w   R12
    jnz     delay_ms
    ret

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .word   _start
    .end
