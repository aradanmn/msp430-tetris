;******************************************************************************
; Lesson 15 - Exercise 2 SOLUTION: Write/Read AT24C02 EEPROM over I2C
;******************************************************************************
#include "../../../../common/msp430g2552-defs.s"

        .equ    I2C_SDA,     BIT6
        .equ    I2C_SCL,     BIT7
        .equ    UART_RX,     BIT1
        .equ    UART_TX,     BIT2
        .equ    EEPROM_ADDR, 0x50
        .equ    TEST_BYTE,   0xAB
        .equ    TEST_ADDR,   0x00

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        bis.b   #(LED1|LED2), &P1DIR
        bic.b   #(LED1|LED2), &P1OUT

        ; UART
        bis.b   #UCSWRST, &UCA0CTL1
        mov.b   #0x00, &UCA0CTL0
        mov.b   #(UCSSEL_2|UCSWRST), &UCA0CTL1
        mov.b   #104, &UCA0BR0
        mov.b   #0,   &UCA0BR1
        mov.b   #0x02, &UCA0MCTL
        bis.b   #(UART_RX|UART_TX), &P1SEL
        bis.b   #(UART_RX|UART_TX), &P1SEL2
        bic.b   #UCSWRST, &UCA0CTL1

        ; I2C
        bis.b   #UCSWRST, &UCB0CTL1
        mov.b   #(UCMODE_3|UCMST|UCSYNC), &UCB0CTL0
        mov.b   #(UCSSEL_2|UCSWRST), &UCB0CTL1
        mov.b   #10, &UCB0BR0
        mov.b   #0,  &UCB0BR1
        bis.b   #(I2C_SDA|I2C_SCL), &P1SEL
        bis.b   #(I2C_SDA|I2C_SCL), &P1SEL2
        bic.b   #UCSWRST, &UCB0CTL1

        ; Write 0xAB to address 0x00
        ; Transaction: S ADDR W A MEM_ADDR A DATA A P
        mov.b   #EEPROM_ADDR, &UCB0I2CSA
        bis.b   #UCTR, &UCB0CTL1
        bis.b   #UCTXSTT, &UCB0CTL1        ; START
_w_stt: bit.b   #UCTXSTT, &UCB0CTL1
        jnz     _w_stt
        ; Send memory address
        mov.b   #TEST_ADDR, &UCB0TXBUF
_w_tx1: bit.b   #UCB0TXIFG, &IFG2
        jz      _w_tx1
        ; Send data byte
        mov.b   #TEST_BYTE, &UCB0TXBUF
_w_tx2: bit.b   #UCB0TXIFG, &IFG2
        jz      _w_tx2
        ; STOP
        bis.b   #UCTXSTP, &UCB0CTL1
_w_stp: bit.b   #UCTXSTP, &UCB0CTL1
        jnz     _w_stp

        ; Wait 5ms write cycle
        mov.w   #5, R12
        call    #delay_ms

        ; Set address pointer: S ADDR W A MEM_ADDR A P
        mov.b   #EEPROM_ADDR, &UCB0I2CSA
        bis.b   #UCTR, &UCB0CTL1
        bis.b   #UCTXSTT, &UCB0CTL1
_r_stt: bit.b   #UCTXSTT, &UCB0CTL1
        jnz     _r_stt
        mov.b   #TEST_ADDR, &UCB0TXBUF
_r_tx:  bit.b   #UCB0TXIFG, &IFG2
        jz      _r_tx
        bis.b   #UCTXSTP, &UCB0CTL1
_r_stp: bit.b   #UCTXSTP, &UCB0CTL1
        jnz     _r_stp

        ; Read one byte: S ADDR R A byte NA P
        mov.b   #EEPROM_ADDR, &UCB0I2CSA
        bic.b   #UCTR, &UCB0CTL1
        bis.b   #UCTXSTT, &UCB0CTL1
_rr_stt:bit.b   #UCTXSTT, &UCB0CTL1
        jnz     _rr_stt
        ; NACK + STOP for single-byte read
        bis.b   #(UCTXNACK|UCTXSTP), &UCB0CTL1
_rr_rx: bit.b   #UCB0RXIFG, &IFG2
        jz      _rr_rx
        mov.b   &UCB0RXBUF, R12

        ; Verify
        cmp.b   #TEST_BYTE, R12
        jnz     fail

ok:
        mov.w   #ok_msg, R14
        call    #uart_puts
ok_blink:
        xor.b   #LED1, &P1OUT
        mov.w   #500, R12
        call    #delay_ms
        jmp     ok_blink

fail:
        mov.w   #fail_msg, R14
        call    #uart_puts
        call    #print_hex_byte
        mov.w   #crlf, R14
        call    #uart_puts
        bis.b   #LED2, &P1OUT
fail_loop:
        jmp     fail_loop

;----------------------------------------------------------------------
; Subroutines
;----------------------------------------------------------------------
print_hex_byte:
        push    R13
        mov.b   R12, R13
        mov.b   R13, R12
        rra.b   R12
        rra.b   R12
        rra.b   R12
        rra.b   R12
        and.b   #0x0F, R12
        call    #nibble_to_ascii
        call    #uart_putc
        mov.b   R13, R12
        and.b   #0x0F, R12
        call    #nibble_to_ascii
        call    #uart_putc
        pop     R13
        ret

nibble_to_ascii:
        cmp.b   #10, R12
        jge     _na
        add.b   #'0', R12
        ret
_na:    add.b   #('A'-10), R12
        ret

uart_putc:
_utx:   bit.b   #UCA0TXIFG, &IFG2
        jz      _utx
        mov.b   R12, &UCA0TXBUF
        ret

uart_puts:
        push    R12
_upl:   mov.b   @R14+, R12
        tst.b   R12
        jz      _upd
        call    #uart_putc
        jmp     _upl
_upd:   pop     R12
        ret

delay_ms:
        mov.w   #250, R15
_d:     dec.w   R15
        jnz     _d
        dec.w   R12
        jnz     delay_ms
        ret

        .section ".rodata"
ok_msg:
        .byte 'E','E','P','R','O','M',' ','O','K','\r','\n',0
fail_msg:
        .byte 'F','A','I','L',':',' ','0','x',0
crlf:
        .byte '\r','\n',0

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
