# Lesson 09 Exercises — Interrupt Concepts

---

## Exercise 1 · Your First ISR — WDT Interval Toggle

**File:** `ex1/ex1.s`

Write the simplest possible interrupt-driven program:

1. Configure WDT in interval mode (~32ms)
2. Enable the WDT interrupt (IE1 bit 0)
3. Enable global interrupts (GIE)
4. Loop: `BIS.W #(GIE|CPUOFF), SR` to sleep
5. Write a `WDT_ISR` that toggles LED1

Expected: LED1 flickers at 32ms rate (appears dim/on).

**You must:**
- Use `RETI` (not `RET`) in the ISR
- Save any registers you use in the ISR
- Place the ISR address at vector `0xFFF6`

---

## Exercise 2 · Sleeping Main with Flag Signaling

**File:** `ex2/ex2.s`

Extend Exercise 1:

1. WDT ISR sets a `flag` variable (in `.data`) to 1 on every 31st tick
2. Main loop: sleep in LPM0, wake after each ISR, check flag
3. If flag is set: clear it, toggle LED1, go back to sleep
4. If flag not set: immediately go back to sleep

This is the **flag-and-main-loop** pattern used in all real projects. Main does
the work; ISR only signals that work is needed.

**Key difference from Ex1:** In Ex1 the ISR toggles the LED directly. Here, the
ISR only sets a flag — main does the LED toggle.

---

## Exercise 3 · Two ISRs Running Together

**File:** `ex3/ex3.s`

Run two interrupts simultaneously:

- **WDT ISR** (~32ms): count to 31, toggle LED1 (~1Hz)
- **Timer_A CC0 ISR** (125ms): toggle LED2 (4Hz)

Main sleeps in LPM0.

**Timer_A setup for 125ms (SMCLK=1MHz, /8=125kHz):**
```
TACCR0 = 15624   (125ms × 125kHz = 15625 ticks)
TACCTL0 = CCIE   (enable CC0 interrupt)
TACTL = TASSEL_2 | ID_3 | MC_1 | TACLR
```

**Vector addresses:**
- Timer_A CC0: `0xFFF4`
- WDT interval: `0xFFF6`
- Reset: `0xFFFE`
