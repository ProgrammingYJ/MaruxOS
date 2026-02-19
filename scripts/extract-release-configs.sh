#!/bin/bash
# Extract all config files from release ISO

set -e

RELEASE_ISO="/mnt/c/Users/Administrator/Desktop/MaruxOS/output/MaruxOS-1.0-67-release.iso"
PROJECT_CONFIG="/mnt/c/Users/Administrator/Desktop/MaruxOS/config"
WORK_DIR="/home/administrator/release-extract"

echo "=========================================="
echo "Extracting config files from release ISO"
echo "=========================================="

# Clean up previous extraction
echo "[1/6] Cleaning up previous extraction..."
sudo umount "$WORK_DIR/iso-mount" 2>/dev/null || true
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR/iso-mount"
mkdir -p "$WORK_DIR/squashfs-root"

# Mount ISO
echo "[2/6] Mounting release ISO..."
sudo mount -o loop "$RELEASE_ISO" "$WORK_DIR/iso-mount"

# Extract squashfs
echo "[3/6] Extracting squashfs (this may take a while)..."
sudo unsquashfs -f -d "$WORK_DIR/squashfs-root" "$WORK_DIR/iso-mount/live/filesystem.squashfs"

# Extract xinitrc
echo "[4/6] Extracting xinitrc..."
if [ -f "$WORK_DIR/squashfs-root/etc/X11/xinit/xinitrc" ]; then
    sudo cp "$WORK_DIR/squashfs-root/etc/X11/xinit/xinitrc" "$PROJECT_CONFIG/xinitrc"
    sudo chown $USER:$USER "$PROJECT_CONFIG/xinitrc"
    echo "  ✓ xinitrc extracted"
else
    echo "  ✗ xinitrc not found in release"
fi

# Extract desktop files
echo "[5/6] Extracting desktop application files..."
mkdir -p "$PROJECT_CONFIG/applications"

for desktop_file in "$WORK_DIR/squashfs-root/usr/share/applications"/*.desktop; do
    if [ -f "$desktop_file" ]; then
        filename=$(basename "$desktop_file")
        # Only extract specific MaruxOS-related desktop files
        if [[ "$filename" == "firefox.desktop" ]] || \
           [[ "$filename" == "terminal.desktop" ]] || \
           [[ "$filename" == "filemanager.desktop" ]] || \
           [[ "$filename" == "maruxos-menu.desktop" ]]; then
            sudo cp "$desktop_file" "$PROJECT_CONFIG/applications/"
            sudo chown $USER:$USER "$PROJECT_CONFIG/applications/$filename"
            echo "  ✓ $filename extracted"
        fi
    fi
done

# Extract tint2 config
echo "[6/6] Extracting tint2 config..."
mkdir -p "$PROJECT_CONFIG/tint2"

if [ -f "$WORK_DIR/squashfs-root/etc/skel/.config/tint2/tint2rc" ]; then
    sudo cp "$WORK_DIR/squashfs-root/etc/skel/.config/tint2/tint2rc" "$PROJECT_CONFIG/tint2/tint2rc"
    sudo chown $USER:$USER "$PROJECT_CONFIG/tint2/tint2rc"
    echo "  ✓ tint2rc extracted"
else
    echo "  ✗ tint2rc not found in release"
fi

# Also extract tint2 desktop files if they exist
if [ -d "$WORK_DIR/squashfs-root/etc/skel/.config/tint2" ]; then
    for tint2_desktop in "$WORK_DIR/squashfs-root/etc/skel/.config/tint2"/*.desktop; do
        if [ -f "$tint2_desktop" ]; then
            filename=$(basename "$tint2_desktop")
            sudo cp "$tint2_desktop" "$PROJECT_CONFIG/tint2/"
            sudo chown $USER:$USER "$PROJECT_CONFIG/tint2/$filename"
            echo "  ✓ tint2/$filename extracted"
        fi
    done
fi

# Clean up
echo ""
echo "Cleaning up..."
sudo umount "$WORK_DIR/iso-mount"
rm -rf "$WORK_DIR"

echo ""
echo "=========================================="
echo "Config extraction complete!"
echo "=========================================="
echo ""
echo "Extracted files:"
echo "  - config/xinitrc"
echo "  - config/applications/*.desktop"
echo "  - config/tint2/*"
echo ""
echo "These are now the EXACT config files from release version."
echo "=========================================="
