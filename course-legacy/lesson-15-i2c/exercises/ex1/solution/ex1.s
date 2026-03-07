;******************************************************************************
; Lesson 15 - Exercise 1 SOLUTION: I2C Bus Scanner with Device Count
;******************************************************************************
#include "../../../../common/msp430g2552-defs.s"

        .equ    I2C_SDA,  BIT6
        .equ    I2C_SCL,  BIT7
        .equ    UART_RX,  BIT1
        .equ    UART_TX,  BIT2

        .data
found_count: .word 0

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        ; UART init
        bis.b   #UCSWRST, &UCA0CTL1
        mov.b   #0x00, &UCA0CTL0
        mov.b   #(UCSSEL_2|UCSWRST), &UCA0CTL1
        mov.b   #104, &UCA0BR0
        mov.b   #0,   &UCA0BR1
        mov.b   #0x02, &UCA0MCTL
        bis.b   #(UART_RX|UART_TX), &P1SEL
        bis.b   #(UART_RX|UART_TX), &P1SEL2
        bic.b   #UCSWRST, &UCA0CTL1

        ; I2C master init
        bis.b   #UCSWRST, &UCB0CTL1
        mov.b   #(UCMODE_3|UCMST|UCSYNC), &UCB0CTL0
        mov.b   #(UCSSEL_2|UCSWRST), &UCB0CTL1
        mov.b   #10, &UCB0BR0
        mov.b   #0,  &UCB0BR1
        bis.b   #(I2C_SDA|I2C_SCL), &P1SEL
        bis.b   #(I2C_SDA|I2C_SCL), &P1SEL2
        bic.b   #UCSWRST, &UCB0CTL1

        mov.w   #scan_msg, R14
        call    #uart_puts

        clr.w   &found_count
        mov.b   #0x01, R4

scan_loop:
        cmp.b   #0x78, R4
        jge     scan_done

        call    #i2c_probe
        jnz     scan_nack

        ; ACK found
        inc.w   &found_count
        mov.w   #found_msg, R14
        call    #uart_puts
        mov.b   R4, R12
        call    #print_hex_byte
        mov.w   #crlf, R14
        call    #uart_puts
        jmp     scan_next

scan_nack:
        mov.b   #'.', R12
        call    #uart_putc

scan_next:
        inc.b   R4
        jmp     scan_loop

scan_done:
        mov.w   #crlf, R14
        call    #uart_puts
        mov.w   #done_msg, R14
        call    #uart_puts

        ; Print count (single digit for simplicity)
        mov.w   &found_count, R12
        add.b   #'0', R12
        call    #uart_putc

        mov.w   #dev_suffix, R14
        call    #uart_puts
halt:   jmp     halt

;----------------------------------------------------------------------
; i2c_probe — probe address in R4, returns Z=1 if ACK
;----------------------------------------------------------------------
i2c_probe:
        mov.b   R4, &UCB0I2CSA
        bis.b   #UCTR, &UCB0CTL1
        bis.b   #UCTXSTT, &UCB0CTL1
_ps:    bit.b   #UCTXSTT, &UCB0CTL1
        jnz     _ps
        bis.b   #UCTXSTP, &UCB0CTL1
        bit.b   #UCNACKIFG, &UCB0STAT
        jnz     _pnack
_pstop: bit.b   #UCTXSTP, &UCB0CTL1
        jnz     _pstop
        bic.b   #UCNACKIFG, &UCB0STAT
        clr.w   R5          ; Z=1 (ACK)
        ret
_pnack: bic.b   #UCNACKIFG, &UCB0STAT
_pns:   bit.b   #UCTXSTP, &UCB0CTL1
        jnz     _pns
        mov.w   #1, R5      ; Z=0 (NACK)
        tst.w   R5
        ret

;----------------------------------------------------------------------
; print_hex_byte — send "0xXX" for byte in R12
;----------------------------------------------------------------------
print_hex_byte:
        push    R12
        push    R13
        mov.b   R12, R13
        mov.b   #'0', R12
        call    #uart_putc
        mov.b   #'x', R12
        call    #uart_putc
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
        pop     R12
        ret

nibble_to_ascii:
        cmp.b   #10, R12
        jge     _na
        add.b   #'0', R12
        ret
_na:    add.b   #('A'-10), R12
        ret

uart_putc:
_tx:    bit.b   #UCA0TXIFG, &IFG2
        jz      _tx
        mov.b   R12, &UCA0TXBUF
        ret

uart_puts:
        push    R12
_pl:    mov.b   @R14+, R12
        tst.b   R12
        jz      _pd
        call    #uart_putc
        jmp     _pl
_pd:    pop     R12
        ret

        .section ".rodata"
scan_msg:
        .byte 'S','c','a','n','n','i','n','g',' ','I','2','C','.','.','.','\r','\n',0
found_msg:
        .byte 'F','o','u','n','d',':',' ',0
done_msg:
        .byte 'D','o','n','e','.',' ',0
dev_suffix:
        .byte ' ','d','e','v','i','c','e','(','s',')',' ','f','o','u','n','d','.','\r','\n',0
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
