#!/bin/bash
# MaruxOS ISO에 Desktop 패키지 추가
# feh, tint2, pcmanfm + 설정

set -e

ISO_FILE=/home/administrator/MaruxOS/output/MaruxOS-1.0-Phoenix-v24.iso
WORK_DIR=/home/administrator/MaruxOS/iso-modify
OUTPUT_ISO=/home/administrator/MaruxOS/output/MaruxOS-1.0-Phoenix-v25.iso

log() {
    echo "[$(date '+%H:%M:%S')] $1"
}

log "=== MaruxOS Desktop Enhancement 시작 ==="

# 작업 디렉토리 준비
rm -rf $WORK_DIR
mkdir -p $WORK_DIR/{iso,squashfs,newiso}

# ISO 마운트
log "ISO 마운트 중..."
mount -o loop $ISO_FILE $WORK_DIR/iso

# ISO 내용 복사
log "ISO 내용 복사 중..."
cp -a $WORK_DIR/iso/* $WORK_DIR/newiso/

# squashfs 압축 해제
log "squashfs 압축 해제 중..."
SQUASHFS_FILE=$(find $WORK_DIR/newiso -name "*.squashfs" -o -name "filesystem.squashfs" 2>/dev/null | head -1)
if [ -z "$SQUASHFS_FILE" ]; then
    SQUASHFS_FILE=$(find $WORK_DIR/newiso -name "*.sfs" 2>/dev/null | head -1)
fi

if [ -z "$SQUASHFS_FILE" ]; then
    log "ERROR: squashfs 파일을 찾을 수 없습니다"
    ls -laR $WORK_DIR/newiso/
    exit 1
fi

log "Found squashfs: $SQUASHFS_FILE"
unsquashfs -d $WORK_DIR/squashfs "$SQUASHFS_FILE"

# Desktop 앱 복사
log "=== Desktop Applications 복사 ==="

ROOTFS=$WORK_DIR/squashfs

# 디렉토리 준비
mkdir -p $ROOTFS/usr/bin
mkdir -p $ROOTFS/usr/lib
mkdir -p $ROOTFS/etc/xdg/{openbox,tint2,pcmanfm/default,libfm}
mkdir -p $ROOTFS/usr/share/{applications,backgrounds,icons,tint2,pcmanfm,libfm,mime}
mkdir -p $ROOTFS/root/Desktop

# feh 복사
log "feh 복사..."
cp /usr/bin/feh $ROOTFS/usr/bin/

# tint2 복사
log "tint2 복사..."
cp /usr/bin/tint2 $ROOTFS/usr/bin/
[ -f /usr/bin/tint2conf ] && cp /usr/bin/tint2conf $ROOTFS/usr/bin/

# pcmanfm 복사
log "pcmanfm 복사..."
cp /usr/bin/pcmanfm $ROOTFS/usr/bin/

# 필요한 라이브러리 복사 함수
copy_lib_deps() {
    local binary=$1
    ldd "$binary" 2>/dev/null | grep "=>" | awk '{print $3}' | while read lib; do
        if [ -f "$lib" ]; then
            local libname=$(basename "$lib")
            if [ ! -f "$ROOTFS/usr/lib/$libname" ] && [ ! -f "$ROOTFS/lib/$libname" ]; then
                cp -f "$lib" "$ROOTFS/usr/lib/" 2>/dev/null || true
            fi
        fi
    done
}

log "라이브러리 의존성 복사..."
copy_lib_deps /usr/bin/feh
copy_lib_deps /usr/bin/tint2
copy_lib_deps /usr/bin/pcmanfm

# 추가 라이브러리
for lib in /usr/lib/x86_64-linux-gnu/libImlib2.so* \
           /usr/lib/x86_64-linux-gnu/libfm*.so* \
           /usr/lib/x86_64-linux-gnu/libmenu-cache*.so*; do
    [ -f "$lib" ] && cp -af "$lib" "$ROOTFS/usr/lib/" 2>/dev/null || true
done

# 배경화면 복사
log "배경화면 복사..."
cp /home/administrator/MaruxOS/assets/wallpapers/marux-desktop.png $ROOTFS/usr/share/backgrounds/
cp /home/administrator/MaruxOS/assets/wallpapers/marux-login.png $ROOTFS/usr/share/backgrounds/

# Openbox autostart 설정
log "Openbox autostart 설정..."
cat > $ROOTFS/etc/xdg/openbox/autostart << 'EOF'
#!/bin/bash
# MaruxOS Desktop Autostart

# 배경화면 설정 (pcmanfm이 관리)
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
log "tint2 설정..."
cat > $ROOTFS/etc/xdg/tint2/tint2rc << 'EOF'
# MaruxOS tint2 Panel
panel_items = LTSC
panel_size = 100% 40
panel_margin = 0 0
panel_padding = 8 4 8
panel_position = bottom center horizontal
panel_layer = top
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
task_maximum_size = 200 35
task_padding = 6 3 6
task_font = Sans 10
task_font_color = #ffffff 100
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
EOF

# PCManFM 바탕화면 설정
log "PCManFM 설정..."
cat > $ROOTFS/etc/xdg/pcmanfm/default/desktop-items-0.conf << 'EOF'
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
EOF

cat > $ROOTFS/etc/xdg/pcmanfm/default/pcmanfm.conf << 'EOF'
[config]
bm_open_method=0

[volume]
mount_on_startup=1
mount_removable=1

[ui]
always_show_tabs=0
win_width=800
win_height=600
view_mode=icon
show_hidden=0
sort=name;ascending;
EOF

# 바탕화면 아이콘
log "바탕화면 아이콘 생성..."
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

# squashfs 재압축
log "squashfs 재압축 중..."
rm -f "$SQUASHFS_FILE"
mksquashfs $ROOTFS "$SQUASHFS_FILE" -comp xz -b 1M

# ISO 재생성
log "ISO 재생성 중..."
umount $WORK_DIR/iso

# ISO 생성
cd $WORK_DIR/newiso
xorriso -as mkisofs \
    -o $OUTPUT_ISO \
    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
    -c isolinux/boot.cat \
    -b isolinux/isolinux.bin \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -eltorito-alt-boot \
    -e boot/grub/efi.img \
    -no-emul-boot \
    -isohybrid-gpt-basdat \
    -V "MaruxOS" \
    .

log "=== 완료: $OUTPUT_ISO ==="
ls -lh $OUTPUT_ISO

# 정리
rm -rf $WORK_DIR
