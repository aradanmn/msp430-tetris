;******************************************************************************
; Lesson 03 — Exercise 3: Press-to-Cycle Patterns
;
; Behaviour:
;   The button cycles through four LED states, one per press:
;
;     State 0 (IDLE)      — both LEDs off
;     State 1 (RED)       — LED1 on, LED2 off
;     State 2 (GREEN)     — LED1 off, LED2 on
;     State 3 (BOTH)      — LED1 on, LED2 on
;     next press → back to State 0
;
;   Each press must be fully debounced. The state updates instantly on
;   confirmed press (before waiting for release).
;
; Requirements:
;   - State stored in a register (R8 recommended)
;   - State advances 0→1→2→3→0 using inc.w + cmp.w + jlo (or jge + clr)
;   - Separate subroutine `apply_state` that reads R8 and drives LEDs
;     (subroutine must end with ret)
;   - Debounce on both press and release
;   - No magic numbers: state values and timing as .equ constants
;
; New instruction: inc.w Rn
;   Increments Rn by 1. Equivalent to add.w #1, Rn but one word shorter.
;
; Wrapping the counter:
;   After inc.w R8, compare to the total number of states.
;   If equal (all states exhausted), reset to 0.
;
;     inc.w   R8
;     cmp.w   #4, R8          ; 4 states total (0–3)
;     jlo     skip_wrap       ; R8 < 4 → no wrap needed
;     clr.w   R8              ; R8 >= 4 → wrap to 0
;   skip_wrap:
;
; apply_state subroutine hint:
;   Use cmp.w + jeq to check each state value and branch to the appropriate
;   LED setup code. Always bic.b both LEDs first, then bis.b only the ones
;   that should be on. End every branch path with ret.
;******************************************************************************

#include "../../../common/msp430g2553-defs.s"

    .text
    .global _start

;==============================================================================
; Constants
;==============================================================================
.equ DEBOUNCE_MS,   20
.equ STATE_IDLE,     0
.equ STATE_RED,      1
.equ STATE_GREEN,    2
.equ STATE_BOTH,     3
.equ NUM_STATES,     4

_start:
    mov.w   #0x0400, SP
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1
    mov.b   &CALDCO_1MHZ, &DCOCTL

    ; TODO: configure LED1 and LED2 as outputs, both OFF
    bis.b #(LED1|LED2), &P1DIR
    bic.b #(LED1|LED2), &P1OUT

    ; TODO: configure BTN as input with pull-up
    bic.b #BTN, &P1DIR
    bis.b #BTN, &P1REN
    bis.b #BTN, &P1OUT

    ; TODO: initialize state register R8 to STATE_IDLE
    mov.w #STATE_IDLE, R8
    ; TODO: call apply_state to set initial LED output
    call #apply_state

; TODO: main press/release loop
;   wait_press → debounce → confirm
;   inc.w R8 → wrap if needed
;   call apply_state
;   wait_release → debounce → confirm
;   loop
main_loop:
    call #wait_button_press ;
    call #apply_state
    call #wait_button_release
    jmp main_loop

;==============================================================================
; apply_state — drive LEDs based on state in R8
;
; Args:     R8 = current state (0–3)
; Returns:  nothing
; Clobbers: nothing (does not call delay_ms)
;==============================================================================
apply_state:
    ; TODO: implement
    ;   Turn off both LEDs first (defensive)
    ;   Then turn on the correct combination based on R8
    ;   End with ret
    bic.b #(LED1|LED2), &P1OUT
    cmp.w #STATE_IDLE, R8
    jeq .Lstate_idle
    cmp.w #STATE_RED, R8
    jeq .Lstate_red
    cmp.w #STATE_GREEN, R8
    jeq .Lstate_green
    cmp.w #STATE_BOTH, R8
    jeq .Lstate_both
    ret
.Lstate_idle:
    bic.b #(LED1|LED2), &P1OUT
    ret
.Lstate_red:
    bis.b #LED1, &P1OUT
    bic.b #LED2, &P1OUT
    ret
.Lstate_green:
    bic.b #LED1, &P1OUT
    bis.b #LED2, &P1OUT
    ret
.Lstate_both:
    bis.b #(LED1|LED2), &P1OUT
    ret

wait_button_press:
.Lwbp_wait_press:
    bit.b #BTN, &P1IN   ;check if P1.3 is high, or
    jnz .Lwbp_wait_press   ;

    mov.w #DEBOUNCE_MS, R12 ; wait n ms for switch to settle.
    call #delay_ms

    bit.b #BTN, &P1IN ; check BTN register
    jnz .Lwbp_wait_press   ;

    call #change_state
    ret

wait_button_release:
.Lwbp_wait_release:
    bit.b #BTN, &P1IN
    jz .Lwbp_wait_release

    mov.w #DEBOUNCE_MS, R12
    call #delay_ms

    bit.b #BTN, &P1IN
    jz .Lwbp_wait_release

    ret

change_state:
    inc.w R8
    cmp.w #4, R8
    jlo skip_wrap
    clr.w R8
skip_wrap:
    ret

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
