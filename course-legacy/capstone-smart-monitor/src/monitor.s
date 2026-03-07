;******************************************************************************
; Capstone: Smart Environment Monitor
;
; Integrates: Timer_A 1ms tick, ADC10 temp sensor, UART TX, LPM0,
;             WDT watchdog, GPIO button, LED heartbeat + alarm.
;
; UART: 9600 baud, connect host terminal: picocom -b 9600 /dev/ttyACM0
;
; Operation:
;   - LED1 heartbeats every 500ms
;   - Temperature read and reported every 2 seconds
;   - LED2 on + "ALARM" message when T > threshold AND armed
;   - Button (P1.3) toggles arm/disarm
;   - WDT resets if main stalls > 2.7s
;******************************************************************************
#include "../../../common/msp430g2552-defs.s"

        ;------------------------------------------------------------------
        ; Constants
        ;------------------------------------------------------------------
        .equ    UART_RX,        BIT1
        .equ    UART_TX,        BIT2
        .equ    TEMP_THRESHOLD, 30      ; alarm above this °C
        .equ    TEMP_PERIOD,    2000    ; ms between readings
        .equ    HB_PERIOD,      500     ; ms heartbeat toggle

        ;------------------------------------------------------------------
        ; RAM variables
        ;------------------------------------------------------------------
        .data
ms_tick:    .word   0           ; 16-bit 1ms counter (wraps ~65s)
t_temp:     .word   0           ; last temp reading timestamp
t_hb:       .word   0           ; last heartbeat timestamp
armed:      .byte   1           ; 1=armed, 0=disarmed (start armed)
alarm:      .byte   0           ; 1=alarm active
temp_c:     .word   0           ; last measured °C

        ;------------------------------------------------------------------
        ; Code
        ;------------------------------------------------------------------
        .text
        .global main

main:
        ;------------------------------------------------------------------
        ; WDT: watchdog mode, ACLK/32768 ≈ 2.7s timeout
        ;------------------------------------------------------------------
        ; First, hold WDT while we configure
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL

        ;------------------------------------------------------------------
        ; DCO = 1 MHz (calibrated)
        ;------------------------------------------------------------------
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        ;------------------------------------------------------------------
        ; VLO as ACLK source (for WDT — no crystal needed)
        ;------------------------------------------------------------------
        mov.b   #LFXT1S_2, &BCSCTL3

        ;------------------------------------------------------------------
        ; GPIO
        ;------------------------------------------------------------------
        bis.b   #(LED1|LED2), &P1DIR
        bic.b   #(LED1|LED2), &P1OUT

        ; Button: input, pull-up, falling-edge interrupt
        bic.b   #BTN, &P1DIR
        bis.b   #BTN, &P1REN
        bis.b   #BTN, &P1OUT
        bis.b   #BTN, &P1IES
        bic.b   #BTN, &P1IFG
        bis.b   #BTN, &P1IE

        ;------------------------------------------------------------------
        ; UART: 9600 baud, 8-N-1, SMCLK=1MHz
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
        ; Timer_A CC0: 1ms tick, SMCLK/1, Up mode
        ;------------------------------------------------------------------
        mov.w   #999, &TACCR0
        mov.w   #CCIE, &TACCTL0
        mov.w   #(TASSEL_2|MC_1|TACLR), &TACTL

        ;------------------------------------------------------------------
        ; Start WDT watchdog: ACLK/32768 ≈ 2.7s (VLO ~12kHz)
        ;------------------------------------------------------------------
        mov.w   #(WDTPW|WDTCNTCL|WDTSSEL), &WDTCTL

        ; Enable global interrupts
        bis.w   #GIE, SR

        ; Print banner
        mov.w   #banner_msg, R14
        call    #uart_puts
        mov.w   #armed_msg, R14
        call    #uart_puts

        ;------------------------------------------------------------------
        ; Main loop — sleeps in LPM0 between 1ms ticks
        ;------------------------------------------------------------------
main_loop:
        bis.w   #(GIE|CPUOFF), SR      ; LPM0
        nop

        ;--- Heartbeat (LED1 every 500ms) ---
        mov.w   &ms_tick, R12
        sub.w   &t_hb, R12
        cmp.w   #HB_PERIOD, R12
        jl      check_temp
        xor.b   #LED1, &P1OUT
        mov.w   &ms_tick, &t_hb

check_temp:
        ;--- Temperature reading (every 2000ms) ---
        mov.w   &ms_tick, R12
        sub.w   &t_temp, R12
        cmp.w   #TEMP_PERIOD, R12
        jl      main_loop

        ; Update timestamp and pet the watchdog
        mov.w   &ms_tick, &t_temp
        mov.w   #(WDTPW|WDTCNTCL|WDTSSEL), &WDTCTL

        ; Sample ADC10 internal temperature sensor
        call    #adc_read_temp          ; result in R12 (raw 10-bit)
        call    #raw_to_celsius         ; R12 = °C (signed 16-bit)
        mov.w   R12, &temp_c

        ; Check alarm condition
        cmp.w   #TEMP_THRESHOLD, R12    ; T - threshold (sets N if T < threshold)
        jl      no_alarm                ; T < threshold

        ; Temperature >= threshold: set alarm if armed
        tst.b   &armed
        jz      no_alarm

        ; Armed and over threshold — alarm!
        mov.b   #1, &alarm
        bis.b   #LED2, &P1OUT
        jmp     send_report

no_alarm:
        clr.b   &alarm
        bic.b   #LED2, &P1OUT

send_report:
        ; Send "T=XXC  [OK/ALARM/OFF]\r\n"
        mov.w   #temp_prefix, R14
        call    #uart_puts
        mov.w   &temp_c, R12
        call    #print_dec
        mov.w   #temp_suffix, R14
        call    #uart_puts

        ; Status string
        tst.b   &armed
        jz      status_off
        tst.b   &alarm
        jnz     status_alarm

status_ok:
        mov.w   #ok_str, R14
        call    #uart_puts
        jmp     main_loop

status_alarm:
        mov.w   #alarm_str, R14
        call    #uart_puts
        jmp     main_loop

status_off:
        mov.w   #off_str, R14
        call    #uart_puts
        jmp     main_loop

        ;------------------------------------------------------------------
        ; Timer_A CC0 ISR — 1ms tick
        ;------------------------------------------------------------------
TIMERA_CC0_ISR:
        inc.w   &ms_tick
        bic.w   #CPUOFF, 0(SP)         ; wake main
        reti

        ;------------------------------------------------------------------
        ; PORT1 ISR — button toggles arm/disarm
        ;------------------------------------------------------------------
PORT1_ISR:
        bic.b   #BTN, &P1IFG

        ; Debounce: disable interrupt, re-enable in main after 50ms
        ; (Simple approach: just toggle and re-arm immediately)
        xor.b   #0x01, &armed

        ; Send status message
        tst.b   &armed
        jnz     _p1_armed
        ; Disarmed
        bic.b   #LED2, &P1OUT
        clr.b   &alarm
        bic.w   #CPUOFF, 0(SP)
        reti

_p1_armed:
        bic.w   #CPUOFF, 0(SP)
        reti

        ;------------------------------------------------------------------
        ; adc_read_temp — sample ADC10 internal temperature sensor
        ; Returns: R12 = raw 10-bit ADC value (0..1023)
        ;------------------------------------------------------------------
adc_read_temp:
        ; Configure ADC10: temp sensor, 1.5V ref, 64-cycle sample
        mov.w   #(INCH_10|ADC10SSEL_3|CONSEQ_0), &ADC10CTL1
        mov.w   #(SREF_1|ADC10SHT_3|REFON|ADC10ON), &ADC10CTL0

        ; Wait ~30µs for reference to settle (30 cycles at 1MHz)
        mov.w   #30, R15
_adc_wait:
        dec.w   R15
        jnz     _adc_wait

        ; Start conversion
        bis.w   #ENC|ADC10SC, &ADC10CTL0
_adc_busy:
        bit.w   #ADC10BUSY, &ADC10CTL1
        jnz     _adc_busy

        mov.w   &ADC10MEM, R12
        bic.w   #ENC, &ADC10CTL0
        bic.w   #(REFON|ADC10ON), &ADC10CTL0
        ret

        ;------------------------------------------------------------------
        ; raw_to_celsius — convert ADC10 raw to integer °C
        ; Input:  R12 = raw (0..1023)
        ; Output: R12 = temperature in °C (signed)
        ;
        ; Approximation: T°C = (raw - 673) / 4 + 25
        ; (Calibrate 673 for your chip; valid ±5°C typical)
        ;------------------------------------------------------------------
raw_to_celsius:
        sub.w   #673, R12           ; subtract offset
        ; Arithmetic right shift 2 (divide by 4, sign-preserving)
        rra.w   R12
        rra.w   R12
        add.w   #25, R12            ; add reference temperature
        ret

        ;------------------------------------------------------------------
        ; print_dec — send R12 as signed decimal over UART
        ; Handles -99..127 (sufficient for temperature)
        ;------------------------------------------------------------------
print_dec:
        tst.w   R12
        jge     _pd_pos
        push    R12
        mov.b   #'-', R12
        call    #uart_putc
        pop     R12
        neg.w   R12
_pd_pos:
        push    R13
        push    R14
        clr.w   R13

        ; Hundreds digit
        mov.w   #100, R14
_pd_h:  cmp.w   R14, R12
        jl      _pd_te
        sub.w   R14, R12
        inc.w   R13
        jmp     _pd_h
_pd_te: tst.w   R13
        jz      _pd_tens
        add.b   #'0', R13
        mov.b   R13, R12
        call    #uart_putc
        clr.w   R13

        ; Tens digit
_pd_tens:
        mov.w   #10, R14
_pd_t:  cmp.w   R14, R12
        jl      _pd_u
        sub.w   R14, R12
        inc.w   R13
        jmp     _pd_t
_pd_u:  tst.w   R13
        jz      _pd_skip
        add.b   #'0', R13
        mov.b   R13, R12
        call    #uart_putc
_pd_skip:
        ; Units digit (always print)
        add.b   #'0', R12
        call    #uart_putc
        pop     R14
        pop     R13
        ret

        ;------------------------------------------------------------------
        ; uart_putc — send R12 byte, poll TXIFG
        ;------------------------------------------------------------------
uart_putc:
_utx:   bit.b   #UCA0TXIFG, &IFG2
        jz      _utx
        mov.b   R12, &UCA0TXBUF
        ret

        ;------------------------------------------------------------------
        ; uart_puts — send null-terminated string at R14
        ;------------------------------------------------------------------
uart_puts:
        push    R12
_upl:   mov.b   @R14+, R12
        tst.b   R12
        jz      _upd
        call    #uart_putc
        jmp     _upl
_upd:   pop     R12
        ret

        ;------------------------------------------------------------------
        ; String constants
        ;------------------------------------------------------------------
        .section ".rodata"
banner_msg:
        .byte '=','=',' ','S','m','a','r','t',' ','E','n','v',' ','M','o','n','i','t','o','r',' ','=','=','\r','\n',0
armed_msg:
        .byte 'A','r','m','e','d','.',' ','T','h','r','e','s','h',':',' ','3','0','C','\r','\n',0
temp_prefix:
        .byte 'T','=',0
temp_suffix:
        .byte 'C','  ',0
ok_str:
        .byte '[','O','K',']','\r','\n',0
alarm_str:
        .byte '[','A','L','A','R','M',']','\r','\n',0
off_str:
        .byte '[','O','F','F',']','\r','\n',0

        ;------------------------------------------------------------------
        ; Interrupt vector table
        ;------------------------------------------------------------------

;==============================================================================
; Interrupt Vector Table  (16 entries × 2 bytes = 32 bytes at 0xFFE0-0xFFFF)
;==============================================================================
        .section ".vectors","ax",@progbits
        .word   0                    ; 0xFFE0 - unused
        .word   0                    ; 0xFFE2 - unused
        .word   PORT1_ISR            ; 0xFFE4 - Port 1
        .word   0                    ; 0xFFE6 - Port 2
        .word   0                    ; 0xFFE8 - unused
        .word   0                    ; 0xFFEA - ADC10
        .word   0                    ; 0xFFEC - USCI RX
        .word   0                    ; 0xFFEE - USCI TX
        .word   0                    ; 0xFFF0 - unused
        .word   0                    ; 0xFFF2 - Timer_A overflow
        .word   TIMERA_CC0_ISR       ; 0xFFF4 - Timer_A CC0
        .word   0                    ; 0xFFF6 - WDT
        .word   0                    ; 0xFFF8 - unused
        .word   0                    ; 0xFFFA - unused
        .word   0                    ; 0xFFFC - unused
        .word   main                 ; 0xFFFE - Reset
        .end
