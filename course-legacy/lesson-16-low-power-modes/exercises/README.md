# Lesson 16 Exercises — Low Power Modes

These exercises progress from LPM0 through the deepest LPM4 sleep. Aim: measure
actual current with a multimeter if possible, or observe LED behavior to confirm
the wake pattern is correct.

---

## Exercise 1 · LPM3 + WDT Interval 1Hz Blink

**File:** `ex1/ex1.s`

Implement the ultra-low-power 1Hz LED blink:

1. Configure ACLK from VLO (`BCSCTL3 = LFXT1S_2`).
2. Start WDT in interval mode, ACLK source, period ≈ 1 second. - `WDTPW |
   WDTTMSEL | WDTSSEL | WDTCNTCL` with no WDTIS bits = /32768 - VLO ≈ 12 kHz →
   period ≈ 2.7 s (fine for this exercise) - Or use WDTIS1 for /8192 → ≈ 0.68 s
3. Enable WDTIE in IE1, set GIE.
4. Main loop: `bis.w #(GIE|CPUOFF|SCG0|SCG1), SR` → LPM3.
5. WDT ISR: toggle LED1, exit LPM3 (`bic.w #(CPUOFF|SCG0|SCG1), 0(SP)`).

**Challenge:** Count 4 WDT ticks in the ISR before toggling LED1, to produce a
1:3 duty cycle (on for 0.68s, off for 2.04s).

---

## Exercise 2 · LPM4 + Button Wakeup

**File:** `ex2/ex2.s`

Implement the deepest possible sleep with GPIO wakeup:

1. Set LED1 off, no clocks needed.
2. Configure button (P1.3): input, pull-up, falling-edge interrupt.
3. Enter LPM4: `bis.w #(GIE|CPUOFF|SCG0|SCG1|OSCOFF), SR`.
4. PORT1_ISR: - Toggle LED1. - Clear P1IFG. - Exit LPM4 (`bic.w
   #(CPUOFF|SCG0|SCG1|OSCOFF), 0(SP)`).
5. Main wakes, does a 100ms blink (needs a software delay that works **without
   any clock running first** — you must restart DCO in main before the delay, or
   use a long cycle-count loop calibrated to VLO).

**Key insight:** In LPM4, OSCOFF=1 turns off LFXT1 and VLO.  When the ISR exits
LPM4, the DCO needs a moment to stabilize.  Wait a few hundred cycles after
waking before timing-sensitive operations.

---

## Exercise 3 · LPM0 + Timer_A Tick Scheduler

**File:** `ex3/ex3.s`

Port the Lesson 11 timer ISR tick-scheduler to use LPM0 between ticks:

1. Timer_A CC0 at 1ms (SMCLK/1, TACCR0=999), ISR increments `ms_tick`.
2. ISR wakes main from LPM0 on every tick.
3. Main checks elapsed time against two tasks: - Task A every 250 ms: toggle
   LED1 - Task B every 1000 ms: toggle LED2
4. Main returns to LPM0 after checking.

**Measure:** With an oscilloscope or logic analyzer, verify the LED periods are
accurate (250ms ± 1ms and 1000ms ± 1ms).

**LPM0 wake on every 1ms tick trades energy for responsiveness.  For a 1Hz blink
this is inefficient — compare this power vs LPM3+WDT.**
