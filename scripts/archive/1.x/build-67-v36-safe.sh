#!/bin/bash
# MaruxOS 67-v36 Safe Build Script
# v35 ISO 기반으로 안전하게 빌드

set -e

WORK_DIR="/home/administrator/MaruxOS/build"
ISO_SOURCE="/mnt/c/Users/Administrator/Desktop/MaruxOS/output/MaruxOS-1.0-67-v35.iso"
CONFIG_DIR="/mnt/c/Users/Administrator/Desktop/MaruxOS/config"
OUTPUT_DIR="/mnt/c/Users/Administrator/Desktop/MaruxOS/iso"
VERSION="67-v36"

echo "=========================================="
echo "MaruxOS $VERSION Safe Build Script"
echo "Based on v35 ISO"
echo "=========================================="

# Check if v35 ISO exists
if [ ! -f "$ISO_SOURCE" ]; then
    echo "ERROR: v35 ISO not found at $ISO_SOURCE"
    exit 1
fi

cd "$WORK_DIR"

# 1. Extract v35 ISO
echo "[1/6] Extracting v35 ISO..."
mkdir -p iso-mount squashfs-mount rootfs-new iso-build

# Mount ISO
mount -o loop "$ISO_SOURCE" iso-mount 2>/dev/null || {
    echo "Mounting with sudo..."
    sudo mount -o loop "$ISO_SOURCE" iso-mount
}

# Copy ISO contents
cp -a iso-mount/boot iso-build/
mkdir -p iso-build/live

# 2. Extract squashfs
echo "[2/6] Extracting squashfs..."
sudo mount -o loop iso-mount/live/filesystem.squashfs squashfs-mount
sudo cp -a squashfs-mount/* rootfs-new/
sudo umount squashfs-mount
sudo umount iso-mount

# 3. Apply v36 changes
echo "[3/6] Applying v36 changes..."

# Desktop files
echo "  - Desktop files..."
sudo cp "$CONFIG_DIR/applications/firefox.desktop" rootfs-new/usr/share/applications/ 2>/dev/null || true
sudo cp "$CONFIG_DIR/applications/terminal.desktop" rootfs-new/usr/share/applications/ 2>/dev/null || true
sudo cp "$CONFIG_DIR/applications/filemanager.desktop" rootfs-new/usr/share/applications/ 2>/dev/null || true

# tint2 config
echo "  - tint2 config..."
sudo mkdir -p rootfs-new/etc/skel/.config/tint2
sudo cp "$CONFIG_DIR/tint2/tint2rc" rootfs-new/etc/skel/.config/tint2/tint2rc

# Set permissions
echo "[4/6] Setting permissions..."
sudo chmod 644 rootfs-new/usr/share/applications/*.desktop 2>/dev/null || true
sudo chmod 644 rootfs-new/etc/skel/.config/tint2/tint2rc

# 5. Create squashfs
echo "[5/6] Creating squashfs..."
rm -f iso-build/live/filesystem.squashfs
sudo mksquashfs rootfs-new iso-build/live/filesystem.squashfs -comp gzip -noappend

# 6. Create ISO
echo "[6/6] Creating ISO..."
mkdir -p "$OUTPUT_DIR"
grub-mkrescue -o "$OUTPUT_DIR/MaruxOS-1.0-$VERSION.iso" iso-build

# Cleanup
echo "Cleaning up..."
sudo rm -rf rootfs-new iso-mount squashfs-mount

echo ""
echo "=========================================="
echo "Build complete!"
ls -lh "$OUTPUT_DIR/MaruxOS-1.0-$VERSION.iso"
echo "=========================================="
