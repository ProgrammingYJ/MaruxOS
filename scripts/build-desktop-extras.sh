#!/bin/bash
# MaruxOS Desktop Extras Build Script
# feh (배경화면), tint2 (패널), pcmanfm (바탕화면 아이콘)

set -e

LFS=/home/administrator/MaruxOS/lfs
SOURCES=$LFS/sources
LOG=/home/administrator/MaruxOS/desktop-extras-build.log

export PATH=$LFS/usr/bin:$LFS/usr/sbin:/usr/bin:/bin
export PKG_CONFIG_PATH=$LFS/usr/lib/pkgconfig:$LFS/usr/share/pkgconfig
export CFLAGS="-I$LFS/usr/include"
export LDFLAGS="-L$LFS/usr/lib -Wl,-rpath,$LFS/usr/lib"

log() {
    echo "[$(date '+%H:%M:%S')] $1" | tee -a $LOG
}

cd $SOURCES

# ============================================
# 1. imlib2 (feh 의존성)
# ============================================
log "=== Building imlib2 ==="
if [ ! -f $LFS/usr/lib/libImlib2.so ]; then
    if [ ! -f imlib2-1.12.2.tar.xz ]; then
        wget https://downloads.sourceforge.net/enlightenment/imlib2-1.12.2.tar.xz
    fi
    tar xf imlib2-1.12.2.tar.xz
    cd imlib2-1.12.2
    ./configure --prefix=/usr \
        --disable-static \
        --with-x \
        --with-jpeg \
        --with-png
    make -j$(nproc)
    make DESTDIR=$LFS install
    cd $SOURCES
    rm -rf imlib2-1.12.2
    log "imlib2 완료"
else
    log "imlib2 이미 설치됨"
fi

# ============================================
# 2. feh (배경화면 설정)
# ============================================
log "=== Building feh ==="
if [ ! -f $LFS/usr/bin/feh ]; then
    if [ ! -f feh-3.10.2.tar.bz2 ]; then
        wget https://feh.finalrewind.org/feh-3.10.2.tar.bz2
    fi
    tar xf feh-3.10.2.tar.bz2
    cd feh-3.10.2
    sed -i "s:doc/feh:&-3.10.2:" config.mk
    make PREFIX=/usr
    make PREFIX=/usr DESTDIR=$LFS install
    cd $SOURCES
    rm -rf feh-3.10.2
    log "feh 완료"
else
    log "feh 이미 설치됨"
fi

# ============================================
# 3. tint2 의존성들
# ============================================
log "=== Building tint2 dependencies ==="

# startup-notification
if [ ! -f $LFS/usr/lib/libstartup-notification-1.so ]; then
    if [ ! -f startup-notification-0.12.tar.gz ]; then
        wget https://www.freedesktop.org/software/startup-notification/releases/startup-notification-0.12.tar.gz
    fi
    tar xf startup-notification-0.12.tar.gz
    cd startup-notification-0.12
    ./configure --prefix=/usr --disable-static
    make -j$(nproc)
    make DESTDIR=$LFS install
    cd $SOURCES
    rm -rf startup-notification-0.12
    log "startup-notification 완료"
fi

# ============================================
# 4. tint2 (패널)
# ============================================
log "=== Building tint2 ==="
if [ ! -f $LFS/usr/bin/tint2 ]; then
    if [ ! -f tint2-17.1.3.tar.gz ]; then
        wget https://gitlab.com/o9000/tint2/-/archive/v17.1.3/tint2-v17.1.3.tar.gz -O tint2-17.1.3.tar.gz
    fi
    tar xf tint2-17.1.3.tar.gz
    cd tint2-v17.1.3
    mkdir -p build && cd build
    cmake .. \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_BUILD_TYPE=Release \
        -DENABLE_TINT2CONF=ON
    make -j$(nproc)
    make DESTDIR=$LFS install
    cd $SOURCES
    rm -rf tint2-v17.1.3
    log "tint2 완료"
else
    log "tint2 이미 설치됨"
fi

# ============================================
# 5. libfm (pcmanfm 의존성)
# ============================================
log "=== Building libfm ==="
if [ ! -f $LFS/usr/lib/libfm.so ]; then
    if [ ! -f libfm-1.3.2.tar.xz ]; then
        wget https://downloads.sourceforge.net/pcmanfm/libfm-1.3.2.tar.xz
    fi
    tar xf libfm-1.3.2.tar.xz
    cd libfm-1.3.2
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --disable-static
    make -j$(nproc)
    make DESTDIR=$LFS install
    cd $SOURCES
    rm -rf libfm-1.3.2
    log "libfm 완료"
else
    log "libfm 이미 설치됨"
fi

# ============================================
# 6. pcmanfm (파일 매니저 + 바탕화면)
# ============================================
log "=== Building pcmanfm ==="
if [ ! -f $LFS/usr/bin/pcmanfm ]; then
    if [ ! -f pcmanfm-1.3.2.tar.xz ]; then
        wget https://downloads.sourceforge.net/pcmanfm/pcmanfm-1.3.2.tar.xz
    fi
    tar xf pcmanfm-1.3.2.tar.xz
    cd pcmanfm-1.3.2
    ./configure --prefix=/usr --sysconfdir=/etc
    make -j$(nproc)
    make DESTDIR=$LFS install
    cd $SOURCES
    rm -rf pcmanfm-1.3.2
    log "pcmanfm 완료"
else
    log "pcmanfm 이미 설치됨"
fi

# ============================================
# 7. menu-cache (libfm 의존성, 필요시)
# ============================================
log "=== Building menu-cache ==="
if [ ! -f $LFS/usr/lib/libmenu-cache.so ]; then
    if [ ! -f menu-cache-1.1.0.tar.xz ]; then
        wget https://downloads.sourceforge.net/lxde/menu-cache-1.1.0.tar.xz
    fi
    tar xf menu-cache-1.1.0.tar.xz
    cd menu-cache-1.1.0
    ./configure --prefix=/usr --disable-static
    make -j$(nproc)
    make DESTDIR=$LFS install
    cd $SOURCES
    rm -rf menu-cache-1.1.0
    log "menu-cache 완료"
else
    log "menu-cache 이미 설치됨"
fi

# ============================================
# 8. libfm-extra
# ============================================
log "=== Building libfm-extra ==="
if [ ! -f $LFS/usr/lib/libfm-extra.so ]; then
    if [ ! -f libfm-extra-1.3.2.tar.xz ]; then
        wget https://downloads.sourceforge.net/pcmanfm/libfm-extra-1.3.2.tar.xz
    fi
    tar xf libfm-extra-1.3.2.tar.xz
    cd libfm-extra-1.3.2
    ./configure --prefix=/usr --disable-static
    make -j$(nproc)
    make DESTDIR=$LFS install
    cd $SOURCES
    rm -rf libfm-extra-1.3.2
    log "libfm-extra 완료"
else
    log "libfm-extra 이미 설치됨"
fi

# ============================================
# 9. jgmenu (앱 메뉴)
# ============================================
log "=== Building jgmenu ==="
if [ ! -f $LFS/usr/bin/jgmenu ]; then
    if [ ! -d jgmenu ]; then
        git clone --depth 1 https://github.com/johanmalm/jgmenu.git
    fi
    cd jgmenu
    ./configure --prefix=/usr
    make -j$(nproc)
    make DESTDIR=$LFS install
    cd $SOURCES
    rm -rf jgmenu
    log "jgmenu 완료"
else
    log "jgmenu 이미 설치됨"
fi

log "=== 모든 데스크톱 추가 패키지 빌드 완료 ==="
