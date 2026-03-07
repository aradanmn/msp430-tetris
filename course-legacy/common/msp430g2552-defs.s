;******************************************************************************
; msp430g2552-defs.s
;
; MSP430G2552 register and bit definitions for GNU assembler.
; Include this file at the top of every lesson with:
;
;   #include "../../common/msp430g2552-defs.s"
;
; (adjust the relative path to match your lesson location)
;
; MSP430G2552 at a glance:
;   - 16-bit RISC CPU, 16 registers (R0-R15)
;   - 8KB Flash  (0xE000-0xFFFF)
;   - 512B RAM   (0x0200-0x03FF)
;   - Peripherals mapped into address space (0x0000-0x01FF)
;
; LaunchPad pin assignments:
;   P1.0 = LED1  (Red)
;   P1.6 = LED2  (Green)
;   P1.3 = Button S2  (active LOW, use internal pull-up)
;   P1.1 = UCA0RXD  (UART receive)
;   P1.2 = UCA0TXD  (UART transmit)
;******************************************************************************

;==============================================================================
; Special Function Registers (0x0000-0x000F)
;==============================================================================
.equ    IE1,        0x0000      ; Interrupt Enable 1
.equ    IFG1,       0x0002      ; Interrupt Flag 1
.equ    IE2,        0x0001      ; Interrupt Enable 2
.equ    IFG2,       0x0003      ; Interrupt Flag 2
.equ    ME2,        0x0005      ; Module Enable 2

;==============================================================================
; Port 1 (8-bit registers, 0x0020-0x0027)
;==============================================================================
.equ    P1IN,       0x0020      ; Port 1 Input
.equ    P1OUT,      0x0021      ; Port 1 Output
.equ    P1DIR,      0x0022      ; Port 1 Direction  (0=in, 1=out)
.equ    P1IFG,      0x0023      ; Port 1 Interrupt Flag
.equ    P1IES,      0x0024      ; Port 1 Interrupt Edge Select (0=rising, 1=falling)
.equ    P1IE,       0x0025      ; Port 1 Interrupt Enable
.equ    P1SEL,      0x0026      ; Port 1 Function Select (0=GPIO, 1=peripheral)
.equ    P1REN,      0x0027      ; Port 1 Resistor Enable

;==============================================================================
; Port 2 (8-bit registers, 0x0028-0x002F)
;==============================================================================
.equ    P2IN,       0x0028      ; Port 2 Input
.equ    P2OUT,      0x0029      ; Port 2 Output
.equ    P2DIR,      0x002A      ; Port 2 Direction
.equ    P2IFG,      0x002B      ; Port 2 Interrupt Flag
.equ    P2IES,      0x002C      ; Port 2 Interrupt Edge Select
.equ    P2IE,       0x002D      ; Port 2 Interrupt Enable
.equ    P2SEL,      0x002E      ; Port 2 Function Select
.equ    P2REN,      0x002F      ; Port 2 Resistor Enable

;==============================================================================
; Port 3 (8-bit, 0x0018-0x001A)
;==============================================================================
.equ    P3IN,       0x0018
.equ    P3OUT,      0x0019
.equ    P3DIR,      0x001A

;==============================================================================
; Port 1/2 SEL2 (secondary function select, 0x0041-0x0042)
;==============================================================================
.equ    P1SEL2,     0x0041
.equ    P2SEL2,     0x0042

;==============================================================================
; Useful bit masks (BIT0-BIT7)
;==============================================================================
.equ    BIT0,       0x01
.equ    BIT1,       0x02
.equ    BIT2,       0x04
.equ    BIT3,       0x08
.equ    BIT4,       0x10
.equ    BIT5,       0x20
.equ    BIT6,       0x40
.equ    BIT7,       0x80

; LaunchPad aliases
.equ    LED1,       BIT0        ; P1.0 Red LED
.equ    LED2,       BIT6        ; P1.6 Green LED
.equ    BTN,        BIT3        ; P1.3 Button (active low)
.equ    UART_RX,    BIT1        ; P1.1 UCA0RXD
.equ    UART_TX,    BIT2        ; P1.2 UCA0TXD

;==============================================================================
; Watchdog Timer (16-bit, 0x0120)
;==============================================================================
.equ    WDTCTL,     0x0120      ; Watchdog Timer Control

; WDTCTL fields
.equ    WDTPW,      0x5A00      ; Password (must be written with control word)
.equ    WDTHOLD,    0x0080      ; Hold WDT (stop it)
.equ    WDTTMSEL,   0x0010      ; Timer mode select (1 = interval timer)
.equ    WDTCNTCL,   0x0008      ; Counter clear
.equ    WDTSSEL,    0x0004      ; Clock source (0=SMCLK, 1=ACLK)
.equ    WDTIS1,     0x0002      ; Interval select bit 1
.equ    WDTIS0,     0x0001      ; Interval select bit 0

; WDT interval presets (SMCLK @ 1MHz)
.equ    WDT_MDLY_32,    WDTPW|WDTTMSEL|WDTCNTCL|0x0000  ; ~32ms
.equ    WDT_MDLY_8,     WDTPW|WDTTMSEL|WDTCNTCL|WDTIS0  ; ~8ms
.equ    WDT_MDLY_0_5,   WDTPW|WDTTMSEL|WDTCNTCL|WDTIS1  ; ~0.5ms

;==============================================================================
; Basic Clock System (8-bit, 0x0053-0x0058)
;==============================================================================
.equ    BCSCTL3,    0x0053      ; Basic Clock System Control 3
.equ    DCOCTL,     0x0056      ; DCO Control (frequency fine-tune)
.equ    BCSCTL1,    0x0057      ; Basic Clock System Control 1
.equ    BCSCTL2,    0x0058      ; Basic Clock System Control 2

; BCSCTL1 fields
.equ    XT2OFF,     0x80        ; Disable XT2 oscillator
.equ    XTS,        0x40        ; LFXT1 mode (0=LF, 1=HF)
.equ    DIVA_0,     0x00        ; ACLK divider /1
.equ    DIVA_1,     0x10        ; ACLK divider /2
.equ    DIVA_2,     0x20        ; ACLK divider /4
.equ    DIVA_3,     0x30        ; ACLK divider /8
.equ    RSEL3,      0x08        ; Range select bit 3
.equ    RSEL2,      0x04        ; Range select bit 2
.equ    RSEL1,      0x02        ; Range select bit 1
.equ    RSEL0,      0x01        ; Range select bit 0

; BCSCTL2 fields
.equ    SELM_0,     0x00        ; MCLK source = DCO
.equ    SELM_2,     0x80        ; MCLK source = XT2
.equ    SELM_3,     0xC0        ; MCLK source = LFXT1
.equ    DIVM_0,     0x00        ; MCLK divider /1
.equ    DIVM_1,     0x10        ; MCLK divider /2
.equ    DIVM_2,     0x20        ; MCLK divider /4
.equ    DIVM_3,     0x30        ; MCLK divider /8
.equ    SELS,       0x08        ; SMCLK source (0=DCO, 1=XT2)
.equ    DIVS_0,     0x00        ; SMCLK divider /1
.equ    DIVS_1,     0x02        ; SMCLK divider /2
.equ    DIVS_2,     0x04        ; SMCLK divider /4
.equ    DIVS_3,     0x06        ; SMCLK divider /8

; BCSCTL3 fields
.equ    XCAP_0,     0x00        ; Crystal cap 1pF
.equ    XCAP_1,     0x04        ; Crystal cap 6pF
.equ    XCAP_2,     0x08        ; Crystal cap 10pF
.equ    XCAP_3,     0x0C        ; Crystal cap 12.5pF (default)

; Calibration constants in Flash (written by TI at manufacture)
.equ    CALBC1_1MHZ,    0x10FF  ; BCSCTL1 cal value for 1MHz DCO
.equ    CALBC1_8MHZ,    0x10FE  ; BCSCTL1 cal value for 8MHz DCO
.equ    CALBC1_12MHZ,   0x10FD  ; BCSCTL1 cal value for 12MHz DCO
.equ    CALBC1_16MHZ,   0x10FC  ; BCSCTL1 cal value for 16MHz DCO
.equ    CALDCO_1MHZ,    0x10FE  ; DCOCTL cal value for 1MHz DCO (note: uses 8-bit read)
.equ    CALDCO_8MHZ,    0x10FA  ; DCOCTL cal value for 8MHz DCO
.equ    CALDCO_12MHZ,   0x10F9  ; DCOCTL cal value for 12MHz DCO
.equ    CALDCO_16MHZ,   0x10F8  ; DCOCTL cal value for 16MHz DCO

;==============================================================================
; Timer_A3 (three capture/compare units: TA0, TA1, TA2)
; 16-bit registers at 0x0160-0x0176
;==============================================================================
.equ    TACTL,      0x0160      ; Timer_A Control
.equ    TACCTL0,    0x0162      ; Capture/Compare Control 0
.equ    TACCTL1,    0x0164      ; Capture/Compare Control 1
.equ    TACCTL2,    0x0166      ; Capture/Compare Control 2
.equ    TAR,        0x0170      ; Timer_A Counter Register
.equ    TACCR0,     0x0172      ; Capture/Compare Register 0 (sets period in Up mode)
.equ    TACCR1,     0x0174      ; Capture/Compare Register 1
.equ    TACCR2,     0x0176      ; Capture/Compare Register 2
.equ    TAIV,       0x012E      ; Timer_A Interrupt Vector

; TACTL fields
.equ    TASSEL_0,   0x0000      ; Clock source: TACLK external
.equ    TASSEL_1,   0x0100      ; Clock source: ACLK
.equ    TASSEL_2,   0x0200      ; Clock source: SMCLK
.equ    TASSEL_3,   0x0300      ; Clock source: INCLK
.equ    ID_0,       0x0000      ; Input divider /1
.equ    ID_1,       0x0040      ; Input divider /2
.equ    ID_2,       0x0080      ; Input divider /4
.equ    ID_3,       0x00C0      ; Input divider /8
.equ    MC_0,       0x0000      ; Stop mode
.equ    MC_1,       0x0010      ; Up mode (count to TACCR0)
.equ    MC_2,       0x0020      ; Continuous mode (count to 0xFFFF)
.equ    MC_3,       0x0030      ; Up/Down mode
.equ    TACLR,      0x0004      ; Clear timer counter
.equ    TAIE,       0x0002      ; Timer overflow interrupt enable
.equ    TAIFG,      0x0001      ; Timer overflow interrupt flag

; TACCTL fields (for TACCTL0, TACCTL1, TACCTL2)
.equ    CM_0,       0x0000      ; No capture
.equ    CM_1,       0x4000      ; Capture on rising edge
.equ    CM_2,       0x8000      ; Capture on falling edge
.equ    CM_3,       0xC000      ; Capture on both edges
.equ    CCIS_0,     0x0000      ; Capture input: CCIxA
.equ    CCIS_1,     0x1000      ; Capture input: CCIxB
.equ    CCIS_2,     0x2000      ; Capture input: GND
.equ    CCIS_3,     0x3000      ; Capture input: VCC
.equ    SCS,        0x0800      ; Synchronize capture source
.equ    CAP,        0x0100      ; Capture mode (0=compare, 1=capture)
; OUTMOD values (output mode for PWM)
.equ    OUTMOD_0,   0x0000      ; Output (set by OUT bit)
.equ    OUTMOD_1,   0x0020      ; Set
.equ    OUTMOD_2,   0x0040      ; Toggle/Reset
.equ    OUTMOD_3,   0x0060      ; Set/Reset
.equ    OUTMOD_4,   0x0080      ; Toggle
.equ    OUTMOD_5,   0x00A0      ; Reset
.equ    OUTMOD_6,   0x00C0      ; Toggle/Set
.equ    OUTMOD_7,   0x00E0      ; Reset/Set  ← most common for PWM
.equ    CCIE,       0x0010      ; Capture/Compare Interrupt Enable
.equ    CCIFG,      0x0001      ; Capture/Compare Interrupt Flag
.equ    OUT,        0x0004      ; Output bit value

;==============================================================================
; ADC10 (0x01B0-0x01BC, plus 8-bit at 0x0048-0x004C)
;==============================================================================
.equ    ADC10DTC0,  0x0048      ; ADC10 Data Transfer Control 0
.equ    ADC10DTC1,  0x0049      ; ADC10 Data Transfer Control 1
.equ    ADC10AE0,   0x004B      ; ADC10 Analog Enable 0 (channels 0-7)
.equ    ADC10AE1,   0x004C      ; ADC10 Analog Enable 1 (channels 8-15)
.equ    ADC10CTL0,  0x01B0      ; ADC10 Control 0
.equ    ADC10CTL1,  0x01B2      ; ADC10 Control 1
.equ    ADC10MEM,   0x01B4      ; ADC10 Memory (10-bit result, right-justified)
.equ    ADC10SA,    0x01BC      ; ADC10 DTC Start Address

; ADC10CTL0 fields
.equ    ADC10SC,    0x0001      ; Start conversion
.equ    ENC,        0x0002      ; Enable conversion
.equ    ADC10IFG,   0x0004      ; Interrupt flag
.equ    ADC10IE,    0x0008      ; Interrupt enable
.equ    ADC10ON,    0x0010      ; ADC10 power on
.equ    REFON,      0x0020      ; Internal reference on
.equ    REF2_5V,    0x0040      ; Reference = 2.5V (0 = 1.5V)
.equ    MSC,        0x0080      ; Multiple sample and convert
.equ    ADC10SR,    0x0100      ; Sampling rate
.equ    ADC10SHT_0, 0x0000      ; Sample-and-hold time: 4 × ADC10CLK
.equ    ADC10SHT_1, 0x0800      ; Sample-and-hold time: 8 × ADC10CLK
.equ    ADC10SHT_2, 0x1000      ; Sample-and-hold time: 16 × ADC10CLK
.equ    ADC10SHT_3, 0x1800      ; Sample-and-hold time: 64 × ADC10CLK
.equ    SREF_0,     0x0000      ; Vr+ = VCC,  Vr- = GND
.equ    SREF_1,     0x2000      ; Vr+ = Vref, Vr- = GND
.equ    SREF_2,     0x4000      ; Vr+ = VeRef+, Vr- = GND
.equ    SREF_7,     0xE000      ; Vr+ = Vref, Vr- = VeRef-

; ADC10CTL1 fields
.equ    ADC10BUSY,  0x0001      ; Busy flag
.equ    CONSEQ_0,   0x0000      ; Single channel, single conversion
.equ    CONSEQ_1,   0x0002      ; Sequence of channels
.equ    CONSEQ_2,   0x0004      ; Repeat single channel
.equ    CONSEQ_3,   0x0006      ; Repeat sequence
.equ    ADC10SSEL_0, 0x0000     ; ADC10CLK source: ADC10OSC (~5MHz)
.equ    ADC10SSEL_1, 0x0008     ; ADC10CLK source: ACLK
.equ    ADC10SSEL_2, 0x0010     ; ADC10CLK source: MCLK
.equ    ADC10SSEL_3, 0x0018     ; ADC10CLK source: SMCLK
.equ    ADC10DIV_0,  0x0000     ; ADC10CLK divider /1
.equ    ADC10DIV_7,  0x00E0     ; ADC10CLK divider /8
.equ    ISSH,        0x0100     ; Invert sample-and-hold signal
.equ    ADC10DF,     0x0200     ; Data format (0=unsigned binary, 1=2's complement)
.equ    SHS_0,       0x0000     ; Sample-and-hold source: ADC10SC
.equ    SHS_1,       0x0400     ; Sample-and-hold source: Timer_A TACCR1
; Input channel select (bits 12-15 of ADC10CTL1)
.equ    INCH_0,     0x0000      ; A0 = P1.0
.equ    INCH_1,     0x1000      ; A1 = P1.1
.equ    INCH_2,     0x2000      ; A2 = P1.2
.equ    INCH_3,     0x3000      ; A3 = P1.3
.equ    INCH_4,     0x4000      ; A4 = P1.4
.equ    INCH_5,     0x5000      ; A5 = P1.5
.equ    INCH_6,     0x6000      ; A6 = P1.6
.equ    INCH_7,     0x7000      ; A7 = P1.7
.equ    INCH_10,    0xA000      ; A10 = Internal temperature sensor
.equ    INCH_11,    0xB000      ; A11 = (VCC - VSS) / 2
.equ    INCH_12,    0xC000      ; A12 = (VCC - VSS) / 2
.equ    INCH_13,    0xD000      ; A13 = (VCC - VSS) / 2
.equ    INCH_14,    0xE000      ; A14 = (VCC - VSS) / 2
.equ    INCH_15,    0xF000      ; A15 = (VCC - VSS) / 2

;==============================================================================
; USCI_A0 - UART and SPI A  (8-bit registers, 0x0060-0x0067)
;==============================================================================
.equ    UCA0CTL0,   0x0060      ; Control 0
.equ    UCA0CTL1,   0x0061      ; Control 1
.equ    UCA0BR0,    0x0062      ; Baud rate control 0 (low byte)
.equ    UCA0BR1,    0x0063      ; Baud rate control 1 (high byte)
.equ    UCA0MCTL,   0x0064      ; Modulation control (for UART)
.equ    UCA0STAT,   0x0065      ; Status
.equ    UCA0RXBUF,  0x0066      ; Receive buffer
.equ    UCA0TXBUF,  0x0067      ; Transmit buffer

; UCA0CTL1 fields
.equ    UCSSEL_0,   0x00        ; Clock source: UCLK
.equ    UCSSEL_1,   0x40        ; Clock source: ACLK
.equ    UCSSEL_2,   0x80        ; Clock source: SMCLK
.equ    UCSWRST,    0x01        ; Software reset (hold in reset while configuring)

; UCA0CTL0 fields (UART mode: all zeros for 8-N-1)
.equ    UCPEN,      0x80        ; Parity enable
.equ    UCPAR,      0x40        ; Parity select (0=odd, 1=even)
.equ    UCMSB,      0x20        ; MSB first
.equ    UC7BIT,     0x10        ; 7-bit data
.equ    UCSPB,      0x08        ; Two stop bits
.equ    UCMODE_0,   0x00        ; UART mode
.equ    UCMODE_1,   0x02        ; Idle-line multiprocessor
.equ    UCMODE_2,   0x04        ; Address-bit multiprocessor
.equ    UCMODE_3,   0x06        ; UART with auto baud rate detection
.equ    UCSYNC,     0x01        ; Synchronous mode (SPI or I2C vs UART)

; UCA0STAT flags
.equ    UCLISTEN,   0x80        ; Listen enable (loopback)
.equ    UCFE,       0x40        ; Framing error
.equ    UCOE,       0x20        ; Overrun error
.equ    UCPE,       0x10        ; Parity error
.equ    UCBRK,      0x08        ; Break detect
.equ    UCRXERR,    0x04        ; Receive error flag
.equ    UCADDR,     0x02        ; Address received
.equ    UCBUSY,     0x01        ; USCI busy (TX or RX in progress)

; IE2 / IFG2 bits for USCI
.equ    UCA0RXIE,   0x01        ; USCI_A0 receive interrupt enable
.equ    UCA0TXIE,   0x02        ; USCI_A0 transmit interrupt enable
.equ    UCB0RXIE,   0x04        ; USCI_B0 receive interrupt enable
.equ    UCB0TXIE,   0x08        ; USCI_B0 transmit interrupt enable
.equ    UCA0RXIFG,  0x01        ; USCI_A0 receive interrupt flag
.equ    UCA0TXIFG,  0x02        ; USCI_A0 transmit interrupt flag
.equ    UCB0RXIFG,  0x04        ; USCI_B0 receive interrupt flag
.equ    UCB0TXIFG,  0x08        ; USCI_B0 transmit interrupt flag

;==============================================================================
; USCI_B0 - SPI B and I2C  (8-bit registers, 0x0068-0x006F)
;==============================================================================
.equ    UCB0CTL0,   0x0068      ; Control 0
.equ    UCB0CTL1,   0x0069      ; Control 1
.equ    UCB0BR0,    0x006A      ; Bit rate control 0
.equ    UCB0BR1,    0x006B      ; Bit rate control 1
.equ    UCB0I2CIE,  0x006C      ; I2C interrupt enable
.equ    UCB0STAT,   0x006D      ; Status
.equ    UCB0RXBUF,  0x006E      ; Receive buffer
.equ    UCB0TXBUF,  0x006F      ; Transmit buffer
; I2C address registers (16-bit)
.equ    UCB0I2COA,  0x0118      ; Own address
.equ    UCB0I2CSA,  0x011A      ; Slave address

; UCB0CTL0 fields (SPI / I2C)
.equ    UCCKPH,     0x80        ; Clock phase
.equ    UCCKPL,     0x40        ; Clock polarity (0=inactive low)
.equ    UCMST,      0x08        ; Master mode
.equ    UCMODE_SPI, 0x00        ; 3-pin SPI
.equ    UCMODE_I2C, 0x06        ; I2C mode
.equ    UCMST_I2C,  0x08        ; I2C master
.equ    UCA10,      0x80        ; Own address 10-bit

; UCB0CTL1 fields
.equ    UCTR,       0x10        ; Transmitter (I2C: 0=rx, 1=tx)
.equ    UCTXNACK,   0x08        ; Transmit NACK
.equ    UCTXSTP,    0x04        ; Transmit STOP condition
.equ    UCTXSTT,    0x02        ; Transmit START condition

;==============================================================================
; Status Register (R2/SR) bits — for interrupt and LPM control
;==============================================================================
.equ    C,          0x0001      ; Carry
.equ    Z,          0x0002      ; Zero
.equ    N,          0x0004      ; Negative
.equ    GIE,        0x0008      ; Global Interrupt Enable
.equ    CPUOFF,     0x0010      ; CPU off (LPM1-LPM4)
.equ    OSCOFF,     0x0020      ; Oscillator off (LPM2, LPM4)
.equ    SCG0,       0x0040      ; System clock generator 0 off (LPM1-LPM4)
.equ    SCG1,       0x0080      ; System clock generator 1 off (LPM3, LPM4)
.equ    V,          0x0100      ; Overflow

; Low Power Mode entry values (OR into SR with BIS.W)
.equ    LPM0_bits,  CPUOFF
.equ    LPM1_bits,  SCG0|CPUOFF
.equ    LPM2_bits,  SCG1|CPUOFF
.equ    LPM3_bits,  SCG1|SCG0|CPUOFF
.equ    LPM4_bits,  SCG1|SCG0|OSCOFF|CPUOFF

; LPM exit value (clear LPM bits in saved SR during ISR)
.equ    LPM0_EXIT,  ~LPM0_bits & 0x00F0
.equ    LPM3_EXIT,  ~LPM3_bits & 0x00F0

;==============================================================================
; Interrupt Vector Table  (0xFFE0-0xFFFF)
; The linker places code here via the .vectors section.
; Vector addresses (each is a 16-bit word pointing to an ISR):
;==============================================================================
; 0xFFE0  Unused
; 0xFFE2  Unused
; 0xFFE4  Port 1          ← P1 interrupts
; 0xFFE6  Port 2          ← P2 interrupts
; 0xFFE8  Unused
; 0xFFEA  ADC10           ← ADC10 conversion complete
; 0xFFEC  USCI A0/B0 RX  ← UART/SPI/I2C receive
; 0xFFEE  USCI A0/B0 TX  ← UART/SPI/I2C transmit
; 0xFFF0  Unused (no Comparator_A on G2552)
; 0xFFF2  Timer_A CC1-2/overflow (TAIV)
; 0xFFF4  Timer_A CC0     ← most precise timer interrupt
; 0xFFF6  WDT+            ← watchdog timer interval
; 0xFFF8  Unused
; 0xFFFA  Unused
; 0xFFFC  Unused
; 0xFFFE  Reset (NMI/RST#)

; End of msp430g2552-defs.s
