;******************************************************************************
; hal/timer.s — Timer_A setup + CC0 ISR
;
; Provides:
;   timer_init  — configure Timer_A for 5 ms tick, enable CC0 interrupt
;   timer_isr   — CC0 ISR: tick counter, LED1 heartbeat, game_update call
;
; Register usage (see registers.md):
;   R4  — blink tick counter (persistent, decremented each tick)
;
; Added in: Lesson 05 Ex4
;******************************************************************************

; --- Timing constants (all derived from TICK_MS) ---
.equ TICK_MS,         5
.equ TICK_PERIOD,     (TICK_MS * 1000) - 1      ; 4999 — 5 ms at 1 MHz
.equ BLINK_TICKS,     250 / TICK_MS             ; 50 ticks = 250 ms → 2 Hz toggle
.equ STARTUP_TICKS,   200 / TICK_MS             ; 40 ticks = 200 ms LED2 pulse
.equ FRAME_TICKS,     20 / TICK_MS              ; 4 ticks = 20 ms → 50 FPS

;==============================================================================
; timer_init — Configure Timer_A: 5 ms tick, CC0 interrupt enabled
;==============================================================================
timer_init:
    mov.w   #TICK_PERIOD, &TACCR0
    mov.w   #CCIE, &TACCTL0             ; enable CC0 interrupt
    mov.w   #(TASSEL_2|MC_1|TACLR), &TACTL
    ret

;==============================================================================
; timer_isr — Timer_A CC0 ISR (fires every 5 ms)
;
; 1. Counts down startup LED2 pulse (R12 used as one-shot counter)
; 2. Decrements R4 (blink counter); on zero toggles LED1, reloads
; 3. (Future) Calls game_update every FRAME_TICKS
;==============================================================================
timer_isr:
    ; --- LED1 heartbeat (2 Hz) ---
    dec.w   R4
    jnz     .Lno_blink
    xor.b   #LED1, &P1OUT               ; toggle LED1
    mov.w   #BLINK_TICKS, R4            ; reload blink counter
.Lno_blink:

    ; --- Startup LED2 pulse (one-shot 200 ms) ---
    ; R12 is used as a one-shot countdown; starts at STARTUP_TICKS,
    ; counts down to 0, then stays at 0 forever.
    tst.w   R12
    jz      .Lstartup_done
    dec.w   R12
    jnz     .Lstartup_done
    bic.b   #LED2, &P1OUT               ; turn OFF LED2 after 200 ms
.Lstartup_done:

    reti
