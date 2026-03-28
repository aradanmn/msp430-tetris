# Exercise 2 — Timing by Counting: Grade Report

**Grade: B+**

## Functionality (Pass/Fail): PASS

LED1 blinks and the pattern is recognizable as a ~2 Hz blink. The timing is off (see below), but the fundamental behavior works.

## Concept Understanding

The overall structure is correct — you understood:
- `xor.b` toggles the LED (good)
- A nested loop is needed: outer loop counts milliseconds, inner loop burns ~1000 cycles
- 333 iterations of a 3-cycle loop = 999 cycles ~ 1 ms (correct math)
- R12 for the ms count, R11 for the inner count

Good instinct placing the toggle *before* the delay — the steady-state behavior is identical either way, so this is fine.

## Issues Found

### 1. Redundant `cmp.w #0` instructions (both loops)

`dec.w` already sets the Zero flag in the Status Register. You can branch directly with `jnz` after `dec.w` — no `cmp` needed. This is a key MSP430 concept: **most ALU instructions update the status flags automatically.**

Your inner loop:
```asm
.Lburn_cycles:
    dec.w   R11
    cmp.w   #0, R11       ; <-- redundant, dec.w already set Z flag
    jnz .Lburn_cycles
```

Should be:
```asm
.Lburn_cycles:
    dec.w   R11
    jnz     .Lburn_cycles
```

Same issue in the outer loop with `cmp.w #0, R12`.

Each redundant `cmp` adds 1 cycle per iteration. In the inner loop that's 333 extra cycles per ms — your "3-cycle loop" is actually 4 cycles, making each ms take ~1.33 ms instead of ~1 ms.

### 2. Unnecessary `call` / `ret` for inner loop

Using `call #.Lburn_cycles` to enter the inner loop adds 8 cycles of overhead per millisecond (call = 5 cycles, ret = 3 cycles) and pushes/pops the return address on the stack unnecessarily. The inner loop can live directly inside `delay_ms` as a nested loop — no subroutine call needed.

The example's approach is cleaner:
```asm
delay_ms:
    mov.w   #333, R13
.Linner:
    dec.w   R13
    jnz     .Linner        ; burn 999 cycles
    dec.w   R12
    jnz     delay_ms       ; next ms
    ret
```

Flat, no extra call/ret, no stack overhead.

### 3. Timing Impact

Because of issues 1 and 2, each "millisecond" actually takes ~1.34 ms:
- Inner: 333 iterations x 4 cycles (dec + cmp + jnz + one extra) = 1332 cycles
- Overhead: call (5) + ret (3) + dec R12 (1) + cmp (1) + jnz (2) = 12 cycles
- Total per ms: ~1344 cycles = ~1.34 ms

So your 250 "ms" delay is actually ~335 ms. Full blink period ~670 ms = ~1.5 Hz instead of 2 Hz. That's ~25% off target (the spec allowed 20%). Close, but the root cause is the extra instructions inflating your cycle count.

## Code Quality

- Good use of local label prefix (`.Lburn_cycles`)
- Main loop structure is clean and readable
- LED setup (direction + start OFF) is correct
- The comment `; 1MHz is 1,000,000 uS. 999 is ~ 1 mS.` shows you did the math, though the comment says 999 while the code uses 333 — the 333 is the correct loop count (333 x 3 = 999 cycles)

## Key Takeaway

**`dec.w` sets the flags.** This is true for nearly all MSP430 arithmetic/logic instructions (`add`, `sub`, `and`, `xor`, `bit`, etc.). Lean on this — it's one of the architecture's strengths and eliminates a lot of explicit comparisons. Once you internalize this, your loops will be tighter and your cycle-count math will be accurate.

## Summary

The approach and math are fundamentally sound. The two issues (redundant `cmp` and unnecessary `call` for the inner loop) are the kind of things that disappear once you internalize how the MSP430 status register works. The logic is correct, the structure is reasonable, and the LED blinks — just tighten the inner loop and trust `dec.w` to set your flags.
