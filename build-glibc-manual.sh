#!/bin/bash
set -e

PROJECT_ROOT="/home/administrator/MaruxOS"
source "$PROJECT_ROOT/config/marux-release.conf"
source "$PROJECT_ROOT/config/lfs-config.conf"
source "$PROJECT_ROOT/config/lfs-versions.conf"

export PATH="$LFS_TOOLS/bin:$PATH"
export LFS_TGT="x86_64-maruxos-linux-gnu"

echo "=== Installing Linux Headers (fixed) ==="
cd "$PROJECT_ROOT/kernel/source/linux-$KERNEL_VERSION"
make mrproper
make headers

# Install to CORRECT location (not /usr/usr/include)
find usr/include -name '*.h' -exec install -Dm644 {} "$LFS_ROOTFS/{}" \;

echo "✓ Headers installed to $LFS_ROOTFS/usr/include"
ls -la "$LFS_ROOTFS/usr/include/linux/version.h"

echo ""
echo "=== Building Glibc ==="
BUILD_DIR="$PROJECT_ROOT/lfs/build/cross-tools"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

rm -rf "glibc-$GLIBC_VERSION"
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

echo "✓ Glibc installed"

echo ""
echo "=== Building Libstdc++ ==="
cd "$BUILD_DIR"
rm -rf "gcc-$GCC_VERSION"
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

rm -v "$LFS_ROOTFS/usr/lib/lib{stdc++,stdc++fs,supc++}.la" 2>/dev/null || true

echo "✓ Libstdc++ installed"
echo ""
echo "✓✓✓ Phase 2 Complete! ✓✓✓"
