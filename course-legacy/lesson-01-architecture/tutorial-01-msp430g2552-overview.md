# Tutorial 01 — MSP430G2552 Overview

## Why MSP430?

The MSP430 is Texas Instruments' flagship ultralow-power 16-bit RISC
microcontroller family. It is used in real products including medical devices,
industrial sensors, smart meters, and battery-powered IoT nodes. Key reasons to
learn it:

- **Ultralow power**: active mode as low as 220 µA/MHz; sleep modes under 1 µA
- **16-bit RISC architecture**: clean, orthogonal instruction set — easy to
  learn
- **Integrated peripherals**: ADC, UART, SPI, I2C, timers all on-chip
- **Large ecosystem**: free tools (GCC, mspdebug), wide industry use
- **Small footprint**: the G2552 has only 8KB flash and 512B RAM — every byte
  matters, teaching efficiency

The MSP430G2552 is the chip on the MSP-EXP430G2 LaunchPad development board. It
costs about $1 in volume, runs from 1.8–3.6V, and operates from DC to 16MHz.

---

## The 16 Registers

The MSP430 CPU has 16 registers, each 16 bits wide. They are divided into
special-purpose and general-purpose groups.

| Register | Name | Purpose |
|----------|------|---------|
| R0 | PC — Program Counter | Address of the next instruction to execute. Automatically updated by the CPU after each instruction fetch. |
| R1 | SP — Stack Pointer | Address of the top of the stack. Decremented by PUSH, incremented by POP. Initialized to top of RAM (0x0400 on G2552). |
| R2 | SR — Status Register | CPU condition flags and control bits. See the Status Register section below. |
| R3 | CG — Constant Generator | Special register used by the assembler to encode small constants efficiently. Not directly addressable in most instructions. |
| R4 | General Purpose | Available for program use — first choice for local variables. |
| R5 | General Purpose | Available for program use. |
| R6 | General Purpose | Available for program use. |
| R7 | General Purpose | Available for program use. |
| R8 | General Purpose | Available for program use. |
| R9 | General Purpose | Available for program use. |
| R10 | General Purpose | Available for program use. |
| R11 | General Purpose | Available for program use. |
| R12 | General Purpose | By convention: first argument to subroutines, return value from subroutines. |
| R13 | General Purpose | By convention: second argument to subroutines. |
| R14 | General Purpose | By convention: third argument to subroutines. |
| R15 | General Purpose | By convention: fourth argument; commonly used as a scratch/delay counter. |

Registers R4–R15 are initialized to unknown values at power-on. Your program
must initialize any register before using its value.

---

## Status Register (R2/SR)

The Status Register records the result of the most recent arithmetic or logical
operation, and controls CPU operating modes.

| Bit | Name | Description |
|-----|------|-------------|
| 8 | V | **Overflow**: set when a signed arithmetic operation overflows (result exceeds signed 16-bit range) |
| 7 | SCG1 | System Clock Generator 1 control — used for low-power modes |
| 6 | SCG0 | System Clock Generator 0 control — used for low-power modes |
| 5 | OSCOFF | Oscillator off — used for low-power modes |
| 4 | CPUOFF | CPU off — used for low-power modes (LPM1 and above) |
| 3 | GIE | **Global Interrupt Enable**: when 1, maskable interrupts are enabled |
| 2 | N | **Negative**: set when result of operation is negative (MSB = 1) |
| 1 | Z | **Zero**: set when result of operation is zero |
| 0 | C | **Carry**: set when operation produces a carry or borrow |

The conditional jump instructions (`jz`, `jnz`, `jc`, `jnc`, `jn`, `jge`, `jl`)
test these flags. For example, `sub.w R4, R4` sets Z=1 because the result is
zero.

---

## Memory Map

The MSP430G2552 uses a unified 16-bit address space — RAM, flash, and peripheral
registers all share the same address bus.

| Address Range | Size | Region | Description |
|---------------|------|--------|-------------|
| 0x0000–0x000F | 16 B | Special Function Registers (SFR) | Interrupt enable/flag registers |
| 0x0010–0x00FF | 240 B | 8-bit Peripheral Registers | GPIO, comparator registers (byte access) |
| 0x0100–0x01FF | 256 B | 16-bit Peripheral Registers | Timer, USCI, ADC, clock system (word access) |
| 0x0200–0x03FF | 512 B | RAM | Stack and program variables |
| 0x0400–0x1FFF | — | (not used on G2552) | Reserved |
| 0x1000–0x10FF | 256 B | Information Flash | Calibration data, user info storage |
| 0x2000–0x3FFF | — | (not used on G2552) | Reserved |
| 0xC000–0xFFDF | 8 KB | Program Flash | Your program code lives here |
| 0xFFE0–0xFFFF | 32 B | Interrupt Vector Table | Addresses of interrupt service routines |

Key addresses to know:
- `0x0120` = WDTCTL (Watchdog Timer Control)
- `0x0020` = P1IN, `0x0021` = P1OUT, `0x0022` = P1DIR (GPIO Port 1)
- `0x0200` = start of RAM (good place for variables)
- `0x03FF` = top of RAM (stack starts here and grows downward)

---

## Instruction Format

MSP430 assembly instructions follow this general format:

```
label:  opcode.suffix  source, destination  ; comment
```

- **label**: optional symbolic name for this address (used by jumps and calls)
- **opcode**: the operation (mov, add, sub, bis, bic, jmp, call, etc.)
- **.suffix**: `.w` for 16-bit word operation, `.b` for 8-bit byte operation
- **source**: where data comes from
- **destination**: where result is stored
- **comment**: anything after `;` is ignored by the assembler

Example:
```asm
loop:   add.w   R5, R4      ; R4 = R4 + R5 (16-bit addition)
        bis.b   #BIT0, &P1OUT   ; Set bit 0 of P1OUT (8-bit)
```

Note: GNU assembler syntax is `opcode src, dst` — source first, destination
second. This is the same as AT&T syntax used by GCC for x86.

---

## Common Instructions

| Instruction | Operation | Description |
|-------------|-----------|-------------|
| `mov.w src, dst` | dst = src | Copy value (no flags set) |
| `add.w src, dst` | dst = dst + src | Add; sets C, Z, N, V |
| `sub.w src, dst` | dst = dst - src | Subtract; sets C, Z, N, V |
| `cmp.w src, dst` | dst - src (flags only) | Compare without storing result |
| `bis.w src, dst` | dst = dst \| src | Bit Set — set bits where src=1 |
| `bic.w src, dst` | dst = dst & ~src | Bit Clear — clear bits where src=1 |
| `xor.w src, dst` | dst = dst ^ src | Exclusive-OR — toggle bits |
| `bit.w src, dst` | dst & src (flags only) | Bit Test — test bits without storing |
| `and.w src, dst` | dst = dst & src | Logical AND |
| `inc.w dst` | dst = dst + 1 | Increment |
| `dec.w dst` | dst = dst - 1 | Decrement |
| `clr.w dst` | dst = 0 | Clear register |
| `inv.w dst` | dst = ~dst | Invert (bitwise NOT) |
| `push.w src` | SP -= 2; mem[SP] = src | Push to stack |
| `pop.w dst` | dst = mem[SP]; SP += 2 | Pop from stack |
| `jmp label` | PC = label | Unconditional jump |
| `jz label` | if Z=1: PC = label | Jump if zero |
| `jnz label` | if Z=0: PC = label | Jump if not zero |
| `jc label` | if C=1: PC = label | Jump if carry |
| `jnc label` | if C=0: PC = label | Jump if no carry |
| `jn label` | if N=1: PC = label | Jump if negative |
| `jge label` | if N=V: PC = label | Jump if greater-or-equal (signed) |
| `jl label` | if N≠V: PC = label | Jump if less-than (signed) |
| `call #label` | push PC; PC = label | Call subroutine |
| `ret` | pop PC | Return from subroutine |
| `reti` | pop SR; pop PC | Return from interrupt |
| `nop` | no operation | One cycle delay / alignment |

Use the `.b` suffix variants (e.g., `bis.b`, `bic.b`, `xor.b`) for 8-bit
peripheral registers like P1OUT, P1DIR. Using `.w` on an 8-bit register can have
unexpected effects.

---

## Addressing Modes

The MSP430 supports five addressing modes for source and destination operands:

| Mode | Syntax | Example | Description |
|------|--------|---------|-------------|
| Register | `Rn` | `R4` | Operand is the value in register Rn |
| Absolute | `&ADDR` | `&P1OUT` | Operand is at memory address ADDR (the `&` means "absolute address") |
| Immediate | `#value` | `#42` | Operand is the constant value (source only) |
| Indexed | `offset(Rn)` | `2(R4)` | Operand is at address Rn + offset |
| Indirect | `@Rn` | `@R4` | Operand is at the address contained in Rn |
| Indirect auto-increment | `@Rn+` | `@R4+` | Like indirect, but Rn is incremented after access |

Examples:
```asm
mov.w   #0x1234, R5         ; Immediate → register: R5 = 0x1234
mov.w   R5, &0x0200         ; Register → absolute: RAM[0x0200] = R5
mov.w   &0x0200, R6         ; Absolute → register: R6 = RAM[0x0200]
mov.w   R6, 4(R5)           ; Register → indexed: RAM[R5+4] = R6
mov.w   @R5, R6             ; Indirect → register: R6 = RAM[R5]
```

---

## The Constant Generator (R3/CG)

Register R3 is the Constant Generator. The CPU has special hardware that, when
R3 is used as a source operand with certain addressing modes, generates one of
six constants without fetching an additional word from memory:

| Encoding | Value Generated |
|----------|----------------|
| R3 with register mode | 0 |
| R3 with indexed mode (offset 0) | 0 |
| R3 with indexed mode (offset 1) | 1 |
| R3 with absolute mode | 2 |
| R3 with indirect mode | 4 |
| R3 with indirect auto-increment | 8 |
| R2 with indirect mode | 4 |
| R2 with indirect auto-increment | 8 |
| R2 with absolute mode | -1 (0xFFFF) |

In practice, the assembler automatically uses the constant generator when you
write `#0`, `#1`, `#2`, `#4`, `#8`, or `#-1` as immediate operands. This saves a
word of flash and one instruction cycle. You don't need to use R3 directly —
just write `mov.w #1, R4` and the assembler optimizes it.

This is why simple constant operations are faster and smaller than they might
appear — the MSP430 was designed from the start with power and code density in
mind.
