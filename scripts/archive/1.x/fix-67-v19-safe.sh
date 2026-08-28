#!/bin/bash
# MaruxOS 67-v19 Safe Fix Script
# Apply custom icons to v18 extracted filesystem

set -e

DESIGN_DIR="/mnt/c/Users/Administrator/Desktop/MaruxOS/MaruxOS 디자인"
SQUASHFS_ROOT="/home/administrator/MaruxOS/v18-restore/squashfs-root"

echo "=========================================="
echo "MaruxOS 67-v19 Safe Fix Script"
echo "=========================================="

if [ ! -d "$SQUASHFS_ROOT" ]; then
    echo "Error: $SQUASHFS_ROOT not found"
    exit 1
fi

# Create MaruxOS icon theme
ICON_THEME_DIR="$SQUASHFS_ROOT/usr/share/icons/MaruxOS"
echo "[1/5] Creating MaruxOS icon theme..."
mkdir -p "$ICON_THEME_DIR/48x48/apps"
mkdir -p "$ICON_THEME_DIR/48x48/status"
mkdir -p "$ICON_THEME_DIR/32x32/apps"
mkdir -p "$ICON_THEME_DIR/32x32/status"
mkdir -p "$ICON_THEME_DIR/24x24/apps"
mkdir -p "$ICON_THEME_DIR/24x24/status"

# Create index.theme
cat > "$ICON_THEME_DIR/index.theme" << 'EOF'
[Icon Theme]
Name=MaruxOS
Comment=MaruxOS Custom Icon Theme
Inherits=Adwaita,hicolor
Directories=48x48/apps,48x48/status,32x32/apps,32x32/status,24x24/apps,24x24/status

[48x48/apps]
Size=48
Context=Applications
Type=Fixed

[48x48/status]
Size=48
Context=Status
Type=Fixed

[32x32/apps]
Size=32
Context=Applications
Type=Fixed

[32x32/status]
Size=32
Context=Status
Type=Fixed

[24x24/apps]
Size=24
Context=Applications
Type=Fixed

[24x24/status]
Size=24
Context=Status
Type=Fixed
EOF

echo "[2/5] Copying app icons..."
for size in 48x48 32x32 24x24; do
    [ -f "$DESIGN_DIR/terminal.png" ] && cp "$DESIGN_DIR/terminal.png" "$ICON_THEME_DIR/$size/apps/utilities-terminal.png"
    [ -f "$DESIGN_DIR/marux-file-manager.png" ] && cp "$DESIGN_DIR/marux-file-manager.png" "$ICON_THEME_DIR/$size/apps/system-file-manager.png"
done

echo "[3/5] Copying WiFi icons..."
for size in 48x48 32x32 24x24; do
    [ -f "$DESIGN_DIR/wifi_0.png" ] && cp "$DESIGN_DIR/wifi_0.png" "$ICON_THEME_DIR/$size/status/network-wireless-signal-none.png"
    [ -f "$DESIGN_DIR/wifi_1.png" ] && cp "$DESIGN_DIR/wifi_1.png" "$ICON_THEME_DIR/$size/status/network-wireless-signal-weak.png"
    [ -f "$DESIGN_DIR/wifi_2.png" ] && cp "$DESIGN_DIR/wifi_2.png" "$ICON_THEME_DIR/$size/status/network-wireless-signal-ok.png"
    [ -f "$DESIGN_DIR/wifi_3.png" ] && cp "$DESIGN_DIR/wifi_3.png" "$ICON_THEME_DIR/$size/status/network-wireless-signal-good.png"
    [ -f "$DESIGN_DIR/wifi_4.png" ] && cp "$DESIGN_DIR/wifi_4.png" "$ICON_THEME_DIR/$size/status/network-wireless-signal-excellent.png"
    [ -f "$DESIGN_DIR/InternetLan.png" ] && cp "$DESIGN_DIR/InternetLan.png" "$ICON_THEME_DIR/$size/status/network-wired.png"
    [ -f "$DESIGN_DIR/internetNotConnected.png" ] && cp "$DESIGN_DIR/internetNotConnected.png" "$ICON_THEME_DIR/$size/status/network-offline.png"
done

echo "[4/5] Copying sound icons..."
for size in 48x48 32x32 24x24; do
    [ -f "$DESIGN_DIR/sound_0.png" ] && cp "$DESIGN_DIR/sound_0.png" "$ICON_THEME_DIR/$size/status/audio-volume-muted.png"
    [ -f "$DESIGN_DIR/sound_1.png" ] && cp "$DESIGN_DIR/sound_1.png" "$ICON_THEME_DIR/$size/status/audio-volume-low.png"
    [ -f "$DESIGN_DIR/sound_2.png" ] && cp "$DESIGN_DIR/sound_2.png" "$ICON_THEME_DIR/$size/status/audio-volume-medium.png"
    [ -f "$DESIGN_DIR/sound_3.png" ] && cp "$DESIGN_DIR/sound_3.png" "$ICON_THEME_DIR/$size/status/audio-volume-high.png"
done

echo "[5/5] Updating GTK icon theme settings..."
# Update GTK 3.0 settings
mkdir -p "$SQUASHFS_ROOT/etc/gtk-3.0"
cat > "$SQUASHFS_ROOT/etc/gtk-3.0/settings.ini" << 'EOF'
[Settings]
gtk-icon-theme-name = MaruxOS
gtk-theme-name = Adwaita
gtk-application-prefer-dark-theme = false
EOF

# Update launcher icons
mkdir -p "$SQUASHFS_ROOT/usr/share/maruxos/icons"
[ -f "$DESIGN_DIR/terminal.png" ] && cp "$DESIGN_DIR/terminal.png" "$SQUASHFS_ROOT/usr/share/maruxos/icons/marux-terminal.png"
[ -f "$DESIGN_DIR/marux-file-manager.png" ] && cp "$DESIGN_DIR/marux-file-manager.png" "$SQUASHFS_ROOT/usr/share/maruxos/icons/marux-file-manager.png"

echo ""
echo "=========================================="
echo "v19 Fix Applied Successfully!"
echo "Listing icon theme directory:"
ls -la "$ICON_THEME_DIR/24x24/status/" | head -10
echo "=========================================="
