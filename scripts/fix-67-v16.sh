#!/bin/bash
# 67-v16 - Firefox 브라우저 설치

set -e

rm -rf /home/administrator/MaruxOS/iso-modify
mkdir -p /home/administrator/MaruxOS/iso-modify/{iso,squashfs,newiso}
mount -o loop /home/administrator/MaruxOS/output/MaruxOS-1.0-67-v15.iso /home/administrator/MaruxOS/iso-modify/iso
cp -a /home/administrator/MaruxOS/iso-modify/iso/* /home/administrator/MaruxOS/iso-modify/newiso/
unsquashfs -d /home/administrator/MaruxOS/iso-modify/squashfs /home/administrator/MaruxOS/iso-modify/newiso/live/filesystem.squashfs

ROOTFS=/home/administrator/MaruxOS/iso-modify/squashfs

echo "=== Firefox 설치 ==="

# Firefox 디렉토리 복사
if [ -d /tmp/firefox ]; then
    echo "복사: /tmp/firefox -> $ROOTFS/opt/firefox"
    mkdir -p $ROOTFS/opt
    cp -a /tmp/firefox $ROOTFS/opt/
    chmod +x $ROOTFS/opt/firefox/firefox
    chmod +x $ROOTFS/opt/firefox/firefox-bin
else
    echo "ERROR: /tmp/firefox 디렉토리가 없습니다."
    echo "먼저 Firefox를 다운로드하세요:"
    echo "  wget 'https://download.mozilla.org/?product=firefox-latest-ssl&os=linux64&lang=en-US' -O /tmp/firefox.tar.bz2"
    echo "  cd /tmp && tar xJf firefox.tar.bz2"
    exit 1
fi

# Firefox 실행 스크립트
echo "=== Firefox 래퍼 스크립트 생성 ==="
cat > $ROOTFS/usr/bin/firefox << 'WRAPPER'
#!/bin/bash
export DISPLAY=${DISPLAY:-:0}
export MOZ_DISABLE_CONTENT_SANDBOX=1
export MOZ_DISABLE_GMP_SANDBOX=1
export MOZ_DISABLE_NPAPI_SANDBOX=1
export MOZ_DISABLE_GPU_SANDBOX=1

cd /opt/firefox
exec ./firefox "$@" 2>/dev/null
WRAPPER
chmod +x $ROOTFS/usr/bin/firefox

# Firefox .desktop 파일
echo "=== Firefox .desktop 생성 ==="
cat > $ROOTFS/usr/share/applications/firefox.desktop << 'EOF'
[Desktop Entry]
Name=Firefox
Exec=/usr/bin/firefox %u
Icon=/opt/firefox/browser/chrome/icons/default/default128.png
Type=Application
Categories=Network;WebBrowser;
Terminal=false
MimeType=text/html;text/xml;application/xhtml+xml;
EOF

# 기존 chromium.desktop을 firefox로 변경
cat > $ROOTFS/usr/share/applications/chromium.desktop << 'EOF'
[Desktop Entry]
Name=Web Browser
Exec=/usr/bin/firefox %u
Icon=/opt/firefox/browser/chrome/icons/default/default128.png
Type=Application
Categories=Network;WebBrowser;
Terminal=false
EOF

# 필요한 라이브러리 복사
echo "=== 필수 라이브러리 복사 ==="

# GTK3 관련
for lib in libgtk-3 libgdk-3 libatk-1.0 libatk-bridge-2.0 libpango libcairo libgdk_pixbuf; do
    for file in /usr/lib/x86_64-linux-gnu/${lib}*; do
        [ -f "$file" ] && cp -n "$file" "$ROOTFS/usr/lib/" 2>/dev/null || true
    done
done

# X11 관련
for lib in libX11 libXcomposite libXdamage libXext libXfixes libXrender libxcb libXt libXcursor libXi libXrandr; do
    for file in /usr/lib/x86_64-linux-gnu/${lib}*; do
        [ -f "$file" ] && cp -n "$file" "$ROOTFS/usr/lib/" 2>/dev/null || true
    done
done

# dbus, atspi
for lib in libdbus-1 libatspi libepoxy; do
    for file in /usr/lib/x86_64-linux-gnu/${lib}*; do
        [ -f "$file" ] && cp -n "$file" "$ROOTFS/usr/lib/" 2>/dev/null || true
    done
done

# squashfs 재생성
echo "=== squashfs 생성 ==="
rm -f /home/administrator/MaruxOS/iso-modify/newiso/live/filesystem.squashfs
mksquashfs $ROOTFS /home/administrator/MaruxOS/iso-modify/newiso/live/filesystem.squashfs -comp gzip -noappend

# ISO 생성
echo "=== ISO 생성 ==="
xorriso -as mkisofs \
    -isohybrid-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
    -c boot/boot.cat \
    -b boot/grub/bios.img \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -o /home/administrator/MaruxOS/output/MaruxOS-1.0-67-v16.iso \
    /home/administrator/MaruxOS/iso-modify/newiso

# 정리
umount /home/administrator/MaruxOS/iso-modify/iso 2>/dev/null || true
rm -rf /home/administrator/MaruxOS/iso-modify

echo "=== 완료 ==="
ls -lh /home/administrator/MaruxOS/output/MaruxOS-1.0-67-v16.iso
