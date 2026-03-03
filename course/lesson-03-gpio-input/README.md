# Lesson 03 — GPIO Input: Reading Buttons

## Learning Objectives
- Configure GPIO pins as inputs with internal pull-up resistors
- Read P1IN to detect button presses
- Debounce mechanical buttons in software
- Build a button-controlled LED toggle

## Topics
| Tutorial | Content |
|----------|---------|
| tutorial-01-reading-buttons.md | P1DIR, P1REN, P1OUT (pull), P1IN, active-low buttons |
| tutorial-02-polling-vs-interrupts.md | Polling loop, debounce, preview of interrupts |

## How This Fits the Capstone
The button input (P1.3) in the Smart Environment Monitor arms and disarms the
temperature alarm — the same GPIO input technique from this lesson (Lesson 10
upgrades it to interrupt-driven).

## Steps
1. Read tutorials
2. Build and flash example: `cd examples && make && make flash`
3. Press the S2 button — LED1 should toggle
4. Complete exercises
