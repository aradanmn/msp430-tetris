# Tutorial 09-1 · Interrupt Mechanics

## What Is an Interrupt?

An **interrupt** is a hardware signal that pauses the CPU, saves its state, runs
a special routine (the ISR), then restores the CPU state and resumes normal
execution.

The programmer's model:

```
Normal execution:           Interrupt fires:
  ...                         CPU finishes current instruction
  instruction N               CPU saves: PC, SR → stack
  instruction N+1    ←──      CPU clears GIE (disables further interrupts)
  ...                         CPU loads ISR address from vector table
                              ISR runs
                              RETI: restores PC, SR from stack
                              GIE restored → interrupts re-enabled
                              execution resumes at instruction N+1
```

---

## The Interrupt Request Sequence

When a peripheral sets an interrupt flag (e.g., WDT sets WDTIFG):

1. **Hardware checks**: Is the interrupt enabled? (peripheral IE bit) AND is GIE
   set in SR? If yes, proceed.
2. **CPU completes** the current instruction
3. **CPU pushes SR** then **PC** onto the stack (SP decrements by 4 total)
4. **GIE is cleared** in SR (prevents nested interrupts unless re-enabled)
5. **CPU loads** the ISR address from the interrupt vector table
6. **ISR runs**
7. **`RETI`** restores PC and SR from the stack (GIE is restored too)

---

## The Interrupt Vector Table

The MSP430 reserves the top 32 bytes of flash for interrupt vectors:
`0xFFE0–0xFFFF`.  Each vector is a 16-bit word pointing to an ISR.

```
Address  | Interrupt Source
---------|------------------
0xFFFE   | Reset (highest priority)
0xFFFC   | NMI
0xFFF6   | WDT+ interval
0xFFF4   | Timer_A CC0
0xFFF2   | Timer_A CC1/CC2/overflow
0xFFEC   | USCI A0/B0 RX
0xFFEE   | USCI A0/B0 TX
0xFFEA   | ADC10
0xFFE4   | Port 1
0xFFE6   | Port 2
```

In GNU assembler, you place vector entries like this:

```asm
        .section ".vectors","ax",@progbits

        .org    0xFFF6
        .word   WDT_ISR         ; WDT vector → address of WDT_ISR

        .org    0xFFFE
        .word   main            ; Reset vector → address of main
```

---

## Priority

Lower address = lower priority, higher address = higher priority. Reset (0xFFFE)
has the highest priority.  If multiple interrupts fire simultaneously, the
highest priority one runs first.

---

## Why `RETI` and Not `RET`?

`RET` pops only PC from the stack. `RETI` pops **both SR and PC** — and since SR
contains GIE, popping SR re-enables global interrupts automatically.

```
Stack before RETI:
  SP → [PC_of_interrupted_code]
         [SR_of_interrupted_code]  ← contains GIE=1

RETI: pops SR (GIE restored), then pops PC
```

If you use `RET` in an ISR, GIE remains 0 (cleared when ISR started) and no
further interrupts can fire — the system effectively freezes.

---

## GIE — Global Interrupt Enable

The **Global Interrupt Enable** bit is bit 3 of the Status Register:

```asm
.equ    GIE,    0x0008      ; SR bit 3
```

- `BIS.W #GIE, SR` — enable all interrupts
- `BIC.W #GIE, SR` — disable all interrupts (temporarily)
- `DINT` — disable interrupts (assembler shorthand for BIC.W #GIE, SR)
- `EINT` — enable interrupts (shorthand for BIS.W #GIE, SR)

GIE must be set in `main` before any interrupt can fire.

---

## Registers in ISRs

When your ISR runs, it has access to all 16 registers **but the CPU does not
save them** — only SR and PC are saved automatically.

**You must save any registers your ISR uses:**

```asm
MY_ISR:
        push    R12         ; save register
        push    R13

        ; ... do work using R12, R13 ...

        pop     R13         ; restore in reverse order
        pop     R12
        reti
```

If you forget to save a register, its value will be corrupted on return to the
interrupted code — a hard-to-debug bug.

---

## Next

Tutorial 02 shows how to combine ISRs with Low Power Modes so the CPU sleeps
between interrupts.
