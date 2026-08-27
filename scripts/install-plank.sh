#!/bin/bash
# MaruxOS - Plank Dock Installation Script (2.0.0 "Cooked" 신규)
# ===============================================================
# Windows 11 스타일 dock 도입. tint2의 launcher+taskbar 분리 한계 보완.
#
# 전략: source-from-Vala 빌드 대신 Debian Bookworm prebuilt .deb 추출 (1.x Firefox 패턴).
#   - LFS rootfs에 valac 없음 → source build 회피
#   - Bookworm GLib 2.74 ↔ LFS 2.78 forward-compatible (검증 후 결정)
#
# 추출 패키지 (4개):
#   1. plank             → /usr/bin/plank, /usr/share/plank/, /usr/share/applications/plank.desktop
#   2. libplank1         → /usr/lib/libplank.so.1.* (plank 자체 라이브러리)
#   3. libgee-0.8-2      → /usr/lib/libgee-0.8.so.2.*
#   4. libwnck-3-0       → /usr/lib/libwnck-3.so.0.*
#   5. libgnome-menu-3-0 → /usr/lib/libgnome-menu-3.so.0.*
#
# 안전장치 (1.x PCManFM 사고 회피):
#   - libc.so / libglib / libgtk 등 핵심 시스템 라이브러리 절대 덮어쓰지 않음
#   - 신규 추가 lib만 복사. 기존 파일은 건드리지 않음
#   - 마지막에 chroot에서 ldd 검증, missing symbols 있으면 abort

set -e
set -o pipefail

SQUASHFS_ROOT="${1:-/home/administrator/MaruxOS/build/rootfs-lfs}"
WORK_DIR="${PLANK_WORK_DIR:-/tmp/plank-build}"

# Debian Bookworm 패키지 (packages.debian.org 검증 — AI 추측 금지, raw fetch 후 박은 값들)
PLANK_VERSION="0.11.89-4+b1"
LIBPLANK_COMMON_VERSION="0.11.89-4"   # _all.deb (arch-independent) — schema 포함
LIBGEE_VERSION="0.20.6-1"
LIBWNCK_VERSION="43.0-3"
LIBGNOME_MENU_VERSION="3.36.0-1.1"
# ldd가 catch한 추가 의존성 (1차 빌드 후 발견)
LIBBAMF_VERSION="0.5.6+repack-1"
LIBDBUSMENU_VERSION="18.10.20180917~bzr492+repack1-3"
LIBXRES_VERSION="1.2.1-1"

DEB_BASE="http://ftp.debian.org/debian/pool/main"

declare -a DEBS=(
    # Plank 본체 + 자체 라이브러리
    "p/plank/plank_${PLANK_VERSION}_amd64.deb"
    "p/plank/libplank1_${PLANK_VERSION}_amd64.deb"
    "p/plank/libplank-common_${LIBPLANK_COMMON_VERSION}_all.deb"   # ⚠ GSettings schema 여기 들어있음 (net.launchpad.plank.gschema.xml)
    # Vala 컬렉션, 창 매칭, GNOME menu data
    "libg/libgee-0.8/libgee-0.8-2_${LIBGEE_VERSION}_amd64.deb"
    "libw/libwnck3/libwnck-3-0_${LIBWNCK_VERSION}_amd64.deb"
    "g/gnome-menus/libgnome-menu-3-0_${LIBGNOME_MENU_VERSION}_amd64.deb"
    # ldd가 catch한 추가 의존성 (Plank의 transitive deps)
    "b/bamf/libbamf3-2_${LIBBAMF_VERSION}_amd64.deb"          # window-app 매칭
    "libd/libdbusmenu/libdbusmenu-gtk3-4_${LIBDBUSMENU_VERSION}_amd64.deb"
    "libd/libdbusmenu/libdbusmenu-glib4_${LIBDBUSMENU_VERSION}_amd64.deb"
    "libx/libxres/libxres1_${LIBXRES_VERSION}_amd64.deb"      # X resource extension
)

echo "============================================="
echo "  Plank Dock Installation (prebuilt extract)"
echo "============================================="
echo ""

# 이미 설치돼있는지 + schema 깨지지 않았는지 확인
PLANK_BIN="$SQUASHFS_ROOT/usr/bin/plank"
PLANK_SCHEMA_XML="$SQUASHFS_ROOT/usr/share/glib-2.0/schemas/net.launchpad.plank.gschema.xml"
PLANK_SCHEMA_COMPILED="$SQUASHFS_ROOT/usr/share/glib-2.0/schemas/gschemas.compiled"
SKIP_INSTALL=0
if [ -f "$PLANK_BIN" ] && [ -f "$PLANK_SCHEMA_XML" ] && \
   [ -f "$PLANK_SCHEMA_COMPILED" ] && \
   strings "$PLANK_SCHEMA_COMPILED" 2>/dev/null | grep -q "net.launchpad.plank"; then
    echo "  ✓ Plank fully installed (binary + schema XML + compiled cache 모두 존재)"
    echo "    To force reinstall: rm $PLANK_BIN && re-run"
    exit 0
fi
if [ -f "$PLANK_BIN" ]; then
    echo "  ⚠ Plank binary exists but schema/compile 결손 발견 → 재배포 진행"
    echo "    binary: $([ -f "$PLANK_BIN" ] && echo OK || echo MISSING)"
    echo "    schema: $([ -f "$PLANK_SCHEMA_XML" ] && echo OK || echo MISSING)"
    echo "    compiled: $([ -f "$PLANK_SCHEMA_COMPILED" ] && echo OK || echo MISSING)"
    echo "    in cache: $(strings "$PLANK_SCHEMA_COMPILED" 2>/dev/null | grep -q net.launchpad.plank && echo YES || echo NO)"
fi

# Pre-flight: 핵심 시스템 라이브러리 존재 확인 (의존성)
echo "[1/6] Checking host dependencies in rootfs..."
for lib in libglib-2.0.so libgtk-3.so libpango-1.0.so libcairo.so libgdk_pixbuf-2.0.so; do
    if find "$SQUASHFS_ROOT/usr/lib" "$SQUASHFS_ROOT/lib" -name "$lib*" 2>/dev/null | head -1 | grep -q .; then
        echo "  ✓ $lib (host)"
    else
        echo "  ✗ $lib MISSING in rootfs"
        echo "ERROR: Plank needs GTK3 stack. Verify rootfs-lfs is on 1.x baseline."
        exit 1
    fi
done

# Pre-flight: 빌드 도구 (호스트)
echo ""
echo "[2/6] Checking host build tools..."
for tool in wget ar tar; do
    command -v "$tool" >/dev/null 2>&1 || { echo "ERROR: $tool not found"; exit 1; }
done

# 작업 디렉토리
mkdir -p "$WORK_DIR/debs" "$WORK_DIR/extracted"
cd "$WORK_DIR"

# .deb 다운로드
echo ""
echo "[3/6] Downloading .deb packages..."
for deb_path in "${DEBS[@]}"; do
    deb_file="$(basename "$deb_path")"
    if [ -f "debs/$deb_file" ] && [ -s "debs/$deb_file" ]; then
        echo "  ✓ $deb_file (cached)"
    else
        echo "  - Downloading $deb_file..."
        # -nv: 진행 출력은 줄이되 에러는 보이게 (quiet -q 였을 때 silent fail 함정)
        wget -nv -O "debs/$deb_file" "$DEB_BASE/$deb_path" || {
            echo ""
            echo "ERROR: Failed to download $deb_path"
            echo "  URL: $DEB_BASE/$deb_path"
            echo "  → URL stale 가능성. Debian Bookworm 패키지 페이지에서 정확 버전 확인:"
            echo "    https://packages.debian.org/bookworm/$(echo $deb_file | cut -d_ -f1)"
            rm -f "debs/$deb_file"   # zero-byte placeholder 제거 (다음 실행에서 재시도)
            exit 1
        }
    fi
done

# .deb 추출 (ar로 풀어 data.tar.* 만 사용)
echo ""
echo "[4/6] Extracting .deb packages..."
rm -rf "$WORK_DIR/extracted"
mkdir -p "$WORK_DIR/extracted"
for deb_file in debs/*.deb; do
    pkg_name=$(basename "$deb_file" .deb)
    pkg_dir="$WORK_DIR/extracted/$pkg_name"
    mkdir -p "$pkg_dir"
    cd "$pkg_dir"
    ar x "$WORK_DIR/$deb_file"
    if [ -f data.tar.xz ]; then tar -xf data.tar.xz; fi
    if [ -f data.tar.zst ]; then tar --zstd -xf data.tar.zst; fi
    if [ -f data.tar.gz ]; then tar -xf data.tar.gz; fi
    cd "$WORK_DIR"
    echo "  ✓ $pkg_name"
done

# rootfs로 복사 (신규 파일만, 기존 시스템 라이브러리는 절대 덮어쓰지 않음)
echo ""
echo "[5/6] Installing to rootfs (additive only)..."

# 복사할 경로 화이트리스트 — 시스템 핵심 영역 보호
ALLOWED_PATHS=(
    "usr/bin/plank"
    "usr/lib/x86_64-linux-gnu/libplank.so"
    "usr/lib/x86_64-linux-gnu/libgee-0.8.so"
    "usr/lib/x86_64-linux-gnu/libwnck-3.so"
    "usr/lib/x86_64-linux-gnu/libgnome-menu-3.so"
    "usr/lib/x86_64-linux-gnu/plank"        # plank의 .so 모듈
    "usr/share/plank/"
    "usr/share/applications/plank.desktop"
    "usr/share/glib-2.0/schemas/net.launchpad.plank.gschema.xml"
    "usr/share/icons/hicolor/scalable/apps/plank.svg"
)

# Debian uses /usr/lib/x86_64-linux-gnu/, LFS uses /usr/lib/. 둘 다 처리.
copy_safe() {
    local src="$1"
    local dst="$2"
    # dangling symlink 제거 (cp -n이 못 따라감)
    if [ -L "$dst" ] && [ ! -e "$dst" ]; then
        echo "    - Removing dangling symlink: $dst"
        rm -f "$dst"
    fi
    if [ -d "$src" ]; then
        mkdir -p "$dst"
        # /. → 디렉토리 내용만 복사. -a archive (perms/symlinks/timestamp 보존), --update=none 미존재만 (cp -n 대체)
        cp -a --update=none "$src/." "$dst/" 2>/dev/null || true
    elif [ -f "$src" ] || [ -L "$src" ]; then
        if [ -e "$dst" ]; then
            echo "    ⚠ exists, skipping (보호): $dst"
        else
            mkdir -p "$(dirname "$dst")"
            cp -a --update=none "$src" "$dst"
        fi
    fi
}

for ext_dir in "$WORK_DIR/extracted"/*/; do
    # /usr/lib/x86_64-linux-gnu/ → LFS의 /usr/lib/
    if [ -d "$ext_dir/usr/lib/x86_64-linux-gnu" ]; then
        # Plank + 1차 의존성 (libplank, libgee, libwnck, libgnome-menu)
        # + 2차 의존성 (libbamf, libdbusmenu, libXRes)
        for prefix in libplank libgee libwnck libgnome-menu libbamf libdbusmenu libXRes; do
            for f in "$ext_dir/usr/lib/x86_64-linux-gnu/${prefix}"*.so*; do
                [ -e "$f" ] || continue
                copy_safe "$f" "$SQUASHFS_ROOT/usr/lib/$(basename "$f")"
            done
        done
        # plank 자체의 .so 모듈 디렉토리
        if [ -d "$ext_dir/usr/lib/x86_64-linux-gnu/plank" ]; then
            copy_safe "$ext_dir/usr/lib/x86_64-linux-gnu/plank" "$SQUASHFS_ROOT/usr/lib/plank"
        fi
        # bamfdaemon (libbamf3-2 deb 안에 같이 있을 수 있음 — plank가 직접 사용 X but 같이 깔자)
        if [ -f "$ext_dir/usr/lib/x86_64-linux-gnu/bamf/bamfdaemon" ]; then
            mkdir -p "$SQUASHFS_ROOT/usr/lib/bamf"
            copy_safe "$ext_dir/usr/lib/x86_64-linux-gnu/bamf/bamfdaemon" "$SQUASHFS_ROOT/usr/lib/bamf/bamfdaemon"
        fi
    fi

    # /usr/bin/plank
    [ -f "$ext_dir/usr/bin/plank" ] && copy_safe "$ext_dir/usr/bin/plank" "$SQUASHFS_ROOT/usr/bin/plank"

    # /usr/share/plank/, /usr/share/applications/plank.desktop, schemas
    [ -d "$ext_dir/usr/share/plank" ] && copy_safe "$ext_dir/usr/share/plank" "$SQUASHFS_ROOT/usr/share/plank"
    [ -f "$ext_dir/usr/share/applications/plank.desktop" ] && \
        copy_safe "$ext_dir/usr/share/applications/plank.desktop" "$SQUASHFS_ROOT/usr/share/applications/plank.desktop"
    # GSettings schema는 plank 동작에 CRITICAL — 없으면 SIGTRAP exit 133
    # copy_safe의 "exists, skip" 로직 우회: schema는 strict force-overwrite
    if [ -d "$ext_dir/usr/share/glib-2.0/schemas" ]; then
        for s in "$ext_dir/usr/share/glib-2.0/schemas/"*plank*.xml; do
            [ -f "$s" ] || continue
            mkdir -p "$SQUASHFS_ROOT/usr/share/glib-2.0/schemas"
            cp -af "$s" "$SQUASHFS_ROOT/usr/share/glib-2.0/schemas/$(basename "$s")"
            echo "    ✓ schema deployed (force): $(basename "$s")"
        done
    fi
done

chmod 755 "$SQUASHFS_ROOT/usr/bin/plank" 2>/dev/null || true

# ============================================================================
# Plank schema 검증 (post-copy, pre-compile) — 없으면 plank SIGTRAP exit 133
# ============================================================================
PLANK_SCHEMA="$SQUASHFS_ROOT/usr/share/glib-2.0/schemas/net.launchpad.plank.gschema.xml"
if [ ! -f "$PLANK_SCHEMA" ]; then
    echo "ERROR: Plank GSettings schema not deployed!"
    echo "  Expected at: $PLANK_SCHEMA"
    echo "  plank.deb 안에 schema 파일이 없거나 추출 실패. 확인:"
    echo "    find $WORK_DIR/extracted/plank* -name '*plank*.xml'"
    exit 1
fi
echo "  ✓ Plank schema present at $PLANK_SCHEMA"

# chroot 후처리 (ldconfig + glib schemas + ldd 검증)
echo ""
echo "[6/6] Post-install (chroot ldconfig + verify)..."
mount --bind /proc "$SQUASHFS_ROOT/proc" 2>/dev/null || true
mount --bind /sys "$SQUASHFS_ROOT/sys" 2>/dev/null || true
mount --bind /dev "$SQUASHFS_ROOT/dev" 2>/dev/null || true

trap 'umount "$SQUASHFS_ROOT/proc" 2>/dev/null; umount "$SQUASHFS_ROOT/sys" 2>/dev/null; umount "$SQUASHFS_ROOT/dev" 2>/dev/null' EXIT

if [ -x "$SQUASHFS_ROOT/usr/sbin/ldconfig" ]; then
    chroot "$SQUASHFS_ROOT" /usr/sbin/ldconfig
fi

if [ -x "$SQUASHFS_ROOT/usr/bin/glib-compile-schemas" ]; then
    echo "  - Compiling GSettings schemas in chroot..."
    # silent fail 회피 — 출력 보이게 + exit code 체크
    if ! chroot "$SQUASHFS_ROOT" /usr/bin/glib-compile-schemas /usr/share/glib-2.0/schemas/; then
        echo "ERROR: glib-compile-schemas failed in chroot"
        exit 1
    fi
    # 검증: gschemas.compiled 안에 plank schema가 진짜 들어갔는지
    if [ ! -f "$SQUASHFS_ROOT/usr/share/glib-2.0/schemas/gschemas.compiled" ]; then
        echo "ERROR: gschemas.compiled not generated"
        exit 1
    fi
    if ! strings "$SQUASHFS_ROOT/usr/share/glib-2.0/schemas/gschemas.compiled" | grep -q "net.launchpad.plank"; then
        echo "ERROR: Plank schema not in compiled cache"
        echo "  → Schema XML 형식 오류 또는 glib-compile-schemas 침묵 실패."
        exit 1
    fi
    echo "  ✓ Plank schema compiled and registered (net.launchpad.plank)"
else
    echo "ERROR: glib-compile-schemas not found in rootfs (need GLib runtime)"
    exit 1
fi

# ldd 검증 — missing libs 있으면 부팅 시 plank 실행 실패
echo ""
echo "  - Running ldd on plank binary..."
MISSING=$(chroot "$SQUASHFS_ROOT" /usr/bin/ldd /usr/bin/plank 2>&1 | grep "not found" || true)
if [ -n "$MISSING" ]; then
    echo "  ✗ Missing libraries detected:"
    echo "$MISSING"
    echo ""
    echo "ERROR: Plank installation incomplete. 추가 의존성 필요."
    echo "  → 누락 라이브러리 .deb 패키지를 추가로 추출하거나, source build로 전환 검토."
    exit 1
fi

echo ""
echo "============================================="
echo "  ✓ Plank installed successfully"
echo "  - Binary:  $SQUASHFS_ROOT/usr/bin/plank"
echo "  - Lib(s):  libplank.so, libgee-0.8.so, libwnck-3.so, libgnome-menu-3.so"
echo "============================================="
echo ""
echo "Next: build script에서 plank 자동 시작 (xinitrc) + tint2 systray-only로 분할"
