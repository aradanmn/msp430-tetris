# Lesson 05 Exercises — Clock System

These exercises deepen your understanding of the MSP430 clock system by making
timing precise and measurable via LED blink rates.

---

## Exercise 1 · Accurate 2Hz Blink at 1MHz

**File:** `ex1/ex1.s`

Using the factory-calibrated 1MHz DCO and a software delay loop, blink LED1 at
exactly 2Hz (on 250ms, off 250ms).

**Why this is non-trivial:** A naive `dec / jnz` loop has an overhead you must
account for.  Tune your inner-loop count so the LED period is as close to 500ms
total (250ms on + 250ms off) as you can get.

**Hints:**
- Set 1MHz: `clr.b &DCOCTL` / `mov.b &CALBC1_1MHZ, &BCSCTL1` / `mov.b
  &CALDCO_1MHZ, &DCOCTL`
- Each `dec.w` + `jnz` pair ≈ 2 cycles at 1MHz → 2µs per iteration
- 250ms = 250,000µs ÷ 2µs per iter ≈ **125,000 inner iterations**
- You'll need nested loops (a single 16-bit register maxes at 65535)

---

## Exercise 2 · MCLK Divide-by-8 Demo

**File:** `ex2/ex2.s`

Configure BCSCTL2 to divide MCLK by 8 (DIVM_3), keeping the DCO at 1MHz.  Then
run your delay loop from Exercise 1 *unchanged* and observe the blink rate.  It
should be approximately **8× slower** (≈ 0.25Hz).

This demonstrates that delay loops are clock-speed dependent.

**Key register:**
```asm
mov.b   #DIVM_3, &BCSCTL2   ; MCLK = DCO / 8 = 125kHz
```

After the slow blink, restore `BCSCTL2 = 0` (DIVM_0) and show the normal fast
blink again, so you can see the contrast.

---

## Exercise 3 · Two-Speed Blink Using SMCLK Divider

**File:** `ex3/ex3.s`

Run the DCO at 1MHz.  Blink LED1 using a delay loop that times off **SMCLK at
full speed** (fast), then switch SMCLK to ÷8 (DIVS_3 in BCSCTL2) and blink LED2
with the **same delay constant** (slow). Repeat in a loop: fast LED1, then slow
LED2, alternating.

This shows that MCLK (CPU speed) and SMCLK (peripheral clock) can be
independently divided.

**Key register bits (BCSCTL2):**
- `DIVS_0 = 0x00` — SMCLK = DCO / 1
- `DIVS_3 = 0x06` — SMCLK = DCO / 8

Note: a pure software delay loop runs off MCLK, not SMCLK — so changing SMCLK
alone will NOT slow the loop.  For this exercise you must change **DIVM** (MCLK
divider) to see a timing difference, but *name* the register DIVS in your
comments to demonstrate you understand which clock you're changing.
Alternatively, use Timer_A clocked by SMCLK (covered in Lesson 07) for a truly
SMCLK-dependent delay.

**Suggested approach:** change DIVM_3 to slow MCLK, loop on LED2, then DIVM_0 to
restore MCLK, loop on LED1.
