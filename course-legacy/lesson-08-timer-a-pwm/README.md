# Lesson 08 · Timer_A PWM

## What You'll Learn

- How hardware PWM works (duty cycle, period, OUTMOD)
- How to route Timer_A output to a physical pin (P1.6 = TA0.2)
- How to change duty cycle at runtime to dim an LED or control a servo
- The difference between OUTMOD_7 (Reset/Set) and other output modes

## Why This Matters

PWM is used everywhere: LED dimming, motor speed control, servo positioning,
audio generation, and DC-DC converters.  Hardware PWM generates a clean signal
without any CPU involvement — the CPU is free to do other work while the timer
outputs the waveform.

## Goals

1. Configure P1.6 as TA0.2 output (hardware PWM)
2. Set a 1kHz PWM frequency with variable duty cycle
3. Smoothly ramp duty cycle to create a breathing LED effect
4. Understand OUTMOD_7 (Reset/Set) waveform generation

## Tutorials

| File | Topic |
|------|-------|
| `tutorial-01-pwm-theory.md` | PWM basics, TACCR0/TACCR2 relationship, OUTMOD |
| `tutorial-02-pwm-setup.md` | Pin muxing, hardware PWM configuration code |

## Example

```
examples/
└── pwm_demo.s   ← Breathing LED on P1.6 — smooth ramp via TACCR2
```

## Exercises

| Exercise | Task |
|----------|------|
| ex1 | Fixed 25% duty cycle on LED2 (P1.6) |
| ex2 | Button-controlled brightness: press S2 to step through 5 levels |
| ex3 | Generate a ~1kHz tone on P2.6 using 50% duty cycle PWM |

## Capstone Connection

The capstone uses PWM on P1.6 for an alarm LED brightness indicator.
