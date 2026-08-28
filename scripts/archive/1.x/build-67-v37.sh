#!/bin/bash
# MaruxOS 67-v37 Build Script

set -e

WORK_DIR="/home/administrator/MaruxOS/build"
SQUASHFS_ROOT="$WORK_DIR/rootfs-lfs"
ISO_DIR="$WORK_DIR/iso-build"
CONFIG_DIR="/mnt/c/Users/Administrator/Desktop/MaruxOS/config"
OUTPUT_DIR="/mnt/c/Users/Administrator/Desktop/MaruxOS/output"
VERSION="67-v37"

echo "=========================================="
echo "MaruxOS $VERSION Build Script"
echo "=========================================="

cd "$WORK_DIR"

# Clean up any existing mounts
echo "[1/7] Cleaning up..."
umount "$SQUASHFS_ROOT/proc" 2>/dev/null || true
umount "$SQUASHFS_ROOT/sys" 2>/dev/null || true
umount "$SQUASHFS_ROOT/dev" 2>/dev/null || true

# Create ISO directory structure
echo "[2/7] Setting up ISO directory..."
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

# Apply v37 changes
echo "[3/7] Applying v37 changes..."

# Copy desktop files (Firefox fix included)
echo "  - Copying desktop files with Firefox icon fix..."
cp "$CONFIG_DIR/applications/firefox.desktop" "$SQUASHFS_ROOT/usr/share/applications/"
cp "$CONFIG_DIR/applications/terminal.desktop" "$SQUASHFS_ROOT/usr/share/applications/"
cp "$CONFIG_DIR/applications/filemanager.desktop" "$SQUASHFS_ROOT/usr/share/applications/"

# Copy tint2 config
echo "  - Copying tint2 config..."
mkdir -p "$SQUASHFS_ROOT/etc/skel/.config/tint2"
cp "$CONFIG_DIR/tint2/tint2rc" "$SQUASHFS_ROOT/etc/skel/.config/tint2/tint2rc"

# Copy xinitrc
echo "  - Copying xinitrc..."
cp "$CONFIG_DIR/xinitrc" "$SQUASHFS_ROOT/etc/X11/xinit/xinitrc"
chmod 755 "$SQUASHFS_ROOT/etc/X11/xinit/xinitrc"

echo "[4/7] Setting permissions..."
chmod 644 "$SQUASHFS_ROOT/usr/share/applications/firefox.desktop"
chmod 644 "$SQUASHFS_ROOT/usr/share/applications/terminal.desktop"
chmod 644 "$SQUASHFS_ROOT/usr/share/applications/filemanager.desktop"
chmod 644 "$SQUASHFS_ROOT/etc/skel/.config/tint2/tint2rc"

# Remove old squashfs
echo "[5/7] Removing old squashfs..."
rm -f "$ISO_DIR/live/filesystem.squashfs"

# Create new squashfs
echo "[6/7] Creating squashfs (this may take a while)..."
mksquashfs "$SQUASHFS_ROOT" "$ISO_DIR/live/filesystem.squashfs" \
    -comp gzip \
    -e boot \
    -noappend

# Create ISO
echo "[7/7] Creating ISO..."
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
echo "Changes in v37:"
echo "  - Fixed Firefox icon duplication in tint2"
echo "  - firefox.desktop: StartupWMClass=Navigator"
echo "  - firefox.desktop: StartupNotify=true"
echo "=========================================="
