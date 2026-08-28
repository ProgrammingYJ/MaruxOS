#!/bin/bash
# 67-v10 - 아이콘 테마 + Openbox 윈도우 버튼 수정

rm -rf /home/administrator/MaruxOS/iso-modify
mkdir -p /home/administrator/MaruxOS/iso-modify/{iso,squashfs,newiso}
mount -o loop /home/administrator/MaruxOS/output/MaruxOS-1.0-67-v9.iso /home/administrator/MaruxOS/iso-modify/iso
cp -a /home/administrator/MaruxOS/iso-modify/iso/* /home/administrator/MaruxOS/iso-modify/newiso/
unsquashfs -d /home/administrator/MaruxOS/iso-modify/squashfs /home/administrator/MaruxOS/iso-modify/newiso/live/filesystem.squashfs

ROOTFS=/home/administrator/MaruxOS/iso-modify/squashfs

# 1. Openbox 테마 수정 (윈도우 버튼 포함)
echo "=== Openbox 테마 수정 ==="
mkdir -p $ROOTFS/usr/share/themes/Clearlooks-Phenix/openbox-3

# Clearlooks 스타일 themerc 생성 (버튼 포함)
cat > $ROOTFS/usr/share/themes/Clearlooks-Phenix/openbox-3/themerc << 'EOF'
# Clearlooks-Phenix Openbox Theme

# Window geometry
padding.width: 4
padding.height: 4
border.width: 1
window.client.padding.width: 0
window.client.padding.height: 0
window.handle.width: 0

# Title bar
window.active.title.bg: flat gradient vertical
window.active.title.bg.color: #4a90d9
window.active.title.bg.colorTo: #3c7fc4
window.inactive.title.bg: flat gradient vertical
window.inactive.title.bg.color: #808080
window.inactive.title.bg.colorTo: #6a6a6a

# Title text
window.active.label.bg: parentrelative
window.active.label.text.color: #ffffff
window.active.label.text.font: shadow=y:shadowtint=30:shadowoffset=1
window.inactive.label.bg: parentrelative
window.inactive.label.text.color: #d0d0d0

# Buttons
window.active.button.unpressed.bg: flat gradient vertical
window.active.button.unpressed.bg.color: #5a9fe0
window.active.button.unpressed.bg.colorTo: #4a8fd0
window.active.button.unpressed.image.color: #ffffff

window.active.button.hover.bg: flat gradient vertical
window.active.button.hover.bg.color: #6ab0f0
window.active.button.hover.bg.colorTo: #5aa0e0
window.active.button.hover.image.color: #ffffff

window.active.button.pressed.bg: flat gradient vertical
window.active.button.pressed.bg.color: #3a7fc0
window.active.button.pressed.bg.colorTo: #2a6fb0
window.active.button.pressed.image.color: #ffffff

window.active.button.disabled.bg: flat solid
window.active.button.disabled.bg.color: #4a90d9
window.active.button.disabled.image.color: #888888

window.inactive.button.unpressed.bg: flat gradient vertical
window.inactive.button.unpressed.bg.color: #909090
window.inactive.button.unpressed.bg.colorTo: #808080
window.inactive.button.unpressed.image.color: #d0d0d0

window.inactive.button.hover.bg: flat gradient vertical
window.inactive.button.hover.bg.color: #a0a0a0
window.inactive.button.hover.bg.colorTo: #909090
window.inactive.button.hover.image.color: #ffffff

window.inactive.button.pressed.bg: flat gradient vertical
window.inactive.button.pressed.bg.color: #707070
window.inactive.button.pressed.bg.colorTo: #606060
window.inactive.button.pressed.image.color: #ffffff

# Close button (red on hover)
window.active.button.close.hover.bg: flat gradient vertical
window.active.button.close.hover.bg.color: #e04040
window.active.button.close.hover.bg.colorTo: #c03030
window.active.button.close.hover.image.color: #ffffff

window.active.button.close.pressed.bg: flat gradient vertical
window.active.button.close.pressed.bg.color: #b02020
window.active.button.close.pressed.bg.colorTo: #901010
window.active.button.close.pressed.image.color: #ffffff

# Border
window.active.border.color: #3a7fc0
window.inactive.border.color: #505050

# Menu
menu.title.bg: flat gradient vertical
menu.title.bg.color: #4a90d9
menu.title.bg.colorTo: #3c7fc4
menu.title.text.color: #ffffff
menu.title.text.font: shadow=y:shadowtint=30:shadowoffset=1

menu.items.bg: flat solid
menu.items.bg.color: #f5f5f5
menu.items.text.color: #000000
menu.items.disabled.text.color: #888888

menu.items.active.bg: flat gradient vertical
menu.items.active.bg.color: #4a90d9
menu.items.active.bg.colorTo: #3c7fc4
menu.items.active.text.color: #ffffff

menu.separator.color: #d0d0d0
menu.separator.width: 1
menu.separator.padding.width: 6
menu.separator.padding.height: 3

# OSD
osd.bg: flat solid
osd.bg.color: #f5f5f5
osd.label.text.color: #000000
EOF

# Openbox rc.xml에 버튼 레이아웃 설정
echo "=== Openbox rc.xml 설정 ==="
mkdir -p $ROOTFS/etc/xdg/openbox
cat > $ROOTFS/etc/xdg/openbox/rc.xml << 'RCEOF'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_config xmlns="http://openbox.org/3.4/rc">
  <theme>
    <name>Clearlooks-Phenix</name>
    <titleLayout>NLIMC</titleLayout>
    <keepBorder>yes</keepBorder>
    <font place="ActiveWindow">
      <name>Sans</name>
      <size>10</size>
      <weight>Bold</weight>
    </font>
    <font place="InactiveWindow">
      <name>Sans</name>
      <size>10</size>
      <weight>Bold</weight>
    </font>
  </theme>
  <desktops>
    <number>1</number>
    <firstdesk>1</firstdesk>
  </desktops>
  <resize>
    <drawContents>yes</drawContents>
  </resize>
  <keyboard>
    <keybind key="A-F4">
      <action name="Close"/>
    </keybind>
    <keybind key="A-Tab">
      <action name="NextWindow"/>
    </keybind>
  </keyboard>
  <mouse>
    <context name="Titlebar">
      <mousebind button="Left" action="Press">
        <action name="Focus"/>
        <action name="Raise"/>
      </mousebind>
      <mousebind button="Left" action="Drag">
        <action name="Move"/>
      </mousebind>
      <mousebind button="Left" action="DoubleClick">
        <action name="ToggleMaximize"/>
      </mousebind>
    </context>
    <context name="Close">
      <mousebind button="Left" action="Click">
        <action name="Close"/>
      </mousebind>
    </context>
    <context name="Maximize">
      <mousebind button="Left" action="Click">
        <action name="ToggleMaximize"/>
      </mousebind>
    </context>
    <context name="Iconify">
      <mousebind button="Left" action="Click">
        <action name="Iconify"/>
      </mousebind>
    </context>
    <context name="Client">
      <mousebind button="Left" action="Press">
        <action name="Focus"/>
        <action name="Raise"/>
      </mousebind>
    </context>
    <context name="Frame">
      <mousebind button="Left" action="Press">
        <action name="Focus"/>
        <action name="Raise"/>
      </mousebind>
    </context>
    <context name="Desktop">
      <mousebind button="Right" action="Press">
        <action name="ShowMenu">
          <menu>root-menu</menu>
        </action>
      </mousebind>
    </context>
    <context name="Root">
      <mousebind button="Right" action="Press">
        <action name="ShowMenu">
          <menu>root-menu</menu>
        </action>
      </mousebind>
    </context>
  </mouse>
</openbox_config>
RCEOF

# 2. 아이콘 테마 설치
echo "=== 아이콘 테마 설치 ==="
mkdir -p $ROOTFS/usr/share/icons/hicolor/{16x16,24x24,48x48}/{apps,places,devices,actions,categories}

# 기본 아이콘 심볼릭 PNG 생성 (간단한 placeholder)
# tint2가 아이콘을 찾을 수 있도록 기본 아이콘 설정

# Adwaita 아이콘 복사 (주요 아이콘만)
if [ -d /usr/share/icons/Adwaita ]; then
    cp -r /usr/share/icons/Adwaita $ROOTFS/usr/share/icons/ 2>/dev/null
fi

# hicolor 아이콘 복사
if [ -d /usr/share/icons/hicolor ]; then
    cp -r /usr/share/icons/hicolor/* $ROOTFS/usr/share/icons/hicolor/ 2>/dev/null
fi

# gnome 아이콘 (일부)
if [ -d /usr/share/icons/gnome ]; then
    cp -r /usr/share/icons/gnome $ROOTFS/usr/share/icons/ 2>/dev/null
fi

# GTK 설정
mkdir -p $ROOTFS/etc/gtk-3.0
cat > $ROOTFS/etc/gtk-3.0/settings.ini << 'EOF'
[Settings]
gtk-icon-theme-name=Adwaita
gtk-theme-name=Adwaita
gtk-font-name=Sans 10
EOF

mkdir -p $ROOTFS/etc/gtk-2.0
cat > $ROOTFS/etc/gtk-2.0/gtkrc << 'EOF'
gtk-icon-theme-name="Adwaita"
gtk-theme-name="Adwaita"
gtk-font-name="Sans 10"
EOF

# tint2 설정 업데이트
echo "=== tint2 설정 업데이트 ==="
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
launcher_icon_theme = Adwaita
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

echo "=== squashfs 생성 ==="
rm -f /home/administrator/MaruxOS/iso-modify/newiso/live/filesystem.squashfs
mksquashfs $ROOTFS /home/administrator/MaruxOS/iso-modify/newiso/live/filesystem.squashfs -comp gzip -b 131072

umount /home/administrator/MaruxOS/iso-modify/iso 2>/dev/null

echo "=== ISO 생성 ==="
cd /home/administrator/MaruxOS/iso-modify/newiso
xorriso -as mkisofs -o /home/administrator/MaruxOS/output/MaruxOS-1.0-67-v10.iso \
    -r -V 'MARUXOS' -J -joliet-long \
    -isohybrid-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
    -partition_offset 16 -b boot/grub/bios.img -c boot.catalog \
    -no-emul-boot -boot-load-size 4 -boot-info-table .

echo "=== 완료 ==="
ls -lh /home/administrator/MaruxOS/output/MaruxOS-1.0-67-v10.iso
rm -rf /home/administrator/MaruxOS/iso-modify
