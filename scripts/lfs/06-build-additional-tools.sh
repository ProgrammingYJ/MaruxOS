#!/usr/bin/env bash
# MaruxOS LFS - Build Additional Temporary Tools (Chapter 7)
# This script runs INSIDE the chroot environment

set -e
set -o pipefail

echo "========================================"
echo "MaruxOS LFS - Additional Tools Build"
echo "========================================"
echo ""
echo "Building additional temporary tools:"
echo "  - Gettext"
echo "  - Bison"
echo "  - Perl"
echo "  - Python"
echo "  - Texinfo"
echo "  - Util-linux"
echo ""
echo "Estimated time: 1-2 hours"
echo ""

# Build configuration
export MAKEFLAGS="${MAKEFLAGS:--j$(nproc)}"

# Source directories (assuming sources are available)
SOURCES_DIR="/sources"
if [ ! -d "$SOURCES_DIR" ]; then
    SOURCES_DIR="/lfs/sources"
fi

BUILD_DIR="/tmp/lfs-build-additional"
mkdir -p "$BUILD_DIR"

# Load version information
# Note: Inside chroot, we need to source from the mounted location
if [ -f "/sources/../config/lfs-versions.conf" ]; then
    source "/sources/../config/lfs-versions.conf"
else
    # Define versions inline if config not accessible
    GETTEXT_VERSION="0.22.4"
    BISON_VERSION="3.8.2"
    PERL_VERSION="5.38.2"
    PYTHON_VERSION="3.12.2"
    TEXINFO_VERSION="7.1"
    UTIL_LINUX_VERSION="2.39.3"
fi

# Helper function to extract and build
build_package() {
    local name=$1
    local version=$2
    local archive=$3
    local build_commands=$4

    echo ""
    echo "=== Building $name $version ===="
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
# Phase 7.7: Gettext
#================================================
if [ ! -f "/usr/bin/msgfmt" ]; then
    build_package "gettext" "$GETTEXT_VERSION" "gettext-$GETTEXT_VERSION.tar.xz" '
        ./configure --disable-shared
        make
        cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin
    '
else
    echo "✓ Gettext already installed"
fi

#================================================
# Phase 7.8: Bison
#================================================
if [ ! -f "/usr/bin/bison" ]; then
    build_package "bison" "$BISON_VERSION" "bison-$BISON_VERSION.tar.xz" '
        ./configure --prefix=/usr \
                    --docdir=/usr/share/doc/bison-$BISON_VERSION
        make
        make install
    '
else
    echo "✓ Bison already installed"
fi

#================================================
# Phase 7.9: Perl
#================================================
if [ ! -f "/usr/bin/perl" ]; then
    echo ""
    echo "=== Building Perl $PERL_VERSION ===="
    echo ""

    cd "$BUILD_DIR"
    tar -xf "$SOURCES_DIR/perl-$PERL_VERSION.tar.xz"
    cd "perl-$PERL_VERSION"

    sh Configure -des                                        \
                 -Dprefix=/usr                               \
                 -Dvendorprefix=/usr                         \
                 -Duseshrplib                                \
                 -Dprivlib=/usr/lib/perl5/${PERL_VERSION%.*}/core_perl      \
                 -Darchlib=/usr/lib/perl5/${PERL_VERSION%.*}/core_perl      \
                 -Dsitelib=/usr/lib/perl5/${PERL_VERSION%.*}/site_perl      \
                 -Dsitearch=/usr/lib/perl5/${PERL_VERSION%.*}/site_perl     \
                 -Dvendorlib=/usr/lib/perl5/${PERL_VERSION%.*}/vendor_perl  \
                 -Dvendorarch=/usr/lib/perl5/${PERL_VERSION%.*}/vendor_perl

    make
    make install

    cd "$BUILD_DIR"
    rm -rf "perl-$PERL_VERSION"

    echo "✓ Perl $PERL_VERSION installed"
else
    echo "✓ Perl already installed"
fi

#================================================
# Phase 7.10: Python
#================================================
if [ ! -f "/usr/bin/python3" ]; then
    echo ""
    echo "=== Building Python $PYTHON_VERSION ===="
    echo ""

    cd "$BUILD_DIR"
    tar -xf "$SOURCES_DIR/Python-$PYTHON_VERSION.tar.xz"
    cd "Python-$PYTHON_VERSION"

    ./configure --prefix=/usr        \
                --enable-shared      \
                --without-ensurepip

    make
    make install

    cd "$BUILD_DIR"
    rm -rf "Python-$PYTHON_VERSION"

    echo "✓ Python $PYTHON_VERSION installed"
else
    echo "✓ Python already installed"
fi

#================================================
# Phase 7.11: Texinfo
#================================================
if [ ! -f "/usr/bin/makeinfo" ]; then
    build_package "texinfo" "$TEXINFO_VERSION" "texinfo-$TEXINFO_VERSION.tar.xz" '
        ./configure --prefix=/usr
        make
        make install
    '
else
    echo "✓ Texinfo already installed"
fi

#================================================
# Phase 7.12: Util-linux
#================================================
if [ ! -f "/usr/bin/mount" ]; then
    echo ""
    echo "=== Building Util-linux $UTIL_LINUX_VERSION ===="
    echo ""

    cd "$BUILD_DIR"
    tar -xf "$SOURCES_DIR/util-linux-$UTIL_LINUX_VERSION.tar.xz"
    cd "util-linux-$UTIL_LINUX_VERSION"

    mkdir -pv /var/lib/hwclock

    ./configure --libdir=/usr/lib     \
                --runstatedir=/run    \
                --disable-chfn-chsh   \
                --disable-login       \
                --disable-nologin     \
                --disable-su          \
                --disable-setpriv     \
                --disable-runuser     \
                --disable-pylibmount  \
                --disable-static      \
                --without-python      \
                ADJTIME_PATH=/var/lib/hwclock/adjtime \
                --docdir=/usr/share/doc/util-linux-$UTIL_LINUX_VERSION

    make
    make install

    cd "$BUILD_DIR"
    rm -rf "util-linux-$UTIL_LINUX_VERSION"

    echo "✓ Util-linux $UTIL_LINUX_VERSION installed"
else
    echo "✓ Util-linux already installed"
fi

#================================================
# Phase 7.13: Clean up and strip
#================================================
echo ""
echo "=== Cleaning up temporary files ==="
echo ""

rm -rf "$BUILD_DIR"

echo "Stripping debug symbols from temporary tools..."
save_usrlib="$(cd /usr/lib; ls ld-linux*[^g])
             libc.so.6
             libthread_db.so.1
             libquadmath.so.0.0.0
             libstdc++.so.6.0.32
             libitm.so.1.0.0
             libatomic.so.1.2.0"

cd /usr/lib

for LIB in $save_usrlib; do
    objcopy --only-keep-debug --compress-debug-sections=zlib $LIB $LIB.dbg
    cp $LIB /tmp/$LIB
    strip --strip-unneeded /tmp/$LIB
    objcopy --add-gnu-debuglink=$LIB.dbg /tmp/$LIB
    install -vm755 /tmp/$LIB /usr/lib
    rm /tmp/$LIB
done

online_usrbin="bash find strip"
online_usrlib="libbfd-2.41.so
               libsframe.so.1.0.0
               libhistory.so.8.2
               libncursesw.so.6.4
               libm.so.6
               libreadline.so.8.2
               libz.so.1.3
               libzstd.so.1.5.5
               $(cd /usr/lib; find libnss*.so* -type f)"

for BIN in $online_usrbin; do
    cp /usr/bin/$BIN /tmp/$BIN
    strip --strip-unneeded /tmp/$BIN
    install -vm755 /tmp/$BIN /usr/bin
    rm /tmp/$BIN
done

for LIB in $online_usrlib; do
    cp /usr/lib/$LIB /tmp/$LIB
    strip --strip-unneeded /tmp/$LIB
    install -vm755 /tmp/$LIB /usr/lib
    rm /tmp/$LIB
done

echo "✓ Cleanup complete"
echo ""

#================================================
# Backup the temporary system
#================================================
echo "=== Creating backup of temporary system ==="
echo ""

# Exit chroot for backup (note: this message is for information)
echo "Temporary tools build complete!"
echo ""
echo "IMPORTANT: Before continuing to Chapter 8, you should:"
echo "  1. Exit this chroot environment (type: exit)"
echo "  2. Create a backup of the current system"
echo "  3. Continue with Phase 8 (building the final system)"
echo ""

echo "========================================"
echo "Additional Tools Build Complete!"
echo "========================================"
echo ""
echo "All additional temporary tools installed:"
echo "  ✓ Gettext"
echo "  ✓ Bison"
echo "  ✓ Perl"
echo "  ✓ Python"
echo "  ✓ Texinfo"
echo "  ✓ Util-linux"
echo ""
echo "Next: Exit chroot and proceed to Phase 8"
echo ""
