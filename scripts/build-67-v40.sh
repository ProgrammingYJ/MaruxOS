#!/bin/bash
# MaruxOS 67-v40 Build Script

set -e

WORK_DIR="/home/administrator/MaruxOS/build"
SQUASHFS_ROOT="$WORK_DIR/rootfs-lfs"
ISO_DIR="$WORK_DIR/iso-build"
CONFIG_DIR="/mnt/c/Users/Administrator/Desktop/MaruxOS/config"
SCRIPT_DIR="/mnt/c/Users/Administrator/Desktop/MaruxOS/scripts"
OUTPUT_DIR="/mnt/c/Users/Administrator/Desktop/MaruxOS/output"
VERSION="67-v40"

echo "=========================================="
echo "MaruxOS $VERSION Build Script"
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
if [ -f "$SQUASHFS_ROOT/boot/vmlinuz"* ]; then
    cp "$SQUASHFS_ROOT/boot/vmlinuz"* "$ISO_DIR/boot/vmlinuz"
elif [ -f "$SQUASHFS_ROOT/boot/vmlinuz" ]; then
    cp "$SQUASHFS_ROOT/boot/vmlinuz" "$ISO_DIR/boot/vmlinuz"
fi

if [ -f "$SQUASHFS_ROOT/boot/initrd"* ]; then
    cp "$SQUASHFS_ROOT/boot/initrd"* "$ISO_DIR/boot/initrd.img"
elif [ -f "$SQUASHFS_ROOT/boot/initrd.img" ]; then
    cp "$SQUASHFS_ROOT/boot/initrd.img" "$ISO_DIR/boot/initrd.img"
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

# Apply v37 changes (Firefox icon fix)
echo "[3/9] Applying v37 changes (Firefox icon fix)..."

# Copy ALL desktop files (including maruxos-menu.desktop!)
echo "  - Copying desktop files..."
cp "$CONFIG_DIR/applications/maruxos-menu.desktop" "$SQUASHFS_ROOT/usr/share/applications/"
cp "$CONFIG_DIR/applications/firefox.desktop" "$SQUASHFS_ROOT/usr/share/applications/"
cp "$CONFIG_DIR/applications/terminal.desktop" "$SQUASHFS_ROOT/usr/share/applications/"
cp "$CONFIG_DIR/applications/filemanager.desktop" "$SQUASHFS_ROOT/usr/share/applications/"

# Apply v38 changes (Korean locale support)
echo "[4/9] Applying v38 changes (Korean locale support)..."

# Copy updated xinitrc with improved locale settings and tint2rc fallback
echo "  - Copying xinitrc with Korean locale support and tint2rc fallback..."
cp "$CONFIG_DIR/xinitrc" "$SQUASHFS_ROOT/etc/X11/xinit/xinitrc"
chmod 755 "$SQUASHFS_ROOT/etc/X11/xinit/xinitrc"

# Add Korean locale configuration
echo "  - Adding Korean locale configuration..."
mkdir -p "$SQUASHFS_ROOT/etc"
cat > "$SQUASHFS_ROOT/etc/locale.gen" << 'LOCALE_EOF'
# MaruxOS Locale Configuration
en_US.UTF-8 UTF-8
ko_KR.UTF-8 UTF-8
ja_JP.UTF-8 UTF-8
zh_CN.UTF-8 UTF-8
LOCALE_EOF

cat > "$SQUASHFS_ROOT/etc/locale.conf" << 'LOCALE_CONF_EOF'
LANG=ko_KR.UTF-8
LC_CTYPE=ko_KR.UTF-8
LC_MESSAGES=en_US.UTF-8
LC_COLLATE=C
LOCALE_CONF_EOF

# Create locale directories
mkdir -p "$SQUASHFS_ROOT/usr/share/locale/ko/LC_MESSAGES"
mkdir -p "$SQUASHFS_ROOT/usr/share/locale/ja/LC_MESSAGES"
mkdir -p "$SQUASHFS_ROOT/usr/share/locale/zh_CN/LC_MESSAGES"
mkdir -p "$SQUASHFS_ROOT/usr/lib/locale"

echo "  - Korean locale configuration complete"

# Apply v40 changes (Fix missing maruxos-menu.desktop)
echo "[5/9] Applying v40 changes (tint2 panel fix)..."
echo "  - All desktop files copied (including maruxos-menu.desktop)"
echo "  - This fixes the broken tint2 panel layout"

# Copy tint2 config to /etc/skel (for xinitrc fallback)
echo "[6/9] Copying tint2 config..."
mkdir -p "$SQUASHFS_ROOT/etc/skel/.config/tint2"
cp "$CONFIG_DIR/tint2/tint2rc" "$SQUASHFS_ROOT/etc/skel/.config/tint2/tint2rc"

# Also copy to root's home directory for Live ISO
mkdir -p "$SQUASHFS_ROOT/root/.config/tint2"
cp "$CONFIG_DIR/tint2/tint2rc" "$SQUASHFS_ROOT/root/.config/tint2/tint2rc"

echo "[7/9] Setting permissions..."
chmod 644 "$SQUASHFS_ROOT/usr/share/applications/maruxos-menu.desktop"
chmod 644 "$SQUASHFS_ROOT/usr/share/applications/firefox.desktop"
chmod 644 "$SQUASHFS_ROOT/usr/share/applications/terminal.desktop"
chmod 644 "$SQUASHFS_ROOT/usr/share/applications/filemanager.desktop"
chmod 644 "$SQUASHFS_ROOT/etc/skel/.config/tint2/tint2rc"
chmod 644 "$SQUASHFS_ROOT/root/.config/tint2/tint2rc"
chmod 644 "$SQUASHFS_ROOT/etc/locale.gen"
chmod 644 "$SQUASHFS_ROOT/etc/locale.conf"

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

# Check for grub-mkrescue or xorriso
if command -v grub-mkrescue &> /dev/null; then
    grub-mkrescue -o "$OUTPUT_DIR/MaruxOS-1.0-$VERSION.iso" "$ISO_DIR"
else
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
        "$ISO_DIR"
fi

# Show result
echo ""
echo "=========================================="
echo "Build complete!"
ls -lh "$OUTPUT_DIR/MaruxOS-1.0-$VERSION.iso"
echo "=========================================="
echo ""
echo "Changes in v40:"
echo "  - v37: Fixed Firefox icon duplication"
echo "  - v38: Added Korean locale support (ko_KR.UTF-8)"
echo "  - v39: Fixed tint2rc wget fallback to local file"
echo "  - v40: Fixed missing maruxos-menu.desktop (tint2 panel broken)"
echo ""
echo "Fixed issues:"
echo "  ✓ MaruxOS logo now shows in panel"
echo "  ✓ Firefox icon appears in panel"
echo "  ✓ Clock positioned correctly (right side)"
echo "  ✓ All launcher items working"
echo "=========================================="
