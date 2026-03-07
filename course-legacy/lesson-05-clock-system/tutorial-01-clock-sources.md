# MSP430G2552 Clock System

## The Three System Clocks

The MSP430 uses three different clocks that can be configured independently:

| Clock | Source Options | Purpose |
|-------|---------------|---------|
| **MCLK** (Master) | DCO, LFXT1, VLOCLK | CPU and main code execution |
| **SMCLK** (Sub-Main) | DCO, LFXT1, VLOCLK | Fast peripherals (Timer_A, USCI, ADC10) |
| **ACLK** (Auxiliary) | LFXT1, VLO | Low-power peripherals, RTC-style timing |

After reset, both MCLK and SMCLK default to the DCO. ACLK defaults to LFXT1
(external crystal pins). On the LaunchPad without a crystal, ACLK is unreliable
until you switch it to VLO.

## DCO — Digitally Controlled Oscillator

The DCO is an internal RC oscillator built into the chip. No external components
are needed.

- Range: approximately 100 kHz to 16 MHz
- Controlled by two registers: - **BCSCTL1** (Basic Clock System Control 1):
  RSEL bits select the frequency range (coarse) - **DCOCTL** (DCO Control): DCO
  and MOD bits fine-tune within the range
- Accuracy without calibration: roughly ±10% — too imprecise for UART or
  anything timing-critical
- Accuracy with TI calibration constants: ±1% — suitable for most applications
- Default at reset: approximately 1.1 MHz (imprecise)

## Calibration Constants

TI programs calibration values into Info Flash segment A at manufacture time.
Reading these constants and loading them into the DCO control registers gives
you a precisely calibrated frequency.

| Constant | Address | Use |
|----------|---------|-----|
| CALBC1_1MHZ  | 0x10FF | BCSCTL1 setting for 1 MHz  |
| CALDCO_1MHZ  | 0x10FE | DCOCTL setting for 1 MHz   |
| CALBC1_8MHZ  | 0x10FD | BCSCTL1 for 8 MHz          |
| CALDCO_8MHZ  | 0x10F9 | DCOCTL for 8 MHz           |
| CALBC1_12MHZ | 0x10FC | BCSCTL1 for 12 MHz         |
| CALDCO_12MHZ | 0x10F8 | DCOCTL for 12 MHz          |
| CALBC1_16MHZ | 0x10FB | BCSCTL1 for 16 MHz         |
| CALDCO_16MHZ | 0x10F7 | DCOCTL for 16 MHz          |

These are byte values stored in Info Flash. They survive normal program flash
operations but are destroyed by a full chip erase (mass erase). If 0x10FF reads
0xFF, the calibration has been erased and is invalid — do not use it.

## Setting DCO to 1 MHz

```asm
; Step 1: Clear DCOCTL first (required before changing BCSCTL1 range)
;         Prevents a brief glitch at an unintended intermediate frequency
clr.b   &DCOCTL

; Step 2: Load calibration constants from Info Flash
mov.b   &0x10FF, &BCSCTL1   ; BCSCTL1 for 1 MHz (CALBC1_1MHZ)
mov.b   &0x10FE, &DCOCTL    ; DCOCTL for 1 MHz  (CALDCO_1MHZ)

; Now MCLK = SMCLK = 1.000 MHz (±1%)
```

The clear-first sequence is important. BCSCTL1 controls the frequency range.
Changing the range while DCOCTL still has its old fine-tune value could briefly
send the clock to an unintended frequency. Clearing DCOCTL first ensures a clean
transition.

## BCSCTL1 — Additional Bits

BCSCTL1 contains more than just the RSEL (range select) bits. The calibration
constant preserves the important ones:

- **XT2OFF** (bit 7): Should remain 1 on G2552, which has no XT2 oscillator pin
- **XTS** (bit 6): 0 = low frequency mode for LFXT1 (correct for VLO or 32kHz
  crystal)
- **DIVA** (bits 5:4): ACLK divider — 00=/1, 01=/2, 10=/4, 11=/8
- **RSEL** (bits 3:0): DCO range select (set by calibration)

The calibration constant at 0x10FF preserves XT2OFF=1 and sets the correct RSEL
for 1 MHz.

## VLO — Very Low Frequency Oscillator

The VLO is a second internal oscillator optimized for minimal current draw:

- Frequency: approximately 12 kHz typical (range: 6–16 kHz across voltage and
  temperature)
- Current: extremely low — designed for low-power sleep periods
- No external components needed
- Not precise enough for UART, but fine for rough periodic wakeups

```asm
; Use VLO as ACLK source
; LFXT1S_2 = 0x20 in BCSCTL3 selects VLO
bis.b   #0x20, &BCSCTL3
```

After this, ACLK runs at ~12 kHz from the VLO. MCLK and SMCLK are unaffected.

## BCSCTL2 — Clock Dividers

You can independently divide MCLK and SMCLK for lower speeds without changing
the DCO:

```asm
; Divide MCLK by 8:  DIVM_3 = 0x30 (bits 5:4 = 11)
bis.b   #0x30, &BCSCTL2

; Divide SMCLK by 4: DIVS_2 = 0x04 (bits 3:2 = 10)
bis.b   #0x04, &BCSCTL2
```

Dividers available: /1, /2, /4, /8

## Clock Domain Summary

```
DCO (controlled by BCSCTL1/DCOCTL)
  |
  +---> MCLK (divided by DIVM in BCSCTL2)  ---> CPU, all code
  |
  +---> SMCLK (divided by DIVS in BCSCTL2) ---> Timer_A, USCI, ADC10

VLO or LFXT1 (selected by BCSCTL3)
  |
  +---> ACLK (divided by DIVA in BCSCTL1)  ---> Low-power peripherals
```

## Practical Notes

1. Always disable the watchdog timer before configuring the clock, or service it
   promptly. The WDT runs on SMCLK by default and can reset the CPU during a
   frequency transition.

2. The G2552 has no XT2 crystal. BCSCTL1 bit XT2OFF is 1 at reset and must stay
   1.

3. Info Flash addresses 0x10FF through 0x10F7 hold calibration constants.
   Segment A (0x10C0–0x10FF) is write-protected by default — you cannot
   accidentally overwrite it during normal code flash operations.

4. At 1 MHz with MCLK=SMCLK=DCO: one instruction cycle = 1 microsecond. This
   makes timing calculations straightforward.
