#!/bin/sh
#==============================================================================
# install-msp430-support.sh
#
# Installs MSP430 device support files for a from-source msp430-elf-gcc build:
#   - Linker scripts for msp430g2552 and msp430g2553
#   - devices.csv MCU database
#   - Symlinks so both MCU names work
#
# Run as root in the VM.  Takes < 5 seconds.
#==============================================================================
set -e

GCC_VER=$(msp430-elf-gcc -dumpversion 2>/dev/null) || {
    echo "ERROR: msp430-elf-gcc not found in PATH"; exit 1; }

# Detect actual GCC data directory from the compiler — works whether GCC was
# installed via package manager (/usr/lib/gcc/msp430-elf/VERSION) or built
# from source (/usr/local/lib/gcc/msp430-elf/VERSION).
GCCDATA=$(dirname "$(msp430-elf-gcc -print-libgcc-file-name 2>/dev/null)")

# Derive install prefix: 4 levels up from GCCDATA (lib/gcc/msp430-elf/VERSION)
PREFIX=$(cd "$GCCDATA/../../../.." && pwd)
LDDIR="$PREFIX/msp430-elf/lib"

echo "==> msp430-elf-gcc $GCC_VER"
echo "    GCC data dir : $GCCDATA"
echo "    LD script dir: $LDDIR"

# GCC searches for devices.csv next to the cc1 binary.  On Alpine Linux,
# cc1 may live in /usr/lib/gcc/msp430-elf/VERSION/ (same as libgcc.a) or
# in /usr/libexec/gcc/msp430-elf/VERSION/ (separate libexec tree).
# We write devices.csv to EVERY likely location to avoid path ambiguity.
CC1_FULL=$(msp430-elf-gcc -print-prog-name=cc1 2>/dev/null || true)

# Always derive the libexec equivalent path and create it.
# Even if the directory does not yet exist, GCC may resolve cc1 via
# a symlink whose realpath() lands in libexec rather than lib.
LIBEXEC_DIR=$(echo "$GCCDATA" | sed 's|/lib/gcc/|/libexec/gcc/|')

mkdir -p "$GCCDATA" "$LDDIR"
[ "$LIBEXEC_DIR" != "$GCCDATA" ] && mkdir -p "$LIBEXEC_DIR"

# Collect extra directories where we should also place devices.csv
EXTRA_DIRS=""
[ "$LIBEXEC_DIR" != "$GCCDATA" ] && EXTRA_DIRS="$LIBEXEC_DIR"

# If -print-prog-name=cc1 returned an absolute path and its directory
# differs from the ones we already have, add it too.
case "$CC1_FULL" in
    /*)
        CC1_DIR=$(dirname "$CC1_FULL")
        if [ "$CC1_DIR" != "$GCCDATA" ] && [ "$CC1_DIR" != "$LIBEXEC_DIR" ]; then
            mkdir -p "$CC1_DIR"
            EXTRA_DIRS="$EXTRA_DIRS $CC1_DIR"
        fi ;;
esac

echo "==> devices.csv will be written to:"
echo "    $GCCDATA/ (primary)"
for d in $EXTRA_DIRS; do echo "    $d/ (extra)"; done

# ── devices.csv ───────────────────────────────────────────────────────────────
# GCC uses this to look up CPU type, MPY support, and clock info.
# Format: Name,CPU,MPY,EXPA,Clk
#   CPU : 430 (16-bit) | 430X (20-bit extended)
#   MPY : N (none) | 430 (16-bit hw multiply) | 430X (32-bit)
#   EXPA: N (standard 64KB) | Y (extended memory)
#   Clk : max DCO frequency in Hz
cat > "$GCCDATA/devices.csv" << 'EOF'
Name,CPU,MPY,EXPA,Clk
msp430g2001,430,N,N,16000000
msp430g2101,430,N,N,16000000
msp430g2131,430,N,N,16000000
msp430g2201,430,N,N,16000000
msp430g2211,430,N,N,16000000
msp430g2221,430,N,N,16000000
msp430g2231,430,N,N,16000000
msp430g2301,430,N,N,16000000
msp430g2311,430,N,N,16000000
msp430g2321,430,N,N,16000000
msp430g2331,430,N,N,16000000
msp430g2351,430,N,N,16000000
msp430g2402,430,N,N,16000000
msp430g2412,430,N,N,16000000
msp430g2432,430,N,N,16000000
msp430g2444,430,430,N,16000000
msp430g2452,430,N,N,16000000
msp430g2512,430,N,N,16000000
msp430g2532,430,N,N,16000000
msp430g2544,430,430,N,16000000
msp430g2552,430,N,N,16000000
msp430g2553,430,430,N,16000000
msp430g2744,430,430,N,16000000
msp430g2755,430,430,N,16000000
msp430g2855,430,430,N,16000000
msp430g2955,430,430,N,16000000
EOF

# Copy to extra cc1 search directories.
for d in $EXTRA_DIRS; do
    cp "$GCCDATA/devices.csv" "$d/devices.csv"
done

# Confirm the writes.
echo "==> devices.csv written:"
ls -la "$GCCDATA/devices.csv" 2>/dev/null && echo "    ✓  $GCCDATA/devices.csv" || echo "    ✗  FAILED: $GCCDATA/devices.csv"
for d in $EXTRA_DIRS; do
    ls -la "$d/devices.csv" 2>/dev/null && echo "    ✓  $d/devices.csv" || echo "    ✗  FAILED: $d/devices.csv"
done

# ── Linker script writer function ─────────────────────────────────────────────
# Usage: write_ldscript NAME ROM_ORIGIN ROM_LEN_HEX RAM_ORIGIN RAM_LEN_HEX STACK_TOP
write_ldscript() {
    local MCU=$1
    local ROM_ORG=$2   # hex, e.g. 0xE000
    local ROM_LEN=$3   # hex length of code area (excludes 32-byte vector table)
    local RAM_ORG=$4   # hex, e.g. 0x0200
    local RAM_LEN=$5   # hex, e.g. 0x0100
    local STACK=$6     # hex, top of RAM + 2, e.g. 0x0300

    cat > "$LDDIR/${MCU}.ld" << LDEOF
/* ${MCU}.ld — Linker script for msp430-elf-gcc (from-source build)
 *
 *   Code Flash : ${ROM_ORG}–0xFFDF  (${ROM_LEN} bytes)
 *   Vectors    : 0xFFE0–0xFFFF  (32 bytes, 16 interrupt vectors)
 *   RAM        : ${RAM_ORG}–(${RAM_ORG}+${RAM_LEN}-1)  (${RAM_LEN} bytes)
 *   Stack top  : ${STACK}
 *
 * Assembly files use a 16-word sequential .vectors section that the linker
 * places at 0xFFE0.  Do NOT use .org 0xFFFE style with this script.
 */
OUTPUT_FORMAT("elf32-msp430")
OUTPUT_ARCH("msp430")

MEMORY
{
    rom     (rx)  : ORIGIN = ${ROM_ORG}, LENGTH = ${ROM_LEN}
    ram     (rwx) : ORIGIN = ${RAM_ORG}, LENGTH = ${RAM_LEN}
    vectors (rw)  : ORIGIN = 0xFFE0,    LENGTH = 0x0020
}

/* Stack grows downward from top of RAM */
PROVIDE(__stack = ${STACK});

SECTIONS
{
    /* ── code and constants in flash ─────────────────────────────── */
    .text :
    {
        . = ALIGN(2);
        *(.text)
        *(.text.*)
        *(.rodata)
        *(.rodata.*)
        . = ALIGN(2);
        _etext = .;
    } > rom

    /* ── 16-entry interrupt vector table (32 bytes) ──────────────── */
    .vectors :
    {
        KEEP(*(.vectors))
    } > vectors

    /* ── initialized data (stored in flash, copied to RAM) ─────────
     * For most bare-metal assembly programs this section is empty.  */
    .data :
    {
        . = ALIGN(2);
        PROVIDE(_data = .);
        *(.data)
        *(.data.*)
        . = ALIGN(2);
        PROVIDE(_edata = .);
    } > ram AT > rom

    /* ── zero-initialized data ───────────────────────────────────── */
    .bss (NOLOAD) :
    {
        . = ALIGN(2);
        PROVIDE(__bss_start = .);
        *(.bss)
        *(.bss.*)
        *(COMMON)
        . = ALIGN(2);
        PROVIDE(__bss_end = .);
    } > ram

    /* ── DWARF debug sections (optional, not loaded to flash) ─────── */
    .stab          0 : { *(.stab)          }
    .stabstr       0 : { *(.stabstr)       }
    .debug_info    0 : { *(.debug_info)    }
    .debug_abbrev  0 : { *(.debug_abbrev)  }
    .debug_aranges 0 : { *(.debug_aranges) }
    .debug_ranges  0 : { *(.debug_ranges)  }
    .debug_line    0 : { *(.debug_line)    }
    .debug_str     0 : { *(.debug_str)     }
    .debug_frame   0 : { *(.debug_frame)   }
}
LDEOF
    echo "    Wrote $LDDIR/${MCU}.ld"
}

# ── msp430g2552 — 8KB Flash (0xE000–0xFFFF), 256B RAM (0x0200–0x02FF) ────────
echo "==> Writing msp430g2552.ld ..."
write_ldscript msp430g2552 0xE000 0x1FE0 0x0200 0x0100 0x0300

# ── msp430g2553 — 16KB Flash (0xC000–0xFFFF), 512B RAM (0x0200–0x03FF) ───────
echo "==> Writing msp430g2553.ld ..."
write_ldscript msp430g2553 0xC000 0x3FE0 0x0200 0x0200 0x0400

# ── A few more common Value Line chips ────────────────────────────────────────
echo "==> Writing additional linker scripts ..."
# g2452 / g2512: 8KB Flash, 256B RAM  (same as g2552)
write_ldscript msp430g2452 0xE000 0x1FE0 0x0200 0x0100 0x0300
write_ldscript msp430g2512 0xE000 0x1FE0 0x0200 0x0100 0x0300
# g2231 / g2211: 2KB Flash, 128B RAM
write_ldscript msp430g2231 0xF800 0x07E0 0x0200 0x0080 0x0280
write_ldscript msp430g2211 0xF800 0x07E0 0x0200 0x0080 0x0280

# ── Quick compile test ────────────────────────────────────────────────────────
echo "==> Running compile test ..."
TMPF=$(mktemp /var/tmp/msp430_test_XXXXXX)
cat > "$TMPF" << 'TESTEOF'
#define WDTPW   0x5A00
#define WDTHOLD 0x0080
#define WDTCTL  0x0120
        .text
        .global main
main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
halt:
        jmp     halt
        .section ".vectors","ax",@progbits
        .word   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        .word   main
        .end
TESTEOF

TMPELF=$(mktemp /var/tmp/msp430_test_XXXXXX)
if msp430-elf-gcc -mmcu=msp430g2552 -x assembler-with-cpp -nostdlib \
        -o "$TMPELF" "$TMPF" 2>&1; then
    echo "    ✓  msp430g2552 compile+link successful"
    msp430-elf-size "$TMPELF" 2>/dev/null || true
else
    echo "    ✗  compile test FAILED (see messages above)"
fi
rm -f "$TMPF" "$TMPELF"

echo ""
echo "All done!  Now run:"
echo "  rsync -av ~/Documents/msp430-dev-vm/course/ dev@<vm-ip>:~/course/"
echo "  ssh dev@<vm-ip>"
echo "  cd ~/course/lesson-01-architecture/examples && make"
