# Lesson 05 — Interrupts and Low Power Mode 0

## What You'll Learn

- How interrupts work on the MSP430 (vector table, ISR entry, `reti`)
- Enabling the Timer_A CC0 interrupt with `CCIE`
- Entering LPM0 so the CPU sleeps between ticks
- Why interrupt-driven code is the foundation of the game loop

## How This Connects to the Handheld

Every lesson so far has been heading somewhere concrete:

| Lesson | Skill | Game use |
|--------|-------|----------|
| 01–02 | GPIO output | Drive the display and LEDs |
| 03 | GPIO input | Read the buttons |
| 04 | Timer_A polling | Consistent tick rate |
| **05** | **Timer_A ISR + LPM0** | **Game loop: wake on tick, process, sleep** |
| 06 | SPI | Send frames to the OLED |
| 07 | PWM | Buzzer sound effects |
| 08+ | Combine everything | Tetris |

The game loop for Tetris looks like this at a high level:

```
sleep (LPM0)
    ← timer fires every 16 ms (≈ 60 fps tick)
ISR wakes CPU:
    read buttons
    update game state (move piece, check lines)
    send frame to display over SPI
    go back to sleep
```

After this lesson you can write that skeleton. The display and game logic fill in later.

## Read First

1. `tutorial-01-interrupts.md` — how interrupts work, ISR anatomy
2. `tutorial-02-lpm0.md` — CPU sleep, wake on interrupt, power budget

## Then

```sh
cd examples && make flash
```

Observe LED1 blinking at 2 Hz with the CPU asleep between ticks.

## Exercises

See `exercises/README.md`.
