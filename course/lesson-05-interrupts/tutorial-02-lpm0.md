# Tutorial 02 — Low Power Mode 0 (LPM0)

## Why Sleep?

A polling loop burns power constantly. At 1 MHz active mode, the MSP430G2553
draws around 270 µA. On a small LiPo battery (say 200 mAh), that's under
a month of continuous runtime — and that's before the display and other
peripherals are added.

A game doesn't need the CPU running 1,000,000 times per second. It needs
it running ~60 times per second (once per frame). LPM0 lets the CPU sleep
between ticks, waking only when there is work to do.

---

## LPM0 — What It Does

LPM0 turns off the **CPU clock** while leaving everything else running:

| What | LPM0 |
|------|------|
| CPU | **off** |
| SMCLK (Timer_A, UART, SPI) | running |
| ACLK | running |
| RAM contents | preserved |
| Register contents | preserved |
| Interrupt response | immediate |

Current consumption in LPM0 at 1 MHz: ~60 µA — about 4× lower than active.
The display and radio draw far more than the CPU, but every µA matters on
battery.

---

## Entering LPM0

LPM0 is controlled by two bits in the **status register (SR)**:

| Bit | Name | Effect when set |
|-----|------|----------------|
| 4 | `CPUOFF` | CPU clock disabled |
| 3 | `GIE` | Global interrupt enable |

You set both simultaneously:

```asm
bis.w   #(GIE|CPUOFF), SR      ; enter LPM0, enable interrupts
```

After this instruction the CPU stops. Execution does not continue to the
next line until an interrupt wakes it.

**Always set GIE at the same time as CPUOFF.** If you set CPUOFF first
without GIE, the CPU sleeps and can never wake up — no interrupts are
accepted.

---

## What Happens on an Interrupt

When Timer_A fires its CC0 interrupt:

1. Hardware wakes the CPU
2. Current SR (with CPUOFF and GIE bits) is pushed onto the stack
3. GIE is cleared in SR (interrupts temporarily disabled)
4. CPU jumps to `timer_isr`
5. ISR runs
6. `reti` pops the saved SR — CPUOFF and GIE are restored
7. CPU sees CPUOFF is set again → goes back to sleep

The CPU wakes, does exactly the work the ISR specifies, then goes back to
sleep automatically. No explicit re-entry to LPM0 needed.

---

## The Program Structure

With polling:

```asm
_start:
    ; ... setup ...
    ; ... load registers ...
main_loop:
    bit.w   #TAIFG, &TACTL   ; spin waiting for tick
    jz      main_loop
    bic.w   #TAIFG, &TACTL
    ; ... do work ...
    jmp     main_loop
```

With interrupts + LPM0:

```asm
_start:
    ; ... setup ...
    ; ... load registers ...
    bis.w   #(GIE|CPUOFF), SR   ; sleep — ISR handles everything
    ; execution never reaches here (unless ISR wakes CPU permanently)

timer_isr:
    ; ... do work ...
    reti                         ; go back to sleep automatically
```

The main body becomes nearly empty. All logic moves into the ISR.

---

## Waking the CPU Permanently

Sometimes the ISR needs to signal the main program (not just run and sleep
again) — for example when a complete frame has been built and needs to be
sent to the display.

From inside the ISR, clear CPUOFF **in the saved SR on the stack**:

```asm
timer_isr:
    ; ... do work ...
    bic.w   #CPUOFF, 0(SP)      ; clear CPUOFF in the stacked SR
    reti                         ; reti restores the modified SR → CPU stays awake
```

`0(SP)` is the top of stack — where the saved SR lives during ISR execution.
After `reti`, SR is restored with CPUOFF=0, so the CPU continues executing
after the `bis.w #(GIE|CPUOFF), SR` line in `_start`.

You won't need this until the display lessons. For now, every ISR just does
its work and returns to sleep.

---

## Common Mistakes

**Forgetting to set GIE with CPUOFF:**
```asm
bis.w   #CPUOFF, SR     ; ← CPUOFF without GIE — sleeps forever, no wakeup
```
Always use `#(GIE|CPUOFF)`.

**Initializing registers after `bis.w #(GIE|CPUOFF), SR`:**
Code after the sleep entry never runs until woken. Put all initialization
before the sleep entry.

**Using `bic.w #TAIFG, &TACTL` inside the ISR:**
With CC0 interrupts (CCIE), the CCIFG flag in TACCTL0 — not TAIFG in TACTL —
is what the hardware clears automatically on ISR entry. You do not need to
manually clear any flag in the CC0 ISR.
