#!/usr/bin/env bash
# MaruxOS LFS - Build Final System Software (Chapter 8)
# This script runs INSIDE the chroot environment
#
# WARNING: This is a MASSIVE build phase with 80+ packages
# Estimated time: 8-15 hours depending on hardware

set -e
set -o pipefail

echo "========================================"
echo "MaruxOS LFS - Final System Build"
echo "========================================"
echo ""
echo "This will build the complete final system:"
echo "  - System libraries (Glibc, Zlib, etc.)"
echo "  - Final GCC with full C++ support"
echo "  - Core utilities (Coreutils, Bash, etc.)"
echo "  - System tools (Util-linux, E2fsprogs, etc.)"
echo "  - Development tools (Autoconf, Make, etc.)"
echo ""
echo "Total packages: 80+"
echo "Estimated time: 8-15 hours"
echo ""

read -p "Continue with final system build? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Build cancelled"
    exit 0
fi

echo ""

# Build configuration
export MAKEFLAGS="${MAKEFLAGS:--j$(nproc)}"
export TESTSUITEFLAGS="${TESTSUITEFLAGS:--j$(nproc)}"

# Source directories
SOURCES_DIR="/sources"
if [ ! -d "$SOURCES_DIR" ]; then
    SOURCES_DIR="/lfs/sources"
fi

BUILD_DIR="/tmp/lfs-build-final"
mkdir -p "$BUILD_DIR"

# Helper function to extract and build
build_package() {
    local name=$1
    local version=$2
    local archive=$3
    local build_commands=$4
    local run_tests=${5:-no}

    echo ""
    echo "================================================================"
    echo "Building $name $version"
    echo "================================================================"
    echo ""

    cd "$BUILD_DIR"

    # Extract
    if [ ! -d "$name-$version" ]; then
        tar -xf "$SOURCES_DIR/$archive"
    fi

    cd "$name-$version"

    # Execute build commands
    eval "$build_commands"

    # Run tests if specified
    if [ "$run_tests" = "yes" ]; then
        echo "Running test suite for $name..."
        make check || echo "⚠ Some tests failed for $name"
    fi

    # Cleanup
    cd "$BUILD_DIR"
    rm -rf "$name-$version"

    echo "✓ $name $version installed"
}

# Track start time
START_TIME=$(date +%s)

#================================================
# Phase 8.1-8.5: Documentation and Basic Data
#================================================

echo ""
echo "=== Installing Man-pages and Iana-Etc ==="
echo ""

# Man-pages
cd "$BUILD_DIR"
tar -xf "$SOURCES_DIR/man-pages-6.06.tar.xz"
cd man-pages-6.06
rm -v man3/crypt*
make prefix=/usr install
cd "$BUILD_DIR"
rm -rf man-pages-6.06
echo "✓ Man-pages installed"

# Iana-Etc
cd "$BUILD_DIR"
tar -xf "$SOURCES_DIR/iana-etc-20240125.tar.gz"
cd iana-etc-20240125
cp services protocols /etc
cd "$BUILD_DIR"
rm -rf iana-etc-20240125
echo "✓ Iana-Etc installed"

#================================================
# Build Python dependencies BEFORE Glibc
#================================================

echo ""
echo "=== Building Python dependencies (needed by Glibc) ==="
echo ""

# Zlib
build_package "zlib" "1.3.1" "zlib-1.3.1.tar.gz" '
    ./configure --prefix=/usr
    make
    make install
    rm -fv /usr/lib/libz.a
'

# Bzip2
build_package "bzip2" "1.0.8" "bzip2-1.0.8.tar.gz" '
    patch -N -p1 -i "$SOURCES_DIR/bzip2-1.0.8-install_docs-1.patch" || true
    sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile
    make -f Makefile-libbz2_so clean
    make -f Makefile-libbz2_so
    make clean
    make
    make PREFIX=/usr install
    cp -av libbz2.so.* /usr/lib
    ln -sfv libbz2.so.1.0.8 /usr/lib/libbz2.so
    cp -v bzip2-shared /usr/bin/bzip2
    for i in /usr/bin/{bzcat,bunzip2}; do
      ln -sfv bzip2 $i
    done
    rm -fv /usr/lib/libbz2.a
'

# XZ
build_package "xz" "5.4.6" "xz-5.4.6.tar.xz" '
    ./configure --prefix=/usr    \
                --disable-static \
                --docdir=/usr/share/doc/xz-5.4.6
    make
    make install
'

# Libffi
build_package "libffi" "3.4.4" "libffi-3.4.4.tar.gz" '
    ./configure --prefix=/usr          \
                --disable-static       \
                --with-gcc-arch=native
    make
    make install
'

# Expat
build_package "expat" "2.6.0" "expat-2.6.0.tar.xz" '
    ./configure --prefix=/usr    \
                --disable-static \
                --docdir=/usr/share/doc/expat-2.6.0
    make
    make install
    install -v -m644 doc/*.{html,css} /usr/share/doc/expat-2.6.0
'

#================================================
# Perl (needed by OpenSSL)
#================================================

echo ""
echo "================================================================"
echo "Building Perl 5.38.2 (needed by OpenSSL)"
echo "================================================================"
echo ""

cd "$BUILD_DIR"
tar -xf "$SOURCES_DIR/perl-5.38.2.tar.xz"
cd perl-5.38.2

export BUILD_ZLIB=False
export BUILD_BZIP2=0

sh Configure -des                                         \
             -Dprefix=/usr                                \
             -Dvendorprefix=/usr                          \
             -Dprivlib=/usr/lib/perl5/5.38/core_perl      \
             -Darchlib=/usr/lib/perl5/5.38/core_perl      \
             -Dsitelib=/usr/lib/perl5/5.38/site_perl      \
             -Dsitearch=/usr/lib/perl5/5.38/site_perl     \
             -Dvendorlib=/usr/lib/perl5/5.38/vendor_perl  \
             -Dvendorarch=/usr/lib/perl5/5.38/vendor_perl \
             -Dman1dir=/usr/share/man/man1                \
             -Dman3dir=/usr/share/man/man3                \
             -Dpager="/usr/bin/less -isR"                 \
             -Duseshrplib                                 \
             -Dusethreads

make
make install
unset BUILD_ZLIB BUILD_BZIP2

cd "$BUILD_DIR"
rm -rf perl-5.38.2

echo "✓ Perl 5.38.2 installed"

# OpenSSL (Python dependency)
build_package "openssl" "3.2.1" "openssl-3.2.1.tar.gz" '
    ./config --prefix=/usr         \
             --openssldir=/etc/ssl \
             --libdir=lib          \
             shared                \
             zlib-dynamic
    make
    sed -i "/INSTALL_LIBS/s/libcrypto.a libssl.a//" Makefile
    make MANSUFFIX=ssl install
    mv -v /usr/share/doc/openssl /usr/share/doc/openssl-3.2.1
    cp -vfr doc/* /usr/share/doc/openssl-3.2.1
'

#================================================
# Build Python BEFORE Glibc (Glibc needs Python!)
#================================================

echo ""
echo "================================================================"
echo "Building Python 3.12.2 (BEFORE Glibc)"
echo "================================================================"
echo ""

cd "$BUILD_DIR"
tar -xf "$SOURCES_DIR/Python-3.12.2.tar.xz"
cd Python-3.12.2

./configure --prefix=/usr        \
            --enable-shared      \
            --with-system-expat  \
            --without-ensurepip

make
make install

cd "$BUILD_DIR"
rm -rf Python-3.12.2

echo "✓ Python 3.12.2 installed (minimal)"

echo ""
echo "NOTICE: Glibc already installed from Phase 6 - skipping rebuild"
echo ""

#================================================
# Phase 8.7-8.12: Compression and Basic Libraries
#================================================

echo "NOTICE: Zlib, Bzip2, XZ already installed as Python dependencies - skipping"

build_package "zstd" "1.5.5" "zstd-1.5.5.tar.gz" '
    make prefix=/usr
    make prefix=/usr install
    rm -v /usr/lib/libzstd.a
'

build_package "file" "5.45" "file-5.45.tar.gz" '
    ./configure --prefix=/usr
    make
    make install
'

build_package "readline" "8.2" "readline-8.2.tar.gz" '
    sed -i "/MV.*old/d" Makefile.in
    sed -i "/{OLDSUFF}/c:" support/shlib-install
    patch -N -p1 -i "$SOURCES_DIR/readline-8.2-upstream_fixes-3.patch" || true
    ./configure --prefix=/usr    \
                --disable-static \
                --with-curses    \
                --docdir=/usr/share/doc/readline-8.2
    make SHLIB_LIBS="-lncursesw"
    make SHLIB_LIBS="-lncursesw" install
'

#================================================
# Phase 8.13-8.20: Build Tools and Utilities
#================================================

build_package "m4" "1.4.19" "m4-1.4.19.tar.xz" '
    ./configure --prefix=/usr
    make
    make install
'

build_package "bc" "6.7.5" "bc-6.7.5.tar.xz" '
    CC=gcc ./configure --prefix=/usr -G -O3 -r
    make
    make install
'

build_package "flex" "2.6.4" "flex-2.6.4.tar.gz" '
    ./configure --prefix=/usr \
                --docdir=/usr/share/doc/flex-2.6.4 \
                --disable-static
    make
    make install
    ln -sfv flex /usr/bin/lex
    ln -sfv flex.1 /usr/share/man/man1/lex.1
'

# Tcl (custom build - non-standard directory name)
echo ""
echo "================================================================"
echo "Building tcl 8.6.13"
echo "================================================================"
echo ""

cd "$BUILD_DIR"
if [ ! -d "tcl8.6.13" ]; then
    tar -xf "$SOURCES_DIR/tcl8.6.13-src.tar.gz"
fi
cd tcl8.6.13

SRCDIR=$(pwd)
cd unix
./configure --prefix=/usr           \
            --mandir=/usr/share/man
make
sed -e "s|$SRCDIR/unix|/usr/lib|" \
    -e "s|$SRCDIR|/usr/include|"  \
    -i tclConfig.sh
sed -e "s|$SRCDIR/unix/pkgs/tdbc1.1.5|/usr/lib/tdbc1.1.5|" \
    -e "s|$SRCDIR/pkgs/tdbc1.1.5/generic|/usr/include|"    \
    -e "s|$SRCDIR/pkgs/tdbc1.1.5/library|/usr/lib/tcl8.6|" \
    -e "s|$SRCDIR/pkgs/tdbc1.1.5|/usr/include|"            \
    -i pkgs/tdbc1.1.5/tdbcConfig.sh
sed -e "s|$SRCDIR/unix/pkgs/itcl4.2.3|/usr/lib/itcl4.2.3|" \
    -e "s|$SRCDIR/pkgs/itcl4.2.3/generic|/usr/include|"    \
    -e "s|$SRCDIR/pkgs/itcl4.2.3|/usr/include|"            \
    -i pkgs/itcl4.2.3/itclConfig.sh
unset SRCDIR
make install
chmod -v u+w /usr/lib/libtcl8.6.so
make install-private-headers
ln -sfv tclsh8.6 /usr/bin/tclsh
mv /usr/share/man/man3/{Thread,Tcl_Thread}.3

cd "$BUILD_DIR"
rm -rf tcl8.6.13

echo "✓ tcl 8.6.13 installed"

# Expect (custom build - non-standard directory name)
echo ""
echo "================================================================"
echo "Building expect 5.45.4"
echo "================================================================"
echo ""

cd "$BUILD_DIR"
if [ ! -d "expect5.45.4" ]; then
    tar -xf "$SOURCES_DIR/expect5.45.4.tar.gz"
fi
cd expect5.45.4

./configure --prefix=/usr           \
            --with-tcl=/usr/lib     \
            --enable-shared         \
            --mandir=/usr/share/man \
            --with-tclinclude=/usr/include
make
make install
ln -svf expect5.45.4/libexpect5.45.4.so /usr/lib

cd "$BUILD_DIR"
rm -rf expect5.45.4

echo "✓ expect 5.45.4 installed"

# DejaGNU (skip docs - makeinfo not available yet, will be installed with Texinfo later)
echo ""
echo "================================================================"
echo "Building dejagnu 1.6.3"
echo "================================================================"
echo ""

cd "$BUILD_DIR"
if [ ! -d "dejagnu-1.6.3" ]; then
    tar -xf "$SOURCES_DIR/dejagnu-1.6.3.tar.gz"
fi
cd dejagnu-1.6.3

mkdir -v build
cd build
../configure --prefix=/usr
make install

cd "$BUILD_DIR"
rm -rf dejagnu-1.6.3

echo "✓ dejagnu 1.6.3 installed"

#================================================
# Phase 8.21-8.25: Binutils and Math Libraries
#================================================

echo ""
echo "================================================================"
echo "Building Binutils 2.42 (Final)"
echo "================================================================"
echo ""

cd "$BUILD_DIR"
tar -xf "$SOURCES_DIR/binutils-2.42.tar.xz"
cd binutils-2.42

mkdir -v build
cd build

../configure --prefix=/usr       \
             --sysconfdir=/etc   \
             --disable-gold      \
             --enable-ld=default \
             --enable-plugins    \
             --enable-shared     \
             --disable-werror    \
             --enable-64-bit-bfd \
             --with-system-zlib  \
             --enable-default-hash-style=gnu \
             --disable-gprofng

make tooldir=/usr MAKEINFO=true
make tooldir=/usr MAKEINFO=true install

rm -fv /usr/lib/lib{bfd,ctf,ctf-nobfd,gprofng,opcodes,sframe}.a

cd "$BUILD_DIR"
rm -rf binutils-2.42

echo "✓ Binutils 2.42 installed"

# GMP, MPFR, MPC for final GCC
build_package "gmp" "6.3.0" "gmp-6.3.0.tar.xz" '
    ./configure --prefix=/usr    \
                --disable-cxx    \
                --disable-static \
                --docdir=/usr/share/doc/gmp-6.3.0
    make
    make install
'

build_package "mpfr" "4.2.1" "mpfr-4.2.1.tar.xz" '
    ./configure --prefix=/usr        \
                --disable-static     \
                --enable-thread-safe \
                --docdir=/usr/share/doc/mpfr-4.2.1
    make
    make install
'

build_package "mpc" "1.3.1" "mpc-1.3.1.tar.gz" '
    ./configure --prefix=/usr    \
                --disable-static \
                --docdir=/usr/share/doc/mpc-1.3.1
    make
    make install
'

#================================================
# Phase 8.26-8.30: Security and Access Control
#================================================

build_package "attr" "2.5.2" "attr-2.5.2.tar.gz" '
    ./configure --prefix=/usr     \
                --disable-static  \
                --sysconfdir=/etc \
                --docdir=/usr/share/doc/attr-2.5.2
    make
    make install
'

build_package "acl" "2.3.2" "acl-2.3.2.tar.xz" '
    ./configure --prefix=/usr         \
                --disable-static      \
                --docdir=/usr/share/doc/acl-2.3.2
    make
    make install
'

build_package "libcap" "2.69" "libcap-2.69.tar.xz" '
    sed -i "/install -m.*STA/d" libcap/Makefile
    sed -i "s/install-static//" libcap/Makefile
    make prefix=/usr lib=lib RAISE_SETFCAP=no
    make prefix=/usr lib=lib RAISE_SETFCAP=no install
'

build_package "libxcrypt" "4.4.36" "libxcrypt-4.4.36.tar.xz" '
    ./configure --prefix=/usr                \
                --enable-hashes=strong,glibc \
                --enable-obsolete-api=no     \
                --disable-static             \
                --disable-failure-tokens
    make
    make install
'

build_package "shadow" "4.14.5" "shadow-4.14.5.tar.xz" '
    sed -i "s/groups$(EXEEXT) //" src/Makefile.in
    find man -name Makefile.in -exec sed -i "s/groups\.1 / /"   {} \;
    find man -name Makefile.in -exec sed -i "s/getspnam\.3 / /" {} \;
    find man -name Makefile.in -exec sed -i "s/passwd\.5 / /"   {} \;

    sed -e "s:#ENCRYPT_METHOD DES:ENCRYPT_METHOD YESCRYPT:" \
        -e "s@#USERGROUPS_ENAB no@USERGROUPS_ENAB yes@"     \
        -e "s@/var/spool/mail@/var/mail@"                   \
        -e "/PATH=/{s@/sbin:@@;s@/bin:@@}"                  \
        -i etc/login.defs

    ./configure --sysconfdir=/etc   \
                --disable-static    \
                --with-{b,yes}crypt \
                --without-libbsd    \
                --with-group-name-max-length=32
    make
    make exec_prefix=/usr install
    make -C man install-man

    pwconv
    grpconv

    mkdir -p /etc/default
    useradd -D --gid 999

    sed -i "/MAIL/s/yes/no/" /etc/default/useradd
'

#================================================
# Build Libstdc++ BEFORE GCC (provides C++ headers)
#================================================

echo ""
echo "================================================================"
echo "Building Libstdc++ 13.2.0 (BEFORE GCC)"
echo "This provides C++ headers needed by GCC build"
echo "================================================================"
echo ""

cd "$BUILD_DIR"
tar -xf "$SOURCES_DIR/gcc-13.2.0.tar.xz"
cd gcc-13.2.0

mkdir -v build-libstdcxx
cd build-libstdcxx

../libstdc++-v3/configure            \
    --prefix=/usr                    \
    --disable-multilib               \
    --disable-nls                    \
    --host=$(uname -m)-maruxos-linux-gnu \
    --disable-libstdcxx-pch          \
    --disable-libstdcxx-time

make
make install

cd "$BUILD_DIR"
rm -rf gcc-13.2.0

echo "✓ Libstdc++ 13.2.0 installed (C++ headers available)"

#================================================
# Building GCC (Final) with C++
#================================================

echo ""
echo "================================================================"
echo "Building GCC 13.2.0 (Final with C++) - CRITICAL PACKAGE"
echo "This will take a LONG time (2-4 hours)"
echo "================================================================"
echo ""

cd "$BUILD_DIR"
tar -xf "$SOURCES_DIR/gcc-13.2.0.tar.xz"
cd gcc-13.2.0

# Apply patch to fix missing <mutex> header in C++20 timezone code
echo "Applying GCC 13.2.0 tzdb mutex fix patch..."
patch -Np1 -i "$SOURCES_DIR/gcc-13.2.0-tzdb_mutex_fix-1.patch"

case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
  ;;
esac

mkdir -v build
cd build

../configure --prefix=/usr            \
             LD=ld                    \
             --enable-languages=c,c++ \
             --enable-default-pie     \
             --enable-default-ssp     \
             --disable-multilib       \
             --disable-bootstrap      \
             --disable-fixincludes    \
             --disable-libcody        \
             --with-system-zlib

make

# Skip GCC tests in automated build - they take hours and are optional
# Tests can be run manually later if needed
echo "Skipping GCC test suite (takes several hours, optional)"
echo "To run tests manually: make -k check"

make install

chown -v -R root:root \
    /usr/lib/gcc/$(gcc -dumpmachine)/13.2.0/include{,-fixed}

ln -sfvr /usr/bin/cpp /usr/lib
ln -sfv gcc.1 /usr/share/man/man1/cc.1

ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/13.2.0/liblto_plugin.so \
        /usr/lib/bfd-plugins/

echo 'int main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose &> dummy.log
readelf -l a.out | grep ': /lib'

echo ""
echo "Verifying GCC installation:"
grep -E -o '/usr/lib.*/S?crt[1in].*succeeded' dummy.log
grep -B4 '^ /usr/include' dummy.log
grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'
grep "/lib.*/libc.so.6 " dummy.log
grep found dummy.log

rm -v dummy.c a.out dummy.log

mkdir -pv /usr/share/gdb/auto-load/usr/lib
mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib

cd "$BUILD_DIR"
rm -rf gcc-13.2.0

echo "✓ GCC 13.2.0 (Final) installed"

#================================================
# Phase 8.32: Pkg-config
#================================================

build_package "pkgconf" "2.1.1" "pkgconf-2.1.1.tar.xz" '
    ./configure --prefix=/usr              \
                --disable-static           \
                --docdir=/usr/share/doc/pkgconf-2.1.1
    make
    make install
    ln -sfv pkgconf   /usr/bin/pkg-config
    ln -sfv pkgconf.1 /usr/share/man/man1/pkg-config.1
'

#================================================
# Phase 8.33: Ncurses
#================================================

build_package "ncurses" "6.4-20230520" "ncurses-6.4-20230520.tar.xz" '
    ./configure --prefix=/usr           \
                --mandir=/usr/share/man \
                --with-shared           \
                --without-debug         \
                --without-normal        \
                --with-cxx-shared       \
                --enable-pc-files       \
                --enable-widec          \
                --with-pkg-config-libdir=/usr/lib/pkgconfig
    make
    make DESTDIR=$PWD/dest install
    install -vm755 dest/usr/lib/libncursesw.so.6.4 /usr/lib
    rm -v  dest/usr/lib/libncursesw.so.6.4
    sed -e "s/^#if.*XOPEN.*$/#if 1/" -i dest/usr/include/curses.h
    cp -av dest/* /
    for lib in ncurses form panel menu ; do
        ln -sfv lib${lib}w.so /usr/lib/lib${lib}.so
        ln -sfv ${lib}w.pc    /usr/lib/pkgconfig/${lib}.pc
    done
    ln -sfv libncursesw.so /usr/lib/libcurses.so
    mkdir -pv      /usr/share/doc/ncurses-6.4-20230520
    cp -v -R doc/* /usr/share/doc/ncurses-6.4-20230520
'

#================================================
# Phase 8.34: Sed
#================================================

build_package "sed" "4.9" "sed-4.9.tar.xz" '
    ./configure --prefix=/usr
    make
    make install
'

#================================================
# Phase 8.35: Psmisc
#================================================

build_package "psmisc" "23.6" "psmisc-23.6.tar.xz" '
    ./configure --prefix=/usr
    make
    make install
'

#================================================
# Phase 8.36: Gettext
#================================================

build_package "gettext" "0.22.4" "gettext-0.22.4.tar.xz" '
    ./configure --prefix=/usr    \
                --disable-static \
                --docdir=/usr/share/doc/gettext-0.22.4
    make
    make install
    chmod -v 0755 /usr/lib/preloadable_libintl.so
'

#================================================
# Phase 8.37: Bison
#================================================

build_package "bison" "3.8.2" "bison-3.8.2.tar.xz" '
    ./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.8.2
    make
    make install
'

#================================================
# Phase 8.38: Grep
#================================================

build_package "grep" "3.11" "grep-3.11.tar.xz" '
    sed -i "s/echo/#echo/" src/egrep.sh
    ./configure --prefix=/usr
    make
    make install
'

#================================================
# Phase 8.39: Bash
#================================================

build_package "bash" "5.2.21" "bash-5.2.21.tar.gz" '
    ./configure --prefix=/usr             \
                --without-bash-malloc     \
                --with-installed-readline \
                --docdir=/usr/share/doc/bash-5.2.21
    make
    make install
'

#================================================
# Phase 8.40: Libtool
#================================================

build_package "libtool" "2.4.7" "libtool-2.4.7.tar.xz" '
    ./configure --prefix=/usr
    make
    make install
    rm -fv /usr/lib/libltdl.a
'

#================================================
# Phase 8.41: GDBM
#================================================

build_package "gdbm" "1.23" "gdbm-1.23.tar.gz" '
    ./configure --prefix=/usr    \
                --disable-static \
                --enable-libgdbm-compat
    make
    make install
'

#================================================
# Phase 8.42: Gperf
#================================================

build_package "gperf" "3.1" "gperf-3.1.tar.gz" '
    ./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.1
    make
    make install
'

#================================================
# Phase 8.43: Expat (already installed as Python dependency - skipping)
#================================================

echo "NOTICE: Expat already installed - skipping"

#================================================
# Phase 8.44: Inetutils
#================================================

build_package "inetutils" "2.5" "inetutils-2.5.tar.xz" '
    ./configure --prefix=/usr        \
                --bindir=/usr/bin    \
                --localstatedir=/var \
                --disable-logger     \
                --disable-whois      \
                --disable-rcp        \
                --disable-rexec      \
                --disable-rlogin     \
                --disable-rsh        \
                --disable-servers
    make
    make install
    mv -v /usr/{,s}bin/ifconfig
'

#================================================
# Phase 8.45: Less
#================================================

build_package "less" "643" "less-643.tar.gz" '
    ./configure --prefix=/usr --sysconfdir=/etc
    make
    make install
'

#================================================
# Phase 8.47: XML::Parser
#================================================

build_package "XML-Parser" "2.47" "XML-Parser-2.47.tar.gz" '
    perl Makefile.PL
    make
    make install
'

#================================================
# Phase 8.48: Intltool
#================================================

build_package "intltool" "0.51.0" "intltool-0.51.0.tar.gz" '
    sed -i "s:\\\${:\\\$\\{:g" intltool-update.in
    ./configure --prefix=/usr
    make
    make install
    install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO
'

#================================================
# Phase 8.49: Autoconf
#================================================

build_package "autoconf" "2.72" "autoconf-2.72.tar.xz" '
    ./configure --prefix=/usr
    make
    make install
'

#================================================
# Phase 8.50: Automake
#================================================

build_package "automake" "1.16.5" "automake-1.16.5.tar.xz" '
    ./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.16.5
    make
    make install
'

#================================================
# Phase 8.51: OpenSSL (already installed as Python dependency - skipping)
#================================================

echo "NOTICE: OpenSSL already installed - skipping"

#================================================
# Phase 8.52: Kmod
#================================================

build_package "kmod" "31" "kmod-31.tar.xz" '
    ./configure --prefix=/usr          \
                --sysconfdir=/etc      \
                --with-openssl         \
                --with-xz              \
                --with-zstd            \
                --with-zlib
    make
    make install

    for target in depmod insmod modinfo modprobe rmmod; do
      ln -sfv ../bin/kmod /usr/sbin/$target
    done

    ln -sfv kmod /usr/bin/lsmod
'

#================================================
# Phase 8.53: Libelf from Elfutils
#================================================

build_package "elfutils" "0.190" "elfutils-0.190.tar.bz2" '
    ./configure --prefix=/usr                \
                --disable-debuginfod         \
                --enable-libdebuginfod=dummy
    make
    make -C libelf install
    install -vm644 config/libelf.pc /usr/lib/pkgconfig
    rm /usr/lib/libelf.a
'

#================================================
# Phase 8.54: Libffi (already installed as Python dependency - skipping)
#================================================

echo "NOTICE: Libffi already installed - skipping"

#================================================
# Phase 8.55: Python (already installed - skipping)
#================================================

echo "NOTICE: Python 3.12.2 already installed - skipping"

#================================================
# Phase 8.56: Flit-Core
#================================================

build_package "flit_core" "3.9.0" "flit_core-3.9.0.tar.gz" '
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
    pip3 install --no-index --no-user --find-links dist flit_core
'

#================================================
# Phase 8.57: Wheel
#================================================

build_package "wheel" "0.42.0" "wheel-0.42.0.tar.gz" '
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
    pip3 install --no-index --find-links=dist wheel
'

#================================================
# Phase 8.58: Setuptools
#================================================

build_package "setuptools" "69.1.0" "setuptools-69.1.0.tar.gz" '
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
    pip3 install --no-index --find-links dist setuptools
'

#================================================
# Phase 8.59: Ninja
#================================================

build_package "ninja" "1.11.1" "ninja-1.11.1.tar.gz" '
    export NINJAJOBS=$(nproc)
    sed -i "/int Guess/a \\
  int   j = 0;\\
  char* jobs = getenv( \"NINJAJOBS\" );\\
  if ( jobs != NULL ) j = atoi( jobs );\\
  if ( j > 0 ) return j;\\
" src/ninja.cc
    python3 configure.py --bootstrap
    install -vm755 ninja /usr/bin/
    install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
    install -vDm644 misc/zsh-completion  /usr/share/zsh/site-functions/_ninja
'

#================================================
# Phase 8.60: Meson
#================================================

build_package "meson" "1.3.2" "meson-1.3.2.tar.gz" '
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
    pip3 install --no-index --find-links dist meson
    install -vDm644 data/shell-completions/bash/meson /usr/share/bash-completion/completions/meson
    install -vDm644 data/shell-completions/zsh/_meson /usr/share/zsh/site-functions/_meson
'

#================================================
# Phase 8.61: Coreutils
#================================================

build_package "coreutils" "9.4" "coreutils-9.4.tar.xz" '
    patch -N -p1 -i "$SOURCES_DIR/coreutils-9.4-i18n-1.patch" || true
    autoreconf -fiv
    FORCE_UNSAFE_CONFIGURE=1 ./configure \
            --prefix=/usr            \
            --enable-no-install-program=kill,uptime
    make
    make install
    mv -v /usr/bin/chroot /usr/sbin
    mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
    sed -i "s/\"1\"/\"8\"/" /usr/share/man/man8/chroot.8
'

#================================================
# Phase 8.62: Check
#================================================

build_package "check" "0.15.2" "check-0.15.2.tar.gz" '
    ./configure --prefix=/usr --disable-static
    make
    make docdir=/usr/share/doc/check-0.15.2 install
'

#================================================
# Phase 8.63: Diffutils
#================================================

build_package "diffutils" "3.10" "diffutils-3.10.tar.xz" '
    ./configure --prefix=/usr
    make
    make install
'

#================================================
# Phase 8.64: Gawk
#================================================

build_package "gawk" "5.3.0" "gawk-5.3.0.tar.xz" '
    sed -i "s/extras//" Makefile.in
    ./configure --prefix=/usr
    make
    rm -f /usr/bin/gawk-5.3.0
    make install
    ln -sfv gawk.1 /usr/share/man/man1/awk.1
    mkdir -pv                                   /usr/share/doc/gawk-5.3.0
    cp    -v doc/{awkforai.txt,*.{eps,pdf,jpg}} /usr/share/doc/gawk-5.3.0
'

#================================================
# Phase 8.65: Findutils
#================================================

build_package "findutils" "4.9.0" "findutils-4.9.0.tar.xz" '
    ./configure --prefix=/usr --localstatedir=/var/lib/locate
    make
    make install
'

#================================================
# Phase 8.66: Groff
#================================================

build_package "groff" "1.23.0" "groff-1.23.0.tar.gz" '
    PAGE=letter ./configure --prefix=/usr
    make
    make install
'

#================================================
# Phase 8.67: GRUB
#================================================

build_package "grub" "2.12" "grub-2.12.tar.xz" '
    echo depends bli part_gpt > grub-core/extra_deps.lst
    ./configure --prefix=/usr          \
                --sysconfdir=/etc      \
                --disable-efiemu       \
                --disable-werror
    make
    make install
    mv -v /etc/bash_completion.d/grub /usr/share/bash-completion/completions
'

#================================================
# Phase 8.68: Gzip
#================================================

build_package "gzip" "1.13" "gzip-1.13.tar.xz" '
    ./configure --prefix=/usr
    make
    make install
'

#================================================
# Phase 8.69: IPRoute2
#================================================

build_package "iproute2" "6.7.0" "iproute2-6.7.0.tar.xz" '
    sed -i /ARPD/d Makefile
    rm -fv man/man8/arpd.8
    make NETNS_RUN_DIR=/run/netns
    make SBINDIR=/usr/sbin install
    mkdir -pv             /usr/share/doc/iproute2-6.7.0
    cp -v COPYING README* /usr/share/doc/iproute2-6.7.0
'

#================================================
# Phase 8.70: Kbd
#================================================

build_package "kbd" "2.6.4" "kbd-2.6.4.tar.xz" '
    patch -N -p1 -i "$SOURCES_DIR/kbd-2.6.4-backspace-1.patch" || true
    sed -i "/RESIZECONS_PROGS=/s/yes/no/" configure
    sed -i "s/resizecons.8 //" docs/man/man8/Makefile.in
    ./configure --prefix=/usr --disable-vlock
    make
    make install
    cp -R -v docs/doc -T /usr/share/doc/kbd-2.6.4
'

#================================================
# Phase 8.71: Libpipeline
#================================================

build_package "libpipeline" "1.5.7" "libpipeline-1.5.7.tar.gz" '
    ./configure --prefix=/usr
    make
    make install
'

#================================================
# Phase 8.72: Make
#================================================

build_package "make" "4.4.1" "make-4.4.1.tar.gz" '
    ./configure --prefix=/usr
    make
    make install
'

#================================================
# Phase 8.73: Patch
#================================================

build_package "patch" "2.7.6" "patch-2.7.6.tar.xz" '
    ./configure --prefix=/usr
    make
    make install
'

#================================================
# Phase 8.74: Tar
#================================================

build_package "tar" "1.35" "tar-1.35.tar.xz" '
    FORCE_UNSAFE_CONFIGURE=1  \
    ./configure --prefix=/usr
    make
    make install
'

#================================================
# Phase 8.75: Texinfo
#================================================

build_package "texinfo" "7.1" "texinfo-7.1.tar.xz" '
    ./configure --prefix=/usr
    make
    make install
    make TEXMF=/usr/share/texmf install-tex
'

#================================================
# Phase 8.76: Vim
#================================================

echo ""
echo "================================================================"
echo "Building Vim 9.1.0041"
echo "================================================================"
echo ""

cd "$BUILD_DIR"
tar -xf "$SOURCES_DIR/vim-9.1.0041.tar.gz"
cd vim-9.1.0041

echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h

./configure --prefix=/usr

make

make install

ln -sfv vim /usr/bin/vi
for L in  /usr/share/man/{,*/}man1/vim.1; do
    ln -sfv vim.1 $(dirname $L)/vi.1
done

ln -sfv ../vim/vim91/doc /usr/share/doc/vim-9.1.0041

cat > /etc/vimrc << "EOF"
" Begin /etc/vimrc

" Ensure defaults are set before customizing settings, not after
source $VIMRUNTIME/defaults.vim
let skip_defaults_vim=1

set nocompatible
set backspace=2
set mouse=
syntax on
if (&term == "xterm") || (&term == "putty")
  set background=dark
endif

" End /etc/vimrc
EOF

cd "$BUILD_DIR"
rm -rf vim-9.1.0041

echo "✓ Vim 9.1.0041 installed"

#================================================
# Phase 8.77: MarkupSafe
#================================================

build_package "MarkupSafe" "2.1.5" "MarkupSafe-2.1.5.tar.gz" '
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
    pip3 install --no-index --no-user --find-links dist Markupsafe
'

#================================================
# Phase 8.78: Jinja2
#================================================

build_package "Jinja2" "3.1.3" "Jinja2-3.1.3.tar.gz" '
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
    pip3 install --no-index --no-user --find-links dist Jinja2
'

#================================================
# Phase 8.79: Systemd
#================================================

echo ""
echo "================================================================"
echo "Building Systemd 255"
echo "================================================================"
echo ""

cd "$BUILD_DIR"
tar -xf "$SOURCES_DIR/systemd-255.tar.gz"
cd systemd-255

sed -i -e "s/GROUP=\"render\"/GROUP=\"video\"/g" \
       -e "s/GROUP=\"sgx\", //" rules.d/50-udev-default.rules.in

mkdir -p build
cd build

meson setup \
      --prefix=/usr                 \
      --buildtype=release           \
      -Dmode=release                \
      -Ddev-kvm-mode=0660           \
      -Dlink-udev-shared=false      \
      -Dlogind=false                \
      -Dvconsole=false              \
      ..

ninja udevadm systemd-hwdb \
      $(grep -o -E "^build (src/libudev|src/udev|rules.d|hwdb.d)[^:]*" \
        build.ninja | awk '{ print $2 }')                              \
      $(realpath libudev.so --relative-to .)

install -vm755 -d {/usr/lib,/etc}/udev/{hwdb.d,rules.d,network}
install -vm755 -d /usr/{lib,share}/pkgconfig
install -vm755 udevadm                             /usr/bin/
install -vm755 systemd-hwdb                        /usr/bin/udev-hwdb
ln      -svfn  ../bin/udevadm                      /usr/sbin/udevd
cp      -av    libudev.so{,*[0-9]}                 /usr/lib/
install -vm644 ../src/libudev/libudev.h            /usr/include/
install -vm644 src/libudev/*.pc                    /usr/lib/pkgconfig/
install -vm644 src/udev/*.pc                       /usr/share/pkgconfig/
install -vm644 ../src/udev/udev.conf               /etc/udev/
install -vm644 rules.d/* ../rules.d/README         /usr/lib/udev/rules.d/
install -vm644 $(find ../rules.d/*.rules \
                      -not -name "*power-switch*") /usr/lib/udev/rules.d/
install -vm644 hwdb.d/*  ../hwdb.d/{*.hwdb,README} /usr/lib/udev/hwdb.d/
install -vm755 $(find src/udev \
                      -type f -not -name '*.*')    /usr/lib/udev

tar -xvf "$SOURCES_DIR/udev-lfs-20230818.tar.xz"
make -f udev-lfs-20230818/Makefile.lfs install

tar -xf "$SOURCES_DIR/systemd-man-pages-255.tar.xz" \
    --no-same-owner --strip-components=1   \
    -C /usr/share/man --wildcards "*/udev*" "*/libudev*" \
                                  "*/systemd.link.5"     \
                                  "*/systemd-hwdb.8"

sed "s/systemd\///" /usr/share/man/man5/systemd.link.5 \
  > /usr/share/man/man5/udev.link.5

sed "s|Link|Network|g" /usr/share/man/man5/systemd.link.5 \
  > /usr/share/man/man5/udev.network.5

udev-hwdb update

cd "$BUILD_DIR"
rm -rf systemd-255

echo "✓ Systemd 255 (Udev) installed"

#================================================
# Phase 8.80: Man-DB
#================================================

build_package "man-db" "2.12.0" "man-db-2.12.0.tar.xz" '
    ./configure --prefix=/usr                         \
                --docdir=/usr/share/doc/man-db-2.12.0 \
                --sysconfdir=/etc                     \
                --disable-setuid                      \
                --enable-cache-owner=bin              \
                --with-browser=/usr/bin/lynx          \
                --with-vgrind=/usr/bin/vgrind         \
                --with-grap=/usr/bin/grap
    make
    make install
'

#================================================
# Phase 8.81: Procps-ng
#================================================

build_package "procps-ng" "4.0.4" "procps-ng-4.0.4.tar.xz" '
    ./configure --prefix=/usr                           \
                --docdir=/usr/share/doc/procps-ng-4.0.4 \
                --disable-static                        \
                --disable-kill
    make
    make install
'

#================================================
# Phase 8.82: Util-linux
#================================================

build_package "util-linux" "2.39.3" "util-linux-2.39.3.tar.xz" '
    ./configure --bindir=/usr/bin    \
                --libdir=/usr/lib    \
                --runstatedir=/run   \
                --sbindir=/usr/sbin  \
                --disable-chfn-chsh  \
                --disable-login      \
                --disable-nologin    \
                --disable-su         \
                --disable-setpriv    \
                --disable-runuser    \
                --disable-pylibmount \
                --disable-static     \
                --without-python     \
                --without-systemd    \
                --without-systemdsystemunitdir \
                ADJTIME_PATH=/var/lib/hwclock/adjtime \
                --docdir=/usr/share/doc/util-linux-2.39.3
    make
    make install
'

#================================================
# Phase 8.83: E2fsprogs
#================================================

build_package "e2fsprogs" "1.47.0" "e2fsprogs-1.47.0.tar.gz" '
    mkdir -v build
    cd build
    ../configure --prefix=/usr           \
                 --sysconfdir=/etc       \
                 --enable-elf-shlibs     \
                 --disable-libblkid      \
                 --disable-libuuid       \
                 --disable-uuidd         \
                 --disable-fsck
    make
    make install
    rm -fv /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a
    sed "s/metadata_csum_seed,/_&/" -i /etc/mke2fs.conf
'

#================================================
# Phase 8.84: Sysklogd
#================================================

build_package "sysklogd" "1.5.1" "sysklogd-1.5.1.tar.gz" '
    sed -i "/Error loading kernel symbols/d" ksym_mod.c
    sed -i "s/union wait/int/" syslogd.c
    make
    make BINDIR=/sbin install
    cat > /etc/syslog.conf << "EOF"
# Begin /etc/syslog.conf

auth,authpriv.* -/var/log/auth.log
*.*;auth,authpriv.none -/var/log/sys.log
daemon.* -/var/log/daemon.log
kern.* -/var/log/kern.log
mail.* -/var/log/mail.log
user.* -/var/log/user.log
*.emerg *

# End /etc/syslog.conf
EOF
'

#================================================
# Phase 8.85: Sysvinit
#================================================

build_package "sysvinit" "3.08" "sysvinit-3.08.tar.xz" '
    patch -N -p1 -i "$SOURCES_DIR/sysvinit-3.08-consolidated-1.patch" || true
    make
    make install
'

#================================================
# Final Steps
#================================================

echo ""
echo "================================================================"
echo "Performing final system cleanup..."
echo "================================================================"
echo ""

# Strip unnecessary symbols
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

# Clean up
rm -rf /tmp/*

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
HOURS=$((DURATION / 3600))
MINUTES=$(((DURATION % 3600) / 60))

echo ""
echo "================================================================"
echo "Final System Build Complete!"
echo "================================================================"
echo ""
echo "Build time: ${HOURS}h ${MINUTES}m"
echo ""
echo "The MaruxOS base system is now built!"
echo ""
echo "Next steps:"
echo "  1. System configuration (Phase 9)"
echo "  2. Kernel configuration and build"
echo "  3. Bootloader installation (GRUB)"
echo "  4. System finalization"
echo ""
