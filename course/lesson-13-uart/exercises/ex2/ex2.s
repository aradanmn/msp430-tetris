;******************************************************************************
; Lesson 13 - Exercise 2: Interrupt-Driven Echo
;
; Use the USCI_A0 RX interrupt (vector 0xFFEC) to receive bytes without
; busy-waiting.  Main sleeps in LPM0; the ISR wakes it when a byte arrives.
;******************************************************************************
#include "../../../common/msp430g2552-defs.s"

        .equ    UART_RX,  BIT1
        .equ    UART_TX,  BIT2

        .data
rx_char:    .byte   0       ; byte received by ISR
rx_ready:   .byte   0       ; 1 = new byte available

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        bis.b   #LED1, &P1DIR
        bic.b   #LED1, &P1OUT

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

        ; TODO: enable UCA0RXIE in IE2
        ; TODO: enable GIE in SR

        mov.w   #ready_str, R14
        call    #uart_puts

main_loop:
        ; TODO: enter LPM0 (bis.w #(GIE|CPUOFF), SR)
        nop

        ; TODO: check rx_ready flag; if set, echo rx_char and clear flag
        jmp     main_loop

;----------------------------------------------------------------------
; USCI_A0 RX ISR — vector at 0xFFEC
;----------------------------------------------------------------------
USCI_RX_ISR:
        ; TODO: read UCA0RXBUF → rx_char
        ; TODO: set rx_ready = 1
        ; TODO: wake main from LPM0 (bic.w #CPUOFF, 0(SP))
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
ready_str:
        .byte 'R','e','a','d','y','\r','\n',0

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
