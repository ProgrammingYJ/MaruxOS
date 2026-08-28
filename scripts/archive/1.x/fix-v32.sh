#!/bin/bash
ROOTFS=/home/administrator/MaruxOS/iso-modify/squashfs

# xterm 복사
echo "=== xterm 복사 ==="
cp /usr/bin/xterm $ROOTFS/usr/bin/
ldd /usr/bin/xterm 2>/dev/null | grep "=>" | awk '{print $3}' | while read lib; do
    if [ -f "$lib" ]; then
        cp -n "$lib" "$ROOTFS/usr/lib/" 2>/dev/null
    fi
done

# menu.xml 수정
cat > $ROOTFS/etc/xdg/openbox/menu.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_menu xmlns="http://openbox.org/3.4/menu">
  <menu id="root-menu" label="MaruxOS">
    <item label="Terminal"><action name="Execute"><command>xterm -bg black -fg white</command></action></item>
    <item label="File Manager"><action name="Execute"><command>pcmanfm</command></action></item>
    <separator/>
    <item label="Reconfigure"><action name="Reconfigure"/></item>
    <item label="Log Out"><action name="Exit"/></item>
  </menu>
</openbox_menu>
EOF

# xinitrc 수정
cat > $ROOTFS/etc/X11/xinit/xinitrc << 'EOF'
#!/bin/sh
export XDG_RUNTIME_DIR=/tmp/runtime-root
mkdir -p $XDG_RUNTIME_DIR
chmod 700 $XDG_RUNTIME_DIR
export DISPLAY=:0

# 배경화면
/usr/bin/feh --bg-scale /usr/share/backgrounds/marux-desktop.png 2>/dev/null &

# 바탕화면 아이콘
sleep 0.5
/usr/bin/pcmanfm --desktop 2>/dev/null &

# tint2 패널
sleep 1
/usr/bin/tint2 2>/dev/null &

# Openbox
exec /usr/bin/openbox
EOF
chmod +x $ROOTFS/etc/X11/xinit/xinitrc

# ISO 빌드
echo "=== squashfs 생성 ==="
rm -f /home/administrator/MaruxOS/iso-modify/newiso/live/filesystem.squashfs
mksquashfs $ROOTFS /home/administrator/MaruxOS/iso-modify/newiso/live/filesystem.squashfs -comp gzip -b 131072

umount /home/administrator/MaruxOS/iso-modify/iso 2>/dev/null

echo "=== ISO 생성 ==="
cd /home/administrator/MaruxOS/iso-modify/newiso
xorriso -as mkisofs -o /home/administrator/MaruxOS/output/MaruxOS-1.0-Phoenix-v32.iso \
    -r -V 'MARUXOS' -J -joliet-long \
    -isohybrid-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
    -partition_offset 16 -b boot/grub/bios.img -c boot.catalog \
    -no-emul-boot -boot-load-size 4 -boot-info-table .

echo "=== 완료 ==="
ls -lh /home/administrator/MaruxOS/output/MaruxOS-1.0-Phoenix-v32.iso
rm -rf /home/administrator/MaruxOS/iso-modify
