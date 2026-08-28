#!/bin/bash
# 67-v14 - mc 단일 패널 모드 + Chromium 수정

set -e

rm -rf /home/administrator/MaruxOS/iso-modify
mkdir -p /home/administrator/MaruxOS/iso-modify/{iso,squashfs,newiso}
mount -o loop /home/administrator/MaruxOS/output/MaruxOS-1.0-67-v13.iso /home/administrator/MaruxOS/iso-modify/iso
cp -a /home/administrator/MaruxOS/iso-modify/iso/* /home/administrator/MaruxOS/iso-modify/newiso/
unsquashfs -d /home/administrator/MaruxOS/iso-modify/squashfs /home/administrator/MaruxOS/iso-modify/newiso/live/filesystem.squashfs

ROOTFS=/home/administrator/MaruxOS/iso-modify/squashfs

# 1. mc 설정 - 좌우 패널이 다른 디렉토리를 보이도록 설정
echo "=== mc 설정 ==="
mkdir -p $ROOTFS/etc/skel/.config/mc

# mc 기본 설정
cat > $ROOTFS/etc/skel/.config/mc/ini << 'MCINI'
[Midnight-Commander]
verbose=true
shell_patterns=true
auto_save_setup=true
auto_menu=false
use_internal_view=true
use_internal_edit=true
clear_before_exec=true
confirm_delete=true
confirm_overwrite=true
confirm_exit=false
safe_delete=false
navigate_with_arrows=true
scroll_pages=true
filetype_mode=true
permission_mode=false
editor_tab_spacing=8
editor_syntax_highlighting=true
nice_rotating_dash=true
mcview_remember_file_position=false
auto_fill_mkdir_name=true
copymove_persistent_attr=true
skin=default

[Layout]
output_lines=0
command_prompt=true
keybar_visible=true
message_visible=true
xterm_title=true
free_space=true
horizontal_split=false
vertical_equal=true
left_panel_size=80
horizontal_equal=true
top_panel_size=1

[Panels]
show_mini_info=true
kilobyte_si=false
mix_all_files=false
show_backups=true
show_dot_files=true
fast_reload=false
mark_moves_down=true
reverse_files_only=true
auto_save_setup_panels=false
navigate_with_arrows=true
panel_scroll_pages=true
mouse_move_pages=true
filetype_mode=true
quick_search_mode=2
MCINI

# mc 패널 설정 - 좌측은 홈, 우측은 루트로 시작
cat > $ROOTFS/etc/skel/.config/mc/panels.ini << 'PANELS'
[New Left Panel]
list_format=full
user_format=half type name | size | perm
user_mini_status=false
user_status=half type name | size | perm
sort_order=name
reverse=false
case_sensitive=false
exec_first=false

[New Right Panel]
list_format=full
user_format=half type name | size | perm
user_mini_status=false
user_status=half type name | size | perm
sort_order=name
reverse=false
case_sensitive=false
exec_first=false
PANELS

# root 계정용 mc 설정도 복사
mkdir -p $ROOTFS/root/.config/mc
cp $ROOTFS/etc/skel/.config/mc/ini $ROOTFS/root/.config/mc/
cp $ROOTFS/etc/skel/.config/mc/panels.ini $ROOTFS/root/.config/mc/

# mc.desktop - 좌측은 홈, 우측은 /로 시작하도록 설정
cat > $ROOTFS/usr/share/applications/mc.desktop << 'EOF'
[Desktop Entry]
Name=File Manager
Exec=xterm -bg "#1a1a2e" -fg "#ffffff" -geometry 120x35 -e "mc ~ /"
Icon=/usr/share/pixmaps/maruxos/marux-file-manager.png
Type=Application
Categories=System;FileManager;
Terminal=false
EOF

# 2. Chromium 완전 수정
echo "=== Chromium 설치 수정 ==="

# Chromium 실행 스크립트 - 간소화
cat > $ROOTFS/usr/bin/chromium << 'CHROMIUM'
#!/bin/bash
export DISPLAY=${DISPLAY:-:0}

# Chromium 실행 경로 찾기
CHROME=""
for path in /usr/lib/chromium/chromium /usr/lib/chromium-browser/chromium-browser /usr/bin/chromium-bin; do
    if [ -x "$path" ]; then
        CHROME="$path"
        break
    fi
done

if [ -z "$CHROME" ]; then
    xterm -e "echo 'Chromium not found. Install with: apt install chromium' && sleep 5"
    exit 1
fi

# Chromium 실행 (root 환경 대응)
exec "$CHROME" --no-sandbox --disable-gpu --disable-software-rasterizer --disable-dev-shm-usage "$@" 2>/dev/null
CHROMIUM
chmod +x $ROOTFS/usr/bin/chromium

# Chromium .desktop 수정
cat > $ROOTFS/usr/share/applications/chromium.desktop << 'EOF'
[Desktop Entry]
Name=Web Browser
Exec=/usr/bin/chromium
Icon=web-browser
Type=Application
Categories=Network;WebBrowser;
Terminal=false
EOF

# 3. 대체 브라우저로 links2 추가 (텍스트 기반, 가벼움)
if [ -f /usr/bin/links2 ]; then
    cp /usr/bin/links2 $ROOTFS/usr/bin/
fi

cat > $ROOTFS/usr/share/applications/links2.desktop << 'EOF'
[Desktop Entry]
Name=Links Browser
Exec=xterm -e links2
Icon=web-browser
Type=Application
Categories=Network;WebBrowser;
Terminal=false
EOF

# 4. tint2 런처 업데이트
echo "=== tint2 설정 업데이트 ==="
cat > $ROOTFS/etc/xdg/tint2/tint2rc << 'EOF'
# tint2 config for MaruxOS v14

# Background definitions
rounded = 0
border_width = 0
background_color = #1a1a2e 95
border_color = #000000 0

rounded = 6
border_width = 1
background_color = #0f3460 100
border_color = #e94560 100

rounded = 4
border_width = 0
background_color = #16213e 80
border_color = #0f3460 50

# Panel
panel_items = LTSC
panel_size = 100% 36
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
launcher_padding = 6 4 6
launcher_background_id = 0
launcher_icon_size = 26
launcher_icon_asb = 100 0 0
launcher_icon_theme = Adwaita
launcher_icon_theme_override = 1
launcher_tooltip = 1
launcher_item_app = /usr/share/applications/marux-menu.desktop
launcher_item_app = /usr/share/applications/xterm.desktop
launcher_item_app = /usr/share/applications/mc.desktop
launcher_item_app = /usr/share/applications/chromium.desktop

# Taskbar - 단일 데스크톱 모드
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
task_padding = 6 2 6
task_font = Sans 10
task_font_color = #ffffff 100
task_icon_asb = 100 0 0
task_background_id = 3
task_active_background_id = 2
task_urgent_background_id = 2
mouse_left = toggle_iconify
mouse_middle = close
mouse_right = none
mouse_scroll_up = toggle
mouse_scroll_down = iconify

# feh 데스크톱 창 숨기기
wm_class_filter = feh

# System tray
systray_padding = 4 2 4
systray_background_id = 0
systray_sort = ascending
systray_icon_size = 22
systray_icon_asb = 100 0 0
systray_monitor = 1

# Clock
time1_format = %H:%M
time1_font = Sans Bold 11
time2_format = %Y-%m-%d
time2_font = Sans 9
clock_font_color = #ffffff 100
clock_padding = 8 0
clock_background_id = 0
clock_tooltip = %A %B %d, %Y
EOF

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
    -o /home/administrator/MaruxOS/output/MaruxOS-1.0-67-v14.iso \
    /home/administrator/MaruxOS/iso-modify/newiso

# 정리
umount /home/administrator/MaruxOS/iso-modify/iso 2>/dev/null || true
rm -rf /home/administrator/MaruxOS/iso-modify

echo "=== 완료 ==="
ls -lh /home/administrator/MaruxOS/output/MaruxOS-1.0-67-v14.iso
