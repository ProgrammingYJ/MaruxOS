#!/bin/bash
# MaruxOS 1.2.0-67-v4 Build Script
# Bugfix 1: 바탕화면 아이콘 일부만 표시되거나 새 파일 아이콘이 안 보이는 버그 수정
#   - 원인: PNG 파일은 marux-* prefix로 설치되는데 .lnk와 desktop-refresh는 prefix 없는 이름 참조
#   - 수정: 모든 아이콘 참조를 marux-* prefix로 통일
#   - 위치: config/idesk/idesktop/{terminal,filemanager}.lnk, config/scripts/marux-desktop-refresh,
#           본 스크립트의 file-generic 폴백 블록
# Bugfix 2: 터미널 아이콘이 불투명하게 나오는 버그 수정
#   - 원인: rootfs의 PNG가 stale (12월 버전). 디자인 폴더의 1월 투명 버전이 동기화 안 됨
#   - 수정: 빌드 시 MaruxOS 디자인/ → rootfs 아이콘 동기화 단계 추가
#   - 부수: MaruxOS 디자인/terminal.png → marux-terminal.png 로 이름 통일 (prefix 일관성)
# 이전 (v3) bugfix 유지: setsid로 idesk 재시작 시 SIGHUP 차단

set -e

WORK_DIR="/home/administrator/MaruxOS/build"
SQUASHFS_ROOT="$WORK_DIR/rootfs-lfs"
ISO_DIR="$WORK_DIR/iso-build"
CONFIG_DIR="/mnt/c/Users/Administrator/Desktop/MaruxOS/config"
OUTPUT_DIR="/mnt/c/Users/Administrator/Desktop/MaruxOS/output"
SCRIPT_DIR="/mnt/c/Users/Administrator/Desktop/MaruxOS/scripts"
VERSION="67-v4"

echo "=========================================="
echo "MaruxOS $VERSION Build Script"
echo "v1.2.0 - Desktop Features"
echo "=========================================="

cd "$WORK_DIR"

# Clean up any existing mounts
echo "[1/17] Cleaning up..."
umount "$SQUASHFS_ROOT/proc" 2>/dev/null || true
umount "$SQUASHFS_ROOT/sys" 2>/dev/null || true
umount "$SQUASHFS_ROOT/dev" 2>/dev/null || true

# Create ISO directory structure
echo "[2/17] Setting up ISO directory..."
mkdir -p "$ISO_DIR/boot/grub"
mkdir -p "$ISO_DIR/live"

# Copy kernel and initrd
echo "  - Copying kernel..."
VMLINUZ=$(ls "$SQUASHFS_ROOT/boot/vmlinuz"* 2>/dev/null | head -1)
if [ -n "$VMLINUZ" ]; then
    cp "$VMLINUZ" "$ISO_DIR/boot/vmlinuz"
else
    echo "Error: vmlinuz not found"
    exit 1
fi

echo "  - Copying initrd..."
INITRD=$(ls "$SQUASHFS_ROOT/boot/initrd"* 2>/dev/null | head -1)
if [ -n "$INITRD" ]; then
    cp "$INITRD" "$ISO_DIR/boot/initrd.img"
else
    echo "Warning: initrd not found, skipping..."
fi

# Create GRUB config (v1.2.0)
cat > "$ISO_DIR/boot/grub/grub.cfg" << 'GRUB_EOF'
set default=0
set timeout=5

menuentry "MaruxOS 1.2.0 (67) - Desktop" {
    linux /boot/vmlinuz boot=live quiet
    initrd /boot/initrd.img
}

menuentry "MaruxOS 1.2.0 (67) - Safe Mode" {
    linux /boot/vmlinuz boot=live single
    initrd /boot/initrd.img
}
GRUB_EOF

# Install idesk (desktop icons)
echo "[3/17] Installing idesk (desktop icons)..."
if [ -f "$SQUASHFS_ROOT/usr/bin/idesk" ]; then
    echo "  ✓ idesk already installed, skipping"
else
    if [ -f "$SCRIPT_DIR/install-idesk.sh" ]; then
        echo "  - Running idesk installation script..."
        bash "$SCRIPT_DIR/install-idesk.sh" "$SQUASHFS_ROOT"
        if [ $? -eq 0 ]; then
            echo "  ✓ idesk installation completed"
        else
            echo "  ⚠ idesk installation failed (non-critical, continuing...)"
        fi
    else
        echo "  ⚠ install-idesk.sh not found, skipping idesk"
    fi
fi

# Install neofetch (system info)
echo "[4/17] Installing neofetch..."
if [ -f "$SQUASHFS_ROOT/usr/bin/neofetch" ]; then
    echo "  ✓ neofetch already installed, skipping"
else
    if [ -f "$SCRIPT_DIR/install-neofetch.sh" ]; then
        echo "  - Running neofetch installation script..."
        bash "$SCRIPT_DIR/install-neofetch.sh" "$SQUASHFS_ROOT"
        if [ $? -eq 0 ]; then
            echo "  ✓ neofetch installation completed"
        else
            echo "  ⚠ neofetch installation failed (non-critical, continuing...)"
        fi
    else
        echo "  ⚠ install-neofetch.sh not found, skipping neofetch"
    fi
fi

# Install ibus-hangul (Korean input method)
echo "[5/17] Installing ibus-hangul Korean input method..."
if [ -f "$SQUASHFS_ROOT/usr/lib/ibus/ibus-engine-hangul" ]; then
    echo "  ✓ ibus-hangul already installed, skipping compilation"
else
    if [ -f "$SCRIPT_DIR/install-ibus-hangul.sh" ]; then
        echo "  - Running ibus-hangul installation script..."
        bash "$SCRIPT_DIR/install-ibus-hangul.sh"
        if [ $? -eq 0 ]; then
            echo "  ✓ ibus-hangul installation completed"
        else
            echo "  ✗ ERROR: ibus-hangul installation failed"
            exit 1
        fi
    else
        echo "  ✗ ERROR: install-ibus-hangul.sh not found"
        exit 1
    fi
fi

# Apply config files
echo "[6/17] Copying config files..."

# Copy xinitrc (with idesk + ibus + GTK immodules cache)
echo "  - Copying xinitrc..."
cp "$CONFIG_DIR/xinitrc" "$SQUASHFS_ROOT/etc/X11/xinit/xinitrc"
chmod 755 "$SQUASHFS_ROOT/etc/X11/xinit/xinitrc"

# [NEW] Copy Openbox config (right-click menu + keybindings)
echo "[7/17] Setting up Openbox desktop menu..."
mkdir -p "$SQUASHFS_ROOT/etc/xdg/openbox"
cp "$CONFIG_DIR/openbox/rc.xml" "$SQUASHFS_ROOT/etc/xdg/openbox/rc.xml"
cp "$CONFIG_DIR/openbox/menu.xml" "$SQUASHFS_ROOT/etc/xdg/openbox/menu.xml"
chmod 644 "$SQUASHFS_ROOT/etc/xdg/openbox/rc.xml"
chmod 644 "$SQUASHFS_ROOT/etc/xdg/openbox/menu.xml"
echo "  ✓ Openbox rc.xml (keybindings: Alt+F4, Alt+Tab, Win+D, Win+T, Win+E, F11, Win+Arrow)"
echo "  ✓ Openbox menu.xml (right-click: Apps, Settings, System, Reboot/Shutdown)"

# [NEW] Install wallpaper changer + desktop refresh scripts
echo "[8/17] Installing desktop scripts..."
cp "$CONFIG_DIR/scripts/marux-wallpaper" "$SQUASHFS_ROOT/usr/bin/marux-wallpaper"
chmod 755 "$SQUASHFS_ROOT/usr/bin/marux-wallpaper"
echo "  ✓ /usr/bin/marux-wallpaper installed"

cp "$CONFIG_DIR/scripts/marux-desktop-refresh" "$SQUASHFS_ROOT/usr/bin/marux-desktop-refresh"
chmod 755 "$SQUASHFS_ROOT/usr/bin/marux-desktop-refresh"
echo "  ✓ /usr/bin/marux-desktop-refresh installed"

cp "$CONFIG_DIR/scripts/marux-new-desktop-item" "$SQUASHFS_ROOT/usr/bin/marux-new-desktop-item"
chmod 755 "$SQUASHFS_ROOT/usr/bin/marux-new-desktop-item"
echo "  ✓ /usr/bin/marux-new-desktop-item installed"

# ~/Desktop 기본 폴더 (skel)
mkdir -p "$SQUASHFS_ROOT/etc/skel/Desktop"
echo "  ✓ /etc/skel/Desktop created"

echo "  - Creating file type icons..."
mkdir -p "$SQUASHFS_ROOT/usr/share/pixmaps/maruxos"

# MaruxOS 디자인/ → rootfs 아이콘 동기화 (디자인 변경 시 자동 반영)
DESIGN_DIR="/mnt/c/Users/Administrator/Desktop/MaruxOS/MaruxOS 디자인"
PIXMAP_DIR="$SQUASHFS_ROOT/usr/share/pixmaps/maruxos"
echo "  - Syncing icons from design folder..."
for src in marux-terminal.png marux-file-manager.png marux-desktop.png; do
    if [ -f "$DESIGN_DIR/$src" ]; then
        cp "$DESIGN_DIR/$src" "$PIXMAP_DIR/$src"
        echo "    ✓ $src"
    else
        echo "    ⚠ $src missing in design folder"
    fi
done
# 로고: 표준 사이즈로 marux-logo-128.png를 marux-logo.png로 (idesk/tint2 launcher가 사용)
if [ -f "$DESIGN_DIR/marux-logo-128.png" ]; then
    cp "$DESIGN_DIR/marux-logo-128.png" "$PIXMAP_DIR/marux-logo.png"
    echo "    ✓ marux-logo.png (from marux-logo-128.png)"
fi

# 파일 타입별 아이콘이 없으면 marux-file-manager.png / marux-terminal.png로 심볼릭 링크
for icon_name in file-generic folder file-text file-image; do
    if [ ! -f "$SQUASHFS_ROOT/usr/share/pixmaps/maruxos/${icon_name}.png" ]; then
        if [ -f "$SQUASHFS_ROOT/usr/share/pixmaps/maruxos/marux-file-manager.png" ]; then
            ln -sf marux-file-manager.png "$SQUASHFS_ROOT/usr/share/pixmaps/maruxos/${icon_name}.png"
            echo "    ✓ ${icon_name}.png -> marux-file-manager.png (symlink)"
        elif [ -f "$SQUASHFS_ROOT/usr/share/pixmaps/maruxos/marux-terminal.png" ]; then
            ln -sf marux-terminal.png "$SQUASHFS_ROOT/usr/share/pixmaps/maruxos/${icon_name}.png"
            echo "    ✓ ${icon_name}.png -> marux-terminal.png (symlink)"
        fi
    else
        echo "    ✓ ${icon_name}.png exists"
    fi
done

# [NEW] Setup desktop icons (idesk)
echo "[9/17] Setting up desktop icons..."
mkdir -p "$SQUASHFS_ROOT/etc/skel/.idesktop"
cp "$CONFIG_DIR/idesk/ideskrc" "$SQUASHFS_ROOT/etc/skel/.ideskrc"
cp "$CONFIG_DIR/idesk/idesktop/terminal.lnk" "$SQUASHFS_ROOT/etc/skel/.idesktop/"
cp "$CONFIG_DIR/idesk/idesktop/filemanager.lnk" "$SQUASHFS_ROOT/etc/skel/.idesktop/"
cp "$CONFIG_DIR/idesk/idesktop/firefox.lnk" "$SQUASHFS_ROOT/etc/skel/.idesktop/"
chmod 644 "$SQUASHFS_ROOT/etc/skel/.ideskrc"
chmod 644 "$SQUASHFS_ROOT/etc/skel/.idesktop/"*.lnk
echo "  ✓ Desktop icons: Terminal, Files, Firefox"

# Korean locale configuration
echo "[10/17] Adding full Korean locale support..."

cat > "$SQUASHFS_ROOT/etc/locale.gen" << 'LOCALE_GEN_EOF'
# MaruxOS Locale Configuration - Full Korean Support
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

echo "  - Generating Korean locale..."
chroot "$SQUASHFS_ROOT" /usr/bin/localedef -i ko_KR -f UTF-8 ko_KR.UTF-8 2>/dev/null || echo "    Warning: localedef issue"
chroot "$SQUASHFS_ROOT" /usr/bin/localedef -i en_US -f UTF-8 en_US.UTF-8 2>/dev/null || true

# Verify Korean fonts
echo "  - Checking Korean fonts..."
if [ -d "$SQUASHFS_ROOT/usr/share/fonts" ]; then
    if find "$SQUASHFS_ROOT/usr/share/fonts" -name "*Nanum*" -o -name "*NotoSans*CJK*" -o -name "*Baekmuk*" | grep -q .; then
        echo "    ✓ Korean fonts found"
    else
        echo "    ⚠ WARNING: Korean fonts not found!"
    fi
fi

if [ -x "$SQUASHFS_ROOT/usr/bin/fc-cache" ]; then
    echo "  - Updating font cache..."
    chroot "$SQUASHFS_ROOT" /usr/bin/fc-cache -f 2>/dev/null || true
fi

# Configure ibus-hangul
echo "[11/17] Configuring ibus-hangul..."

if [ -x "$SQUASHFS_ROOT/usr/sbin/ldconfig" ]; then
    chroot "$SQUASHFS_ROOT" /usr/sbin/ldconfig 2>/dev/null || true
fi

if [ -x "$SQUASHFS_ROOT/usr/bin/ibus" ]; then
    chroot "$SQUASHFS_ROOT" /usr/bin/ibus write-cache 2>/dev/null || true
fi

mkdir -p "$SQUASHFS_ROOT/usr/share/glib-2.0/schemas"
if [ -x "$SQUASHFS_ROOT/usr/bin/glib-compile-schemas" ]; then
    chroot "$SQUASHFS_ROOT" /usr/bin/glib-compile-schemas /usr/share/glib-2.0/schemas/ 2>/dev/null || true
fi

# Verify ibus-hangul
if [ -f "$SQUASHFS_ROOT/usr/lib/ibus/ibus-engine-hangul" ]; then
    echo "    ✓ ibus-engine-hangul: INSTALLED"
else
    echo "    ✗ ERROR: ibus-engine-hangul not found!"
    exit 1
fi

# GTK3 immodules cache
echo "[12/17] Updating GTK3 immodules cache..."
if [ -x "$SQUASHFS_ROOT/usr/bin/gtk-query-immodules-3.0" ]; then
    chroot "$SQUASHFS_ROOT" /bin/bash -c '/usr/bin/gtk-query-immodules-3.0 > /usr/lib/gtk-3.0/3.0.0/immodules.cache 2>/dev/null' || true
fi

if ! grep -q ibus "$SQUASHFS_ROOT/usr/lib/gtk-3.0/3.0.0/immodules.cache" 2>/dev/null; then
    cat >> "$SQUASHFS_ROOT/usr/lib/gtk-3.0/3.0.0/immodules.cache" << 'IBUS_CACHE_EOF'

"/usr/lib/gtk-3.0/3.0.0/immodules/im-ibus.so"
"ibus" "Intelligent Input Bus" "ibus10" "/usr/share/locale" ""

IBUS_CACHE_EOF
    echo "    ✓ ibus manually added to immodules.cache"
else
    echo "    ✓ ibus already in immodules.cache"
fi

# Update version info
echo "[13/17] Updating version info to 1.2.0..."

if [ -f "$SQUASHFS_ROOT/etc/maruxos-release" ]; then
    sed -i 's/MaruxOS 1\.[0-9]\+\(\.[0-9]\+\)\?/MaruxOS 1.2.0/g' "$SQUASHFS_ROOT/etc/maruxos-release"
    echo "    ✓ /etc/maruxos-release"
fi

if [ -f "$SQUASHFS_ROOT/etc/os-release" ]; then
    sed -i 's/VERSION="1\.[0-9]\+\(\.[0-9]\+\)\?"/VERSION="1.2.0"/g' "$SQUASHFS_ROOT/etc/os-release"
    sed -i 's/VERSION_ID="1\.[0-9]\+\(\.[0-9]\+\)\?"/VERSION_ID="1.2.0"/g' "$SQUASHFS_ROOT/etc/os-release"
    sed -i 's/MaruxOS 1\.[0-9]\+\(\.[0-9]\+\)\?/MaruxOS 1.2.0/g' "$SQUASHFS_ROOT/etc/os-release"
    echo "    ✓ /etc/os-release"
fi

if [ -f "$SQUASHFS_ROOT/etc/issue" ]; then
    sed -i 's/MaruxOS 1\.[0-9]\+\(\.[0-9]\+\)\?/MaruxOS 1.2.0/g' "$SQUASHFS_ROOT/etc/issue"
    echo "    ✓ /etc/issue"
fi

if [ -f "$SQUASHFS_ROOT/etc/lsb-release" ]; then
    sed -i 's/DISTRIB_RELEASE=1\.[0-9]\+\(\.[0-9]\+\)\?/DISTRIB_RELEASE=1.2.0/g' "$SQUASHFS_ROOT/etc/lsb-release"
    sed -i 's/MaruxOS 1\.[0-9]\+\(\.[0-9]\+\)\?/MaruxOS 1.2.0/g' "$SQUASHFS_ROOT/etc/lsb-release"
    echo "    ✓ /etc/lsb-release"
fi

if [ -f "$SQUASHFS_ROOT/usr/bin/marux-splash" ]; then
    sed -i 's/MaruxOS 1\.[0-9]\+\(\.[0-9]\+\)\?/MaruxOS 1.2.0/g' "$SQUASHFS_ROOT/usr/bin/marux-splash"
    echo "    ✓ /usr/bin/marux-splash"
fi

# Update initrd boot splash
echo "[14/17] Updating initrd boot splash..."
INITRD_WORK="/tmp/initrd-modify-$$"
mkdir -p "$INITRD_WORK"
cd "$INITRD_WORK"
gunzip -c "$ISO_DIR/boot/initrd.img" | cpio -id 2>/dev/null

if [ -f "$INITRD_WORK/init" ]; then
    sed -i 's/MaruxOS 1\.[0-9]\+\(\.[0-9]\+\)\? [0-9]\+/MaruxOS 1.2.0 67/g' "$INITRD_WORK/init"
    sed -i 's/MaruxOS 1\.[0-9]\+\(\.[0-9]\+\)\?/MaruxOS 1.2.0/g' "$INITRD_WORK/init"
    echo "    ✓ init script updated"
fi

find . | cpio -o -H newc 2>/dev/null | gzip -9 > "$ISO_DIR/boot/initrd.img"
cd "$WORK_DIR"
rm -rf "$INITRD_WORK"
echo "    ✓ initrd.img repacked"

# Copy desktop files
echo "[15/17] Copying desktop/tint2 files..."
cp "$CONFIG_DIR/applications/marux-menu.desktop" "$SQUASHFS_ROOT/usr/share/applications/" 2>/dev/null || true
cp "$CONFIG_DIR/applications/firefox.desktop" "$SQUASHFS_ROOT/usr/share/applications/" 2>/dev/null || true
cp "$CONFIG_DIR/applications/xterm.desktop" "$SQUASHFS_ROOT/usr/share/applications/" 2>/dev/null || true
cp "$CONFIG_DIR/applications/mc.desktop" "$SQUASHFS_ROOT/usr/share/applications/" 2>/dev/null || true
cp "$CONFIG_DIR/applications/battery.desktop" "$SQUASHFS_ROOT/usr/share/applications/" 2>/dev/null || true
cp "$CONFIG_DIR/applications/network.desktop" "$SQUASHFS_ROOT/usr/share/applications/" 2>/dev/null || true
cp "$CONFIG_DIR/applications/volume.desktop" "$SQUASHFS_ROOT/usr/share/applications/" 2>/dev/null || true

mkdir -p "$SQUASHFS_ROOT/etc/xdg/tint2"
cp "$CONFIG_DIR/tint2/tint2rc" "$SQUASHFS_ROOT/etc/xdg/tint2/tint2rc"

# Set permissions
echo "[16/17] Setting permissions..."
chmod 644 "$SQUASHFS_ROOT/etc/locale.gen" 2>/dev/null || true
chmod 644 "$SQUASHFS_ROOT/etc/locale.conf" 2>/dev/null || true
chmod 644 "$SQUASHFS_ROOT/etc/environment" 2>/dev/null || true
chmod 644 "$SQUASHFS_ROOT/etc/xdg/tint2/tint2rc" 2>/dev/null || true
chmod 755 "$SQUASHFS_ROOT/usr/lib/ibus/ibus-engine-hangul" 2>/dev/null || true
chmod 755 "$SQUASHFS_ROOT/usr/bin/idesk" 2>/dev/null || true

# Build ISO
echo "[17/17] Building ISO..."
rm -f "$ISO_DIR/live/filesystem.squashfs"

echo "  - Creating squashfs (this may take a while)..."
mksquashfs "$SQUASHFS_ROOT" "$ISO_DIR/live/filesystem.squashfs" \
    -comp gzip \
    -e boot \
    -noappend

echo "  - Creating ISO image..."
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
    -output "$OUTPUT_DIR/MaruxOS-1.2.0-$VERSION.iso" \
    "$ISO_DIR" 2>/dev/null || \
grub-mkrescue -o "$OUTPUT_DIR/MaruxOS-1.2.0-$VERSION.iso" "$ISO_DIR"

# Show result
echo ""
echo "=========================================="
echo "✓ Build complete!"
ls -lh "$OUTPUT_DIR/MaruxOS-1.2.0-$VERSION.iso" 2>/dev/null || echo "ISO created"
echo "=========================================="
echo ""
echo "Changes in v1.4.0:"
echo "  ✅ 바탕화면 우클릭 메뉴 (Openbox menu.xml)"
echo "  ✅ 키보드 단축키 (Alt+F4, Alt+Tab, Win+D/T/E, F11, Win+Arrow)"
echo "  ✅ 배경화면 변경 도구 (marux-wallpaper)"
echo "  ✅ 바탕화면 아이콘 (idesk: Terminal, Files, Firefox)"
echo "  ✅ 바탕화면 파일 기능 (~/Desktop 폴더 동기화)"
echo "  ✅ neofetch 시스템 정보 도구"
echo "  ✅ GRUB/initrd/release 버전 1.2.0 업데이트"
echo "  ✅ ISO 파일명: MaruxOS-1.2.0-$VERSION.iso"
echo ""
echo "v1.2.0 바탕화면 기능:"
echo "  - 우클릭: 앱 실행, 설정, 시스템 메뉴"
echo "  - Win+D: 바탕화면 보기"
echo "  - Win+T: 터미널 열기"
echo "  - Win+E: 파일 매니저"
echo "  - Win+Arrow: 창 스냅"
echo "  - 배경화면 변경 (우클릭 → Settings → Change Wallpaper)"
echo "  - ~/Desktop 파일 → 바탕화면 아이콘 (우클릭 → Refresh Desktop)"
echo "=========================================="
