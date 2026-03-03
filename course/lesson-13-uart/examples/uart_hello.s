;******************************************************************************
; Lesson 13 - Example: UART Hello + Echo
;
; Sends "Hello!\r\n" over UART at 9600 baud, then echoes every received byte.
;
; Hardware (MSP430G2552 LaunchPad):
;   P1.1 = UCA0RXD (connect to emulator RXD via jumper)
;   P1.2 = UCA0TXD (connect to emulator TXD via jumper)
;
; Host terminal: picocom -b 9600 /dev/ttyACM0
;******************************************************************************
#include "../../common/msp430g2552-defs.s"

        .equ    UART_RX,  BIT1      ; P1.1 = UCA0RXD
        .equ    UART_TX,  BIT2      ; P1.2 = UCA0TXD

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL

        ; DCO = 1 MHz
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        ; LED1 on P1.0 as activity indicator
        bis.b   #LED1, &P1DIR
        bic.b   #LED1, &P1OUT

        ;------------------------------------------------------------------
        ; UART init — USCI_A0, 9600 baud, 8-N-1, SMCLK=1MHz
        ;------------------------------------------------------------------
        bis.b   #UCSWRST, &UCA0CTL1            ; hold in reset
        mov.b   #0x00, &UCA0CTL0               ; 8-N-1
        mov.b   #(UCSSEL_2|UCSWRST), &UCA0CTL1 ; SMCLK, still in reset
        mov.b   #104, &UCA0BR0                  ; 1MHz/9600 = 104
        mov.b   #0,   &UCA0BR1
        mov.b   #0x02, &UCA0MCTL               ; UCBRS0 modulation
        bis.b   #(UART_RX|UART_TX), &P1SEL     ; route pins to USCI
        bis.b   #(UART_RX|UART_TX), &P1SEL2
        bic.b   #UCSWRST, &UCA0CTL1            ; release from reset
        ;------------------------------------------------------------------

        ; Send greeting
        mov.w   #hello_str, R14
        call    #uart_puts

echo_loop:
        ; Wait for received byte, echo it, toggle LED1
        call    #uart_getc          ; R12 = received byte
        call    #uart_putc          ; echo back
        xor.b   #LED1, &P1OUT      ; activity blink
        jmp     echo_loop

;----------------------------------------------------------------------
; uart_putc — send one byte, poll TXIFG
; Input: R12 = byte to send
;----------------------------------------------------------------------
uart_putc:
_txwait:
        bit.b   #UCA0TXIFG, &IFG2
        jz      _txwait
        mov.b   R12, &UCA0TXBUF
        ret

;----------------------------------------------------------------------
; uart_puts — send null-terminated string
; Input: R14 = pointer to string
; Clobbers: R12, R14
;----------------------------------------------------------------------
uart_puts:
        push    R12
_puts_loop:
        mov.b   @R14+, R12
        tst.b   R12
        jz      _puts_done
        call    #uart_putc
        jmp     _puts_loop
_puts_done:
        pop     R12
        ret

;----------------------------------------------------------------------
; uart_getc — block until byte received, return in R12
;----------------------------------------------------------------------
uart_getc:
_rxwait:
        bit.b   #UCA0RXIFG, &IFG2
        jz      _rxwait
        mov.b   &UCA0RXBUF, R12
        ret

;----------------------------------------------------------------------
; String data in ROM
;----------------------------------------------------------------------
        .section ".rodata"
hello_str:
        .byte 'H','e','l','l','o','!','\r','\n',0

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
