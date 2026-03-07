# Lesson 06 Exercises — Watchdog Timer

---

## Exercise 1 · Watchdog Mode — Pet It or Die

**File:** `ex1/ex1.s`

Configure the WDT in **watchdog mode** (not interval mode).  In the main loop,
pet the watchdog every ~10ms.  Use LED1 to show the loop is running (toggle on
each iteration).

Then **simulate a fault**: add a button check — if S2 is pressed, stop petting
the watchdog.  Observe that the system resets after ~32ms (LED pattern restarts
from the beginning).

**Expected behavior:**
- Button not pressed: LED1 toggles steadily (system running)
- Button held: LED1 freezes, then restarts after ~32ms reset

**Key code:**
```asm
; Start watchdog (watchdog mode, 32ms timeout)
mov.w   #(WDTPW|WDTCNTCL), &WDTCTL

; In loop — pet it:
mov.w   #(WDTPW|WDTCNTCL), &WDTCTL
```

---

## Exercise 2 · WDT Interval Timer — 1Hz LED Toggle

**File:** `ex2/ex2.s`

Use the WDT in **interval mode** at 32ms to generate a 1Hz LED toggle.

Requirements:
- Use an ISR for the WDT interrupt (do NOT poll)
- Count 31 ticks in the ISR, toggle LED1 on every 31st tick (~992ms)
- Main should enter **LPM0** (CPU off) between interrupts

This is the pattern used in the capstone project.

---

## Exercise 3 · Heartbeat Watchdog

**File:** `ex3/ex3.s`

Implement a **heartbeat pattern** using WDT in watchdog mode with a slower
timeout.  Use `WDTSSEL=1` to clock from **ACLK** (the VLO at ~12kHz) instead of
SMCLK.  With ACLK/32768 ≈ **2.7 seconds** timeout you have more time between
pets.

In the main loop:
1. Blink LED1 five times quickly
2. Pet the watchdog
3. Short delay (~500ms)
4. Repeat

The visible heartbeat (five quick blinks) confirms the system is alive. If it
ever hangs, the watchdog resets and the five-blink pattern restarts — clear
evidence of a reset.

**Hint for ACLK/VLO clock source:**
```asm
; Use ACLK (from VLO) for WDT clock
mov.w   #(WDTPW|WDTCNTCL|WDTSSEL), &WDTCTL
; WDTSSEL=1 selects ACLK; VLO ≈ 12kHz → timeout ≈ 2.7s
```
