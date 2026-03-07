;******************************************************************************
; Lesson 13 - Exercise 1: Hex Byte Printer
;
; Receive bytes over UART and print each as two hex digits + space.
; Example: type 'A' (0x41) → prints "41 "
;******************************************************************************
#include "../../../common/msp430g2552-defs.s"

        .equ    UART_RX,  BIT1
        .equ    UART_TX,  BIT2

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        ; UART init 9600 baud
        bis.b   #UCSWRST, &UCA0CTL1
        mov.b   #0x00, &UCA0CTL0
        mov.b   #(UCSSEL_2|UCSWRST), &UCA0CTL1
        mov.b   #104, &UCA0BR0
        mov.b   #0,   &UCA0BR1
        mov.b   #0x02, &UCA0MCTL
        bis.b   #(UART_RX|UART_TX), &P1SEL
        bis.b   #(UART_RX|UART_TX), &P1SEL2
        bic.b   #UCSWRST, &UCA0CTL1

        mov.w   #ready_str, R14
        call    #uart_puts

hex_loop:
        call    #uart_getc          ; R12 = received byte
        ; TODO: call print_hex to display as two hex digits + space
        jmp     hex_loop

;----------------------------------------------------------------------
; print_hex — print R12 as two hex digits followed by a space
; Clobbers: R12, R13, R14
;----------------------------------------------------------------------
print_hex:
        ; TODO: extract high nibble, convert, send
        ;       extract low  nibble, convert, send
        ;       send a space
        ret

;----------------------------------------------------------------------
; nibble_to_ascii — convert 0-15 to '0'-'9' or 'A'-'F'
; Input:  R12 = nibble (0..15)
; Output: R12 = ASCII character
;----------------------------------------------------------------------
nibble_to_ascii:
        ; TODO: if R12 < 10 → add '0', else → subtract 10 and add 'A'
        ret

;----------------------------------------------------------------------
; uart_putc, uart_puts, uart_getc (same as uart_hello.s)
;----------------------------------------------------------------------
uart_putc:
_txwait:
        bit.b   #UCA0TXIFG, &IFG2
        jz      _txwait
        mov.b   R12, &UCA0TXBUF
        ret

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

uart_getc:
_rxwait:
        bit.b   #UCA0RXIFG, &IFG2
        jz      _rxwait
        mov.b   &UCA0RXBUF, R12
        ret

        .section ".rodata"
ready_str:
        .byte 'H','e','x',' ','p','r','i','n','t','e','r','\r','\n',0

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
