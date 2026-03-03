#!/bin/bash
#==============================================================================
# setup-flash.sh
#
# Enables "make flash" for the MSP430 LaunchPad eZ-FET lite (USB 2047:0013)
# on ARM64 Debian 12 (bookworm).
#
# Background
# ──────────
# The LaunchPad Rev 1.5 ships with an eZ-FET lite debugger (VID:PID 2047:0013).
# The old "mspdebug rf2500" command only supports the original RF2500 FET
# (0451:f432) and will NOT work with the eZ-FET lite.
#
# Two compatible flash drivers exist in mspdebug:
#   tilib  — uses TI's open-source MSP430 Debug Stack (libmsp430.so)
#             Full-featured; requires compiling the library from source.
#   ezfet  — direct built-in USB driver added in mspdebug 0.25
#             Zero compilation; supports 2047:0013 on Debian 12 out of the box.
#
# This script:
#   1. Installs mspdebug and build dependencies
#   2. Adds udev rules so the eZ-FET is accessible without root
#   3. Adds you to the plugdev / dialout groups
#   4. Tries to build libmsp430.so from TI's open-source Debug Stack
#      (primary path — most complete driver)
#   5. Falls back to the built-in ezfet driver if the build fails
#   6. Updates all ~/course Makefiles to use the working driver
#   7. Prints exactly what to do next
#
# Run time: ~10 minutes on first run (mostly compiling libmsp430.so).
# Run as your normal user — will sudo when needed.
#
# Usage:
#   chmod +x ~/setup-flash.sh
#   ./setup-flash.sh
#   # Unplug + replug LaunchPad, then log out and back in (or: newgrp plugdev)
#==============================================================================
set -euo pipefail

COURSE_DIR="${HOME}/course"
BUILD_DIR="${HOME}/msp430-tilib-build"
LIB_DIR="/usr/local/lib"
DRIVER=""   # will be set to "tilib" or "ezfet"

# ── colour helpers ─────────────────────────────────────────────────────────────
_G='\033[0;32m'; _Y='\033[1;33m'; _R='\033[0;31m'; _N='\033[0m'
step()  { echo -e "\n${_G}==> $*${_N}"; }
info()  { echo    "    $*"; }
warn()  { echo -e "${_Y}    WARN: $*${_N}"; }
ok()    { echo -e "${_G}    OK: $*${_N}"; }

# ══════════════════════════════════════════════════════════════════════════════
# STEP 1 — Install packages
# ══════════════════════════════════════════════════════════════════════════════
step "Installing packages..."
sudo apt-get update -qq
DEBIAN_FRONTEND=noninteractive sudo apt-get install -y \
    mspdebug \
    libhidapi-libusb0 \
    libhidapi-dev \
    libusb-1.0-0-dev \
    cmake \
    git \
    build-essential \
    unzip \
    wget \
    libboost-filesystem-dev \
    libboost-system-dev \
    pkg-config \
    2>&1 | grep -E "^(Get:|Setting up|Processing)" || true
ok "Packages installed."

# ══════════════════════════════════════════════════════════════════════════════
# STEP 2 — udev rules (non-root USB access for eZ-FET lite)
# ══════════════════════════════════════════════════════════════════════════════
step "Writing udev rules..."
sudo tee /etc/udev/rules.d/71-ti-msp430.rules > /dev/null <<'UDEV'
# TI MSP430 LaunchPad eZ-FET lite (Rev 1.5+)  —  VID:PID 2047:0013
SUBSYSTEM=="usb", ATTRS{idVendor}=="2047", ATTRS{idProduct}=="0013", MODE="0664", GROUP="plugdev", TAG+="uaccess"
SUBSYSTEM=="usb", ATTRS{idVendor}=="2047", ATTRS{idProduct}=="0010", MODE="0664", GROUP="plugdev", TAG+="uaccess"
KERNEL=="hidraw*", ATTRS{idVendor}=="2047", MODE="0664", GROUP="plugdev", TAG+="uaccess"
# TI RF2500 (older LaunchPad Rev 1.4)  —  VID:PID 0451:f432
SUBSYSTEM=="usb", ATTRS{idVendor}=="0451", ATTRS{idProduct}=="f432", MODE="0664", GROUP="plugdev", TAG+="uaccess"
UDEV
sudo udevadm control --reload-rules
sudo udevadm trigger
ok "Written: /etc/udev/rules.d/71-ti-msp430.rules"

# ══════════════════════════════════════════════════════════════════════════════
# STEP 3 — Group membership
# ══════════════════════════════════════════════════════════════════════════════
step "Adding ${USER} to plugdev and dialout groups..."
sudo usermod -aG plugdev,dialout "${USER}"
info "Group change takes effect at next login (or run: newgrp plugdev)."

# ══════════════════════════════════════════════════════════════════════════════
# STEP 4 — Build libmsp430.so (TI MSP430 Debug Stack)
# ══════════════════════════════════════════════════════════════════════════════
step "Building TI MSP430 Debug Stack → libmsp430.so ..."
info "This may take several minutes."

TILIB_BUILT=false
LIBMSP430=""
SOURCE_DIR=""

rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# ── Try SourceForge (authoritative upstream) ──────────────────────────────────
SF_URL="https://sourceforge.net/projects/mspds/files/MSPDebugStack_OS_Package_3_15_1_1.zip/download"
info "Downloading from SourceForge..."
if wget -q --show-progress -L \
        -O "${BUILD_DIR}/debugstack.zip" \
        "${SF_URL}" 2>&1 && \
   [ -s "${BUILD_DIR}/debugstack.zip" ]; then
    info "Extracting..."
    unzip -q "${BUILD_DIR}/debugstack.zip" -d "${BUILD_DIR}/sf-src" 2>/dev/null || true
    # The zip might have a nested directory — find CMakeLists.txt or Makefile
    FOUND_CMAKE=$(find "${BUILD_DIR}/sf-src" -name "CMakeLists.txt" -print -quit 2>/dev/null || true)
    FOUND_MAKE=$(find "${BUILD_DIR}/sf-src" -name "Makefile" -print -quit 2>/dev/null || true)
    if [ -n "${FOUND_CMAKE}" ]; then
        SOURCE_DIR=$(dirname "${FOUND_CMAKE}")
    elif [ -n "${FOUND_MAKE}" ]; then
        SOURCE_DIR=$(dirname "${FOUND_MAKE}")
    fi
fi

# ── Fallback: GitHub mirror ───────────────────────────────────────────────────
if [ -z "${SOURCE_DIR}" ]; then
    warn "SourceForge unavailable or empty — trying GitHub mirror..."
    GH_URLS=(
        "https://github.com/nicowillis/MSP430DebugStack.git"
        "https://github.com/czietz/msp430-debugstack.git"
    )
    for GH_URL in "${GH_URLS[@]}"; do
        info "Cloning ${GH_URL} ..."
        if git clone --depth=1 "${GH_URL}" "${BUILD_DIR}/gh-src" 2>&1 | tail -2; then
            SOURCE_DIR="${BUILD_DIR}/gh-src"
            break
        fi
        rm -rf "${BUILD_DIR}/gh-src"
    done
fi

# ── Build ─────────────────────────────────────────────────────────────────────
if [ -n "${SOURCE_DIR}" ]; then
    info "Source directory: ${SOURCE_DIR}"
    cd "${SOURCE_DIR}"

    BUILD_OK=false

    # cmake build
    if [ -f CMakeLists.txt ]; then
        info "cmake build..."
        if cmake -B "${BUILD_DIR}/cmake-out" \
                 -S . \
                 -DCMAKE_BUILD_TYPE=Release \
                 -DBUILD_SHARED_LIBS=ON \
                 -DCMAKE_C_FLAGS="-fPIC" \
                 -DCMAKE_CXX_FLAGS="-fPIC" \
                 2>&1 | tail -5 \
        && cmake --build "${BUILD_DIR}/cmake-out" \
                 -j"$(nproc)" \
                 2>&1 | tail -10; then
            LIBMSP430=$(find "${BUILD_DIR}/cmake-out" -name "libmsp430.so" -print -quit 2>/dev/null || true)
            [ -n "${LIBMSP430}" ] && BUILD_OK=true
        fi
    fi

    # make build (if cmake produced nothing or no CMakeLists.txt)
    if ! $BUILD_OK && [ -f Makefile ]; then
        info "make build..."
        # Try common flags; ignore errors from individual attempts
        make -j"$(nproc)" STATIC=0 2>&1 | tail -15 || \
        make -j"$(nproc)"          2>&1 | tail -15 || true
        LIBMSP430=$(find "${SOURCE_DIR}" -name "libmsp430.so" -print -quit 2>/dev/null || true)
        [ -n "${LIBMSP430}" ] && BUILD_OK=true
    fi

    # Install
    if $BUILD_OK && [ -n "${LIBMSP430}" ]; then
        sudo cp "${LIBMSP430}" "${LIB_DIR}/libmsp430.so"
        sudo ldconfig
        ok "Installed: ${LIB_DIR}/libmsp430.so"
        TILIB_BUILT=true
    fi
fi

# ══════════════════════════════════════════════════════════════════════════════
# STEP 5 — Select driver
# ══════════════════════════════════════════════════════════════════════════════
if $TILIB_BUILT; then
    DRIVER="tilib"
    step "Driver selected: mspdebug tilib  (libmsp430.so built and installed)"

    # /usr/local/lib is in ldconfig's default search path on Debian, but
    # add LD_LIBRARY_PATH to .bashrc as belt-and-suspenders insurance.
    if ! grep -q "libmsp430\|msp430-tilib" "${HOME}/.bashrc" 2>/dev/null; then
        {
            echo ""
            echo "# MSP430 Debug Stack (libmsp430.so for mspdebug tilib)"
            echo "export LD_LIBRARY_PATH=\"/usr/local/lib\${LD_LIBRARY_PATH:+:\$LD_LIBRARY_PATH}\""
        } >> "${HOME}/.bashrc"
        info "Added LD_LIBRARY_PATH=/usr/local/lib to ~/.bashrc"
    fi
    export LD_LIBRARY_PATH="/usr/local/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
else
    DRIVER="ezfet"
    warn "libmsp430.so build failed (or source unavailable)."
    warn "Falling back to mspdebug's built-in ezfet driver."
    info "The ezfet driver in mspdebug 0.25 (Debian 12) supports 2047:0013."
    step "Driver selected: mspdebug ezfet  (no extra library needed)"
fi

# ══════════════════════════════════════════════════════════════════════════════
# STEP 6 — Update ~/course Makefiles
# ══════════════════════════════════════════════════════════════════════════════
step "Updating ~/course Makefiles → mspdebug ${DRIVER} ..."
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
    ok "Updated ${UPDATED} Makefile(s) to use: mspdebug ${DRIVER}"
else
    warn "~/course not found — sync your files first."
    warn "Then run: find ~/course -name Makefile | xargs sed -i 's/mspdebug rf2500/mspdebug ${DRIVER}/g'"
fi

# ══════════════════════════════════════════════════════════════════════════════
# STEP 7 — Quick connection test (non-fatal)
# ══════════════════════════════════════════════════════════════════════════════
step "Testing connection (non-fatal — device may not be ready yet)..."
if lsusb 2>/dev/null | grep -qE "2047:0013|2047:0010"; then
    info "LaunchPad detected on USB ✓"
    if timeout 8 mspdebug "${DRIVER}" "exit" 2>&1; then
        ok "mspdebug ${DRIVER} connected successfully ✓"
    else
        warn "mspdebug test failed — this is expected before you replug the device."
        warn "Replug the LaunchPad after this script finishes, then test manually."
    fi
else
    info "LaunchPad not currently detected on USB."
    info "Plug it in after the script finishes and test with: mspdebug ${DRIVER} exit"
fi

# ══════════════════════════════════════════════════════════════════════════════
# DONE — print next steps
# ══════════════════════════════════════════════════════════════════════════════
echo
printf "${_G}%s${_N}\n" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "${_G}  setup-flash.sh complete!   Flash driver: mspdebug %s${_N}\n" "${DRIVER}"
printf "${_G}%s${_N}\n" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
echo "  Do these steps now:"
echo ""
echo "  1.  UNPLUG the LaunchPad USB cable"
echo "  2.  REPLUG  the LaunchPad USB cable"
echo "  3.  Log out and back in  (or in this same terminal: exec newgrp plugdev)"
echo ""
echo "  Then verify:"
echo "    mspdebug ${DRIVER} \"exit\""
echo ""
echo "  Flash your first program:"
echo "    cd ~/course/lesson-01-architecture/examples"
echo "    make flash"
echo ""
if [ "${DRIVER}" = "tilib" ]; then
    echo "  Troubleshooting tilib:"
    echo "    • 'libmsp430.so not found'  →  run: source ~/.bashrc"
    echo "    • Still failing?  Try the ezfet fallback:"
    echo "        mspdebug ezfet \"prog minimal.elf\""
    echo "    • If ezfet works, update the Makefile: change 'tilib' → 'ezfet'"
else
    echo "  Note: if you later build libmsp430.so (for 'mspdebug tilib'),"
    echo "  re-run this script and it will switch the Makefiles automatically."
fi
echo ""
