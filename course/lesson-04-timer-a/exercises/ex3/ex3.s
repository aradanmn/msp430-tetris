;******************************************************************************
; Lesson 04 — Exercise 3: Adjustable-Speed Blinker
;
; Behaviour:
;   LED1 blinks continuously. Each button press cycles through four speeds:
;
;     Speed 0 (slow)   — toggle every 500 ms   (1 Hz)
;     Speed 1          — toggle every 250 ms   (2 Hz)
;     Speed 2          — toggle every 100 ms   (5 Hz)
;     Speed 3 (fast)   — toggle every  50 ms  (10 Hz)
;     next press → back to Speed 0
;
;   LED2 flashes for 200 ms after each speed change (acknowledgement).
;
; Requirements:
;   - Timer_A 10 ms tick (TACCR0 = TICK_PERIOD)
;   - Speed index in R8 (0–3), initialized to 0
;   - `apply_speed` subroutine: reads R8, loads tick count into R9, ends ret
;   - R6 = LED1 blink countdown (loaded from R9 via apply_speed)
;   - R7 = LED2 ack countdown (counts down from ACK_TICKS each press; 0=off)
;   - R10 = previous button sample (BTN=released, 0=pressed) — for edge detect
;   - All timing and count values as .equ constants
;
; Timer-based button edge detection (no blocking delay_ms):
;
;   On each tick, sample the button and compare to the previous sample.
;   A falling edge (prev=BTN, curr=0) means a new press has occurred.
;   The 10 ms sampling period provides natural debounce.
;
;   Template:
;     ; read current button state
;     mov.b   &P1IN, R11
;     and.w   #BTN, R11           ; R11 = BTN (released) or 0 (pressed)
;
;     ; detect falling edge: currently pressed AND was released last tick
;     tst.w   R11                 ; is it pressed now (zero)?
;     jnz     .Lbtn_update        ; no — skip press logic
;     cmp.w   #BTN, R10           ; was it released before?
;     jne     .Lbtn_update        ; no — was already held, not a new press
;
;     ; ---- NEW PRESS ----
;     ; advance speed, call apply_speed, reload R6
;     ; reload R7 with ACK_TICKS to start LED2 flash
;
;   .Lbtn_update:
;     mov.w   R11, R10            ; save current state as previous
;
; apply_speed subroutine hint:
;   Use cmp.w + jeq to dispatch on R8 (same pattern as apply_state in L03-Ex3).
;   Load the appropriate tick count into R9, then ret.
;
; LED2 ack flash:
;   In the main loop, after the button section:
;     tst.w   R7
;     jz      .Lled2_off
;     bis.b   #LED2, &P1OUT
;     dec.w   R7
;     jmp     .Lled2_done
;   .Lled2_off:
;     bic.b   #LED2, &P1OUT
;   .Lled2_done:
;
; Registers:
;   R6  = LED1 blink countdown
;   R7  = LED2 ack countdown  (0 = LED2 off)
;   R8  = speed index (0–3)
;   R9  = current speed tick count (set by apply_speed)
;   R10 = previous button sample
;   R11 = current button sample  (scratch, set each tick)
;******************************************************************************

#include "../../../common/msp430g2553-defs.s"

    .text
    .global _start

;==============================================================================
; Constants
;==============================================================================
.equ TICK_PERIOD,   9999    ; 10 ms at 1 MHz
.equ NUM_SPEEDS,       4    ; number of speed settings (0–3)

.equ SPD0_TICKS,      50    ; 50 × 10 ms = 500 ms  → 1 Hz
.equ SPD1_TICKS,      25    ; 25 × 10 ms = 250 ms  → 2 Hz
.equ SPD2_TICKS,      10    ; 10 × 10 ms = 100 ms  → 5 Hz
.equ SPD3_TICKS,       5    ;  5 × 10 ms =  50 ms  → 10 Hz

.equ ACK_TICKS,       20    ; 20 × 10 ms = 200 ms  LED2 flash on speed change

_start:
    mov.w   #0x0400, SP
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1
    mov.b   &CALDCO_1MHZ, &DCOCTL

    ; TODO: configure LED1 and LED2 as outputs, both OFF
    bis.b   #(LED1|LED2), &P1DIR
    bic.b   #(LED1|LED2), &P1OUT

    ; TODO: configure BTN as input with pull-up
    bic.b   #BTN, &P1DIR
    bis.b   #BTN, &P1REN
    bis.b   #BTN, &P1OUT

    ; TODO: configure Timer_A
    mov.w   #TICK_PERIOD, &TACCR0
    mov.w   #(TASSEL_2|MC_1|TACLR), &TACTL

    ; TODO: initialize state registers
    ;   R8  = 0 (start at speed 0)
    ;   R7  = 0 (LED2 ack off)
    ;   call apply_speed to populate R9
    ;   R6  = R9 (first blink countdown)
    ;   R10 = seed with current BTN state (read P1IN, and.w #BTN)

; TODO: main loop
main_loop:
    ; --- Wait for 10 ms tick ---

    ; --- Button edge detection ---
    ; (see template in header)

    ; --- LED1 blink channel ---
    ; dec R6, jnz skip, toggle LED1, reload from R9

    ; --- LED2 ack channel ---
    ; if R7 > 0: LED2 on, dec R7; else: LED2 off

    jmp     main_loop       ; placeholder

;==============================================================================
; apply_speed — load tick count for current speed into R9
;
; Args:     R8 = speed index (0–3)
; Returns:  R9 = tick count for that speed
; Clobbers: nothing else
;==============================================================================
apply_speed:
    ; TODO: implement with cmp.w + jeq dispatch
    ;   same pattern as apply_state from Lesson 03 Exercise 3
    ret

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .word   _start
    .end
