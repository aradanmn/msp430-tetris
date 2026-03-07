;******************************************************************************
; Lesson 15 - Exercise 3: TMP102 Temperature Sensor over I2C
;
; TMP102 I2C address: 0x48 (ADD0=GND)
; Temperature register: auto-selected on power-on
;
; Read 2 bytes, extract 12-bit signed temperature (0.0625°C per LSB).
; Print integer °C over UART every 2 seconds.
;
; If no TMP102: substitute internal ADC10 temp sensor from Lesson 12.
;******************************************************************************
#include "../../../common/msp430g2552-defs.s"

        .equ    I2C_SDA,    BIT6
        .equ    I2C_SCL,    BIT7
        .equ    UART_RX,    BIT1
        .equ    UART_TX,    BIT2
        .equ    TMP102_ADDR, 0x48

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        ; TODO: init UART 9600
        ; TODO: init I2C master 100kHz

        mov.w   #hdr_msg, R14
        call    #uart_puts

main_loop:
        ; TODO: read 2 bytes from TMP102 (address 0x48, no register byte needed)
        ;   R12 = MSB (byte0), R13 = LSB (byte1)
        ; TODO: combine: raw12 = (R12 << 4) | (R13 >> 4)
        ;   (result is a 12-bit two's-complement number × 0.0625°C)
        ; TODO: for integer °C: arithmetic right shift 4 bits → divide by 16
        ;   Use rra.w 4 times on the signed 16-bit value
        ; TODO: print "Temp: XXC\r\n"

        mov.w   #2000, R12
        call    #delay_ms
        jmp     main_loop

        .section ".rodata"
hdr_msg:
        .byte 'T','M','P','1','0','2',' ','T','e','m','p','e','r','a','t','u','r','e','\r','\n',0
temp_msg:
        .byte 'T','e','m','p',':',' ',0
deg_msg:
        .byte 'C','\r','\n',0

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
