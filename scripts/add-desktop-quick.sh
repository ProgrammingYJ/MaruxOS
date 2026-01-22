#!/bin/bash
# Quick desktop apps addition

ROOTFS=/home/administrator/MaruxOS/iso-modify/squashfs

# 디렉토리 준비
mkdir -p $ROOTFS/etc/xdg/{openbox,tint2,pcmanfm/default}
mkdir -p $ROOTFS/usr/share/backgrounds
mkdir -p $ROOTFS/root/Desktop

# 바이너리 복사
echo '=== 바이너리 복사 ==='
cp /usr/bin/feh $ROOTFS/usr/bin/
cp /usr/bin/tint2 $ROOTFS/usr/bin/
cp /usr/bin/pcmanfm $ROOTFS/usr/bin/

# 라이브러리 의존성 복사
echo '=== 라이브러리 복사 ==='
copy_deps() {
    ldd "$1" 2>/dev/null | grep "=>" | awk '{print $3}' | while read lib; do
        if [ -f "$lib" ]; then
            libname=$(basename "$lib")
            if [ ! -f "$ROOTFS/usr/lib/$libname" ] && [ ! -f "$ROOTFS/lib/x86_64-linux-gnu/$libname" ]; then
                cp -f "$lib" "$ROOTFS/usr/lib/" 2>/dev/null || true
            fi
        fi
    done
}

copy_deps /usr/bin/feh
copy_deps /usr/bin/tint2
copy_deps /usr/bin/pcmanfm

# 추가 라이브러리
for lib in /usr/lib/x86_64-linux-gnu/libImlib2.so* \
           /usr/lib/x86_64-linux-gnu/libfm*.so* \
           /usr/lib/x86_64-linux-gnu/libmenu-cache*.so*; do
    [ -f "$lib" ] && cp -af "$lib" "$ROOTFS/usr/lib/" 2>/dev/null || true
done

# 배경화면 복사
echo '=== 배경화면 복사 ==='
cp /home/administrator/MaruxOS/assets/wallpapers/marux-desktop.png $ROOTFS/usr/share/backgrounds/
cp /home/administrator/MaruxOS/assets/wallpapers/marux-login.png $ROOTFS/usr/share/backgrounds/

# Openbox autostart
echo '=== Openbox autostart 설정 ==='
cat > $ROOTFS/etc/xdg/openbox/autostart << 'EOF'
#!/bin/bash
# MaruxOS Desktop Autostart

# 바탕화면 관리 (pcmanfm)
if [ -f /usr/bin/pcmanfm ]; then
    pcmanfm --desktop &
elif [ -f /usr/bin/feh ]; then
    feh --bg-scale /usr/share/backgrounds/marux-desktop.png &
fi

# tint2 패널
if [ -f /usr/bin/tint2 ]; then
    sleep 1
    tint2 &
fi
EOF
chmod +x $ROOTFS/etc/xdg/openbox/autostart

# tint2 설정
echo '=== tint2 설정 ==='
cat > $ROOTFS/etc/xdg/tint2/tint2rc << 'EOF'
panel_items = LTSC
panel_size = 100% 40
panel_margin = 0 0
panel_padding = 8 4 8
panel_position = bottom center horizontal
panel_layer = top
panel_monitor = all
autohide = 0
rounded = 0
border_width = 0
background_color = #1a1a2e 90
border_color = #16213e 100
taskbar_mode = single_desktop
taskbar_padding = 4 2 4
task_text = 1
task_icon = 1
task_maximum_size = 200 35
task_padding = 6 3 6
task_font = Sans 10
task_font_color = #ffffff 100
task_active_font_color = #ffffff 100
systray_padding = 4 4 4
systray_icon_size = 22
time1_format = %H:%M
time1_font = Sans Bold 11
time2_format = %Y-%m-%d
time2_font = Sans 9
clock_font_color = #ffffff 100
clock_padding = 8 4
EOF

# PCManFM 바탕화면 설정
echo '=== PCManFM 설정 ==='
cat > $ROOTFS/etc/xdg/pcmanfm/default/desktop-items-0.conf << 'EOF'
[*]
wallpaper_mode=stretch
wallpaper_common=1
wallpaper=/usr/share/backgrounds/marux-desktop.png
desktop_bg=#1a1a2e
desktop_fg=#ffffff
desktop_font=Sans 11
show_trash=1
show_mounts=1
EOF

# 바탕화면 아이콘
echo '=== 바탕화면 아이콘 ==='
cat > $ROOTFS/root/Desktop/Terminal.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Terminal
Exec=maruxos-terminal
Icon=utilities-terminal
Terminal=false
EOF

cat > $ROOTFS/root/Desktop/Files.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Files
Exec=pcmanfm
Icon=system-file-manager
Terminal=false
EOF

chmod +x $ROOTFS/root/Desktop/*.desktop

echo '=== 완료 ==='
ls -la $ROOTFS/usr/bin/{feh,tint2,pcmanfm}
