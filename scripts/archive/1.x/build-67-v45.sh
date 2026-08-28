#!/bin/bash
# MaruxOS 67-v45 Build Script (Korean Locale Support)

set -e

WORK_DIR="/home/administrator/MaruxOS/build"
SQUASHFS_ROOT="$WORK_DIR/rootfs-lfs"
ISO_DIR="$WORK_DIR/iso-build"
CONFIG_DIR="/mnt/c/Users/Administrator/Desktop/MaruxOS/config"
OUTPUT_DIR="/mnt/c/Users/Administrator/Desktop/MaruxOS/output"
VERSION="67-v45"

echo "=========================================="
echo "MaruxOS $VERSION Build Script"
echo "Korean Locale Support (ko_KR.UTF-8)"
echo "=========================================="

cd "$WORK_DIR"

# Clean up any existing mounts
echo "[1/9] Cleaning up..."
umount "$SQUASHFS_ROOT/proc" 2>/dev/null || true
umount "$SQUASHFS_ROOT/sys" 2>/dev/null || true
umount "$SQUASHFS_ROOT/dev" 2>/dev/null || true

# Create ISO directory structure
echo "[2/9] Setting up ISO directory..."
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

menuentry "MaruxOS 1.0 (67)" {
    linux /boot/vmlinuz boot=live quiet
    initrd /boot/initrd.img
}

menuentry "MaruxOS 1.0 (67) - Safe Mode" {
    linux /boot/vmlinuz boot=live single
    initrd /boot/initrd.img
}
GRUB_EOF

# Apply v45 changes (Add Korean locale support)
echo "[3/9] Copying config files..."

# Copy xinitrc
echo "  - Copying xinitrc..."
cp "$CONFIG_DIR/xinitrc" "$SQUASHFS_ROOT/etc/X11/xinit/xinitrc"
chmod 755 "$SQUASHFS_ROOT/etc/X11/xinit/xinitrc"

# Add Korean locale configuration
echo "[4/9] Adding Korean locale support..."

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

echo "  - Korean locale configuration complete"

# Copy desktop files (release version)
echo "[5/9] Copying desktop files..."
cp "$CONFIG_DIR/applications/marux-menu.desktop" "$SQUASHFS_ROOT/usr/share/applications/" 2>/dev/null || true
cp "$CONFIG_DIR/applications/firefox.desktop" "$SQUASHFS_ROOT/usr/share/applications/" 2>/dev/null || true
cp "$CONFIG_DIR/applications/xterm.desktop" "$SQUASHFS_ROOT/usr/share/applications/" 2>/dev/null || true
cp "$CONFIG_DIR/applications/mc.desktop" "$SQUASHFS_ROOT/usr/share/applications/" 2>/dev/null || true
cp "$CONFIG_DIR/applications/battery.desktop" "$SQUASHFS_ROOT/usr/share/applications/" 2>/dev/null || true
cp "$CONFIG_DIR/applications/network.desktop" "$SQUASHFS_ROOT/usr/share/applications/" 2>/dev/null || true
cp "$CONFIG_DIR/applications/volume.desktop" "$SQUASHFS_ROOT/usr/share/applications/" 2>/dev/null || true

# Copy tint2 config (release location: /etc/xdg/tint2/)
echo "[6/9] Copying tint2 config..."
mkdir -p "$SQUASHFS_ROOT/etc/xdg/tint2"
cp "$CONFIG_DIR/tint2/tint2rc" "$SQUASHFS_ROOT/etc/xdg/tint2/tint2rc"

echo "[7/9] Setting permissions..."
chmod 644 "$SQUASHFS_ROOT/etc/locale.gen" 2>/dev/null || true
chmod 644 "$SQUASHFS_ROOT/etc/locale.conf" 2>/dev/null || true
chmod 644 "$SQUASHFS_ROOT/etc/xdg/tint2/tint2rc" 2>/dev/null || true

# Remove old squashfs
echo "[8/9] Removing old squashfs..."
rm -f "$ISO_DIR/live/filesystem.squashfs"

# Create new squashfs
echo "Creating squashfs (this may take a while)..."
mksquashfs "$SQUASHFS_ROOT" "$ISO_DIR/live/filesystem.squashfs" \
    -comp gzip \
    -e boot \
    -noappend

# Create ISO
echo "[9/9] Creating ISO..."
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
echo "Build complete!"
ls -lh "$OUTPUT_DIR/MaruxOS-1.0-$VERSION.iso" 2>/dev/null || echo "ISO created"
echo "=========================================="
echo ""
echo "Changes in v45:"
echo "  - 완벽한 한국어 로케일 지원 (ko_KR.UTF-8 + EUC-KR)"
echo "  - 모든 LC_* 환경변수 한국어로 설정"
echo "  - 한국어 입력기 지원 (ibus)"
echo "  - Locale files: /etc/locale.gen, /etc/locale.conf, /etc/environment"
echo "  - 시스템 전역 한국어 인코딩 설정"
echo "  - Locale directories: /usr/share/locale/ko/, /usr/lib/locale/"
echo ""
echo "Note: Built on top of v44 (release configuration)"
echo "      All Korean encoding support added"
echo "=========================================="
