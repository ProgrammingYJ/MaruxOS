#!/bin/bash
# MaruxOS 2.0.0 "Cooked" - cooked-v1 Build Script
# =================================================
# 첫 번째 진짜 의도-일치 커널 빌드 위에 1.x의 검증된 유저랜드(데스크톱/한글입력)를 얹는 빌드.
#
# 변경사항 (vs 1.2.1 67-v4):
#   - 커널: 6.7.4 (genesis hallucination) → 6.18.26 LTS (정공)
#   - 코드네임: 67 → Cooked
#   - 버전: 1.2.1 → 2.0.0
#   - 신규 단계 [KERNEL]: 02-build-kernel.sh가 만든 vmlinuz + 모듈을 rootfs-lfs에 sync
#   - 6.7.4 잔재(vmlinuz, /lib/modules/6.7.4)는 백업 폴더로 이동 (롤백 보존)
#   - 검증 게이트: 빌드 산출물 존재 + 모듈 의존성 + 커널 버전 매칭
# 유지사항:
#   - 1.2.1의 모든 데스크톱 기능 (idesk, openbox, tint2, ibus-hangul, marux-* 헬퍼)
#   - minimal busybox initrd 그대로 재사용 (lib/modules 없는 구조 → 6.18.26과 호환)
#   - MaruxOS 디자인/ → rootfs 아이콘 동기화 (1.2.1 v4 도입분)

set -e
set -o pipefail

# Timestamped log (stage, message, elapsed)
BUILD_START=$(date +%s)
log() {
    local stage="$1"; shift
    local elapsed=$(( $(date +%s) - BUILD_START ))
    printf "[%s][+%4ds][%s] %s\n" "$(date +%H:%M:%S)" "$elapsed" "$stage" "$*"
}

# ============================================================================
# Paths & config
# ============================================================================
PROJECT_ROOT="/mnt/c/Users/Administrator/Desktop/MaruxOS"
WORK_DIR="/home/administrator/MaruxOS/build"
SQUASHFS_ROOT="$WORK_DIR/rootfs-lfs"
ISO_DIR="$WORK_DIR/iso-build"
# 커널 빌드 산출물은 WSL native fs (Windows 드라이브 case-insensitive 함정 회피)
# sudo 실행 시 $USER=root가 되어 경로 미스매치 → SUDO_USER로 원래 사용자 복원
EFFECTIVE_USER="${SUDO_USER:-$USER}"
WSL_KERNEL_BUILD_ROOT="${WSL_KERNEL_BUILD_ROOT:-/home/$EFFECTIVE_USER/MaruxOS-kernel-build}"
KERNEL_BUILD_DIR="$WSL_KERNEL_BUILD_ROOT/output"
KERNEL_MODULES_STAGING="$WSL_KERNEL_BUILD_ROOT/modules"
CONFIG_DIR="$PROJECT_ROOT/config"
SCRIPT_DIR="$PROJECT_ROOT/scripts"
OUTPUT_DIR="$PROJECT_ROOT/output"

# Source single-source-of-truth metadata
source "$CONFIG_DIR/marux-release.conf"
source "$CONFIG_DIR/lfs-versions.conf"

VERSION="cooked-v1"
ISO_FILENAME="MaruxOS-${DISTRO_VERSION}-${VERSION}.iso"

echo "=========================================="
echo "MaruxOS $DISTRO_VERSION \"$DISTRO_CODENAME\" - $VERSION"
echo "Kernel: Linux $KERNEL_VERSION $KERNEL_TYPE"
echo "=========================================="

cd "$WORK_DIR"

# ============================================================================
# [PRE] Sanity: 필수 입력 존재 확인
# ============================================================================
echo "[PRE] Pre-flight checks..."

# A. 빌드 도구 의존성 검증 (1.x는 묵시적 가정 → 2.0.0은 명시적 게이트)
MISSING_TOOLS=()
for tool in mksquashfs xorriso cpio gzip gunzip sed find chroot sha256sum sha512sum; do
    command -v "$tool" >/dev/null 2>&1 || MISSING_TOOLS+=("$tool")
done
# grub-mkrescue는 fallback이라 별도 — xorriso가 있으면 충분
if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    echo "ERROR: Missing required tools:"
    for t in "${MISSING_TOOLS[@]}"; do echo "  - $t"; done
    echo "Install with: sudo apt install squashfs-tools xorriso cpio gzip"
    exit 1
fi
echo "  ✓ build tools present (mksquashfs, xorriso, cpio, ...)"

# B. 커널 빌드 산출물 검증
NEW_VMLINUZ="$KERNEL_BUILD_DIR/vmlinuz-$KERNEL_VERSION"
NEW_MODULES_DIR="$KERNEL_MODULES_STAGING/lib/modules/$KERNEL_VERSION"
[ -f "$NEW_VMLINUZ" ] || { echo "ERROR: $NEW_VMLINUZ not found. Run scripts/build/02-build-kernel.sh first."; exit 1; }
[ -d "$NEW_MODULES_DIR" ] || { echo "ERROR: $NEW_MODULES_DIR not found. Run scripts/build/02-build-kernel.sh first."; exit 1; }
[ -f "$NEW_MODULES_DIR/modules.dep" ] || { echo "ERROR: modules.dep not found in $NEW_MODULES_DIR (depmod 미실행?)"; exit 1; }
echo "  ✓ kernel build artifacts present"

# C. rootfs / iso-build 검증 (initrd 재사용 의존성)
[ -d "$SQUASHFS_ROOT" ] || { echo "ERROR: rootfs-lfs not found at $SQUASHFS_ROOT"; exit 1; }
[ -f "$ISO_DIR/boot/initrd.img" ] || { echo "ERROR: stale initrd.img not found at $ISO_DIR/boot/initrd.img — 1.x carry-over 손실. ROLLBACK.md 참고하여 1.2.1 ISO에서 추출 또는 git history 복구."; exit 1; }
echo "  ✓ rootfs-lfs + carry-over initrd present"

# D. 디스크 공간 (squashfs는 ~1GB+, ISO 빌드는 +1GB)
AVAIL_KB=$(df -k "$WORK_DIR" | awk 'NR==2 {print $4}')
AVAIL_GB=$((AVAIL_KB / 1024 / 1024))
if [ "$AVAIL_GB" -lt 5 ]; then
    echo "ERROR: 빌드 디렉토리 공간 부족 (${AVAIL_GB}GB available, 최소 5GB 필요)"
    exit 1
fi
echo "  ✓ disk space: ${AVAIL_GB}GB available"
echo ""

# ============================================================================
# [1] Cleanup mounts
# ============================================================================
echo "[1] Cleaning up..."
umount "$SQUASHFS_ROOT/proc" 2>/dev/null || true
umount "$SQUASHFS_ROOT/sys" 2>/dev/null || true
umount "$SQUASHFS_ROOT/dev" 2>/dev/null || true

# ============================================================================
# [2] Setup ISO directory
# ============================================================================
echo "[2] Setting up ISO directory..."
mkdir -p "$ISO_DIR/boot/grub"
mkdir -p "$ISO_DIR/live"

# ============================================================================
# [KERNEL] Sync new kernel + modules into rootfs-lfs (2.0.0 신규 단계)
# ============================================================================
echo ""
echo "==== [KERNEL] Genesis: 진짜 의도-일치 커널 설치 ===="
echo ""

# Backup old 6.x kernel artifacts (rollback용)
LEGACY_BACKUP_DIR="$WORK_DIR/legacy-1.x-kernel"
if [ -d "$SQUASHFS_ROOT/lib/modules" ] && [ ! -d "$LEGACY_BACKUP_DIR" ]; then
    echo "  - Backing up 1.x legacy kernel artifacts (rollback)..."
    mkdir -p "$LEGACY_BACKUP_DIR"

    # Move legacy modules (entire /lib/modules)
    if [ -d "$SQUASHFS_ROOT/lib/modules" ]; then
        cp -a "$SQUASHFS_ROOT/lib/modules" "$LEGACY_BACKUP_DIR/"
    fi
    # Backup legacy vmlinuz files
    mkdir -p "$LEGACY_BACKUP_DIR/boot"
    for f in "$SQUASHFS_ROOT/boot"/vmlinuz*; do
        [ -e "$f" ] && cp -a "$f" "$LEGACY_BACKUP_DIR/boot/" 2>/dev/null || true
    done
    echo "  ✓ Legacy kernel backed up to: $LEGACY_BACKUP_DIR"
elif [ -d "$LEGACY_BACKUP_DIR" ]; then
    echo "  ✓ Legacy backup already exists: $LEGACY_BACKUP_DIR (skipping)"
fi

# Remove legacy /lib/modules (will be replaced by 6.18.26)
echo "  - Removing legacy /lib/modules..."
rm -rf "$SQUASHFS_ROOT/lib/modules"

# Remove legacy vmlinuz files
echo "  - Removing legacy vmlinuz files..."
rm -f "$SQUASHFS_ROOT/boot"/vmlinuz*

# Install new vmlinuz with -maruxos suffix (LFS convention 따라)
echo "  - Installing new vmlinuz-$KERNEL_VERSION-maruxos..."
mkdir -p "$SQUASHFS_ROOT/boot"
cp "$NEW_VMLINUZ" "$SQUASHFS_ROOT/boot/vmlinuz-$KERNEL_VERSION-maruxos"
ln -sf "vmlinuz-$KERNEL_VERSION-maruxos" "$SQUASHFS_ROOT/boot/vmlinuz"

# Sync new modules
log KERNEL "Syncing modules to rootfs-lfs/lib/modules/$KERNEL_VERSION/..."
mkdir -p "$SQUASHFS_ROOT/lib/modules"
cp -a "$NEW_MODULES_DIR" "$SQUASHFS_ROOT/lib/modules/"

# Handoff verification: staging count == synced count
STAGING_COUNT=$(find "$NEW_MODULES_DIR" -name "*.ko*" 2>/dev/null | wc -l)
SYNCED_MODULES=$(find "$SQUASHFS_ROOT/lib/modules/$KERNEL_VERSION" -name "*.ko*" 2>/dev/null | wc -l)
[ "$SYNCED_MODULES" -gt 0 ] || { echo "ERROR: No modules synced!"; exit 1; }
if [ "$STAGING_COUNT" != "$SYNCED_MODULES" ]; then
    echo "ERROR: Module count mismatch! staging=$STAGING_COUNT synced=$SYNCED_MODULES"
    echo "       cp -a 도중 일부 파일 누락 가능 (권한? 디스크 풀?). 빌드 abort."
    exit 1
fi
[ -f "$SQUASHFS_ROOT/lib/modules/$KERNEL_VERSION/modules.dep" ] || { echo "ERROR: modules.dep not synced"; exit 1; }
log KERNEL "✓ $SYNCED_MODULES modules synced (handoff verified, modules.dep present)"

# Final embedded version sanity in rootfs (1.x 6.7.4 잔재 재유입 방지)
ROOTFS_KERNEL=$(strings "$SQUASHFS_ROOT/boot/vmlinuz-$KERNEL_VERSION-maruxos" 2>/dev/null | grep -m1 "^Linux version " | awk '{print $3}' || echo "")
if [ -z "$ROOTFS_KERNEL" ]; then
    log KERNEL "  ⚠ rootfs vmlinuz version extraction failed (strings unavailable on bzImage; modules.dep verification가 대체 보증)"
elif [[ "$ROOTFS_KERNEL" != "$KERNEL_VERSION"* ]]; then
    echo "ERROR: rootfs vmlinuz mismatch! Expected $KERNEL_VERSION, got $ROOTFS_KERNEL"
    exit 1
else
    log KERNEL "✓ rootfs vmlinuz embedded version: $ROOTFS_KERNEL"
fi

# Optional: copy System.map for debugging
if [ -f "$KERNEL_BUILD_DIR/System.map-$KERNEL_VERSION" ]; then
    cp "$KERNEL_BUILD_DIR/System.map-$KERNEL_VERSION" "$SQUASHFS_ROOT/boot/"
fi
if [ -f "$KERNEL_BUILD_DIR/config-$KERNEL_VERSION" ]; then
    cp "$KERNEL_BUILD_DIR/config-$KERNEL_VERSION" "$SQUASHFS_ROOT/boot/"
fi
echo "  ✓ Kernel artifacts synced into rootfs-lfs"
echo ""

# ============================================================================
# [3] Copy kernel + initrd to ISO staging
# ============================================================================
echo "[3] Copying kernel + initrd to ISO staging..."
cp "$SQUASHFS_ROOT/boot/vmlinuz-$KERNEL_VERSION-maruxos" "$ISO_DIR/boot/vmlinuz"

# initrd 재사용 (1.x의 minimal busybox initrd, lib/modules 없으니 6.18.26 호환)
INITRD_SRC="$ISO_DIR/boot/initrd.img"  # 기존 stale initrd가 그대로 있음
if [ ! -f "$INITRD_SRC" ]; then
    echo "ERROR: $INITRD_SRC not found. 1.x build에서 carried over된 initrd가 사라짐."
    echo "       legacy-1.x-kernel 백업 또는 git history에서 복구 필요."
    exit 1
fi
echo "  ✓ vmlinuz: linux $KERNEL_VERSION (cooked-v1)"
echo "  ✓ initrd.img: 1.x minimal busybox initrd 재사용 (lib/modules 없음 → 호환)"

# ============================================================================
# [4] GRUB config (2.0.0 Cooked)
# ============================================================================
cat > "$ISO_DIR/boot/grub/grub.cfg" << GRUB_EOF
set default=0
set timeout=5

menuentry "MaruxOS $DISTRO_VERSION \"$DISTRO_CODENAME\" - Desktop" {
    linux /boot/vmlinuz boot=live quiet
    initrd /boot/initrd.img
}

menuentry "MaruxOS $DISTRO_VERSION \"$DISTRO_CODENAME\" - Safe Mode (CLI, no KMS, no mitigations)" {
    linux /boot/vmlinuz boot=live systemd.unit=multi-user.target nomodeset mitigations=off
    initrd /boot/initrd.img
}

menuentry "MaruxOS $DISTRO_VERSION \"$DISTRO_CODENAME\" - Debug" {
    linux /boot/vmlinuz boot=live debug
    initrd /boot/initrd.img
}
GRUB_EOF
echo "[4] GRUB cfg generated (Desktop / Safe Mode / Debug)"

# ============================================================================
# [5] idesk
# ============================================================================
echo "[5] Installing idesk..."
if [ -f "$SQUASHFS_ROOT/usr/bin/idesk" ]; then
    echo "  ✓ idesk already installed"
elif [ -f "$SCRIPT_DIR/install-idesk.sh" ]; then
    bash "$SCRIPT_DIR/install-idesk.sh" "$SQUASHFS_ROOT" || echo "  ⚠ idesk install failed (non-critical)"
fi

# ============================================================================
# [6] neofetch
# ============================================================================
echo "[6] Installing neofetch..."
if [ -f "$SQUASHFS_ROOT/usr/bin/neofetch" ]; then
    echo "  ✓ neofetch already installed"
elif [ -f "$SCRIPT_DIR/install-neofetch.sh" ]; then
    bash "$SCRIPT_DIR/install-neofetch.sh" "$SQUASHFS_ROOT" || echo "  ⚠ neofetch install failed (non-critical)"
fi

# ============================================================================
# [7] ibus-hangul (한글 입력기 — 1.1 핵심 기능, 보존)
# ============================================================================
echo "[7] Installing ibus-hangul..."
if [ -f "$SQUASHFS_ROOT/usr/lib/ibus/ibus-engine-hangul" ]; then
    echo "  ✓ ibus-hangul already installed"
elif [ -f "$SCRIPT_DIR/install-ibus-hangul.sh" ]; then
    bash "$SCRIPT_DIR/install-ibus-hangul.sh" || { echo "ERROR: ibus-hangul install failed"; exit 1; }
fi

# ============================================================================
# [8] Config files
# ============================================================================
echo "[8] Copying config files (xinitrc, openbox, scripts)..."
cp "$CONFIG_DIR/xinitrc" "$SQUASHFS_ROOT/etc/X11/xinit/xinitrc"
chmod 755 "$SQUASHFS_ROOT/etc/X11/xinit/xinitrc"

mkdir -p "$SQUASHFS_ROOT/etc/xdg/openbox"
cp "$CONFIG_DIR/openbox/rc.xml" "$SQUASHFS_ROOT/etc/xdg/openbox/rc.xml"
cp "$CONFIG_DIR/openbox/menu.xml" "$SQUASHFS_ROOT/etc/xdg/openbox/menu.xml"
chmod 644 "$SQUASHFS_ROOT/etc/xdg/openbox"/{rc,menu}.xml

cp "$CONFIG_DIR/scripts/marux-wallpaper" "$SQUASHFS_ROOT/usr/bin/marux-wallpaper"
cp "$CONFIG_DIR/scripts/marux-desktop-refresh" "$SQUASHFS_ROOT/usr/bin/marux-desktop-refresh"
cp "$CONFIG_DIR/scripts/marux-new-desktop-item" "$SQUASHFS_ROOT/usr/bin/marux-new-desktop-item"
chmod 755 "$SQUASHFS_ROOT/usr/bin/marux-"{wallpaper,desktop-refresh,new-desktop-item}

mkdir -p "$SQUASHFS_ROOT/etc/skel/Desktop"
mkdir -p "$SQUASHFS_ROOT/usr/share/pixmaps/maruxos"

# ============================================================================
# [9] 디자인 → rootfs 아이콘 동기화 (1.2.1 v4 도입분, 보존)
# ============================================================================
echo "[9] Syncing icons from design folder..."
DESIGN_DIR="$PROJECT_ROOT/MaruxOS 디자인"
PIXMAP_DIR="$SQUASHFS_ROOT/usr/share/pixmaps/maruxos"
for src in marux-terminal.png marux-file-manager.png marux-desktop.png; do
    if [ -f "$DESIGN_DIR/$src" ]; then
        cp "$DESIGN_DIR/$src" "$PIXMAP_DIR/$src"
        echo "    ✓ $src"
    else
        echo "    ⚠ $src missing in design folder"
    fi
done
if [ -f "$DESIGN_DIR/marux-logo-128.png" ]; then
    cp "$DESIGN_DIR/marux-logo-128.png" "$PIXMAP_DIR/marux-logo.png"
fi

for icon_name in file-generic folder file-text file-image; do
    if [ ! -f "$PIXMAP_DIR/${icon_name}.png" ]; then
        if [ -f "$PIXMAP_DIR/marux-file-manager.png" ]; then
            ln -sf marux-file-manager.png "$PIXMAP_DIR/${icon_name}.png"
        elif [ -f "$PIXMAP_DIR/marux-terminal.png" ]; then
            ln -sf marux-terminal.png "$PIXMAP_DIR/${icon_name}.png"
        fi
    fi
done

# ============================================================================
# [10] idesk desktop icons (skel)
# ============================================================================
echo "[10] Setting up desktop icons..."
mkdir -p "$SQUASHFS_ROOT/etc/skel/.idesktop"
cp "$CONFIG_DIR/idesk/ideskrc" "$SQUASHFS_ROOT/etc/skel/.ideskrc"
cp "$CONFIG_DIR/idesk/idesktop"/*.lnk "$SQUASHFS_ROOT/etc/skel/.idesktop/"
chmod 644 "$SQUASHFS_ROOT/etc/skel/.ideskrc"
chmod 644 "$SQUASHFS_ROOT/etc/skel/.idesktop"/*.lnk

# ============================================================================
# [11] Korean locale
# ============================================================================
echo "[11] Korean locale support..."
cat > "$SQUASHFS_ROOT/etc/locale.gen" << 'LOCALE_GEN_EOF'
en_US.UTF-8 UTF-8
ko_KR.UTF-8 UTF-8
ko_KR.EUC-KR EUC-KR
C.UTF-8 UTF-8
LOCALE_GEN_EOF

cat > "$SQUASHFS_ROOT/etc/locale.conf" << 'LOCALE_CONF_EOF'
LANG=ko_KR.UTF-8
LC_ALL=ko_KR.UTF-8
LC_CTYPE=ko_KR.UTF-8
LC_NUMERIC=ko_KR.UTF-8
LC_TIME=ko_KR.UTF-8
LC_COLLATE=ko_KR.UTF-8
LC_MONETARY=ko_KR.UTF-8
LC_MESSAGES=ko_KR.UTF-8
LC_PAPER=ko_KR.UTF-8
LC_NAME=ko_KR.UTF-8
LC_ADDRESS=ko_KR.UTF-8
LC_TELEPHONE=ko_KR.UTF-8
LC_MEASUREMENT=ko_KR.UTF-8
LC_IDENTIFICATION=ko_KR.UTF-8
LOCALE_CONF_EOF

cat > "$SQUASHFS_ROOT/etc/environment" << 'ENV_EOF'
LANG=ko_KR.UTF-8
LC_ALL=ko_KR.UTF-8
ENV_EOF

mkdir -p "$SQUASHFS_ROOT/usr/share/locale/ko/LC_MESSAGES"
mkdir -p "$SQUASHFS_ROOT/usr/lib/locale"

chroot "$SQUASHFS_ROOT" /usr/bin/localedef -i ko_KR -f UTF-8 ko_KR.UTF-8 2>/dev/null || echo "  Warning: localedef issue"
chroot "$SQUASHFS_ROOT" /usr/bin/localedef -i en_US -f UTF-8 en_US.UTF-8 2>/dev/null || true

if [ -x "$SQUASHFS_ROOT/usr/bin/fc-cache" ]; then
    chroot "$SQUASHFS_ROOT" /usr/bin/fc-cache -f 2>/dev/null || true
fi

# ============================================================================
# [12] ibus-hangul + GTK3 immodules
# ============================================================================
echo "[12] Configuring ibus + GTK3 immodules..."
[ -x "$SQUASHFS_ROOT/usr/sbin/ldconfig" ] && chroot "$SQUASHFS_ROOT" /usr/sbin/ldconfig 2>/dev/null || true
[ -x "$SQUASHFS_ROOT/usr/bin/ibus" ] && chroot "$SQUASHFS_ROOT" /usr/bin/ibus write-cache 2>/dev/null || true
mkdir -p "$SQUASHFS_ROOT/usr/share/glib-2.0/schemas"
[ -x "$SQUASHFS_ROOT/usr/bin/glib-compile-schemas" ] && chroot "$SQUASHFS_ROOT" /usr/bin/glib-compile-schemas /usr/share/glib-2.0/schemas/ 2>/dev/null || true

[ -f "$SQUASHFS_ROOT/usr/lib/ibus/ibus-engine-hangul" ] || { echo "ERROR: ibus-engine-hangul missing"; exit 1; }

if [ -x "$SQUASHFS_ROOT/usr/bin/gtk-query-immodules-3.0" ]; then
    chroot "$SQUASHFS_ROOT" /bin/bash -c '/usr/bin/gtk-query-immodules-3.0 > /usr/lib/gtk-3.0/3.0.0/immodules.cache 2>/dev/null' || true
fi

if ! grep -q ibus "$SQUASHFS_ROOT/usr/lib/gtk-3.0/3.0.0/immodules.cache" 2>/dev/null; then
    cat >> "$SQUASHFS_ROOT/usr/lib/gtk-3.0/3.0.0/immodules.cache" << 'IBUS_CACHE_EOF'

"/usr/lib/gtk-3.0/3.0.0/immodules/im-ibus.so"
"ibus" "Intelligent Input Bus" "ibus10" "/usr/share/locale" ""

IBUS_CACHE_EOF
fi

# ============================================================================
# [13] Version metadata in rootfs (2.0.0 / Cooked / 6.18.26)
# ============================================================================
echo "[13] Writing version metadata to rootfs..."

# 1.x 시리즈는 메타파일을 sed로 부분 패치 → 따옴표/형식 변형마다 누락. 2.0.0은 canonical 템플릿으로 통째 생성.
# (sed는 우리가 형식을 100% 모르는 외부 스크립트인 marux-splash에만 보존)

# /etc/os-release — freedesktop.org 표준 포맷
cat > "$SQUASHFS_ROOT/etc/os-release" << OSRELEOF
NAME="$DISTRO_NAME"
PRETTY_NAME="$DISTRO_NAME $DISTRO_VERSION \"$DISTRO_CODENAME\""
ID=maruxos
ID_LIKE=lfs
VERSION="$DISTRO_VERSION"
VERSION_ID="$DISTRO_VERSION"
VERSION_CODENAME=$(echo "$DISTRO_CODENAME" | tr '[:upper:]' '[:lower:]')
HOME_URL="https://github.com/ProgrammingYJ/MaruxOS"
SUPPORT_URL="https://github.com/ProgrammingYJ/MaruxOS/issues"
BUG_REPORT_URL="https://github.com/ProgrammingYJ/MaruxOS/issues"
OSRELEOF

# /etc/maruxos-release — 자체 정의 포맷 (1.x로부터 보존)
cat > "$SQUASHFS_ROOT/etc/maruxos-release" << MARUXEOF
$DISTRO_NAME $DISTRO_VERSION ($DISTRO_CODENAME)
MARUXEOF

# /etc/issue — 로그인 프롬프트 배너
cat > "$SQUASHFS_ROOT/etc/issue" << ISSUEEOF
$DISTRO_NAME $DISTRO_VERSION "$DISTRO_CODENAME" \\n \\l

ISSUEEOF

# /etc/lsb-release — Linux Standard Base
cat > "$SQUASHFS_ROOT/etc/lsb-release" << LSBEOF
DISTRIB_ID=MaruxOS
DISTRIB_RELEASE=$DISTRO_VERSION
DISTRIB_CODENAME=$DISTRO_CODENAME
DISTRIB_DESCRIPTION="$DISTRO_NAME $DISTRO_VERSION ($DISTRO_CODENAME)"
LSBEOF

# /usr/bin/marux-splash — 외부 스크립트, 형식 모름 → sed로 보수적 갱신
if [ -f "$SQUASHFS_ROOT/usr/bin/marux-splash" ]; then
    sed -i "s/MaruxOS [0-9]\+\.[0-9]\+\(\.[0-9]\+\)\?/MaruxOS $DISTRO_VERSION/g" "$SQUASHFS_ROOT/usr/bin/marux-splash"
    sed -i "s/\bPhoenix\b/$DISTRO_CODENAME/g" "$SQUASHFS_ROOT/usr/bin/marux-splash"
    sed -i "s/\b67\b/$DISTRO_CODENAME/g" "$SQUASHFS_ROOT/usr/bin/marux-splash"
fi

# ============================================================================
# [14] initrd splash text update
# ============================================================================
echo "[14] Updating initrd splash text..."
INITRD_WORK="/tmp/initrd-modify-$$"
mkdir -p "$INITRD_WORK"
( cd "$INITRD_WORK" && gunzip -c "$ISO_DIR/boot/initrd.img" | cpio -id 2>/dev/null )
if [ -f "$INITRD_WORK/init" ]; then
    sed -i "s/MaruxOS [0-9]\+\.[0-9]\+\(\.[0-9]\+\)\? [^ ]*/MaruxOS $DISTRO_VERSION $DISTRO_CODENAME/g" "$INITRD_WORK/init"
fi
( cd "$INITRD_WORK" && find . | cpio -o -H newc 2>/dev/null | gzip -9 > "$ISO_DIR/boot/initrd.img" )
rm -rf "$INITRD_WORK"

# ============================================================================
# [15] Desktop / tint2 files
# ============================================================================
echo "[15] Copying desktop/tint2 files..."
for f in marux-menu firefox xterm mc battery network volume; do
    [ -f "$CONFIG_DIR/applications/$f.desktop" ] && \
        cp "$CONFIG_DIR/applications/$f.desktop" "$SQUASHFS_ROOT/usr/share/applications/" 2>/dev/null || true
done

mkdir -p "$SQUASHFS_ROOT/etc/xdg/tint2"
cp "$CONFIG_DIR/tint2/tint2rc" "$SQUASHFS_ROOT/etc/xdg/tint2/tint2rc"
chmod 644 "$SQUASHFS_ROOT/etc/xdg/tint2/tint2rc"

# Permissions
chmod 644 "$SQUASHFS_ROOT/etc/locale.gen" "$SQUASHFS_ROOT/etc/locale.conf" "$SQUASHFS_ROOT/etc/environment" 2>/dev/null || true
chmod 755 "$SQUASHFS_ROOT/usr/lib/ibus/ibus-engine-hangul" "$SQUASHFS_ROOT/usr/bin/idesk" 2>/dev/null || true

# ============================================================================
# [16] squashfs
# ============================================================================
echo "[16] Building squashfs..."
rm -f "$ISO_DIR/live/filesystem.squashfs"
mksquashfs "$SQUASHFS_ROOT" "$ISO_DIR/live/filesystem.squashfs" \
    -comp gzip \
    -e boot \
    -noappend

# ============================================================================
# [17] ISO image
# ============================================================================
echo "[17] Building ISO..."
mkdir -p "$OUTPUT_DIR"

xorriso -as mkisofs \
    -iso-level 3 \
    -full-iso9660-filenames \
    -volid "MARUXOS" \
    -eltorito-boot boot/grub/bios.img \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    --grub2-boot-info \
    --grub2-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
    -eltorito-catalog boot/grub/boot.cat \
    --protective-msdos-label \
    -output "$OUTPUT_DIR/$ISO_FILENAME" \
    "$ISO_DIR" 2>/dev/null || \
grub-mkrescue -o "$OUTPUT_DIR/$ISO_FILENAME" "$ISO_DIR"

# ============================================================================
# [POST] SHA256 + summary
# ============================================================================
echo ""
echo "[POST] Computing ISO checksums..."
sha256sum "$OUTPUT_DIR/$ISO_FILENAME" > "$OUTPUT_DIR/$ISO_FILENAME.sha256"
sha512sum "$OUTPUT_DIR/$ISO_FILENAME" > "$OUTPUT_DIR/$ISO_FILENAME.sha512"

echo ""
echo "=========================================="
echo "✓ Build complete: $ISO_FILENAME"
ls -lh "$OUTPUT_DIR/$ISO_FILENAME" 2>/dev/null
echo "=========================================="
echo ""
echo "Summary:"
echo "  Distro:   MaruxOS $DISTRO_VERSION \"$DISTRO_CODENAME\""
echo "  Kernel:   Linux $KERNEL_VERSION $KERNEL_TYPE (정공 빌드, 첫 의도-일치)"
echo "  Modules:  $SYNCED_MODULES installed"
echo "  ISO:     $OUTPUT_DIR/$ISO_FILENAME"
echo "  SHA256:  $OUTPUT_DIR/$ISO_FILENAME.sha256"
echo "  SHA512:  $OUTPUT_DIR/$ISO_FILENAME.sha512"
echo ""
echo "1.x legacy kernel (6.7.4 hallucination):"
echo "  Backed up to: $LEGACY_BACKUP_DIR (rollback 보존)"
echo ""
echo "Next: QEMU 부팅 + Phase D 회귀 체크리스트"
echo "  qemu-system-x86_64 -m 4G -enable-kvm -cdrom $OUTPUT_DIR/$ISO_FILENAME"
echo "=========================================="
