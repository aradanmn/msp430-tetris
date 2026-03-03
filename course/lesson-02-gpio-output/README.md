# Lesson 02 — GPIO Output: Controlling LEDs

## Learning Objectives
- Configure GPIO pins as outputs using P1DIR
- Set, clear, and toggle output pins using BIS.B, BIC.B, XOR.B
- Write a software delay loop calibrated to ~1MHz DCO
- Create multi-LED patterns using bit manipulation

## Topics
| Tutorial | Content |
|----------|---------|
| tutorial-01-gpio-registers.md | P1DIR, P1OUT, P1IN, bit manipulation |
| tutorial-02-software-delays.md | Delay loops, timing approximations |

## How This Fits the Capstone
The LED status indicators (LED1=alive blink, LED2=alarm) in the Smart
Environment Monitor use exactly the GPIO output techniques from this lesson.

## Steps
1. Read both tutorials
2. Build and flash: `cd examples && make && make flash`
3. Watch the LEDs on your LaunchPad blink
4. Complete exercises — start with ex1 (simplest)
