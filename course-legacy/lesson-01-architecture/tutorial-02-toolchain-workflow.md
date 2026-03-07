# Tutorial 02 — Toolchain & Development Workflow

## The Toolchain Pipeline

Every MSP430 assembly program goes through a fixed series of transformations
before it runs on the chip:

```
your_file.s
    │
    ▼  C Preprocessor (cpp)
    │  Handles: #include, #define, #ifdef
    │
    ▼  GNU Assembler (as)
    │  Translates mnemonics to machine code bytes
    │
    ▼  Linker (ld)
    │  Assigns addresses, links sections → .elf file
    │
    ▼  mspdebug / rf2500 driver
       Sends .elf over USB to LaunchPad
       Writes bytes into MSP430 flash memory
```

In practice, `msp430-elf-gcc` (or `msp430-gcc`) handles all of these steps in
one command. You only invoke one tool; it calls the preprocessor, assembler, and
linker internally.

---

## Why -x assembler-with-cpp

Assembly files (`.s`) normally skip the C preprocessor step. But our files use
`#include` to pull in register definitions:

```asm
#include "../../common/msp430g2552-defs.s"
```

Without the C preprocessor, `#include` is an error. The flag `-x
assembler-with-cpp` tells GCC: "treat this file as assembly, but run the C
preprocessor first." This allows:

- `#include "file.s"` — pull in definitions from another file
- `#define NAME value` — create named constants
- `#ifdef / #endif` — conditional assembly

Without this flag, GCC would try to compile the `.s` file as C source code and
fail immediately at the `#include` line. This is the most common setup error
beginners encounter.

---

## File Structure and Sections

Every MSP430 assembly file has a structure that tells the linker how to organize
its contents:

```asm
; Preprocessor directives (resolved before assembling)
#include "../../common/msp430g2552-defs.s"

; Assembler directives — section placement
        .text           ; Code goes into flash (read-only)

        .global main    ; Make 'main' visible to the linker

main:
        ; Your instructions here
```

The three standard sections:

| Section | Directive | Stored In | Contents |
|---------|-----------|-----------|----------|
| `.text` | `.text` | Flash (ROM) | Executable instructions |
| `.data` | `.data` | RAM (copied from flash at startup) | Initialized variables |
| `.bss` | `.bss` | RAM (zero-filled at startup) | Uninitialized variables |

For most bare-metal MSP430 programs in this course, we only use `.text`.
Variables are stored directly in RAM using absolute addresses (`&0x0200`) rather
than `.data` or `.bss` sections (the startup code that would copy `.data` into
RAM is not present in minimal builds).

---

## The Makefile Explained

Every lesson uses the same Makefile pattern. Here it is annotated line by line:

```makefile
TARGET  = minimal          # Name of your program (no extension)
MCU     = msp430g2552      # Target MCU — passed to GCC

# Auto-detect the compiler: prefer msp430-elf-gcc, fall back to msp430-gcc
CC := $(shell which msp430-elf-gcc 2>/dev/null || which msp430-gcc 2>/dev/null)

# Derive objdump and size tool names from the compiler path
# e.g. msp430-elf-gcc → msp430-elf-objdump
OBJDUMP := $(subst gcc,objdump,$(CC))
SIZE    := $(subst gcc,size,$(CC))

# Compiler/assembler flags:
#   -mmcu=msp430g2552        : select MSP430G2552 linker script and defines
#   -x assembler-with-cpp    : run C preprocessor on .s files
#   -g                       : include debug symbols in .elf
#   -Wall                    : show all warnings
CFLAGS  = -mmcu=$(MCU) -x assembler-with-cpp -g -Wall

# Default target: build the .elf and show its size
all: $(TARGET).elf
	@$(SIZE) $(TARGET).elf

# Assemble and link the .s file to produce .elf
$(TARGET).elf: $(TARGET).s
	$(CC) $(CFLAGS) -o $@ $<

# Flash the .elf to the LaunchPad using mspdebug
flash: $(TARGET).elf
	mspdebug rf2500 "prog $<"

# Disassemble the .elf to see machine code and addresses
disasm: $(TARGET).elf
	$(OBJDUMP) -d $<

# Remove build artifacts
clean:
	rm -f $(TARGET).elf

.PHONY: all flash disasm clean
```

---

## Running make

Navigate to the `examples/` directory and run `make`:

```
$ cd lesson-01-architecture/examples
$ make
msp430-elf-gcc -mmcu=msp430g2552 -x assembler-with-cpp \
               -g -Wall -o minimal.elf minimal.s
   text	   data	    bss	    dec	    hex	filename
     18	      0	      0	     18	     12	minimal.elf
```

The `SIZE` output tells you:
- **text**: bytes of flash used by your program (18 bytes — very small!)
- **data**: bytes of initialized RAM variables (0 — we have none)
- **bss**: bytes of zero-initialized RAM variables (0 — we have none)
- **dec / hex**: total in decimal and hexadecimal

The MSP430G2552 has 8192 bytes of flash. A minimal program uses 18 bytes — you
have room to grow.

---

## Flashing to the LaunchPad

Connect your MSP-EXP430G2 LaunchPad via USB, then run:

```
$ make flash
mspdebug rf2500 "prog minimal.elf"
```

mspdebug will:
1. Detect the LaunchPad over USB
2. Erase the MSP430 flash
3. Write your program
4. Verify the write
5. Exit (the MSP430 starts running immediately)

Expected output:
```
MSPDebug version 0.25 - debugging tool for MSP430 MCUs
Copyright (C) 2009-2013 Daniel Beer <dlbeer@gmail.com>
...
Erasing...
Programming...
Writing 18 bytes at c000 [section: .text]...
Done, 18 bytes total
```

---

## make disasm

The `disasm` target shows you the actual machine code that the assembler
produced:

```
$ make disasm
msp430-elf-objdump -d minimal.elf

minimal.elf:     file format elf32-msp430

Disassembly of section .text:

0000c000 <main>:
    c000:   b2 40 80 5a     mov.w   #23168, 0x0120  ; WDTPW|WDTHOLD = 0x5A80
    c004:   20 01
    c006:   ff 3f           jmp     .+0             ; halt (jmp to self)
```

Reading a disassembly line:
- `0000c000` — address in flash where this instruction is stored
- `b2 40 80 5a 20 01` — the raw bytes in memory (little-endian)
- `mov.w #23168, 0x0120` — the human-readable disassembly

Your `mov.w #(WDTPW|WDTHOLD), &WDTCTL` becomes 6 bytes (3 words) because it uses
immediate and absolute addressing. The `jmp halt` becomes 2 bytes (a self-jump:
`ff 3f`).

---

## mspdebug Interactive Commands

After flashing, you can debug interactively:

```
$ mspdebug rf2500
(mspdebug) prog minimal.elf     ; Flash the program
(mspdebug) run                  ; Start execution
(mspdebug) halt                 ; Pause execution
(mspdebug) regs                 ; Show all register values
(mspdebug) step                 ; Execute one instruction
(mspdebug) md 0x0200 16        ; Memory dump: show 16 bytes at 0x0200
(mspdebug) md 0xFFE0 32        ; Show interrupt vector table (32 bytes)
(mspdebug) reset                ; Reset the MSP430
(mspdebug) exit                 ; Quit mspdebug
```

Example `regs` output:
```
    PC  0xc006    SP  0x03ff    SR  0x0000    CG  0x0000
    R4  0x0000    R5  0x0000    R6  0x0000    R7  0x0000
    R8  0x0000    R9  0x0000   R10  0x0000   R11  0x0000
   R12  0x0000   R13  0x0000   R14  0x0000   R15  0x0000
```

PC=0xc006 is the halt loop — the CPU is executing `jmp halt` repeatedly, which
is correct.

Example `md 0x0200 16` output (after Exercise 1 writes to RAM):
```
0200:   37 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00   7...............
```

The first two bytes `37 00` are the 16-bit value 55 (0x0037) stored in
little-endian byte order: low byte first (0x37), high byte second (0x00).

---

## Little-Endian Byte Order

The MSP430 is little-endian: when a 16-bit word is stored in memory, the low
byte goes at the lower address, high byte at the higher address.

Example: storing 0xABCD at address 0x0200:
```
Address 0x0200: 0xCD   (low byte)
Address 0x0201: 0xAB   (high byte)
```

So `md 0x0200 2` shows: `CD AB`

This is important when reading mspdebug memory dumps — byte pairs appear
reversed compared to what you might expect.

---

## Common Mistakes

**Forgetting -x assembler-with-cpp**
```
minimal.s:1: error: no such instruction: `#include "..."'
```
Fix: ensure your Makefile has `-x assembler-with-cpp` in CFLAGS.

**Wrong include path**
```
../../common/msp430g2552-defs.s: No such file or directory
```
Fix: count the directory levels. Files in `examples/` need `../../common/`.
Files in `exercises/ex1/` need `../../../common/`.

**Using .w suffix on 8-bit peripheral registers** GPIO registers (P1DIR, P1OUT,
P1IN) are 8 bits. Using `.w` reads/writes two adjacent registers at once,
causing unexpected behavior. Always use `.b` for GPIO operations.

**Forgetting to stop the Watchdog Timer** The Watchdog Timer resets the CPU
every ~32ms by default if not serviced. Your first instruction must always be:
```asm
mov.w   #(WDTPW|WDTHOLD), &WDTCTL
```
If you forget this and your program takes more than 32ms to run, the CPU resets
and runs from the beginning — creating confusing behavior that looks like your
program "works then breaks."
