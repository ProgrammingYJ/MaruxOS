#!/bin/bash
# 67-v12 - tint2 패널 완전 개편 (커스텀 아이콘 + 시스템 트레이)

rm -rf /home/administrator/MaruxOS/iso-modify
mkdir -p /home/administrator/MaruxOS/iso-modify/{iso,squashfs,newiso}
mount -o loop /home/administrator/MaruxOS/output/MaruxOS-1.0-67-v11.iso /home/administrator/MaruxOS/iso-modify/iso
cp -a /home/administrator/MaruxOS/iso-modify/iso/* /home/administrator/MaruxOS/iso-modify/newiso/
unsquashfs -d /home/administrator/MaruxOS/iso-modify/squashfs /home/administrator/MaruxOS/iso-modify/newiso/live/filesystem.squashfs

ROOTFS=/home/administrator/MaruxOS/iso-modify/squashfs

# 1. 커스텀 아이콘 복사
echo "=== 커스텀 아이콘 복사 ==="
mkdir -p $ROOTFS/usr/share/pixmaps/maruxos
cp "/mnt/c/Users/Administrator/Desktop/MaruxOS/MaruxOS 디자인/marux-terminal.png" $ROOTFS/usr/share/pixmaps/maruxos/
cp "/mnt/c/Users/Administrator/Desktop/MaruxOS/MaruxOS 디자인/marux-file-manager.png" $ROOTFS/usr/share/pixmaps/maruxos/
cp "/mnt/c/Users/Administrator/Desktop/MaruxOS/MaruxOS 디자인/marux-desktop.png" $ROOTFS/usr/share/pixmaps/maruxos/marux-logo.png

# 2. network-manager 및 volumeicon 설치
echo "=== nm-applet 및 volumeicon 복사 ==="
# nm-applet
if [ -f /usr/bin/nm-applet ]; then
    cp /usr/bin/nm-applet $ROOTFS/usr/bin/
    # nm-applet 의존성
    ldd /usr/bin/nm-applet 2>/dev/null | grep "=>" | awk '{print $3}' | while read lib; do
        if [ -f "$lib" ]; then
            basename_lib=$(basename "$lib")
            if [[ ! "$basename_lib" =~ ^(libc\.so|libm\.so|libpthread|libdl\.so|librt\.so) ]]; then
                cp -n "$lib" "$ROOTFS/usr/lib/" 2>/dev/null
            fi
        fi
    done
fi

# volumeicon
if [ -f /usr/bin/volumeicon ]; then
    cp /usr/bin/volumeicon $ROOTFS/usr/bin/
    # volumeicon 의존성
    ldd /usr/bin/volumeicon 2>/dev/null | grep "=>" | awk '{print $3}' | while read lib; do
        if [ -f "$lib" ]; then
            basename_lib=$(basename "$lib")
            if [[ ! "$basename_lib" =~ ^(libc\.so|libm\.so|libpthread|libdl\.so|librt\.so) ]]; then
                cp -n "$lib" "$ROOTFS/usr/lib/" 2>/dev/null
            fi
        fi
    done
fi

# chromium
echo "=== Chromium 브라우저 복사 ==="
if [ -f /usr/bin/chromium ]; then
    cp /usr/bin/chromium $ROOTFS/usr/bin/
    # chromium 의존성
    ldd /usr/bin/chromium 2>/dev/null | grep "=>" | awk '{print $3}' | while read lib; do
        if [ -f "$lib" ]; then
            basename_lib=$(basename "$lib")
            if [[ ! "$basename_lib" =~ ^(libc\.so|libm\.so|libpthread|libdl\.so|librt\.so) ]]; then
                cp -n "$lib" "$ROOTFS/usr/lib/" 2>/dev/null
            fi
        fi
    done
    # chromium 데이터 파일
    if [ -d /usr/lib/chromium ]; then
        mkdir -p $ROOTFS/usr/lib/chromium
        cp -r /usr/lib/chromium/* $ROOTFS/usr/lib/chromium/ 2>/dev/null
    fi
fi

# 3. .desktop 파일 업데이트 (커스텀 아이콘)
echo "=== .desktop 파일 업데이트 ==="
cat > $ROOTFS/usr/share/applications/xterm.desktop << 'EOF'
[Desktop Entry]
Name=Terminal
Exec=xterm -bg black -fg white
Icon=/usr/share/pixmaps/maruxos/marux-terminal.png
Type=Application
Categories=System;TerminalEmulator;
EOF

cat > $ROOTFS/usr/share/applications/mc.desktop << 'EOF'
[Desktop Entry]
Name=File Manager
Exec=xterm -bg black -fg white -e mc
Icon=/usr/share/pixmaps/maruxos/marux-file-manager.png
Type=Application
Categories=System;FileManager;
EOF

# Marux 앱 메뉴 런처
cat > $ROOTFS/usr/share/applications/marux-menu.desktop << 'EOF'
[Desktop Entry]
Name=Applications
Exec=xterm -e "echo 'App Menu - Feature Coming Soon' && sleep 2"
Icon=/usr/share/pixmaps/maruxos/marux-logo.png
Type=Application
Categories=System;
NoDisplay=false
EOF

# Chromium 브라우저
cat > $ROOTFS/usr/share/applications/chromium.desktop << 'EOF'
[Desktop Entry]
Name=Chromium Web Browser
Exec=chromium --no-sandbox
Icon=/usr/share/pixmaps/maruxos/marux-logo.png
Type=Application
Categories=Network;WebBrowser;
EOF

# 4. tint2 설정 업데이트
echo "=== tint2 설정 업데이트 ==="
cat > $ROOTFS/etc/xdg/tint2/tint2rc << 'EOF'
# Tint2 config for MaruxOS

# Panel
panel_items = LTSC
panel_size = 100% 32
panel_position = bottom center horizontal
panel_background_id = 1
panel_padding = 4 0 4
panel_layer = top
wm_menu = 1
panel_dock = 0
panel_shrink = 0

# Backgrounds
background_color = #2d2d2d 90
border_width = 0
background_color_hover = #3d3d3d 100
border_color_hover = #555555 30

background_color = #2d2d2d 90
border_width = 0

background_color = #3d3d3d 100
border_width = 0

background_color = #4a90d9 100
border_width = 0

# Launcher
launcher_padding = 4 2 4
launcher_background_id = 1
launcher_icon_background_id = 0
launcher_icon_size = 24
launcher_icon_asb = 100 0 0
launcher_icon_theme = Adwaita
launcher_icon_theme_override = 1
launcher_tooltip = 1
launcher_item_app = /usr/share/applications/marux-menu.desktop
launcher_item_app = /usr/share/applications/xterm.desktop
launcher_item_app = /usr/share/applications/mc.desktop
launcher_item_app = /usr/share/applications/chromium.desktop

# Taskbar
taskbar_mode = single_desktop
taskbar_hide_if_empty = 0
taskbar_padding = 4 2 4
taskbar_background_id = 0
taskbar_active_background_id = 0
taskbar_name = 1
taskbar_hide_inactive_tasks = 0
taskbar_hide_different_monitor = 0
taskbar_hide_different_desktop = 0
taskbar_always_show_all_desktop_tasks = 0
taskbar_name_padding = 6 3
taskbar_name_background_id = 0
taskbar_name_active_background_id = 0
taskbar_name_font_color = #ffffff 100
taskbar_name_active_font_color = #ffffff 100
taskbar_distribute_size = 1
taskbar_sort_order = none
task_align = left

# Task
task_text = 1
task_icon = 1
task_centered = 0
task_maximum_size = 200 32
task_padding = 4 3 4
task_font = Sans 10
task_tooltip = 1
task_thumbnail = 0
task_thumbnail_size = 210
task_font_color = #ffffff 100
task_icon_asb = 100 0 0
task_background_id = 0
task_active_background_id = 3
task_urgent_background_id = 0
task_iconified_background_id = 0
mouse_left = toggle_iconify
mouse_middle = none
mouse_right = close
mouse_scroll_up = prev_task
mouse_scroll_down = next_task

# System tray
systray_padding = 4 2 4
systray_background_id = 0
systray_sort = ascending
systray_icon_size = 20
systray_icon_asb = 100 0 0
systray_monitor = 1
systray_name_filter =

# Clock
time1_format = %H:%M
time1_font = Sans Bold 10
time2_format = %Y-%m-%d
time2_font = Sans 8
clock_font_color = #ffffff 100
clock_padding = 6 2
clock_background_id = 0
clock_tooltip = %A, %d %B
clock_tooltip_timezone =
clock_lclick_command =
clock_rclick_command =
clock_mclick_command =
clock_uwheel_command =
clock_dwheel_command =

# Tooltip
tooltip_show_timeout = 0.5
tooltip_hide_timeout = 0.1
tooltip_padding = 4 4
tooltip_background_id = 2
tooltip_font_color = #ffffff 100
tooltip_font = Sans 10
EOF

# 5. xinitrc 업데이트 (nm-applet, volumeicon 자동 실행)
echo "=== xinitrc 업데이트 ==="
cat > $ROOTFS/etc/X11/xinit/xinitrc << 'EOF'
#!/bin/sh
export XDG_RUNTIME_DIR=/tmp/runtime-root
mkdir -p $XDG_RUNTIME_DIR
chmod 700 $XDG_RUNTIME_DIR
export DISPLAY=:0

# 배경화면
/usr/bin/feh --bg-scale /usr/share/backgrounds/marux-desktop.png 2>/dev/null &

# 시스템 트레이 앱들
sleep 0.5
if [ -x /usr/bin/nm-applet ]; then
    /usr/bin/nm-applet 2>/dev/null &
fi
if [ -x /usr/bin/volumeicon ]; then
    /usr/bin/volumeicon 2>/dev/null &
fi

# tint2 패널
sleep 1
/usr/bin/tint2 2>/dev/null &

# Openbox
exec /usr/bin/openbox
EOF
chmod +x $ROOTFS/etc/X11/xinit/xinitrc

echo "=== squashfs 생성 ==="
rm -f /home/administrator/MaruxOS/iso-modify/newiso/live/filesystem.squashfs
mksquashfs $ROOTFS /home/administrator/MaruxOS/iso-modify/newiso/live/filesystem.squashfs -comp gzip -b 131072

umount /home/administrator/MaruxOS/iso-modify/iso 2>/dev/null

echo "=== ISO 생성 ==="
cd /home/administrator/MaruxOS/iso-modify/newiso
xorriso -as mkisofs -o /home/administrator/MaruxOS/output/MaruxOS-1.0-67-v12.iso \
    -r -V 'MARUXOS' -J -joliet-long \
    -isohybrid-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
    -partition_offset 16 -b boot/grub/bios.img -c boot.catalog \
    -no-emul-boot -boot-load-size 4 -boot-info-table .

echo "=== 완료 ==="
ls -lh /home/administrator/MaruxOS/output/MaruxOS-1.0-67-v12.iso
rm -rf /home/administrator/MaruxOS/iso-modify
