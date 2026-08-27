#!/bin/bash
# =============================================================================
# MaruxOS 2.0.0 "Cooked" — ARM64 배치 W 스텝3: 퀵설정 GUI (marux-quicksettings)
# -----------------------------------------------------------------------------
# 소스: src/marux-quicksettings/marux-quicksettings.vala (100% 자체 제작 — 기성 애플릿 無)
# 빌드: qemu-chroot에서 MaruxOS 자체 valac(0.56, 배치 P 부트스트랩 자산)로 컴파일.
#   valac --pkg gtk+-3.0 → C 생성 → chroot native gcc. plank 체인과 동일 경로라 검증됨.
# 전제: .p-COMPLETE(valac/gtk3) + .w-COMPLETE(wpa_cli — 런타임 백엔드)
# resumable(.q-markers). 완료기준: .q-COMPLETE. 실행: wsl -u root bash <this>
# =============================================================================
set -uo pipefail
B=/home/administrator/MaruxOS-arm64
LFS=$B/rootfs-clfs-arm64
S=$LFS/sources
SRC=/mnt/c/Users/Administrator/Desktop/MaruxOS/src/marux-quicksettings/marux-quicksettings.vala
[[ "$LFS" == *"MaruxOS-arm64"* ]] || { echo "🚨 ABORT: $LFS"; exit 1; }
[ -f "$S/.p-COMPLETE" ] || { echo "🚨 ABORT: 배치 P 미완(valac/gtk3 없음)"; exit 1; }
[ -f "$S/.w-COMPLETE" ] || { echo "🚨 ABORT: 배치 W userspace 미완(wpa_cli 없음)"; exit 1; }
[ -f "$SRC" ] || { echo "🚨 ABORT: vala 소스 없음"; exit 1; }

# ---------- binfmt + mounts (함정 #5: 세션마다 재등록) ----------
mountpoint -q /proc/sys/fs/binfmt_misc || mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc
[ -e /proc/sys/fs/binfmt_misc/qemu-aarch64 ] || echo ':qemu-aarch64:M::\x7f\x45\x4c\x46\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-aarch64-static:F' > /proc/sys/fs/binfmt_misc/register
[ -e "$LFS/usr/bin/qemu-aarch64-static" ] || cp /usr/bin/qemu-aarch64-static "$LFS/usr/bin/"
for fs in dev dev/pts proc sys run; do
  mkdir -p "$LFS/$fs"; mountpoint -q "$LFS/$fs" && continue
  case $fs in dev) mount --bind /dev "$LFS/dev";; dev/pts) mount --bind /dev/pts "$LFS/dev/pts";; proc) mount -t proc proc "$LFS/proc";; sys) mount -t sysfs sysfs "$LFS/sys";; run) mount -t tmpfs tmpfs "$LFS/run";; esac
done

# 소스 반입 (항상 최신본 — 멱등)
cp -f "$SRC" "$S/marux-quicksettings.vala"

# ---------- chroot 내부 컴파일 ----------
cat > "$LFS/root/qs-inside.sh" <<'INSIDE'
#!/bin/bash
set -uo pipefail
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
export LC_ALL=C
MARKDIR=/sources/.q-markers; mkdir -p "$MARKDIR"
rm -f /sources/.q-FAILED /sources/.q-COMPLETE
log(){ echo "[qs] $(date '+%H:%M:%S') $*"; }
fail(){ echo "FAILED_AT=$1" > /sources/.q-FAILED; exit 1; }

valac --version || fail valac-missing
pkg-config --exists gtk+-3.0 || fail gtk3-pc

log "COMPILE marux-quicksettings (valac → C → gcc)"
cd /sources
# ⚠️ 로그는 파일 리다이렉트 (| head는 SIGPIPE로 컴파일러 조기 사살 — 함정 박제)
valac --pkg gtk+-3.0 --pkg posix -X -O2 -X -w \
  -o /usr/bin/marux-quicksettings marux-quicksettings.vala > /sources/qs-build.log 2>&1; rc=$?
[ $rc -ne 0 ] && { tail -40 /sources/qs-build.log; fail "valac(rc=$rc)"; }
[ -x /usr/bin/marux-quicksettings ] || fail no-binary
file_out=$(head -c 20 /usr/bin/marux-quicksettings | od -An -t x1 | head -1)
log "binary head: $file_out"
# aarch64 ELF 확인 (매직 7f454c46 + e_machine 0xb7)
head -c 20 /usr/bin/marux-quicksettings | od -An -t x1 | tr -d ' \n' | grep -q "^7f454c46" || fail not-elf
touch /sources/.q-COMPLETE
log "===== QUICKSETTINGS DONE ====="
INSIDE
chmod +x "$LFS/root/qs-inside.sh"
echo "===== quicksettings build 시작 (chroot) $(date) ====="
chroot "$LFS" /bin/bash /root/qs-inside.sh
RC=$?
echo "===== quicksettings build 종료 rc=$RC ====="
[ -f "$S/.q-COMPLETE" ] || { echo "Q_COMPLETE=NO"; cat "$S/.q-FAILED" 2>/dev/null; tail -40 "$S/qs-build.log" 2>/dev/null; exit 1; }

echo "===== 최종 검증 ====="
ok=1
[ -x "$LFS/usr/bin/marux-quicksettings" ] && echo "  ✅ /usr/bin/marux-quicksettings ($(stat -c %s "$LFS/usr/bin/marux-quicksettings") B)" || { echo "  ❌ 바이너리"; ok=0; }
readelf -h "$LFS/usr/bin/marux-quicksettings" 2>/dev/null | grep -q AArch64 && echo "  ✅ AArch64 ELF" || { echo "  ❌ 아키텍처"; ok=0; }
[ "$ok" = 1 ] && echo "QS_COMPLETE=YES" || { echo "QS_COMPLETE=NO"; exit 1; }
