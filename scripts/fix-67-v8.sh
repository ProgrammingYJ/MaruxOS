#!/bin/bash
# 67-v8 - mc 파일 관리자로 교체 (xfe 제거)

rm -rf /home/administrator/MaruxOS/iso-modify
mkdir -p /home/administrator/MaruxOS/iso-modify/{iso,squashfs,newiso}
mount -o loop /home/administrator/MaruxOS/output/MaruxOS-1.0-67-v5.iso /home/administrator/MaruxOS/iso-modify/iso
cp -a /home/administrator/MaruxOS/iso-modify/iso/* /home/administrator/MaruxOS/iso-modify/newiso/
unsquashfs -d /home/administrator/MaruxOS/iso-modify/squashfs /home/administrator/MaruxOS/iso-modify/newiso/live/filesystem.squashfs

ROOTFS=/home/administrator/MaruxOS/iso-modify/squashfs

# mc 바이너리 복사
echo "=== mc 복사 ==="
cp /usr/bin/mc $ROOTFS/usr/bin/
cp /usr/bin/mcedit $ROOTFS/usr/bin/ 2>/dev/null
cp /usr/bin/mcview $ROOTFS/usr/bin/ 2>/dev/null

# mc 의존성 복사 (libc, libm 제외)
echo "=== mc 의존성 복사 ==="
ldd /usr/bin/mc 2>/dev/null | grep "=>" | awk '{print $3}' | while read lib; do
    if [ -f "$lib" ]; then
        basename_lib=$(basename "$lib")
        if [[ ! "$basename_lib" =~ ^(libc\.so|libm\.so|libpthread|libdl\.so|librt\.so) ]]; then
            cp -n "$lib" "$ROOTFS/usr/lib/" 2>/dev/null
            echo "  Copied: $lib"
        fi
    fi
done

# mc 데이터 파일 복사
echo "=== mc 데이터 복사 ==="
mkdir -p $ROOTFS/usr/share/mc
cp -r /usr/share/mc/* $ROOTFS/usr/share/mc/

# 메뉴 업데이트
echo "=== 메뉴 업데이트 ==="
cat > $ROOTFS/etc/xdg/openbox/menu.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_menu xmlns="http://openbox.org/3.4/menu">
  <menu id="root-menu" label="MaruxOS">
    <item label="Terminal"><action name="Execute"><command>xterm -bg black -fg white</command></action></item>
    <item label="File Manager"><action name="Execute"><command>xterm -bg black -fg white -e mc</command></action></item>
    <separator/>
    <item label="Reconfigure"><action name="Reconfigure"/></item>
    <item label="Log Out"><action name="Exit"/></item>
  </menu>
</openbox_menu>
EOF

# tint2 설정
cat > $ROOTFS/etc/xdg/tint2/tint2rc << 'EOF'
panel_items = LTSC
panel_size = 100% 32
panel_position = bottom center horizontal
panel_background_id = 1
panel_padding = 4 0 4

rounded = 0
border_width = 0
background_color = #2d2d2d 90
border_color = #000000 0

rounded = 0
border_width = 0
background_color = #3d3d3d 100
border_color = #000000 0

launcher_icon_size = 24
launcher_padding = 2 2 2
launcher_background_id = 0
launcher_item_app = /usr/share/applications/xterm.desktop
launcher_item_app = /usr/share/applications/mc.desktop

taskbar_mode = single_desktop
taskbar_padding = 2 0 2
taskbar_background_id = 0

task_text = 1
task_icon = 1
task_centered = 0
task_maximum_size = 200 32
task_padding = 4 2 4
task_font = Sans 10
task_font_color = #ffffff 100
task_background_id = 0
task_active_background_id = 2

systray_padding = 2 2 2
systray_background_id = 0

time1_format = %H:%M
time1_font = Sans Bold 10
clock_font_color = #ffffff 100
clock_padding = 6 0
clock_background_id = 0
EOF

# .desktop 파일
mkdir -p $ROOTFS/usr/share/applications
cat > $ROOTFS/usr/share/applications/xterm.desktop << 'EOF'
[Desktop Entry]
Name=Terminal
Exec=xterm -bg black -fg white
Icon=utilities-terminal
Type=Application
Categories=System;TerminalEmulator;
EOF

cat > $ROOTFS/usr/share/applications/mc.desktop << 'EOF'
[Desktop Entry]
Name=File Manager
Exec=xterm -bg black -fg white -e mc
Icon=system-file-manager
Type=Application
Categories=System;FileManager;
EOF

echo "=== squashfs 생성 ==="
rm -f /home/administrator/MaruxOS/iso-modify/newiso/live/filesystem.squashfs
mksquashfs $ROOTFS /home/administrator/MaruxOS/iso-modify/newiso/live/filesystem.squashfs -comp gzip -b 131072

umount /home/administrator/MaruxOS/iso-modify/iso 2>/dev/null

echo "=== ISO 생성 ==="
cd /home/administrator/MaruxOS/iso-modify/newiso
xorriso -as mkisofs -o /home/administrator/MaruxOS/output/MaruxOS-1.0-67-v8.iso \
    -r -V 'MARUXOS' -J -joliet-long \
    -isohybrid-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
    -partition_offset 16 -b boot/grub/bios.img -c boot.catalog \
    -no-emul-boot -boot-load-size 4 -boot-info-table .

echo "=== 완료 ==="
ls -lh /home/administrator/MaruxOS/output/MaruxOS-1.0-67-v8.iso
rm -rf /home/administrator/MaruxOS/iso-modify
