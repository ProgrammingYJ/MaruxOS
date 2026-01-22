#!/bin/bash
# MaruxOS Desktop Environment Setup
# 배경화면, tint2 패널, 바탕화면 시스템 설정

set -e

LFS=/home/administrator/MaruxOS/lfs
MARUX_DIR=/home/administrator/MaruxOS
LOG=$MARUX_DIR/desktop-setup.log

log() {
    echo "[$(date '+%H:%M:%S')] $1" | tee -a $LOG
}

log "=== MaruxOS 데스크톱 환경 설정 시작 ==="

# ============================================
# 1. 필수 디렉토리 생성
# ============================================
log "디렉토리 생성 중..."
mkdir -p $LFS/etc/xdg/openbox
mkdir -p $LFS/etc/xdg/tint2
mkdir -p $LFS/etc/xdg/pcmanfm/default
mkdir -p $LFS/usr/share/backgrounds
mkdir -p $LFS/usr/share/applications
mkdir -p $LFS/usr/share/icons/hicolor/48x48/apps
mkdir -p $LFS/root/Desktop
mkdir -p $LFS/home

# ============================================
# 2. 배경화면 복사
# ============================================
log "배경화면 설정 중..."
cp $MARUX_DIR/assets/wallpapers/marux-desktop.png $LFS/usr/share/backgrounds/
cp $MARUX_DIR/assets/wallpapers/marux-login.png $LFS/usr/share/backgrounds/

# ============================================
# 3. Openbox Autostart 설정
# ============================================
log "Openbox autostart 설정 중..."
cat > $LFS/etc/xdg/openbox/autostart << 'AUTOSTART_EOF'
#!/bin/bash
# MaruxOS Openbox Autostart

# 배경화면 설정
if [ -f /usr/bin/feh ]; then
    feh --bg-scale /usr/share/backgrounds/marux-desktop.png &
elif [ -f /usr/bin/pcmanfm ]; then
    # pcmanfm이 배경화면 관리
    :
fi

# 바탕화면 아이콘 (pcmanfm --desktop)
if [ -f /usr/bin/pcmanfm ]; then
    pcmanfm --desktop &
fi

# tint2 패널 시작
if [ -f /usr/bin/tint2 ]; then
    sleep 1
    tint2 &
fi

# 볼륨 컨트롤 (있으면)
if [ -f /usr/bin/volumeicon ]; then
    volumeicon &
fi

# 네트워크 매니저 (있으면)
if [ -f /usr/bin/nm-applet ]; then
    nm-applet &
fi
AUTOSTART_EOF
chmod +x $LFS/etc/xdg/openbox/autostart

# ============================================
# 4. Openbox rc.xml 메뉴 설정
# ============================================
log "Openbox 메뉴 설정 중..."
cat > $LFS/etc/xdg/openbox/rc.xml << 'RCXML_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_config xmlns="http://openbox.org/3.4/rc">
  <resistance>
    <strength>10</strength>
    <screen_edge_strength>20</screen_edge_strength>
  </resistance>
  <focus>
    <focusNew>yes</focusNew>
    <followMouse>no</followMouse>
    <focusLast>yes</focusLast>
    <underMouse>no</underMouse>
    <focusDelay>200</focusDelay>
    <raiseOnFocus>no</raiseOnFocus>
  </focus>
  <placement>
    <policy>Smart</policy>
    <center>yes</center>
    <monitor>Primary</monitor>
    <primaryMonitor>1</primaryMonitor>
  </placement>
  <theme>
    <name>Clearlooks</name>
    <titleLayout>NLIMC</titleLayout>
    <keepBorder>yes</keepBorder>
    <animateIconify>yes</animateIconify>
    <font place="ActiveWindow">
      <name>Sans</name>
      <size>10</size>
      <weight>Bold</weight>
      <slant>Normal</slant>
    </font>
    <font place="InactiveWindow">
      <name>Sans</name>
      <size>10</size>
      <weight>Normal</weight>
      <slant>Normal</slant>
    </font>
  </theme>
  <desktops>
    <number>4</number>
    <firstdesk>1</firstdesk>
    <names>
      <name>Desktop 1</name>
      <name>Desktop 2</name>
      <name>Desktop 3</name>
      <name>Desktop 4</name>
    </names>
    <popupTime>875</popupTime>
  </desktops>
  <resize>
    <drawContents>yes</drawContents>
    <popupShow>Nonpixel</popupShow>
    <popupPosition>Center</popupPosition>
    <popupFixedPosition>
      <x>10</x>
      <y>10</y>
    </popupFixedPosition>
  </resize>
  <keyboard>
    <keybind key="A-F4">
      <action name="Close"/>
    </keybind>
    <keybind key="A-Tab">
      <action name="NextWindow"/>
    </keybind>
    <keybind key="A-S-Tab">
      <action name="PreviousWindow"/>
    </keybind>
    <keybind key="W-d">
      <action name="ToggleShowDesktop"/>
    </keybind>
    <keybind key="W-e">
      <action name="Execute">
        <command>pcmanfm</command>
      </action>
    </keybind>
    <keybind key="W-t">
      <action name="Execute">
        <command>maruxos-terminal</command>
      </action>
    </keybind>
    <keybind key="Print">
      <action name="Execute">
        <command>scrot</command>
      </action>
    </keybind>
  </keyboard>
  <mouse>
    <dragThreshold>8</dragThreshold>
    <doubleClickTime>200</doubleClickTime>
    <screenEdgeWarpTime>400</screenEdgeWarpTime>
    <context name="Desktop">
      <mousebind button="Right" action="Press">
        <action name="ShowMenu">
          <menu>root-menu</menu>
        </action>
      </mousebind>
    </context>
    <context name="Titlebar">
      <mousebind button="Left" action="Drag">
        <action name="Move"/>
      </mousebind>
      <mousebind button="Left" action="DoubleClick">
        <action name="ToggleMaximize"/>
      </mousebind>
    </context>
    <context name="Frame">
      <mousebind button="A-Left" action="Drag">
        <action name="Move"/>
      </mousebind>
      <mousebind button="A-Right" action="Drag">
        <action name="Resize"/>
      </mousebind>
    </context>
  </mouse>
  <menu>
    <file>menu.xml</file>
    <hideDelay>200</hideDelay>
    <middle>no</middle>
    <submenuShowDelay>100</submenuShowDelay>
    <submenuHideDelay>400</submenuHideDelay>
    <applicationIcons>yes</applicationIcons>
    <manageDesktops>yes</manageDesktops>
  </menu>
</openbox_config>
RCXML_EOF

# ============================================
# 5. Openbox 메뉴 (우클릭 메뉴)
# ============================================
log "Openbox 우클릭 메뉴 설정 중..."
cat > $LFS/etc/xdg/openbox/menu.xml << 'MENU_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_menu xmlns="http://openbox.org/3.4/menu">
  <menu id="root-menu" label="MaruxOS">
    <item label="Terminal">
      <action name="Execute">
        <command>maruxos-terminal</command>
      </action>
    </item>
    <item label="File Manager">
      <action name="Execute">
        <command>pcmanfm</command>
      </action>
    </item>
    <item label="Web Browser">
      <action name="Execute">
        <command>firefox</command>
      </action>
    </item>
    <separator/>
    <menu id="apps-menu" label="Applications">
      <menu id="apps-accessories" label="Accessories">
        <item label="Text Editor">
          <action name="Execute">
            <command>leafpad</command>
          </action>
        </item>
        <item label="Calculator">
          <action name="Execute">
            <command>galculator</command>
          </action>
        </item>
      </menu>
      <menu id="apps-system" label="System">
        <item label="Task Manager">
          <action name="Execute">
            <command>lxtask</command>
          </action>
        </item>
      </menu>
    </menu>
    <separator/>
    <menu id="settings-menu" label="Settings">
      <item label="Openbox Configuration">
        <action name="Execute">
          <command>obconf</command>
        </action>
      </item>
      <item label="Panel Settings">
        <action name="Execute">
          <command>tint2conf</command>
        </action>
      </item>
      <item label="Wallpaper">
        <action name="Execute">
          <command>pcmanfm --wallpaper-mode=desktop-settings</command>
        </action>
      </item>
    </menu>
    <separator/>
    <item label="Reconfigure">
      <action name="Reconfigure"/>
    </item>
    <separator/>
    <item label="Log Out">
      <action name="Exit"/>
    </item>
    <item label="Reboot">
      <action name="Execute">
        <command>systemctl reboot</command>
      </action>
    </item>
    <item label="Shutdown">
      <action name="Execute">
        <command>systemctl poweroff</command>
      </action>
    </item>
  </menu>
</openbox_menu>
MENU_EOF

# ============================================
# 6. tint2 설정 복사
# ============================================
log "tint2 패널 설정 중..."
if [ -f $MARUX_DIR/config/tint2/tint2rc ]; then
    cp $MARUX_DIR/config/tint2/tint2rc $LFS/etc/xdg/tint2/
fi

# 기본 tint2 설정 (백업용)
cat > $LFS/etc/xdg/tint2/tint2rc << 'TINT2_EOF'
# MaruxOS tint2 Panel - Default Config
panel_items = LTSC
panel_size = 100% 40
panel_margin = 0 0
panel_padding = 8 4 8
panel_position = bottom center horizontal
panel_layer = top
panel_dock = 0
panel_monitor = all
autohide = 0

# Panel background
rounded = 0
border_width = 0
background_color = #1a1a2e 90
border_color = #16213e 100

# Taskbar
taskbar_mode = single_desktop
taskbar_padding = 4 2 4
task_text = 1
task_icon = 1
task_centered = 0
task_maximum_size = 200 35
task_padding = 6 3 6
task_font = Sans 10
task_font_color = #ffffff 100
task_icon_asb = 100 0 0
task_active_font_color = #ffffff 100

# System tray
systray_padding = 4 4 4
systray_icon_size = 22

# Clock
time1_format = %H:%M
time1_font = Sans Bold 11
time2_format = %Y-%m-%d
time2_font = Sans 9
clock_font_color = #ffffff 100
clock_padding = 8 4
TINT2_EOF

# ============================================
# 7. PCManFM 설정 (바탕화면 모드)
# ============================================
log "PCManFM 바탕화면 설정 중..."
cat > $LFS/etc/xdg/pcmanfm/default/desktop-items-0.conf << 'PCMANFM_DESKTOP_EOF'
[*]
wallpaper_mode=stretch
wallpaper_common=1
wallpaper=/usr/share/backgrounds/marux-desktop.png
desktop_bg=#1a1a2e
desktop_fg=#ffffff
desktop_shadow=#000000
desktop_font=Sans 11
show_wm_menu=0
sort=mtime;ascending;
show_documents=0
show_trash=1
show_mounts=1
PCMANFM_DESKTOP_EOF

cat > $LFS/etc/xdg/pcmanfm/default/pcmanfm.conf << 'PCMANFM_CONF_EOF'
[config]
bm_open_method=0
su_cmd=sudo %s

[volume]
mount_on_startup=1
mount_removable=1
autorun=1

[ui]
always_show_tabs=0
max_tab_chars=32
win_width=800
win_height=600
splitter_pos=150
media_in_new_tab=0
desktop_folder_new_win=0
change_tab_on_drop=1
close_on_unmount=1
focus_previous=0
side_pane_mode=places
view_mode=icon
show_hidden=0
sort=name;ascending;
columns=name:200;desc;size;mtime;
toolbar=newtab;navigation;home;
show_statusbar=1
pathbar_mode_buttons=0
PCMANFM_CONF_EOF

# ============================================
# 8. 바탕화면 아이콘 생성
# ============================================
log "바탕화면 아이콘 생성 중..."

# 홈 폴더 아이콘
cat > $LFS/root/Desktop/Home.desktop << 'DESKTOP_EOF'
[Desktop Entry]
Type=Application
Name=Home
Comment=Open Home Folder
Exec=pcmanfm ~
Icon=user-home
Terminal=false
Categories=System;FileManager;
DESKTOP_EOF

# 터미널 아이콘
cat > $LFS/root/Desktop/Terminal.desktop << 'DESKTOP_EOF'
[Desktop Entry]
Type=Application
Name=Terminal
Comment=Open Terminal
Exec=maruxos-terminal
Icon=utilities-terminal
Terminal=false
Categories=System;TerminalEmulator;
DESKTOP_EOF

# 파일 매니저 아이콘
cat > $LFS/root/Desktop/Files.desktop << 'DESKTOP_EOF'
[Desktop Entry]
Type=Application
Name=Files
Comment=File Manager
Exec=pcmanfm
Icon=system-file-manager
Terminal=false
Categories=System;FileManager;
DESKTOP_EOF

chmod +x $LFS/root/Desktop/*.desktop

# ============================================
# 9. .desktop 애플리케이션 파일
# ============================================
log "애플리케이션 .desktop 파일 생성 중..."

# maruxos-menu.desktop
if [ -f $MARUX_DIR/config/applications/maruxos-menu.desktop ]; then
    cp $MARUX_DIR/config/applications/maruxos-menu.desktop $LFS/usr/share/applications/
fi

# Terminal
cat > $LFS/usr/share/applications/maruxos-terminal.desktop << 'DESKTOP_EOF'
[Desktop Entry]
Type=Application
Name=MaruxOS Terminal
Comment=Terminal Emulator
Exec=maruxos-terminal
Icon=utilities-terminal
Terminal=false
Categories=System;TerminalEmulator;
DESKTOP_EOF

# File Manager
cat > $LFS/usr/share/applications/pcmanfm.desktop << 'DESKTOP_EOF'
[Desktop Entry]
Type=Application
Name=File Manager
Comment=Browse the file system
Exec=pcmanfm %U
Icon=system-file-manager
Terminal=false
Categories=System;FileManager;
MimeType=inode/directory;
DESKTOP_EOF

log "=== 데스크톱 환경 설정 완료 ==="
log "다음 단계: build-desktop-extras.sh 실행하여 feh, tint2, pcmanfm 빌드"
