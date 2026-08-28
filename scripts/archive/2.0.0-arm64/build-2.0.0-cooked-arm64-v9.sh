#!/bin/bash
###############################################################################
# MaruxOS 2.0.0 "Cooked" — ARM64 이미지 빌드 v9 (한글 입력 / 배치 B-1)
#
# v8 대비 변경:
#   ① ibus 1.5.29 + ibus-hangul 1.5.5 + GTK2 2.24.33 (ibus-x11 XIM 서버)
#      → xterm XIM 한글입력 (gtk3 불요. gtk3/Firefox는 배치 B-2)
#   ② NanumGothic TTF (18x18ko 비트맵 → 예쁜 벡터 한글)
#   ③ VC4 SWcursor xorg.conf + 시계 ASCII 포맷 (배치 A 실기기 폴리시, $LFS 이미 박제)
#   * 커서 미세깜빡(SW커서/VC4)은 알려진 비치명 이슈로 보류.
#
# 사용법: HDMI 로그인 → startx → xterm에서 Shift+Space(한영토글) → 한글 타이핑.
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
echo "===== MaruxOS 2.0.0 ARM64 v9 (한글 입력) 빌드 $(date) ====="

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
[ -f "$LFS/etc/X11/xorg.conf.d/99-swcursor.conf" ] || { echo "🚨 ABORT: SWcursor xorg.conf 없음"; exit 1; }
grep -q "time2_format = %Y-%m-%d" "$LFS/etc/xdg/tint2/tint2rc" || { echo "🚨 ABORT: 시계 ASCII 포맷 미적용"; exit 1; }
# 배치 B-1 한글 (v9 신규)
[ -x "$LFS/usr/bin/ibus-daemon" ] || { echo "🚨 ABORT: ibus-daemon 없음"; exit 1; }
[ -x "$LFS/usr/libexec/ibus-x11" ] || { echo "🚨 ABORT: ibus-x11(XIM) 없음"; exit 1; }
[ -x "$LFS/usr/libexec/ibus-engine-hangul" ] || { echo "🚨 ABORT: ibus-engine-hangul 없음"; exit 1; }
[ -e "$LFS/usr/lib/libhangul.so" ] || { echo "🚨 ABORT: libhangul 없음"; exit 1; }
[ -e "$LFS/usr/lib/libgtk-x11-2.0.so"* ] 2>/dev/null || ls "$LFS"/usr/lib/libgtk-x11-2.0.so* >/dev/null 2>&1 || { echo "🚨 ABORT: gtk2 없음(ibus-x11 의존)"; exit 1; }
[ -f "$LFS/usr/share/fonts/nanum/NanumGothic-Regular.ttf" ] || { echo "🚨 ABORT: NanumGothic 없음"; exit 1; }
[ -f "$LFS/etc/X11/xinit/xinitrc" ] || { echo "🚨 ABORT: xinitrc 없음"; exit 1; }
grep -q "ibus-daemon" "$LFS/etc/X11/xinit/xinitrc" || { echo "🚨 ABORT: xinitrc에 ibus 기동 없음"; exit 1; }
[ -f "$KDTB" ] || { echo "🚨 ABORT: dtb"; exit 1; }
[ "$(stat -c%s "$FW/start4.elf")" -eq 2306400 ] || { echo "🚨 ABORT: start4.elf"; exit 1; }
echo "✅ 게이트 통과 (arm64/VC4/데스크톱 + ibus-x11/engine-hangul/gtk2/libhangul/NanumGothic/xinitrc-ibus)"

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
printf 'earlycon=uart8250,mmio32,0xfe215040 8250.nr_uarts=1 console=tty1 console=ttyS0,115200 root=/dev/mmcblk0p2 rootfstype=ext4 rootwait fsck.repair=yes net.ifnames=0\n' > "$MNT/cmdline.txt"
sync; umount "$MNT"; rmdir "$MNT"; MNT=""
echo "[7/8] loop 해제"; losetup -d "$LOOP"; LOOP=""
echo "[8/8] xz 압축"; xz -T0 -f "$IMG"; cp -f "$IMG.xz" "$OUT/"
mkdir -p "$WINOUT" && cp -f "$IMG.xz" "$WINOUT/" && echo "  Windows output 복사 완료"
echo "===== ✅ v9 완료 $(date) ====="
ls -lh "$OUT/$OUTPUT_NAME.xz"; sha256sum "$OUT/$OUTPUT_NAME.xz"
