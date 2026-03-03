;******************************************************************************
; Lesson 06 - Exercise 3: Heartbeat Watchdog with ACLK
;
; WDT clocked from ACLK (VLO ~12kHz).  Timeout = VLO/32768 ≈ 2.7 seconds.
; Main loop blinks LED1 five times quickly then pets the watchdog.
; If the loop ever hangs, the 2.7s timeout triggers a reset.
;******************************************************************************
#include "../../../common/msp430g2552-defs.s"

        .text
        .global main

main:
        ; TODO: Configure WDT in watchdog mode using ACLK
        ;   WDTSSEL=1 selects ACLK (VLO ≈ 12kHz)
        ;   WDTCNTCL clears counter
        ;   No WDTTMSEL (watchdog, not interval)
        ;   No WDTHOLD (let it run)
        ;   mov.w #(WDTPW|WDTCNTCL|WDTSSEL), &WDTCTL

        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        bis.b   #LED1, &P1DIR
        bic.b   #LED1, &P1OUT

loop:
        ; Heartbeat: 5 quick blinks
        mov.w   #5, R13
blink5:
        bis.b   #LED1, &P1OUT
        mov.w   #50, R12
        call    #delay_ms
        bic.b   #LED1, &P1OUT
        mov.w   #50, R12
        call    #delay_ms
        dec.w   R13
        jnz     blink5

        ; TODO: Pet the watchdog here
        ;       mov.w #(WDTPW|WDTCNTCL|WDTSSEL), &WDTCTL

        ; 500ms pause before next heartbeat
        mov.w   #500, R12
        call    #delay_ms
        jmp     loop

delay_ms:
        mov.w   #250, R15
_dms:   dec.w   R15
        jnz     _dms
        dec.w   R12
        jnz     delay_ms
        ret

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
