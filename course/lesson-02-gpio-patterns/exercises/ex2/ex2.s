;******************************************************************************
; Lesson 02 — Exercise 2: Dual Throb
;
; LED1 flashes 3× fast (100ms on/off),
; then LED2 flashes 3× fast (100ms on/off),
; then both off for 500ms, repeat forever.
;
; Hints:
;   - You need two separate counted loops, one after the other.
;   - Reload R7 with #3 before each burst.
;   - Make sure the inactive LED is explicitly off during each burst
;     (use bic.b to be certain).
;******************************************************************************

#include "../../../common/msp430g2553-defs.s"

    .text
    .global _start

_start:
    mov.w   #0x0400, SP
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1
    mov.b   &CALDCO_1MHZ, &DCOCTL

    ; TODO: configure both LEDs as outputs, both off
    bis.b   #(LED1|LED2), &P1DIR
    bic.b   #(LED1|LED2), &P1OUT

main_loop:
    ; TODO: flash LED1 3× at 100ms (LED2 off during this burst)
    ; first ensure LED2 is off
    bic.b #LED2, &P1OUT
    ; second flash LED1 3x
    mov.w #LED1, R4
    mov.w #3,   R5
    mov.w #100, R6
    call #flash_leds
    ; TODO: flash LED2 3× at 100ms (LED1 off during this burst)
    ; first ensure LED1 is off
    bic.b #LED1, & P1OUT
    ; second flash LED2 3x
    mov.w #LED2, R4
    mov.w #3,   R5
    mov.w #100, R6
    call #flash_leds

    ; TODO: 500ms dark gap
    mov.w #500, R12
    call #delay_ms
    
    jmp     main_loop
; flash_leds - flash one led or more LEDs a fixed number of times
;
; Args: R4 = LED bitmask    (e.q. LED1, or LED2, or LED1|LED2)
;       R5 = flash count
;       R6 = LED on/off time in ms.

flash_leds:
    bis.b   R4, &P1OUT
    mov.w   R6, R12
    call    #delay_ms
    bic.b   R4, &P1OUT
    mov.w   R6, R12
    call    #delay_ms
    dec.w   R5
    jnz     flash_leds
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
