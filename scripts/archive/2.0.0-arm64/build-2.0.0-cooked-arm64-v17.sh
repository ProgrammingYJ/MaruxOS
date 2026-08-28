#!/bin/bash
###############################################################################
# MaruxOS 2.0.0 "Cooked" — ARM64 이미지 빌드 v17 (bamf 진짜 픽스: libwnck 43.2 + clock-only)
#
# v16 대비 변경 (2026-08-14 근원 수사 + 실기기 검증 완료분 박제):
#   ① **libwnck 43.0 → 43.2** — v16의 bamf 픽스(SN 재빌드)는 오진이었음. 진짜 근원 =
#      43.0 업스트림 버그(invalidate_icons에 screens 배열 NULL 가드 누락 → bamf가
#      스크린 생성 전 set_default_icon_size 호출 시 즉사). 43.0↔43.2 소스 diff로
#      업스트림 픽스 확인 후 채택. **시리얼 무플래시 배포(gzip+b64, MD5검증)로
#      실기기 선검증 완료**: bamfdaemon 가동 + 독 실행 점 + 실행 중 앱 클릭 창전환 ✅
#   ② **tint2 clock-only** (config v8) — panel_items C + 100px, 윈도우식 우하단 밀착
#      시계(빈 systray 공간 제거, 실기기 확정). 트레이 역할=추후 우상단 퀵설정 바.
#   🐛 미탑재(알려진 버그): 독 인디케이터 점 위치가 테마값(BottomPadding)으로 안
#      움직임 — plank 재시작 배제 후 소스 패치 예정 (ARM64-Log 2026-08-14).
#
# 사용법: 부팅 → startx → 독 점 표시/클릭 전환(재부팅 후에도!) + 코너 시계.
###############################################################################
set -euo pipefail
BUILD_TARGET="arm64"
OUTPUT_NAME="MaruxOS-2.0.0-arm64.img"
B="/home/administrator/MaruxOS-arm64"
LFS="$B/rootfs-clfs-arm64"
KIMG="$B/kernel/linux-6.18.26/arch/arm64/boot/Image"
KDTB="$B/kernel/linux-6.18.26/arch/arm64/boot/dts/broadcom/bcm2711-rpi-4-b.dtb"
FW="$B/firmware"
WORK="$B/iso-build"
OUT="$B/output"
WINOUT="/mnt/c/Users/Administrator/Desktop/MaruxOS/output"
IMGSIZE="27G"
MNT=""; LOOP=""
cleanup(){ set +e; [ -n "$MNT" ] && mountpoint -q "$MNT" && umount "$MNT"; [ -n "$LOOP" ] && losetup -d "$LOOP" 2>/dev/null; [ -n "$MNT" ] && [ -d "$MNT" ] && rmdir "$MNT" 2>/dev/null; }
trap cleanup EXIT
echo "===== MaruxOS 2.0.0 ARM64 v17 (libwnck 43.2 + clock-only) 빌드 $(date) ====="

# ============================ 게이트 ============================
[[ "$OUTPUT_NAME" == *arm64* ]] || { echo "🚨 ABORT: OUTPUT_NAME"; exit 1; }
[[ "$B" == *MaruxOS-arm64* ]] || { echo "🚨 ABORT: 빌드루트"; exit 1; }
[[ "$B" == *"/MaruxOS/build"* ]] && { echo "🚨 ABORT: x86_64 디렉토리"; exit 1; }
[ -f "$KIMG" ] || { echo "🚨 ABORT: 커널"; exit 1; }
KMAGIC="$(od -An -tx1 -j56 -N4 "$KIMG" | tr -d ' ')"
[ "$KMAGIC" = "41524d64" ] || { echo "🚨 ABORT: 커널 arm64 매직 ($KMAGIC)"; exit 1; }
grep -q "vc4.ko" "$B/kernel/linux-6.18.26/modules.builtin" || { echo "🚨 ABORT: VC4 builtin 아님"; exit 1; }
# 데스크톱 코어 (v8)
for f in usr/bin/Xorg usr/bin/openbox usr/bin/tint2 usr/bin/idesk usr/bin/feh usr/bin/mc usr/sbin/syslogd; do
  [ -x "$LFS/$f" ] || { echo "🚨 ABORT: $f 없음(v8 스택)"; exit 1; }
done
# 한글 B-1 (v9/v10)
[ -x "$LFS/usr/bin/ibus-daemon" ] || { echo "🚨 ABORT: ibus-daemon 없음"; exit 1; }
[ -x "$LFS/usr/libexec/ibus-x11" ] || { echo "🚨 ABORT: ibus-x11(XIM) 없음"; exit 1; }
[ -x "$LFS/usr/libexec/ibus-engine-hangul" ] || { echo "🚨 ABORT: ibus-engine-hangul 없음"; exit 1; }
[ -f "$LFS/usr/share/glib-2.0/schemas/org.freedesktop.ibus.gschema.xml" ] || { echo "🚨 ABORT: ibus 코어 gschema 없음"; exit 1; }
[ -f "$LFS/usr/share/glib-2.0/schemas/gschemas.compiled" ] || { echo "🚨 ABORT: gschemas.compiled 없음"; exit 1; }
[ -s "$LFS/etc/machine-id" ] || { echo "🚨 ABORT: /etc/machine-id 없음"; exit 1; }
[ -e "$LFS/usr/lib/libhangul.so" ] || { echo "🚨 ABORT: libhangul 없음"; exit 1; }
ls "$LFS"/usr/lib/libgtk-x11-2.0.so* >/dev/null 2>&1 || { echo "🚨 ABORT: gtk2 없음"; exit 1; }
[ -f "$LFS/usr/share/fonts/nanum/NanumGothic-Regular.ttf" ] || { echo "🚨 ABORT: NanumGothic 없음"; exit 1; }
# 배치 B-2 (v11)
[ -f "$LFS/sources/.b2-COMPLETE" ] || { echo "🚨 ABORT: B-2 미완"; exit 1; }
[ -e "$LFS/usr/lib/libgtk-3.so.0" ] || { echo "🚨 ABORT: gtk3 없음"; exit 1; }
[ -e "$LFS/usr/lib/gtk-3.0/3.0.0/immodules/im-ibus.so" ] || { echo "🚨 ABORT: gtk3 im-ibus.so 없음"; exit 1; }
grep -q ibus "$LFS/usr/lib/gtk-3.0/3.0.0/immodules.cache" || { echo "🚨 ABORT: immodules.cache에 ibus 없음"; exit 1; }
[ -x "$LFS/opt/firefox/firefox" ] || { echo "🚨 ABORT: Firefox 없음"; exit 1; }
grep -q "^Version=140\." "$LFS/opt/firefox/application.ini" || { echo "🚨 ABORT: Firefox 버전 불일치"; exit 1; }
[ -L "$LFS/usr/bin/firefox" ] || { echo "🚨 ABORT: firefox 심링크 없음"; exit 1; }
[ -e "$LFS/usr/lib/libasound.so.2" ] || { echo "🚨 ABORT: alsa-lib 없음"; exit 1; }
[ -x "$LFS/usr/bin/setxkbmap" ] || { echo "🚨 ABORT: setxkbmap 없음"; exit 1; }
[ -f "$LFS/usr/share/mime/mime.cache" ] || { echo "🚨 ABORT: shared-mime-info 없음"; exit 1; }
[ ! -f "$LFS/sources/.b2-FFDEPS" ] || { echo "🚨 ABORT: Firefox 의존성 미해결"; exit 1; }
[ -f "$LFS/etc/skel/.idesktop/firefox.lnk" ] || { echo "🚨 ABORT: firefox.lnk 없음"; exit 1; }
grep -q "NanumGothic" "$LFS/etc/xdg/openbox/rc.xml" || { echo "🚨 ABORT: rc.xml NanumGothic 없음"; exit 1; }
grep -q "GTK_IM_MODULE=ibus" "$LFS/etc/X11/xinit/xinitrc" || { echo "🚨 ABORT: xinitrc GTK_IM_MODULE 없음"; exit 1; }
# 네트워크 (v12)
[ -f "$LFS/sources/.n-COMPLETE" ] || { echo "🚨 ABORT: 네트워크 빌드 미완"; exit 1; }
[ -x "$LFS/usr/sbin/dhcpcd" ] || { echo "🚨 ABORT: dhcpcd 없음"; exit 1; }
[ -x "$LFS/usr/sbin/chronyd" ] || { echo "🚨 ABORT: chronyd 없음"; exit 1; }
[ -f "$LFS/lib/services/dhcpcd" ] || { echo "🚨 ABORT: /lib/services/dhcpcd 없음"; exit 1; }
grep -q "SERVICE=dhcpcd" "$LFS/etc/sysconfig/ifconfig.eth0" || { echo "🚨 ABORT: ifconfig.eth0 static 잔재"; exit 1; }
[ -f "$LFS/etc/chrony.conf" ] || { echo "🚨 ABORT: chrony.conf 없음"; exit 1; }
[ -e "$LFS/etc/rc.d/rc3.d/S25chronyd" ] || { echo "🚨 ABORT: S25chronyd 없음"; exit 1; }
# 커서 폴리시 (v13 — config v4/v5)
grep -q '"SWcursor" "false"' "$LFS/etc/X11/xorg.conf.d/99-swcursor.conf" || { echo "🚨 ABORT: HW커서 미적용"; exit 1; }
grep -q '"TearFree"' "$LFS/etc/X11/xorg.conf.d/99-swcursor.conf" && { echo "🚨 ABORT: 죽은 TearFree 옵션 잔재"; exit 1; }
[ -f "$LFS/etc/X11/xorg.conf.d/50-mouse-flat.conf" ] || { echo "🚨 ABORT: flat 가속 conf 없음"; exit 1; }
# 🔴 배치 P: Plank (v14 신규)
[ -f "$LFS/sources/.p-COMPLETE" ] || { echo "🚨 ABORT: Plank 빌드 미완(.p-COMPLETE 없음)"; exit 1; }
[ -x "$LFS/usr/bin/plank" ] || { echo "🚨 ABORT: plank 바이너리 없음"; exit 1; }
ls "$LFS"/usr/lib/libplank.so.1* >/dev/null 2>&1 || { echo "🚨 ABORT: libplank 없음"; exit 1; }
ls "$LFS"/usr/lib/libbamf3.so.2* >/dev/null 2>&1 || { echo "🚨 ABORT: libbamf3 없음"; exit 1; }
[ -x "$LFS/usr/bin/valac" ] || { echo "🚨 ABORT: valac 없음(vala 부트스트랩 미완)"; exit 1; }
[ -f "$LFS/usr/share/glib-2.0/schemas/net.launchpad.plank.gschema.xml" ] || { echo "🚨 ABORT: plank gschema 없음(SIGTRAP 크래시 원인)"; exit 1; }
[ -f "$LFS/usr/share/glib-2.0/schemas/40_maruxos.gschema.override" ] || { echo "🚨 ABORT: gschema.override 없음(빈 독 원인)"; exit 1; }
grep -q "xterm.dockitem" "$LFS/usr/share/glib-2.0/schemas/40_maruxos.gschema.override" || { echo "🚨 ABORT: override에 dock-items 없음"; exit 1; }
strings "$LFS/usr/share/glib-2.0/schemas/gschemas.compiled" | grep -q "net.launchpad.plank" || { echo "🚨 ABORT: gschemas.compiled에 plank 없음"; exit 1; }
# config v5 적용 확인
grep -q "GSETTINGS_BACKEND=keyfile" "$LFS/etc/X11/xinit/xinitrc" || { echo "🚨 ABORT: xinitrc keyfile 백엔드 없음(config v5 미적용)"; exit 1; }
grep -q "/usr/bin/plank" "$LFS/etc/X11/xinit/xinitrc" || { echo "🚨 ABORT: xinitrc plank 블록 없음"; exit 1; }
for d in xterm mc firefox; do
  [ -f "$LFS/usr/share/applications/$d.desktop" ] || { echo "🚨 ABORT: $d.desktop 없음"; exit 1; }
  [ -f "$LFS/root/.config/plank/dock1/launchers/$d.dockitem" ] || { echo "🚨 ABORT: $d.dockitem 없음"; exit 1; }
done
grep -q "^panel_items = C" "$LFS/etc/xdg/tint2/tint2rc" || { echo "🚨 ABORT: tint2 clock-only 미적용(config v8 안 돌림)"; exit 1; }
# 배치 P2: 폴리시 (v15)
[ -f "$LFS/sources/.p2-COMPLETE" ] || { echo "🚨 ABORT: P2 빌드 미완(.p2-COMPLETE 없음)"; exit 1; }
[ -x "$LFS/usr/bin/picom" ] || { echo "🚨 ABORT: picom 없음"; exit 1; }
[ -f "$LFS/etc/xdg/picom.conf" ] || { echo "🚨 ABORT: picom.conf 없음"; exit 1; }
[ -f "$LFS/usr/share/plank/themes/Marux/dock.theme" ] || { echo "🚨 ABORT: Marux 테마 없음"; exit 1; }
grep -q "theme='Marux'" "$LFS/usr/share/glib-2.0/schemas/40_maruxos.gschema.override" || { echo "🚨 ABORT: override theme≠Marux"; exit 1; }
grep -q "picom" "$LFS/etc/X11/xinit/xinitrc" || { echo "🚨 ABORT: xinitrc picom 기동 없음"; exit 1; }
grep -q "^panel_size = 100 36" "$LFS/etc/xdg/tint2/tint2rc" || { echo "🚨 ABORT: tint2 panel_size 100 미적용(config v8)"; exit 1; }
# 🔴 v17: libwnck 43.2 강제 (43.0 = bamf 즉사 버그)
grep -q "^Version: 43.2" "$LFS/usr/lib/pkgconfig/libwnck-3.0.pc" || { echo "🚨 ABORT: libwnck 43.2 아님(43.0=bamf segv 버그)"; exit 1; }
# 🔴 v16 라이브픽스 4종 게이트
grep -q 'context name="Client"' "$LFS/etc/xdg/openbox/rc.xml" || { echo "🚨 ABORT: rc.xml Client 컨텍스트 없음(클릭 창전환 버그)"; exit 1; }
readelf -d "$LFS/usr/lib/libwnck-3.so.0.3.0" | grep -q startup-notification || { echo "🚨 ABORT: libwnck SN 미링크(bamf segv 재발)"; exit 1; }
grep -q "bamfdaemon" "$LFS/etc/X11/xinit/xinitrc" || { echo "🚨 ABORT: xinitrc bamfdaemon 기동 없음(config v7 미적용)"; exit 1; }
grep -q "dmesg -n 1" "$LFS/etc/X11/xinit/xinitrc" || { echo "🚨 ABORT: xinitrc dmesg 조용화 없음"; exit 1; }
grep -q "TopRoundness=10" "$LFS/usr/share/plank/themes/Marux/dock.theme" || { echo "🚨 ABORT: 테마 라운드 확정값(10) 미적용"; exit 1; }
grep -q ";;95$" "$LFS/usr/share/plank/themes/Marux/dock.theme" || { echo "🚨 ABORT: 테마 알파 확정값(95) 미적용"; exit 1; }
[ -f "$KDTB" ] || { echo "🚨 ABORT: dtb"; exit 1; }
[ "$(stat -c%s "$FW/start4.elf")" -eq 2306400 ] || { echo "🚨 ABORT: start4.elf"; exit 1; }
echo "✅ 게이트 통과 (v13 전체 + plank/valac/override/keyfile/dockitem/desktop/tint2-SC)"

mkdir -p "$WORK" "$OUT"; IMG="$WORK/$OUTPUT_NAME"; rm -f "$IMG" "$IMG.xz"
echo "[1/8] $IMGSIZE sparse"; truncate -s "$IMGSIZE" "$IMG"
echo "[2/8] 파티션"; sfdisk "$IMG" <<'SFDISK'
label: dos
unit: sectors
start=2048, size=1048576, type=c, bootable
start=1050624, type=83
SFDISK
echo "[3/8] losetup"; LOOP="$(losetup -fP --show "$IMG")"; echo "  loop=$LOOP"
echo "[4/8] mkfs"; mkfs.vfat -F 32 -n MARUXBOOT "${LOOP}p1" >/dev/null; mkfs.ext4 -q -F -L maruxroot "${LOOP}p2"
echo "[5/8] rootfs 복사 (/tools 제외 · /sources 유지)"
MNT="$(mktemp -d)"; mount "${LOOP}p2" "$MNT"
rsync -aHAX --numeric-ids --exclude='/tools' --exclude='/proc/*' --exclude='/sys/*' --exclude='/run/*' --exclude='/tmp/*' "$LFS"/ "$MNT"/
echo "  [5b] rootfs 픽스 (idempotent)"
ln -sf /usr/sbin/udevadm "$MNT/bin/udevadm"
grep -q "/dev/shm" "$MNT/etc/fstab" || printf "tmpfs           /dev/shm    tmpfs     nosuid,nodev        0    0\ncgroup2         /sys/fs/cgroup cgroup2 nosuid,noexec,nodev 0   0\n" >> "$MNT/etc/fstab"
[ -e "$MNT/etc/rc.d/rcS.d/S70console" ] && mv "$MNT/etc/rc.d/rcS.d/S70console" "$MNT/etc/rc.d/rcS.d/DISABLED-S70console"
grep -q "agetty.*ttyS0" "$MNT/etc/inittab" || echo 's0:2345:respawn:/sbin/agetty --keep-baud 115200,38400,9600 ttyS0 vt220' >> "$MNT/etc/inittab"
cat > "$MNT/etc/resolv.conf" <<'RESOLV'
# MaruxOS — dhcpcd가 DHCP 응답의 DNS로 갱신함. 아래는 클린 폴백.
nameserver 1.1.1.1
nameserver 8.8.8.8
RESOLV
sync; umount "$MNT"
echo "[6/8] boot 파티션"
mount "${LOOP}p1" "$MNT"
cp "$KIMG" "$MNT/kernel8.img"; cp "$KDTB" "$MNT/bcm2711-rpi-4-b.dtb"; cp "$FW/start4.elf" "$MNT/start4.elf"; cp "$FW/fixup4.dat" "$MNT/fixup4.dat"
cat > "$MNT/config.txt" <<'CFG'
arm_64bit=1
kernel=kernel8.img
enable_uart=1
max_framebuffers=2
CFG
# v13: video= 1080p60 강제(TV 픽스). v16: 미연결 HDMI-A-2 강제 제거(vc4 RGB 경고 스팸 원인 유력)
printf 'earlycon=uart8250,mmio32,0xfe215040 8250.nr_uarts=1 console=tty1 console=ttyS0,115200 loglevel=4 root=/dev/mmcblk0p2 rootfstype=ext4 rootwait fsck.repair=yes net.ifnames=0 video=HDMI-A-1:1920x1080@60\n' > "$MNT/cmdline.txt"
sync; umount "$MNT"; rmdir "$MNT"; MNT=""
echo "[7/8] loop 해제"; losetup -d "$LOOP"; LOOP=""
echo "[8/8] xz 압축"; xz -T0 -f "$IMG"; cp -f "$IMG.xz" "$OUT/"
mkdir -p "$WINOUT" && cp -f "$IMG.xz" "$WINOUT/" && echo "  Windows output 복사 완료"
echo "===== ✅ v17 완료 $(date) ====="
ls -lh "$OUT/$OUTPUT_NAME.xz"; sha256sum "$OUT/$OUTPUT_NAME.xz"
