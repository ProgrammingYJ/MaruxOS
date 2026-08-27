#!/bin/bash
###############################################################################
# MaruxOS 2.0.0 "Cooked" — ARM64 이미지 빌드 v8 (데스크톱 x86 패리티 / 배치 A)
#
# v7 대비 변경 (배치 A = x86_64 최신버전 기능 이식):
#   ① feh + mc aarch64 빌드 (install-desktop-polish-arm64.sh) → 배경화면 + 파일매니저
#   ② config-v2 배포 (setup-desktop-config-arm64-v2.sh):
#      - PNG 자산(배경 marux-desktop.png + 아이콘 marux-terminal/file-manager)
#      - idesk 2아이콘(terminal/files) — 더블클릭 실행
#      - 헬퍼 3종(marux-wallpaper/-new-desktop-item/-desktop-refresh)
#      - openbox 풀메뉴 + 키바인드(W-t 터미널 / W-e 파일 / W-d 바탕화면)
#      - .Xdefaults(xterm 색상/폰트) + full xinitrc(feh배경+network+idesk)
#   ③ 한글입력(ibus)·Firefox = 배치 B(Pi 네이티브 gtk3 후). xinitrc 가드로 존재 시 자동활성.
#
# 사용법: HDMI 로그인(root) → `startx` → 배경화면 + 패널 + 바탕화면 아이콘(더블클릭 실행)
#         + 우클릭 풀메뉴 + 키바인드. "VM 돌리듯" 완성 데스크톱.
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

MNT=""
LOOP=""
cleanup() {
  set +e
  [ -n "$MNT" ] && mountpoint -q "$MNT" && umount "$MNT"
  [ -n "$LOOP" ] && losetup -d "$LOOP" 2>/dev/null
  [ -n "$MNT" ] && [ -d "$MNT" ] && rmdir "$MNT" 2>/dev/null
}
trap cleanup EXIT

echo "===== MaruxOS 2.0.0 ARM64 v8 (데스크톱 x86 패리티) 빌드 $(date) ====="

# ============================ 게이트 ============================
[[ "$OUTPUT_NAME" == *arm64* ]] || { echo "🚨 ABORT: OUTPUT_NAME arm64 누락"; exit 1; }
[[ "$B" == *MaruxOS-arm64* ]] || { echo "🚨 ABORT: 빌드루트 arm64 아님: $B"; exit 1; }
[[ "$B" == *"/MaruxOS/build"* ]] && { echo "🚨 ABORT: x86_64 디렉토리"; exit 1; }
[ -d "$LFS" ] || { echo "🚨 ABORT: rootfs 없음"; exit 1; }
[ -f "$KIMG" ] || { echo "🚨 ABORT: 커널 Image 없음"; exit 1; }
KMAGIC="$(od -An -tx1 -j56 -N4 "$KIMG" | tr -d ' ')"
[ "$KMAGIC" = "41524d64" ] || { echo "🚨 ABORT: 커널 arm64 매직 불일치 ($KMAGIC)"; exit 1; }
grep -q "vc4.ko" "$B/kernel/linux-6.18.26/modules.builtin" || { echo "🚨 ABORT: 커널이 5a(VC4 builtin) 아님"; exit 1; }
# --- 데스크톱 코어 (v7 유지) ---
[ -x "$LFS/usr/bin/Xorg" ]   || { echo "🚨 ABORT: Xorg 없음(5b)"; exit 1; }
[ -x "$LFS/usr/bin/openbox" ]|| { echo "🚨 ABORT: openbox 없음(5c)"; exit 1; }
[ -x "$LFS/usr/bin/tint2" ]  || { echo "🚨 ABORT: tint2 없음"; exit 1; }
[ -x "$LFS/usr/bin/idesk" ]  || { echo "🚨 ABORT: idesk 없음"; exit 1; }
[ -x "$LFS/usr/sbin/syslogd" ] || { echo "🚨 ABORT: syslogd 없음"; exit 1; }
# --- 배치 A 추가 (v8 신규 게이트) ---
[ -x "$LFS/usr/bin/feh" ] || { echo "🚨 ABORT: feh 없음(배치A 빌드 미완)"; exit 1; }
[ -x "$LFS/usr/bin/mc" ]  || { echo "🚨 ABORT: mc 없음(배치A 빌드 미완)"; exit 1; }
[ -f "$LFS/usr/share/backgrounds/marux-desktop.png" ] || { echo "🚨 ABORT: 배경화면 PNG 없음(config-v2 미배포)"; exit 1; }
[ -f "$LFS/usr/share/pixmaps/maruxos/marux-terminal.png" ] || { echo "🚨 ABORT: 아이콘 PNG 없음"; exit 1; }
[ -x "$LFS/usr/bin/marux-wallpaper" ] || { echo "🚨 ABORT: marux-wallpaper 헬퍼 없음"; exit 1; }
[ -f "$LFS/etc/skel/.idesktop/filemanager.lnk" ] || { echo "🚨 ABORT: idesk filemanager.lnk 없음"; exit 1; }
[ -f "$LFS/etc/X11/xinit/xinitrc" ] || { echo "🚨 ABORT: xinitrc 없음"; exit 1; }
grep -q "feh --bg-scale" "$LFS/etc/X11/xinit/xinitrc" || { echo "🚨 ABORT: xinitrc가 feh 배경화면 미포함(config-v1?)"; exit 1; }
[ -f "$KDTB" ] || { echo "🚨 ABORT: dtb 없음"; exit 1; }
[ "$(stat -c%s "$FW/start4.elf")" -eq 2306400 ] || { echo "🚨 ABORT: start4.elf != master"; exit 1; }
echo "✅ 게이트 통과 (arm64 magic=$KMAGIC, VC4 builtin, Xorg/openbox/tint2/idesk, feh/mc, PNG/헬퍼/xinitrc-feh)"

mkdir -p "$WORK" "$OUT"
IMG="$WORK/$OUTPUT_NAME"
rm -f "$IMG" "$IMG.xz"

echo "[1/8] $IMGSIZE sparse 이미지"
truncate -s "$IMGSIZE" "$IMG"

echo "[2/8] 파티션 (p1 512M FAT32 boot / p2 ext4 root)"
sfdisk "$IMG" <<'SFDISK'
label: dos
unit: sectors
start=2048, size=1048576, type=c, bootable
start=1050624, type=83
SFDISK

echo "[3/8] losetup"
LOOP="$(losetup -fP --show "$IMG")"
echo "  loop=$LOOP"

echo "[4/8] mkfs (vfat p1 / ext4 p2)"
mkfs.vfat -F 32 -n MARUXBOOT "${LOOP}p1" >/dev/null
mkfs.ext4 -q -F -L maruxroot "${LOOP}p2"

echo "[5/8] rootfs 복사 ($LFS → p2, /tools 제외 · /sources 유지)"
MNT="$(mktemp -d)"
mount "${LOOP}p2" "$MNT"
rsync -aHAX --numeric-ids \
  --exclude='/tools' \
  --exclude='/proc/*' --exclude='/sys/*' --exclude='/run/*' --exclude='/tmp/*' \
  "$LFS"/ "$MNT"/

echo "  [5b] rootfs 픽스 재확인 (idempotent)"
ln -sf /usr/sbin/udevadm "$MNT/bin/udevadm"
grep -q "/dev/shm" "$MNT/etc/fstab" || \
  printf "tmpfs           /dev/shm    tmpfs     nosuid,nodev        0    0\ncgroup2         /sys/fs/cgroup cgroup2 nosuid,noexec,nodev 0   0\n" >> "$MNT/etc/fstab"
[ -e "$MNT/etc/rc.d/rcS.d/S70console" ] && mv "$MNT/etc/rc.d/rcS.d/S70console" "$MNT/etc/rc.d/rcS.d/DISABLED-S70console"
grep -q "agetty.*ttyS0" "$MNT/etc/inittab" || \
  echo 's0:2345:respawn:/sbin/agetty --keep-baud 115200,38400,9600 ttyS0 vt220' >> "$MNT/etc/inittab"
sync
umount "$MNT"

echo "[6/8] boot 파티션 (kernel8.img/dtb/펌웨어/config/cmdline)"
mount "${LOOP}p1" "$MNT"
cp "$KIMG"  "$MNT/kernel8.img"
cp "$KDTB"  "$MNT/bcm2711-rpi-4-b.dtb"
cp "$FW/start4.elf" "$MNT/start4.elf"
cp "$FW/fixup4.dat" "$MNT/fixup4.dat"
cat > "$MNT/config.txt" <<'CFG'
arm_64bit=1
kernel=kernel8.img
enable_uart=1
max_framebuffers=2
CFG
printf 'earlycon=uart8250,mmio32,0xfe215040 8250.nr_uarts=1 console=tty1 console=ttyS0,115200 root=/dev/mmcblk0p2 rootfstype=ext4 rootwait fsck.repair=yes net.ifnames=0\n' > "$MNT/cmdline.txt"
sync
umount "$MNT"
rmdir "$MNT"; MNT=""

echo "[7/8] loop 해제"
losetup -d "$LOOP"; LOOP=""

echo "[8/8] xz 압축 (-T0)"
xz -T0 -f "$IMG"
cp -f "$IMG.xz" "$OUT/"
mkdir -p "$WINOUT" && cp -f "$IMG.xz" "$WINOUT/" && echo "  Windows output 복사 완료"

echo "===== ✅ v8 완료 $(date) ====="
ls -lh "$OUT/$OUTPUT_NAME.xz"
sha256sum "$OUT/$OUTPUT_NAME.xz"
