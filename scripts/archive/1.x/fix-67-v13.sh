#!/bin/bash
# 67-v13 - Chromium 수정 및 Desktop 태스크바 표시 문제 해결

set -e

rm -rf /home/administrator/MaruxOS/iso-modify
mkdir -p /home/administrator/MaruxOS/iso-modify/{iso,squashfs,newiso}
mount -o loop /home/administrator/MaruxOS/output/MaruxOS-1.0-67-v12.iso /home/administrator/MaruxOS/iso-modify/iso
cp -a /home/administrator/MaruxOS/iso-modify/iso/* /home/administrator/MaruxOS/iso-modify/newiso/
unsquashfs -d /home/administrator/MaruxOS/iso-modify/squashfs /home/administrator/MaruxOS/iso-modify/newiso/live/filesystem.squashfs

ROOTFS=/home/administrator/MaruxOS/iso-modify/squashfs

# 1. Chromium 완전 설치
echo "=== Chromium 완전 설치 ==="

# Chromium 바이너리 및 라이브러리 복사
if [ -d /usr/lib/chromium ]; then
    mkdir -p $ROOTFS/usr/lib/chromium
    cp -r /usr/lib/chromium/* $ROOTFS/usr/lib/chromium/
fi

if [ -d /usr/lib/chromium-browser ]; then
    mkdir -p $ROOTFS/usr/lib/chromium-browser
    cp -r /usr/lib/chromium-browser/* $ROOTFS/usr/lib/chromium-browser/
fi

# chromium 실행 파일
if [ -f /usr/bin/chromium ]; then
    cp /usr/bin/chromium $ROOTFS/usr/bin/
elif [ -f /usr/bin/chromium-browser ]; then
    cp /usr/bin/chromium-browser $ROOTFS/usr/bin/chromium
fi

# chromium 의존성 복사
for bin in /usr/bin/chromium /usr/bin/chromium-browser /usr/lib/chromium/chromium /usr/lib/chromium-browser/chromium-browser; do
    if [ -f "$bin" ]; then
        ldd "$bin" 2>/dev/null | grep "=>" | awk '{print $3}' | while read lib; do
            if [ -f "$lib" ]; then
                basename_lib=$(basename "$lib")
                if [[ ! "$basename_lib" =~ ^(libc\.so|libm\.so|libpthread|libdl\.so|librt\.so) ]]; then
                    cp -n "$lib" "$ROOTFS/usr/lib/" 2>/dev/null || true
                fi
            fi
        done
    fi
done

# NSS 라이브러리 (Chromium 필수)
for lib in /usr/lib/x86_64-linux-gnu/libnss* /usr/lib/x86_64-linux-gnu/libnspr* /usr/lib/libnss* /usr/lib/libnspr*; do
    if [ -f "$lib" ]; then
        cp -n "$lib" "$ROOTFS/usr/lib/" 2>/dev/null || true
    fi
done

# Chromium .desktop 파일 수정
cat > $ROOTFS/usr/share/applications/chromium.desktop << 'EOF'
[Desktop Entry]
Name=Chromium
Exec=/usr/bin/chromium --no-sandbox --disable-gpu --disable-software-rasterizer
Icon=web-browser
Type=Application
Categories=Network;WebBrowser;
Terminal=false
EOF

# Chromium 래퍼 스크립트 생성
cat > $ROOTFS/usr/bin/chromium-wrapper << 'EOF'
#!/bin/bash
export DISPLAY=:0
exec /usr/lib/chromium/chromium --no-sandbox --disable-gpu --disable-software-rasterizer "$@" 2>/dev/null
EOF
chmod +x $ROOTFS/usr/bin/chromium-wrapper

# 2. tint2 설정 - Desktop 태스크바 숨기기
echo "=== tint2 설정 업데이트 ==="
cat > $ROOTFS/etc/xdg/tint2/tint2rc << 'EOF'
# tint2 config for MaruxOS v13

# Background definitions
rounded = 0
border_width = 0
background_color = #2d2d2d 100
border_color = #000000 0

rounded = 0
border_width = 0
background_color = #4a90d9 100
border_color = #000000 0

rounded = 0
border_width = 0
background_color = #3a3a3a 100
border_color = #000000 0

# Panel
panel_items = LTSC
panel_size = 100% 32
panel_margin = 0 0
panel_padding = 4 0 4
panel_background_id = 1
panel_position = bottom center horizontal
panel_layer = top
panel_monitor = all
panel_dock = 0
autohide = 0
strut_policy = follow_size

# Launcher
launcher_padding = 4 4 4
launcher_background_id = 0
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
taskbar_name = 0
taskbar_hide_inactive_tasks = 0
taskbar_hide_different_monitor = 0
taskbar_sort_order = none
taskbar_always_show_all_desktop_tasks = 0

# Task
task_text = 1
task_icon = 1
task_centered = 0
task_maximum_size = 200 32
task_padding = 4 2 4
task_font = Sans 10
task_font_color = #ffffff 100
task_icon_asb = 100 0 0
task_background_id = 0
task_active_background_id = 2
task_urgent_background_id = 2
mouse_left = toggle_iconify
mouse_middle = close
mouse_right = none
mouse_scroll_up = toggle
mouse_scroll_down = iconify

# Task: skip specific window classes
wm_class_filter = feh pcmanfm-desktop

# System tray
systray_padding = 4 2 4
systray_background_id = 0
systray_sort = ascending
systray_icon_size = 20
systray_icon_asb = 100 0 0
systray_monitor = 1

# Clock
time1_format = %H:%M
time1_font = Sans Bold 10
time2_format = %Y-%m-%d
time2_font = Sans 8
clock_font_color = #ffffff 100
clock_padding = 8 0
clock_background_id = 0
clock_lclick_command =
clock_rclick_command =
clock_tooltip = %A %d %B %Y
EOF

# 3. feh를 데스크톱으로 설정 - 태스크바에서 숨기기
echo "=== xinitrc 업데이트 ==="
cat > $ROOTFS/etc/X11/xinit/xinitrc << 'XINITRC'
#!/bin/sh

# XDG Runtime Directory
export XDG_RUNTIME_DIR=/tmp/runtime-root
mkdir -p $XDG_RUNTIME_DIR
chmod 700 $XDG_RUNTIME_DIR

# GTK 설정
export GTK2_RC_FILES=/etc/gtk-2.0/gtkrc
export GTK_THEME=Adwaita

# 배경화면 설정 (--no-fehbg로 태스크바에서 숨기기)
if [ -f /usr/share/pixmaps/maruxos/marux-desktop.png ]; then
    feh --bg-scale /usr/share/pixmaps/maruxos/marux-desktop.png &
fi

# 윈도우 매니저 시작
openbox &
sleep 0.5

# 시스템 트레이 앱
if [ -x /usr/bin/nm-applet ]; then
    /usr/bin/nm-applet 2>/dev/null &
fi
if [ -x /usr/bin/volumeicon ]; then
    /usr/bin/volumeicon 2>/dev/null &
fi

# tint2 패널
exec tint2
XINITRC
chmod +x $ROOTFS/etc/X11/xinit/xinitrc

# 4. Openbox 설정 - 데스크톱 창 무시
echo "=== Openbox 설정 업데이트 ==="
# Openbox applications 설정 추가
mkdir -p $ROOTFS/etc/xdg/openbox
if [ -f $ROOTFS/etc/xdg/openbox/rc.xml ]; then
    # rc.xml의 </openbox_config> 앞에 applications 섹션 추가
    sed -i 's|</openbox_config>|<applications>\n    <application class="feh">\n      <skip_taskbar>yes</skip_taskbar>\n      <skip_pager>yes</skip_pager>\n      <layer>below</layer>\n    </application>\n    <application class="Desktop">\n      <skip_taskbar>yes</skip_taskbar>\n      <skip_pager>yes</skip_pager>\n    </application>\n  </applications>\n</openbox_config>|' $ROOTFS/etc/xdg/openbox/rc.xml
fi

# 5. squashfs 재생성
echo "=== squashfs 생성 ==="
rm -f /home/administrator/MaruxOS/iso-modify/newiso/live/filesystem.squashfs
mksquashfs $ROOTFS /home/administrator/MaruxOS/iso-modify/newiso/live/filesystem.squashfs -comp gzip -noappend

# 6. ISO 생성
echo "=== ISO 생성 ==="
xorriso -as mkisofs \
    -isohybrid-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
    -c boot/boot.cat \
    -b boot/grub/bios.img \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -o /home/administrator/MaruxOS/output/MaruxOS-1.0-67-v13.iso \
    /home/administrator/MaruxOS/iso-modify/newiso

# 정리
umount /home/administrator/MaruxOS/iso-modify/iso 2>/dev/null || true
rm -rf /home/administrator/MaruxOS/iso-modify

echo "=== 완료 ==="
ls -lh /home/administrator/MaruxOS/output/MaruxOS-1.0-67-v13.iso
