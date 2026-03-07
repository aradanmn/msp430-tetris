;******************************************************************************
; Lesson 15 - Exercise 3 SOLUTION: TMP102 Temperature Sensor over I2C
;******************************************************************************
#include "../../../../common/msp430g2552-defs.s"

        .equ    I2C_SDA,     BIT6
        .equ    I2C_SCL,     BIT7
        .equ    UART_RX,     BIT1
        .equ    UART_TX,     BIT2
        .equ    TMP102_ADDR, 0x48

        .text
        .global main

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

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

        mov.w   #hdr_msg, R14
        call    #uart_puts

main_loop:
        ; Read 2 bytes from TMP102 temperature register
        mov.b   #TMP102_ADDR, &UCB0I2CSA
        bic.b   #UCTR, &UCB0CTL1            ; receive mode
        bis.b   #UCTXSTT, &UCB0CTL1         ; START

_stt:   bit.b   #UCTXSTT, &UCB0CTL1
        jnz     _stt

        ; Wait for first byte (MSB) — keep ACK active
_rx1:   bit.b   #UCB0RXIFG, &IFG2
        jz      _rx1
        mov.b   &UCB0RXBUF, R12             ; MSB

        ; For last byte: NACK + STOP
        bis.b   #(UCTXNACK|UCTXSTP), &UCB0CTL1
_rx2:   bit.b   #UCB0RXIFG, &IFG2
        jz      _rx2
        mov.b   &UCB0RXBUF, R13             ; LSB

        ; Build 12-bit signed value in R12:
        ; byte0 = R12 (MSB), byte1 = R13 (LSB)
        ; raw = (R12 << 4) | (R13 >> 4)
        ; First extend byte0 to 16 bits, shift left 4
        mov.w   R12, R14
        rla.w   R14
        rla.w   R14
        rla.w   R14
        rla.w   R14                         ; R14 = R12 << 4

        ; Shift R13 right 4 (unsigned — only upper nibble matters)
        mov.b   R13, R13
        rra.b   R13
        rra.b   R13
        rra.b   R13
        rra.b   R13
        and.b   #0x0F, R13

        ; Combine
        bis.w   R13, R14                    ; R14 = raw 12-bit value

        ; Sign-extend from 12 bits to 16 bits
        ; Bit 11 is sign; shift left 4, then arithmetic right 4
        rla.w   R14
        rla.w   R14
        rla.w   R14
        rla.w   R14
        ; Now bit 15 is sign
        rra.w   R14
        rra.w   R14
        rra.w   R14
        rra.w   R14
        ; R14 = signed 12-bit value × 16 = integer part of °C × 1

        ; R14 now holds integer °C (shift right 4 total from raw 12-bit)
        ; Actually raw 12-bit / 16 = °C. We did sign extend then /16.
        ; R14 = integer °C
        mov.w   R14, R12

        mov.w   #temp_msg, R14
        call    #uart_puts
        ; Print R12 as signed decimal
        call    #print_dec
        mov.w   #deg_msg, R14
        call    #uart_puts

        mov.w   #2000, R12
        call    #delay_ms
        jmp     main_loop

;----------------------------------------------------------------------
; print_dec — print R12 as signed decimal
; Handles -128..127 (sufficient for temperature)
;----------------------------------------------------------------------
print_dec:
        tst.w   R12
        jge     _pd_pos
        ; negative
        push    R12
        mov.b   #'-', R12
        call    #uart_putc
        pop     R12
        neg.w   R12
_pd_pos:
        ; Print digits (up to 3 for 0..127)
        push    R13
        push    R14
        clr.w   R13
        mov.w   #100, R14
_pd_h:  cmp.w   R14, R12
        jl      _pd_t
        sub.w   R14, R12
        inc.w   R13
        jmp     _pd_h
_pd_t:  tst.w   R13
        jz      _pd_t2
        add.b   #'0', R13
        mov.b   R13, R12
        call    #uart_putc
        clr.w   R13
_pd_t2: mov.w   #10, R14
_pd_t3: cmp.w   R14, R12
        jl      _pd_u
        sub.w   R14, R12
        inc.w   R13
        jmp     _pd_t3
_pd_u:  ; always print tens even if 0 (for multi-digit)
        tst.w   R13          ; skip leading zero if hundreds also 0
        jz      _pd_skip
        add.b   #'0', R13
        mov.b   R13, R12
        call    #uart_putc
_pd_skip:
        add.b   #'0', R12
        call    #uart_putc
        pop     R14
        pop     R13
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
