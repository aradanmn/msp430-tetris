# Tutorial 02 — Toolchain & Workflow

## Overview

Everything runs directly on your Mac — no VM, no rsync, no SSH. Your workflow is:

```
Edit .s files → make → make flash → observe hardware
```

- **Edit** in any text editor (VS Code recommended)
- **Build** in Terminal with `make`
- **Flash** to the LaunchPad via USB with `make flash`
- **Debug** with mspdebug or GDB (covered at the end)

---

## Toolchain Components

| Component | Location | Purpose |
|-----------|----------|---------|
| `msp430-elf-gcc` | `~/ti/msp430-gcc/bin/` | Assembler + linker |
| Device linker scripts | `~/ti/msp430-gcc/include/` | Memory map for G2553 |
| `mspdebug` | `/opt/homebrew/bin/` | Flash programmer + debugger |
| `libmsp430.dylib` | `~/.local/lib/` | TI debug stack (arm64 build) |
| `picocom` | `/opt/homebrew/bin/` | Serial monitor (Lessons 13+) |

If any of these are missing, run `./setup-mac.sh` from the repo root.

---

## Step 1 — Edit

Open any `.s` file in your editor. The course files live under `course/`:

```
course/lesson-01-architecture/examples/blink.s
course/lesson-01-architecture/exercises/ex1/ex1.s
...
```

VS Code with the "MSP430 Assembly" or "ARM Assembly" extension gives reasonable syntax highlighting. Save as plain text with Unix line endings (LF) — VS Code handles this automatically on Mac.

---

## Step 2 — Build

Open Terminal, navigate to the lesson directory, and run `make`:

```sh
cd ~/path/to/repo/course/lesson-01-architecture/examples
make
```

Successful output:
```
/Users/scott/ti/msp430-gcc/bin/msp430-elf-gcc -mmcu=msp430g2553 \
  -x assembler-with-cpp -nostdlib -g -Os -Wall -Wextra \
  -Wl,-L/Users/scott/ti/msp430-gcc/include \
  -Wl,-T,/Users/scott/ti/msp430-gcc/include/msp430g2553.ld \
  -Wl,--section-start=.vectors=0xFFE0 \
  -o blink.elf blink.s
```

If you see errors, check:
- Is the `#include` path correct? Count the `../../` levels carefully.
- Are you using `.b` vs `.w` correctly for 8-bit vs 16-bit registers?
- Are all label names spelled consistently?

---

## Step 3 — Verify the Memory Map

Before flashing, confirm the code is going to the right addresses:

```sh
make disasm
# or:
msp430-elf-objdump -h blink.elf
```

The output should show:
```
.text     VMA 0x0000c000   ← Flash starts here on G2553
.vectors  VMA 0x0000ffe0   ← Interrupt vector table
```

If `.text` shows `0x00008000`, the device linker script isn't being found — check that `~/ti/msp430-gcc/include/msp430g2553.ld` exists.

---

## Step 4 — Flash

Connect the LaunchPad via USB, then:

```sh
make flash
```

This runs:
```sh
DYLD_LIBRARY_PATH=~/.local/lib mspdebug tilib "prog blink.elf"
```

Expected output:
```
MSPDebug version 0.25 ...
Chip ID data: 55 31
Device: MSP430G2553
...
Writing   58 bytes at c000 [section: .text]...
Writing   32 bytes at ffe0 [section: .vectors]...
Done, 90 bytes total
```

**First time only** — if you see `Interface Communication error`, the eZ-FET firmware needs updating:
```sh
DYLD_LIBRARY_PATH=~/.local/lib mspdebug --allow-fw-update tilib "prog blink.elf"
```

This takes about 30 seconds and only needs to happen once.

**If mspdebug can't find the LaunchPad:**
- Check the USB cable is firmly connected
- Run `system_profiler SPUSBDataType | grep -A4 "430"` to confirm it appears
- Try unplugging and re-plugging

---

## Step 5 — Observe

Watch the LaunchPad. LED1 (Red, P1.0) should blink at 1 Hz. The code runs immediately after flashing — no reset button needed.

---

## The Makefile

Every `examples/` and `exercises/exN/` directory has a Makefile. Here's what's in it:

```makefile
TARGET  = blink
MCU     = msp430g2553

# Prefer TI full toolchain (includes device linker scripts)
TI_GCC       := $(HOME)/ti/msp430-gcc/bin/msp430-elf-gcc
GCC          := $(shell test -f $(TI_GCC) && echo $(TI_GCC) || which msp430-elf-gcc 2>/dev/null)
OBJDUMP      := $(patsubst %gcc,%objdump,$(GCC))
LIBMSP430_DIR := $(HOME)/.local/lib
TI_INC       := $(HOME)/ti/msp430-gcc/include

CFLAGS  = -mmcu=$(MCU) -x assembler-with-cpp -nostdlib -g -Os -Wall -Wextra \
          -Wl,-L$(TI_INC) -Wl,-T,$(TI_INC)/$(MCU).ld \
          -Wl,--section-start=.vectors=0xFFE0

all: $(TARGET).elf

$(TARGET).elf: $(TARGET).s
	$(GCC) $(CFLAGS) -o $@ $<

flash: $(TARGET).elf
	DYLD_LIBRARY_PATH=$(LIBMSP430_DIR):$$DYLD_LIBRARY_PATH mspdebug tilib "prog $(TARGET).elf"

disasm: $(TARGET).elf
	$(OBJDUMP) -d $(TARGET).elf

clean:
	rm -f $(TARGET).elf
```

Three linker flags work together to place code correctly:
- `-Wl,-L$(TI_INC)` — adds the TI include directory to the linker's script search path
- `-Wl,-T,...msp430g2553.ld` — explicitly loads the device linker script (places `.text` at 0xC000)
- `-Wl,--section-start=.vectors=0xFFE0` — forces the interrupt vector table to the top of Flash

---

## Debugging

### Quick register/memory check — mspdebug

```sh
DYLD_LIBRARY_PATH=~/.local/lib mspdebug tilib
```

At the `(mspdebug)` prompt:
```
prog blink.elf      # flash
regs                # show all CPU registers
md 0xC000 16        # memory dump: address, word count
setbrk 0xC004       # breakpoint at address
run                 # run until breakpoint or halt
step                # single-step one instruction
halt                # stop execution
exit
```

### Full source-level debugging — GDB

Start the GDB server in one Terminal window:
```sh
DYLD_LIBRARY_PATH=~/.local/lib mspdebug tilib "gdb"
# listens on port 2000
```

Connect GDB in a second Terminal window:
```sh
~/ti/msp430-gcc/bin/msp430-elf-gdb blink.elf
(gdb) target remote :2000
(gdb) load                    # flash the binary
(gdb) break _start            # set a breakpoint at reset entry
(gdb) continue
(gdb) stepi                   # step one instruction
(gdb) info registers          # show all registers
(gdb) x/4xh 0xC000           # examine 4 halfwords at 0xC000
(gdb) disassemble             # disassemble around PC
(gdb) quit
```

The `-g` flag in CFLAGS embeds debug symbols, so GDB shows your assembly source with line numbers as you step.

---

## File Layout Reference

When writing a new `.s` file, adjust the `#include` path based on its directory depth:

| File location | Include path |
|--------------|-------------|
| `examples/*.s` | `#include "../../common/msp430g2553-defs.s"` |
| `exercises/exN/*.s` | `#include "../../../common/msp430g2553-defs.s"` |
| `exercises/exN/solution/*.s` | `#include "../../../../common/msp430g2553-defs.s"` |

Count the directory levels: `examples/` is two levels below the repo root's `course/` directory sibling. `../../` goes up to `lesson-01-architecture/`, then up to `course/`, then down into `common/`.

---

## Next Step

Run the example:

```sh
cd course/lesson-01-architecture/examples
make flash
```

Watch LED1 (Red) blink. Then attempt the exercises in `exercises/`.
