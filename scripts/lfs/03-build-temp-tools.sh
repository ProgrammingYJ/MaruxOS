#!/usr/bin/env bash
# MaruxOS LFS - Build Temporary Tools (Chapter 6)
# This builds temporary tools using the cross-compilation toolchain

set -e
set -o pipefail

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/config/marux-release.conf"
source "$PROJECT_ROOT/config/lfs-config.conf"
source "$PROJECT_ROOT/config/lfs-versions.conf"

# LFS directory (points to target rootfs)
LFS="$LFS_ROOTFS"

# Build configuration
export PATH="$LFS_TOOLS/bin:$PATH"
export CONFIG_SITE="$LFS/usr/share/config.site"
export MAKEFLAGS="-j$(nproc)"

SOURCES_DIR="$LFS_SOURCES"
BUILD_DIR="$LFS_BUILD/temp-tools"

mkdir -p "$BUILD_DIR"

echo "========================================"
echo "MaruxOS LFS - Temporary Tools Build"
echo "========================================"
echo ""
echo "This will build temporary tools:"
echo "  - M4, Ncurses, Bash"
echo "  - Coreutils, Diffutils, File"
echo "  - Findutils, Gawk, Grep"
echo "  - Gzip, Make, Patch, Sed"
echo "  - Tar, Xz"
echo "  - Binutils Pass 2"
echo "  - GCC Pass 2"
echo ""
echo "Estimated time: 3-6 hours"
echo ""

# Helper function to extract and build
build_package() {
    local name=$1
    local version=$2
    local archive=$3
    local build_commands=$4

    echo ""
    echo "=== Building $name $version ==="
    echo ""

    cd "$BUILD_DIR"

    # Extract
    if [ ! -d "$name-$version" ]; then
        tar -xf "$SOURCES_DIR/$archive"
    fi

    cd "$name-$version"

    # Execute build commands
    eval "$build_commands"

    # Cleanup
    cd "$BUILD_DIR"
    rm -rf "$name-$version"

    echo "✓ $name $version installed"
}

#================================================
# Phase 6.1: M4
#================================================
if [ ! -f "$LFS/usr/bin/m4" ]; then
    build_package "m4" "$M4_VERSION" "m4-$M4_VERSION.tar.xz" '
        ./configure --prefix=/usr   \
                    --host=$LFS_TGT \
                    --build=$(build-aux/config.guess)
        make
        make DESTDIR=$LFS install
    '
else
    echo "✓ M4 already installed"
fi

#================================================
# Phase 6.2: Ncurses
#================================================
if [ ! -f "$LFS/usr/bin/ncurses6-config" ]; then
    build_package "ncurses" "6.4-20230520" "ncurses-6.4-20230520.tar.xz" '
        sed -i s/mawk// configure
        mkdir build
        pushd build
          ../configure
          make -C include
          make -C progs tic
        popd
        ./configure --prefix=/usr                \
                    --host=$LFS_TGT              \
                    --build=$(./config.guess)    \
                    --mandir=/usr/share/man      \
                    --with-manpage-format=normal \
                    --with-shared                \
                    --without-normal             \
                    --without-cxx                \
                    --without-debug              \
                    --without-ada                \
                    --disable-stripping          \
                    --enable-widec
        make
        make DESTDIR=$LFS TIC_PATH=$(pwd)/build/progs/tic install
        echo "INPUT(-lncursesw)" > $LFS/usr/lib/libncurses.so
    '
else
    echo "✓ Ncurses already installed"
fi

#================================================
# Phase 6.3: Bash
#================================================
if [ ! -f "$LFS/usr/bin/bash" ]; then
    build_package "bash" "$BASH_VERSION" "bash-$BASH_VERSION.tar.gz" '
        ./configure --prefix=/usr                      \
                    --build=$(sh support/config.guess) \
                    --host=$LFS_TGT                    \
                    --without-bash-malloc
        make
        make DESTDIR=$LFS install
        mkdir -p $LFS/bin
        ln -svf bash $LFS/bin/sh
    '
else
    echo "✓ Bash already installed"
fi

#================================================
# Phase 6.4: Coreutils
#================================================
if [ ! -f "$LFS/usr/bin/ls" ]; then
    build_package "coreutils" "$COREUTILS_VERSION" "coreutils-$COREUTILS_VERSION.tar.xz" '
        ./configure --prefix=/usr                     \
                    --host=$LFS_TGT                   \
                    --build=$(build-aux/config.guess) \
                    --enable-install-program=hostname \
                    --enable-no-install-program=kill,uptime
        make
        make DESTDIR=$LFS install
        mv -v $LFS/usr/bin/chroot $LFS/usr/sbin
        mkdir -pv $LFS/usr/share/man/man8
        mv -v $LFS/usr/share/man/man1/chroot.1 $LFS/usr/share/man/man8/chroot.8
        sed -i "s/\"1\"/\"8\"/" $LFS/usr/share/man/man8/chroot.8
    '
else
    echo "✓ Coreutils already installed"
fi

#================================================
# Phase 6.5: Diffutils
#================================================
if [ ! -f "$LFS/usr/bin/diff" ]; then
    build_package "diffutils" "$DIFFUTILS_VERSION" "diffutils-$DIFFUTILS_VERSION.tar.xz" '
        ./configure --prefix=/usr   \
                    --host=$LFS_TGT \
                    --build=$(./build-aux/config.guess)
        make
        make DESTDIR=$LFS install
    '
else
    echo "✓ Diffutils already installed"
fi

#================================================
# Phase 6.6: File
#================================================
if [ ! -f "$LFS/usr/bin/file" ]; then
    build_package "file" "5.45" "file-5.45.tar.gz" '
        mkdir build
        pushd build
          ../configure --disable-bzlib      \
                       --disable-libseccomp \
                       --disable-xzlib      \
                       --disable-zlib
          make
        popd
        ./configure --prefix=/usr --host=$LFS_TGT --build=$(./config.guess)
        make FILE_COMPILE=$(pwd)/build/src/file
        make DESTDIR=$LFS install
        rm -v $LFS/usr/lib/libmagic.la
    '
else
    echo "✓ File already installed"
fi

#================================================
# Phase 6.7: Findutils
#================================================
if [ ! -f "$LFS/usr/bin/find" ]; then
    build_package "findutils" "$FINDUTILS_VERSION" "findutils-$FINDUTILS_VERSION.tar.xz" '
        ./configure --prefix=/usr                   \
                    --localstatedir=/var/lib/locate \
                    --host=$LFS_TGT                 \
                    --build=$(build-aux/config.guess)
        make
        make DESTDIR=$LFS install
    '
else
    echo "✓ Findutils already installed"
fi

#================================================
# Phase 6.8: Gawk
#================================================
if [ ! -f "$LFS/usr/bin/gawk" ]; then
    build_package "gawk" "$GAWK_VERSION" "gawk-$GAWK_VERSION.tar.xz" '
        sed -i "s/extras//" Makefile.in
        ./configure --prefix=/usr   \
                    --host=$LFS_TGT \
                    --build=$(build-aux/config.guess)
        make
        make DESTDIR=$LFS install
    '
else
    echo "✓ Gawk already installed"
fi

#================================================
# Phase 6.9: Grep
#================================================
if [ ! -f "$LFS/usr/bin/grep" ]; then
    build_package "grep" "$GREP_VERSION" "grep-$GREP_VERSION.tar.xz" '
        ./configure --prefix=/usr   \
                    --host=$LFS_TGT \
                    --build=$(./build-aux/config.guess)
        make
        make DESTDIR=$LFS install
    '
else
    echo "✓ Grep already installed"
fi

#================================================
# Phase 6.10: Gzip
#================================================
if [ ! -f "$LFS/usr/bin/gzip" ]; then
    build_package "gzip" "$GZIP_VERSION" "gzip-$GZIP_VERSION.tar.xz" '
        ./configure --prefix=/usr --host=$LFS_TGT
        make
        make DESTDIR=$LFS install
    '
else
    echo "✓ Gzip already installed"
fi

#================================================
# Phase 6.11: Make
#================================================
if [ ! -f "$LFS/usr/bin/make" ]; then
    build_package "make" "$MAKE_VERSION" "make-$MAKE_VERSION.tar.gz" '
        ./configure --prefix=/usr   \
                    --without-guile \
                    --host=$LFS_TGT \
                    --build=$(build-aux/config.guess)
        make
        make DESTDIR=$LFS install
    '
else
    echo "✓ Make already installed"
fi

#================================================
# Phase 6.12: Patch
#================================================
if [ ! -f "$LFS/usr/bin/patch" ]; then
    build_package "patch" "2.7.6" "patch-2.7.6.tar.xz" '
        ./configure --prefix=/usr   \
                    --host=$LFS_TGT \
                    --build=$(build-aux/config.guess)
        make
        make DESTDIR=$LFS install
    '
else
    echo "✓ Patch already installed"
fi

#================================================
# Phase 6.13: Sed
#================================================
if [ ! -f "$LFS/usr/bin/sed" ]; then
    build_package "sed" "$SED_VERSION" "sed-$SED_VERSION.tar.xz" '
        ./configure --prefix=/usr   \
                    --host=$LFS_TGT \
                    --build=$(./build-aux/config.guess)
        make
        make DESTDIR=$LFS install
    '
else
    echo "✓ Sed already installed"
fi

#================================================
# Phase 6.14: Tar
#================================================
if [ ! -f "$LFS/usr/bin/tar" ]; then
    build_package "tar" "$TAR_VERSION" "tar-$TAR_VERSION.tar.xz" '
        ./configure --prefix=/usr                     \
                    --host=$LFS_TGT                   \
                    --build=$(build-aux/config.guess)
        make
        make DESTDIR=$LFS install
    '
else
    echo "✓ Tar already installed"
fi

#================================================
# Phase 6.15: Xz
#================================================
if [ ! -f "$LFS/usr/bin/xz" ]; then
    build_package "xz" "$XZ_VERSION" "xz-$XZ_VERSION.tar.xz" '
        ./configure --prefix=/usr                     \
                    --host=$LFS_TGT                   \
                    --build=$(build-aux/config.guess) \
                    --disable-static                  \
                    --docdir=/usr/share/doc/xz-$XZ_VERSION
        make
        make DESTDIR=$LFS install
        rm -v $LFS/usr/lib/liblzma.la
    '
else
    echo "✓ Xz already installed"
fi

#================================================
# Phase 6.16: Binutils - Pass 2
#================================================
if [ ! -f "$LFS/usr/bin/ld" ]; then
    echo ""
    echo "=== Phase 6.16: Binutils Pass 2 ==="
    echo ""

    cd "$BUILD_DIR"
    rm -rf binutils-$BINUTILS_VERSION
    tar -xf "$SOURCES_DIR/binutils-$BINUTILS_VERSION.tar.xz"
    cd binutils-$BINUTILS_VERSION

    sed '6009s/$add_dir//' -i ltmain.sh

    mkdir -v build
    cd build

    ../configure                   \
        --prefix=/usr              \
        --build=$(../config.guess) \
        --host=$LFS_TGT            \
        --disable-nls              \
        --enable-shared            \
        --enable-gprofng=no        \
        --disable-werror           \
        --enable-64-bit-bfd        \
        --enable-default-hash-style=gnu

    make MAKEINFO=true
    make DESTDIR=$LFS install MAKEINFO=true

    rm -v $LFS/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}

    cd "$BUILD_DIR"
    rm -rf binutils-$BINUTILS_VERSION

    echo "✓ Binutils Pass 2 installed"
else
    echo "✓ Binutils Pass 2 already installed"
fi

#================================================
# Phase 6.17: GCC - Pass 2
#================================================
if [ ! -f "$LFS/usr/bin/gcc" ]; then
    echo ""
    echo "=== Phase 6.17: GCC Pass 2 ==="
    echo ""

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

    # Apply LFS patches if needed
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
        --disable-libcody                              \
        --enable-languages=c

    make MAKEINFO=true \
        CXXFLAGS="-I$LFS/tools/x86_64-maruxos-linux-gnu/include/c++/13.2.0 -I$LFS/tools/x86_64-maruxos-linux-gnu/include/c++/13.2.0/x86_64-maruxos-linux-gnu"
    make DESTDIR=$LFS install MAKEINFO=true

    ln -sv gcc $LFS/usr/bin/cc

    cd "$BUILD_DIR"
    rm -rf gcc-$GCC_VERSION

    echo "✓ GCC Pass 2 installed"
else
    echo "✓ GCC Pass 2 already installed"
fi

echo ""
echo "========================================"
echo "Temporary Tools Build Complete!"
echo "========================================"
echo ""
echo "All temporary tools have been built successfully."
echo ""
echo "Next step: Enter chroot and build additional tools"
echo ""
