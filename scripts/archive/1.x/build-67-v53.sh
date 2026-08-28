#!/bin/bash
# MaruxOS 67-v53 Build Script (Enable memconf config backend for ibus)

set -e

WORK_DIR="/home/administrator/MaruxOS/build"
SQUASHFS_ROOT="$WORK_DIR/rootfs-lfs"
ISO_DIR="$WORK_DIR/iso-build"
CONFIG_DIR="/mnt/c/Users/Administrator/Desktop/MaruxOS/config"
OUTPUT_DIR="/mnt/c/Users/Administrator/Desktop/MaruxOS/output"
SCRIPT_DIR="/mnt/c/Users/Administrator/Desktop/MaruxOS/scripts"
VERSION="67-v53"

echo "=========================================="
echo "MaruxOS $VERSION Build Script"
echo "Enable memconf config backend for ibus"
echo "=========================================="

cd "$WORK_DIR"

# Clean up any existing mounts
echo "[1/11] Cleaning up..."
umount "$SQUASHFS_ROOT/proc" 2>/dev/null || true
umount "$SQUASHFS_ROOT/sys" 2>/dev/null || true
umount "$SQUASHFS_ROOT/dev" 2>/dev/null || true

# Create ISO directory structure
echo "[2/11] Setting up ISO directory..."
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

# Create GRUB config
cat > "$ISO_DIR/boot/grub/grub.cfg" << 'GRUB_EOF'
set default=0
set timeout=5

menuentry "MaruxOS 1.0 (67) - Korean Input" {
    linux /boot/vmlinuz boot=live quiet
    initrd /boot/initrd.img
}

menuentry "MaruxOS 1.0 (67) - Safe Mode" {
    linux /boot/vmlinuz boot=live single
    initrd /boot/initrd.img
}
GRUB_EOF

# Install ibus-hangul (Korean input method)
echo "[3/11] Installing ibus-hangul Korean input method..."
echo "  This will compile libhangul, ibus, and ibus-hangul from source..."

if [ -f "$SCRIPT_DIR/install-ibus-hangul.sh" ]; then
    echo "  - Running ibus-hangul installation script..."
    bash "$SCRIPT_DIR/install-ibus-hangul.sh"

    if [ $? -eq 0 ]; then
        echo "  ✓ ibus-hangul installation completed successfully"
    else
        echo "  ✗ ERROR: ibus-hangul installation failed"
        exit 1
    fi
else
    echo "  ✗ ERROR: install-ibus-hangul.sh not found at $SCRIPT_DIR"
    exit 1
fi

# Apply v53 changes (memconf config backend)
echo "[4/11] Copying config files..."

# Copy xinitrc (with memconf config backend)
echo "  - Copying xinitrc with memconf config backend..."
cp "$CONFIG_DIR/xinitrc" "$SQUASHFS_ROOT/etc/X11/xinit/xinitrc"
chmod 755 "$SQUASHFS_ROOT/etc/X11/xinit/xinitrc"

# Add Korean locale configuration
echo "[5/11] Adding full Korean locale support..."

# Create locale.gen (모든 한국어 인코딩)
cat > "$SQUASHFS_ROOT/etc/locale.gen" << 'LOCALE_GEN_EOF'
# MaruxOS Locale Configuration - Full Korean Support
en_US.UTF-8 UTF-8
ko_KR.UTF-8 UTF-8
ko_KR.EUC-KR EUC-KR
C.UTF-8 UTF-8
LOCALE_GEN_EOF

# Create locale.conf (완벽한 한국어 지원)
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

# Create environment file for system-wide locale
cat > "$SQUASHFS_ROOT/etc/environment" << 'ENV_EOF'
LANG=ko_KR.UTF-8
LC_ALL=ko_KR.UTF-8
ENV_EOF

# Create locale directories
mkdir -p "$SQUASHFS_ROOT/usr/share/locale/ko/LC_MESSAGES"
mkdir -p "$SQUASHFS_ROOT/usr/lib/locale"

# Generate locales (CRITICAL - actually generate the locale files)
echo "  - Generating Korean locale..."
chroot "$SQUASHFS_ROOT" /usr/bin/localedef -i ko_KR -f UTF-8 ko_KR.UTF-8 2>/dev/null || echo "    Warning: localedef not available, locale may need manual generation"
chroot "$SQUASHFS_ROOT" /usr/bin/localedef -i en_US -f UTF-8 en_US.UTF-8 2>/dev/null || true

# Verify Korean fonts are available
echo "  - Checking Korean fonts..."
KOREAN_FONTS_FOUND=0
if [ -d "$SQUASHFS_ROOT/usr/share/fonts" ]; then
    if find "$SQUASHFS_ROOT/usr/share/fonts" -name "*Nanum*" -o -name "*NotoSans*CJK*" -o -name "*Baekmuk*" | grep -q .; then
        echo "    ✓ Korean fonts found"
        KOREAN_FONTS_FOUND=1
    fi
fi

if [ $KOREAN_FONTS_FOUND -eq 0 ]; then
    echo "    ⚠ WARNING: Korean fonts not found!"
    echo "    Korean text may display as boxes/squares"
    echo "    Install fonts: noto-fonts-cjk, nanum-fonts, or ttf-baekmuk"
fi

# Update font cache
if [ -x "$SQUASHFS_ROOT/usr/bin/fc-cache" ]; then
    echo "  - Updating font cache..."
    chroot "$SQUASHFS_ROOT" /usr/bin/fc-cache -f 2>/dev/null || true
fi

echo "  - Full Korean locale configuration complete"

# Configure ibus-hangul
echo "[6/11] Configuring ibus-hangul..."

# Update library cache for ibus libraries
if [ -x "$SQUASHFS_ROOT/usr/sbin/ldconfig" ]; then
    echo "  - Updating library cache..."
    chroot "$SQUASHFS_ROOT" /usr/sbin/ldconfig 2>/dev/null || true
fi

# Update ibus component cache
if [ -x "$SQUASHFS_ROOT/usr/bin/ibus" ]; then
    echo "  - Updating ibus cache..."
    chroot "$SQUASHFS_ROOT" /usr/bin/ibus write-cache 2>/dev/null || echo "    Note: ibus cache will be generated on first run"
fi

# Create and compile GSettings schemas (CRITICAL for ibus + ibus-engine-hangul!)
echo "  - Creating and compiling GSettings schemas..."
mkdir -p "$SQUASHFS_ROOT/usr/share/glib-2.0/schemas"

# ibus 메인 스키마 + hangul 스키마 생성 (install-ibus-hangul.sh에서 이미 생성했지만 확인)
if ! ls "$SQUASHFS_ROOT/usr/share/glib-2.0/schemas/org.freedesktop.ibus.gschema.xml" 2>/dev/null; then
    echo "    ⚠ ibus GSettings schema missing - should have been created by install-ibus-hangul.sh"
else
    echo "    ✓ ibus GSettings schema exists"
fi

if ! ls "$SQUASHFS_ROOT/usr/share/glib-2.0/schemas/"*hangul* 2>/dev/null; then
    echo "    ⚠ hangul GSettings schema missing"
else
    echo "    ✓ hangul GSettings schema exists"
fi

# 스키마 컴파일
if [ -x "$SQUASHFS_ROOT/usr/bin/glib-compile-schemas" ]; then
    chroot "$SQUASHFS_ROOT" /usr/bin/glib-compile-schemas /usr/share/glib-2.0/schemas/
    echo "    ✓ GSettings schemas compiled"
else
    echo "    ⚠ glib-compile-schemas not found"
fi

# Verify ibus-hangul installation
echo "  - Verifying ibus-hangul installation..."
if [ -f "$SQUASHFS_ROOT/usr/lib/ibus/ibus-engine-hangul" ]; then
    echo "    ✓ ibus-engine-hangul: INSTALLED"
else
    echo "    ✗ ERROR: ibus-engine-hangul not found!"
    exit 1
fi

if [ -f "$SQUASHFS_ROOT/usr/share/ibus/component/hangul.xml" ]; then
    echo "    ✓ hangul.xml component: INSTALLED"
else
    echo "    ✗ ERROR: hangul.xml component not found!"
    exit 1
fi

echo "  ✓ ibus-hangul configured successfully"

# Copy desktop files (release version)
echo "[7/11] Copying desktop files..."
cp "$CONFIG_DIR/applications/marux-menu.desktop" "$SQUASHFS_ROOT/usr/share/applications/" 2>/dev/null || true
cp "$CONFIG_DIR/applications/firefox.desktop" "$SQUASHFS_ROOT/usr/share/applications/" 2>/dev/null || true
cp "$CONFIG_DIR/applications/xterm.desktop" "$SQUASHFS_ROOT/usr/share/applications/" 2>/dev/null || true
cp "$CONFIG_DIR/applications/mc.desktop" "$SQUASHFS_ROOT/usr/share/applications/" 2>/dev/null || true
cp "$CONFIG_DIR/applications/battery.desktop" "$SQUASHFS_ROOT/usr/share/applications/" 2>/dev/null || true
cp "$CONFIG_DIR/applications/network.desktop" "$SQUASHFS_ROOT/usr/share/applications/" 2>/dev/null || true
cp "$CONFIG_DIR/applications/volume.desktop" "$SQUASHFS_ROOT/usr/share/applications/" 2>/dev/null || true

# Copy tint2 config (release location: /etc/xdg/tint2/)
echo "[8/11] Copying tint2 config..."
mkdir -p "$SQUASHFS_ROOT/etc/xdg/tint2"
cp "$CONFIG_DIR/tint2/tint2rc" "$SQUASHFS_ROOT/etc/xdg/tint2/tint2rc"

echo "[9/11] Setting permissions..."
chmod 644 "$SQUASHFS_ROOT/etc/locale.gen" 2>/dev/null || true
chmod 644 "$SQUASHFS_ROOT/etc/locale.conf" 2>/dev/null || true
chmod 644 "$SQUASHFS_ROOT/etc/environment" 2>/dev/null || true
chmod 644 "$SQUASHFS_ROOT/etc/xdg/tint2/tint2rc" 2>/dev/null || true
chmod 755 "$SQUASHFS_ROOT/usr/lib/ibus/ibus-engine-hangul" 2>/dev/null || true

# Remove old squashfs
echo "[10/11] Removing old squashfs..."
rm -f "$ISO_DIR/live/filesystem.squashfs"

# Create new squashfs
echo "Creating squashfs (this may take a while)..."
mksquashfs "$SQUASHFS_ROOT" "$ISO_DIR/live/filesystem.squashfs" \
    -comp gzip \
    -e boot \
    -noappend

# Create ISO
echo "[11/11] Creating ISO..."
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
    -output "$OUTPUT_DIR/MaruxOS-1.0-$VERSION.iso" \
    "$ISO_DIR" 2>/dev/null || \
grub-mkrescue -o "$OUTPUT_DIR/MaruxOS-1.0-$VERSION.iso" "$ISO_DIR"

# Show result
echo ""
echo "=========================================="
echo "✓ Build complete!"
ls -lh "$OUTPUT_DIR/MaruxOS-1.0-$VERSION.iso" 2>/dev/null || echo "ISO created"
echo "=========================================="
echo ""
echo "Changes in v53:"
echo "  ✅ ibus 재빌드: --enable-memconf (메모리 기반 설정 백엔드)"
echo "  ✅ ibus-daemon: --config=memconf 옵션 추가"
echo "  ✅ /root/.config/ibus/bus 디렉토리 생성 추가"
echo ""
echo "Root cause fix:"
echo "  - 'Can not execute default config program' 에러의 근본 원인 해결"
echo "  - 이전: --disable-dconf로 빌드 → 설정 백엔드 없음 → 크래시"
echo "  - 현재: --enable-memconf로 빌드 → 메모리 기반 설정 백엔드 사용"
echo ""
echo "Note: ISO 빌드 과정에서 자동으로 ibus를 재빌드를 해줘서 다시 하지 않으셔도 됩니다. (install-ibus-hangul.sh 자동 실행)"
echo "=========================================="
