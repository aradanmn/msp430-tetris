;******************************************************************************
; Lesson 02 — Exercise 3: Mini State Machine
;
; Implement a 3-state LED machine that advances through states automatically:
;
;   State 0 (ATTRACT):   LED1 blinks 3× at 400ms → advance to State 1
;   State 1 (RUNNING):   LED1+LED2 alternate 6× at 120ms → advance to State 2
;   State 2 (GAME OVER): both LEDs flash 4× at 60ms, 1s dark → back to State 0
;
; Hints:
;   - Store the current state in R8 (values 0, 1, 2).
;   - Use cmp.w and jeq to dispatch:
;
;       state_dispatch:
;           cmp.w   #0, R8
;           jeq     state_attract
;           cmp.w   #1, R8
;           jeq     state_running
;           jmp     state_game_over
;
;   - At the end of each state handler, set R8 to the next state
;     and jmp back to state_dispatch.
;   - Clear both LEDs at the start of each state handler so there's
;     no leftover light from the previous state.
;******************************************************************************

#include "../../../common/msp430g2553-defs.s"

    .text
    .global _start

#define state R8  ; holds the current state machine status
#define led R4
#define tms R5
#define count R6

_start:
    mov.w   #0x0400, SP
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1
    mov.b   &CALDCO_1MHZ, &DCOCTL

    bis.b   #(LED1|LED2), &P1DIR
    bic.b   #(LED1|LED2), &P1OUT

    mov.w   #0, state              ; start in State 0

; TODO: implement state_dispatch and the three state handlers below
state_dispatch:

    cmp.w   #0, R8
    jeq     state_attract
    cmp.w   #1, R8
    jeq     state_running
    jmp     state_game_over
    
state_attract:

    mov.w   #3, count       ; set flash count for attract state
    mov.w   #LED1, led      ; set which LED to flash
    mov.w   #400, tms       ; set how long each flash should take
    call    #flash_leds     ; call the sub
    mov.w   #1, state       ; set to running state
    jmp     state_dispatch  ; jump back to the state_dispatch
    
state_running:

    mov.w   #6, R7          ; use Register 7 for total loop count
    mov.w   #120, tms       ; 120ms on/off
.Lrunning_loop:
    mov.w   #1, count       ; set count to 1
    mov.w   #LED1, led      ; use LED1
    call    #flash_leds     ; flash LED1
    mov.w   #1, count       ; set count to 1
    mov.w   #LED2, led      ; use LED2
    call    #flash_leds     ; flash LED2
    dec.w   R7              ; decrement Register 7
    jnz     .Lrunning_loop  ; jump on non zero
    mov.w   #2, state       ; set state machine to 2
    jmp     state_dispatch  ; jump to state_dispatch
    
state_game_over:

    mov.w   #4, count       ; set flash count for game over state
    mov.w   #(LED1|LED2), led   ; use both LEDs
    mov.w   #60, tms        ; on/off time
    call    #flash_leds     ; flash the LEDs
    mov.w   #1000, R12      ; set a 1 second wait
    call    #delay_ms       ; wait 1 second
    mov.w   #0, state       ; set state to attract
    jmp     state_dispatch  ; jump to state_dispatch

flash_leds:
    bic.b   #(LED1|LED2), &P1OUT    ; ensure the LEDs are off first
    bis.b   led, &P1OUT             ; Set the LED high or 1
    mov.w   tms, R12                ; set wait time to register 12
    call    #delay_ms               ; wait time in ms
    bic.b   led, &P1OUT             ; turn off LED(s)
    mov.w   tms, R12                ; set wait time to register 12
    call    #delay_ms               ; wait time in ms
    dec.w   count                   ; decrease the loop counter
    jnz     flash_leds              ; on non zero jump to start of sub
    bic.b   #(LED1|LED2), &P1OUT    ; ensure the LEDs are off (known state)
    ret

delay_ms:
    mov.w   #333, R13
.Ldms_inner:
    dec.w   R13
    jnz     .Ldms_inner
    dec.w   R12
    jnz     delay_ms
    ret

    .section ".vectors","ax",@progbits
    .word   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .word   _start
    .end
