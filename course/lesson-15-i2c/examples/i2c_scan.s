;******************************************************************************
; Lesson 15 - Example: I2C Bus Scanner
;
; Scans all 127 I2C addresses (0x01..0x77), sends START+addr+STOP,
; and reports which addresses ACK over UART.
;
; Output: "Scanning I2C...\r\n"
;         "Found: 0x48\r\n"    (for each device found)
;         "Done.\r\n"
;
; Hardware:
;   P1.6 = UCB0SDA  (with 4.7kΩ pull-up to VCC)
;   P1.7 = UCB0SCL  (with 4.7kΩ pull-up to VCC)
;   P1.1 = UCA0RXD
;   P1.2 = UCA0TXD  → host terminal picocom -b 9600 /dev/ttyACM0
;******************************************************************************
#include "../../common/msp430g2552-defs.s"

        .equ    I2C_SDA,  BIT6
        .equ    I2C_SCL,  BIT7
        .equ    UART_RX,  BIT1
        .equ    UART_TX,  BIT2

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        ;------------------------------------------------------------------
        ; UART init (debug output)
        ;------------------------------------------------------------------
        bis.b   #UCSWRST, &UCA0CTL1
        mov.b   #0x00, &UCA0CTL0
        mov.b   #(UCSSEL_2|UCSWRST), &UCA0CTL1
        mov.b   #104, &UCA0BR0
        mov.b   #0,   &UCA0BR1
        mov.b   #0x02, &UCA0MCTL
        bis.b   #(UART_RX|UART_TX), &P1SEL
        bis.b   #(UART_RX|UART_TX), &P1SEL2
        bic.b   #UCSWRST, &UCA0CTL1

        ;------------------------------------------------------------------
        ; I2C master init — 100 kHz
        ;------------------------------------------------------------------
        bis.b   #UCSWRST, &UCB0CTL1
        mov.b   #(UCMODE_3|UCMST|UCSYNC), &UCB0CTL0
        mov.b   #(UCSSEL_2|UCSWRST), &UCB0CTL1
        mov.b   #10, &UCB0BR0           ; 1MHz / 10 = 100kHz
        mov.b   #0,  &UCB0BR1
        bis.b   #(I2C_SDA|I2C_SCL), &P1SEL
        bis.b   #(I2C_SDA|I2C_SCL), &P1SEL2
        bic.b   #UCSWRST, &UCB0CTL1

        mov.w   #scan_msg, R14
        call    #uart_puts

        ; Scan addresses 0x01 .. 0x77
        mov.b   #0x01, R4           ; current address
scan_loop:
        cmp.b   #0x78, R4
        jge     scan_done

        call    #i2c_probe          ; R4 = address to probe
                                    ; returns Z=1 if ACK, Z=0 if NACK
        jnz     scan_next           ; NACK — no device

        ; Found device — print "Found: 0xXX\r\n"
        mov.w   #found_msg, R14
        call    #uart_puts
        mov.b   R4, R12
        call    #print_hex_byte
        mov.w   #crlf, R14
        call    #uart_puts

scan_next:
        inc.b   R4
        jmp     scan_loop

scan_done:
        mov.w   #done_msg, R14
        call    #uart_puts
halt:   jmp     halt

;----------------------------------------------------------------------
; i2c_probe — attempt to address R4, return Z=1 if ACK
; Sends START + addr + STOP (write mode, no data)
; Clobbers: R5
;----------------------------------------------------------------------
i2c_probe:
        mov.b   R4, &UCB0I2CSA
        bis.b   #UCTR, &UCB0CTL1        ; TX mode (write)
        bis.b   #UCTXSTT, &UCB0CTL1     ; START

        ; Wait for START sent (UCTXSTT auto-clears)
_probe_start:
        bit.b   #UCTXSTT, &UCB0CTL1
        jnz     _probe_start

        ; Immediately send STOP (no data bytes)
        bis.b   #UCTXSTP, &UCB0CTL1

        ; Check NACK flag
        bit.b   #UCNACKIFG, &UCB0STAT
        jnz     _probe_nack

        ; Wait for STOP
_probe_stop:
        bit.b   #UCTXSTP, &UCB0CTL1
        jnz     _probe_stop
        ; Clear any flags, return Z=1 (ACK found)
        bic.b   #UCNACKIFG, &UCB0STAT
        clr.w   R5                  ; set Z flag
        ret

_probe_nack:
        ; Wait for STOP to complete
_probe_nack_stop:
        bit.b   #UCTXSTP, &UCB0CTL1
        jnz     _probe_nack_stop
        bic.b   #UCNACKIFG, &UCB0STAT
        ; Return Z=0 (no device)
        mov.w   #1, R5              ; NZ — NACK
        tst.w   R5
        ret

;----------------------------------------------------------------------
; print_hex_byte — send R12 as "0xXX" over UART
;----------------------------------------------------------------------
print_hex_byte:
        push    R12
        push    R13
        mov.b   R12, R13

        mov.b   #'0', R12
        call    #uart_putc
        mov.b   #'x', R12
        call    #uart_putc

        ; High nibble
        mov.b   R13, R12
        rra.b   R12
        rra.b   R12
        rra.b   R12
        rra.b   R12
        and.b   #0x0F, R12
        call    #nibble_to_ascii
        call    #uart_putc

        ; Low nibble
        mov.b   R13, R12
        and.b   #0x0F, R12
        call    #nibble_to_ascii
        call    #uart_putc

        pop     R13
        pop     R12
        ret

nibble_to_ascii:
        cmp.b   #10, R12
        jge     _na_alpha
        add.b   #'0', R12
        ret
_na_alpha:
        add.b   #('A'-10), R12
        ret

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
scan_msg:
        .byte 'S','c','a','n','n','i','n','g',' ','I','2','C','.','.','.','\r','\n',0
found_msg:
        .byte 'F','o','u','n','d',':',' ',0
done_msg:
        .byte 'D','o','n','e','.','\r','\n',0
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
