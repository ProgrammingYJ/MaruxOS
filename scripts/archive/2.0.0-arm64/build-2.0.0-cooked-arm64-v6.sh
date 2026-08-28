#!/bin/bash
###############################################################################
# MaruxOS 2.0.0 "Cooked" — ARM64 이미지 빌드 v6
#
# v5 대비 변경 (커널/툴체인/유저랜드 불변, 이미지 재포장 + rootfs 설정 픽스):
#   ① /bin/udevadm 심링크 (스크립트 하드코딩 경로 → /usr/sbin/udevadm)
#   ② /etc/fstab 에 /dev/shm(tmpfs) + /sys/fs/cgroup(cgroup2) 2줄 추가
#   ③ S70console 비활성 (헤드리스 setfont 실패 → "Press Enter" 정지 방지)
#   ④ S10sysklogd 비활성 (sysklogd 미설치 → 실패 방지; 정식설치는 후속)
#   + 콘솔 순서 console=tty1 console=ttyS0,115200 (ttyS0=/dev/console=시리얼)
#   + earlycon 유지 (조기 커널 출력)
#
# 소스 = $LFS 직접 (내 4픽스 이미 반영). /tools 제외(x86_64 死), /sources 유지(self-host).
# 이미지 = 27G (p1 512M FAT32 boot / p2 나머지 ext4 root) → 29.7G SD 채움.
# 목표 = 무인 클린부팅 (FAIL 0, 자동 marux login:).
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

echo "===== MaruxOS 2.0.0 ARM64 v6 빌드 $(date) ====="

# ============================ 게이트 ============================
[[ "$OUTPUT_NAME" == *arm64* ]] || { echo "🚨 ABORT: OUTPUT_NAME에 arm64 누락"; exit 1; }
[[ "$B" == *MaruxOS-arm64* ]] || { echo "🚨 ABORT: 빌드루트가 arm64 분리경로 아님: $B"; exit 1; }
[[ "$B" == *"/MaruxOS/build"* ]] && { echo "🚨 ABORT: x86_64 디렉토리"; exit 1; }
[ -d "$LFS" ] || { echo "🚨 ABORT: rootfs 없음: $LFS"; exit 1; }
[ -f "$KIMG" ] || { echo "🚨 ABORT: 커널 Image 없음: $KIMG"; exit 1; }
# 커널이 진짜 arm64 Image 인지 매직바이트로 강제 (offset 0x38 == 41 52 4d 64)
KMAGIC="$(od -An -tx1 -j56 -N4 "$KIMG" | tr -d ' ')"
[ "$KMAGIC" = "41524d64" ] || { echo "🚨 ABORT: 커널 arm64 Image 매직 불일치 ($KMAGIC != 41524d64)"; exit 1; }
[ -f "$KDTB" ] || { echo "🚨 ABORT: dtb 없음: $KDTB"; exit 1; }
[ "$(stat -c%s "$FW/start4.elf")" -eq 2306400 ] || { echo "🚨 ABORT: start4.elf != master 2306400"; exit 1; }
echo "✅ 게이트 통과 (arm64 Image magic=$KMAGIC, start4.elf=master)"

mkdir -p "$WORK" "$OUT"
IMG="$WORK/$OUTPUT_NAME"
rm -f "$IMG" "$IMG.xz"

# ============================ 1. 이미지 컨테이너 ============================
echo "[1/8] $IMGSIZE sparse 이미지"
truncate -s "$IMGSIZE" "$IMG"

# ============================ 2. 파티션 ============================
echo "[2/8] 파티션 (p1 512M FAT32 boot / p2 나머지 ext4)"
sfdisk "$IMG" <<'SFDISK'
label: dos
unit: sectors
start=2048, size=1048576, type=c, bootable
start=1050624, type=83
SFDISK

# ============================ 3. loop ============================
echo "[3/8] losetup"
LOOP="$(losetup -fP --show "$IMG")"
echo "  loop=$LOOP"

# ============================ 4. mkfs ============================
echo "[4/8] mkfs (vfat p1 / ext4 p2)"
mkfs.vfat -F 32 -n MARUXBOOT "${LOOP}p1" >/dev/null
mkfs.ext4 -q -F -L maruxroot "${LOOP}p2"

# ============================ 5. rootfs 전개 ($LFS 직접, /tools 제외) ============================
echo "[5/8] rootfs 복사 ($LFS → p2, /tools 제외 · /sources 유지)"
MNT="$(mktemp -d)"
mount "${LOOP}p2" "$MNT"
rsync -aHAX --numeric-ids \
  --exclude='/tools' \
  --exclude='/proc/*' --exclude='/sys/*' --exclude='/run/*' --exclude='/tmp/*' \
  "$LFS"/ "$MNT"/

echo "  [5b] rootfs 4픽스 재확인 (idempotent)"
# ① udevadm
ln -sf /usr/sbin/udevadm "$MNT/bin/udevadm"
# ② fstab
grep -q "/dev/shm" "$MNT/etc/fstab" || \
  printf "tmpfs           /dev/shm    tmpfs     nosuid,nodev        0    0\ncgroup2         /sys/fs/cgroup cgroup2 nosuid,noexec,nodev 0   0\n" >> "$MNT/etc/fstab"
# ③④ 비활성 (혹시 활성 상태면 끔)
[ -e "$MNT/etc/rc.d/rcS.d/S70console" ] && mv "$MNT/etc/rc.d/rcS.d/S70console" "$MNT/etc/rc.d/rcS.d/DISABLED-S70console"
[ -e "$MNT/etc/rc.d/rc3.d/S10sysklogd" ] && mv "$MNT/etc/rc.d/rc3.d/S10sysklogd" "$MNT/etc/rc.d/rc3.d/DISABLED-S10sysklogd"
# ttyS0 getty 보장
grep -q "agetty.*ttyS0" "$MNT/etc/inittab" || \
  echo 's0:2345:respawn:/sbin/agetty --keep-baud 115200,38400,9600 ttyS0 vt220' >> "$MNT/etc/inittab"
sync
umount "$MNT"

# ============================ 6. boot 파티션 populate ============================
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
CFG
printf 'earlycon=uart8250,mmio32,0xfe215040 8250.nr_uarts=1 console=tty1 console=ttyS0,115200 root=/dev/mmcblk0p2 rootfstype=ext4 rootwait fsck.repair=yes net.ifnames=0\n' > "$MNT/cmdline.txt"
sync
umount "$MNT"
rmdir "$MNT"; MNT=""

# ============================ 7. loop 해제 ============================
echo "[7/8] loop 해제"
losetup -d "$LOOP"; LOOP=""

# ============================ 8. 압축 + 산출 ============================
echo "[8/8] xz 압축 (-T0)"
xz -T0 -f "$IMG"
cp -f "$IMG.xz" "$OUT/"
mkdir -p "$WINOUT" && cp -f "$IMG.xz" "$WINOUT/" && echo "  Windows output 복사 완료"

echo "===== ✅ v6 완료 $(date) ====="
ls -lh "$OUT/$OUTPUT_NAME.xz"
sha256sum "$OUT/$OUTPUT_NAME.xz"
