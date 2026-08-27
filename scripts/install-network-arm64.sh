#!/bin/bash
# =============================================================================
# MaruxOS 2.0.0 "Cooked" — ARM64 네트워크 스택: dhcpcd + chrony (유선 DHCP + NTP)
# -----------------------------------------------------------------------------
# 정찰 결과 (2026-07-25):
#   - rootfs에 DHCP 클라이언트 전무 → xinitrc의 dhcpcd 가드가 조용히 스킵 = 네트워크 불통 원인
#   - ifconfig.eth0 = ipv4-static 192.168.1.50 플레이스홀더(부팅마다 엉뚱한 고정IP) → dhcpcd로 교체
#   - NTP 전무 + Pi 4B는 RTC 없음 → 시계 매부팅 1970년 → chrony(makestep)로 해결
#   - WiFi는 커널 CFG80211/MAC80211=m(no-modules 원칙 위반 상태) → 커널 재빌드 필요 = 후속 배치
# 내용:
#   ① dhcpcd 10.0.6 (privsep off — from-scratch rootfs 단순화) [qemu-chroot]
#   ② chrony 4.5 (chronyd, makestep 1 -1 = RTC 없는 Pi의 대오프셋 즉시 스텝) [qemu-chroot]
#   ③ 부팅 통합: x86 검증자산 /lib/services/dhcpcd 이식 + ifconfig.eth0 SERVICE=dhcpcd
#      + init.d/chronyd + rc3.d/S25chronyd (S20network 뒤)
#   ⚠️ resolv.conf는 여기서 안 건드림(chroot이 WSL 것 복사해 씀) → v12 빌드 [5b]에서 클린 생성
# resumable(.n-markers). 완료기준: .n-COMPLETE. 실행: wsl -u root bash <this>
# =============================================================================
set -uo pipefail
B=/home/administrator/MaruxOS-arm64
LFS=$B/rootfs-clfs-arm64
S=$LFS/sources
X86=/home/administrator/MaruxOS/build/rootfs-lfs
[[ "$LFS" == *"MaruxOS-arm64"* ]] || { echo "🚨 ABORT: $LFS"; exit 1; }
[ -f "$S/.b2-COMPLETE" ] || { echo "🚨 ABORT: B-2 미완"; exit 1; }
[ -f "$X86/lib/services/dhcpcd" ] || { echo "🚨 ABORT: x86 dhcpcd 서비스 스크립트 없음"; exit 1; }

# ---------- 소스 fetch (호스트) ----------
fetch(){ [ -s "$2" ] && return 0; echo "[fetch] $(basename "$2")"; timeout 300 wget -q -O "$2" "$1" || { rm -f "$2"; echo "🚨 ABORT: fetch 실패 $1"; exit 1; }; echo "  OK $(ls -lh "$2" | awk '{print $5}')"; }
fetch "https://github.com/NetworkConfiguration/dhcpcd/releases/download/v10.0.6/dhcpcd-10.0.6.tar.xz" "$S/dhcpcd-10.0.6.tar.xz"
fetch "https://chrony-project.org/releases/chrony-4.5.tar.gz" "$S/chrony-4.5.tar.gz"

# ---------- binfmt + mounts (B-1/B-2 스캐폴드) ----------
mountpoint -q /proc/sys/fs/binfmt_misc || mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc
[ -e /proc/sys/fs/binfmt_misc/qemu-aarch64 ] || echo ':qemu-aarch64:M::\x7f\x45\x4c\x46\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-aarch64-static:F' > /proc/sys/fs/binfmt_misc/register
[ -e "$LFS/usr/bin/qemu-aarch64-static" ] || cp /usr/bin/qemu-aarch64-static "$LFS/usr/bin/"
cp -f /etc/resolv.conf "$LFS/etc/resolv.conf" 2>/dev/null || true
for fs in dev dev/pts proc sys run; do
  mkdir -p "$LFS/$fs"; mountpoint -q "$LFS/$fs" && continue
  case $fs in dev) mount --bind /dev "$LFS/dev";; dev/pts) mount --bind /dev/pts "$LFS/dev/pts";; proc) mount -t proc proc "$LFS/proc";; sys) mount -t sysfs sysfs "$LFS/sys";; run) mount -t tmpfs tmpfs "$LFS/run";; esac
done

# ---------- chroot 내부 빌드 ----------
cat > "$LFS/root/net-inside.sh" <<'INSIDE'
#!/bin/bash
set -uo pipefail
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
export LC_ALL=C
JOBS=6
MARKDIR=/sources/.n-markers; mkdir -p "$MARKDIR"
rm -f /sources/.n-FAILED /sources/.n-COMPLETE
log(){ echo "[net] $(date '+%H:%M:%S') $*"; }
fail(){ echo "FAILED_AT=$1" > /sources/.n-FAILED; exit 1; }

# ---- dhcpcd 10.0.6 ----
if [ ! -f "$MARKDIR/dhcpcd" ]; then
  log "BUILD dhcpcd-10.0.6"
  cd /sources && rm -rf dhcpcd-10.0.6 && tar xf dhcpcd-10.0.6.tar.xz && cd dhcpcd-10.0.6 || fail dhcpcd-extract
  ( ./configure --prefix=/usr --sysconfdir=/etc --libexecdir=/usr/lib/dhcpcd \
      --dbdir=/var/lib/dhcpcd --runstatedir=/run --disable-privsep \
    && make -j$JOBS && make install ) > /sources/dhcpcd-build.log 2>&1; rc=$?
  [ $rc -ne 0 ] && { tail -25 /sources/dhcpcd-build.log; fail "dhcpcd(rc=$rc)"; }
  touch "$MARKDIR/dhcpcd"; cd /sources && rm -rf dhcpcd-10.0.6; log "OK dhcpcd"
else log "SKIP dhcpcd"; fi
/usr/sbin/dhcpcd --version >/dev/null 2>&1 || fail dhcpcd-run

# ---- chrony 4.5 ----
if [ ! -f "$MARKDIR/chrony" ]; then
  log "BUILD chrony-4.5"
  cd /sources && rm -rf chrony-4.5 && tar xf chrony-4.5.tar.gz && cd chrony-4.5 || fail chrony-extract
  ( ./configure --prefix=/usr && make -j$JOBS && make install ) > /sources/chrony-build.log 2>&1; rc=$?
  [ $rc -ne 0 ] && { tail -25 /sources/chrony-build.log; fail "chrony(rc=$rc)"; }
  touch "$MARKDIR/chrony"; cd /sources && rm -rf chrony-4.5; log "OK chrony"
else log "SKIP chrony"; fi
/usr/sbin/chronyd --version >/dev/null 2>&1 || fail chronyd-run

# ---- chrony 설정 (멱등) ----
mkdir -p /var/lib/chrony
cat > /etc/chrony.conf <<'CONF'
# MaruxOS — Pi 4B는 RTC 없음: 부팅 시 대오프셋을 즉시 스텝(makestep 1 -1)
pool pool.ntp.org iburst
makestep 1 -1
driftfile /var/lib/chrony/drift
CONF
log "chrony.conf 생성"

log "===== 검증 ====="
ok=1
for f in /usr/sbin/dhcpcd /usr/sbin/chronyd /usr/bin/chronyc /etc/chrony.conf; do
  [ -e "$f" ] && echo "  ✅ $f" || { echo "  ❌ $f"; ok=0; }
done
[ "$ok" = 1 ] && touch /sources/.n-COMPLETE || fail final
log "===== NET ALL DONE ====="
INSIDE
chmod +x "$LFS/root/net-inside.sh"
echo "===== network build 시작 (chroot) $(date) ====="
chroot "$LFS" /bin/bash /root/net-inside.sh
RC=$?
echo "===== network build 종료 rc=$RC ====="
[ -f "$S/.n-COMPLETE" ] || { echo "N_COMPLETE=NO"; cat "$S/.n-FAILED" 2>/dev/null; exit 1; }

# ---------- 부팅 통합 (호스트측 파일작업, 멱등) ----------
echo "[통합] /lib/services/dhcpcd (x86 검증자산 이식)"
cp -f "$X86/lib/services/dhcpcd" "$LFS/lib/services/dhcpcd"
chmod 755 "$LFS/lib/services/dhcpcd"

echo "[통합] ifconfig.eth0: ipv4-static 플레이스홀더 → dhcpcd"
cat > "$LFS/etc/sysconfig/ifconfig.eth0" <<'IFCFG'
ONBOOT=yes
IFACE=eth0
SERVICE=dhcpcd
DHCP_START="-b -q"
DHCP_STOP="-k"
IFCFG

echo "[통합] init.d/chronyd + S25chronyd (S20network 뒤)"
cat > "$LFS/etc/rc.d/init.d/chronyd" <<'RCSCRIPT'
#!/bin/sh
# MaruxOS chronyd — NTP 시계 동기화 (Pi 4B RTC 없음 → makestep으로 부팅 직후 스텝)
case "$1" in
  start) echo "Starting chronyd..."; /usr/sbin/chronyd ;;
  stop)  echo "Stopping chronyd...";  killall chronyd 2>/dev/null ;;
  restart) $0 stop; sleep 1; $0 start ;;
  *) echo "Usage: $0 {start|stop|restart}"; exit 1 ;;
esac
RCSCRIPT
chmod 755 "$LFS/etc/rc.d/init.d/chronyd"
ln -sf ../init.d/chronyd "$LFS/etc/rc.d/rc3.d/S25chronyd"
ln -sf ../init.d/chronyd "$LFS/etc/rc.d/rc0.d/K74chronyd" 2>/dev/null || true
ln -sf ../init.d/chronyd "$LFS/etc/rc.d/rc6.d/K74chronyd" 2>/dev/null || true

echo "===== 최종 검증 ====="
ok=1
for f in usr/sbin/dhcpcd usr/sbin/chronyd lib/services/dhcpcd etc/chrony.conf etc/rc.d/init.d/chronyd etc/rc.d/rc3.d/S25chronyd; do
  [ -e "$LFS/$f" ] && echo "  ✅ /$f" || { echo "  ❌ /$f"; ok=0; }
done
grep -q "SERVICE=dhcpcd" "$LFS/etc/sysconfig/ifconfig.eth0" && echo "  ✅ ifconfig.eth0=dhcpcd" || { echo "  ❌ ifconfig.eth0"; ok=0; }
[ "$ok" = 1 ] && echo "NET_COMPLETE=YES" || { echo "NET_COMPLETE=NO"; exit 1; }
