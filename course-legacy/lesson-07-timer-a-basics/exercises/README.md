# Lesson 07 Exercises — Timer_A Basics

---

## Exercise 1 · Exact 1-Second Delay with Timer_A

**File:** `ex1/ex1.s`

Use Timer_A in **Up mode** to generate an exact 1-second delay. Toggle LED1
every second.  No software delay loops allowed — timing must come entirely from
the timer.

**Setup:**
- SMCLK = 1MHz (calibrated DCO)
- Timer divider: ID_3 (/8) → 125kHz timer clock
- TACCR0: choose a value for 500ms period
- Count 2 periods per LED toggle → 1-second period

**Expected TACCR0:** `62499`  (500ms at 125kHz: 62500 ticks − 1)

---

## Exercise 2 · Dual-Rate Blink from One Timer

**File:** `ex2/ex2.s`

Using **one Timer_A** in Up mode with a 250ms period, blink:
- LED1 every **500ms** (toggle every 2 timer periods)
- LED2 every **250ms** (toggle every 1 timer period)

**Strategy:**
- TACCR0 = period for 250ms
- In main loop, use a counter to divide by 2 for LED1

**Key calculation (SMCLK=1MHz, ID_3=/8, 125kHz):**
```
250ms = 31250 ticks → TACCR0 = 31249
```

---

## Exercise 3 · Measure Button Hold Time

**File:** `ex3/ex3.s`

Use Timer_A in **Continuous mode** (MC_2) to measure how long the user holds
button S2.

Algorithm:
1. Wait for button press (falling edge on P1.3, active-low)
2. Record TAR value at press time
3. Wait for button release
4. Record TAR at release time
5. Compute elapsed ticks, convert to approximate milliseconds
6. Blink LED1 once per 100ms of measured hold time

**Useful:**
- At SMCLK=1MHz with ID_3 (/8), 1 tick = 8µs
- Elapsed ms ≈ (end_TAR − start_TAR) × 8 / 1000
- Use simple integer division (shift right by 7 ≈ divide by 128 ≈ close enough)

**Note:** TAR is 16-bit (max 65535 ticks = ~524ms at 125kHz).  For longer
measurements you'd need to count overflows.  Assume hold ≤ 500ms.
