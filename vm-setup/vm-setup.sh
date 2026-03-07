#!/bin/sh
#==============================================================================
# vm-setup.sh — MSP430G2553 development environment bootstrap (Alpine Linux)
#
# Run this INSIDE the Alpine Linux VM as root.
# Called automatically by full-setup.sh — can also be run manually:
#   ssh -p 5022 root@127.0.0.1
#   sh /tmp/vm-setup.sh
#
# Tested on: Alpine Linux 3.23 (aarch64, QEMU on Apple Silicon)
#==============================================================================

set -e

BANNER="
╔══════════════════════════════════════════════════════════╗
║     MSP430G2553 Development Environment Setup           ║
╚══════════════════════════════════════════════════════════╝"
echo "$BANNER"

echo ""
echo "[1/7] Updating Alpine package index..."

# Enable the community repository — gcc-msp430-elf lives there.
ALPINE_VER=$(cut -d. -f1,2 /etc/alpine-release 2>/dev/null || echo "3.23")
if ! grep -q '^http.*community' /etc/apk/repositories 2>/dev/null; then
    if grep -q 'community' /etc/apk/repositories 2>/dev/null; then
        sed -i '/community/s/^#//' /etc/apk/repositories
        echo "      Enabled community repo (was commented out)"
    else
        cat > /etc/apk/repositories << REPOS_EOF
http://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VER}/main
http://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VER}/community
REPOS_EOF
        echo "      Wrote main + community repos for Alpine ${ALPINE_VER}"
    fi
else
    echo "      Community repo already enabled"
fi

apk update

echo "[2/7] Installing build tools..."
apk add --no-cache \
    build-base \
    git \
    vim \
    tmux \
    curl \
    wget \
    make \
    bash \
    sudo \
    openssh \
    usbutils \
    picocom \
    screen \
    python3

echo "[3/7] Installing MSP430 GCC toolchain..."
# Alpine 3.22+ renamed packages: gcc-msp430-elf, binutils-msp430-elf, newlib-msp430-elf
# Alpine <3.22 used: gcc-msp430, binutils-msp430, msp430-libc
if apk add --no-cache gcc-msp430-elf binutils-msp430-elf newlib-msp430-elf 2>/dev/null; then
    echo "      Installed gcc-msp430-elf (Alpine 3.22+ package names)"
elif apk add --no-cache gcc-msp430 msp430-libc binutils-msp430 2>/dev/null; then
    echo "      Installed gcc-msp430 (legacy package names)"
else
    echo "[ERROR] Could not find MSP430 toolchain packages."
    exit 1
fi

echo "[4/7] Installing mspdebug dependencies..."
apk add --no-cache libusb-dev libusb-compat-dev readline-dev linux-headers

echo "[5/7] Building mspdebug from source..."
cd /tmp
rm -rf mspdebug
git clone --depth=1 https://github.com/dlbeer/mspdebug.git
cd mspdebug
make
make install PREFIX=/usr/local
cd /
rm -rf /tmp/mspdebug

#==============================================================================
# Toolchain compatibility shim
#
# Alpine's gcc-msp430 package may provide either:
#   msp430-gcc  (older packages)
#   msp430-elf-gcc  (newer packages)
#
# The course Makefiles auto-detect both. This section creates a symlink
# so both names work.
#==============================================================================
echo "[6/7] Verifying toolchain..."

if which msp430-elf-gcc >/dev/null 2>&1; then
    GCC_BIN=$(which msp430-elf-gcc)
    echo "      Found: msp430-elf-gcc at $GCC_BIN"
    if ! which msp430-gcc >/dev/null 2>&1; then
        ln -sf "$GCC_BIN" /usr/local/bin/msp430-gcc
        echo "      Created symlink: msp430-gcc → msp430-elf-gcc"
    fi
elif which msp430-gcc >/dev/null 2>&1; then
    GCC_BIN=$(which msp430-gcc)
    echo "      Found: msp430-gcc at $GCC_BIN"
    ln -sf "$GCC_BIN" /usr/local/bin/msp430-elf-gcc
    for tool in as ld objcopy objdump nm size strip; do
        if which msp430-$tool >/dev/null 2>&1 && ! which msp430-elf-$tool >/dev/null 2>&1; then
            ln -sf "$(which msp430-$tool)" /usr/local/bin/msp430-elf-$tool
        fi
    done
    echo "      Created symlinks: msp430-elf-* → msp430-*"
else
    echo "      [ERROR] No MSP430 GCC found! Package installation may have failed."
fi

# Verify mspdebug
if which mspdebug >/dev/null 2>&1; then
    echo "      mspdebug: $(mspdebug --version 2>&1 | head -1)"
else
    echo "      [WARN] mspdebug not found in PATH — check /usr/local/bin/"
fi

#==============================================================================
# User setup
#==============================================================================
echo "[7/7] Configuring dev user and permissions..."

# Create 'dev' user if not exists
if ! id -u dev >/dev/null 2>&1; then
    adduser -D -s /bin/bash dev
    echo "      Created user: dev"
fi

# Alpine adduser -D creates a locked account (no password) — sshd rejects
# locked accounts even for pubkey auth. Unlock it.
passwd -u dev 2>/dev/null || true

# Fix home directory permissions — Alpine adduser sets setgid (2755) which
# causes sshd StrictModes to reject pubkey auth.
chmod 755 /home/dev

# Sudo access
echo "dev ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/dev
chmod 0440 /etc/sudoers.d/dev

# USB rules for Texas Instruments LaunchPad (eZ-FET lite, VID:PID 2047:0013)
mkdir -p /etc/udev/rules.d
cat > /etc/udev/rules.d/71-ti-launchpad.rules << 'UDEV_EOF'
# MSP430 LaunchPad eZ-FET lite USB permissions
SUBSYSTEM=="usb", ATTR{idVendor}=="2047", ATTR{idProduct}=="0013", MODE="0666", GROUP="plugdev"
SUBSYSTEM=="usb", ATTR{idVendor}=="2047", ATTR{idProduct}=="0010", MODE="0666", GROUP="plugdev"
SUBSYSTEM=="usb", ATTR{idVendor}=="2047", ATTR{idProduct}=="0014", MODE="0666", GROUP="plugdev"
UDEV_EOF

# Add dev user to relevant groups
for grp in plugdev dialout uucp tty; do
    addgroup dev $grp 2>/dev/null || true
done
echo "      Added dev to USB groups"

# Create course directory (synced from Mac via rsync)
mkdir -p /home/dev/course
chown dev:dev /home/dev/course

# Welcome message
cat > /etc/motd << 'MOTD_EOF'

  ╔══════════════════════════════════════════════════════════════╗
  ║         MSP430G2553 Development Environment Ready           ║
  ╠══════════════════════════════════════════════════════════════╣
  ║  Course files: ~/course/                                     ║
  ║  Compiler:     msp430-elf-gcc  (or msp430-gcc)              ║
  ║  Flasher:      mspdebug tilib                              ║
  ║  Serial:       picocom -b 9600 /dev/ttyACM0                 ║
  ║                                                             ║
  ║  Sync from Mac:                                              ║
  ║    rsync -av course/ dev@127.0.0.1:~/course/ -e 'ssh -p 5022'║
  ║  Build:   cd ~/course/lesson-01-*/examples && make           ║
  ║  Flash:   make flash   (LaunchPad must be USB-passed-thru)  ║
  ╚══════════════════════════════════════════════════════════════╝

MOTD_EOF

#==============================================================================
# Quick sanity check build
#==============================================================================
echo ""
echo "Running quick build test..."

TEST_DIR=$(mktemp -d)
cat > "$TEST_DIR/test.s" << 'TEST_EOF'
#define WDTPW   0x5A00
#define WDTHOLD 0x0080
#define WDTCTL  0x0120
        .text
        .global _start
_start:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL
halt:   jmp     halt
        .section ".vectors","ax",@progbits
        .word   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        .word   _start
        .end
TEST_EOF

for CC in msp430-elf-gcc msp430-gcc; do
    if which $CC >/dev/null 2>&1; then
        if $CC -mmcu=msp430g2553 -x assembler-with-cpp -nostdlib \
               "$TEST_DIR/test.s" -o "$TEST_DIR/test.elf" 2>&1; then
            SIZE_OUT=""
            for SZ in msp430-elf-size msp430-size; do
                if which $SZ >/dev/null 2>&1; then
                    SIZE_OUT=$($SZ "$TEST_DIR/test.elf" 2>/dev/null || true)
                    break
                fi
            done
            echo "  [OK] Test compile succeeded using $CC"
            [ -n "$SIZE_OUT" ] && echo "$SIZE_OUT"
        else
            echo "  [WARN] Test compile failed with $CC — see messages above"
        fi
        break
    fi
done

rm -rf "$TEST_DIR"

#==============================================================================
# Done!
#==============================================================================
echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  Setup complete!                                        ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "Next steps (from your Mac):"
echo "  1. Sync course files:"
echo "     rsync -av ~/Documents/msp430-dev-vm/course/ dev@127.0.0.1:~/course/ -e 'ssh -p 5022'"
echo "  2. SSH in:"
echo "     ./vm.sh ssh"
echo "  3. Build first lesson:"
echo "     cd ~/course/lesson-01-architecture/examples && make"
echo ""
