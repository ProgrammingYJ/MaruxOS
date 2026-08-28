#!/bin/bash
# 67-v3 - GLib 라이브러리 수정

rm -rf /home/administrator/MaruxOS/iso-modify
mkdir -p /home/administrator/MaruxOS/iso-modify/{iso,squashfs,newiso}
mount -o loop /home/administrator/MaruxOS/output/MaruxOS-1.0-67-v2.iso /home/administrator/MaruxOS/iso-modify/iso
cp -a /home/administrator/MaruxOS/iso-modify/iso/* /home/administrator/MaruxOS/iso-modify/newiso/
unsquashfs -d /home/administrator/MaruxOS/iso-modify/squashfs /home/administrator/MaruxOS/iso-modify/newiso/live/filesystem.squashfs

ROOTFS=/home/administrator/MaruxOS/iso-modify/squashfs

# GLib 라이브러리 업데이트
echo "=== GLib 라이브러리 복사 ==="
cp -af /usr/lib/x86_64-linux-gnu/libglib-2.0.so* $ROOTFS/usr/lib/
cp -af /usr/lib/x86_64-linux-gnu/libgio-2.0.so* $ROOTFS/usr/lib/
cp -af /usr/lib/x86_64-linux-gnu/libgobject-2.0.so* $ROOTFS/usr/lib/
cp -af /usr/lib/x86_64-linux-gnu/libgmodule-2.0.so* $ROOTFS/usr/lib/
cp -af /usr/lib/x86_64-linux-gnu/libgthread-2.0.so* $ROOTFS/usr/lib/

# libfm 관련 라이브러리도 복사
cp -af /usr/lib/x86_64-linux-gnu/libfm*.so* $ROOTFS/usr/lib/
cp -af /usr/lib/x86_64-linux-gnu/libmenu-cache*.so* $ROOTFS/usr/lib/

echo "=== 확인 ==="
ls -la $ROOTFS/usr/lib/libglib*

# ISO 빌드
echo "=== squashfs 생성 ==="
rm -f /home/administrator/MaruxOS/iso-modify/newiso/live/filesystem.squashfs
mksquashfs $ROOTFS /home/administrator/MaruxOS/iso-modify/newiso/live/filesystem.squashfs -comp gzip -b 131072

umount /home/administrator/MaruxOS/iso-modify/iso 2>/dev/null

echo "=== ISO 생성 ==="
cd /home/administrator/MaruxOS/iso-modify/newiso
xorriso -as mkisofs -o /home/administrator/MaruxOS/output/MaruxOS-1.0-67-v3.iso \
    -r -V 'MARUXOS' -J -joliet-long \
    -isohybrid-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
    -partition_offset 16 -b boot/grub/bios.img -c boot.catalog \
    -no-emul-boot -boot-load-size 4 -boot-info-table .

echo "=== 완료 ==="
ls -lh /home/administrator/MaruxOS/output/MaruxOS-1.0-67-v3.iso
rm -rf /home/administrator/MaruxOS/iso-modify
