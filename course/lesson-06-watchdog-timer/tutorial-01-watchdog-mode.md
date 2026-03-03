# Tutorial 06-1 · Watchdog Mode

## What Is a Watchdog Timer?

A watchdog timer is a hardware counter that runs independently of the CPU.  If
the counter reaches its maximum before the firmware resets it, the watchdog
**resets the entire MCU**.

Think of it like a dead-man's switch:

- Firmware is running correctly → pets (resets) the watchdog regularly
- Firmware hangs in an infinite loop or crashes → stops petting → **watchdog
  fires → system restarts**

This turns a frozen system into a self-healing one.

---

## MSP430 WDT+ in Watchdog Mode

On reset, the WDT+ starts in **watchdog mode** counting from SMCLK. This is why
**every program must stop or configure the WDT in the first instruction**:

```asm
mov.w   #(WDTPW|WDTHOLD), &WDTCTL   ; stop watchdog
```

If you forget this, the WDT fires after ~32ms and resets the CPU continuously —
your program never runs.

---

## WDTCTL Register

`WDTCTL` is a 16-bit register at `0x0120`.  The **upper byte must always be
written with the password `0x5A`** (`WDTPW`).  Writing without the password is
ignored.

| Bit | Name | Function |
|-----|------|----------|
| 15:8 | WDTPW | Password: always write `0x5A` |
| 7 | WDTHOLD | 1 = stop counter, 0 = running |
| 6 | WDTNMIES | NMI edge select |
| 5 | WDTNMI | RST/NMI pin function |
| 4 | WDTTMSEL | **0 = watchdog, 1 = interval timer** |
| 3 | WDTCNTCL | 1 = clear counter |
| 2 | WDTSSEL | **0 = SMCLK, 1 = ACLK** |
| 1:0 | WDTIS[1:0] | Timeout interval (see table below) |

### Timeout Intervals (SMCLK @ 1MHz)

| WDTIS | Divisor | Time at 1MHz |
|-------|---------|-------------|
| 00 | /32768 | ~32ms |
| 01 | /8192 | ~8ms |
| 10 | /512 | ~0.5ms |
| 11 | /64 | ~64µs |

---

## Starting the WDT in Watchdog Mode

```asm
; Release WDT from hold and let it count in watchdog mode (WDTTMSEL=0)
; Timeout = SMCLK/32768 ≈ 32ms at 1MHz
mov.w   #(WDTPW|WDTCNTCL), &WDTCTL
```

This clears the counter and lets it run.  You must reset it within 32ms or the
CPU resets.

---

## Petting (Servicing) the Watchdog

To pet the watchdog, clear the counter with WDTCNTCL **without changing other
bits**:

```asm
; Pet the watchdog — must keep WDTPW in upper byte
mov.w   #(WDTPW|WDTCNTCL), &WDTCTL
```

Do this in your main loop, before the 32ms deadline.

---

## Complete Watchdog Example

```asm
main:
        ; Configure WDT: watchdog mode, 32ms timeout, start counting
        mov.w   #(WDTPW|WDTCNTCL), &WDTCTL

        ; Set up 1MHz DCO
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ, &BCSCTL1
        mov.b   &CALDCO_1MHZ, &DCOCTL

        bis.b   #LED1, &P1DIR

loop:
        xor.b   #LED1, &P1OUT          ; toggle LED
        mov.w   #(WDTPW|WDTCNTCL), &WDTCTL  ; PET the watchdog

        ; Short delay (must be < 32ms to not trigger watchdog)
        mov.w   #5, R12
        call    #delay_ms

        jmp     loop
```

If you comment out the `WDTCNTCL` line in the loop, the LED stops toggling and
after 32ms the system resets and starts over.

---

## What a Reset Looks Like

When the WDT fires, execution jumps to the Reset vector (0xFFFE). On the
LaunchPad, the LED freezes momentarily then restarts — visible as a brief pause
or restart of the pattern.

---

## Next

In Tutorial 02 you will switch the WDT to **interval timer mode**, where it
generates a periodic interrupt instead of resetting the CPU.  This is more
useful for timing tasks that don't need Timer_A's precision.
