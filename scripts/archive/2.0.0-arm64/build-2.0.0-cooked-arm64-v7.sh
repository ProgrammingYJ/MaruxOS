#!/bin/bash
###############################################################################
# MaruxOS 2.0.0 "Cooked" — ARM64 이미지 빌드 v7 (그래픽 데스크톱)
#
# v6 대비 변경:
#   ① 커널 = 5a 재빌드(CONFIG_DRM_VC4=y / DRM_V3D=y builtin) → HDMI KMS
#   ② config.txt 에 max_framebuffers=2 추가 (VC4 KMS 프레임버퍼)
#   ③ sysklogd 정식 설치됨 → S10sysklogd 재-disable 라인 제거 (v6 line101 삭제)
#   ④ rootfs에 X.org(5b) + openbox/tint2/idesk/xterm(5c) + DejaVu 폰트 + 데스크톱 config
#   ⑤ tty1 getty 는 inittab에 이미 존재 (HDMI 로그인)
#   * 한글(ibus/gtk3)은 qemu gdk-pixbuf 이슈로 Pi 네이티브 빌드로 보류
#
# 사용법: HDMI 로그인(root) 후 `startx` → openbox+tint2 데스크톱, 우클릭 메뉴 → xterm.
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

echo "===== MaruxOS 2.0.0 ARM64 v7 (데스크톱) 빌드 $(date) ====="

# ============================ 게이트 ============================
[[ "$OUTPUT_NAME" == *arm64* ]] || { echo "🚨 ABORT: OUTPUT_NAME arm64 누락"; exit 1; }
[[ "$B" == *MaruxOS-arm64* ]] || { echo "🚨 ABORT: 빌드루트 arm64 아님: $B"; exit 1; }
[[ "$B" == *"/MaruxOS/build"* ]] && { echo "🚨 ABORT: x86_64 디렉토리"; exit 1; }
[ -d "$LFS" ] || { echo "🚨 ABORT: rootfs 없음"; exit 1; }
[ -f "$KIMG" ] || { echo "🚨 ABORT: 커널 Image 없음"; exit 1; }
KMAGIC="$(od -An -tx1 -j56 -N4 "$KIMG" | tr -d ' ')"
[ "$KMAGIC" = "41524d64" ] || { echo "🚨 ABORT: 커널 arm64 매직 불일치 ($KMAGIC)"; exit 1; }
# 커널 5a 확인: VC4 builtin (modules.builtin에 vc4.ko)
grep -q "vc4.ko" "$B/kernel/linux-6.18.26/modules.builtin" || { echo "🚨 ABORT: 커널이 5a(VC4 builtin) 아님"; exit 1; }
# 데스크톱 스택 확인
[ -x "$LFS/usr/bin/Xorg" ]   || { echo "🚨 ABORT: Xorg 없음(5b 미완)"; exit 1; }
[ -x "$LFS/usr/bin/openbox" ]|| { echo "🚨 ABORT: openbox 없음(5c 미완)"; exit 1; }
[ -x "$LFS/usr/bin/tint2" ]  || { echo "🚨 ABORT: tint2 없음"; exit 1; }
[ -f "$LFS/etc/X11/xinit/xinitrc" ] || { echo "🚨 ABORT: xinitrc 없음(config 미적용)"; exit 1; }
# sysklogd 정식 설치 확인
[ -x "$LFS/usr/sbin/syslogd" ] || { echo "🚨 ABORT: syslogd 없음"; exit 1; }
[ -f "$KDTB" ] || { echo "🚨 ABORT: dtb 없음"; exit 1; }
[ "$(stat -c%s "$FW/start4.elf")" -eq 2306400 ] || { echo "🚨 ABORT: start4.elf != master"; exit 1; }
echo "✅ 게이트 통과 (arm64 magic=$KMAGIC, VC4 builtin, Xorg/openbox/tint2/xinitrc/syslogd)"

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
# ① udevadm 심링크
ln -sf /usr/sbin/udevadm "$MNT/bin/udevadm"
# ② fstab (/dev/shm + cgroup)
grep -q "/dev/shm" "$MNT/etc/fstab" || \
  printf "tmpfs           /dev/shm    tmpfs     nosuid,nodev        0    0\ncgroup2         /sys/fs/cgroup cgroup2 nosuid,noexec,nodev 0   0\n" >> "$MNT/etc/fstab"
# ③ S70console 비활성 유지 (헤드리스 setfont 방지 — 데스크톱은 X가 담당)
[ -e "$MNT/etc/rc.d/rcS.d/S70console" ] && mv "$MNT/etc/rc.d/rcS.d/S70console" "$MNT/etc/rc.d/rcS.d/DISABLED-S70console"
# ④ (v6의 S10sysklogd 재-disable 라인 삭제됨 — sysklogd 정식 설치되어 활성 유지)
# ⑤ ttyS0 getty 보장 (tty1은 inittab에 이미 존재)
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
# config.txt: max_framebuffers=2 (VC4 KMS 프레임버퍼)
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

echo "===== ✅ v7 완료 $(date) ====="
ls -lh "$OUT/$OUTPUT_NAME.xz"
sha256sum "$OUT/$OUTPUT_NAME.xz"
