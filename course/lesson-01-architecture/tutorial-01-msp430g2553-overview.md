# Tutorial 01 — MSP430G2553 Architecture Overview

## What is a Microcontroller?

A microcontroller (MCU) is a computer on a chip. It has a CPU, memory, and peripherals (timers, communication, ADC) all in one package. The MSP430G2553 is a tiny 20-pin chip that runs on 3.3V, consumes microamps in sleep mode, and costs about $1.

The LaunchPad (MSP-EXP430G2) is a development board that holds the G2553, provides USB programming, and breaks out all the pins so you can connect hardware to a breadboard.

---

## Memory Map

The MSP430 uses a single flat address space — the CPU accesses Flash, RAM, and peripheral registers all with the same instructions, just different addresses.

```
Address         Size    What lives here
──────────────────────────────────────────────────────
0xFFFF ┐
  ...  │  16 KB  Flash (your program code)
0xC000 ┘
0x10FF ┐
  ...  │   256 B  Info Flash (calibration data, see below)
0x1000 ┘
0x03FF ┐
  ...  │   512 B  RAM (your variables and the stack)
0x0200 ┘
0x01FF ┐
  ...  │   512 B  Peripheral registers (ports, timers, UART...)
0x0000 ┘
```

### Flash (0xC000–0xFFFF)

This is where your assembled `.s` file lives after you flash it. It's non-volatile — it survives power loss. The CPU reads instructions directly from Flash, one 16-bit word at a time.

The last 32 bytes of Flash (0xFFE0–0xFFFF) are the **interrupt vector table** — 16 two-byte slots, each holding the address of an interrupt service routine (ISR). The most important is at 0xFFFE, the **Reset vector**, which holds the address of `_start`. When power is applied or the Reset button is pressed, the CPU reads 0xFFFE and jumps there.

### RAM (0x0200–0x03FF)

All 512 bytes of RAM are here. This is where you store variables, arrays, and the call stack. It's volatile — cleared on power loss.

The **stack** starts at the top of RAM (0x0400) and grows **downward**. The stack pointer (R1/SP) always points to the last item pushed. Each CALL pushes the return address (2 bytes), so with 512 B of RAM and a few levels of subroutine calls, you can easily run out if you're not careful.

### Info Flash (0x1000–0x10FF)

This is a small area where TI pre-programmed **DCO calibration constants** at manufacture. Reading them gives you a precise clock frequency. The ones we use:

| Address | Name | Meaning |
|---------|------|---------|
| 0x10FF | CALBC1_1MHZ | Load into BCSCTL1 for 1 MHz |
| 0x10FE | CALDCO_1MHZ | Load into DCOCTL  for 1 MHz |
| 0x10FD | CALBC1_8MHZ | Load into BCSCTL1 for 8 MHz |
| 0x10FC | CALDCO_8MHZ | Load into DCOCTL  for 8 MHz |

### Peripheral Registers (0x0000–0x01FF)

Every peripheral (GPIO ports, timers, ADC, UART, SPI) is controlled by reading and writing specific addresses in this range. For example, to make P1.0 (LED1) an output, you set bit 0 of the register at address 0x0022 (P1DIR). The `common/msp430g2553-defs.s` file gives all these addresses readable names.

---

## The 16 CPU Registers

The MSP430 has 16 sixteen-bit registers. You can think of them as very fast scratch-pad memory inside the CPU.

```
Register   Alias    Role
─────────────────────────────────────────────────────────
R0         PC       Program Counter — address of next instruction
R1         SP       Stack Pointer   — address of top of stack
R2         SR / CG1 Status Register — flags (carry, zero, negative, GIE...)
R3         CG2      Constant Generator — always reads 0, 1, 2, 4, 8, -1
R4–R11              General purpose — use freely
R12–R15             General purpose — also function arguments (R12=arg0, R13=arg1, R14=arg2)
```

You never write to R0–R3 directly (use JMP/CALL for R0, PUSH/POP for R1). R4–R15 are yours.

### Status Register (R2/SR) Bits

The SR holds flags that reflect the result of the last arithmetic or logic instruction:

| Bit | Name | Meaning |
|-----|------|---------|
| 0 | C | Carry — set if addition overflows 16 bits |
| 1 | Z | Zero — set if result is 0 |
| 2 | N | Negative — set if result is negative (bit 15 = 1) |
| 3 | GIE | Global Interrupt Enable — must be set for interrupts to fire |
| 4 | CPUOFF | CPU off — enter low-power mode |

Conditional jump instructions test these flags: `JZ` jumps if Z=1, `JNZ` if Z=0, `JC` if C=1, etc.

---

## Instruction Set Basics

MSP430 instructions follow the pattern: `OPCODE.SIZE  SOURCE, DEST`

The `.SIZE` suffix is `.W` (16-bit word, default) or `.B` (8-bit byte). Peripheral registers are usually 8-bit, so you'll use `.B` when touching port registers and `.W` for everything else.

### Most-Used Instructions

**Data movement:**

```asm
mov.w   #42, R5         ; R5 = 42  (immediate → register)
mov.w   R5, R6          ; R6 = R5  (register → register)
mov.b   &P1IN, R7       ; R7 = P1IN register  (memory → register, 8-bit)
mov.b   R7, &P1OUT      ; P1OUT = low byte of R7  (register → memory)
```

**Arithmetic:**

```asm
add.w   #1, R5          ; R5 = R5 + 1
sub.w   #10, R6         ; R6 = R6 - 10
inc.w   R5              ; R5++  (shorthand for add.w #1, R5)
dec.w   R5              ; R5--  (shorthand for sub.w #1, R5)
```

**Bit manipulation** — these are the most important for embedded work:

```asm
bis.b   #BIT0, &P1DIR   ; Set bit 0 of P1DIR   (BIS = Bit Set)
bic.b   #BIT0, &P1OUT   ; Clear bit 0 of P1OUT (BIC = Bit Clear)
xor.b   #BIT0, &P1OUT   ; Toggle bit 0 of P1OUT
bit.b   #BIT3, &P1IN    ; Test bit 3 of P1IN (sets Z flag, no write)
```

`BIS` and `BIC` are how you set and clear individual bits without disturbing others. In C you'd write `P1DIR |= BIT0` (set) or `P1DIR &= ~BIT0` (clear) — in MSP430 assembly you just write `bis.b` or `bic.b`.

**Jumps and calls:**


```asm
jmp     loop            ; Unconditional jump
jz      done            ; Jump if Z flag = 1 (result was zero)
jnz     loop            ; Jump if Z flag = 0 (result was not zero)
jc      overflow        ; Jump if Carry set
jnc     no_carry        ; Jump if Carry clear
call    #delay_ms       ; Call subroutine (push PC, jump)
ret                     ; Return from subroutine (pop PC)
```

### Four Addressing Modes

| Mode | Example | Meaning |
|------|---------|---------|
| Register | `R5` | The register itself |
| Immediate | `#42` or `#BIT0` | A constant value |
| Absolute | `&P1OUT` | The contents of a specific memory address |
| Indirect | `@R5` | The memory address stored in R5 |

The `&` prefix means "the memory location at this address." You'll use it for every peripheral register access.

---

## Hex Values and Bit Positions

Peripheral registers are controlled bit by bit. Understanding how a hex constant maps to individual bits is essential for reading any MSP430 program.

### Each power of two is exactly one bit

```
Hex    Binary      Bit position
0x01 = 0000 0001   bit 0
0x02 = 0000 0010   bit 1
0x04 = 0000 0100   bit 2
0x08 = 0000 1000   bit 3
0x10 = 0001 0000   bit 4
0x20 = 0010 0000   bit 5
0x40 = 0100 0000   bit 6
0x80 = 1000 0000   bit 7
```

That's why `BIT0 = 0x01`, `BIT6 = 0x40`, etc. — each is 2 raised to the bit-position number. To find which bit a hex constant sets, find which power of two it equals.

### OR combines multiple bits without conflict

When you see `#(WDTPW|WDTHOLD)`, the `|` is bitwise OR. Each bit stays independent — ORing masks together sets all their bits at once:

```
WDTPW   = 0x5A00 = 0101 1010 0000 0000   upper byte = password 0x5A
WDTHOLD = 0x0080 = 0000 0000 1000 0000   bit 7 = stop the watchdog

WDTPW | WDTHOLD
        = 0x5A80 = 0101 1010 1000 0000
                   ─────────             password still in upper byte
                             ─           bit 7 set = watchdog stopped
```

No bit in one constant overwrites a bit from the other — every 1 from either mask becomes a 1 in the result.

### BIS and BIC only touch the bits you name

`bis.b` and `bic.b` affect only the bits that are 1 in the mask; all other bits in the register are left alone. This matters because one register controls multiple things simultaneously:

```asm
; P1DIR currently = 0100 0000  (P1.6 was already an output for LED2)
bis.b   #BIT0, &P1DIR       ; set bit 0 only — leave everything else
; P1DIR is now  = 0100 0001   (P1.0 AND P1.6 are both outputs)

bic.b   #BIT6, &P1DIR       ; clear bit 6 only
; P1DIR is now  = 0000 0001   (only P1.0 remains an output)
```

If you used `mov.b #BIT0, &P1DIR` instead of `bis.b`, it would overwrite the whole register — clearing P1.6 as a side effect.

### 16-bit registers use the same pattern, extended to two bytes

For 16-bit registers like TACTL or WDTCTL, bit 0 is still the rightmost, bit 15 the leftmost. Multi-field values are still just OR'd together:

```asm
mov.w   #(TASSEL_2|MC_1|TACLR), &TACTL
; TASSEL_2 = 0x0200 = 0000 0010 0000 0000   bit 9  = SMCLK source
; MC_1     = 0x0010 = 0000 0000 0001 0000   bit 4  = Up mode
; TACLR    = 0x0004 = 0000 0000 0000 0100   bit 2  = clear counter
;            ─────────────────────────────
;            0x0214 = 0000 0010 0001 0100   all three at once
```

The `msp430g2553-defs.s` file has bit-position comments and register layout diagrams for every peripheral — refer to it whenever a hex value looks mysterious.

---

## GPIO: Controlling LED1

Every GPIO pin has two key registers: **DIR** (direction) and **OUT** (output value).

```asm
; Make P1.0 an output
bis.b   #BIT0, &P1DIR       ; P1DIR bit 0 = 1 → output

; Turn LED1 on
bis.b   #BIT0, &P1OUT       ; P1OUT bit 0 = 1 → HIGH → LED on

; Turn LED1 off
bic.b   #BIT0, &P1OUT       ; P1OUT bit 0 = 0 → LOW → LED off

; Toggle LED1
xor.b   #BIT0, &P1OUT       ; flip bit 0 every time
```

The `msp430g2553-defs.s` file defines `LED1 = BIT0`, so you can write:
```asm
bis.b   #LED1, &P1DIR
xor.b   #LED1, &P1OUT
```

---

## Program Structure

Every `.s` file in this course follows the same skeleton:

```asm
#include "../../common/msp430g2553-defs.s"   ; all register names

    .text                                     ; code goes here
    .global _start

_start:
    ; 1. Initialize the Stack Pointer (ALWAYS first when using call/ret)
    mov.w   #0x0400, SP                 ; top of RAM = 0x0400 (one past 0x03FF)

    ; 2. Disable the watchdog timer
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL

    ; 3. Calibrate the DCO to 1 MHz
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1
    mov.b   &CALDCO_1MHZ, &DCOCTL

    ; ... your setup code here ...

main_loop:
    ; ... your main loop here ...
    jmp     main_loop

; --- Subroutines below ---

; --- Interrupt vector table at bottom ---
    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0            ; 0xFFE0–0xFFEF  unused vectors
    .word   0,0,0,0, 0,0,0              ; 0xFFF0–0xFFFC  unused vectors
    .word   _start                      ; 0xFFFE  Reset — CPU jumps here on power-up
    .end
```

Three things you must **always** do at the very start:

1. **Initialize the Stack Pointer** — with `-nostdlib` there is no C runtime to set up SP for you. `call` and `ret` use the stack to save and restore the return address. Without a valid SP, the first `call` pushes the return address to a garbage location and `ret` jumps to a garbage address, crashing the chip. Set SP to `0x0400` — one byte past the top of RAM (0x03FF), because the stack grows downward and SP points to the last value pushed.

2. **Disable the watchdog** — the WDT is a hardware timer that resets the chip if you don't service it. We hold it (stop it) with `mov.w #(WDTPW|WDTHOLD), &WDTCTL`. In the game project we'll eventually use it as an interval timer, but for now we stop it.

3. **Calibrate the DCO** — the internal oscillator runs at an imprecise frequency from the factory. The three-line calibration sequence loads TI's factory-measured values from Info Flash to hit exactly 1 MHz.

---

## A Software Delay Loop

Without timers (covered in Lesson 06), we can burn time by running empty loops. At 1 MHz, 1 instruction cycle = 1 µs.

```asm
; delay_ms — wait approximately R12 milliseconds at 1 MHz
; Arg:     R12 = millisecond count (pass by register, consumed)
; Clobbers: R12, R13
;
; How it works: at 1 MHz, 1 ms = 1000 cycles
;   Inner loop: dec (1 cycle) + jnz (2 cycles) = 3 cycles per iteration
;   333 iterations × 3 cycles = 999 cycles ≈ 1 ms
delay_ms:
    mov.w   #333, R13           ; reset inner counter
.Ldms_inner:
    dec.w   R13
    jnz     .Ldms_inner         ; loop 333 times (999 cycles total)
    dec.w   R12                 ; one ms done; any more to go?
    jnz     delay_ms
    ret
```

Call it like this:
```asm
    mov.w   #500, R12           ; 500 ms
    call    #delay_ms
```

This isn't perfect — the overhead of `dec R12` and `jnz delay_ms` adds a few cycles per millisecond, and call/ret adds a few more — but it's within 1% of target at 1 MHz, which is plenty for blinking an LED. In Lesson 06 we'll use Timer A for cycle-accurate timing.

---

## Next

Read `tutorial-02-toolchain-workflow.md`, then run the example in `examples/blink.s`.
