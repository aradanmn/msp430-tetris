# Lesson 05 — Clock System

## Learning Objectives
- Understand DCO, MCLK, SMCLK, and ACLK clock sources
- Configure the DCO to a precise frequency using TI calibration constants
- Explain why software delay timing depends on clock speed
- Use ACLK with the internal VLO oscillator

## Topics
| Tutorial | Content |
|----------|---------|
| tutorial-01-clock-sources.md | DCO, ACLK, SMCLK, MCLK, calibration |
| tutorial-02-configuring-dco.md | Step-by-step DCO configuration |

## How This Fits the Capstone
All timing in the capstone (UART baud rate, Timer_A period, ADC sample timing)
depends on having an accurate, known clock frequency. The capstone sets DCO to
1MHz using calibration constants from this lesson.

## Steps
1. Read tutorials
2. Build and flash the clock_demo example — observe LED blink rates
3. Try changing the clock speed and see how delays change
4. Complete exercises
