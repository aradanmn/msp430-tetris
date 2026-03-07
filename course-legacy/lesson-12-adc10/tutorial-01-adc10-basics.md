# Tutorial 12-1 · ADC10 Basics

## ADC10 Overview

The ADC10 is a successive-approximation ADC with:
- **10-bit resolution**: 0–1023 output
- **8 external channels** (A0–A7, shared with P1 pins)
- **2 internal channels**: A10 = temperature sensor, A11 = VCC/2
- **Programmable reference**: VCC, 1.5V internal, 2.5V internal, or external

---

## Key Registers

| Register | Address | Size | Purpose |
|----------|---------|------|---------|
| ADC10CTL0 | 0x01B0 | 16-bit | Reference, sample time, power, start |
| ADC10CTL1 | 0x01B2 | 16-bit | Channel, clock, conversion mode |
| ADC10MEM | 0x01B4 | 16-bit | Conversion result (right-justified) |
| ADC10AE0 | 0x004B | 8-bit | Analog enable for P1 pins |

---

## ADC10CTL0 — Control Register 0

Important fields:

| Field | Bits | Description |
|-------|------|-------------|
| SREF | 15:13 | Reference: SREF_1 = Vref+/GND (1.5V internal) |
| ADC10SHT | 12:11 | Sample time: ADC10SHT_3 = 64 ADC10CLK (longest) |
| REFON | 5 | Turn on internal reference |
| ADC10ON | 4 | Power on ADC10 |
| ENC | 1 | Enable conversion |
| ADC10SC | 0 | Start conversion (triggers immediately if ENC set) |
| ADC10BUSY | — | In CTL1: 1 = conversion in progress |

---

## ADC10CTL1 — Control Register 1

Important fields:

| Field | Bits | Description |
|-------|------|-------------|
| INCH | 15:12 | Input channel: INCH_10 = internal temp sensor |
| CONSEQ | 3:2 | CONSEQ_0 = single channel, single conversion |
| ADC10SSEL | 4:3 | Clock: ADC10SSEL_3 = SMCLK |
| ADC10BUSY | 0 | 1 = busy converting |

---

## Configuration Sequence

```asm
; Step 1: Configure CTL1 — channel and clock BEFORE enabling
mov.w   #(INCH_10|ADC10SSEL_3|CONSEQ_0), &ADC10CTL1

; Step 2: Configure CTL0 — reference, sample time, power
; SREF_1 = internal 1.5V reference
; ADC10SHT_3 = 64 cycles sample time (needed for temp sensor)
; REFON = internal reference on
; ADC10ON = ADC power on
mov.w   #(SREF_1|ADC10SHT_3|REFON|ADC10ON), &ADC10CTL0

; Step 3: Wait for reference to stabilize (~30µs)
mov.w   #1000, R15
_ref_wait: dec.w R15
           jnz   _ref_wait

; Step 4: Start conversion
bis.w   #(ENC|ADC10SC), &ADC10CTL0

; Step 5: Wait for conversion complete (poll ADC10BUSY)
_adc_busy:
        bit.w   #ADC10BUSY, &ADC10CTL1
        jnz     _adc_busy           ; loop while busy

; Step 6: Read result
mov.w   &ADC10MEM, R12             ; R12 = 0-1023
```

---

## Using External Channels (A0–A7)

To read an external pin (e.g., P1.4 = A4):

```asm
; Enable analog input on P1.4
bis.b   #BIT4, &ADC10AE0           ; disable digital input buffer

; Use INCH_4 in CTL1
mov.w   #(INCH_4|ADC10SSEL_3|CONSEQ_0), &ADC10CTL1
```

Without setting ADC10AE0, the digital buffer on the pin may clamp the analog
input and give incorrect readings.

---

## Multiple Conversions

For repeated readings, the simplest approach is to restart each time:

```asm
read_loop:
        bic.w   #ENC, &ADC10CTL0       ; disable conversion
        bis.w   #(ENC|ADC10SC), &ADC10CTL0  ; re-enable and start
        _busy: bit.w #ADC10BUSY, &ADC10CTL1
               jnz  _busy
        mov.w   &ADC10MEM, R12
        ; ... process R12 ...
        jmp     read_loop
```

---

## ADC10 Interrupt (Optional)

Instead of polling ADC10BUSY, you can enable `ADC10IE` in CTL0. The ADC10
interrupt fires when conversion is complete (flag in CTL0). Vector: `0xFFEA`.
For simplicity, this course uses polling.

---

## Next

Tutorial 02 explains the internal temperature sensor and how to convert the ADC
result to degrees Celsius.
