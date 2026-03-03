# Lesson 06 · Watchdog Timer (WDT+)

## What You'll Learn

- What a watchdog timer is and why embedded systems need one
- How to use the WDT+ in **watchdog mode** (system reset on timeout)
- How to use the WDT+ in **interval timer mode** (periodic interrupt)
- How to service (pet) the watchdog in a main loop

## Why This Matters

Every real embedded project uses a watchdog.  If firmware hangs due to a bug,
the watchdog resets the CPU and restores operation automatically. The MSP430
WDT+ also doubles as a low-resolution periodic timer — useful when you don't
need Timer_A's precision.

## Goals

1. Stop the WDT safely on startup (you've been doing this since Lesson 01)
2. Configure WDT in interval mode to generate periodic interrupts
3. Configure WDT in watchdog mode and pet it in the main loop
4. Observe what happens when you stop petting the watchdog

## Tutorials

| File | Topic |
|------|-------|
| `tutorial-01-watchdog-mode.md` | Watchdog fundamentals, WDTPW, timeout reset |
| `tutorial-02-interval-mode.md` | Interval timer mode, ISR, IE1/IFG1 flags |

## Example

```
examples/
└── wdt_demo.s   ← WDT interval timer blinks LED via ISR; main in LPM0
```

## Exercises

| Exercise | Task |
|----------|------|
| ex1 | WDT watchdog mode — pet it in loop, observe reset when you stop |
| ex2 | WDT interval timer — generate a 1Hz LED toggle |
| ex3 | Heartbeat with WDT — must pet within 32ms or system resets |

## Capstone Connection

The capstone uses WDT interval mode as a **32ms system tick**. Lesson 06 gives
you that skill directly.
