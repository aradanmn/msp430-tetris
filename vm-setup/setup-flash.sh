#!/bin/bash
#==============================================================================
# setup-flash.sh
#
# Enables "make flash" for the MSP430 LaunchPad eZ-FET lite (USB 2047:0013)
# on the Alpine Linux QEMU VM.
#
# Background
# ──────────
# The LaunchPad Rev 1.5 uses an eZ-FET lite debugger (VID:PID 2047:0013).
# "mspdebug rf2500" does NOT support it.  Two drivers do:
#
#   tilib  — uses TI's MSP430 Debug Stack (libmsp430.so, compiled from source)
#             Full-featured; preferred when it builds.
#   ezfet  — built-in driver added in mspdebug 0.25 (already in your binary)
#             No compilation needed; works on Alpine musl libc.
#
# NOTE: libmsp430.so is unlikely to compile on Alpine (musl libc lacks
# execinfo.h used by the Debug Stack).  This script tries anyway, then
# falls back to ezfet, which is fully functional for "make flash".
#
# What this script does:
#   1. Installs hidapi-dev, cmake, pkgconf, unzip, eudev
#   2. Starts eudev so udev rules apply (VM was using mdev by default)
#   3. Adds hidraw udev rule for libmsp430.so HIDAPI path
#   4. Builds libmsp430.so from TI MSP430 Debug Stack source (may fail on musl)
#   5. Selects ezfet fallback if build fails
#   6. Configures library path (/etc/ld-musl-aarch64.path) if tilib was built
#   7. Updates all ~/course Makefiles to use the working driver
#   8. Tests the connection if LaunchPad is already attached
#
# Run as dev (not root) — uses passwordless sudo when needed.
# Runtime: ~5 min if ezfet; ~15 min if libmsp430.so builds successfully.
#
# Usage:
#   # Boot the VM with LaunchPad USB passed through (see QEMU command below)
#   # SSH in as dev, then:
#   chmod +x ~/setup-flash.sh
#   ./setup-flash.sh
#   sudo reboot
#   # Replug LaunchPad, test: mspdebug ezfet exit
#==============================================================================
set -euo pipefail

COURSE_DIRS=("${HOME}/course" "${HOME}/msp430-dev-vm/course")
BUILD_DIR="${HOME}/msp430-tilib-build"
LIB_DIR="/usr/local/lib"
DRIVER=""

# ── colour helpers ──────────────────────────────────────────────────────────
_G='\033[0;32m'; _Y='\033[1;33m'; _R='\033[0;31m'; _N='\033[0m'
step()  { echo -e "\n${_G}==> $*${_N}"; }
info()  { echo    "    $*"; }
warn()  { echo -e "${_Y}    WARN: $*${_N}"; }
ok()    { echo -e "${_G}    OK: $*${_N}"; }

# ══════════════════════════════════════════════════════════════════════════════
# STEP 1 — Install additional packages
# ══════════════════════════════════════════════════════════════════════════════
step "Installing additional packages..."
sudo apk add --no-cache \
    hidapi-dev \
    cmake \
    pkgconf \
    unzip \
    eudev
ok "Packages installed."

# ══════════════════════════════════════════════════════════════════════════════
# STEP 2 — Enable eudev
#
# Alpine's virt install uses mdev (BusyBox) by default, so udev rules are
# written to disk but never applied.  Switch to eudev so the TI rules take
# effect and /dev/bus/usb/* and /dev/hidraw* get the right permissions.
# ══════════════════════════════════════════════════════════════════════════════
step "Enabling eudev service..."

# Remove mdev from sysinit to avoid conflicts (ignore errors if absent)
sudo rc-update del mdev sysinit 2>/dev/null || true

if ! rc-update show default 2>/dev/null | grep -q "udev" && \
   ! rc-update show sysinit 2>/dev/null | grep -q "udev"; then
    sudo rc-update add udev sysinit
    sudo rc-update add udev-trigger sysinit
    sudo rc-update add udev-settle sysinit
    info "Added eudev to sysinit runlevel."
    info "Device permission rules will be active after reboot."
else
    info "eudev already in runlevel — skipping."
fi

# Add comprehensive hidraw rule (not in vm-setup.sh's basic rule file)
sudo tee /etc/udev/rules.d/72-ti-hidraw.rules > /dev/null << 'UDEV'
# TI eZ-FET lite — hidraw node access (needed by libmsp430.so / HIDAPI)
KERNEL=="hidraw*", ATTRS{idVendor}=="2047", MODE="0664", GROUP="plugdev"
UDEV

# Attempt a live reload if eudev is already running
if sudo udevadm control --reload-rules 2>/dev/null; then
    sudo udevadm trigger 2>/dev/null || true
    info "udev rules reloaded."
else
    info "eudev not yet running — rules will load after reboot."
fi

ok "eudev configured."

# ══════════════════════════════════════════════════════════════════════════════
# STEP 3 — Build libmsp430.so from TI MSP430 Debug Stack
#
# NOTE: This step commonly fails on Alpine (musl libc) because the Debug Stack
# uses execinfo.h (backtrace), which is a glibc extension unavailable in musl.
# The script will fall through to the ezfet driver in that case.
# ══════════════════════════════════════════════════════════════════════════════
step "Attempting to build TI MSP430 Debug Stack → libmsp430.so ..."
info "(Likely to fail on Alpine musl — will use ezfet fallback if so)"

TILIB_BUILT=false
LIBMSP430=""
SOURCE_DIR=""

rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# ── Try SourceForge (authoritative upstream) ──────────────────────────────
SF_URL="https://sourceforge.net/projects/mspds/files/MSPDebugStack_OS_Package_3_15_1_1.zip/download"
info "Downloading from SourceForge..."
if wget -q --show-progress -L --timeout=30 \
        -O "${BUILD_DIR}/debugstack.zip" \
        "${SF_URL}" 2>&1 \
   && [ -s "${BUILD_DIR}/debugstack.zip" ]; then
    info "Extracting..."
    unzip -q "${BUILD_DIR}/debugstack.zip" -d "${BUILD_DIR}/sf-src" 2>/dev/null || true
    FOUND_MAKE=$(find "${BUILD_DIR}/sf-src" -name "Makefile" -print -quit 2>/dev/null || true)
    FOUND_CMAKE=$(find "${BUILD_DIR}/sf-src" -name "CMakeLists.txt" -print -quit 2>/dev/null || true)
    if   [ -n "${FOUND_MAKE}" ];  then SOURCE_DIR=$(dirname "${FOUND_MAKE}")
    elif [ -n "${FOUND_CMAKE}" ]; then SOURCE_DIR=$(dirname "${FOUND_CMAKE}")
    fi
fi

# ── Fallback: GitHub mirror ───────────────────────────────────────────────
if [ -z "${SOURCE_DIR}" ]; then
    warn "SourceForge unavailable — trying GitHub mirror..."
    for GH_URL in \
        "https://github.com/nicowillis/MSP430DebugStack.git" \
        "https://github.com/czietz/msp430-debugstack.git"
    do
        info "Cloning ${GH_URL} ..."
        if GIT_TERMINAL_PROMPT=0 git clone --depth=1 "${GH_URL}" "${BUILD_DIR}/gh-src" 2>&1 | tail -2; then
            SOURCE_DIR="${BUILD_DIR}/gh-src"
            break
        fi
        rm -rf "${BUILD_DIR}/gh-src"
    done
fi

# ── Attempt Makefile build ────────────────────────────────────────────────
if [ -n "${SOURCE_DIR}" ]; then
    info "Source at: ${SOURCE_DIR}"
    cd "${SOURCE_DIR}"

    if [ -f Makefile ]; then
        info "Makefile build (attempting STATIC=0)..."
        # Suppress the full error log — we expect this to fail on musl.
        if make -j"$(nproc)" STATIC=0 2>"${BUILD_DIR}/build.log" || \
           make -j"$(nproc)"          2>>"${BUILD_DIR}/build.log"; then
            LIBMSP430=$(find "${SOURCE_DIR}" -name "libmsp430.so" -print -quit 2>/dev/null || true)
        fi
    fi

    # ── cmake fallback (only if Makefile produced nothing) ────────────────
    if [ -z "${LIBMSP430}" ] && [ -f CMakeLists.txt ]; then
        info "Trying cmake build (installs boost-dev — this is large)..."
        sudo apk add --no-cache boost-dev
        cmake -B "${BUILD_DIR}/cmake-out" \
              -DCMAKE_BUILD_TYPE=Release \
              -DBUILD_SHARED_LIBS=ON \
              -DCMAKE_C_FLAGS="-fPIC" \
              -DCMAKE_CXX_FLAGS="-fPIC" \
              2>"${BUILD_DIR}/cmake.log" \
        && cmake --build "${BUILD_DIR}/cmake-out" \
                 -j"$(nproc)" \
                 2>>"${BUILD_DIR}/cmake.log" || true
        LIBMSP430=$(find "${BUILD_DIR}/cmake-out" -name "libmsp430.so" -print -quit 2>/dev/null || true)
    fi

    if [ -n "${LIBMSP430}" ]; then
        sudo cp "${LIBMSP430}" "${LIB_DIR}/libmsp430.so"
        ok "Installed: ${LIB_DIR}/libmsp430.so"
        TILIB_BUILT=true
    else
        warn "libmsp430.so did not build (expected on Alpine musl — see ${BUILD_DIR}/build.log)."
    fi

    cd "${HOME}"
fi

# ══════════════════════════════════════════════════════════════════════════════
# STEP 4 — Select flash driver
# ══════════════════════════════════════════════════════════════════════════════
if $TILIB_BUILT; then
    DRIVER="tilib"
    step "Driver selected: mspdebug tilib  (libmsp430.so installed)"

    # Alpine musl: ldconfig doesn't scan /usr/local/lib by default.
    # Add it to the musl dynamic linker search path.
    ARCH=$(uname -m)           # e.g. aarch64
    MUSL_PATH="/etc/ld-musl-${ARCH}.path"
    if ! grep -qF "${LIB_DIR}" "${MUSL_PATH}" 2>/dev/null; then
        echo "${LIB_DIR}" | sudo tee -a "${MUSL_PATH}" > /dev/null
        info "Added ${LIB_DIR} to ${MUSL_PATH}"
    fi

    # Belt-and-suspenders: also set LD_LIBRARY_PATH in .bashrc
    if ! grep -q "msp430.*tilib\|LD_LIBRARY_PATH.*${LIB_DIR}" "${HOME}/.bashrc" 2>/dev/null; then
        cat >> "${HOME}/.bashrc" << 'BASHRC'

# MSP430 Debug Stack — libmsp430.so search path for mspdebug tilib
export LD_LIBRARY_PATH="/usr/local/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
BASHRC
        info "Added LD_LIBRARY_PATH to ~/.bashrc"
    fi
    export LD_LIBRARY_PATH="${LIB_DIR}${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"

else
    DRIVER="ezfet"
    warn "Falling back to mspdebug ezfet (zero-dependency built-in driver)."
    info "ezfet fully supports the eZ-FET lite (2047:0013) for programming."
    step "Driver selected: mspdebug ezfet"
fi

# ══════════════════════════════════════════════════════════════════════════════
# STEP 5 — Update ~/course Makefiles
# ══════════════════════════════════════════════════════════════════════════════
step "Updating Makefiles → mspdebug ${DRIVER} ..."
TOTAL_UPDATED=0
for COURSE_DIR in "${COURSE_DIRS[@]}"; do
    if [ -d "${COURSE_DIR}" ]; then
        UPDATED=0
        while IFS= read -r -d '' mf; do
            if grep -q "mspdebug" "${mf}" 2>/dev/null; then
                sed -i \
                    -e "s|mspdebug rf2500|mspdebug ${DRIVER}|g" \
                    -e "s|mspdebug tilib|mspdebug ${DRIVER}|g" \
                    -e "s|mspdebug ezfet|mspdebug ${DRIVER}|g" \
                    "${mf}"
                UPDATED=$((UPDATED + 1))
            fi
        done < <(find "${COURSE_DIR}" -name "Makefile" -print0 2>/dev/null)
        ok "Updated ${UPDATED} Makefile(s) in ${COURSE_DIR}"
        TOTAL_UPDATED=$((TOTAL_UPDATED + UPDATED))
    fi
done
if [ "${TOTAL_UPDATED}" -eq 0 ]; then
    warn "No course directories found — sync course files first, then re-run this script."
    info "rsync: rsync -av ~/Documents/msp430-dev-vm/course/ dev@<vm-ip>:~/course/"
fi

# ══════════════════════════════════════════════════════════════════════════════
# STEP 6 — Update /etc/motd
# ══════════════════════════════════════════════════════════════════════════════
sudo sed -i "s|mspdebug rf2500|mspdebug ${DRIVER}|g" /etc/motd 2>/dev/null || true

# ══════════════════════════════════════════════════════════════════════════════
# STEP 7 — Connection test (non-fatal)
# ══════════════════════════════════════════════════════════════════════════════
step "Testing USB connection (non-fatal — device may not be attached yet)..."
if lsusb 2>/dev/null | grep -qE "2047:0013|2047:0010"; then
    info "LaunchPad detected on USB ✓"
    if timeout 8 mspdebug "${DRIVER}" "exit" 2>&1; then
        ok "mspdebug ${DRIVER} connected successfully ✓"
    else
        warn "mspdebug test failed — see 'After reboot' instructions below."
        warn "Permission errors are normal until eudev is running (after reboot)."
    fi
else
    info "LaunchPad not detected on USB (that's fine at this stage)."
fi

# ══════════════════════════════════════════════════════════════════════════════
# DONE
# ══════════════════════════════════════════════════════════════════════════════
echo
printf "${_G}%s${_N}\n" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "${_G}  setup-flash.sh complete!  Flash driver: mspdebug %s${_N}\n" "${DRIVER}"
printf "${_G}%s${_N}\n" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
echo "  Steps to finish:"
echo ""
echo "  1.  Reboot the VM to start eudev (device permission rules):"
echo "        sudo reboot"
echo ""
echo "  2.  Start QEMU with LaunchPad passed through (on your Mac):"
echo "        VM=~/Documents/msp430-dev-vm/vm"
echo "        sudo /opt/homebrew/bin/qemu-system-aarch64 \\"
echo "          -machine virt,highmem=on -accel hvf -cpu host -smp 2 -m 2048 \\"
echo "          -drive if=pflash,format=raw,readonly=on,file=/opt/homebrew/share/qemu/edk2-aarch64-code.fd \\"
echo "          -drive if=pflash,format=raw,file=\"\$VM/efi_vars.fd\" \\"
echo "          -drive file=\"\$VM/msp430-dev.img\",if=virtio,format=raw \\"
echo "          -netdev user,id=net0,hostfwd=tcp::5022-:22 \\"
echo "          -device virtio-net-pci,netdev=net0 \\"
echo "          -device usb-ehci,id=ehci \\"
echo "          -device usb-host,bus=ehci.0,vendorid=0x2047,productid=0x0013 \\"
echo "          -nographic &"
echo ""
echo "  3.  SSH back in and test:"
echo "        ssh -p 5022 dev@127.0.0.1"
echo "        mspdebug ${DRIVER} exit"
echo ""
echo "  4.  Flash your first program:"
echo "        cd ~/course/lesson-01-architecture/examples"
echo "        make flash"
echo ""
if [ "${DRIVER}" = "tilib" ]; then
    echo "  Troubleshooting tilib:"
    echo "    • 'libmsp430.so: not found'  →  run: source ~/.bashrc"
    echo "    • Still failing?  Try the built-in driver:"
    echo "        mspdebug ezfet exit"
else
    echo "  If you later want to try tilib (more complete debug features):"
    echo "    Build the MSP430 Debug Stack manually from:"
    echo "    https://sourceforge.net/projects/mspds/"
    echo "    then: sudo cp libmsp430.so /usr/local/lib/ && re-run this script"
fi
echo ""
