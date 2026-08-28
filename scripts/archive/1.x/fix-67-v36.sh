#!/bin/bash
# MaruxOS 67-v36 Fix Script
# v35 기반으로 설정 파일만 수정 (squashfs 새로 빌드하지 않음)

set -e

WORK_DIR="/home/administrator/MaruxOS/build"
SQUASHFS_ROOT="$WORK_DIR/rootfs-lfs"
CONFIG_DIR="/mnt/c/Users/Administrator/Desktop/MaruxOS/config"

echo "=========================================="
echo "MaruxOS 67-v36 Fix Script"
echo "v35 기반 - 설정 파일만 수정"
echo "=========================================="

# 1. 데스크톱 파일 복사
echo "[1/4] Copying desktop files..."
cp "$CONFIG_DIR/applications/firefox.desktop" "$SQUASHFS_ROOT/usr/share/applications/" 2>/dev/null || echo "  - firefox.desktop: skipped (file may not exist)"
cp "$CONFIG_DIR/applications/terminal.desktop" "$SQUASHFS_ROOT/usr/share/applications/" 2>/dev/null || echo "  - terminal.desktop: skipped"
cp "$CONFIG_DIR/applications/filemanager.desktop" "$SQUASHFS_ROOT/usr/share/applications/" 2>/dev/null || echo "  - filemanager.desktop: skipped"

# 2. tint2 설정 복사
echo "[2/4] Copying tint2 config..."
mkdir -p "$SQUASHFS_ROOT/etc/skel/.config/tint2"
cp "$CONFIG_DIR/tint2/tint2rc" "$SQUASHFS_ROOT/etc/skel/.config/tint2/tint2rc"

# 3. xinitrc 업데이트 (기존 네트워크 코드 유지하면서 로케일만 추가)
echo "[3/4] Updating xinitrc locale settings..."
# 기존 xinitrc 백업
cp "$SQUASHFS_ROOT/etc/X11/xinit/xinitrc" "$SQUASHFS_ROOT/etc/X11/xinit/xinitrc.backup"

# 로케일 설정만 추가 (기존 파일 맨 앞에)
TEMP_FILE=$(mktemp)
cat > "$TEMP_FILE" << 'LOCALE_EOF'
#!/bin/sh
# MaruxOS System xinitrc

# XDG Runtime Directory
export XDG_RUNTIME_DIR=/tmp/runtime-root
mkdir -p $XDG_RUNTIME_DIR
chmod 700 $XDG_RUNTIME_DIR

# Locale settings (Korean, Japanese, UTF-8)
export LANG=ko_KR.UTF-8
export LC_ALL=
export LC_CTYPE=ko_KR.UTF-8
export LC_MESSAGES=ko_KR.UTF-8
export LC_COLLATE=C

# Fallback to UTF-8 if Korean locale unavailable
if ! locale -a 2>/dev/null | grep -q "ko_KR"; then
    export LANG=C.UTF-8
    export LC_CTYPE=C.UTF-8
fi

# Input Method for Korean/Japanese
export GTK_IM_MODULE=ibus
export QT_IM_MODULE=ibus
export XMODIFIERS=@im=ibus

LOCALE_EOF

# 기존 xinitrc에서 shebang과 초기 설정 제외하고 나머지 추가
tail -n +2 "$SQUASHFS_ROOT/etc/X11/xinit/xinitrc.backup" | grep -v "^export LANG" | grep -v "^export LC_" | grep -v "XDG_RUNTIME" | grep -v "mkdir -p \$XDG" | grep -v "chmod 700 \$XDG" >> "$TEMP_FILE"

mv "$TEMP_FILE" "$SQUASHFS_ROOT/etc/X11/xinit/xinitrc"
chmod 755 "$SQUASHFS_ROOT/etc/X11/xinit/xinitrc"

# 4. 권한 설정
echo "[4/4] Setting permissions..."
chmod 644 "$SQUASHFS_ROOT/usr/share/applications/firefox.desktop" 2>/dev/null || true
chmod 644 "$SQUASHFS_ROOT/usr/share/applications/terminal.desktop" 2>/dev/null || true
chmod 644 "$SQUASHFS_ROOT/usr/share/applications/filemanager.desktop" 2>/dev/null || true
chmod 644 "$SQUASHFS_ROOT/etc/skel/.config/tint2/tint2rc"

echo ""
echo "=========================================="
echo "Fix applied!"
echo "Now run the squashfs rebuild manually:"
echo ""
echo "cd $WORK_DIR"
echo "rm -f iso-build/live/filesystem.squashfs"
echo "mksquashfs rootfs-lfs iso-build/live/filesystem.squashfs -comp gzip -e boot -noappend"
echo "grub-mkrescue -o /mnt/c/Users/Administrator/Desktop/MaruxOS/iso/MaruxOS-1.0-67-v36.iso iso-build"
echo "=========================================="
