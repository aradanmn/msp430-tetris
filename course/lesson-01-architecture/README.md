# Lesson 01 — MSP430 Architecture & Tools

## Learning Objectives
- Describe the MSP430G2552 CPU registers and their purposes
- Interpret the memory map and find peripherals, RAM, flash
- Write and build a minimal program
- Use mspdebug to inspect registers and RAM

## Topics
| Tutorial | Content |
|----------|---------|
| tutorial-01-msp430g2552-overview.md | CPU, registers, memory map |
| tutorial-02-toolchain-workflow.md | Build tools, make, mspdebug |

## Files
```
lesson-01-architecture/
├── README.md
├── tutorial-01-msp430g2552-overview.md
├── tutorial-02-toolchain-workflow.md
├── examples/Makefile, minimal.s
└── exercises/README.md, ex1/, ex2/, ex3/
```

## How This Fits the Capstone
Every program — including the final Smart Environment Monitor — starts with
stopping the watchdog timer and follows the same structural pattern learned
here.

## Steps
1. Read both tutorials
2. Build examples: `cd examples && make && make flash`
3. Inspect with mspdebug: `mspdebug rf2500` then `regs` and `md 0x0200 16`
4. Complete exercises — try before looking at solutions!
