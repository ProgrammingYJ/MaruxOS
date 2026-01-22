#!/bin/bash
# MaruxOS LFS - Phase 7 Continuation Script
# Continues from after shadow (28 packages completed)
# Skips Libstdc++ separate build - GCC will build it

set -e
set -o pipefail

export MAKEFLAGS="${MAKEFLAGS:--j$(nproc)}"
SOURCES_DIR="/sources"
[ -d "$SOURCES_DIR" ] || SOURCES_DIR="/lfs/sources"
BUILD_DIR="/tmp/lfs-build-final"
mkdir -p "$BUILD_DIR"

build_package() {
    local name=$1
    local version=$2
    local archive=$3
    local build_commands=$4

    echo ""
    echo "================================================================"
    echo "Building $name $version"
    echo "================================================================"
    echo ""

    cd "$BUILD_DIR"
    rm -rf "$name-$version" 2>/dev/null || true
    tar -xf "$SOURCES_DIR/$archive"
    cd "$name-$version"
    eval "$build_commands"
    cd "$BUILD_DIR"
    rm -rf "$name-$version"
    echo "✓ $name $version installed"
}

echo "=== Phase 7 Continuation - Starting from GCC ==="

#================================================
# GCC 13.2.0 (includes Libstdc++)
#================================================

echo ""
echo "================================================================"
echo "Building GCC 13.2.0 (Final with C++) - CRITICAL PACKAGE"
echo "This will take 2-4 hours"
echo "================================================================"
echo ""

cd "$BUILD_DIR"
rm -rf gcc-13.2.0 2>/dev/null || true
tar -xf "$SOURCES_DIR/gcc-13.2.0.tar.xz"
cd gcc-13.2.0

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
             --with-system-zlib

# Use all cores for maximum speed
make -j$(nproc)
make install

chown -v -R root:root \
    /usr/lib/gcc/$(gcc -dumpmachine)/13.2.0/include{,-fixed}

ln -sfvr /usr/bin/cpp /usr/lib
ln -sfv gcc.1 /usr/share/man/man1/cc.1
ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/13.2.0/liblto_plugin.so \
        /usr/lib/bfd-plugins/

mkdir -pv /usr/share/gdb/auto-load/usr/lib
mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib 2>/dev/null || true

cd "$BUILD_DIR"
rm -rf gcc-13.2.0

echo "✓ GCC 13.2.0 (Final) installed"

#================================================
# Pkg-config
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
# Ncurses
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
'

build_package "sed" "4.9" "sed-4.9.tar.xz" '
    ./configure --prefix=/usr
    make
    make install
'

build_package "psmisc" "23.6" "psmisc-23.6.tar.xz" '
    ./configure --prefix=/usr
    make
    make install
'

build_package "gettext" "0.22.4" "gettext-0.22.4.tar.xz" '
    ./configure --prefix=/usr    \
                --disable-static \
                --docdir=/usr/share/doc/gettext-0.22.4
    make
    make install
    chmod -v 0755 /usr/lib/preloadable_libintl.so
'

build_package "bison" "3.8.2" "bison-3.8.2.tar.xz" '
    ./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.8.2
    make
    make install
'

build_package "grep" "3.11" "grep-3.11.tar.xz" '
    sed -i "s/echo/#echo/" src/egrep.sh
    ./configure --prefix=/usr
    make
    make install
'

build_package "bash" "5.2.21" "bash-5.2.21.tar.gz" '
    ./configure --prefix=/usr             \
                --without-bash-malloc     \
                --with-installed-readline \
                --docdir=/usr/share/doc/bash-5.2.21
    make
    make install
'

build_package "libtool" "2.4.7" "libtool-2.4.7.tar.xz" '
    ./configure --prefix=/usr
    make
    make install
    rm -fv /usr/lib/libltdl.a
'

build_package "gdbm" "1.23" "gdbm-1.23.tar.gz" '
    ./configure --prefix=/usr    \
                --disable-static \
                --enable-libgdbm-compat
    make
    make install
'

build_package "gperf" "3.1" "gperf-3.1.tar.gz" '
    ./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.1
    make
    make install
'

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

build_package "less" "643" "less-643.tar.gz" '
    ./configure --prefix=/usr --sysconfdir=/etc
    make
    make install
'

build_package "XML-Parser" "2.47" "XML-Parser-2.47.tar.gz" '
    perl Makefile.PL
    make
    make install
'

build_package "intltool" "0.51.0" "intltool-0.51.0.tar.gz" '
    sed -i "s:\\\${:\\\$\\{:g" intltool-update.in
    ./configure --prefix=/usr
    make
    make install
'

build_package "autoconf" "2.72" "autoconf-2.72.tar.xz" '
    ./configure --prefix=/usr
    make
    make install
'

build_package "automake" "1.16.5" "automake-1.16.5.tar.xz" '
    ./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.16.5
    make
    make install
'

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

build_package "elfutils" "0.190" "elfutils-0.190.tar.bz2" '
    ./configure --prefix=/usr                \
                --disable-debuginfod         \
                --enable-libdebuginfod=dummy
    make
    make -C libelf install
    install -vm644 config/libelf.pc /usr/lib/pkgconfig
    rm -f /usr/lib/libelf.a
'

build_package "flit_core" "3.9.0" "flit_core-3.9.0.tar.gz" '
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
    pip3 install --no-index --no-user --find-links dist flit_core
'

build_package "wheel" "0.42.0" "wheel-0.42.0.tar.gz" '
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
    pip3 install --no-index --find-links=dist wheel
'

build_package "setuptools" "69.1.0" "setuptools-69.1.0.tar.gz" '
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
    pip3 install --no-index --find-links dist setuptools
'

build_package "ninja" "1.11.1" "ninja-1.11.1.tar.gz" '
    python3 configure.py --bootstrap
    install -vm755 ninja /usr/bin/
'

build_package "meson" "1.3.2" "meson-1.3.2.tar.gz" '
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
    pip3 install --no-index --find-links dist meson
'

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

build_package "check" "0.15.2" "check-0.15.2.tar.gz" '
    ./configure --prefix=/usr --disable-static
    make
    make install
'

build_package "diffutils" "3.10" "diffutils-3.10.tar.xz" '
    ./configure --prefix=/usr
    make
    make install
'

build_package "gawk" "5.3.0" "gawk-5.3.0.tar.xz" '
    sed -i "s/extras//" Makefile.in
    ./configure --prefix=/usr
    make
    make install
'

build_package "findutils" "4.9.0" "findutils-4.9.0.tar.xz" '
    ./configure --prefix=/usr --localstatedir=/var/lib/locate
    make
    make install
'

build_package "groff" "1.23.0" "groff-1.23.0.tar.gz" '
    PAGE=A4 ./configure --prefix=/usr
    make
    make install
'

build_package "gzip" "1.13" "gzip-1.13.tar.xz" '
    ./configure --prefix=/usr
    make
    make install
'

build_package "iproute2" "6.7.0" "iproute2-6.7.0.tar.xz" '
    sed -i /ARPD/d Makefile
    rm -fv man/man8/arpd.8
    make NETNS_RUN_DIR=/run/netns
    make SBINDIR=/usr/sbin install
'

build_package "kbd" "2.6.4" "kbd-2.6.4.tar.xz" '
    patch -Np1 -i "$SOURCES_DIR/kbd-2.6.4-backspace-1.patch" || true
    sed -i "/RESIZECONS_PROGS=/s/yes/no/" configure
    sed -i "s/resizecons.8 //" docs/man/man8/Makefile.in
    ./configure --prefix=/usr --disable-vlock
    make
    make install
'

build_package "libpipeline" "1.5.7" "libpipeline-1.5.7.tar.gz" '
    ./configure --prefix=/usr
    make
    make install
'

build_package "make" "4.4.1" "make-4.4.1.tar.gz" '
    ./configure --prefix=/usr
    make
    make install
'

build_package "patch" "2.7.6" "patch-2.7.6.tar.xz" '
    ./configure --prefix=/usr
    make
    make install
'

build_package "tar" "1.35" "tar-1.35.tar.xz" '
    FORCE_UNSAFE_CONFIGURE=1 \
    ./configure --prefix=/usr
    make
    make install
'

build_package "texinfo" "7.1" "texinfo-7.1.tar.xz" '
    ./configure --prefix=/usr
    make
    make install
'

build_package "vim" "9.1.0041" "vim-9.1.0041.tar.gz" '
    echo "#define SYS_VIMRC_FILE \"/etc/vimrc\"" >> src/feature.h
    ./configure --prefix=/usr
    make
    make install
    ln -sfv vim /usr/bin/vi
'

build_package "MarkupSafe" "2.1.5" "MarkupSafe-2.1.5.tar.gz" '
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
    pip3 install --no-index --find-links dist MarkupSafe
'

build_package "Jinja2" "3.1.3" "Jinja2-3.1.3.tar.gz" '
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
    pip3 install --no-index --find-links dist Jinja2
'

# Systemd-udev
echo ""
echo "================================================================"
echo "Building systemd-255 (udev only)"
echo "================================================================"
echo ""

cd "$BUILD_DIR"
rm -rf systemd-255 2>/dev/null || true
tar -xf "$SOURCES_DIR/systemd-255.tar.gz"
cd systemd-255

sed -i -e 's/want_libfuzzer = true/want_libfuzzer = false/' \
       -e 's/want_ossfuzz = true/want_ossfuzz = false/' meson.build

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
      $(grep -o 'build src/udev/[^ ]*' build.ninja | awk '{print $2}' | grep -v /)

install -vm755 udevadm                             /usr/bin/
install -vm755 systemd-hwdb                        /usr/bin/udev-hwdb
ln -sfv udevadm                                    /usr/sbin/udevd
cp -av rules.d                                     /etc/udev/
mkdir -pv /usr/lib/udev/rules.d
mkdir -pv /etc/udev/rules.d

cd "$BUILD_DIR"
rm -rf systemd-255

echo "✓ systemd-255 (udev) installed"

build_package "man-db" "2.12.0" "man-db-2.12.0.tar.xz" '
    ./configure --prefix=/usr                         \
                --docdir=/usr/share/doc/man-db-2.12.0 \
                --sysconfdir=/etc                     \
                --disable-setuid                      \
                --enable-cache-owner=bin              \
                --with-browser=/usr/bin/lynx          \
                --with-vgrind=/usr/bin/vgrind         \
                --with-grap=/usr/bin/grap             \
                --with-systemdtmpfilesdir=            \
                --with-systemdsystemunitdir=
    make
    make install
'

build_package "procps-ng" "4.0.4" "procps-ng-4.0.4.tar.xz" '
    ./configure --prefix=/usr                           \
                --docdir=/usr/share/doc/procps-ng-4.0.4 \
                --disable-static                        \
                --disable-kill
    make
    make install
'

build_package "util-linux" "2.39.3" "util-linux-2.39.3.tar.xz" '
    ./configure ADJTIME_PATH=/var/lib/hwclock/adjtime \
                --bindir=/usr/bin    \
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
                --docdir=/usr/share/doc/util-linux-2.39.3
    make
    make install
'

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
'

build_package "sysklogd" "1.5.1" "sysklogd-1.5.1.tar.gz" '
    sed -i "/Error loading kernel symbols/d" ksym_mod.c
    sed -i "s/union wait/int/" syslogd.c
    make
    make BINDIR=/sbin install
'

build_package "sysvinit" "3.08" "sysvinit-3.08.tar.xz" '
    patch -Np1 -i "$SOURCES_DIR/sysvinit-3.08-consolidated-1.patch" || true
    make
    make install
'

echo ""
echo "================================================================"
echo "Phase 7 Continuation COMPLETE!"
echo "================================================================"
echo ""
echo "All packages built successfully."
echo "Next step: Run Phase 8 for final configuration"
