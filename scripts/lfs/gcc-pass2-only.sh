#!/usr/bin/env bash
# GCC Pass 2 Only Build Script

set -e
set -o pipefail

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/config/lfs-config.conf"
source "$PROJECT_ROOT/config/lfs-versions.conf"

# LFS directory
LFS="$LFS_ROOTFS"

# Build configuration
export PATH="$LFS_TOOLS/bin:$PATH"
export MAKEFLAGS="-j$(nproc)"

SOURCES_DIR="$LFS_SOURCES"
BUILD_DIR="$LFS_BUILD/temp-tools"

echo "========================================="
echo "Building GCC Pass 2 with CXXFLAGS fix"
echo "========================================="

cd "$BUILD_DIR"
rm -rf gcc-$GCC_VERSION
tar -xf "$SOURCES_DIR/gcc-$GCC_VERSION.tar.xz"
cd gcc-$GCC_VERSION

# Extract GMP, MPFR, MPC
tar -xf "$SOURCES_DIR/mpfr-$MPFR_VERSION.tar.xz"
mv -v mpfr-$MPFR_VERSION mpfr
tar -xf "$SOURCES_DIR/gmp-$GMP_VERSION.tar.xz"
mv -v gmp-$GMP_VERSION gmp
tar -xf "$SOURCES_DIR/mpc-$MPC_VERSION.tar.gz"
mv -v mpc-$MPC_VERSION mpc

# Fix for x86_64
case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
  ;;
esac

# Apply LFS patches
sed '/thread_header =/s/@.*@/gthr-posix.h/' \
    -i libgcc/Makefile.in libstdc++-v3/include/Makefile.in

mkdir -v build
cd build

echo "Configuring GCC Pass 2..."
../configure                                       \
    --build=$(../config.guess)                     \
    --host=$LFS_TGT                                \
    --target=$LFS_TGT                              \
    LDFLAGS_FOR_TARGET=-L$PWD/$LFS_TGT/libgcc      \
    --prefix=/usr                                  \
    --with-build-sysroot=$LFS                      \
    --enable-default-pie                           \
    --enable-default-ssp                           \
    --disable-nls                                  \
    --disable-multilib                             \
    --disable-libatomic                            \
    --disable-libgomp                              \
    --disable-libquadmath                          \
    --disable-libsanitizer                         \
    --disable-libssp                               \
    --disable-libvtv                               \
    --without-isl                                  \
    --enable-languages=c

echo "Building GCC Pass 2 with CXXFLAGS..."
make MAKEINFO=true \
    CXXFLAGS="-I$LFS/tools/x86_64-maruxos-linux-gnu/include/c++/13.2.0 -I$LFS/tools/x86_64-maruxos-linux-gnu/include/c++/13.2.0/x86_64-maruxos-linux-gnu"

echo "Installing GCC Pass 2..."
make DESTDIR=$LFS install MAKEINFO=true

ln -sv gcc $LFS/usr/bin/cc

cd "$BUILD_DIR"
rm -rf gcc-$GCC_VERSION

echo "✓ GCC Pass 2 installed successfully"
