#!/bin/bash
# MaruxOS 67-v19 Fix Script
# - Custom launcher icons (terminal.png, marux-file-manager.png)
# - Custom system tray icon theme (WiFi, Sound, Battery)
# - Configure applets to use MaruxOS icon theme

set -e

DESIGN_DIR="/mnt/c/Users/Administrator/Desktop/MaruxOS/MaruxOS 디자인"
SQUASHFS_ROOT="/home/administrator/MaruxOS/build/rootfs-lfs"

echo "=========================================="
echo "MaruxOS 67-v19 Fix Script"
echo "Custom Icons for Launcher & System Tray"
echo "=========================================="

# Check if squashfs-root exists
if [ ! -d "$SQUASHFS_ROOT" ]; then
    echo "Error: $SQUASHFS_ROOT not found"
    exit 1
fi

# Create icon theme directory structure
ICON_THEME_DIR="$SQUASHFS_ROOT/usr/share/icons/MaruxOS"
echo "[1/6] Creating MaruxOS icon theme directory..."
mkdir -p "$ICON_THEME_DIR/scalable/apps"
mkdir -p "$ICON_THEME_DIR/scalable/status"
mkdir -p "$ICON_THEME_DIR/scalable/devices"
mkdir -p "$ICON_THEME_DIR/48x48/apps"
mkdir -p "$ICON_THEME_DIR/48x48/status"
mkdir -p "$ICON_THEME_DIR/48x48/devices"
mkdir -p "$ICON_THEME_DIR/32x32/apps"
mkdir -p "$ICON_THEME_DIR/32x32/status"
mkdir -p "$ICON_THEME_DIR/32x32/devices"
mkdir -p "$ICON_THEME_DIR/24x24/apps"
mkdir -p "$ICON_THEME_DIR/24x24/status"
mkdir -p "$ICON_THEME_DIR/24x24/devices"

# Create index.theme
echo "[2/6] Creating icon theme index..."
cat > "$ICON_THEME_DIR/index.theme" << 'THEME_EOF'
[Icon Theme]
Name=MaruxOS
Comment=MaruxOS Custom Icon Theme
Inherits=Adwaita,hicolor
Directories=scalable/apps,scalable/status,scalable/devices,48x48/apps,48x48/status,48x48/devices,32x32/apps,32x32/status,32x32/devices,24x24/apps,24x24/status,24x24/devices

[scalable/apps]
Size=48
MinSize=16
MaxSize=256
Type=Scalable
Context=Applications

[scalable/status]
Size=48
MinSize=16
MaxSize=256
Type=Scalable
Context=Status

[scalable/devices]
Size=48
MinSize=16
MaxSize=256
Type=Scalable
Context=Devices

[48x48/apps]
Size=48
Context=Applications
Type=Fixed

[48x48/status]
Size=48
Context=Status
Type=Fixed

[48x48/devices]
Size=48
Context=Devices
Type=Fixed

[32x32/apps]
Size=32
Context=Applications
Type=Fixed

[32x32/status]
Size=32
Context=Status
Type=Fixed

[32x32/devices]
Size=32
Context=Devices
Type=Fixed

[24x24/apps]
Size=24
Context=Applications
Type=Fixed

[24x24/status]
Size=24
Context=Status
Type=Fixed

[24x24/devices]
Size=24
Context=Devices
Type=Fixed
THEME_EOF

# Copy and rename icons
echo "[3/6] Copying custom icons..."

# App icons - copy to multiple sizes for better compatibility
for size in 48x48 32x32 24x24; do
    # Terminal icon
    if [ -f "$DESIGN_DIR/terminal.png" ]; then
        cp "$DESIGN_DIR/terminal.png" "$ICON_THEME_DIR/$size/apps/utilities-terminal.png"
        cp "$DESIGN_DIR/terminal.png" "$ICON_THEME_DIR/$size/apps/terminal.png"
        cp "$DESIGN_DIR/terminal.png" "$ICON_THEME_DIR/$size/apps/xterm.png"
    fi

    # File Manager icon
    if [ -f "$DESIGN_DIR/marux-file-manager.png" ]; then
        cp "$DESIGN_DIR/marux-file-manager.png" "$ICON_THEME_DIR/$size/apps/system-file-manager.png"
        cp "$DESIGN_DIR/marux-file-manager.png" "$ICON_THEME_DIR/$size/apps/file-manager.png"
        cp "$DESIGN_DIR/marux-file-manager.png" "$ICON_THEME_DIR/$size/apps/mc.png"
    fi
done

# WiFi/Network status icons (for nm-applet)
for size in 48x48 32x32 24x24; do
    # WiFi signal levels
    if [ -f "$DESIGN_DIR/wifi_0.png" ]; then
        cp "$DESIGN_DIR/wifi_0.png" "$ICON_THEME_DIR/$size/status/network-wireless-signal-none.png"
        cp "$DESIGN_DIR/wifi_0.png" "$ICON_THEME_DIR/$size/status/network-wireless-offline.png"
    fi
    if [ -f "$DESIGN_DIR/wifi_1.png" ]; then
        cp "$DESIGN_DIR/wifi_1.png" "$ICON_THEME_DIR/$size/status/network-wireless-signal-weak.png"
    fi
    if [ -f "$DESIGN_DIR/wifi_2.png" ]; then
        cp "$DESIGN_DIR/wifi_2.png" "$ICON_THEME_DIR/$size/status/network-wireless-signal-ok.png"
    fi
    if [ -f "$DESIGN_DIR/wifi_3.png" ]; then
        cp "$DESIGN_DIR/wifi_3.png" "$ICON_THEME_DIR/$size/status/network-wireless-signal-good.png"
    fi
    if [ -f "$DESIGN_DIR/wifi_4.png" ]; then
        cp "$DESIGN_DIR/wifi_4.png" "$ICON_THEME_DIR/$size/status/network-wireless-signal-excellent.png"
        cp "$DESIGN_DIR/wifi_4.png" "$ICON_THEME_DIR/$size/status/network-wireless-connected.png"
    fi

    # Wired/LAN icon
    if [ -f "$DESIGN_DIR/InternetLan.png" ]; then
        cp "$DESIGN_DIR/InternetLan.png" "$ICON_THEME_DIR/$size/status/network-wired.png"
        cp "$DESIGN_DIR/InternetLan.png" "$ICON_THEME_DIR/$size/devices/network-wired.png"
    fi

    # No connection icon
    if [ -f "$DESIGN_DIR/internetNotConnected.png" ]; then
        cp "$DESIGN_DIR/internetNotConnected.png" "$ICON_THEME_DIR/$size/status/network-offline.png"
        cp "$DESIGN_DIR/internetNotConnected.png" "$ICON_THEME_DIR/$size/status/network-error.png"
    fi
done

# Sound/Volume icons (for volumeicon)
for size in 48x48 32x32 24x24; do
    if [ -f "$DESIGN_DIR/sound_0.png" ]; then
        cp "$DESIGN_DIR/sound_0.png" "$ICON_THEME_DIR/$size/status/audio-volume-muted.png"
    fi
    if [ -f "$DESIGN_DIR/sound_1.png" ]; then
        cp "$DESIGN_DIR/sound_1.png" "$ICON_THEME_DIR/$size/status/audio-volume-low.png"
    fi
    if [ -f "$DESIGN_DIR/sound_2.png" ]; then
        cp "$DESIGN_DIR/sound_2.png" "$ICON_THEME_DIR/$size/status/audio-volume-medium.png"
    fi
    if [ -f "$DESIGN_DIR/sound_3.png" ]; then
        cp "$DESIGN_DIR/sound_3.png" "$ICON_THEME_DIR/$size/status/audio-volume-high.png"
    fi
done

# Battery icons
for size in 48x48 32x32 24x24; do
    if [ -f "$DESIGN_DIR/bettery_25.png" ]; then
        cp "$DESIGN_DIR/bettery_25.png" "$ICON_THEME_DIR/$size/status/battery-low.png"
        cp "$DESIGN_DIR/bettery_25.png" "$ICON_THEME_DIR/$size/status/battery-caution.png"
    fi
    if [ -f "$DESIGN_DIR/bettery_50.png" ]; then
        cp "$DESIGN_DIR/bettery_50.png" "$ICON_THEME_DIR/$size/status/battery-good.png"
    fi
    if [ -f "$DESIGN_DIR/bettery_75.png" ]; then
        cp "$DESIGN_DIR/bettery_75.png" "$ICON_THEME_DIR/$size/status/battery-good-charging.png"
    fi
    if [ -f "$DESIGN_DIR/bettery_100.png" ]; then
        cp "$DESIGN_DIR/bettery_100.png" "$ICON_THEME_DIR/$size/status/battery-full.png"
        cp "$DESIGN_DIR/bettery_100.png" "$ICON_THEME_DIR/$size/status/battery-full-charged.png"
    fi
    if [ -f "$DESIGN_DIR/betteryCharge.png" ]; then
        cp "$DESIGN_DIR/betteryCharge.png" "$ICON_THEME_DIR/$size/status/battery-charging.png"
    fi
    if [ -f "$DESIGN_DIR/betteryLow.png" ]; then
        cp "$DESIGN_DIR/betteryLow.png" "$ICON_THEME_DIR/$size/status/battery-empty.png"
        cp "$DESIGN_DIR/betteryLow.png" "$ICON_THEME_DIR/$size/status/battery-missing.png"
    fi
done

echo "   Icons copied successfully"

# Update tint2 launcher icons
echo "[4/6] Updating launcher icons..."
LAUNCHER_DIR="$SQUASHFS_ROOT/usr/share/maruxos/icons"
mkdir -p "$LAUNCHER_DIR"

# Copy launcher icons
cp "$DESIGN_DIR/terminal.png" "$LAUNCHER_DIR/marux-terminal.png"
cp "$DESIGN_DIR/marux-file-manager.png" "$LAUNCHER_DIR/marux-file-manager.png"

# Update GTK settings to use MaruxOS icon theme
echo "[5/6] Configuring GTK to use MaruxOS icon theme..."

# GTK 2.0 settings
cat > "$SQUASHFS_ROOT/etc/skel/.gtkrc-2.0" << 'GTK2_EOF'
gtk-icon-theme-name = "MaruxOS"
gtk-theme-name = "Adwaita"
gtk-font-name = "Sans 10"
GTK2_EOF

# GTK 3.0 settings
mkdir -p "$SQUASHFS_ROOT/etc/skel/.config/gtk-3.0"
cat > "$SQUASHFS_ROOT/etc/skel/.config/gtk-3.0/settings.ini" << 'GTK3_EOF'
[Settings]
gtk-icon-theme-name = MaruxOS
gtk-theme-name = Adwaita
gtk-font-name = Sans 10
gtk-application-prefer-dark-theme = false
GTK3_EOF

# System-wide GTK settings
mkdir -p "$SQUASHFS_ROOT/etc/gtk-2.0"
cat > "$SQUASHFS_ROOT/etc/gtk-2.0/gtkrc" << 'SYSGTK2_EOF'
gtk-icon-theme-name = "MaruxOS"
gtk-theme-name = "Adwaita"
SYSGTK2_EOF

mkdir -p "$SQUASHFS_ROOT/etc/gtk-3.0"
cat > "$SQUASHFS_ROOT/etc/gtk-3.0/settings.ini" << 'SYSGTK3_EOF'
[Settings]
gtk-icon-theme-name = MaruxOS
gtk-theme-name = Adwaita
gtk-application-prefer-dark-theme = false
SYSGTK3_EOF

# Update xinitrc to set icon theme
echo "[6/6] Updating xinitrc..."
cat > "$SQUASHFS_ROOT/etc/X11/xinit/xinitrc" << 'XINITRC_EOF'
#!/bin/sh

# Set locale
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

# XDG directories
export XDG_RUNTIME_DIR=/tmp/runtime-root
mkdir -p $XDG_RUNTIME_DIR
chmod 700 $XDG_RUNTIME_DIR
export XDG_CONFIG_HOME=$HOME/.config
export XDG_DATA_HOME=$HOME/.local/share

# GTK/Icon theme settings
export GTK_THEME=Adwaita
export GTK2_RC_FILES=/etc/gtk-2.0/gtkrc:$HOME/.gtkrc-2.0
export GDK_PIXBUF_MODULE_FILE=/usr/lib/x86_64-linux-gnu/gdk-pixbuf-2.0/2.10.0/loaders.cache

# Icon theme - Use MaruxOS custom theme
export XCURSOR_THEME=Adwaita
export ICON_THEME=MaruxOS

# Copy default configs if not exist
if [ ! -f "$HOME/.gtkrc-2.0" ]; then
    cp /etc/skel/.gtkrc-2.0 "$HOME/.gtkrc-2.0" 2>/dev/null || true
fi
if [ ! -d "$HOME/.config/gtk-3.0" ]; then
    mkdir -p "$HOME/.config/gtk-3.0"
    cp /etc/skel/.config/gtk-3.0/settings.ini "$HOME/.config/gtk-3.0/" 2>/dev/null || true
fi

# Update icon cache
if [ -x /usr/bin/gtk-update-icon-cache ]; then
    gtk-update-icon-cache -f /usr/share/icons/MaruxOS 2>/dev/null || true
fi

# Set wallpaper
feh --bg-scale /usr/share/backgrounds/marux-desktop.png &

# Start tint2 panel
tint2 &

# Start system tray applets
sleep 1
nm-applet &
volumeicon &

# Start Openbox
exec openbox
XINITRC_EOF

chmod +x "$SQUASHFS_ROOT/etc/X11/xinit/xinitrc"

# Update icon cache script to run on boot
cat > "$SQUASHFS_ROOT/etc/profile.d/maruxos-icons.sh" << 'PROFILE_EOF'
#!/bin/sh
# Update icon cache on first login
if [ ! -f /tmp/.icon-cache-updated ]; then
    if [ -x /usr/bin/gtk-update-icon-cache ]; then
        gtk-update-icon-cache -f /usr/share/icons/MaruxOS 2>/dev/null || true
    fi
    touch /tmp/.icon-cache-updated
fi
PROFILE_EOF
chmod +x "$SQUASHFS_ROOT/etc/profile.d/maruxos-icons.sh"

echo ""
echo "=========================================="
echo "v19 Fix Applied Successfully!"
echo "=========================================="
echo ""
echo "Changes made:"
echo "  - Created MaruxOS icon theme"
echo "  - Copied custom icons:"
echo "    - WiFi: wifi_0~4.png -> network-wireless-*"
echo "    - Sound: sound_0~3.png -> audio-volume-*"
echo "    - Battery: bettery_*.png -> battery-*"
echo "    - Apps: terminal.png, marux-file-manager.png"
echo "  - Updated GTK settings to use MaruxOS theme"
echo "  - Updated xinitrc for icon theme"
echo ""
