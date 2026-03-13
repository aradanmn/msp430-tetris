#!/bin/bash
# build-libmsp430.sh — build libmsp430.dylib (arm64) from TI open-source package
# Run once on Apple Silicon Mac; re-run after 'brew upgrade boost hidapi'.
set -eo pipefail

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

DEST="$HOME/.local/lib/libmsp430.dylib"
BUILD_DIR="/tmp/mspds-build-$$"
TI_URL="https://dr-download.ti.com/software-development/driver-or-library/MD-4vnqcP1Wk4/3.15.1.1/MSPDebugStack_OS_Package_3_15_1_1.zip"

# ── 0. Skip if arm64 build already present ────────────────────────────────────
if [ -f "$DEST" ]; then
    ARCH=$(file "$DEST" | grep -o 'arm64\|x86_64' || true)
    if [ "$ARCH" = "arm64" ]; then
        echo -e "${GREEN}arm64 libmsp430.dylib already at $DEST — nothing to do${NC}"
        exit 0
    fi
    echo -e "${YELLOW}Replacing x86_64 libmsp430.dylib with arm64 build${NC}"
fi

# ── 1. Dependencies ───────────────────────────────────────────────────────────
echo "Installing dependencies (boost, hidapi)..."
brew install boost hidapi 2>/dev/null || true

BOOST_PREFIX="$(brew --prefix boost)"
HID_PREFIX="$(brew --prefix)"   # /opt/homebrew — contains include/hidapi/ and lib/

# Detect whether Homebrew Boost ships -mt variants (naming differs by version)
if ls "$BOOST_PREFIX/lib/libboost_filesystem-mt.a" "$BOOST_PREFIX/lib/libboost_filesystem-mt.dylib" 2>/dev/null | head -1 >/dev/null; then
    BOOST_MT="-mt"
    echo "Boost: using -mt library variants"
else
    BOOST_MT=""
    echo "Boost: using default library names (no -mt suffix)"
fi

# ── 2. Download & extract source ──────────────────────────────────────────────
echo "Downloading MSP Debug Stack 3.15.1.1 source (~2 MB)..."
mkdir -p "$BUILD_DIR"
curl -fL --progress-bar "$TI_URL" -o "$BUILD_DIR/mspds.zip"
unzip -q "$BUILD_DIR/mspds.zip" -d "$BUILD_DIR"
# Zip extracts flat (no top-level directory), so sources are directly in BUILD_DIR
cd "$BUILD_DIR"

# ── 3. Patch Makefiles ────────────────────────────────────────────────────────
# Uses Python (always present on macOS) for reliable multi-line text edits.
# BOOST_MT is passed as an env variable to the Python script.
echo "Patching Makefiles..."
BOOST_MT="$BOOST_MT" python3 - << 'PYEOF'
import os, re, sys

boost_mt = os.environ.get('BOOST_MT', '')

# ── Main Makefile ─────────────────────────────────────────────────────────────
with open('Makefile', 'r') as f:
    m = f.read()

# 1. Add INSTALL variable at the very top
m = 'INSTALL := /usr/bin/install\n\n' + m

# 2. Export PREFIX (needed so sub-make inherits it)
m = m.replace('export DEBUG\n', 'export DEBUG\nexport PREFIX\n', 1)

# 3. Add hidapi include path to INCLUDES list (append after last -I entry)
m = m.replace(
    '\t-I./ThirdParty/BSL430_DLL\n',
    '\t-I./ThirdParty/BSL430_DLL \\\n\t-I$(PREFIX)/include/hidapi\n',
    1
)

# 4. Seed LIBS and STATIC_LIBS with the Homebrew lib path
#    Original has a blank line between them; remove it (matches patch)
m = m.replace('LIBS :=\nSTATIC_LIBS :=\n', 'LIBS := -L$(PREFIX)/lib\nSTATIC_LIBS := -L$(PREFIX)/lib\n', 1)

# 5. Boost library names: add -mt suffix if Homebrew uses it
if boost_mt:
    for lib in ['filesystem', 'system', 'date_time', 'chrono', 'thread']:
        m = m.replace(f'-lboost_{lib}', f'-lboost_{lib}{boost_mt}')

# 5b. Drop boost_system — header-only since Boost 1.69, no library file exists
m = m.replace(' -lboost_system-mt', '')
m = m.replace(' -lboost_system', '')

# 6. Fix critical -install_name bug: $(OUTNAME)$(OUTPUT) → $(OUTNAME) $(OUTPUT)
#    Without the space the linker gets '-install_namelibmsp430.dylib' — broken.
m = m.replace('$(OUTNAME)$(OUTPUT)', '$(OUTNAME) $(OUTPUT)', 1)

# 7. Propagate PREFIX into the BSL430_DLL sub-make
m = m.replace(
    '\t$(MAKE) -C ./ThirdParty/BSL430_DLL\n',
    '\t$(MAKE) PREFIX=$(PREFIX) -C ./ThirdParty/BSL430_DLL\n',
    1
)

# 8. Fix install target (use $PREFIX/$DESTDIR instead of hardcoded /usr/local/lib)
m = m.replace(
    'install:\n\tcp $(OUTPUT) /usr/local/lib/',
    'install:\n\tmkdir -p $(DESTDIR)/$(PREFIX)/lib/\n\t$(INSTALL) $(OUTPUT) $(DESTDIR)/$(PREFIX)/lib/'
)

with open('Makefile', 'w') as f:
    f.write(m)
print('  Main Makefile: OK')

# ── Fix Boost ASIO breaking change across ALL source directories ───────────────
# Boost 1.66 renamed io_service → io_context; the compat header
# boost/asio/io_service.hpp was removed in Boost 1.74.
# Walk every .cpp/.h in the whole tree and fix both the include and the type name.
fixed = []
for root, dirs, files in os.walk('.'):
    for fname in files:
        if not fname.endswith(('.cpp', '.h', '.hpp')):
            continue
        path = os.path.join(root, fname)
        # Use latin-1: accepts all byte values 0-255, handles CP1252 comments
        with open(path, 'r', encoding='latin-1') as f:
            src = f.read()
        if 'io_service' in src:
            # Fix removed compat header (Boost 1.74+)
            src = src.replace('#include <boost/asio/io_service.hpp>',
                              '#include <boost/asio/io_context.hpp>')
            # Fix type names: qualified then bare (word-boundary to avoid partials)
            src = src.replace('boost::asio::io_service', 'boost::asio::io_context')
            src = src.replace('asio::io_service', 'asio::io_context')
            src = re.sub(r'\bio_service\b', 'io_context', src)
            with open(path, 'w', encoding='latin-1') as f:
                f.write(src)
            fixed.append(path)
if fixed:
    print(f'  Boost io_service→io_context fixed in: {", ".join(fixed)}')
else:
    print('  Boost io_service: no occurrences found (OK)')

# ── Fix UsbCdcIoChannel.cpp: further Boost ASIO API removals (Boost 1.66+) ────
# run(ec) and run_one(ec) overloads taking error_code were removed.
# io_context::reset() was renamed to restart().
usb_path = 'DLL430_v3/src/TI/DLL430/UsbCdcIoChannel.cpp'
with open(usb_path, 'r', encoding='latin-1') as f:
    usb = f.read()
usb = re.sub(r'(->run_one\()\s*\w+\s*(\))', r'\1\2', usb)   # run_one(ec) → run_one()
usb = re.sub(r'(->run\()\s*\w+\s*(\))',      r'\1\2', usb)   # run(ec)     → run()
usb = usb.replace('->reset()', '->restart()')                 # reset()     → restart()
with open(usb_path, 'w', encoding='latin-1') as f:
    f.write(usb)
print('  UsbCdcIoChannel.cpp: run(ec)/run_one(ec)/reset() fixed')

# ── ThirdParty/BSL430_DLL/Makefile ────────────────────────────────────────────
bsl_path = 'ThirdParty/BSL430_DLL/Makefile'
with open(bsl_path, 'r') as f:
    b = f.read()

# 1. Export PREFIX (before INCLUDES block)
b = b.replace('INCLUDES := \\\n', 'export PREFIX\n\nINCLUDES := \\\n', 1)

# 2. Add hidapi include (append after last -I entry in BSL Makefile)
b = b.replace(
    '\t-I./BSL430_DLL/Connections\n',
    '\t-I./BSL430_DLL/Connections \\\n\t-I$(PREFIX)/include/hidapi\n',
    1
)

# 3. Fix install target
b = b.replace(
    'install:\n\tcp $(OUTPUT) /usr/lib/',
    'install:\n\tcp $(OUTPUT) $(DESTDIR)/lib/'
)

with open(bsl_path, 'w') as f:
    f.write(b)
print('  BSL430_DLL Makefile: OK')
PYEOF

# ── 4. Build ──────────────────────────────────────────────────────────────────
echo "Building libmsp430.dylib — this takes 1-2 minutes..."
BOOST_DIR="$BOOST_PREFIX" PREFIX="$HID_PREFIX" make STATIC=1

# ── 5. Verify & install ───────────────────────────────────────────────────────
if [ ! -f libmsp430.dylib ]; then
    echo -e "${RED}Build failed: libmsp430.dylib was not produced${NC}"
    exit 1
fi

ARCH=$(file libmsp430.dylib | grep -o 'arm64\|x86_64' || true)
echo "Built architecture: $ARCH"

if [ "$ARCH" != "arm64" ]; then
    echo -e "${RED}Wrong architecture ($ARCH) — expected arm64${NC}"
    exit 1
fi

mkdir -p "$(dirname "$DEST")"
cp libmsp430.dylib "$DEST"
echo -e "${GREEN}Installed: $DEST${NC}"

# ── 6. Cleanup ────────────────────────────────────────────────────────────────
cd /tmp
rm -rf "$BUILD_DIR"

echo ""
echo "Run:  cd course/lesson-01-architecture/examples && make flash"
