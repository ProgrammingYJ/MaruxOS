#!/bin/bash
# Copy battery icons to MaruxOS theme

DESIGN="/mnt/c/Users/Administrator/Desktop/MaruxOS/MaruxOS 디자인"
ICONS24="/home/administrator/MaruxOS/v18-restore/squashfs-root/usr/share/icons/MaruxOS/24x24/status"
ICONS32="/home/administrator/MaruxOS/v18-restore/squashfs-root/usr/share/icons/MaruxOS/32x32/status"
ICONS48="/home/administrator/MaruxOS/v18-restore/squashfs-root/usr/share/icons/MaruxOS/48x48/status"

echo "Copying battery icons..."

# 24x24
cp "$DESIGN/bettery_100.png" "$ICONS24/battery-full.png"
cp "$DESIGN/bettery_75.png" "$ICONS24/battery-good.png"
cp "$DESIGN/bettery_50.png" "$ICONS24/battery-low.png"
cp "$DESIGN/bettery_25.png" "$ICONS24/battery-caution.png"
cp "$DESIGN/betteryLow.png" "$ICONS24/battery-empty.png"
cp "$DESIGN/betteryCharge.png" "$ICONS24/battery-charging.png"

# 32x32
cp "$DESIGN/bettery_100.png" "$ICONS32/battery-full.png"
cp "$DESIGN/bettery_75.png" "$ICONS32/battery-good.png"
cp "$DESIGN/bettery_50.png" "$ICONS32/battery-low.png"
cp "$DESIGN/bettery_25.png" "$ICONS32/battery-caution.png"
cp "$DESIGN/betteryLow.png" "$ICONS32/battery-empty.png"
cp "$DESIGN/betteryCharge.png" "$ICONS32/battery-charging.png"

# 48x48
cp "$DESIGN/bettery_100.png" "$ICONS48/battery-full.png"
cp "$DESIGN/bettery_75.png" "$ICONS48/battery-good.png"
cp "$DESIGN/bettery_50.png" "$ICONS48/battery-low.png"
cp "$DESIGN/bettery_25.png" "$ICONS48/battery-caution.png"
cp "$DESIGN/betteryLow.png" "$ICONS48/battery-empty.png"
cp "$DESIGN/betteryCharge.png" "$ICONS48/battery-charging.png"

echo "Done! Battery icons:"
ls "$ICONS24" | grep battery
