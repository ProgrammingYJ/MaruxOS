#!/bin/bash
# 67-v7 - xfe root 경고 제거 + 아이콘 수정

rm -rf /home/administrator/MaruxOS/iso-modify
mkdir -p /home/administrator/MaruxOS/iso-modify/{iso,squashfs,newiso}
mount -o loop /home/administrator/MaruxOS/output/MaruxOS-1.0-67-v6.iso /home/administrator/MaruxOS/iso-modify/iso
cp -a /home/administrator/MaruxOS/iso-modify/iso/* /home/administrator/MaruxOS/iso-modify/newiso/
unsquashfs -d /home/administrator/MaruxOS/iso-modify/squashfs /home/administrator/MaruxOS/iso-modify/newiso/live/filesystem.squashfs

ROOTFS=/home/administrator/MaruxOS/iso-modify/squashfs

# xfe root 경고 무시하는 래퍼 스크립트
echo "=== xfe 래퍼 스크립트 생성 ==="
mv $ROOTFS/usr/bin/xfe $ROOTFS/usr/bin/xfe.bin
cat > $ROOTFS/usr/bin/xfe << 'EOF'
#!/bin/sh
exec /usr/bin/xfe.bin --no-warnings "$@" 2>/dev/null
EOF
chmod +x $ROOTFS/usr/bin/xfe

# 아이콘 테마 복사 (Adwaita)
echo "=== 아이콘 테마 복사 ==="
mkdir -p $ROOTFS/usr/share/icons

# hicolor 기본 아이콘
if [ -d /usr/share/icons/hicolor ]; then
    cp -r /usr/share/icons/hicolor $ROOTFS/usr/share/icons/
fi

# Adwaita 아이콘 테마 (주요 아이콘만)
mkdir -p $ROOTFS/usr/share/icons/Adwaita/16x16/{apps,places,devices,actions}
mkdir -p $ROOTFS/usr/share/icons/Adwaita/24x24/{apps,places,devices,actions}
mkdir -p $ROOTFS/usr/share/icons/Adwaita/scalable/{apps,places,devices,actions}

# 주요 아이콘 복사
for size in 16x16 24x24 scalable; do
    if [ -d /usr/share/icons/Adwaita/$size ]; then
        cp -r /usr/share/icons/Adwaita/$size/* $ROOTFS/usr/share/icons/Adwaita/$size/ 2>/dev/null
    fi
done

# index.theme
if [ -f /usr/share/icons/Adwaita/index.theme ]; then
    cp /usr/share/icons/Adwaita/index.theme $ROOTFS/usr/share/icons/Adwaita/
fi

# GTK 아이콘 테마 설정
mkdir -p $ROOTFS/etc/gtk-3.0
cat > $ROOTFS/etc/gtk-3.0/settings.ini << 'EOF'
[Settings]
gtk-icon-theme-name = Adwaita
gtk-theme-name = Adwaita
EOF

# xfe 설정 (root 경고 비활성화)
mkdir -p $ROOTFS/root/.config/xfe
cat > $ROOTFS/root/.config/xfe/xferc << 'EOF'
[OPTIONS]
root_warn=0
confirm_quit=0
file_tooltips=1
[SETTINGS]
iconpath=/usr/share/icons/Adwaita
EOF

# tint2 런처 아이콘 직접 지정
echo "=== tint2 설정 업데이트 ==="
cat > $ROOTFS/etc/xdg/tint2/tint2rc << 'EOF'
panel_items = LTSC
panel_size = 100% 32
panel_position = bottom center horizontal
panel_background_id = 1
panel_padding = 4 0 4

# Backgrounds
rounded = 0
border_width = 0
background_color = #2d2d2d 90
border_color = #000000 0

rounded = 0
border_width = 0
background_color = #3d3d3d 100
border_color = #000000 0

# Launcher
launcher_icon_size = 24
launcher_padding = 2 2 2
launcher_background_id = 0
launcher_icon_theme = Adwaita
launcher_item_app = /usr/share/applications/xterm.desktop
launcher_item_app = /usr/share/applications/xfe.desktop

# Taskbar
taskbar_mode = single_desktop
taskbar_padding = 2 0 2
taskbar_background_id = 0

# Task
task_text = 1
task_icon = 1
task_centered = 0
task_maximum_size = 200 32
task_padding = 4 2 4
task_font = Sans 10
task_font_color = #ffffff 100
task_background_id = 0
task_active_background_id = 2

# System tray
systray_padding = 2 2 2
systray_background_id = 0

# Clock
time1_format = %H:%M
time1_font = Sans Bold 10
clock_font_color = #ffffff 100
clock_padding = 6 0
clock_background_id = 0
EOF

# .desktop 파일 아이콘 수정
cat > $ROOTFS/usr/share/applications/xterm.desktop << 'EOF'
[Desktop Entry]
Name=Terminal
Exec=xterm -bg black -fg white
Icon=utilities-terminal
Type=Application
Categories=System;TerminalEmulator;
EOF

cat > $ROOTFS/usr/share/applications/xfe.desktop << 'EOF'
[Desktop Entry]
Name=File Manager
Exec=xfe
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
xorriso -as mkisofs -o /home/administrator/MaruxOS/output/MaruxOS-1.0-67-v7.iso \
    -r -V 'MARUXOS' -J -joliet-long \
    -isohybrid-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
    -partition_offset 16 -b boot/grub/bios.img -c boot.catalog \
    -no-emul-boot -boot-load-size 4 -boot-info-table .

echo "=== 완료 ==="
ls -lh /home/administrator/MaruxOS/output/MaruxOS-1.0-67-v7.iso
rm -rf /home/administrator/MaruxOS/iso-modify
