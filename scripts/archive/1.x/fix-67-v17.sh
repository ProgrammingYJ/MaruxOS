#!/bin/bash
# 67-v17 - Firefox 디버그 및 의존성 추가

set -e

rm -rf /home/administrator/MaruxOS/iso-modify
mkdir -p /home/administrator/MaruxOS/iso-modify/{iso,squashfs,newiso}
mount -o loop /home/administrator/MaruxOS/output/MaruxOS-1.0-67-v16.iso /home/administrator/MaruxOS/iso-modify/iso
cp -a /home/administrator/MaruxOS/iso-modify/iso/* /home/administrator/MaruxOS/iso-modify/newiso/
unsquashfs -d /home/administrator/MaruxOS/iso-modify/squashfs /home/administrator/MaruxOS/iso-modify/newiso/live/filesystem.squashfs

ROOTFS=/home/administrator/MaruxOS/iso-modify/squashfs

echo "=== Firefox 디버그 래퍼 스크립트 ==="

# Firefox 래퍼 - 오류 메시지 표시
cat > $ROOTFS/usr/bin/firefox << 'WRAPPER'
#!/bin/bash
export DISPLAY=${DISPLAY:-:0}
export MOZ_DISABLE_CONTENT_SANDBOX=1
export MOZ_DISABLE_GMP_SANDBOX=1
export MOZ_DISABLE_NPAPI_SANDBOX=1
export MOZ_DISABLE_GPU_SANDBOX=1
export MOZ_DISABLE_RDD_SANDBOX=1
export MOZ_DISABLE_SOCKET_PROCESS_SANDBOX=1

# 라이브러리 경로 추가
export LD_LIBRARY_PATH=/opt/firefox:/usr/lib:$LD_LIBRARY_PATH

cd /opt/firefox

# 오류를 xterm에 표시
if ! ./firefox-bin "$@" 2>&1; then
    echo ""
    echo "=== Firefox Error ==="
    echo "Press Enter to close..."
    read
fi
WRAPPER
chmod +x $ROOTFS/usr/bin/firefox

# Firefox .desktop - 터미널에서 오류 확인 가능하도록
cat > $ROOTFS/usr/share/applications/chromium.desktop << 'EOF'
[Desktop Entry]
Name=Web Browser
Exec=xterm -hold -e /usr/bin/firefox
Icon=/opt/firefox/browser/chrome/icons/default/default128.png
Type=Application
Categories=Network;WebBrowser;
Terminal=false
EOF

echo "=== 추가 라이브러리 복사 ==="

# Firefox가 필요로 하는 주요 라이브러리들
LIBS=(
    # GTK3
    "libgtk-3.so*"
    "libgdk-3.so*"
    "libgdk_pixbuf-2.0.so*"
    # Pango
    "libpango*"
    "libharfbuzz*"
    # Cairo
    "libcairo*"
    "libpixman*"
    # GLib
    "libglib-2.0.so*"
    "libgobject-2.0.so*"
    "libgio-2.0.so*"
    "libgmodule-2.0.so*"
    "libgthread-2.0.so*"
    # ATK
    "libatk-1.0.so*"
    "libatk-bridge-2.0.so*"
    "libatspi.so*"
    # X11
    "libX11.so*"
    "libX11-xcb.so*"
    "libXcomposite.so*"
    "libXcursor.so*"
    "libXdamage.so*"
    "libXext.so*"
    "libXfixes.so*"
    "libXi.so*"
    "libXinerama.so*"
    "libXrandr.so*"
    "libXrender.so*"
    "libXt.so*"
    "libxcb*.so*"
    "libxkbcommon.so*"
    # DBus
    "libdbus-1.so*"
    "libdbus-glib-1.so*"
    # 기타
    "libfontconfig.so*"
    "libfreetype.so*"
    "libffi.so*"
    "libexpat.so*"
    "libz.so*"
    "libbz2.so*"
    "liblzma.so*"
    "libpng*.so*"
    "libjpeg.so*"
    "libdrm.so*"
    "libgbm.so*"
    "libEGL.so*"
    "libGL.so*"
    "libGLX.so*"
    "libGLdispatch.so*"
    "libasound.so*"
    "libpulse*.so*"
    "libepoxy.so*"
    "libwayland*.so*"
    # PCRE
    "libpcre*.so*"
)

for pattern in "${LIBS[@]}"; do
    for lib in /usr/lib/x86_64-linux-gnu/$pattern; do
        if [ -f "$lib" ]; then
            cp -n "$lib" "$ROOTFS/usr/lib/" 2>/dev/null || true
        fi
    done
done

# GIO 모듈
if [ -d /usr/lib/x86_64-linux-gnu/gio ]; then
    mkdir -p $ROOTFS/usr/lib/gio
    cp -a /usr/lib/x86_64-linux-gnu/gio/* $ROOTFS/usr/lib/gio/ 2>/dev/null || true
fi

# GTK 모듈
if [ -d /usr/lib/x86_64-linux-gnu/gtk-3.0 ]; then
    mkdir -p $ROOTFS/usr/lib/gtk-3.0
    cp -a /usr/lib/x86_64-linux-gnu/gtk-3.0/* $ROOTFS/usr/lib/gtk-3.0/ 2>/dev/null || true
fi

# GDK pixbuf loaders
if [ -d /usr/lib/x86_64-linux-gnu/gdk-pixbuf-2.0 ]; then
    mkdir -p $ROOTFS/usr/lib/gdk-pixbuf-2.0
    cp -a /usr/lib/x86_64-linux-gnu/gdk-pixbuf-2.0/* $ROOTFS/usr/lib/gdk-pixbuf-2.0/ 2>/dev/null || true
fi

echo "=== squashfs 생성 ==="
rm -f /home/administrator/MaruxOS/iso-modify/newiso/live/filesystem.squashfs
mksquashfs $ROOTFS /home/administrator/MaruxOS/iso-modify/newiso/live/filesystem.squashfs -comp gzip -noappend

echo "=== ISO 생성 ==="
xorriso -as mkisofs \
    -isohybrid-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
    -c boot/boot.cat \
    -b boot/grub/bios.img \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -o /home/administrator/MaruxOS/output/MaruxOS-1.0-67-v17.iso \
    /home/administrator/MaruxOS/iso-modify/newiso

umount /home/administrator/MaruxOS/iso-modify/iso 2>/dev/null || true
rm -rf /home/administrator/MaruxOS/iso-modify

echo "=== 완료 ==="
ls -lh /home/administrator/MaruxOS/output/MaruxOS-1.0-67-v17.iso
