#!/bin/bash
###############################################################################
# MaruxOS 2.0.0 "Cooked" — ARM64 이미지 빌드 v13 (실기기 폴리시: HW커서 + HDMI 강제)
#
# v12 대비 변경 (전부 2026-07-27 실기기 라이브 A/B 검증):
#   ① 커서: SWcursor → **HW커서**(SWcursor=false) — TV+1080p60 환경 실기기 판정:
#      지지직 재발 없음 + SW커서의 깜빡임·딜레이 완치. (v8 "지지직=HW커서" 판정은
#      모니터+auto EDID 환경 한정이었을 가능성 — 모니터에서 재발 시 롤백 옵션 문서화)
#   ② 마우스 가속 flat 프로파일 (50-mouse-flat.conf) — 커서 1:1 반응
#   ③ cmdline **video=HDMI 1080p60 강제** — TV "invalid format" 해결 (실기기 검증)
#   ④ config v4 (v3 + 커서 델타) 적용 전제
#   (v12 네트워크: 실기기 검증 완료 — DHCP 임대·DNS·ping 36ms·chrony 오차 0.7µs)
#
# 사용법: 이더넷+HDMI(포트0) → 부팅 → startx → Firefox 웹서핑/한글, 커서 클린.
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
echo "===== MaruxOS 2.0.0 ARM64 v13 (HW커서+flat가속+HDMI강제) 빌드 $(date) ====="

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
# 🔴 커서 폴리시 (v13 신규 — config v4)
grep -q '"SWcursor" "false"' "$LFS/etc/X11/xorg.conf.d/99-swcursor.conf" || { echo "🚨 ABORT: HW커서 미적용(config v4 안 돌림)"; exit 1; }
grep -q '"TearFree"' "$LFS/etc/X11/xorg.conf.d/99-swcursor.conf" && { echo "🚨 ABORT: 죽은 TearFree 옵션 잔재"; exit 1; }
[ -f "$LFS/etc/X11/xorg.conf.d/50-mouse-flat.conf" ] || { echo "🚨 ABORT: flat 가속 conf 없음"; exit 1; }
[ -f "$KDTB" ] || { echo "🚨 ABORT: dtb"; exit 1; }
[ "$(stat -c%s "$FW/start4.elf")" -eq 2306400 ] || { echo "🚨 ABORT: start4.elf"; exit 1; }
echo "✅ 게이트 통과 (v12 전체 + HW커서/flat가속 config-v4)"

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
# v13: video=HDMI 1080p60 강제 — TV "invalid format" 픽스 (실기기 검증 2026-07-27)
printf 'earlycon=uart8250,mmio32,0xfe215040 8250.nr_uarts=1 console=tty1 console=ttyS0,115200 loglevel=4 root=/dev/mmcblk0p2 rootfstype=ext4 rootwait fsck.repair=yes net.ifnames=0 video=HDMI-A-1:1920x1080@60 video=HDMI-A-2:1920x1080@60\n' > "$MNT/cmdline.txt"
sync; umount "$MNT"; rmdir "$MNT"; MNT=""
echo "[7/8] loop 해제"; losetup -d "$LOOP"; LOOP=""
echo "[8/8] xz 압축"; xz -T0 -f "$IMG"; cp -f "$IMG.xz" "$OUT/"
mkdir -p "$WINOUT" && cp -f "$IMG.xz" "$WINOUT/" && echo "  Windows output 복사 완료"
echo "===== ✅ v13 완료 $(date) ====="
ls -lh "$OUT/$OUTPUT_NAME.xz"; sha256sum "$OUT/$OUTPUT_NAME.xz"
