;******************************************************************************
; Lesson 04 — Exercise 3 Solution: Adjustable-Speed Blinker
;******************************************************************************

#include "../../../../common/msp430g2553-defs.s"

    .text
    .global _start

;==============================================================================
; Constants
;==============================================================================
.equ TICK_PERIOD,   9999    ; 10 ms at 1 MHz
.equ NUM_SPEEDS,       4

.equ SPD0_TICKS,      50    ; 500 ms → 1 Hz
.equ SPD1_TICKS,      25    ; 250 ms → 2 Hz
.equ SPD2_TICKS,      10    ; 100 ms → 5 Hz
.equ SPD3_TICKS,       5    ;  50 ms → 10 Hz

.equ ACK_TICKS,       20    ; 200 ms LED2 flash

_start:
    mov.w   #0x0400, SP
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1
    mov.b   &CALDCO_1MHZ, &DCOCTL

    bis.b   #(LED1|LED2), &P1DIR
    bic.b   #(LED1|LED2), &P1OUT

    bic.b   #BTN, &P1DIR
    bis.b   #BTN, &P1REN
    bis.b   #BTN, &P1OUT

    mov.w   #TICK_PERIOD, &TACCR0
    mov.w   #(TASSEL_2|MC_1|TACLR), &TACTL

    ; --- Initialize state ---
    clr.w   R8                          ; speed index = 0
    clr.w   R7                          ; LED2 ack countdown = 0 (off)
    call    #apply_speed                ; R9 = SPD0_TICKS
    mov.w   R9, R6                      ; LED1 blink countdown

    ; --- Seed previous button state ---
    mov.b   &P1IN, R10
    and.w   #BTN, R10

;==============================================================================
; Main loop — runs once per 10 ms tick
;==============================================================================
main_loop:

    ; --- Wait for next tick ---
    bit.w   #TAIFG, &TACTL
    jz      main_loop
    bic.w   #TAIFG, &TACTL

    ; --- Button edge detection ---
    mov.b   &P1IN, R11
    and.w   #BTN, R11               ; R11 = BTN (released) or 0 (pressed)

    tst.w   R11                     ; pressed now?
    jnz     .Lbtn_update            ; no (HIGH) — skip press logic
    cmp.w   #BTN, R10               ; was it released last tick?
    jne     .Lbtn_update            ; no — already held, not a new press

    ; --- New press detected (falling edge) ---
    inc.w   R8                      ; advance speed index
    cmp.w   #NUM_SPEEDS, R8
    jlo     .Lno_wrap
    clr.w   R8                      ; wrap to 0
.Lno_wrap:
    call    #apply_speed            ; update R9 for new speed
    mov.w   R9, R6                  ; reset blink countdown immediately
    mov.w   #ACK_TICKS, R7         ; start LED2 ack flash

.Lbtn_update:
    mov.w   R11, R10                ; save current state

    ; --- LED1 blink channel ---
    dec.w   R6
    jnz     .Lled1_skip
    xor.b   #LED1, &P1OUT
    mov.w   R9, R6                  ; reload from current speed setting
.Lled1_skip:

    ; --- LED2 ack channel ---
    tst.w   R7
    jz      .Lled2_off
    bis.b   #LED2, &P1OUT           ; ack flash active
    dec.w   R7
    jmp     .Lled2_done
.Lled2_off:
    bic.b   #LED2, &P1OUT           ; ack expired — LED2 off
.Lled2_done:

    jmp     main_loop

;==============================================================================
; apply_speed — load tick count for speed R8 into R9
;
; Args:     R8 = speed index (0–3)
; Returns:  R9 = tick count
; Clobbers: nothing
;==============================================================================
apply_speed:
    cmp.w   #0, R8
    jeq     .Lspd0
    cmp.w   #1, R8
    jeq     .Lspd1
    cmp.w   #2, R8
    jeq     .Lspd2
    ; else speed 3
    mov.w   #SPD3_TICKS, R9
    ret
.Lspd0:
    mov.w   #SPD0_TICKS, R9
    ret
.Lspd1:
    mov.w   #SPD1_TICKS, R9
    ret
.Lspd2:
    mov.w   #SPD2_TICKS, R9
    ret

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .word   _start
    .end
