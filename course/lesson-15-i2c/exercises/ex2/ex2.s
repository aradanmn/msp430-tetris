;******************************************************************************
; Lesson 15 - Exercise 2: Write/Read AT24C02 EEPROM over I2C
;
; AT24C02: 256-byte EEPROM, I2C address 0x50 (A2=A1=A0=GND)
;
; Write byte to address 0x00: S 0x50 W A 0x00 A 0xAB A P
; Wait 5ms (write cycle).
; Read byte from address 0x00:
;   S 0x50 W A 0x00 A P   (set address pointer)
;   S 0x50 R A byte NA P  (read one byte)
; Verify == 0xAB → LED1 blink, "EEPROM OK\r\n"
; Mismatch → LED2, "FAIL: 0xXX\r\n"
;******************************************************************************
#include "../../../common/msp430g2552-defs.s"

        .equ    I2C_SDA,    BIT6
        .equ    I2C_SCL,    BIT7
        .equ    UART_RX,    BIT1
        .equ    UART_TX,    BIT2
        .equ    EEPROM_ADDR, 0x50

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        bis.b   #(LED1|LED2), &P1DIR
        bic.b   #(LED1|LED2), &P1OUT

        ; TODO: init UART 9600
        ; TODO: init I2C master 100kHz

        ; TODO: write 0xAB to EEPROM address 0x00
        ;   i2c_write(EEPROM_ADDR, [0x00, 0xAB])
        ; TODO: delay 5ms (write cycle time)
        ; TODO: read 1 byte from EEPROM address 0x00
        ;   i2c_write(EEPROM_ADDR, [0x00])  ← set address pointer
        ;   i2c_read(EEPROM_ADDR) → R12
        ; TODO: compare R12 to 0xAB
        ;   if equal: LED1 blink + "EEPROM OK\r\n"
        ;   if not:   LED2 on + "FAIL: 0xXX\r\n"

halt:   jmp     halt

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
