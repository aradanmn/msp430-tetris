# Tutorial 15-2 · USCI_B0 I2C Master — Registers and Sequences

## Key Registers

| Register  | Address | Purpose |
|-----------|---------|---------|
| UCB0CTL0  | 0x0068  | Mode (UCMODE_3=I2C), UCMST, UCSYNC |
| UCB0CTL1  | 0x0069  | Clock, UCSWRST, UCTR (TX/RX), UCTXSTT (start), UCTXSTP (stop) |
| UCB0BR0   | 0x006A  | SCL clock divisor low |
| UCB0BR1   | 0x006B  | SCL clock divisor high |
| UCB0I2CSA | 0x011A  | Slave address (7-bit, bits 6:0) |
| UCB0STAT  | 0x006D  | UCBBUSY, UCNACKIFG, UCSTPIFG |
| UCB0RXBUF | 0x006E  | Received byte |
| UCB0TXBUF | 0x006F  | Byte to transmit |

**UCB0CTL0** for I2C master: `UCMODE_3 | UCMST | UCSYNC`

```asm
; UCMODE_3 = 0x06 (bits 2:1 = 11 = I2C)
; UCMST    = 0x08
; UCSYNC   = 0x01
mov.b   #(UCMODE_3|UCMST|UCSYNC), &UCB0CTL0    ; = 0x0F
```

**UCB0CTL1** control bits:

| Bit | Symbol  | Function |
|-----|---------|----------|
| 7-6 | UCSSEL  | Clock source (10 = SMCLK) |
| 4   | UCTR    | 1=Transmit, 0=Receive |
| 2   | UCTXNACK| Send NACK on next byte |
| 1   | UCTXSTP | Generate STOP |
| 0   | UCTXSTT | Generate START (auto-sends address) |

---

## Initialization Sequence

```asm
        .equ    I2C_SDA, BIT6       ; P1.6
        .equ    I2C_SCL, BIT7       ; P1.7

        bis.b   #UCSWRST, &UCB0CTL1
        mov.b   #(UCMODE_3|UCMST|UCSYNC), &UCB0CTL0
        mov.b   #(UCSSEL_2|UCSWRST), &UCB0CTL1     ; SMCLK
        mov.b   #10, &UCB0BR0                        ; 1MHz/10 = 100kHz
        mov.b   #0,  &UCB0BR1
        bis.b   #(I2C_SDA|I2C_SCL), &P1SEL
        bis.b   #(I2C_SDA|I2C_SCL), &P1SEL2
        bic.b   #UCSWRST, &UCB0CTL1
```

---

## Master Write Sequence

```asm
; i2c_write_byte — send one byte to slave
; R12 = slave address (7-bit), R13 = byte to send
i2c_write_byte:
        mov.b   R12, &UCB0I2CSA         ; set slave address
        bis.b   #UCTR, &UCB0CTL1        ; transmit mode
        bis.b   #UCTXSTT, &UCB0CTL1     ; START + address sent automatically

        ; Wait for address ACK and TXBUF ready
_i2c_w_start:
        bit.b   #UCTXSTT, &UCB0CTL1     ; START sent when bit clears
        jnz     _i2c_w_start

        ; Check for NACK
        bit.b   #UCNACKIFG, &UCB0STAT
        jnz     i2c_nack

        ; Load data byte
        mov.b   R13, &UCB0TXBUF

        ; Wait for TX complete
_i2c_w_tx:
        bit.b   #UCB0TXIFG, &IFG2
        jz      _i2c_w_tx

        ; Send STOP
        bis.b   #UCTXSTP, &UCB0CTL1
_i2c_w_stop:
        bit.b   #UCTXSTP, &UCB0CTL1     ; wait for STOP sent
        jnz     _i2c_w_stop
        ret

i2c_nack:
        bis.b   #UCTXSTP, &UCB0CTL1     ; release bus
        ; … handle error …
        ret
```

---

## Master Read Sequence

```asm
; i2c_read_byte — receive one byte from slave
; R12 = slave address (7-bit)
; Returns received byte in R12
i2c_read_byte:
        mov.b   R12, &UCB0I2CSA
        bic.b   #UCTR, &UCB0CTL1        ; receive mode
        bis.b   #UCTXSTT, &UCB0CTL1     ; START + address

        ; Wait for START sent
_i2c_r_start:
        bit.b   #UCTXSTT, &UCB0CTL1
        jnz     _i2c_r_start

        ; For single-byte read: set NACK + STOP before data arrives
        bis.b   #(UCTXNACK|UCTXSTP), &UCB0CTL1

        ; Wait for byte received
_i2c_r_rx:
        bit.b   #UCB0RXIFG, &IFG2
        jz      _i2c_r_rx

        mov.b   &UCB0RXBUF, R12         ; read received byte
        ret
```

---

## Common Pitfalls

1. **Missing pull-ups** — I2C lines float high only if 4.7 kΩ resistors are
   connected to VCC.  Without them, the bus cannot work.
2. **Address vs 8-bit frame** — `UCB0I2CSA` holds only the 7-bit address; USCI
   appends the R/W̄ bit automatically.  Do not shift the address.
3. **NACK handling** — always check `UCNACKIFG` after sending the address. A
   NACK means no device responded; always send STOP to release the bus.
4. **Bus busy** — if a previous transaction failed mid-way, `UCBBUSY` may stay
   set.  A STOP condition (`UCTXSTP`) or USCI reset clears it.

---

## Next

Exercises implement an I2C bus scanner, EEPROM write/read, and a TMP102/LM75
temperature sensor reader.
