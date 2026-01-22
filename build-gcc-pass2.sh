#!/bin/bash
# Build GCC Pass 2 only
set -e

PROJECT_ROOT="/home/administrator/MaruxOS"
source "$PROJECT_ROOT/config/marux-release.conf"
source "$PROJECT_ROOT/config/lfs-config.conf"
source "$PROJECT_ROOT/config/lfs-versions.conf"

LFS="$LFS_ROOTFS"
export PATH="$LFS_TOOLS/bin:$PATH"
export CONFIG_SITE="$LFS/usr/share/config.site"
export MAKEFLAGS="-j$(nproc)"

SOURCES_DIR="$LFS_SOURCES"
BUILD_DIR="$LFS_BUILD/temp-tools"

mkdir -p "$BUILD_DIR"

echo "========================================"
echo "Building GCC Pass 2"
echo "========================================"
echo ""

if [ -f "$LFS/usr/bin/gcc" ]; then
    echo "✓ GCC Pass 2 already installed"
    exit 0
fi

cd "$BUILD_DIR"
rm -rf gcc-$GCC_VERSION
tar -xf "$SOURCES_DIR/gcc-$GCC_VERSION.tar.xz"
cd gcc-$GCC_VERSION

# Extract dependencies
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

# Configure with proper sysroot
sed '/thread_header =/s/@.*@/gthr-posix.h/' \
    -i libgcc/Makefile.in libstdc++-v3/include/Makefile.in

mkdir -v build
cd build

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
    --enable-languages=c,c++

echo "Building GCC... (this will take 1-2 hours)"
make

echo "Installing GCC Pass 2..."
make DESTDIR=$LFS install

# Create compatibility symlinks
ln -sv gcc $LFS/usr/bin/cc

cd "$BUILD_DIR"
rm -rf gcc-$GCC_VERSION

echo ""
echo "✓✓✓ GCC Pass 2 installed successfully! ✓✓✓"
echo ""
$LFS/usr/bin/gcc --version
