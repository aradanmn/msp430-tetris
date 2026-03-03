# Tutorial 16-1 · Low Power Mode Fundamentals

## The Status Register and LPM Bits

Low Power Mode is entered by setting bits in the Status Register (SR):

| SR Bit | Name   | Function |
|--------|--------|----------|
| 4      | CPUOFF | Turns off CPU (MCLK) |
| 5      | OSCOFF | Turns off LFXT1 oscillator |
| 7      | SCG0   | Turns off FLL (if present) |
| 8      | SCG1   | Turns off SMCLK |

Setting combinations via `bis.w #bits, SR`:

| Mode | SR Bits Set | Entry Instruction |
|------|-------------|-------------------|
| LPM0 | CPUOFF | `bis.w #(GIE\|CPUOFF), SR` |
| LPM1 | CPUOFF \| SCG0 | `bis.w #(GIE\|CPUOFF\|SCG0), SR` |
| LPM2 | CPUOFF \| SCG1 | `bis.w #(GIE\|CPUOFF\|SCG1), SR` |
| LPM3 | CPUOFF \| SCG0 \| SCG1 | `bis.w #(GIE\|CPUOFF\|SCG0\|SCG1), SR` |
| LPM4 | CPUOFF \| SCG0 \| SCG1 \| OSCOFF | `bis.w #(GIE\|CPUOFF\|SCG0\|SCG1\|OSCOFF), SR` |

`GIE` (bit 3) must be set so interrupts can wake the CPU.

---

## What Stays Active in Each Mode

### LPM0
- CPU off, SMCLK on → Timer_A, USCI (UART/SPI/I2C) still work
- Use when: waiting for UART receive or SPI transfer
- Entry: `bis.w #(GIE|CPUOFF), SR`

### LPM3
- CPU off, SMCLK off, ACLK on (32.768 kHz crystal or VLO ~12 kHz)
- Timer_A sourced from ACLK still runs → WDT interval mode works
- Use when: periodic wakeup needed (RTC-like), UART not needed
- Entry: `bis.w #(GIE|CPUOFF|SCG0|SCG1), SR`

### LPM4
- Everything off except GPIO and port interrupt logic
- Only wake source: GPIO interrupt (P1, P2)
- Use when: button-press wakeup from deepest sleep
- Entry: `bis.w #(GIE|CPUOFF|SCG0|SCG1|OSCOFF), SR`

---

## Exiting LPM from an ISR

The ISR must clear the LPM bits in the **saved copy of SR on the stack**:

```asm
MY_ISR:
        ; … do work …
        bic.w   #(CPUOFF|SCG0|SCG1), 0(SP)   ; clear LPM3 bits in saved SR
        reti                        ; restores modified SR → CPU wakes
```

For LPM0 only `CPUOFF` needs clearing:
```asm
        bic.w   #CPUOFF, 0(SP)
```

---

## VLO as ACLK Source (No Crystal Needed)

The LaunchPad G2 has a 32.768 kHz crystal option, but if not populated, use the
internal VLO (~12 kHz typical):

```asm
        mov.b   #(LFXT1S_2), &BCSCTL3   ; ACLK = VLO (~12kHz)
```

WDT interval at VLO:
```asm
        ; WDTTMSEL=1, WDTSSEL=1 (ACLK), WDTIS1=1 (÷8192)
        ; Period ≈ 8192 / 12000 ≈ 0.68 s
        mov.w   #(WDTPW|WDTTMSEL|WDTSSEL|WDTCNTCL|WDTIS1), &WDTCTL
        bis.b   #WDTIE, &IE1
```

---

## Power Calculation Example

A system that wakes every 1 second from LPM3, samples ADC (2 ms), sends UART (5
ms), then sleeps:

```
Active time = 7 ms/s,  I_active ≈ 400 µA
Sleep time  = 993 ms/s, I_LPM3  ≈ 1 µA

Average I = (0.007 × 400 + 0.993 × 1) µA ≈ 3.8 µA
```

A 1000 mAh coin cell would last approximately 30 years at 3.8 µA.

---

## Next

Tutorial 02 covers specific wake sources: WDT interval, Timer_A from ACLK, GPIO,
and UART RX.
