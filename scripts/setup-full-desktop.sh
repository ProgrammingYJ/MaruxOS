#!/bin/bash
# Full desktop setup - Openbox + tint2 + pcmanfm + feh

ROOTFS=/home/administrator/MaruxOS/iso-modify/squashfs

echo "=== 1. Openbox 복사 ==="
cp /usr/bin/openbox $ROOTFS/usr/bin/
cp /usr/bin/openbox-session $ROOTFS/usr/bin/
chmod +x $ROOTFS/usr/bin/openbox*

# Openbox 라이브러리
for lib in $(ldd /usr/bin/openbox | grep "=>" | awk '{print $3}'); do
    if [ -f "$lib" ]; then
        libname=$(basename "$lib")
        [ ! -f "$ROOTFS/usr/lib/$libname" ] && cp -f "$lib" "$ROOTFS/usr/lib/" 2>/dev/null
    fi
done

# Openbox 설정
mkdir -p $ROOTFS/etc/xdg/openbox
cp -r /etc/xdg/openbox/* $ROOTFS/etc/xdg/openbox/ 2>/dev/null || true

echo "=== 2. Desktop apps 복사 ==="
cp /usr/bin/feh $ROOTFS/usr/bin/
cp /usr/bin/tint2 $ROOTFS/usr/bin/
cp /usr/bin/pcmanfm $ROOTFS/usr/bin/

for binary in /usr/bin/feh /usr/bin/tint2 /usr/bin/pcmanfm; do
    for lib in $(ldd $binary 2>/dev/null | grep "=>" | awk '{print $3}'); do
        if [ -f "$lib" ]; then
            libname=$(basename "$lib")
            [ ! -f "$ROOTFS/usr/lib/$libname" ] && cp -f "$lib" "$ROOTFS/usr/lib/" 2>/dev/null
        fi
    done
done

# 추가 라이브러리
for pattern in /usr/lib/x86_64-linux-gnu/libImlib2.so* \
               /usr/lib/x86_64-linux-gnu/libfm*.so* \
               /usr/lib/x86_64-linux-gnu/libmenu-cache*.so* \
               /usr/lib/x86_64-linux-gnu/libobrender*.so* \
               /usr/lib/x86_64-linux-gnu/libobt*.so*; do
    for lib in $pattern; do
        [ -f "$lib" ] && cp -af "$lib" "$ROOTFS/usr/lib/" 2>/dev/null
    done
done

echo "=== 3. 배경화면 ==="
mkdir -p $ROOTFS/usr/share/backgrounds
cp /home/administrator/MaruxOS/assets/wallpapers/marux-desktop.png $ROOTFS/usr/share/backgrounds/

echo "=== 4. xinitrc 설정 ==="
mkdir -p $ROOTFS/etc/X11/xinit
cat > $ROOTFS/etc/X11/xinit/xinitrc << 'XINITRC'
#!/bin/sh
# MaruxOS Desktop Session

# D-Bus
if [ -x /usr/bin/dbus-launch ]; then
    eval $(dbus-launch --sh-syntax)
    export DBUS_SESSION_BUS_ADDRESS
fi

export DISPLAY=:0

# Openbox 실행 (메인 프로세스)
exec openbox --config-file /etc/xdg/openbox/rc.xml
XINITRC
chmod +x $ROOTFS/etc/X11/xinit/xinitrc

echo "=== 5. Openbox autostart ==="
cat > $ROOTFS/etc/xdg/openbox/autostart << 'AUTOSTART'
#!/bin/bash
# MaruxOS Desktop - Autostart

# 배경화면
feh --bg-scale /usr/share/backgrounds/marux-desktop.png &

# 바탕화면 아이콘 (pcmanfm desktop mode)
sleep 0.5
pcmanfm --desktop &

# tint2 패널 (하단 태스크바)
sleep 1
tint2 &

# 터미널 하나 실행
sleep 1.5
maruxos-terminal &
AUTOSTART
chmod +x $ROOTFS/etc/xdg/openbox/autostart

echo "=== 6. Openbox rc.xml (기본 설정) ==="
cat > $ROOTFS/etc/xdg/openbox/rc.xml << 'RCXML'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_config xmlns="http://openbox.org/3.4/rc">
  <resistance><strength>10</strength></resistance>
  <focus>
    <focusNew>yes</focusNew>
    <followMouse>no</followMouse>
  </focus>
  <placement><policy>Smart</policy></placement>
  <theme><name>Clearlooks</name></theme>
  <desktops><number>4</number></desktops>
  <keyboard>
    <keybind key="A-F4"><action name="Close"/></keybind>
    <keybind key="A-Tab"><action name="NextWindow"/></keybind>
  </keyboard>
  <mouse>
    <context name="Desktop">
      <mousebind button="Right" action="Press">
        <action name="ShowMenu"><menu>root-menu</menu></action>
      </mousebind>
    </context>
    <context name="Titlebar">
      <mousebind button="Left" action="Drag"><action name="Move"/></mousebind>
      <mousebind button="Left" action="DoubleClick"><action name="ToggleMaximize"/></mousebind>
    </context>
  </mouse>
  <menu><file>menu.xml</file></menu>
</openbox_config>
RCXML

echo "=== 7. Openbox menu.xml (우클릭 메뉴) ==="
cat > $ROOTFS/etc/xdg/openbox/menu.xml << 'MENUXML'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_menu xmlns="http://openbox.org/3.4/menu">
  <menu id="root-menu" label="MaruxOS">
    <item label="Terminal"><action name="Execute"><command>maruxos-terminal</command></action></item>
    <item label="File Manager"><action name="Execute"><command>pcmanfm</command></action></item>
    <separator/>
    <item label="Reconfigure"><action name="Reconfigure"/></item>
    <item label="Log Out"><action name="Exit"/></item>
  </menu>
</openbox_menu>
MENUXML

echo "=== 8. tint2 설정 ==="
mkdir -p $ROOTFS/etc/xdg/tint2
cat > $ROOTFS/etc/xdg/tint2/tint2rc << 'TINT2RC'
panel_items = LTSC
panel_size = 100% 40
panel_position = bottom center horizontal
panel_layer = top
panel_monitor = all
autohide = 0
rounded = 0
background_color = #1a1a2e 90
taskbar_mode = single_desktop
task_text = 1
task_icon = 1
task_maximum_size = 200 35
task_font = Sans 10
task_font_color = #ffffff 100
systray_padding = 4 4 4
systray_icon_size = 22
time1_format = %H:%M
time1_font = Sans Bold 11
time2_format = %Y-%m-%d
time2_font = Sans 9
clock_font_color = #ffffff 100
TINT2RC

echo "=== 9. PCManFM 바탕화면 설정 ==="
mkdir -p $ROOTFS/etc/xdg/pcmanfm/default
cat > $ROOTFS/etc/xdg/pcmanfm/default/desktop-items-0.conf << 'PCMANFM'
[*]
wallpaper_mode=stretch
wallpaper=/usr/share/backgrounds/marux-desktop.png
desktop_bg=#1a1a2e
desktop_fg=#ffffff
show_trash=1
show_mounts=1
PCMANFM

echo "=== 10. 바탕화면 아이콘 ==="
mkdir -p $ROOTFS/root/Desktop
cat > $ROOTFS/root/Desktop/Terminal.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Terminal
Exec=maruxos-terminal
Icon=utilities-terminal
EOF

cat > $ROOTFS/root/Desktop/Files.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Files
Exec=pcmanfm
Icon=system-file-manager
EOF
chmod +x $ROOTFS/root/Desktop/*.desktop

echo "=== 완료 ==="
ls -la $ROOTFS/usr/bin/{openbox,feh,tint2,pcmanfm}
