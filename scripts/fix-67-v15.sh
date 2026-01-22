#!/bin/bash
# 67-v15 - Windows 11 스타일 가운데 정렬 태스크바

set -e

rm -rf /home/administrator/MaruxOS/iso-modify
mkdir -p /home/administrator/MaruxOS/iso-modify/{iso,squashfs,newiso}
mount -o loop /home/administrator/MaruxOS/output/MaruxOS-1.0-67-v14.iso /home/administrator/MaruxOS/iso-modify/iso
cp -a /home/administrator/MaruxOS/iso-modify/iso/* /home/administrator/MaruxOS/iso-modify/newiso/
unsquashfs -d /home/administrator/MaruxOS/iso-modify/squashfs /home/administrator/MaruxOS/iso-modify/newiso/live/filesystem.squashfs

ROOTFS=/home/administrator/MaruxOS/iso-modify/squashfs

# tint2 설정 - Windows 11 스타일 가운데 정렬
echo "=== tint2 Windows 11 스타일 설정 ==="
cat > $ROOTFS/etc/xdg/tint2/tint2rc << 'EOF'
# MaruxOS tint2 - Windows 11 Style (Center aligned)

#---------------------------------------------
# 배경 정의
#---------------------------------------------
# ID 1: 패널 배경 (반투명 다크)
rounded = 0
border_width = 0
border_sides =
background_color = #1a1a2e 95
border_color = #000000 0

# ID 2: 활성 태스크/호버
rounded = 4
border_width = 0
border_sides = TBLR
background_color = #3d5a80 100
border_color = #5d8ac2 100

# ID 3: 일반 아이콘 배경
rounded = 4
border_width = 0
border_sides =
background_color = #000000 0
border_color = #000000 0

#---------------------------------------------
# 패널 설정
#---------------------------------------------
# 패널 아이템: 빈공간(:) + 런처(L) + 태스크바(T) + 빈공간(:) + 시스템트레이(S) + 시계(C)
# 런처와 실행중인 창이 함께 가운데 정렬됨
panel_items = :LT:SC
panel_size = 100% 48
panel_margin = 0 0
panel_padding = 8 4 8
panel_background_id = 1
panel_position = bottom center horizontal
panel_layer = top
panel_monitor = all
panel_dock = 0
panel_pivot_struts = 0
autohide = 0
autohide_show_timeout = 0.3
autohide_hide_timeout = 1.5
autohide_height = 4
strut_policy = follow_size
panel_window_name = tint2
disable_transparency = 0
mouse_effects = 1
font_shadow = 0
mouse_hover_icon_asb = 100 0 10
mouse_pressed_icon_asb = 100 0 -10

#---------------------------------------------
# 런처 (가운데 정렬 아이콘들)
#---------------------------------------------
launcher_padding = 4 4 8
launcher_background_id = 0
launcher_icon_background_id = 3
launcher_icon_size = 32
launcher_icon_asb = 100 0 0
launcher_icon_theme = Adwaita
launcher_icon_theme_override = 1
launcher_tooltip = 1

# 앱 아이콘들
launcher_item_app = /usr/share/applications/marux-menu.desktop
launcher_item_app = /usr/share/applications/xterm.desktop
launcher_item_app = /usr/share/applications/mc.desktop
launcher_item_app = /usr/share/applications/chromium.desktop

#---------------------------------------------
# 태스크바 (실행 중인 창 - Windows 11 스타일)
#---------------------------------------------
taskbar_mode = single_desktop
taskbar_hide_if_empty = 1
taskbar_padding = 4 0 4
taskbar_background_id = 0
taskbar_active_background_id = 0
taskbar_name = 0
taskbar_hide_inactive_tasks = 0
taskbar_hide_different_monitor = 0
taskbar_hide_different_desktop = 0
taskbar_always_show_all_desktop_tasks = 0
taskbar_sort_order = none
task_align = left

# 태스크 버튼 스타일 (아이콘만, 텍스트 없음 - Windows 11처럼)
task_text = 0
task_icon = 1
task_centered = 1
task_maximum_size = 44 40
task_padding = 4 4 4
task_font = Sans 10
task_tooltip = 1
task_thumbnail = 0

# 태스크 색상
task_font_color = #ffffff 100
task_icon_asb = 100 0 0
task_background_id = 3
task_active_background_id = 2
task_urgent_background_id = 2
task_iconified_icon_asb = 80 0 0
task_iconified_background_id = 3

# feh 데스크톱 창 숨기기
wm_class_filter = feh

#---------------------------------------------
# 시스템 트레이 (오른쪽)
#---------------------------------------------
systray_padding = 8 4 8
systray_background_id = 0
systray_sort = ascending
systray_icon_size = 20
systray_icon_asb = 100 0 0
systray_monitor = primary
systray_name_filter =

#---------------------------------------------
# 시계 (오른쪽 끝)
#---------------------------------------------
time1_format = %H:%M
time1_font = Sans Bold 11
time1_timezone =
time2_format = %Y-%m-%d
time2_font = Sans 9
time2_timezone =
clock_font_color = #ffffff 100
clock_padding = 12 4
clock_background_id = 0
clock_tooltip = %A %B %d, %Y
clock_tooltip_timezone =
clock_lclick_command =
clock_rclick_command =
clock_mclick_command =
clock_uwheel_command =
clock_dwheel_command =

#---------------------------------------------
# 툴팁
#---------------------------------------------
tooltip_show_timeout = 0.5
tooltip_hide_timeout = 0.2
tooltip_padding = 8 6
tooltip_background_id = 1
tooltip_font_color = #ffffff 100
tooltip_font = Sans 10

#---------------------------------------------
# 마우스 액션
#---------------------------------------------
mouse_left = toggle_iconify
mouse_middle = close
mouse_right = none
mouse_scroll_up = toggle_iconify
mouse_scroll_down = iconify
EOF

# squashfs 재생성
echo "=== squashfs 생성 ==="
rm -f /home/administrator/MaruxOS/iso-modify/newiso/live/filesystem.squashfs
mksquashfs $ROOTFS /home/administrator/MaruxOS/iso-modify/newiso/live/filesystem.squashfs -comp gzip -noappend

# ISO 생성
echo "=== ISO 생성 ==="
xorriso -as mkisofs \
    -isohybrid-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
    -c boot/boot.cat \
    -b boot/grub/bios.img \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -o /home/administrator/MaruxOS/output/MaruxOS-1.0-67-v15.iso \
    /home/administrator/MaruxOS/iso-modify/newiso

# 정리
umount /home/administrator/MaruxOS/iso-modify/iso 2>/dev/null || true
rm -rf /home/administrator/MaruxOS/iso-modify

echo "=== 완료 ==="
ls -lh /home/administrator/MaruxOS/output/MaruxOS-1.0-67-v15.iso
