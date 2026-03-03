#!/bin/sh
#==============================================================================
# vm-setup.sh — MSP430G2552 development environment bootstrap
#
# Run this INSIDE the Linux VM (Alpine or Debian/Ubuntu) after first boot.
# It installs the complete MSP430 toolchain, mspdebug, and configures USB.
#
# Usage:
#   sh /mnt/share/vm-setup.sh
#
# Tested on: Alpine Linux 3.19+ (aarch64), Debian 12, Ubuntu 22.04
#==============================================================================

set -e

BANNER="
╔══════════════════════════════════════════════════════════╗
║     MSP430G2552 Development Environment Setup           ║
╚══════════════════════════════════════════════════════════╝"
echo "$BANNER"

#------------------------------------------------------------------------------
# Detect distro
#------------------------------------------------------------------------------
if [ -f /etc/alpine-release ]; then
    DISTRO="alpine"
elif [ -f /etc/debian_version ]; then
    DISTRO="debian"
elif [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO="$ID"
else
    DISTRO="unknown"
fi
echo "[INFO] Detected distro: $DISTRO"

#==============================================================================
# ALPINE LINUX
#==============================================================================
if [ "$DISTRO" = "alpine" ]; then
    echo ""
    echo "[1/7] Updating Alpine package index..."

    # Enable the community repository — picocom, sudo, and gcc-msp430
    # live there on most Alpine releases.
    ALPINE_VER=$(cut -d. -f1,2 /etc/alpine-release 2>/dev/null || echo "3.19")
    if ! grep -q '^http.*community' /etc/apk/repositories 2>/dev/null; then
        if grep -q 'community' /etc/apk/repositories 2>/dev/null; then
            # Uncomment an existing commented-out community line
            sed -i '/community/s/^#//' /etc/apk/repositories
            echo "      Enabled community repo (was commented out)"
        else
            # Repos file is empty or missing main/community — write both
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
    apk add --no-cache \
        gcc-msp430 \
        msp430-libc \
        binutils-msp430 \
        || {
            echo "[WARN] gcc-msp430 not found in standard repos, trying community..."
            apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/community \
                gcc-msp430 msp430-libc binutils-msp430
        }

    echo "[4/7] Installing mspdebug dependencies..."
    apk add --no-cache libusb-dev libusb-compat-dev readline-dev

    echo "[5/7] Building mspdebug from source..."
    cd /tmp
    rm -rf mspdebug
    git clone --depth=1 https://github.com/dlbeer/mspdebug.git
    cd mspdebug
    make
    make install PREFIX=/usr/local
    cd /
    rm -rf /tmp/mspdebug

    PKG_MANAGER="apk"

#==============================================================================
# DEBIAN / UBUNTU
#==============================================================================
elif [ "$DISTRO" = "debian" ] || [ "$DISTRO" = "ubuntu" ]; then
    echo ""
    echo "[1/7] Updating package lists..."
    apt-get update -qq

    echo "[2/7] Installing build tools..."
    apt-get install -y --no-install-recommends \
        build-essential \
        git \
        vim \
        tmux \
        curl \
        wget \
        make \
        sudo \
        usbutils \
        picocom \
        screen \
        python3 \
        ca-certificates

    echo "[3/7] Installing MSP430 GCC toolchain..."
    # Enable universe repo on Ubuntu
    if [ "$DISTRO" = "ubuntu" ]; then
        apt-get install -y --no-install-recommends software-properties-common 2>/dev/null || true
        add-apt-repository -y universe 2>/dev/null || true
        apt-get update -qq
    fi
    if apt-get install -y --no-install-recommends \
            gcc-msp430 binutils-msp430 msp430-libc; then
        echo "      MSP430 toolchain installed"
    else
        # gcc-msp430 packages in Debian/Ubuntu are amd64-only.
        # On ARM64 hosts we build the toolchain from source.
        echo "[WARN] gcc-msp430 not available via apt (amd64-only package)."
        echo "       Building msp430-elf-gcc from source (~30 min)..."
        apt-get install -y --no-install-recommends \
            libgmp-dev libmpfr-dev libmpc-dev \
            texinfo bison flex xz-utils
        BINUTILS_VER=2.43.1
        GCC_VER=13.3.0
        MSP_PREFIX=/usr/local
        MSP_TARGET=msp430-elf
        MSP_JOBS=$(nproc)
        MSP_BD=$(mktemp -d /var/tmp/msp430-build.XXXXXX)
        (
            cd "$MSP_BD"
            # binutils
            wget -q "https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VER}.tar.xz"
            tar xf "binutils-${BINUTILS_VER}.tar.xz"
            mkdir b-bu && cd b-bu
            "../binutils-${BINUTILS_VER}/configure" \
                --target=$MSP_TARGET --prefix=$MSP_PREFIX \
                --disable-nls --disable-werror --quiet
            make -j$MSP_JOBS && make install
            cd "$MSP_BD"
            # GCC (C only — sufficient for assembly course)
            wget -q "https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VER}/gcc-${GCC_VER}.tar.xz"
            tar xf "gcc-${GCC_VER}.tar.xz"
            mkdir b-gcc && cd b-gcc
            "../gcc-${GCC_VER}/configure" \
                --target=$MSP_TARGET --prefix=$MSP_PREFIX \
                --enable-languages=c --disable-nls --disable-werror \
                --with-newlib --without-headers \
                --disable-shared --disable-threads \
                --disable-libssp --disable-libgomp \
                --disable-libquadmath --quiet
            make -j$MSP_JOBS all-gcc all-target-libgcc
            make install-gcc install-target-libgcc
        )
        rm -rf "$MSP_BD"
        ln -sf "$MSP_PREFIX/bin/msp430-elf-gcc" \
            "$MSP_PREFIX/bin/msp430-gcc" 2>/dev/null || true
        echo "      msp430-elf-gcc build complete"
    fi

    echo "[4/7] Installing mspdebug dependencies..."
    apt-get install -y --no-install-recommends \
        libusb-dev \
        libreadline-dev \
        pkg-config

    echo "[5/7] Building mspdebug from source..."
    cd /tmp
    rm -rf mspdebug
    git clone --depth=1 https://github.com/dlbeer/mspdebug.git
    cd mspdebug
    make
    make install PREFIX=/usr/local
    cd /
    rm -rf /tmp/mspdebug

    PKG_MANAGER="apt"

else
    echo "[ERROR] Unsupported distro: $DISTRO"
    echo "        Supported: Alpine, Debian, Ubuntu"
    exit 1
fi

#==============================================================================
# Toolchain compatibility shim
#
# Alpine/Debian's gcc-msp430 package may provide either:
#   msp430-gcc  (older packages)
#   msp430-elf-gcc  (newer packages)
#
# The course Makefiles auto-detect both. This section creates a symlink
# so both names work, just in case.
#==============================================================================
echo "[6/7] Verifying toolchain..."

# Find whichever binary exists
if which msp430-elf-gcc >/dev/null 2>&1; then
    GCC_BIN=$(which msp430-elf-gcc)
    echo "      Found: msp430-elf-gcc at $GCC_BIN"
    # Create msp430-gcc symlink if missing
    if ! which msp430-gcc >/dev/null 2>&1; then
        ln -sf "$GCC_BIN" /usr/local/bin/msp430-gcc
        echo "      Created symlink: msp430-gcc → msp430-elf-gcc"
    fi
elif which msp430-gcc >/dev/null 2>&1; then
    GCC_BIN=$(which msp430-gcc)
    echo "      Found: msp430-gcc at $GCC_BIN"
    # Create msp430-elf-gcc symlink
    ln -sf "$GCC_BIN" /usr/local/bin/msp430-elf-gcc
    # Also create the other binutils symlinks
    for tool in as ld objcopy objdump nm size strip; do
        if which msp430-$tool >/dev/null 2>&1 && ! which msp430-elf-$tool >/dev/null 2>&1; then
            ln -sf "$(which msp430-$tool)" /usr/local/bin/msp430-elf-$tool
        fi
    done
    echo "      Created symlinks: msp430-elf-* → msp430-*"
else
    echo "      [ERROR] No MSP430 GCC found! Package installation may have failed."
    echo "              Try manually: apk add gcc-msp430  OR  apt-get install gcc-msp430"
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
    if [ "$DISTRO" = "alpine" ]; then
        adduser -D -s /bin/bash dev
    else
        adduser --disabled-password --gecos "" --shell /bin/bash dev
    fi
    echo "      Created user: dev"
fi

# Sudo access
echo "dev ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/dev
chmod 0440 /etc/sudoers.d/dev

# Shell workaround for GNU Make flock() incompatibility with 9p/VirtFS.
# Make tries to flock() the Makefile; 9p returns EAGAIN. This function
# copies the Makefile to /var/tmp before invoking the real make binary.
cat >> /home/dev/.bashrc << 'BASHRC_EOF'

# Workaround: GNU Make flock() fails on 9p/VirtFS (UTM shared folder).
make() {
    if [ -f "Makefile" ]; then
        local _mf
        _mf=$(mktemp /var/tmp/Makefile.XXXXXX)
        cp "Makefile" "$_mf"
        command make -f "$_mf" "$@"
        local _ret=$?
        rm -f "$_mf"
        return $_ret
    else
        command make "$@"
    fi
}
BASHRC_EOF

# USB rules for Texas Instruments LaunchPad
cat > /etc/udev/rules.d/71-ti-launchpad.rules << 'UDEV_EOF'
# MSP430 LaunchPad / eZ430 USB permissions
# Vendor 0451 = Texas Instruments, Vendor 2047 = Texas Instruments (alternate)
SUBSYSTEM=="usb", ATTR{idVendor}=="0451", ATTR{idProduct}=="f432", MODE="0666", GROUP="plugdev"
SUBSYSTEM=="usb", ATTR{idVendor}=="0451", ATTR{idProduct}=="f430", MODE="0666", GROUP="plugdev"
SUBSYSTEM=="usb", ATTR{idVendor}=="2047", ATTR{idProduct}=="0010", MODE="0666", GROUP="plugdev"
SUBSYSTEM=="usb", ATTR{idVendor}=="2047", ATTR{idProduct}=="0013", MODE="0666", GROUP="plugdev"
SUBSYSTEM=="usb", ATTR{idVendor}=="2047", ATTR{idProduct}=="0014", MODE="0666", GROUP="plugdev"
UDEV_EOF

# Add dev user to relevant groups
for grp in plugdev dialout uucp tty; do
    if [ "$DISTRO" = "alpine" ]; then
        addgroup dev $grp 2>/dev/null || true
    else
        usermod -aG $grp dev 2>/dev/null || true
    fi
done
echo "      Added dev to USB groups"

# Create course directory mount point (shared from Mac via VirtFS/9p)
SHARE_MOUNT="/home/dev/msp430-dev-vm"
mkdir -p "$SHARE_MOUNT"
chown dev:dev "$SHARE_MOUNT"

# Add fstab entry for auto-mount on boot.
# UTM exposes the shared directory as a 9p device named "share".
# nofail: boot succeeds even if VM started without sharing enabled.
FSTAB_LINE="share  $SHARE_MOUNT  9p  trans=virtio,version=9p2000.L,rw,cache=loose,_netdev,nofail  0  0"
if ! grep -qF "$SHARE_MOUNT" /etc/fstab; then
    echo "$FSTAB_LINE" >> /etc/fstab
    echo "      Added fstab entry for $SHARE_MOUNT"
else
    echo "      fstab entry already present for $SHARE_MOUNT"
fi

# Ensure the 9p kernel module loads at boot
if [ "$DISTRO" != "alpine" ]; then
    echo "9p"       >> /etc/modules-load.d/virtfs.conf 2>/dev/null || true
    echo "9pnet"    >> /etc/modules-load.d/virtfs.conf 2>/dev/null || true
    echo "9pnet_virtio" >> /etc/modules-load.d/virtfs.conf 2>/dev/null || true
fi

# Helper script the user can call manually if needed
cat > /usr/local/bin/mount-share << 'MOUNT_EOF'
#!/bin/sh
# Manually mount the Mac shared directory (if not auto-mounted).
MOUNT=/home/dev/msp430-dev-vm
if mountpoint -q "$MOUNT"; then
    echo "Already mounted at $MOUNT"
else
    sudo mount -t 9p -o trans=virtio,version=9p2000.L,cache=loose share "$MOUNT" \
        && echo "Mounted at $MOUNT" \
        || echo "Mount failed — ensure UTM Directory Sharing is enabled"
fi
MOUNT_EOF
chmod +x /usr/local/bin/mount-share

# Welcome message
cat > /etc/motd << 'MOTD_EOF'

  ╔══════════════════════════════════════════════════════════════╗
  ║         MSP430G2552 Development Environment Ready           ║
  ╠══════════════════════════════════════════════════════════════╣
  ║  Course files: ~/msp430-dev-vm/course/                      ║
  ║  Compiler:     msp430-elf-gcc  (or msp430-gcc)              ║
  ║  Flasher:      mspdebug rf2500                              ║
  ║  Serial:       picocom -b 9600 /dev/ttyACM0                 ║
  ║                                                             ║
  ║  Build:   cd ~/msp430-dev-vm/course/lesson-01-*/examples    ║
  ║           make                                              ║
  ║  Flash:   make flash   (LaunchPad must be USB-passed-thru)  ║
  ║  Re-mount share if missing:  mount-share                    ║
  ╚══════════════════════════════════════════════════════════════╝

MOTD_EOF

#==============================================================================
# Quick sanity check build
#==============================================================================
echo ""
echo "Running quick build test..."

TEST_DIR=$(mktemp -d)
cat > "$TEST_DIR/test.s" << 'TEST_EOF'
#include <msp430.h>
        .text
        .global main
main:   mov.w   #(WDTPW|WDTHOLD), &WDTCTL
halt:   jmp     halt
        .end
TEST_EOF

# Try both compiler names
for CC in msp430-elf-gcc msp430-gcc; do
    if which $CC >/dev/null 2>&1; then
        if $CC -mmcu=msp430g2552 -x assembler-with-cpp "$TEST_DIR/test.s" -o "$TEST_DIR/test.elf" 2>/dev/null; then
            SIZE_OUT=""
            for SZ in msp430-elf-size msp430-size; do
                if which $SZ >/dev/null 2>&1; then
                    SIZE_OUT=$($SZ "$TEST_DIR/test.elf" 2>/dev/null || true)
                    break
                fi
            done
            echo "  [OK] Test compile succeeded using $CC"
            [ -n "$SIZE_OUT" ] && echo "       $SIZE_OUT"
        else
            echo "  [WARN] Test compile failed with $CC — check include paths"
            echo "         Trying with explicit include..."
            if $CC -mmcu=msp430g2552 -x assembler-with-cpp -I/usr/msp430/include "$TEST_DIR/test.s" -o "$TEST_DIR/test.elf" 2>&1; then
                echo "  [OK] Works with -I/usr/msp430/include"
                echo "       Add this flag to Makefiles if needed"
            fi
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
echo "Next steps:"
echo "  1. Reboot:  sudo reboot"
echo "  2. Log in as 'dev'"
echo "  3. Mount shared folder (from macOS ~/Documents/msp430-dev-vm):"
echo "     sudo mkdir -p /mnt/share"
echo "     sudo mount -t 9p share /mnt/share -o trans=virtio"
echo "  4. Copy course files:"
echo "     cp -r /mnt/share/course ~/course"
echo "  5. Connect LaunchPad via USB"
echo "  6. In UTM: VM Settings > USB > share the Texas Instruments device"
echo "  7. Verify:  lsusb | grep -i texas"
echo "  8. Build first lesson:"
echo "     cd ~/course/lesson-01-architecture/examples"
echo "     make"
echo ""
