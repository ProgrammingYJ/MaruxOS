#!/bin/bash
# MaruxOS LFS Build - Cross-Compilation Toolchain
# ================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/config/marux-release.conf"
source "$PROJECT_ROOT/config/lfs-config.conf"
source "$PROJECT_ROOT/config/lfs-versions.conf"

echo "========================================"
echo "MaruxOS LFS - Cross Toolchain Build"
echo "========================================"
echo ""
echo "This will build:"
echo "  - Binutils (cross-linker)"
echo "  - GCC Pass 1 (cross-compiler)"
echo "  - Linux Headers"
echo "  - Glibc (cross C library)"
echo "  - GCC Pass 2 (final cross-compiler)"
echo ""
echo "Estimated time: 2-4 hours"
echo ""

BUILD_DIR="$LFS_BUILD/cross-tools"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Set environment
export PATH="$LFS_TOOLS/bin:$PATH"
export LFS_TGT="x86_64-maruxos-linux-gnu"

echo "=== Phase 1: Binutils (Cross-Linker) ==="
echo ""

if [ ! -f "$LFS_TOOLS/bin/$LFS_TGT-ld" ]; then
    echo "Building Binutils $BINUTILS_VERSION..."

    tar -xf "$LFS_SOURCES/binutils-$BINUTILS_VERSION.tar.xz"
    cd "binutils-$BINUTILS_VERSION"

    mkdir -p build && cd build

    ../configure \
        --prefix="$LFS_TOOLS" \
        --with-sysroot="$LFS_ROOTFS" \
        --target=$LFS_TGT \
        --disable-nls \
        --disable-werror \
        --enable-gprofng=no

    make -j$(nproc)
    make install

    cd "$BUILD_DIR"
    rm -rf "binutils-$BINUTILS_VERSION"

    echo "✓ Binutils installed"
else
    echo "✓ Binutils already installed"
fi

echo ""
echo "=== Phase 2: GCC Pass 1 (Cross-Compiler) ==="
echo ""

if [ ! -f "$LFS_TOOLS/bin/$LFS_TGT-gcc" ]; then
    echo "Building GCC Pass 1 $GCC_VERSION..."

    tar -xf "$LFS_SOURCES/gcc-$GCC_VERSION.tar.xz"
    cd "gcc-$GCC_VERSION"

    # Extract GMP, MPFR, MPC
    tar -xf "$LFS_SOURCES/gmp-$GMP_VERSION.tar.xz"
    mv "gmp-$GMP_VERSION" gmp

    tar -xf "$LFS_SOURCES/mpfr-$MPFR_VERSION.tar.xz"
    mv "mpfr-$MPFR_VERSION" mpfr

    tar -xf "$LFS_SOURCES/mpc-$MPC_VERSION.tar.gz"
    mv "mpc-$MPC_VERSION" mpc

    # Configure for cross-compilation
    mkdir -p build && cd build

    ../configure \
        --target=$LFS_TGT \
        --prefix="$LFS_TOOLS" \
        --with-glibc-version=2.38 \
        --with-sysroot="$LFS_ROOTFS" \
        --with-newlib \
        --without-headers \
        --enable-initfini-array \
        --disable-nls \
        --disable-shared \
        --disable-multilib \
        --disable-decimal-float \
        --disable-threads \
        --disable-libatomic \
        --disable-libgomp \
        --disable-libquadmath \
        --disable-libssp \
        --disable-libvtv \
        --disable-libstdcxx \
        --enable-languages=c,c++

    make -j$(nproc)
    make install

    cd "$BUILD_DIR"
    rm -rf "gcc-$GCC_VERSION"

    # Create limits.h
    cd "$LFS_TOOLS/$LFS_TGT"
    cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
        $(dirname $(find -name limits.h))/limits.h

    echo "✓ GCC Pass 1 installed"
else
    echo "✓ GCC Pass 1 already installed"
fi

echo ""
echo "=== Phase 3: Linux API Headers ==="
echo ""

if [ ! -d "$LFS_ROOTFS/usr/include/linux" ]; then
    echo "Installing Linux kernel headers..."

    KERNEL_SOURCE="$PROJECT_ROOT/kernel/source/linux-$KERNEL_VERSION"

    if [ ! -d "$KERNEL_SOURCE" ]; then
        echo "ERROR: Kernel source not found at $KERNEL_SOURCE"
        echo "Please ensure kernel was downloaded first"
        exit 1
    fi

    cd "$KERNEL_SOURCE"

    make mrproper
    make headers

    # Install headers
    find usr/include -type f ! -name '*.cmd' | \
        cpio -pdm "$LFS_ROOTFS"

    echo "✓ Linux headers installed"
else
    echo "✓ Linux headers already installed"
fi

echo ""
echo "=== Phase 4: Glibc (C Library) ==="
echo ""

cd "$BUILD_DIR"

if [ ! -f "$LFS_ROOTFS/lib/libc.so.6" ]; then
    echo "Building Glibc $GLIBC_VERSION..."

    tar -xf "$LFS_SOURCES/glibc-$GLIBC_VERSION.tar.xz"
    cd "glibc-$GLIBC_VERSION"

    mkdir -p build && cd build

    echo "rootsbindir=/usr/sbin" > configparms

    ../configure \
        --prefix=/usr \
        --host=$LFS_TGT \
        --build=$(../scripts/config.guess) \
        --enable-kernel=4.14 \
        --with-headers="$LFS_ROOTFS/usr/include" \
        libc_cv_slibdir=/usr/lib

    make -j$(nproc)
    make DESTDIR="$LFS_ROOTFS" install

    # Fix symlink
    sed '/RTLDLIST=/s@/usr@@g' -i "$LFS_ROOTFS/usr/bin/ldd"

    cd "$BUILD_DIR"
    rm -rf "glibc-$GLIBC_VERSION"

    echo "✓ Glibc installed"
else
    echo "✓ Glibc already installed"
fi

echo ""
echo "=== Phase 5: Libstdc++ (C++ Library) ==="
echo ""

if [ ! -f "$LFS_ROOTFS/usr/lib/libstdc++.so" ]; then
    echo "Building libstdc++..."

    tar -xf "$LFS_SOURCES/gcc-$GCC_VERSION.tar.xz"
    cd "gcc-$GCC_VERSION"

    mkdir -p build && cd build

    ../libstdc++-v3/configure \
        --host=$LFS_TGT \
        --build=$(../config.guess) \
        --prefix=/usr \
        --disable-multilib \
        --disable-nls \
        --disable-libstdcxx-pch \
        --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/$GCC_VERSION

    make -j$(nproc)
    make DESTDIR="$LFS_ROOTFS" install

    # Clean up
    rm -v "$LFS_ROOTFS/usr/lib/lib{stdc++,stdc++fs,supc++}.la"

    cd "$BUILD_DIR"
    rm -rf "gcc-$GCC_VERSION"

    echo "✓ Libstdc++ installed"
else
    echo "✓ Libstdc++ already installed"
fi

echo ""
echo "========================================"
echo "✓ Cross-Toolchain Build Complete!"
echo "========================================"
echo ""
echo "Installed tools:"
ls -lh "$LFS_TOOLS/bin" | grep "$LFS_TGT" | head -5
echo ""
echo "Next step: Run ./03-build-temp-system.sh"
echo ""
