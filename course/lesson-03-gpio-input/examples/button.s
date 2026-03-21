;******************************************************************************
; Lesson 03 Example — Button Input Modes
;
; Runs three phases in sequence to demonstrate the three input techniques:
;
;   Phase 1: LEVEL DETECTION (5 seconds)
;     LED1 tracks the button continuously: ON while held, OFF when released.
;     No debounce needed — we don't care about individual edges.
;
;   Phase 2: TRANSITION (3 quick LED flashes to signal mode change)
;
;   Phase 3: EDGE DETECTION (forever)
;     Each complete press+release cycle toggles LED1 exactly once.
;     Full debounce applied to both press and release edges.
;     LED2 flashes briefly to confirm each recognized press.
;
; Hardware: MSP-EXP430G2 LaunchPad
;   LED1 = P1.0 (Red)    LED2 = P1.6 (Green)    S2 = P1.3 (active LOW)
; Clock: 1 MHz (DCO calibrated)
;******************************************************************************

#include "../../common/msp430g2553-defs.s"

    .text
    .global _start

;==============================================================================
; Constants
;==============================================================================
.equ LEVEL_DURATION_MS, 5000    ; how long to run level-detection phase
.equ DEBOUNCE_MS,          20   ; debounce window for both edges
.equ ACK_FLASH_MS,         80   ; LED2 confirmation flash duration

;==============================================================================
; _start — one-time initialization
;==============================================================================
_start:
    mov.w   #0x0400, SP
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL

    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1
    mov.b   &CALDCO_1MHZ, &DCOCTL

    ; --- Configure LED1 and LED2 as outputs, both off ---
    bis.b   #(LED1|LED2), &P1DIR
    bic.b   #(LED1|LED2), &P1OUT

    ; --- Configure BTN (P1.3) as input with pull-up ---
    ;
    ;   bic.b: clear P1DIR bit 3  → P1.3 is an input
    ;   bis.b: set   P1REN bit 3  → enable internal resistor on P1.3
    ;   bis.b: set   P1OUT bit 3  → resistor pulls UP (pin = HIGH when released)
    ;
    bic.b   #BTN, &P1DIR
    bis.b   #BTN, &P1REN
    bis.b   #BTN, &P1OUT

;==============================================================================
; Phase 1: LEVEL DETECTION
;
; Run for LEVEL_DURATION_MS. LED1 is ON while button is held, OFF otherwise.
; R8 counts down from LEVEL_DURATION_MS in 1ms steps.
;
; Note: bit.b + jz/jnz happens so fast (~1µs) that the polling overhead
; is negligible. The 1ms delay per loop iteration gives predictable duration.
;==============================================================================
    mov.w   #LEVEL_DURATION_MS, R8     ; R8 = countdown (ms)

level_loop:
    bit.b   #BTN, &P1IN                ; test P1.3
    jnz     level_off                  ; bit = 1 → released → LED off
    bis.b   #LED1, &P1OUT              ; bit = 0 → pressed  → LED on
    jmp     level_tick
level_off:
    bic.b   #LED1, &P1OUT
level_tick:
    mov.w   #1, R12
    call    #delay_ms                  ; 1ms tick
    dec.w   R8
    jnz     level_loop

    bic.b   #(LED1|LED2), &P1OUT      ; both off before transition

;==============================================================================
; Transition: 3 quick flashes on both LEDs to signal mode change
;==============================================================================
    mov.w   #3, R7
transition_loop:
    bis.b   #(LED1|LED2), &P1OUT
    mov.w   #150, R12
    call    #delay_ms
    bic.b   #(LED1|LED2), &P1OUT
    mov.w   #150, R12
    call    #delay_ms
    dec.w   R7
    jnz     transition_loop

    mov.w   #500, R12
    call    #delay_ms                  ; 500ms dark gap

;==============================================================================
; Phase 2: EDGE DETECTION (runs forever)
;
; Each complete press+release cycle:
;   1. Wait for press (LOW), debounce, confirm
;   2. Toggle LED1
;   3. Flash LED2 briefly as acknowledgement
;   4. Wait for release (HIGH), debounce, confirm
;   5. Repeat
;
; The confirm step after debounce is essential: if the pin bounced back to
; HIGH within the debounce window, we discard the event and retry.
;==============================================================================
edge_wait_press:
    bit.b   #BTN, &P1IN
    jnz     edge_wait_press             ; bit = 1 → released → keep waiting

    ; --- first LOW: start debounce ---
    mov.w   #DEBOUNCE_MS, R12
    call    #delay_ms

    ; --- re-read: still pressed? ---
    bit.b   #BTN, &P1IN
    jnz     edge_wait_press             ; was a glitch → start over

    ; --- confirmed press ---
    xor.b   #LED1, &P1OUT              ; toggle LED1

    ; --- brief LED2 flash: acknowledgement of the press ---
    bis.b   #LED2, &P1OUT
    mov.w   #ACK_FLASH_MS, R12
    call    #delay_ms
    bic.b   #LED2, &P1OUT

    ; --- wait for release ---
edge_wait_release:
    bit.b   #BTN, &P1IN
    jz      edge_wait_release           ; bit = 0 → still pressed → wait

    ; --- first HIGH: debounce release ---
    mov.w   #DEBOUNCE_MS, R12
    call    #delay_ms

    ; --- re-read: still released? ---
    bit.b   #BTN, &P1IN
    jz      edge_wait_release           ; glitch → start over

    ; --- confirmed release: ready for next press ---
    jmp     edge_wait_press

;==============================================================================
; delay_ms — software busy-wait
;
; Arg:      R12 = milliseconds
; Clobbers: R12, R13
; At 1 MHz: inner loop ≈ 333 × 3 cycles = 999 µs ≈ 1 ms
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
