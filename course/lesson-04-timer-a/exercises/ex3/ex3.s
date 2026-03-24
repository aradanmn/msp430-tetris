;******************************************************************************
; Lesson 04 — Exercise 3: Adjustable-Speed Blinker
;
; Builds on Exercises 1 and 2.
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
;   LED2 flashes for 200 ms after each speed change.
;
; Requirements:
;   - All timing values as .equ constants; no magic numbers
;   - write an apply_speed subroutine that sets the current blink rate
;   - Button edge detection driven by the timer tick — no blocking waits
;******************************************************************************

;******************************************************************************
; R4 - BTN PUSHED (BOOL), R5 - Unused, R6 - Unused, R7 - LED2_TICKS, R8 - NUM_SPEEDS,
; R9 - LED1_TICKS, R10 - Previous BTN V Level, R11 - Current BTN V Level


#include "../../../common/msp430g2553-defs.s"

	.text
	.global _start
; Target tick rate
.equ	TICK_MS,	    10
.equ 	TICK_PERIOD,	(TICK_MS * 1000) - 1   ; 9999

; LED blink rate based on tick rate
.equ 	NUM_SPEEDS,	    4
.equ    SPD_STATE0,     0
.equ    SPD_STATE1,     1
.equ    SPD_STATE2,     2
.equ    SPD_STATE3,     3
.equ 	SPEED_ZERO,	    500 / TICK_MS		; 50
.equ 	SPEED_ONE,	    250 / TICK_MS		; 25
.equ 	SPEED_TWO,	    100 / TICK_MS		; 10
.equ 	SPEED_THREE,	50  / TICK_MS		; 5
.equ 	LED2_TICKS,	    200 / TICK_MS		; 20

; Button logic
.equ	BTN_RELEASE,	0			; FALSE
.equ	BTN_PRESSED,	1			; TRUE

_start:
	mov.w   #0x0400,                SP
	mov.w   #(WDTPW|WDTHOLD), 	    &WDTCTL
	clr.b   &DCOCTL
	mov.b   &CALBC1_1MHZ,		    &BCSCTL1
	mov.b   &CALDCO_1MHZ,		    &DCOCTL

	; Initialize LEDs
	bis.b	#(LED1|LED2),		    &P1DIR
	bic.b	#(LED1|LED2),		    &P1OUT

	; Initialize Timer_A
	mov.w	#TICK_PERIOD,		    &TACCR0
	mov.w	#(TASSEL_2|MC_1|TACLR),	&TACTL

	; Initialize LED counters
	mov.w	#SPEED_ZERO,		    R9
	mov.w	#0,		                R7

	; Initialize BTN state
	mov.w	#BTN_RELEASE,		    R4	; set to zero
	mov.b	&P1IN,			        R10	; set current state
	and.w	#BTN,			        R10	; isolate BTN bit

	; Initialize starting state
;	mov.w	#SPD_STATE0,		    R8
	mov.w	#0,			            R8

main_loop:
	; Program flow check button press, if button was pressed change state,
	; by calling apply_speed.  Call flash_LED2, then jump back to start of
	; main_loop
	bit.w	#TAIFG, 		        &TACTL	; is the flag set?
	jz	main_loop			                ; no - keep checking
	bic.w	#TAIFG, 		        &TACTL	; yes - clear it and continue

	; flash LED1 every tick
	call	#flash_led1			            ; flash LED1
	call    #flash_led2

	; check for button press.
	call	#btn_check
	cmp.w	#BTN_PRESSED,		    R4
	jne	main_loop			            ; IF BTN wasn't pressed main_loop
	call	#change_speed
	mov.w	#BTN_RELEASE,		    R4	; clear button press
	mov.w   #LED2_TICKS,            R7
	jmp     main_loop

change_speed:

	inc.w	                        R8
	cmp.w	#NUM_SPEEDS,		    R8	; greater than 4?
	jne	.Lno_wrap
	clr.w	                        R8
.Lno_wrap:
	call	#apply_speed			    ; update counter
	ret

apply_speed:
	; check current state
	cmp.w	#SPD_STATE0,		    R8
	jeq	.Lspeed_zero
	cmp.w	#SPD_STATE1,		        R8
	jeq	.Lspeed_one
	cmp.w	#SPD_STATE2,		        R8
	jeq	.Lspeed_two
	cmp.w	#SPD_STATE3,		    R8
	jeq	.Lspeed_three
	ret
	; based on current state reset counter
.Lspeed_zero:
	mov.w	#SPEED_ZERO,		    R9
	ret
.Lspeed_one:
	mov.w	#SPEED_ONE,		        R9
	ret
.Lspeed_two:
	mov.w	#SPEED_TWO,		        R9
	ret
.Lspeed_three:
	mov.w	#SPEED_THREE,		    R9
	ret

flash_led1:

	dec.w	R9
	jnz	.Lled1_skip
	xor.b	#LED1,			&P1OUT	; toggle LED1
	call	#apply_speed
.Lled1_skip:
	ret

flash_led2:

    tst.w                       R7
    jz  .Lled2_skip
	bis.b   #LED2,  &P1OUT
	dec.w                       R7
	ret
.Lled2_skip:
    bic.b   #LED2, &P1OUT
	ret

btn_check:

	mov.b	&P1IN,			R11	; read current button state
	and.w	#BTN,			R11	; isolate BTN bit

	tst.w	R11				; is pin LOW now?
	jnz	.Lbtn_update			; no (HIGH) - skip press logic

	cmp.w	#BTN,			R10	; was pin HIGH last tick?
	jne	.Lbtn_update			; no - already was pressed, hold

	mov.w	#BTN_PRESSED,		R4	; confirmed button was pressed.
.Lbtn_update:
	mov.w	R11,			R10	; save current state as prev.
	ret

;==============================================================================
; Interrupt Vector Table
;==============================================================================
	.section ".vectors","ax",@progbits
	.word   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.word   _start
	.end
