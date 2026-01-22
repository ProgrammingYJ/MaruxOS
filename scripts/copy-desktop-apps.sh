#!/bin/bash
# Copy desktop applications from host to LFS
# feh, tint2, pcmanfm 및 관련 라이브러리 복사

set -e

LFS=/home/administrator/MaruxOS/lfs

log() {
    echo "[$(date '+%H:%M:%S')] $1"
}

copy_with_deps() {
    local binary=$1
    log "Copying $binary and dependencies..."

    # 바이너리 복사
    if [ -f "$binary" ]; then
        cp -f "$binary" "$LFS/usr/bin/"
        chmod +x "$LFS/usr/bin/$(basename $binary)"
    fi

    # 의존성 라이브러리 복사
    ldd "$binary" 2>/dev/null | grep "=>" | awk '{print $3}' | while read lib; do
        if [ -f "$lib" ] && [ ! -f "$LFS$lib" ]; then
            mkdir -p "$LFS$(dirname $lib)"
            cp -f "$lib" "$LFS$lib" 2>/dev/null || true
        fi
    done
}

log "=== Desktop Applications 복사 시작 ==="

# feh 복사
log "=== feh 복사 ==="
copy_with_deps /usr/bin/feh

# tint2 복사
log "=== tint2 복사 ==="
copy_with_deps /usr/bin/tint2
[ -f /usr/bin/tint2conf ] && copy_with_deps /usr/bin/tint2conf

# pcmanfm 복사
log "=== pcmanfm 복사 ==="
copy_with_deps /usr/bin/pcmanfm

# 관련 라이브러리 복사
log "=== 주요 라이브러리 복사 ==="
libs=(
    /usr/lib/x86_64-linux-gnu/libImlib2.so*
    /usr/lib/x86_64-linux-gnu/libfm*.so*
    /usr/lib/x86_64-linux-gnu/libmenu-cache*.so*
    /usr/lib/x86_64-linux-gnu/libstartup-notification*.so*
)

for lib in "${libs[@]}"; do
    if ls $lib 1>/dev/null 2>&1; then
        for f in $lib; do
            if [ -f "$f" ]; then
                cp -af "$f" "$LFS/usr/lib/" 2>/dev/null || true
            fi
        done
    fi
done

# tint2 설정 파일 복사
log "=== tint2 설정 복사 ==="
mkdir -p "$LFS/etc/xdg/tint2"
cp -r /etc/xdg/tint2/* "$LFS/etc/xdg/tint2/" 2>/dev/null || true
mkdir -p "$LFS/usr/share/tint2"
cp -r /usr/share/tint2/* "$LFS/usr/share/tint2/" 2>/dev/null || true

# pcmanfm 설정 및 데이터 복사
log "=== pcmanfm 설정 복사 ==="
mkdir -p "$LFS/etc/xdg/pcmanfm/default"
cp -r /etc/xdg/pcmanfm/* "$LFS/etc/xdg/pcmanfm/" 2>/dev/null || true
mkdir -p "$LFS/usr/share/pcmanfm"
cp -r /usr/share/pcmanfm/* "$LFS/usr/share/pcmanfm/" 2>/dev/null || true

# libfm 설정 복사
mkdir -p "$LFS/etc/xdg/libfm"
cp -r /etc/xdg/libfm/* "$LFS/etc/xdg/libfm/" 2>/dev/null || true
mkdir -p "$LFS/usr/share/libfm"
cp -r /usr/share/libfm/* "$LFS/usr/share/libfm/" 2>/dev/null || true

# gvfs (pcmanfm 파일 작업용)
log "=== gvfs 복사 ==="
mkdir -p "$LFS/usr/lib/gvfs"
cp -r /usr/lib/x86_64-linux-gnu/gvfs/* "$LFS/usr/lib/gvfs/" 2>/dev/null || true

# desktop 파일 복사
log "=== .desktop 파일 복사 ==="
for app in feh tint2 tint2conf pcmanfm; do
    if [ -f "/usr/share/applications/$app.desktop" ]; then
        cp "/usr/share/applications/$app.desktop" "$LFS/usr/share/applications/" 2>/dev/null || true
    fi
done

# 아이콘 복사 (기본 아이콘)
log "=== 기본 아이콘 복사 ==="
mkdir -p "$LFS/usr/share/icons"
if [ -d /usr/share/icons/hicolor ]; then
    cp -r /usr/share/icons/hicolor "$LFS/usr/share/icons/" 2>/dev/null || true
fi
if [ -d /usr/share/icons/Adwaita ]; then
    cp -r /usr/share/icons/Adwaita "$LFS/usr/share/icons/" 2>/dev/null || true
fi

# MIME 데이터 복사 (pcmanfm 파일 타입 인식)
log "=== MIME 데이터 복사 ==="
mkdir -p "$LFS/usr/share/mime"
cp -r /usr/share/mime/* "$LFS/usr/share/mime/" 2>/dev/null || true

# GLib schemas 복사
log "=== GLib schemas 복사 ==="
mkdir -p "$LFS/usr/share/glib-2.0/schemas"
cp /usr/share/glib-2.0/schemas/*.xml "$LFS/usr/share/glib-2.0/schemas/" 2>/dev/null || true
cp /usr/share/glib-2.0/schemas/gschemas.compiled "$LFS/usr/share/glib-2.0/schemas/" 2>/dev/null || true

log "=== 복사 완료 ==="

# 확인
log "=== 설치 확인 ==="
ls -la "$LFS/usr/bin/feh" "$LFS/usr/bin/tint2" "$LFS/usr/bin/pcmanfm" 2>/dev/null || echo "일부 파일 없음"
