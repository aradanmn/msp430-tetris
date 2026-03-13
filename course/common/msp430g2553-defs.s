;******************************************************************************
; msp430g2553-defs.s
;
; MSP430G2553 register and bit definitions for GNU assembler.
; Include this file at the top of every .s file:
;
;   from examples/         use  #include "../../common/msp430g2553-defs.s"
;   from exercises/exN/    use  #include "../../../common/msp430g2553-defs.s"
;   from exN/solution/     use  #include "../../../../common/msp430g2553-defs.s"
;
; MSP430G2553 at a glance:
;   - 16-bit RISC CPU, 16 registers (R0=PC, R1=SP, R2=SR, R3=CG, R4-R15=general)
;   - 16 KB Flash  (0xC000–0xFFFF)
;   - 512 B RAM    (0x0200–0x03FF)
;   - Peripherals  (0x0000–0x01FF, byte-addressable)
;   - Info Flash   (0x1000–0x10FF, holds calibration data)
;
; LaunchPad (MSP-EXP430G2) pin assignments:
;   P1.0 = LED1  (Red,   active HIGH)
;   P1.6 = LED2  (Green, active HIGH — shares SPI MISO in later lessons)
;   P1.3 = S2 Button  (active LOW, use internal pull-up)
;   P1.1 = UCA0RXD   (UART receive)
;   P1.2 = UCA0TXD   (UART transmit)
;   P1.5 = UCB0CLK   (SPI clock)
;   P1.6 = UCB0SOMI  (SPI MISO — same as LED2!)
;   P1.7 = UCB0SIMO  (SPI MOSI)
;******************************************************************************

;==============================================================================
; HOW BIT CONSTANTS WORK
;
; Every constant in this file is a bit mask — a number with one or more bits
; set to 1. Combine masks with OR (|) to build a value that sets multiple bits.
;
; Hex → binary → bit position (each power of two = exactly one bit):
;
;   0x01 = 0000 0001  ← bit 0 only
;   0x02 = 0000 0010  ← bit 1 only
;   0x04 = 0000 0100  ← bit 2 only
;   0x08 = 0000 1000  ← bit 3 only
;   0x10 = 0001 0000  ← bit 4 only
;   0x20 = 0010 0000  ← bit 5 only
;   0x40 = 0100 0000  ← bit 6 only
;   0x80 = 1000 0000  ← bit 7 only
;
; 16-bit registers add a second byte on the left (bits 15-8):
;   0x0100 = 0000 0001 0000 0000  ← bit 8
;   0x0200 = 0000 0010 0000 0000  ← bit 9
;   0x5A00 = 0101 1010 0000 0000  ← bits 14,12,11,9,8 (upper byte = 0x5A)
;
; OR-ing masks together — each bit stays independent:
;   0x81 = 0x80 | 0x01 = 1000 0001  → bits 7 and 0 both set
;   0x5A80 = 0x5A00 | 0x0080        → password in upper byte + bit 7 in lower
;
; The three bit-manipulation instructions:
;   bis.b #mask, &REG   → set   every bit that is 1 in mask  (REG |=  mask)
;   bic.b #mask, &REG   → clear every bit that is 1 in mask  (REG &= ~mask)
;   xor.b #mask, &REG   → toggle every bit that is 1 in mask (REG ^=  mask)
;   bit.b #mask, &REG   → test (sets Z=1 if all masked bits are 0, no write)
;
; These leave all other bits unchanged — critical when sharing a register
; between peripherals (e.g. P1DIR controls all 8 pins at once).
;
; Use .b for 8-bit peripheral registers, .w for 16-bit ones.
;==============================================================================

;==============================================================================
; Bit masks — single-bit constants (only one bit set, all others zero)
;
;   Bit position:  7    6    5    4    3    2    1    0
;   Hex value:    0x80 0x40 0x20 0x10 0x08 0x04 0x02 0x01
;==============================================================================
.equ    BIT0,   0x01    ; 0000 0001  bit 0
.equ    BIT1,   0x02    ; 0000 0010  bit 1
.equ    BIT2,   0x04    ; 0000 0100  bit 2
.equ    BIT3,   0x08    ; 0000 1000  bit 3
.equ    BIT4,   0x10    ; 0001 0000  bit 4
.equ    BIT5,   0x20    ; 0010 0000  bit 5
.equ    BIT6,   0x40    ; 0100 0000  bit 6
.equ    BIT7,   0x80    ; 1000 0000  bit 7

; LaunchPad aliases — readable names for the pins we care about
.equ    LED1,       BIT0        ; P1.0  Red LED        bit 0 = 0x01
.equ    LED2,       BIT6        ; P1.6  Green LED      bit 6 = 0x40
.equ    BTN,        BIT3        ; P1.3  Button (active LOW, needs pull-up)
.equ    UART_RX,    BIT1        ; P1.1  UCA0RXD        bit 1 = 0x02
.equ    UART_TX,    BIT2        ; P1.2  UCA0TXD        bit 2 = 0x04

;==============================================================================
; Special Function Registers (0x0000–0x000F)
;==============================================================================
.equ    IE1,    0x0000          ; Interrupt Enable 1
.equ    IFG1,   0x0002          ; Interrupt Flag 1
.equ    IE2,    0x0001          ; Interrupt Enable 2
.equ    IFG2,   0x0003          ; Interrupt Flag 2
.equ    ME2,    0x0005          ; Module Enable 2

;==============================================================================
; Port 1  (8-bit registers, 0x0020–0x0027)
;
; Each register is 8 bits wide. Bit N controls pin P1.N:
;
;   Bit:   7     6     5     4     3     2     1     0
;          P1.7  P1.6  P1.5  P1.4  P1.3  P1.2  P1.1  P1.0
;                LED2              BTN   TXD   RXD   LED1
;
;   P1DIR — direction:  0 = input (default)   1 = output
;   P1OUT — when output: 0 = LOW, 1 = HIGH
;             when input+REN: 0 = pull-down, 1 = pull-up
;   P1IN  — read the actual pin logic level (read-only, ignores P1DIR)
;   P1REN — resistor enable: 1 = turn on internal pull resistor for that pin
;   P1SEL — function select: 0 = GPIO (default), 1 = peripheral (UART/SPI/I2C)
;   P1IES — interrupt edge:  0 = rising edge, 1 = falling edge
;   P1IE  — interrupt enable per pin: 1 = allow interrupt from that pin
;   P1IFG — interrupt flag per pin (set by hardware; write 0 to clear)
;
; Common patterns:
;   ; Set P1.0 (LED1) as output, drive HIGH (LED on):
;   bis.b  #BIT0, &P1DIR    ; P1DIR = xxxx xxx1 — bit 0 = output
;   bis.b  #BIT0, &P1OUT    ; P1OUT = xxxx xxx1 — bit 0 = HIGH
;
;   ; Set P1.3 (Button) as input with internal pull-up (reads 1 when released):
;   bic.b  #BIT3, &P1DIR    ; P1DIR bit 3 = 0 → input (already the default)
;   bis.b  #BIT3, &P1REN    ; enable pull resistor on P1.3
;   bis.b  #BIT3, &P1OUT    ; P1OUT bit 3 = 1 → pull-UP (not pull-down)
;==============================================================================
.equ    P1IN,   0x0020          ; Input register        (read-only)
.equ    P1OUT,  0x0021          ; Output / pull register
.equ    P1DIR,  0x0022          ; Direction  (0=input, 1=output)
.equ    P1IFG,  0x0023          ; Interrupt flag        (write 0 to clear)
.equ    P1IES,  0x0024          ; Interrupt edge select (0=rising, 1=falling)
.equ    P1IE,   0x0025          ; Interrupt enable
.equ    P1SEL,  0x0026          ; Function select       (0=GPIO, 1=peripheral)
.equ    P1REN,  0x0027          ; Resistor enable

;==============================================================================
; Port 2  (8-bit, 0x0028–0x002F) — same layout as Port 1
;==============================================================================
.equ    P2IN,   0x0028
.equ    P2OUT,  0x0029
.equ    P2DIR,  0x002A
.equ    P2IFG,  0x002B
.equ    P2IES,  0x002C
.equ    P2IE,   0x002D
.equ    P2SEL,  0x002E
.equ    P2REN,  0x002F

;==============================================================================
; Port 1/2 Secondary Function Select (0x0041–0x0042)
;==============================================================================
.equ    P1SEL2, 0x0041
.equ    P2SEL2, 0x0042

;==============================================================================
; Watchdog Timer  (16-bit, 0x0120)
;
; WDTCTL is 16 bits. The UPPER byte is a write password — you MUST include
; WDTPW in every write or the chip resets immediately. The LOWER byte holds
; the actual control bits.
;
;   Bit:  15  14  13  12  11  10   9   8  │  7    6    5   4     3     2    1    0
;         ───────────────────────────────  │ ────────────────────────────────────
;            Password (must = 0x5A)        │ HOLD  —    — TMSEL CNTCL SSEL IS1  IS0
;
;   WDTPW   = 0x5A00  password in bits 15-8 (0x5A = 0101 1010)
;   WDTHOLD = 0x0080  bit 7 — freeze the watchdog counter (stops resets)
;
;   Together: #(WDTPW|WDTHOLD) = 0x5A00 | 0x0080 = 0x5A80
;     Binary:  0101 1010  1000 0000
;              ─────────  ─
;              password   └─ bit 7 = HOLD
;
; Other lower-byte bits (for interval timer mode, Lesson 11):
;   WDTTMSEL = 0x0010  bit 4 — select interval timer mode (else watchdog mode)
;   WDTCNTCL = 0x0008  bit 3 — clear/restart the counter
;   WDTSSEL  = 0x0004  bit 2 — clock: 0 = SMCLK, 1 = ACLK
;   WDTIS1   = 0x0002  bit 1 ─┐ interval: 00=/32768, 01=/8192, 10=/512, 11=/64
;   WDTIS0   = 0x0001  bit 0 ─┘
;==============================================================================
.equ    WDTCTL,     0x0120
.equ    WDTPW,      0x5A00      ; Password (upper byte) — always OR with control bits
.equ    WDTHOLD,    0x0080      ; bit 7 — hold (stop) the watchdog

; Watchdog interval timer presets (Lesson 11)
.equ    WDTTMSEL,   0x0010      ; bit 4 — interval timer mode
.equ    WDTCNTCL,   0x0008      ; bit 3 — clear counter
.equ    WDTSSEL,    0x0004      ; bit 2 — clock source (0=SMCLK, 1=ACLK)
.equ    WDTIS1,     0x0002      ; bit 1 ─┐ interval length select
.equ    WDTIS0,     0x0001      ; bit 0 ─┘

;==============================================================================
; Basic Clock System  (8-bit registers, 0x0053–0x0058)
;
; The DCO (Digitally Controlled Oscillator) is the default CPU clock source.
; Straight from the factory it runs at an imprecise frequency. TI programs
; calibration bytes into Info Flash at manufacture so you can hit exact speeds.
;
; Calibration sequence (always do this near the top of _start):
;   clr.b   &DCOCTL               ; clear fine-tune first to avoid glitch
;   mov.b   &CALBC1_1MHZ, &BCSCTL1  ; set coarse range (from Info Flash)
;   mov.b   &CALDCO_1MHZ, &DCOCTL   ; set fine-tune  (from Info Flash)
;   → CPU now runs at exactly 1 MHz
;
; BCSCTL1 bits relevant to DCO:
;   Bits 7-4: RSEL3:RSEL0 — coarse range (loaded from CALBC1_x)
;   Bits 3-2: DIVA — ACLK divider
;   Bit  0:   XT2OFF — 1 = disable XT2 oscillator (default)
;
; DCOCTL bits:
;   Bits 7-5: DCO2:DCO0 — frequency select within range
;   Bits 4-0: MOD4:MOD0 — modulation for fine-tune
;==============================================================================
.equ    BCSCTL3,    0x0053
.equ    DCOCTL,     0x0056      ; DCO frequency fine-tune (bits 7-5 = step, bits 4-0 = mod)
.equ    BCSCTL1,    0x0057      ; Coarse range + ACLK divider
.equ    BCSCTL2,    0x0058      ; MCLK/SMCLK source and dividers

; BCSCTL1 — ACLK divider field (bits 5-4)
.equ    DIVA_0,     0x00        ; ACLK /1   bits 5-4 = 00
.equ    DIVA_1,     0x10        ; ACLK /2   bits 5-4 = 01 (bit 4 set)
.equ    DIVA_2,     0x20        ; ACLK /4   bits 5-4 = 10 (bit 5 set)
.equ    DIVA_3,     0x30        ; ACLK /8   bits 5-4 = 11 (bits 5 and 4)

; BCSCTL2 — MCLK and SMCLK dividers
.equ    DIVM_0,     0x00        ; MCLK /1   bits 5-4 = 00
.equ    DIVM_1,     0x10        ; MCLK /2   bits 5-4 = 01
.equ    DIVS_0,     0x00        ; SMCLK /1  bits 2-1 = 00
.equ    DIVS_1,     0x02        ; SMCLK /2  bits 2-1 = 01 (bit 1)
.equ    DIVS_2,     0x04        ; SMCLK /4  bits 2-1 = 10 (bit 2)
.equ    DIVS_3,     0x06        ; SMCLK /8  bits 2-1 = 11 (bits 2 and 1)

; DCO calibration constants — pre-programmed by TI into Info Flash
;   Address 0x10FF holds the BCSCTL1 value that gives exactly 1 MHz
;   Address 0x10FE holds the DCOCTL  value that gives exactly 1 MHz
.equ    CALBC1_1MHZ,    0x10FF  ; → BCSCTL1 for 1 MHz
.equ    CALDCO_1MHZ,    0x10FE  ; → DCOCTL  for 1 MHz
.equ    CALBC1_8MHZ,    0x10FD  ; → BCSCTL1 for 8 MHz
.equ    CALDCO_8MHZ,    0x10FC  ; → DCOCTL  for 8 MHz
.equ    CALBC1_16MHZ,   0x10F9  ; → BCSCTL1 for 16 MHz
.equ    CALDCO_16MHZ,   0x10F8  ; → DCOCTL  for 16 MHz

;==============================================================================
; Timer_A  (16-bit registers, 0x0160–0x0176)
;
; TACTL — Timer_A Control Register (16-bit):
;
;   Bit: 15-10   9-8     7-6    5-4    3     2      1     0
;        ──────  ──────  ─────  ─────  ───   ─────  ────  ────
;        unused  TASSEL  ID     MC     unused TACLR  TAIE  TAIFG
;
;   TASSEL (bits 9-8) — clock source:
;     00 = TACLK (external)   0x0000
;     01 = ACLK               0x0100  bit 8
;     10 = SMCLK              0x0200  bit 9       ← most common
;     11 = INCLK              0x0300  bits 9+8
;
;   ID (bits 7-6) — input divider:
;     00 = /1    0x0000
;     01 = /2    0x0040  bit 6
;     10 = /4    0x0080  bit 7
;     11 = /8    0x00C0  bits 7+6
;
;   MC (bits 5-4) — mode control:
;     00 = Stop             0x0000
;     01 = Up (to TACCR0)   0x0010  bit 4    ← most common for PWM/delay
;     10 = Continuous       0x0020  bit 5
;     11 = Up/Down          0x0030  bits 5+4
;
;   TACLR (bit 2) — write 1 to reset TAR to 0 (self-clearing)
;   TAIE  (bit 1) — 1 = enable overflow interrupt
;   TAIFG (bit 0) — overflow interrupt flag (write 0 to clear)
;
; Example — SMCLK, no divider, Up mode, clear counter:
;   mov.w  #(TASSEL_2|MC_1|TACLR), &TACTL
;   = 0x0200 | 0x0010 | 0x0004 = 0x0214
;   = 0000 0010 0001 0100
;              ─         ← bit 9  = SMCLK
;                   ─    ← bit 4  = Up mode
;                     ─  ← bit 2  = clear counter
;==============================================================================
.equ    TACTL,   0x0160         ; Timer_A Control
.equ    TACCTL0, 0x0162         ; Capture/Compare Control 0
.equ    TACCTL1, 0x0164         ; Capture/Compare Control 1
.equ    TACCTL2, 0x0166         ; Capture/Compare Control 2
.equ    TAR,     0x0170         ; Timer counter (current value)
.equ    TACCR0,  0x0172         ; Period/compare register 0 (Up mode counts to this)
.equ    TACCR1,  0x0174         ; Compare register 1
.equ    TACCR2,  0x0176         ; Compare register 2
.equ    TAIV,    0x012E         ; Interrupt vector (read to identify source)

; TACTL — clock source (bits 9-8)
.equ    TASSEL_0, 0x0000        ; TACLK (external) bits 9-8 = 00
.equ    TASSEL_1, 0x0100        ; ACLK             bit  8
.equ    TASSEL_2, 0x0200        ; SMCLK            bit  9    ← most used
.equ    TASSEL_3, 0x0300        ; INCLK            bits 9+8
; TACTL — input divider (bits 7-6)
.equ    ID_0,   0x0000          ; /1  bits 7-6 = 00
.equ    ID_1,   0x0040          ; /2  bit  6
.equ    ID_2,   0x0080          ; /4  bit  7
.equ    ID_3,   0x00C0          ; /8  bits 7+6
; TACTL — mode control (bits 5-4)
.equ    MC_0,   0x0000          ; Stop        bits 5-4 = 00
.equ    MC_1,   0x0010          ; Up          bit  4    ← count 0→TACCR0, repeat
.equ    MC_2,   0x0020          ; Continuous  bit  5    ← count 0→0xFFFF, repeat
.equ    MC_3,   0x0030          ; Up/Down     bits 5+4
; TACTL — other bits
.equ    TACLR,  0x0004          ; bit 2 — clear counter (write 1; self-clears)
.equ    TAIE,   0x0002          ; bit 1 — overflow interrupt enable
.equ    TAIFG,  0x0001          ; bit 0 — overflow interrupt flag

; TACCTL — output mode for PWM (bits 7-5)
.equ    OUTMOD_0, 0x0000        ; bits 7-5 = 000 — Output (manual)
.equ    OUTMOD_1, 0x0020        ; bits 7-5 = 001 — Set
.equ    OUTMOD_2, 0x0040        ; bits 7-5 = 010 — Toggle/Reset
.equ    OUTMOD_3, 0x0060        ; bits 7-5 = 011 — Set/Reset
.equ    OUTMOD_4, 0x0080        ; bits 7-5 = 100 — Toggle
.equ    OUTMOD_5, 0x00A0        ; bits 7-5 = 101 — Reset
.equ    OUTMOD_6, 0x00C0        ; bits 7-5 = 110 — Toggle/Set
.equ    OUTMOD_7, 0x00E0        ; bits 7-5 = 111 — Reset/Set  ← standard PWM
; TACCTL — interrupt
.equ    CCIE,   0x0010          ; bit 4 — compare interrupt enable
.equ    CCIFG,  0x0001          ; bit 0 — compare interrupt flag
.equ    CAP,    0x0100          ; bit 8 — capture mode (else compare)

;==============================================================================
; ADC10  (0x01B0–0x01B4, plus 8-bit at 0x0048–0x004C)
;
; ADC10CTL0 (16-bit) — reference, power, sample/hold:
;
;   Bits 15-13: SREF  — reference voltage selection
;   Bits 12-11: ADC10SHT — sample-hold time
;   Bit  7:     ADC10SR  — sampling rate (0=200ksps, 1=50ksps)
;   Bit  6:     REF2_5V  — 0=1.5V ref, 1=2.5V ref
;   Bit  5:     REFON    — 1 = turn on internal reference voltage
;   Bit  4:     ADC10ON  — 1 = power on the ADC (required before converting)
;   Bit  3:     ADC10IE  — interrupt enable
;   Bit  2:     ADC10IFG — interrupt flag (conversion complete)
;   Bit  1:     ENC      — enable conversion (1 = ready to sample)
;   Bit  0:     ADC10SC  — start conversion (write 1 alongside ENC to trigger)
;
; ADC10CTL1 (16-bit) — channel and clock:
;
;   Bits 15-12: INCH  — input channel (10 = internal temperature sensor)
;   Bits  5-4:  ADC10SSEL — clock: 00=ADC10OSC, 01=ACLK, 10=MCLK, 11=SMCLK
;   Bits  3-2:  CONSEQ    — conversion sequence mode (00=single)
;   Bit   0:    ADC10BUSY — 1 while conversion is in progress (poll until 0)
;
; Example — read internal temperature sensor (channel 10):
;   mov.w  #(INCH_10|ADC10SSEL_3|CONSEQ_0), &ADC10CTL1
;   mov.w  #(SREF_1|ADC10SHT_3|REFON|ADC10ON), &ADC10CTL0
;   ; wait ~30 µs for reference to settle, then:
;   bis.w  #(ENC|ADC10SC), &ADC10CTL0  ; start
;   poll: bit.w #ADC10BUSY, &ADC10CTL1
;         jnz   poll
;   mov.w  &ADC10MEM, R5               ; 10-bit result in R5
;==============================================================================
.equ    ADC10CTL0, 0x01B0
.equ    ADC10CTL1, 0x01B2
.equ    ADC10MEM,  0x01B4
.equ    ADC10AE0,  0x004B       ; Analog enable (disable digital buffer on ADC pins)

; ADC10CTL0 — power and sample control
.equ    ADC10SC,    0x0001      ; bit  0 — start conversion (pulse with ENC)
.equ    ENC,        0x0002      ; bit  1 — enable conversion
.equ    ADC10IFG,   0x0004      ; bit  2 — interrupt flag (conversion done)
.equ    ADC10IE,    0x0008      ; bit  3 — interrupt enable
.equ    ADC10ON,    0x0010      ; bit  4 — power on ADC
.equ    REFON,      0x0020      ; bit  5 — internal reference on
.equ    REF2_5V,    0x0040      ; bit  6 — 0=1.5V reference, 1=2.5V reference
.equ    ADC10SHT_3, 0x1800      ; bits 12-11 = 11 → 64 × ADC10CLK sample-hold
.equ    SREF_0,     0x0000      ; bits 15-13 = 000 → Vr+ = VCC,  Vr- = GND
.equ    SREF_1,     0x2000      ; bits 15-13 = 001 → Vr+ = Vref, Vr- = GND (bit 13)

; ADC10CTL1 — channel and clock
.equ    ADC10BUSY,  0x0001      ; bit  0 — 1 while conversion running (poll until 0)
.equ    CONSEQ_0,   0x0000      ; bits 3-2 = 00 → single channel, single conversion
.equ    ADC10SSEL_3,0x0018      ; bits 5-4 = 11 → SMCLK (bits 4+3 set) → 0x18
.equ    INCH_10,    0xA000      ; bits 15-12 = 1010 → channel 10 = temperature sensor

;==============================================================================
; USCI_A0  (UART / SPI-A, 8-bit registers at 0x0060–0x0067)
;
; UCA0CTL1 is the main control register for UART configuration:
;   Bit 7:   UCSSEL1 ─┐ clock source: 00=UCLK, 01=ACLK, 10=SMCLK, 11=SMCLK
;   Bit 6:   UCSSEL0 ─┘
;   Bit 0:   UCSWRST — software reset; hold at 1 while configuring, clear when done
;
; Baud rate at 1 MHz SMCLK → 9600 baud:
;   UCA0BR0 = 104   (1,000,000 / 104 ≈ 9615, close enough)
;   UCA0BR1 = 0     (high byte of divisor = 0)
;   UCA0MCTL = 0x02 (modulation for accuracy)
;==============================================================================
.equ    UCA0CTL0,   0x0060
.equ    UCA0CTL1,   0x0061
.equ    UCA0BR0,    0x0062      ; Baud rate divisor low byte
.equ    UCA0BR1,    0x0063      ; Baud rate divisor high byte
.equ    UCA0MCTL,   0x0064      ; Modulation control (UART only)
.equ    UCA0STAT,   0x0065
.equ    UCA0RXBUF,  0x0066
.equ    UCA0TXBUF,  0x0067
; UCA0CTL1 control bits
.equ    UCSSEL_2,   0x80        ; bit 7 — clock = SMCLK (bits 7-6 = 10)
.equ    UCSWRST,    0x01        ; bit 0 — software reset (hold during config)
; IFG2 interrupt flags for USCI_A0
.equ    UCA0RXIFG,  0x01        ; bit 0 — receive buffer full
.equ    UCA0TXIFG,  0x02        ; bit 1 — transmit buffer empty (ready)
; IFG2 interrupt flags for USCI_B0
.equ    UCB0RXIFG,  0x04        ; bit 2
.equ    UCB0TXIFG,  0x08        ; bit 3
; IE2 interrupt enable bits
.equ    UCA0RXIE,   0x01        ; bit 0
.equ    UCA0TXIE,   0x02        ; bit 1
.equ    UCB0RXIE,   0x04        ; bit 2
.equ    UCB0TXIE,   0x08        ; bit 3

;==============================================================================
; USCI_B0  (SPI-B / I2C, 8-bit registers at 0x0068–0x006F)
;
; UCB0CTL0 bits (SPI mode):
;   Bit 7: UCCKPH  — clock phase (0=first edge, 1=second edge captures data)
;   Bit 6: UCCKPL  — clock polarity (0=idle LOW, 1=idle HIGH)
;   Bit 5: UCMSB   — 1 = MSB first (standard SPI), 0 = LSB first
;   Bit 3: UCMST   — 1 = master mode
;   Bits 2-1: UCMODE — 00=SPI-3wire, 01=SPI-4wire/slave-enable-high,
;                       10=SPI-4wire/slave-enable-low, 11=I2C
;   Bit 0: UCSYNC  — 1 = synchronous mode (required for SPI and I2C)
;==============================================================================
.equ    UCB0CTL0,   0x0068
.equ    UCB0CTL1,   0x0069
.equ    UCB0BR0,    0x006A      ; Bit rate divisor low byte
.equ    UCB0BR1,    0x006B      ; Bit rate divisor high byte
.equ    UCB0STAT,   0x006D
.equ    UCB0RXBUF,  0x006E
.equ    UCB0TXBUF,  0x006F
; I2C address registers
.equ    UCB0I2COA,  0x0118      ; Own address
.equ    UCB0I2CSA,  0x011A      ; Slave address (target device)
; UCB0CTL0 field bits
.equ    UCCKPH,     0x80        ; bit 7 — clock phase
.equ    UCCKPL,     0x40        ; bit 6 — clock polarity (0=idle-low)
.equ    UCMSB,      0x20        ; bit 5 — MSB first
.equ    UCMST,      0x08        ; bit 3 — master mode
.equ    UCMODE_3,   0x06        ; bits 2-1 = 11 → I2C mode
.equ    UCSYNC,     0x01        ; bit 0 — synchronous mode (SPI/I2C)
; UCB0CTL1 field bits
.equ    UCTR,       0x10        ; bit 4 — I2C: 1=transmit, 0=receive
.equ    UCTXSTP,    0x04        ; bit 2 — send STOP condition
.equ    UCTXSTT,    0x02        ; bit 1 — send START condition

;==============================================================================
; Status Register (R2 / SR) — flags set by arithmetic + low-power mode bits
;
;   Bit:  15-9   8    7    6     5      4       3    2    1    0
;         ─────  ─    ─    ─     ─      ─       ─    ─    ─    ─
;         unused V    SCG1 SCG0  OSCOFF CPUOFF  GIE  N    Z    C
;
;   C    (bit 0) — Carry:    set if addition overflows 16 bits, or shift-out
;   Z    (bit 1) — Zero:     set if result == 0
;   N    (bit 2) — Negative: set if bit 15 of result == 1
;   GIE  (bit 3) — Global Interrupt Enable: must be 1 for any interrupt to fire
;   CPUOFF (bit 4) — CPU off: stops fetching instructions (LPM0–LPM4)
;   OSCOFF (bit 5) — stop LFXT1 oscillator (LPM4)
;   SCG0   (bit 6) — disable DCO (LPM1, LPM3, LPM4)
;   SCG1   (bit 7) — disable SMCLK (LPM2, LPM3, LPM4)
;   V    (bit 8) — Overflow: signed arithmetic overflow
;
; LPM entry: bis.w #LPMx_bits, SR   (sets the relevant bits in SR)
; LPM exit in ISR: bic.w #CPUOFF, 0(SP)  (clears CPUOFF in the saved SR on stack)
;==============================================================================
.equ    C,          0x0001      ; bit 0 — Carry
.equ    Z,          0x0002      ; bit 1 — Zero
.equ    N,          0x0004      ; bit 2 — Negative
.equ    GIE,        0x0008      ; bit 3 — Global Interrupt Enable
.equ    CPUOFF,     0x0010      ; bit 4 — CPU off
.equ    OSCOFF,     0x0020      ; bit 5 — Oscillator off
.equ    SCG0,       0x0040      ; bit 6 — System clock gen 0 off
.equ    SCG1,       0x0080      ; bit 7 — System clock gen 1 off
.equ    V,          0x0100      ; bit 8 — Overflow

; Low-power mode entry masks (OR together to get the right combination of bits)
.equ    LPM0_bits,  CPUOFF                      ; CPU off, clocks running
.equ    LPM1_bits,  SCG0|CPUOFF                 ; CPU + DCO off
.equ    LPM3_bits,  SCG1|SCG0|CPUOFF            ; CPU + DCO + SMCLK off, ACLK on
.equ    LPM4_bits,  SCG1|SCG0|OSCOFF|CPUOFF     ; everything off

; LPM exit — use in ISR to wake the main loop:  bic.w #CPUOFF, 0(SP)

; End of msp430g2553-defs.s
