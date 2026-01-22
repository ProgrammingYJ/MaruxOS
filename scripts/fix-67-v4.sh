#!/bin/bash
# 67-v4 - pcmanfm 완전 재설치 (모든 의존성 포함)

rm -rf /home/administrator/MaruxOS/iso-modify
mkdir -p /home/administrator/MaruxOS/iso-modify/{iso,squashfs,newiso}
mount -o loop /home/administrator/MaruxOS/output/MaruxOS-1.0-67-v3.iso /home/administrator/MaruxOS/iso-modify/iso
cp -a /home/administrator/MaruxOS/iso-modify/iso/* /home/administrator/MaruxOS/iso-modify/newiso/
unsquashfs -d /home/administrator/MaruxOS/iso-modify/squashfs /home/administrator/MaruxOS/iso-modify/newiso/live/filesystem.squashfs

ROOTFS=/home/administrator/MaruxOS/iso-modify/squashfs

# 기존 libfm, pcmanfm 관련 파일 제거
echo "=== 기존 파일 제거 ==="
rm -f $ROOTFS/usr/lib/libfm*.so*
rm -f $ROOTFS/usr/lib/libglib*.so*
rm -f $ROOTFS/usr/lib/libgio*.so*
rm -f $ROOTFS/usr/lib/libgobject*.so*
rm -f $ROOTFS/usr/lib/libgmodule*.so*
rm -f $ROOTFS/usr/bin/pcmanfm

# pcmanfm 및 모든 의존성 복사
echo "=== pcmanfm 의존성 전체 복사 ==="
cp -f /usr/bin/pcmanfm $ROOTFS/usr/bin/

# ldd로 모든 의존성 찾아서 복사
copy_deps() {
    local binary=$1
    echo "Copying dependencies for: $binary"
    ldd "$binary" 2>/dev/null | grep "=>" | awk '{print $3}' | while read lib; do
        if [ -f "$lib" ]; then
            cp -fL "$lib" "$ROOTFS/usr/lib/" 2>/dev/null
            echo "  Copied: $lib"
        fi
    done
}

# pcmanfm 의존성
copy_deps /usr/bin/pcmanfm

# libfm 의존성
for libfm in /usr/lib/x86_64-linux-gnu/libfm*.so*; do
    if [ -f "$libfm" ]; then
        cp -fL "$libfm" "$ROOTFS/usr/lib/"
        copy_deps "$libfm"
    fi
done

# libmenu-cache 의존성
for libmc in /usr/lib/x86_64-linux-gnu/libmenu-cache*.so*; do
    if [ -f "$libmc" ]; then
        cp -fL "$libmc" "$ROOTFS/usr/lib/"
        copy_deps "$libmc"
    fi
done

# GLib 전체 복사 (심볼릭 링크 해결)
echo "=== GLib 전체 복사 ==="
for glib in libglib-2.0 libgio-2.0 libgobject-2.0 libgmodule-2.0 libgthread-2.0; do
    for f in /usr/lib/x86_64-linux-gnu/${glib}.so*; do
        if [ -e "$f" ]; then
            cp -fL "$f" "$ROOTFS/usr/lib/"
        fi
    done
done

# 추가 의존성 (pcre2, ffi 등)
echo "=== 추가 의존성 ==="
for lib in libpcre2-8 libffi libselinux libmount libblkid; do
    for f in /usr/lib/x86_64-linux-gnu/${lib}.so*; do
        if [ -e "$f" ]; then
            cp -fL "$f" "$ROOTFS/usr/lib/"
        fi
    done
done

# gio 모듈 복사
echo "=== GIO 모듈 복사 ==="
mkdir -p $ROOTFS/usr/lib/gio/modules
if [ -d /usr/lib/x86_64-linux-gnu/gio/modules ]; then
    cp -rL /usr/lib/x86_64-linux-gnu/gio/modules/* $ROOTFS/usr/lib/gio/modules/ 2>/dev/null
fi

# glib 스키마 복사
echo "=== GLib 스키마 복사 ==="
mkdir -p $ROOTFS/usr/share/glib-2.0/schemas
cp /usr/share/glib-2.0/schemas/*.xml $ROOTFS/usr/share/glib-2.0/schemas/ 2>/dev/null
cp /usr/share/glib-2.0/schemas/gschemas.compiled $ROOTFS/usr/share/glib-2.0/schemas/ 2>/dev/null

# ldconfig 실행을 위한 설정
echo "/usr/lib" > $ROOTFS/etc/ld.so.conf.d/usrlib.conf

echo "=== 복사된 라이브러리 확인 ==="
ls -la $ROOTFS/usr/lib/libfm* $ROOTFS/usr/lib/libglib* 2>/dev/null | head -20

# ISO 빌드
echo "=== squashfs 생성 ==="
rm -f /home/administrator/MaruxOS/iso-modify/newiso/live/filesystem.squashfs
mksquashfs $ROOTFS /home/administrator/MaruxOS/iso-modify/newiso/live/filesystem.squashfs -comp gzip -b 131072

umount /home/administrator/MaruxOS/iso-modify/iso 2>/dev/null

echo "=== ISO 생성 ==="
cd /home/administrator/MaruxOS/iso-modify/newiso
xorriso -as mkisofs -o /home/administrator/MaruxOS/output/MaruxOS-1.0-67-v4.iso \
    -r -V 'MARUXOS' -J -joliet-long \
    -isohybrid-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
    -partition_offset 16 -b boot/grub/bios.img -c boot.catalog \
    -no-emul-boot -boot-load-size 4 -boot-info-table .

echo "=== 완료 ==="
ls -lh /home/administrator/MaruxOS/output/MaruxOS-1.0-67-v4.iso
rm -rf /home/administrator/MaruxOS/iso-modify
