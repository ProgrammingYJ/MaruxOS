#!/bin/bash
# =============================================================================
# MaruxOS 2.0.0 "Cooked" — ARM64 배치 W 스텝2: wpa_supplicant (WiFi userspace)
# -----------------------------------------------------------------------------
# 전제: rebuild-kernel-wifi-arm64.sh 완료 (.wifi-kernel-COMPLETE — brcmfmac builtin
#       + 펌웨어 임베드 커널). 이 스크립트는 userspace만 담당.
# 내용:
#   ① libnl 3.9.0 [qemu-chroot] — nl80211 드라이버 인터페이스 의존성
#   ② wpa_supplicant 2.11 [qemu-chroot] — CONFIG_TLS=internal + DRIVER_NL80211_BRCM (openssl 회피,
#      WPA2-PSK MVP. ⚠️ SAE/WPA3는 internal 크립토에 ECC 부재로 제외 — openssl 도입 시 재검토)
#   ③ /etc/wpa_supplicant.conf 템플릿 (자격증명 없음 — update_config=1로 GUI/wpa_cli가 관리.
#      🔐 자격증명은 로컬 메모리 전용, git/배포 이미지 절대 금지)
#   ④ 부팅 통합: init.d/wpasupplicant + S24 (wlan0 존재 시에만 기동 — 구커널 무해)
#      dhcpcd는 xinitrc 인터페이스 루프가 wlan0도 커버 (기존 설계 재사용)
# resumable(.w-markers). 완료기준: .w-COMPLETE. 실행: wsl -u root bash <this>
# =============================================================================
set -uo pipefail
B=/home/administrator/MaruxOS-arm64
LFS=$B/rootfs-clfs-arm64
S=$LFS/sources
[[ "$LFS" == *"MaruxOS-arm64"* ]] || { echo "🚨 ABORT: $LFS"; exit 1; }
[ -f "$S/.n-COMPLETE" ] || { echo "🚨 ABORT: 네트워크 배치 미완"; exit 1; }
[ -f "$B/.wifi-kernel-COMPLETE" ] || { echo "🚨 ABORT: WiFi 커널 재빌드 미완(.wifi-kernel-COMPLETE 없음)"; exit 1; }
[ -f "$LFS/lib/firmware/brcm/brcmfmac43455-sdio.bin" ] || { echo "🚨 ABORT: rootfs 펌웨어 없음"; exit 1; }

# ---------- 소스 fetch (호스트) ----------
fetch(){ [ -s "$2" ] && return 0; echo "[fetch] $(basename "$2")"; timeout 300 wget -q -O "$2" "$1" || { rm -f "$2"; echo "🚨 ABORT: fetch 실패 $1"; exit 1; }; echo "  OK $(ls -lh "$2" | awk '{print $5}')"; }
fetch "https://github.com/thom311/libnl/releases/download/libnl3_9_0/libnl-3.9.0.tar.gz" "$S/libnl-3.9.0.tar.gz"
fetch "https://w1.fi/releases/wpa_supplicant-2.11.tar.gz" "$S/wpa_supplicant-2.11.tar.gz"
fetch "https://www.alsa-project.org/files/pub/utils/alsa-utils-1.2.10.tar.bz2" "$S/alsa-utils-1.2.10.tar.bz2"

# ---------- binfmt + mounts (함정 #5: 세션마다 재등록) ----------
mountpoint -q /proc/sys/fs/binfmt_misc || mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc
[ -e /proc/sys/fs/binfmt_misc/qemu-aarch64 ] || echo ':qemu-aarch64:M::\x7f\x45\x4c\x46\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-aarch64-static:F' > /proc/sys/fs/binfmt_misc/register
[ -e "$LFS/usr/bin/qemu-aarch64-static" ] || cp /usr/bin/qemu-aarch64-static "$LFS/usr/bin/"
cp -f /etc/resolv.conf "$LFS/etc/resolv.conf" 2>/dev/null || true
for fs in dev dev/pts proc sys run; do
  mkdir -p "$LFS/$fs"; mountpoint -q "$LFS/$fs" && continue
  case $fs in dev) mount --bind /dev "$LFS/dev";; dev/pts) mount --bind /dev/pts "$LFS/dev/pts";; proc) mount -t proc proc "$LFS/proc";; sys) mount -t sysfs sysfs "$LFS/sys";; run) mount -t tmpfs tmpfs "$LFS/run";; esac
done

# ---------- chroot 내부 빌드 ----------
cat > "$LFS/root/wifi-inside.sh" <<'INSIDE'
#!/bin/bash
set -uo pipefail
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
export LC_ALL=C
JOBS=6
MARKDIR=/sources/.w-markers; mkdir -p "$MARKDIR"
rm -f /sources/.w-FAILED /sources/.w-COMPLETE
log(){ echo "[wifi] $(date '+%H:%M:%S') $*"; }
fail(){ echo "FAILED_AT=$1" > /sources/.w-FAILED; exit 1; }

# ---- libnl 3.9.0 ----
if [ ! -f "$MARKDIR/libnl" ]; then
  log "BUILD libnl-3.9.0"
  cd /sources && rm -rf libnl-3.9.0 && tar xf libnl-3.9.0.tar.gz && cd libnl-3.9.0 || fail libnl-extract
  ( ./configure --prefix=/usr --sysconfdir=/etc --disable-static \
    && make -j$JOBS && make install ) > /sources/libnl-build.log 2>&1; rc=$?
  [ $rc -ne 0 ] && { tail -25 /sources/libnl-build.log; fail "libnl(rc=$rc)"; }
  touch "$MARKDIR/libnl"; cd /sources && rm -rf libnl-3.9.0; log "OK libnl"
else log "SKIP libnl"; fi
pkg-config --exists libnl-genl-3.0 || fail libnl-pc

# ---- wpa_supplicant 2.11 ----
if [ ! -f "$MARKDIR/wpa" ]; then
  log "BUILD wpa_supplicant-2.11"
  cd /sources && rm -rf wpa_supplicant-2.11 && tar xf wpa_supplicant-2.11.tar.gz \
    && cd wpa_supplicant-2.11/wpa_supplicant || fail wpa-extract
  # ── MaruxOS 패치: 4-way handshake offload 강제 해제 ──────────────────────────
  # brcmfmac은 NL80211_EXT_FEATURE_4WAY_HANDSHAKE_STA_PSK를 광고하지만(펌웨어 sup_wpa)
  # 실제로는 port-authorized를 끝내주지 않아 wpa가 영구 대기 → CONN_FAILED (함정 #30).
  # capability 수용부를 무력화해 wpa가 EAPOL을 직접 처리하는 표준 경로로 돌린다.
  CAPA=src/drivers/driver_nl80211_capa.c
  grep -q "WPA_DRIVER_FLAGS_4WAY_HANDSHAKE_PSK" "../$CAPA" || fail wpa-capa-src-missing
  sed -i     -e 's#capa->flags |= WPA_DRIVER_FLAGS_4WAY_HANDSHAKE_PSK;#(void)0; /* MaruxOS: host 4-way 강제 */#'     -e 's#capa->flags |= WPA_DRIVER_FLAGS_4WAY_HANDSHAKE_8021X;#(void)0; /* MaruxOS: host 4-way 강제 */#'     "../$CAPA"
  grep -q "MaruxOS: host 4-way" "../$CAPA" || fail wpa-capa-patch
  log "PATCH 4-way offload 해제 적용"
  touch /sources/.w-markers/wpa-offload-patched

  cat > .config <<'WPACFG'
CONFIG_DRIVER_NL80211=y
CONFIG_LIBNL32=y
CONFIG_CTRL_IFACE=y
CONFIG_BACKEND=file
CONFIG_TLS=internal
CONFIG_INTERNAL_LIBTOMMATH=y
CONFIG_INTERNAL_LIBTOMMATH_FAST=y
CONFIG_IEEE80211W=y
# Broadcom(brcmfmac) 전용 nl80211 확장 — Raspberry Pi OS 공식 빌드와 동일.
# 없으면 wpa가 펌웨어 4-way offload를 신뢰하고 대기만 하다 CONN_FAILED로 끝난다
# (v19 실기기 실측: "wait for driver port authorized indication" → 10초 타임아웃).
CONFIG_DRIVER_NL80211_BRCM=y
WPACFG
  ( make -j$JOBS ) > /sources/wpa-build.log 2>&1; rc=$?
  [ $rc -ne 0 ] && { tail -25 /sources/wpa-build.log; fail "wpa(rc=$rc)"; }
  install -m 755 wpa_supplicant wpa_cli wpa_passphrase /usr/sbin/
  ln -sf ../sbin/wpa_cli /usr/bin/wpa_cli
  touch "$MARKDIR/wpa"; cd /sources && rm -rf wpa_supplicant-2.11; log "OK wpa_supplicant"
else log "SKIP wpa"; fi
/usr/sbin/wpa_supplicant -v >/dev/null 2>&1 || fail wpa-run
/usr/sbin/wpa_passphrase x deadbeef00 >/dev/null 2>&1 || fail wpa-passphrase-run

# ---- alsa-utils 1.2.10 (v18 실기기: amixer 부재로 퀵설정 볼륨 백엔드 죽어있었음) ----
if [ ! -f "$MARKDIR/alsautils" ]; then
  log "BUILD alsa-utils-1.2.10"
  cd /sources && rm -rf alsa-utils-1.2.10 && tar xf alsa-utils-1.2.10.tar.bz2 && cd alsa-utils-1.2.10 || fail alsautils-extract
  ( ./configure --prefix=/usr --disable-alsaconf --disable-bat --disable-xmlto --disable-rst2man \
    && make -j$JOBS && make install ) > /sources/alsautils-build.log 2>&1; rc=$?
  [ $rc -ne 0 ] && { tail -25 /sources/alsautils-build.log; fail "alsautils(rc=$rc)"; }
  touch "$MARKDIR/alsautils"; cd /sources && rm -rf alsa-utils-1.2.10; log "OK alsa-utils"
else log "SKIP alsa-utils"; fi
/usr/bin/amixer --version >/dev/null 2>&1 || fail amixer-run

# ---- /etc/asound.conf — vc4-hdmi 카드엔 HW 볼륨 없음 → softvol로 Master 생성 (멱등) ----
cat > /etc/asound.conf <<'ACONF'
# MaruxOS — HDMI 오디오(vc4-hdmi)는 하드웨어 볼륨 컨트롤이 없음.
# softvol 플러그인으로 "Master" 볼륨 컨트롤 생성 (첫 재생 시 컨트롤 등록됨).
pcm.!default {
    type softvol
    slave.pcm "plughw:0,0"
    control { name "Master"; card 0 }
}
ctl.!default { type hw; card 0 }
ACONF
log "asound.conf (softvol Master) ✓"

# ---- /etc/wpa_supplicant.conf 템플릿 (멱등, 자격증명 없음) ----
if [ ! -f /etc/wpa_supplicant.conf ]; then
  cat > /etc/wpa_supplicant.conf <<'CONF'
# MaruxOS WiFi — 네트워크는 퀵설정 GUI/wpa_cli가 추가·저장 (update_config=1)
# 🔐 이 파일 기본 배포본엔 자격증명 없음 — 릴리즈 이미지 sanitize 원칙
ctrl_interface=/var/run/wpa_supplicant
ctrl_interface_group=0
update_config=1
country=KR
CONF
  chmod 600 /etc/wpa_supplicant.conf
fi
log "wpa_supplicant.conf 템플릿 ✓"

log "===== 검증 ====="
ok=1
for f in /usr/lib/libnl-genl-3.so /usr/sbin/wpa_supplicant /usr/sbin/wpa_cli /usr/sbin/wpa_passphrase /etc/wpa_supplicant.conf /usr/bin/amixer /usr/bin/aplay /etc/asound.conf; do
  [ -e "$f" ] && echo "  ✅ $f" || { echo "  ❌ $f"; ok=0; }
done
[ "$ok" = 1 ] && touch /sources/.w-COMPLETE || fail final
log "===== WIFI USERSPACE ALL DONE ====="
INSIDE
chmod +x "$LFS/root/wifi-inside.sh"
echo "===== wifi userspace build 시작 (chroot) $(date) ====="
chroot "$LFS" /bin/bash /root/wifi-inside.sh
RC=$?
echo "===== wifi userspace build 종료 rc=$RC ====="
[ -f "$S/.w-COMPLETE" ] || { echo "W_COMPLETE=NO"; cat "$S/.w-FAILED" 2>/dev/null; exit 1; }

# ---------- 부팅 통합 (호스트측, 멱등) ----------
echo "[통합] init.d/wpasupplicant + S24 (wlan0 가드 — 구커널 무해)"
cat > "$LFS/etc/rc.d/init.d/wpasupplicant" <<'RCSCRIPT'
#!/bin/sh
# MaruxOS wpa_supplicant — wlan0 존재 시에만 기동. 네트워크 등록은 퀵설정 GUI/wpa_cli.
case "$1" in
  start)
    [ -d /sys/class/net/wlan0 ] || exit 0
    echo "Starting wpa_supplicant on wlan0..."
    /usr/sbin/wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant.conf
    # 규제 도메인 적용 — conf의 country=KR이 초기 적용되지 않아 5GHz 채널이 막히는 현상
    # (v19 실측: set_chanspec 0xd0XX fail -52 무더기). 런타임 설정하면 REG_CHANGE가 발생한다.
    sleep 2; /usr/sbin/wpa_cli -i wlan0 set country KR >/dev/null 2>&1 || true
    ;;
  stop)  echo "Stopping wpa_supplicant..."; killall wpa_supplicant 2>/dev/null ;;
  restart) $0 stop; sleep 1; $0 start ;;
  *) echo "Usage: $0 {start|stop|restart}"; exit 1 ;;
esac
RCSCRIPT
chmod 755 "$LFS/etc/rc.d/init.d/wpasupplicant"
ln -sf ../init.d/wpasupplicant "$LFS/etc/rc.d/rc3.d/S24wpasupplicant"
ln -sf ../init.d/wpasupplicant "$LFS/etc/rc.d/rc0.d/K75wpasupplicant" 2>/dev/null || true
ln -sf ../init.d/wpasupplicant "$LFS/etc/rc.d/rc6.d/K75wpasupplicant" 2>/dev/null || true

echo "===== 최종 검증 ====="
ok=1
for f in usr/sbin/wpa_supplicant usr/sbin/wpa_cli etc/wpa_supplicant.conf etc/rc.d/init.d/wpasupplicant etc/rc.d/rc3.d/S24wpasupplicant lib/firmware/brcm/brcmfmac43455-sdio.bin lib/firmware/regulatory.db; do
  [ -e "$LFS/$f" ] && echo "  ✅ /$f" || { echo "  ❌ /$f"; ok=0; }
done
grep -q "update_config=1" "$LFS/etc/wpa_supplicant.conf" && echo "  ✅ conf 템플릿" || { echo "  ❌ conf"; ok=0; }
grep -rq "psk=" "$LFS/etc/wpa_supplicant.conf" && { echo "  🚨 conf에 자격증명 흔적!"; ok=0; } || echo "  ✅ 자격증명 無 (sanitize)"
[ "$ok" = 1 ] && echo "WIFI_COMPLETE=YES" || { echo "WIFI_COMPLETE=NO"; exit 1; }
