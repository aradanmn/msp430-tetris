# Tutorial 08-1 · PWM Theory

## What Is PWM?

**Pulse Width Modulation** is a technique to simulate an analog output level
using a digital signal.  The signal switches between HIGH and LOW at a fixed
frequency; the **duty cycle** (percentage of time HIGH) determines the effective
average voltage.

```
100% duty:  ████████████████  (always HIGH = 3.3V)
 75% duty:  ████████████░░░░  (3.3V × 0.75 = 2.475V average)
 50% duty:  ████████░░░░░░░░  (3.3V × 0.50 = 1.65V average)
 25% duty:  ████░░░░░░░░░░░░  (3.3V × 0.25 = 0.825V average)
  0% duty:  ░░░░░░░░░░░░░░░░  (always LOW = 0V)
```

An LED connected to a 50% PWM signal appears half as bright as at 100% — your
eye integrates the average light over time.

---

## Timer_A PWM Generation

Timer_A generates PWM using two compare registers:

- **TACCR0** — sets the **period** (TOP value in Up mode)
- **TACCR1** or **TACCR2** — sets the **duty cycle threshold**

With `OUTMOD_7` (Reset/Set):

```
TAR counts 0 → TACCR0 continuously

         TACCR2          TACCR0
TAR:  0 ───────────────────────────── 0 ───...
             ↑                   ↑
         Output RESETS        Output SETS
         (goes LOW)           (goes HIGH)
```

This produces:

```
Output: ████████████░░░░████████████░░░░...
        |← HIGH →|←LOW→|← HIGH →|←LOW→|
        0       TACCR2  TACCR0         TACCR0
```

**Duty cycle** = TACCR2 / (TACCR0 + 1)

---

## Choosing Period and Frequency

```
PWM frequency = Timer_clock / (TACCR0 + 1)
```

For a **1kHz** PWM signal with SMCLK = 1MHz:
```
TACCR0 = 1,000,000 / 1,000 - 1 = 999
```
No divider needed (ID_0).

For **50% duty cycle** at 1kHz:
```
TACCR2 = TACCR0 / 2 = 499
```

For **25% duty cycle**:
```
TACCR2 = TACCR0 / 4 = 249
```

---

## OUTMOD_7 — Reset/Set

This is the standard PWM output mode:

| Event | Action |
|-------|--------|
| TAR = TACCR2 | Output goes LOW (reset) |
| TAR = TACCR0 | Output goes HIGH (set) |
| TAR resets to 0 | Timer restarts, output stays HIGH |

With TACCR2 = 0: output is always HIGH (100% duty cycle) With TACCR2 = TACCR0:
output is always LOW (0% duty cycle) With TACCR2 > TACCR0: output is always HIGH
(treat as 100%)

---

## Other OUTMOD Values

| OUTMOD | Name | Description |
|--------|------|-------------|
| 0 | Output | Output = OUT bit in TACCTL |
| 1 | Set | Output set at CCR; stays set |
| 5 | Reset | Output reset at CCR; stays reset |
| 6 | Toggle/Set | Toggles at CCR2, sets at CCR0 |
| 7 | Reset/Set | **Standard PWM** (most common) |

---

## Key Takeaway

```
TACCR0 → controls frequency/period
TACCR2 → controls duty cycle
OUTMOD_7 in TACCTL2 → enables hardware PWM output
```

Change TACCR2 at any time to change duty cycle — the timer keeps running
uninterrupted.

---

## Next

Tutorial 02 shows how to connect the Timer_A output to the physical pin P1.6 and
the complete register setup.
