#!/bin/bash
# Add Korean locale support to MaruxOS

set -e

ROOTFS="/home/administrator/MaruxOS/build/rootfs-lfs"

echo "=========================================="
echo "MaruxOS - Adding Korean Locale Support"
echo "=========================================="

# Check if rootfs exists
if [ ! -d "$ROOTFS" ]; then
    echo "Error: rootfs not found at $ROOTFS"
    exit 1
fi

# Create locale.gen if it doesn't exist
echo "[1/4] Creating locale.gen..."
cat > "$ROOTFS/etc/locale.gen" << 'LOCALE_EOF'
# MaruxOS Locale Configuration
en_US.UTF-8 UTF-8
ko_KR.UTF-8 UTF-8
ja_JP.UTF-8 UTF-8
zh_CN.UTF-8 UTF-8
LOCALE_EOF

# Create locale directories
echo "[2/4] Creating locale directories..."
mkdir -p "$ROOTFS/usr/share/locale/ko/LC_MESSAGES"
mkdir -p "$ROOTFS/usr/share/locale/ja/LC_MESSAGES"
mkdir -p "$ROOTFS/usr/share/locale/zh_CN/LC_MESSAGES"
mkdir -p "$ROOTFS/usr/lib/locale"

# Generate locales (if localedef is available in rootfs)
echo "[3/4] Generating locales..."
if [ -x "$ROOTFS/usr/bin/localedef" ]; then
    chroot "$ROOTFS" /bin/bash -c "localedef -i ko_KR -f UTF-8 ko_KR.UTF-8" 2>/dev/null || echo "  - localedef for ko_KR failed (may not be critical)"
    chroot "$ROOTFS" /bin/bash -c "localedef -i ja_JP -f UTF-8 ja_JP.UTF-8" 2>/dev/null || echo "  - localedef for ja_JP failed (may not be critical)"
    chroot "$ROOTFS" /bin/bash -c "localedef -i en_US -f UTF-8 en_US.UTF-8" 2>/dev/null || echo "  - localedef for en_US failed (may not be critical)"
else
    echo "  - localedef not found, skipping locale generation"
    echo "  - UTF-8 support will still work via environment variables"
fi

# Set default locale
echo "[4/4] Setting default locale..."
cat > "$ROOTFS/etc/locale.conf" << 'LOCALE_CONF_EOF'
LANG=ko_KR.UTF-8
LC_CTYPE=ko_KR.UTF-8
LC_MESSAGES=en_US.UTF-8
LC_COLLATE=C
LOCALE_CONF_EOF

echo ""
echo "=========================================="
echo "Korean locale support added!"
echo ""
echo "Configured locales:"
echo "  - ko_KR.UTF-8 (Korean)"
echo "  - ja_JP.UTF-8 (Japanese)"
echo "  - en_US.UTF-8 (English)"
echo "  - zh_CN.UTF-8 (Chinese)"
echo ""
echo "Note: Korean fonts (Noto Sans CJK) may need"
echo "      to be added separately for full support"
echo "=========================================="
