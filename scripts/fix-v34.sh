#!/bin/bash
# v34 - Imlib2 로더 경로 수정 + 코드네임 67

rm -rf /home/administrator/MaruxOS/iso-modify
mkdir -p /home/administrator/MaruxOS/iso-modify/{iso,squashfs,newiso}
mount -o loop /home/administrator/MaruxOS/output/MaruxOS-1.0-Phoenix-v33.iso /home/administrator/MaruxOS/iso-modify/iso
cp -a /home/administrator/MaruxOS/iso-modify/iso/* /home/administrator/MaruxOS/iso-modify/newiso/
unsquashfs -d /home/administrator/MaruxOS/iso-modify/squashfs /home/administrator/MaruxOS/iso-modify/newiso/live/filesystem.squashfs

ROOTFS=/home/administrator/MaruxOS/iso-modify/squashfs

# 1. Imlib2 로더 심볼릭 링크 생성
echo "=== Imlib2 로더 경로 수정 ==="
mkdir -p $ROOTFS/usr/lib/x86_64-linux-gnu/imlib2
ln -sf /usr/lib/imlib2/loaders $ROOTFS/usr/lib/x86_64-linux-gnu/imlib2/loaders

# 확인
ls -la $ROOTFS/usr/lib/x86_64-linux-gnu/imlib2/

# 2. 코드네임 67로 변경
echo "=== 코드네임 67로 변경 ==="
cat > $ROOTFS/etc/maruxos-release << 'EOF'
MaruxOS 1.0 "67"
BUILD_DATE=2025-12-19
CODENAME=67
VERSION=1.0
EOF

cat > $ROOTFS/etc/os-release << 'EOF'
NAME="MaruxOS"
VERSION="1.0 (67)"
ID=maruxos
VERSION_ID=1.0
PRETTY_NAME="MaruxOS 1.0 (67)"
HOME_URL="https://maruxos.org"
EOF

# 3. ISO 빌드
echo "=== squashfs 생성 ==="
rm -f /home/administrator/MaruxOS/iso-modify/newiso/live/filesystem.squashfs
mksquashfs $ROOTFS /home/administrator/MaruxOS/iso-modify/newiso/live/filesystem.squashfs -comp gzip -b 131072

umount /home/administrator/MaruxOS/iso-modify/iso 2>/dev/null

echo "=== ISO 생성 (67-v1) ==="
cd /home/administrator/MaruxOS/iso-modify/newiso
xorriso -as mkisofs -o /home/administrator/MaruxOS/output/MaruxOS-1.0-67-v1.iso \
    -r -V 'MARUXOS' -J -joliet-long \
    -isohybrid-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
    -partition_offset 16 -b boot/grub/bios.img -c boot.catalog \
    -no-emul-boot -boot-load-size 4 -boot-info-table .

echo "=== 완료 ==="
ls -lh /home/administrator/MaruxOS/output/MaruxOS-1.0-67-v1.iso
rm -rf /home/administrator/MaruxOS/iso-modify
