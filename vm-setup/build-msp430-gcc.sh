#!/bin/sh
# build-msp430-gcc.sh
# Builds msp430-elf-gcc from source on ARM64 Linux (Debian/Ubuntu).
# Run as root. Takes ~25-30 minutes.
set -e

echo "==> Installing build prerequisites..."
apt-get install -y --no-install-recommends \
    build-essential libgmp-dev libmpfr-dev libmpc-dev \
    texinfo bison flex xz-utils

# Redirect all temp files to /var/tmp — /tmp is a small tmpfs on this system
export TMPDIR=/var/tmp

BINUTILS=2.43.1
GCC=13.3.0
PREFIX=/usr/local
TARGET=msp430-elf
JOBS=$(nproc)
BD=$(mktemp -d /var/tmp/msp430.XXXXXX)

echo "==> Build dir: $BD  Jobs: $JOBS"
cd "$BD"

echo "==> Downloading binutils ${BINUTILS}..."
wget "https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS}.tar.xz"
tar xf "binutils-${BINUTILS}.tar.xz"
mkdir b-bu && cd b-bu
../binutils-${BINUTILS}/configure \
    --target=$TARGET --prefix=$PREFIX \
    --disable-nls --disable-werror --quiet
echo "==> Building binutils (~5 min)..."
make -j$JOBS
make install
cd "$BD"

echo "==> Downloading GCC ${GCC}..."
wget "https://ftp.gnu.org/gnu/gcc/gcc-${GCC}/gcc-${GCC}.tar.xz"
tar xf "gcc-${GCC}.tar.xz"
mkdir b-gcc && cd b-gcc
../gcc-${GCC}/configure \
    --target=$TARGET --prefix=$PREFIX \
    --enable-languages=c --disable-nls --disable-werror \
    --with-newlib --without-headers \
    --disable-shared --disable-threads \
    --disable-libssp --disable-libgomp \
    --disable-libquadmath --quiet
echo "==> Building GCC (~20 min)..."
make -j$JOBS all-gcc all-target-libgcc
make install-gcc install-target-libgcc
cd /
rm -rf "$BD"

ln -sf "$PREFIX/bin/msp430-elf-gcc" "$PREFIX/bin/msp430-gcc" 2>/dev/null || true

echo ""
echo "==> Done! Verifying..."
msp430-elf-gcc --version
