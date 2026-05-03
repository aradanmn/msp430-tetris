# Lesson 04 — Exercise 1 Grade

**Score: 9/10 — Pass**

## What worked
- `TICK_PERIOD` and `BLINK_TICKS` computed correctly as `.equ` constants
- `TACCR0` written before `TACTL` — correct order
- Timer configured: `TASSEL_2|MC_1|TACLR`
- Poll TAIFG with `bit.w`, clear with `bic.w` — correct 16-bit ops
- Decrement / jnz / toggle / reload loop — correct structure
- No `delay_ms`, no `call` in main loop

## Issues
- Leftover `; TODO:` comments on the constant definitions in the submitted file (-1)
