# Tutorial 01 — Timer_A Basics

## The Problem with Software Delays

Your `delay_ms` subroutine works by burning CPU cycles in a loop:

```asm
delay_ms:
    mov.w   #333, R13
.inner:
    dec.w   R13
    jnz     .inner      ; spin ~999 cycles ≈ 1 ms at 1 MHz
    dec.w   R12
    jnz     delay_ms
    ret
```

This is fine for simple blink programs, but it has a serious limitation:
**the CPU is completely occupied while waiting.** It cannot read a button,
update a display, or do anything else. For a game loop that needs to read
inputs and update state on every tick, that's a problem.

Timer_A solves this by counting in hardware. The CPU sets the timer up, then
goes about other business — it only checks the timer when it wants to know
whether a period has elapsed.

---

## Timer_A Overview

The MSP430G2553 has one Timer_A with a 16-bit counter register `TAR` and
three capture/compare registers (`TACCR0`, `TACCR1`, `TACCR2`). For this
lesson we only need `TACCR0` and the control register `TACTL`.

```
TAR     — the 16-bit counter (reads as a running number 0…65535)
TACCR0  — the period register (in up mode, TAR counts up to this value)
TACTL   — the control register (clock source, mode, flags)
```

All three are memory-mapped, so you read and write them with `mov.w` and `bit.w`,
exactly like port registers, but 16-bit wide.

---

## TACTL — The Control Register

```
Bit:   15–10   9–8      7–6    5–4    3      2      1     0
Name:  unused  TASSEL   ID     MC    unused  TACLR  TAIE  TAIFG
```

**TASSEL (bits 9–8) — clock source:**

| Value | Constant | Meaning |
|-------|----------|---------|
| `00` | `TASSEL_0` | TACLK (external pin) |
| `01` | `TASSEL_1` | ACLK (32 kHz crystal if fitted) |
| `10` | `TASSEL_2` | SMCLK ← **use this** (= DCO = 1 MHz after calibration) |
| `11` | `TASSEL_3` | INCLK (inverted external) |

**ID (bits 7–6) — input divider:**

| Value | Constant | Effect |
|-------|----------|--------|
| `00` | `ID_0` | ÷1 — every clock tick advances TAR |
| `01` | `ID_1` | ÷2 |
| `10` | `ID_2` | ÷4 |
| `11` | `ID_3` | ÷8 |

At 1 MHz with `ID_0` (÷1), one TAR increment = 1 µs.

**MC (bits 5–4) — mode:**

| Value | Constant | Meaning |
|-------|----------|---------|
| `00` | `MC_0` | Stop — timer frozen |
| `01` | `MC_1` | Up — count 0 → TACCR0, reset, repeat ← **use this** |
| `10` | `MC_2` | Continuous — count 0 → 0xFFFF, overflow, repeat |
| `11` | `MC_3` | Up/down |

**Other bits:**

| Bit | Constant | Meaning |
|-----|----------|---------|
| 2 | `TACLR` | Write 1 to reset TAR to 0 immediately (self-clearing) |
| 1 | `TAIE` | Enable overflow interrupt (not used in this lesson) |
| 0 | `TAIFG` | **Overflow flag** — set when TAR resets from TACCR0 to 0 |

---

## Up Mode — How It Works

In up mode (`MC_1`), the timer counts like this:

```
TAR:   0 → 1 → 2 → … → TACCR0 → 0 → 1 → 2 → … → TACCR0 → 0 → …
                              ↑                            ↑
                         TAIFG set                   TAIFG set
```

At the moment TAR resets from `TACCR0` back to 0, hardware sets the `TAIFG`
bit in `TACTL`. The timer continues running — **TAIFG stays set until you
clear it**. If you wait too long, the next period fires and sets it again,
but the flag was already 1, so you can't tell you missed a tick.

**Rule: always clear TAIFG immediately after you detect it.**

---

## Period Formula

One up-mode period = `TACCR0 + 1` clock cycles.

At SMCLK = 1 MHz (1 cycle = 1 µs):

```
Period = (TACCR0 + 1) µs

TACCR0 = (period in µs) − 1
```

Common values:

| Period | TACCR0 |
|--------|--------|
| 1 ms | 999 |
| 5 ms | 4999 |
| 10 ms | 9999 |
| 50 ms | 49999 |

---

## Setup Sequence

**Always set `TACCR0` before writing `TACTL`.**
The timer starts the moment `MC` bits go non-zero. If `TACCR0` is still 0
when that happens, the timer fires immediately and keeps firing at 0 — not
what you want.

```asm
; Step 1: set the period
mov.w   #9999, &TACCR0                  ; 10 ms at 1 MHz

; Step 2: start the timer (SMCLK, up mode, clear TAR)
mov.w   #(TASSEL_2|MC_1|TACLR), &TACTL
```

After step 2, `TAR` begins counting from 0 toward 9999. When it reaches 9999
and resets, `TAIFG` in `TACTL` goes high.

---

## Polling TAIFG — Waiting for One Tick

```asm
wait_tick:
    bit.w   #TAIFG, &TACTL  ; is the overflow flag set?
    jz      wait_tick        ; no — keep checking
    bic.w   #TAIFG, &TACTL  ; yes — clear it and fall through
```

`bit.w` tests a 16-bit register, exactly like `bit.b` for byte registers.
It ANDs the operand with the register and sets the Zero flag if the result
is 0. After the `jz` falls through, TAIFG was 1 → one period has elapsed.

**You must clear TAIFG with `bic.w` after detecting it.** Failing to do so
means the flag stays set and the very next `bit.w` check will fire instantly —
your timing will collapse to zero.

---

## Replacing delay_ms with Timer_A

**Before (software delay):**
```asm
; 500 ms delay using software loop
mov.w   #500, R12
call    #delay_ms           ; CPU stuck here, can do nothing else
```

**After (Timer_A polling):**
```asm
; 500 ms using 10 ms tick × 50 counts
mov.w   #50, R6             ; 50 ticks × 10 ms = 500 ms
wait:
    bit.w   #TAIFG, &TACTL
    jz      wait
    bic.w   #TAIFG, &TACTL
    dec.w   R6
    jnz     wait
; 500 ms have elapsed — and the timer is still running for the next interval
```

The CPU is still "busy" in the polling loop, but notice: the timer is running
independently. In a future lesson (interrupts), you'll be able to put the CPU
to sleep instead of polling, and the timer will wake it up. The tick-counting
pattern you learn here transfers directly to that model.

---

## Key Things That Go Wrong

**Forgetting to clear TAIFG:**
After `bit.w #TAIFG, &TACTL` fires, the flag stays set. Your next poll
returns instantly regardless of how much time has passed. Always follow the
detection with `bic.w #TAIFG, &TACTL`.

**Setting TACTL before TACCR0:**
If TACCR0 = 0 when the timer starts, it fires on every single clock cycle.
Always write TACCR0 first.

**Reading TAR directly for timing:**
`TAR` is readable at any time and gives the current count. But comparing
`TAR` to a threshold is tricky because the compare might happen just after a
reset. Use the TAIFG flag instead — it is a clean, reliable event.

**Using `bit.b` instead of `bit.w` on TACTL:**
`TACTL` is a 16-bit register. `TAIFG` is bit 0, `TACLR` is bit 2, `TASSEL`
is bits 9–8. Using `bit.b` only sees the low byte and misses `TASSEL` etc.
Always use `.w` suffix for Timer_A registers.
