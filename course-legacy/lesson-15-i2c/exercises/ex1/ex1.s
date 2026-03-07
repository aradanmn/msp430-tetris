;******************************************************************************
; Lesson 15 - Exercise 1: I2C Bus Scanner with Device Count
;
; Scan all valid I2C addresses (0x01..0x77).
; Print '.' for NACK, report "Found: 0xXX" for ACK.
; Print total device count at end.
;******************************************************************************
#include "../../../common/msp430g2552-defs.s"

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

        ; TODO: init UART (9600 baud, same as Lesson 13)
        ; TODO: init I2C master (100kHz, P1.6/P1.7)

        mov.w   #scan_msg, R14
        call    #uart_puts

        clr.w   &found_count
        mov.b   #0x01, R4           ; scan address

scan_loop:
        cmp.b   #0x78, R4
        jge     scan_done

        ; TODO: call i2c_probe (R4 = address)
        ; TODO: if ACK: increment found_count, print "Found: 0xXX\r\n"
        ; TODO: if NACK: print "."

        inc.b   R4
        jmp     scan_loop

scan_done:
        ; TODO: print "\r\nDone. N device(s) found.\r\n"
        ; Hint: print count as decimal (divide by 10 for two digits,
        ;       or for counts ≤ 9 just add '0')
        mov.w   #done_msg, R14
        call    #uart_puts
halt:   jmp     halt

;----------------------------------------------------------------------
; TODO: implement i2c_probe(R4) → Z=1 if ACK
; TODO: implement uart_putc, uart_puts, print_hex_byte
;----------------------------------------------------------------------

        .section ".rodata"
scan_msg:
        .byte 'S','c','a','n','n','i','n','g',' ','I','2','C','.','.','.','\r','\n',0
found_msg:
        .byte 'F','o','u','n','d',':',' ',0
done_msg:
        .byte '\r','\n','D','o','n','e','.','\r','\n',0
dot:
        .byte '.',0
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
