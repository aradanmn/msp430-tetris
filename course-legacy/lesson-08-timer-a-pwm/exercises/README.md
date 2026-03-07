# Lesson 08 Exercises — Timer_A PWM

---

## Exercise 1 · Fixed 25% Duty Cycle

**File:** `ex1/ex1.s`

Configure hardware PWM on P1.6 (LED2) at:
- **Frequency:** 500Hz (2ms period)
- **Duty cycle:** 25%

LED2 should appear dimly lit (25% brightness).  LED1 should blink at 1Hz using a
software delay loop to show the CPU is free while PWM runs.

**Key values (SMCLK=1MHz, no divider):**
```
TACCR0 = 1999   (2ms period at 1MHz)
TACCR2 = 499    (25% of 2000 = 500 → 499)
```

---

## Exercise 2 · Button-Controlled Brightness

**File:** `ex2/ex2.s`

Each press of button S2 steps LED2 brightness through 5 levels: 0%, 25%, 50%,
75%, 100%, then back to 0%.

**Strategy:**
1. Keep a step counter in R4 (0–4)
2. On each button press (debounced), increment step, wrap at 5
3. Compute duty cycle: `TACCR2 = step × (TACCR0 / 4)` (each step = 25%)
4. Write new TACCR2 while timer runs

**Brightness table:**

| Step | TACCR2 | Duty |
|------|--------|------|
| 0 | 0 | 0% |
| 1 | 249 | 25% |
| 2 | 499 | 50% |
| 3 | 749 | 75% |
| 4 | 999 | 100% |

*(Using TACCR0 = 999 for 1kHz)*

---

## Exercise 3 · 1kHz Audio Tone on P2.6

**File:** `ex3/ex3.s`

Generate a 1kHz square wave (50% duty cycle) on **P2.6** (an available GPIO pin
on the LaunchPad header) to drive a small piezo buzzer.

- Use **TACCR1** (not TACCR2) with P1.6 already taken? Actually, use TACCR2 →
  P1.6 for the buzzer (disconnect LED2 or just use the pin without the LED).

The tone should play for 1 second, then pause 1 second, repeating.

**To start/stop the tone:**
- Start: write `OUTMOD_7` to TACCTL2 and set TACCR2=499
- Stop: write `0` to TACCTL2 (disables output mode, pin goes to OUT bit level)

**Expected sound:** A steady 1kHz beep alternating with silence. You'll need a
piezo buzzer connected between P1.6 and GND.
