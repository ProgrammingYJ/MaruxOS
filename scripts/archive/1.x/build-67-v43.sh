#!/bin/bash
# MaruxOS 67-v43 Build Script (Clean Release Rebuild)

set -e

WORK_DIR="/home/administrator/MaruxOS/build"
SQUASHFS_ROOT="$WORK_DIR/rootfs-lfs"
ISO_DIR="$WORK_DIR/iso-build"
CONFIG_DIR="/mnt/c/Users/Administrator/Desktop/MaruxOS/config"
OUTPUT_DIR="/mnt/c/Users/Administrator/Desktop/MaruxOS/output"
VERSION="67-v43"

echo "=========================================="
echo "MaruxOS $VERSION Build Script"
echo "Release + Korean Locale Support"
echo "=========================================="

cd "$WORK_DIR"

# Clean up any existing mounts
echo "[1/8] Cleaning up..."
umount "$SQUASHFS_ROOT/proc" 2>/dev/null || true
umount "$SQUASHFS_ROOT/sys" 2>/dev/null || true
umount "$SQUASHFS_ROOT/dev" 2>/dev/null || true

# Create ISO directory structure
echo "[2/8] Setting up ISO directory..."
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

# Apply v43 changes (Clean release rebuild - verification)
echo "[3/8] Copying config files (clean release state)..."

# Copy xinitrc (clean version without Korean locale)
echo "  - Copying xinitrc..."
cp "$CONFIG_DIR/xinitrc" "$SQUASHFS_ROOT/etc/X11/xinit/xinitrc"
chmod 755 "$SQUASHFS_ROOT/etc/X11/xinit/xinitrc"

echo "  - No additional locale configuration (release state)"

# Copy desktop files (release version)
echo "[4/8] Copying desktop files..."
cp "$CONFIG_DIR/applications/marux-menu.desktop" "$SQUASHFS_ROOT/usr/share/applications/" 2>/dev/null || true
cp "$CONFIG_DIR/applications/firefox.desktop" "$SQUASHFS_ROOT/usr/share/applications/" 2>/dev/null || true
cp "$CONFIG_DIR/applications/xterm.desktop" "$SQUASHFS_ROOT/usr/share/applications/" 2>/dev/null || true
cp "$CONFIG_DIR/applications/mc.desktop" "$SQUASHFS_ROOT/usr/share/applications/" 2>/dev/null || true
cp "$CONFIG_DIR/applications/battery.desktop" "$SQUASHFS_ROOT/usr/share/applications/" 2>/dev/null || true
cp "$CONFIG_DIR/applications/network.desktop" "$SQUASHFS_ROOT/usr/share/applications/" 2>/dev/null || true
cp "$CONFIG_DIR/applications/volume.desktop" "$SQUASHFS_ROOT/usr/share/applications/" 2>/dev/null || true

# Copy tint2 config (release location: /etc/xdg/tint2/)
echo "[5/8] Copying tint2 config..."
mkdir -p "$SQUASHFS_ROOT/etc/xdg/tint2"
cp "$CONFIG_DIR/tint2/tint2rc" "$SQUASHFS_ROOT/etc/xdg/tint2/tint2rc"

echo "[6/8] Setting permissions..."
chmod 644 "$SQUASHFS_ROOT/etc/locale.gen" 2>/dev/null || true
chmod 644 "$SQUASHFS_ROOT/etc/locale.conf" 2>/dev/null || true
chmod 644 "$SQUASHFS_ROOT/etc/xdg/tint2/tint2rc" 2>/dev/null || true

# Remove old squashfs
echo "[7/8] Removing old squashfs..."
rm -f "$ISO_DIR/live/filesystem.squashfs"

# Create new squashfs
echo "Creating squashfs (this may take a while)..."
mksquashfs "$SQUASHFS_ROOT" "$ISO_DIR/live/filesystem.squashfs" \
    -comp gzip \
    -e boot \
    -noappend

# Create ISO
echo "[8/8] Creating ISO..."
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
echo "Changes in v43:"
echo "  - Clean rebuild of release version"
echo "  - Verification build to confirm rollback"
echo "  - NO modifications from release version"
echo "=========================================="
