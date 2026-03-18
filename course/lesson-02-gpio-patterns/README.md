# Lesson 02 — GPIO Output & Patterns

**Goal:** Go beyond single-LED blink — drive multiple LEDs in coordinated patterns and build your first reusable subroutine.

**Game connection:** Before the OLED arrives, LEDs are your only output. The pattern logic you write here — phase sequencing, counted loops, state tracking — is exactly what the game loop will do later, just driving pixels instead of pins.

---

## What You'll Learn

- How `P1DIR` and `P1OUT` work at the bit level
- `bis.b`, `bic.b`, `xor.b`, `bit.b` — when to use each one
- Building a counted loop with `dec.w` / `jnz`
- Writing a reusable `flash_leds` subroutine (no stack needed yet)
- Sequencing multiple phases in a main loop
- Using a register as a state variable

---

## Hardware

Just the **MSP-EXP430G2 LaunchPad** connected via USB.

- **LED1** — Red, P1.0
- **LED2** — Green, P1.6

---

## Files

```
lesson-02-gpio-patterns/
├── README.md                        ← you are here
├── tutorial-01-gpio-output.md       ← P1DIR/P1OUT deep dive, bit ops, counted loops
├── tutorial-02-patterns-and-state.md ← phase sequencing, subroutines, state machines
├── examples/
│   ├── Makefile
│   └── patterns.s                   ← 3-phase game-state demo
└── exercises/
    ├── README.md                    ← exercise descriptions
    ├── ex1/   ex1/solution/         ← counted flash
    ├── ex2/   ex2/solution/         ← dual throb
    └── ex3/   ex3/solution/         ← mini state machine
```

---

## Suggested Path

1. Read `tutorial-01-gpio-output.md`
2. Read `tutorial-02-patterns-and-state.md`
3. Run the example: `cd examples && make flash`
4. Attempt the exercises **before** looking at solutions
5. When all three pass, move to Lesson 03

---

## Key Facts to Memorize

| Instruction | Effect | When to use |
|-------------|--------|-------------|
| `bis.b #MASK, &P1OUT` | Set bits — LED ON | Explicit on |
| `bic.b #MASK, &P1OUT` | Clear bits — LED OFF | Explicit off |
| `xor.b #MASK, &P1OUT` | Flip bits — toggle | When you don't care about starting state |
| `bit.b #MASK, &P1IN` | Test bits (read) | Reading a pin without changing it |

| Register role | Registers |
|---------------|-----------|
| Scratch / args to subroutines | R12, R13, R14, R15 |
| Loop counters / state (save yourself) | R4–R11 |
