# Tutorial 07-1 · Timer_A Modes

## Timer_A3 Overview

The MSP430G2552 has one **Timer_A3** module — a 16-bit timer with:
- One free-running counter register: **TAR** (`0x0170`)
- Three capture/compare registers: **TACCR0**, **TACCR1**, **TACCR2**
- Three control registers: **TACCTL0**, **TACCTL1**, **TACCTL2**
- One main control register: **TACTL** (`0x0160`)

---

## TACTL — The Control Register

```
Bits 15:14  (unused)
Bits 10:9   TASSEL — clock source
Bits  7:6   ID     — input divider
Bits  5:4   MC     — mode control
Bit   2     TACLR  — clear TAR (self-clearing)
Bit   1     TAIE   — timer overflow interrupt enable
Bit   0     TAIFG  — timer overflow interrupt flag
```

### Clock Source (TASSEL)

| Value | Source | Typical use |
|-------|--------|-------------|
| `TASSEL_1` (0x0100) | ACLK | Low-power timing |
| `TASSEL_2` (0x0200) | SMCLK | Precise timing at DCO speed |

### Input Divider (ID)

| Value | Divisor |
|-------|---------|
| `ID_0` (0x0000) | /1 |
| `ID_1` (0x0040) | /2 |
| `ID_2` (0x0080) | /4 |
| `ID_3` (0x00C0) | /8 |

At SMCLK = 1MHz with ID_3: timer ticks at **125kHz** (1 tick = 8µs).

---

## Three Timer Modes

### Mode 1 — Up Mode (`MC_1`)

TAR counts **0 → TACCR0**, then resets to 0 and repeats.

```
TAR: 0, 1, 2, ... TACCR0, 0, 1, 2, ... TACCR0, 0, ...
                    ↑ CCIFG0 set here
```

- Period = (TACCR0 + 1) timer clock cycles
- TACCTL0.CCIFG is set when TAR reaches TACCR0
- Most common mode for generating periodic events

### Mode 2 — Continuous Mode (`MC_2`)

TAR counts **0 → 0xFFFF**, then overflows to 0 and repeats.

```
TAR: 0, 1, 2, ... 0xFFFF, 0, 1, ...
                    ↑ TAIFG set here
```

- Useful for measuring elapsed time (just read TAR)
- TACCR1 and TACCR2 can be used for compare events mid-count

### Mode 3 — Up/Down Mode (`MC_3`)

TAR counts **0 → TACCR0 → 0 → TACCR0 → ...**

Useful for symmetric PWM.  We will not use this in the course.

---

## Timer Period Calculation

**Up mode with SMCLK and divider:**

```
Period = (TACCR0 + 1) / (SMCLK / divider)
```

Example: 500ms period with SMCLK = 1MHz, ID_3 (/8):
```
Timer clock = 1,000,000 / 8 = 125,000 Hz
Ticks for 500ms = 0.500 × 125,000 = 62,500
TACCR0 = 62,500 - 1 = 62,499
```

Example: 50ms period with SMCLK = 1MHz, ID_2 (/4):
```
Timer clock = 1,000,000 / 4 = 250,000 Hz
Ticks for 50ms = 0.050 × 250,000 = 12,500
TACCR0 = 12,500 - 1 = 12,499
```

---

## Starting Timer_A (Up Mode)

```asm
; Configure Timer_A: SMCLK/8, Up mode, count to 62499 (500ms period)
mov.w   #(TASSEL_2|ID_3|MC_1|TACLR), &TACTL   ; start timer
mov.w   #62499, &TACCR0                         ; period
```

The `TACLR` bit clears TAR on write (it self-clears immediately). Setting it
simultaneously with MC_1 ensures a clean start.

---

## Reading TAR

You can read the current timer value at any time:

```asm
mov.w   &TAR, R12   ; R12 = current timer count
```

This is useful in Continuous mode to measure elapsed time.

---

## Next

In Tutorial 02 you will learn how to **poll CCIFG** to wait for the timer to
complete a period — a reliable, CPU-burning but simple timing method before we
add interrupts in Lesson 11.
