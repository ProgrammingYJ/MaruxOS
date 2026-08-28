#!/bin/bash
# v33 - Imlib2 로더 추가

rm -rf /home/administrator/MaruxOS/iso-modify
mkdir -p /home/administrator/MaruxOS/iso-modify/{iso,squashfs,newiso}
mount -o loop /home/administrator/MaruxOS/output/MaruxOS-1.0-Phoenix-v32.iso /home/administrator/MaruxOS/iso-modify/iso
cp -a /home/administrator/MaruxOS/iso-modify/iso/* /home/administrator/MaruxOS/iso-modify/newiso/
unsquashfs -d /home/administrator/MaruxOS/iso-modify/squashfs /home/administrator/MaruxOS/iso-modify/newiso/live/filesystem.squashfs

ROOTFS=/home/administrator/MaruxOS/iso-modify/squashfs

# Imlib2 로더 복사
echo "=== Imlib2 로더 복사 ==="
mkdir -p $ROOTFS/usr/lib/imlib2/loaders
cp /usr/lib/x86_64-linux-gnu/imlib2/loaders/*.so $ROOTFS/usr/lib/imlib2/loaders/

# libImlib2 라이브러리도 복사
cp /usr/lib/x86_64-linux-gnu/libImlib2.so* $ROOTFS/usr/lib/

# PNG/JPEG 관련 라이브러리 확인 및 복사
for lib in libpng libpng16 libjpeg; do
    for f in /usr/lib/x86_64-linux-gnu/${lib}*.so*; do
        [ -f "$f" ] && cp -n "$f" $ROOTFS/usr/lib/ 2>/dev/null
    done
done

echo "=== 로더 확인 ==="
ls $ROOTFS/usr/lib/imlib2/loaders/

# ISO 빌드
rm -f /home/administrator/MaruxOS/iso-modify/newiso/live/filesystem.squashfs
mksquashfs $ROOTFS /home/administrator/MaruxOS/iso-modify/newiso/live/filesystem.squashfs -comp gzip -b 131072

umount /home/administrator/MaruxOS/iso-modify/iso 2>/dev/null
cd /home/administrator/MaruxOS/iso-modify/newiso
xorriso -as mkisofs -o /home/administrator/MaruxOS/output/MaruxOS-1.0-Phoenix-v33.iso \
    -r -V 'MARUXOS' -J -joliet-long \
    -isohybrid-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
    -partition_offset 16 -b boot/grub/bios.img -c boot.catalog \
    -no-emul-boot -boot-load-size 4 -boot-info-table .

echo "=== 완료 ==="
ls -lh /home/administrator/MaruxOS/output/MaruxOS-1.0-Phoenix-v33.iso
rm -rf /home/administrator/MaruxOS/iso-modify
