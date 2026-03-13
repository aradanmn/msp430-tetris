#!/bin/bash
#==============================================================================
# setup-mac.sh — One-time MSP430 toolchain setup for macOS (Apple Silicon)
#
# Installs:
#   - msp430-elf-gcc   TI official prebuilt toolchain (downloaded from ti.com)
#   - mspdebug         flash/debug tool via Homebrew
#   - picocom          serial monitor via Homebrew
#
# The compiler is installed to ~/.local/msp430-gcc and added to PATH in
# ~/.zshrc.  No Homebrew tap or git clone needed for the compiler.
#
# Usage:
#   ./setup-mac.sh
#   source ~/.zshrc   (or open a new terminal)
#
# Then:
#   cd course/lesson-01-architecture/examples
#   make              # compile → .elf
#   make flash        # flash to LaunchPad via USB
#==============================================================================

set -euo pipefail

# Skip brew auto-update — avoids any git network activity during install
export HOMEBREW_NO_AUTO_UPDATE=1

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

echo "=== MSP430 Mac toolchain setup ==="
echo ""

#──────────────────────────────────────────────────────────────────────────────
# Diagnostics: show any ~/.gitconfig URL rewrites (informational only)
#──────────────────────────────────────────────────────────────────────────────
if grep -q "insteadOf" "$HOME/.gitconfig" 2>/dev/null; then
    echo -e "${YELLOW}Note: ~/.gitconfig has URL rewrites (insteadOf):${NC}"
    grep -A1 "insteadOf" "$HOME/.gitconfig" | sed 's/^/  /'
    echo "  These break 'brew tap' for public repos."
    echo "  The compiler install below uses curl and avoids this entirely."
    echo ""
fi

#──────────────────────────────────────────────────────────────────────────────
# 1. Homebrew check
#──────────────────────────────────────────────────────────────────────────────
if ! command -v brew >/dev/null 2>&1; then
    echo -e "${RED}Homebrew not found.${NC} Install it first:"
    echo '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    exit 1
fi

#──────────────────────────────────────────────────────────────────────────────
# 2. msp430-elf-gcc — TI official prebuilt, downloaded directly from ti.com
#    No brew tap, no git clone — pure curl.
#    Source: https://www.ti.com/tool/MSP430-GCC-OPENSOURCE
#──────────────────────────────────────────────────────────────────────────────
TOOLCHAIN_DIR="$HOME/.local/msp430-gcc"
GCC_BIN="$TOOLCHAIN_DIR/bin/msp430-elf-gcc"
TI_URL="https://dr-download.ti.com/software-development/ide-configuration-compiler-or-debugger/MD-LlCjWuAbzH/9.3.1.2/msp430-gcc-9.3.1.11_macos.tar.bz2"

if [ -x "$GCC_BIN" ]; then
    echo -e "${GREEN}msp430-elf-gcc already installed${NC} at $TOOLCHAIN_DIR"
else
    echo "Downloading TI MSP430 GCC 9.3.1 toolchain (~78 MB)..."
    TMP_TAR="/tmp/msp430-gcc-$$.tar.bz2"
    curl -fL --progress-bar "$TI_URL" -o "$TMP_TAR"

    echo "Extracting to $TOOLCHAIN_DIR ..."
    mkdir -p "$TOOLCHAIN_DIR"
    # The tarball has a single top-level directory — strip it so bin/ lands directly
    # under $TOOLCHAIN_DIR.  If extraction fails, try without --strip-components.
    if ! tar -xjf "$TMP_TAR" -C "$TOOLCHAIN_DIR" --strip-components=1 2>/dev/null; then
        echo "Retrying extraction without --strip-components..."
        rm -rf "$TOOLCHAIN_DIR"
        mkdir -p "$TOOLCHAIN_DIR"
        tar -xjf "$TMP_TAR" -C "$HOME/.local"
        # Find where it actually landed
        EXTRACTED=$(tar -tjf "$TMP_TAR" 2>/dev/null | head -1 | cut -d/ -f1)
        if [ -d "$HOME/.local/$EXTRACTED" ]; then
            mv "$HOME/.local/$EXTRACTED" "$TOOLCHAIN_DIR"
        fi
    fi
    rm -f "$TMP_TAR"

    if [ ! -x "$GCC_BIN" ]; then
        echo -e "${RED}Extraction failed — $GCC_BIN not found.${NC}"
        echo "Check the TI download page: https://www.ti.com/tool/MSP430-GCC-OPENSOURCE"
        exit 1
    fi
    echo -e "${GREEN}Toolchain installed.${NC}"
fi

#──────────────────────────────────────────────────────────────────────────────
# 3. Add toolchain to PATH in ~/.zshrc (idempotent)
#──────────────────────────────────────────────────────────────────────────────
PROFILE="$HOME/.zshrc"
if ! grep -q 'msp430-gcc/bin' "$PROFILE" 2>/dev/null; then
    {
        echo ""
        echo "# MSP430 GCC toolchain (added by setup-mac.sh)"
        echo 'export PATH="$HOME/.local/msp430-gcc/bin:$PATH"'
    } >> "$PROFILE"
    echo "Added toolchain to PATH in $PROFILE"
fi
export PATH="$TOOLCHAIN_DIR/bin:$PATH"

#──────────────────────────────────────────────────────────────────────────────
# 4. mspdebug — in homebrew-core, installs via bottle (no tap needed)
#──────────────────────────────────────────────────────────────────────────────
if command -v mspdebug >/dev/null 2>&1; then
    echo -e "${GREEN}mspdebug already installed${NC}"
else
    echo "Installing mspdebug..."
    brew install mspdebug
fi

#──────────────────────────────────────────────────────────────────────────────
# 5. picocom — serial monitor for Lessons 13+
#──────────────────────────────────────────────────────────────────────────────
if command -v picocom >/dev/null 2>&1; then
    echo -e "${GREEN}picocom already installed${NC}"
else
    echo "Installing picocom..."
    brew install picocom
fi

#──────────────────────────────────────────────────────────────────────────────
# 6. libmsp430.dylib — required for 'mspdebug tilib' (HID driver, no IOKit
#    conflict unlike CDC ACM / ezfet).
#
#  Strategy (in order):
#   A) Already present somewhere → copy it
#   B) MacPorts installed → sudo port install msp430-elf-gcc
#   C) Download TI full installer → strip quarantine recursively → run headless
#      with user-writable prefix so it doesn't need /Applications write access
#──────────────────────────────────────────────────────────────────────────────
LIB_DEST="$HOME/.local/lib/libmsp430.dylib"
PROFILE="$HOME/.zshrc"
TI_FULL_URL="https://dr-download.ti.com/software-development/ide-configuration-compiler-or-debugger/MD-LlCjWuAbzH/9.3.1.2/msp430-gcc-full-osx-installer-9.3.1.2.app.zip"
TI_INSTALL_PREFIX="$HOME/.local/ti-msp430"

# Helper: scan all known locations for the library
_find_lib() {
    find \
        /Applications/ti /usr/local/ti "$HOME/ti" \
        "$TI_INSTALL_PREFIX" \
        /opt/local/lib /opt/local/var/macports \
        -name "libmsp430.dylib" 2>/dev/null | head -1 || true
}

if [ -f "$LIB_DEST" ]; then
    echo -e "${GREEN}libmsp430.dylib already at $LIB_DEST${NC}"

else
    # ── A: already on disk somewhere from a previous install ─────────────────
    LIBMSP430_FOUND=$(_find_lib)

    # ── B: MacPorts ───────────────────────────────────────────────────────────
    if [ -z "$LIBMSP430_FOUND" ] && command -v port >/dev/null 2>&1; then
        echo "MacPorts found — installing msp430-elf-gcc (this may take a few minutes)..."
        sudo port install msp430-elf-gcc 2>/dev/null || true
        LIBMSP430_FOUND=$(_find_lib)
    fi

    # ── C: TI full installer ──────────────────────────────────────────────────
    if [ -z "$LIBMSP430_FOUND" ]; then
        echo "Downloading TI MSP430-GCC full installer (~45 MB) for libmsp430.dylib..."
        TMP_ZIP="/tmp/msp430-full-$$.zip"
        TMP_APP="/tmp/msp430-full-$$"
        curl -fL --progress-bar "$TI_FULL_URL" -o "$TMP_ZIP"

        echo "Unzipping installer..."
        unzip -q "$TMP_ZIP" -d "$TMP_APP"
        rm -f "$TMP_ZIP"

        INSTALLER_APP=$(find "$TMP_APP" -name "*.app" -maxdepth 2 | head -1)
        INSTALLER_BIN=$(find "$INSTALLER_APP/Contents/MacOS" -type f -perm +111 2>/dev/null | head -1)

        # Remove quarantine from every file inside the bundle (must be recursive;
        # a non-recursive xattr -d only covers the top-level .app node and leaves
        # the embedded binary still quarantined).
        sudo xattr -r -d com.apple.quarantine "$INSTALLER_APP" 2>/dev/null || true

        # Run headless with an explicit user-writable prefix so the installer
        # doesn't need to write to /Applications.  sudo -E preserves HOME so
        # $HOME expands correctly inside the installer.
        echo "Running installer (headless, prefix=$TI_INSTALL_PREFIX)..."
        mkdir -p "$TI_INSTALL_PREFIX"
        sudo -E "$INSTALLER_BIN" \
            --mode unattended \
            --unattendedmodeui none \
            --prefix "$TI_INSTALL_PREFIX" 2>&1 | head -30 || true
        rm -rf "$TMP_APP"

        LIBMSP430_FOUND=$(_find_lib)
    fi

    # ── Copy or print manual instructions ─────────────────────────────────────
    if [ -n "$LIBMSP430_FOUND" ]; then
        echo "Found libmsp430.dylib at: $LIBMSP430_FOUND"
        mkdir -p "$(dirname "$LIB_DEST")"
        cp "$LIBMSP430_FOUND" "$LIB_DEST"
        echo -e "${GREEN}libmsp430.dylib installed at $LIB_DEST${NC}"
    else
        echo -e "${YELLOW}══════════════════════════════════════════════════════${NC}"
        echo -e "${YELLOW}  ACTION REQUIRED — libmsp430.dylib not installed yet  ${NC}"
        echo -e "${YELLOW}══════════════════════════════════════════════════════${NC}"
        echo ""
        echo "Option A — MacPorts (easiest, one command after install):"
        echo "  1. Install MacPorts: https://www.macports.org/install.php"
        echo "     (download the .pkg for your macOS version — it is notarized)"
        echo "  2. sudo port install msp430-elf-gcc"
        echo "  3. ./setup-mac.sh          ← re-run this script"
        echo ""
        echo "Option B — TI GUI installer (if already downloaded):"
        echo "  The installer app may be blocked by Gatekeeper.  Fix:"
        echo "  a) In Finder, RIGHT-CLICK the .app → 'Open' → click 'Open'"
        echo "     (right-click bypasses the double-click Gatekeeper block)"
        echo "  b) OR: System Settings → Privacy & Security → scroll to the"
        echo "     blocked entry → click 'Allow Anyway', then open the app."
        echo "  After the GUI install completes, re-run: ./setup-mac.sh"
        echo ""
        echo "Option C — download and open the installer now:"
        echo "  curl -fL '$TI_FULL_URL' -o ~/Downloads/msp430-full.app.zip"
        echo "  unzip ~/Downloads/msp430-full.app.zip -d ~/Downloads/"
        echo "  sudo xattr -r -d com.apple.quarantine \\"
        echo "    ~/Downloads/msp430-gcc-full-osx-installer-9.3.1.2.app"
        echo "  open ~/Downloads/msp430-gcc-full-osx-installer-9.3.1.2.app"
        echo ""
    fi
fi

# Wire up DYLD_LIBRARY_PATH so mspdebug can find libmsp430.dylib at runtime
if ! grep -q 'msp430.*DYLD_LIBRARY_PATH\|DYLD_LIBRARY_PATH.*msp430' "$PROFILE" 2>/dev/null; then
    {
        echo ""
        echo "# mspdebug tilib — needed to find libmsp430.dylib (added by setup-mac.sh)"
        echo 'export DYLD_LIBRARY_PATH="$HOME/.local/lib:${DYLD_LIBRARY_PATH:-}"'
    } >> "$PROFILE"
    echo "Added DYLD_LIBRARY_PATH to $PROFILE"
fi
export DYLD_LIBRARY_PATH="$HOME/.local/lib:${DYLD_LIBRARY_PATH:-}"

#──────────────────────────────────────────────────────────────────────────────
# Verify
#──────────────────────────────────────────────────────────────────────────────
echo ""
echo "=== Verify ==="
"$GCC_BIN" --version | head -1
mspdebug --version 2>&1 | head -1
if [ -f "$LIB_DEST" ]; then
    echo -e "${GREEN}libmsp430.dylib: $LIB_DEST${NC}"
else
    echo -e "${YELLOW}libmsp430.dylib: NOT YET INSTALLED (see instructions above)${NC}"
fi

echo ""
echo -e "${GREEN}=== Done ===${NC}"
echo ""
echo "If msp430-elf-gcc is not found in a new terminal, run:  source ~/.zshrc"
echo ""
echo "Build:   cd course/lesson-01-architecture/examples && make"
echo "Flash:   make flash   (LaunchPad connected via USB)"
echo ""
echo "Serial monitor (Lessons 13+):"
echo "  The LaunchPad creates TWO serial ports — use the lower-numbered one:"
echo "  ls /dev/cu.usbmodem*"
echo "  picocom -b 9600 /dev/cu.usbmodem<LOWER_NUMBER>"
echo "  (exit: Ctrl-A Ctrl-X)"
