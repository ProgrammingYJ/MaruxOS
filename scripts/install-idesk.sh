#!/bin/bash
# MaruxOS - idesk (Desktop Icons) Installation Script
# Imlib2 개발 파일 설치 + idesk 컴파일

set -e

SQUASHFS_ROOT="${1:-/home/administrator/MaruxOS/build/rootfs-lfs}"
SOURCES_DIR="$SQUASHFS_ROOT/sources"

IMLIB2_VERSION="1.12.1"
IMLIB2_URL="https://sourceforge.net/projects/enlightenment/files/imlib2-src/${IMLIB2_VERSION}/imlib2-${IMLIB2_VERSION}.tar.xz/download"

IDESK_VERSION="0.7.5"
IDESK_URL="https://sourceforge.net/projects/idesk/files/idesk/idesk-${IDESK_VERSION}/idesk-${IDESK_VERSION}.tar.bz2/download"

echo "==========================================="
echo "  idesk $IDESK_VERSION Installation"
echo "==========================================="
echo ""

# 이미 설치되어 있는지 확인
if [ -f "$SQUASHFS_ROOT/usr/bin/idesk" ]; then
    echo "idesk is already installed at $SQUASHFS_ROOT/usr/bin/idesk"
    echo "Skipping installation."
    exit 0
fi

# 의존성 확인
echo "[1/6] Checking dependencies..."
for lib in libImlib2.so libXft.so libXpm.so libX11.so; do
    if [ -f "$SQUASHFS_ROOT/usr/lib/$lib" ]; then
        echo "  ✓ $lib"
    else
        echo "  ✗ $lib MISSING"
        echo "ERROR: Cannot proceed without $lib"
        exit 1
    fi
done

# chroot 환경 준비
echo ""
echo "[2/6] Preparing chroot environment..."
mkdir -p "$SOURCES_DIR"
mount --bind /proc "$SQUASHFS_ROOT/proc" 2>/dev/null || true
mount --bind /sys "$SQUASHFS_ROOT/sys" 2>/dev/null || true
mount --bind /dev "$SQUASHFS_ROOT/dev" 2>/dev/null || true

# Imlib2 개발 파일 설치 (imlib2-config + Imlib2.h)
echo ""
echo "[3/6] Installing Imlib2 development files..."
if [ -f "$SQUASHFS_ROOT/usr/bin/imlib2-config" ] && [ -f "$SQUASHFS_ROOT/usr/include/Imlib2.h" ]; then
    echo "  ✓ Imlib2 dev files already present"
else
    cd "$SOURCES_DIR"
    if [ ! -f "imlib2-${IMLIB2_VERSION}.tar.xz" ]; then
        echo "  - Downloading Imlib2 ${IMLIB2_VERSION} source..."
        wget -O "imlib2-${IMLIB2_VERSION}.tar.xz" "$IMLIB2_URL" 2>&1 || {
            # Fallback: 직접 URL
            wget "https://sourceforge.net/projects/enlightenment/files/imlib2-src/${IMLIB2_VERSION}/imlib2-${IMLIB2_VERSION}.tar.xz" 2>&1 || {
                echo "  ERROR: Failed to download Imlib2"
                umount "$SQUASHFS_ROOT/dev" 2>/dev/null || true
                umount "$SQUASHFS_ROOT/sys" 2>/dev/null || true
                umount "$SQUASHFS_ROOT/proc" 2>/dev/null || true
                exit 1
            }
        }
    fi
    echo "  ✓ Imlib2 source ready"

    rm -rf "imlib2-${IMLIB2_VERSION}"
    tar -xf "imlib2-${IMLIB2_VERSION}.tar.xz"

    echo "  - Building Imlib2 dev files in chroot..."
    chroot "$SQUASHFS_ROOT" /bin/bash -c "
        cd /sources/imlib2-${IMLIB2_VERSION}
        export PATH=/usr/bin:/usr/sbin:/bin:/sbin
        ./configure --prefix=/usr --disable-static 2>&1 | tail -3
        make -j\$(nproc) 2>&1 | tail -3
        make install 2>&1 | tail -3
    "

    cd "$SOURCES_DIR"
    rm -rf "imlib2-${IMLIB2_VERSION}"

    if [ -f "$SQUASHFS_ROOT/usr/include/Imlib2.h" ]; then
        echo "  ✓ Imlib2.h installed"
    else
        echo "  ✗ Imlib2.h installation failed"
    fi
fi

# imlib2-config 호환 래퍼 생성 (Imlib2 1.12+는 pkg-config만 제공)
if [ ! -f "$SQUASHFS_ROOT/usr/bin/imlib2-config" ]; then
    echo "  - Creating imlib2-config wrapper (pkg-config shim)..."
    cat > "$SQUASHFS_ROOT/usr/bin/imlib2-config" << 'IMLIB2CFG'
#!/bin/sh
# imlib2-config compatibility wrapper for pkg-config
prefix=/usr
exec_prefix=${prefix}
libdir=${exec_prefix}/lib
includedir=${prefix}/include
version=1.12.1

usage()
{
    echo "Usage: imlib2-config [--prefix] [--exec-prefix] [--libs] [--cflags] [--version]"
    exit 1
}

while test $# -gt 0; do
    case "$1" in
        --version)  echo "$version";;
        --prefix)   echo "$prefix";;
        --exec-prefix) echo "$exec_prefix";;
        --cflags)   echo "-I${includedir}";;
        --libs)     echo "-L${libdir} -lImlib2";;
        *)          usage;;
    esac
    shift
done
IMLIB2CFG
    chmod 755 "$SQUASHFS_ROOT/usr/bin/imlib2-config"
    echo "  ✓ imlib2-config wrapper created"
fi

# idesk 다운로드
echo ""
echo "[4/6] Downloading idesk $IDESK_VERSION source..."
cd "$SOURCES_DIR"

if [ ! -f "idesk-${IDESK_VERSION}.tar.bz2" ]; then
    wget -O "idesk-${IDESK_VERSION}.tar.bz2" "$IDESK_URL" 2>&1 || {
        echo "ERROR: Failed to download idesk source"
        umount "$SQUASHFS_ROOT/dev" 2>/dev/null || true
        umount "$SQUASHFS_ROOT/sys" 2>/dev/null || true
        umount "$SQUASHFS_ROOT/proc" 2>/dev/null || true
        exit 1
    }
    echo "  ✓ Downloaded"
else
    echo "  ✓ Source already exists"
fi

# idesk 빌드
echo ""
echo "[5/6] Building idesk in chroot..."
cd "$SOURCES_DIR"
rm -rf "idesk-${IDESK_VERSION}"
tar -xf "idesk-${IDESK_VERSION}.tar.bz2"

chroot "$SQUASHFS_ROOT" /bin/bash -c "
    cd /sources/idesk-${IDESK_VERSION}
    export PATH=/usr/bin:/usr/sbin:/bin:/sbin
    export PKG_CONFIG_PATH=/usr/lib/pkgconfig
    export IMLIB2_CONFIG=/usr/bin/imlib2-config

    # Patch: fix 'stat' C++ name collision with modern glibc
    # glibc defines 'struct stat' as a C++ class, so stat() function call
    # is misinterpreted as constructor. Fix: use a C wrapper function.
    echo '  - Patching source for modern C++ compatibility...'

    # 1) Create C wrapper for stat() (compiled as C, no name collision)
    cat > src/stat_fix.c << 'CFIX'
#include <sys/types.h>
#include <sys/stat.h>
int idesk_stat(const char *path, struct stat *buf) {
    return stat(path, buf);
}
CFIX

    # 2) Patch DesktopConfig.cpp to use idesk_stat
    sed -i '1i\\
extern \"C\" int idesk_stat(const char *path, struct stat *buf);' src/DesktopConfig.cpp
    sed -i 's/stat( directory/idesk_stat( directory/g' src/DesktopConfig.cpp

    # 3) Compile C wrapper
    gcc -c src/stat_fix.c -o src/stat_fix.o

    echo '  - Running configure...'
    ./configure --prefix=/usr 2>&1 | tail -5

    # 4) Patch Makefile to include stat_fix.o in linking
    sed -i 's/idesk_OBJECTS =/idesk_OBJECTS = stat_fix.o/' src/Makefile

    echo '  - Compiling...'
    make -j\$(nproc) 2>&1 || true

    # Makefile이 stat_fix.o를 포함하지 않아 링킹 실패 → 수동 링킹
    # stat_fix.o는 src/ 안에 있으므로 *.o가 이미 포함함
    echo '  - Linking with stat_fix.o...'
    cd src
    g++ -g -O2 -o idesk *.o -lX11 -lXext -lImlib2 -lXft -lSM -lICE
    cd ..

    echo '  - Installing...'
    install -m 755 src/idesk /usr/bin/idesk
"

# 클린업
cd "$SOURCES_DIR"
rm -rf "idesk-${IDESK_VERSION}"

# chroot 마운트 해제
umount "$SQUASHFS_ROOT/dev" 2>/dev/null || true
umount "$SQUASHFS_ROOT/sys" 2>/dev/null || true
umount "$SQUASHFS_ROOT/proc" 2>/dev/null || true

# 검증
echo ""
echo "[6/6] Verifying installation..."
if [ -f "$SQUASHFS_ROOT/usr/bin/idesk" ]; then
    echo "  ✓ idesk installed successfully at /usr/bin/idesk"
    ls -la "$SQUASHFS_ROOT/usr/bin/idesk"
else
    echo "  ✗ ERROR: idesk binary not found after installation!"
    exit 1
fi

echo ""
echo "==========================================="
echo "  idesk installation complete!"
echo "==========================================="
