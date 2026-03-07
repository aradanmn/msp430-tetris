;******************************************************************************
; Lesson 13 - Exercise 3: Command Interpreter
;
; Single-character command interpreter over UART (interrupt-driven RX):
;   '1' → LED1 ON,  print "LED1 ON\r\n"
;   '0' → LED1 OFF, print "LED1 OFF\r\n"
;   't' → Toggle LED1, print "TOGGLE\r\n"
;   '?' → print "Commands: 0 1 t ?\r\n"
;   else → print "?\r\n"
;******************************************************************************
#include "../../../common/msp430g2552-defs.s"

        .equ    UART_RX,  BIT1
        .equ    UART_TX,  BIT2

        .data
rx_char:    .byte   0
rx_ready:   .byte   0

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        bis.b   #LED1, &P1DIR
        bic.b   #LED1, &P1OUT

        bis.b   #UCSWRST, &UCA0CTL1
        mov.b   #0x00, &UCA0CTL0
        mov.b   #(UCSSEL_2|UCSWRST), &UCA0CTL1
        mov.b   #104, &UCA0BR0
        mov.b   #0,   &UCA0BR1
        mov.b   #0x02, &UCA0MCTL
        bis.b   #(UART_RX|UART_TX), &P1SEL
        bis.b   #(UART_RX|UART_TX), &P1SEL2
        bic.b   #UCSWRST, &UCA0CTL1

        bis.b   #UCA0RXIE, &IE2
        bis.w   #GIE, SR

        mov.w   #help_str, R14
        call    #uart_puts

main_loop:
        bis.w   #(GIE|CPUOFF), SR
        nop

        tst.b   &rx_ready
        jz      main_loop
        clr.b   &rx_ready

        ; TODO: read rx_char and dispatch on its value:
        ;   '1' → bis.b #LED1, &P1OUT; send on_str
        ;   '0' → bic.b #LED1, &P1OUT; send off_str
        ;   't' → xor.b #LED1, &P1OUT; send tog_str
        ;   '?' → send help_str
        ;   else → send err_str

        jmp     main_loop

;----------------------------------------------------------------------
; USCI_A0 RX ISR
;----------------------------------------------------------------------
USCI_RX_ISR:
        mov.b   &UCA0RXBUF, &rx_char
        mov.b   #1, &rx_ready
        bic.w   #CPUOFF, 0(SP)
        reti

;----------------------------------------------------------------------
; uart_putc, uart_puts
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

        .section ".rodata"
on_str:
        .byte 'L','E','D','1',' ','O','N','\r','\n',0
off_str:
        .byte 'L','E','D','1',' ','O','F','F','\r','\n',0
tog_str:
        .byte 'T','O','G','G','L','E','\r','\n',0
help_str:
        .byte 'C','o','m','m','a','n','d','s',':',' ','0',' ','1',' ','t',' ','?','\r','\n',0
err_str:
        .byte '?','\r','\n',0

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
        .word   USCI_RX_ISR          ; 0xFFEC - USCI RX
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
