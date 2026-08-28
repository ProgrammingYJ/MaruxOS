#!/bin/bash
# 67-v18 - 시스템 트레이 (WiFi, 소리) 설정 + Firefox 로케일 경고 수정

set -e

rm -rf /home/administrator/MaruxOS/iso-modify
mkdir -p /home/administrator/MaruxOS/iso-modify/{iso,squashfs,newiso}
mount -o loop /home/administrator/MaruxOS/output/MaruxOS-1.0-67-v17.iso /home/administrator/MaruxOS/iso-modify/iso
cp -a /home/administrator/MaruxOS/iso-modify/iso/* /home/administrator/MaruxOS/iso-modify/newiso/
unsquashfs -d /home/administrator/MaruxOS/iso-modify/squashfs /home/administrator/MaruxOS/iso-modify/newiso/live/filesystem.squashfs

ROOTFS=/home/administrator/MaruxOS/iso-modify/squashfs

echo "=== 시스템 트레이 앱 설치 ==="

# 1. pavucontrol (PulseAudio 볼륨 컨트롤) 복사
if [ -f /usr/bin/pavucontrol ]; then
    cp /usr/bin/pavucontrol $ROOTFS/usr/bin/
    # 의존성 복사
    for lib in $(ldd /usr/bin/pavucontrol 2>/dev/null | grep "=>" | awk '{print $3}'); do
        [ -f "$lib" ] && cp -n "$lib" $ROOTFS/usr/lib/ 2>/dev/null || true
    done
fi

# 2. nm-connection-editor (NetworkManager GUI) 복사
if [ -f /usr/bin/nm-connection-editor ]; then
    cp /usr/bin/nm-connection-editor $ROOTFS/usr/bin/
fi

# 3. nmtui (터미널 기반 네트워크 설정) 복사
if [ -f /usr/bin/nmtui ]; then
    cp /usr/bin/nmtui $ROOTFS/usr/bin/
fi

# 4. 볼륨 컨트롤 스크립트 (pavucontrol 또는 alsamixer)
cat > $ROOTFS/usr/bin/volume-control << 'EOF'
#!/bin/bash
if [ -x /usr/bin/pavucontrol ]; then
    exec pavucontrol
elif [ -x /usr/bin/alsamixer ]; then
    exec xterm -title "Volume Control" -e alsamixer
else
    xterm -title "Volume" -e "echo 'No volume control available' && sleep 3"
fi
EOF
chmod +x $ROOTFS/usr/bin/volume-control

# 5. 네트워크 설정 스크립트
cat > $ROOTFS/usr/bin/network-settings << 'EOF'
#!/bin/bash
if [ -x /usr/bin/nm-connection-editor ]; then
    exec nm-connection-editor
elif [ -x /usr/bin/nmtui ]; then
    exec xterm -title "Network Settings" -e nmtui
else
    xterm -title "Network" -e "echo 'No network manager available' && sleep 3"
fi
EOF
chmod +x $ROOTFS/usr/bin/network-settings

# 6. 퀵 설정 메뉴 (클릭시 팝업)
cat > $ROOTFS/usr/bin/quick-settings << 'EOF'
#!/bin/bash
# 간단한 퀵 설정 메뉴
choice=$(echo -e "Volume Control\nNetwork Settings\nDisplay Settings" | \
    xterm -title "Quick Settings" -geometry 30x5 -e "cat && read -p 'Enter choice (1-3): ' c && echo \$c")

case "$choice" in
    1) /usr/bin/volume-control ;;
    2) /usr/bin/network-settings ;;
    3) xterm -e "xrandr && read" ;;
esac
EOF
chmod +x $ROOTFS/usr/bin/quick-settings

# 7. xinitrc 업데이트 - 시스템 트레이 앱 자동 실행
echo "=== xinitrc 업데이트 ==="
cat > $ROOTFS/etc/X11/xinit/xinitrc << 'XINITRC'
#!/bin/sh

# XDG Runtime Directory
export XDG_RUNTIME_DIR=/tmp/runtime-root
mkdir -p $XDG_RUNTIME_DIR
chmod 700 $XDG_RUNTIME_DIR

# 로케일 설정
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

# GTK 설정
export GTK2_RC_FILES=/etc/gtk-2.0/gtkrc
export GTK_THEME=Adwaita

# 배경화면
if [ -f /usr/share/pixmaps/maruxos/marux-desktop.png ]; then
    feh --bg-scale /usr/share/pixmaps/maruxos/marux-desktop.png &
fi

# Openbox 윈도우 매니저
openbox &
sleep 0.5

# 시스템 트레이 앱들
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

# 8. tint2 설정 - 시스템 트레이 활성화 확인
echo "=== tint2 설정 업데이트 ==="
cat > $ROOTFS/etc/xdg/tint2/tint2rc << 'EOF'
# MaruxOS tint2 - Windows 11 Style with System Tray

#---------------------------------------------
# 배경 정의
#---------------------------------------------
# ID 1: 패널 배경
rounded = 0
border_width = 0
background_color = #1a1a2e 95
border_color = #000000 0

# ID 2: 활성 태스크
rounded = 4
border_width = 0
background_color = #3d5a80 100
border_color = #5d8ac2 100

# ID 3: 일반 아이콘 배경
rounded = 4
border_width = 0
background_color = #000000 0
border_color = #000000 0

#---------------------------------------------
# 패널 설정
#---------------------------------------------
panel_items = :LT:SC
panel_size = 100% 48
panel_margin = 0 0
panel_padding = 8 4 8
panel_background_id = 1
panel_position = bottom center horizontal
panel_layer = top
panel_monitor = all
panel_dock = 0
autohide = 0
strut_policy = follow_size

#---------------------------------------------
# 런처
#---------------------------------------------
launcher_padding = 4 4 8
launcher_background_id = 0
launcher_icon_size = 32
launcher_icon_asb = 100 0 0
launcher_icon_theme = Adwaita
launcher_icon_theme_override = 1
launcher_tooltip = 1

launcher_item_app = /usr/share/applications/marux-menu.desktop
launcher_item_app = /usr/share/applications/xterm.desktop
launcher_item_app = /usr/share/applications/mc.desktop
launcher_item_app = /usr/share/applications/chromium.desktop

#---------------------------------------------
# 태스크바
#---------------------------------------------
taskbar_mode = single_desktop
taskbar_hide_if_empty = 1
taskbar_padding = 4 0 4
taskbar_background_id = 0
taskbar_name = 0
taskbar_sort_order = none

task_text = 0
task_icon = 1
task_centered = 1
task_maximum_size = 44 40
task_padding = 4 4 4
task_tooltip = 1

task_icon_asb = 100 0 0
task_background_id = 3
task_active_background_id = 2
task_urgent_background_id = 2

mouse_left = toggle_iconify
mouse_middle = close
mouse_right = none

wm_class_filter = feh

#---------------------------------------------
# 시스템 트레이 (WiFi, 볼륨 아이콘)
#---------------------------------------------
systray_padding = 8 4 8
systray_background_id = 0
systray_sort = ascending
systray_icon_size = 24
systray_icon_asb = 100 0 0
systray_monitor = primary

#---------------------------------------------
# 시계
#---------------------------------------------
time1_format = %H:%M
time1_font = Sans Bold 11
time2_format = %Y-%m-%d
time2_font = Sans 9
clock_font_color = #ffffff 100
clock_padding = 12 4
clock_background_id = 0
clock_tooltip = %A %B %d, %Y
clock_lclick_command = /usr/bin/quick-settings
clock_rclick_command = /usr/bin/quick-settings
EOF

# 9. Firefox 래퍼 - 로케일 경고 숨기기
echo "=== Firefox 래퍼 업데이트 ==="
cat > $ROOTFS/usr/bin/firefox << 'WRAPPER'
#!/bin/bash
export DISPLAY=${DISPLAY:-:0}
export LANG=C.UTF-8
export LC_ALL=C.UTF-8
export MOZ_DISABLE_CONTENT_SANDBOX=1
export MOZ_DISABLE_GMP_SANDBOX=1
export MOZ_DISABLE_NPAPI_SANDBOX=1
export MOZ_DISABLE_GPU_SANDBOX=1
export MOZ_DISABLE_RDD_SANDBOX=1
export MOZ_DISABLE_SOCKET_PROCESS_SANDBOX=1
export LD_LIBRARY_PATH=/opt/firefox:/usr/lib:$LD_LIBRARY_PATH

cd /opt/firefox
exec ./firefox-bin "$@" 2>/dev/null
WRAPPER
chmod +x $ROOTFS/usr/bin/firefox

# 10. .desktop 파일 수정 - 터미널 없이 실행
cat > $ROOTFS/usr/share/applications/chromium.desktop << 'EOF'
[Desktop Entry]
Name=Web Browser
Exec=/usr/bin/firefox %u
Icon=/opt/firefox/browser/chrome/icons/default/default128.png
Type=Application
Categories=Network;WebBrowser;
Terminal=false
EOF

echo "=== squashfs 생성 ==="
rm -f /home/administrator/MaruxOS/iso-modify/newiso/live/filesystem.squashfs
mksquashfs $ROOTFS /home/administrator/MaruxOS/iso-modify/newiso/live/filesystem.squashfs -comp gzip -noappend

echo "=== ISO 생성 ==="
xorriso -as mkisofs \
    -isohybrid-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
    -c boot/boot.cat \
    -b boot/grub/bios.img \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -o /home/administrator/MaruxOS/output/MaruxOS-1.0-67-v18.iso \
    /home/administrator/MaruxOS/iso-modify/newiso

umount /home/administrator/MaruxOS/iso-modify/iso 2>/dev/null || true
rm -rf /home/administrator/MaruxOS/iso-modify

echo "=== 완료 ==="
ls -lh /home/administrator/MaruxOS/output/MaruxOS-1.0-67-v18.iso
