#!/bin/bash
# =============================================================================
# ⚠️ x86_64 변환본 (2026-08-28, x86 데스크톱 패리티) — 원본 = 같은 이름 -arm64.sh
#   빌드 루트 /home/administrator/MaruxOS/x86-parity, rootfs 사본 rootfs-lfs-parity 안에서 **네이티브 chroot** 빌드
#   (qemu/binfmt 불필요 → 관련 줄 무력화, JOBS 6→32). ARM64 전용 게이트(.b2/.w 마커)는 x86 실체 검사로 대체.
# =============================================================================
# =============================================================================
# MaruxOS 2.0.0 "Cooked" — ARM64 배치 A: 데스크톱 polish 빌드 (feh + mc)
# -----------------------------------------------------------------------------
# x86_64 최신버전 기능 패리티를 위한 유틸 2종:
#   - feh   : 배경화면 설정 (imlib2/X11/Xinerama 기반). 5c에서 imlib2/libX11/libXinerama 이미 빌드됨.
#   - mc    : 파일 매니저 (ncursesw/glib2 기반). 둘 다 rootfs에 존재.
# Firefox는 여기 없음 — gtk3 런타임 의존 → 배치 B(Pi 네이티브 gtk3 후) 이동.
# qemu-chroot 네이티브 aarch64 빌드. resumable 마커(.5A-markers). 5c와 동일 스캐폴드.
# 성공기준: /usr/bin/feh + /usr/bin/mc. root로 실행할 것 (wsl -u root).
# =============================================================================
set -uo pipefail
B=/home/administrator/MaruxOS/x86-parity
LFS=$B/rootfs-lfs-parity
S=$LFS/sources
MC_VER=4.8.31
FEH_VER=3.10.3

[[ "$LFS" == *"x86-parity"* ]] || { echo "🚨 ABORT: $LFS 경로 오류"; exit 1; }
[[ "$LFS" == *"/MaruxOS/build"* ]] && { echo "🚨 ABORT: x86_64 디렉토리"; exit 1; }
[ -x "$LFS/usr/bin/openbox" ] || { echo "🚨 ABORT: 5c 미완료 (openbox 없음)"; exit 1; }
[ -e "$LFS/usr/lib/libImlib2.so.1" ] || { echo "🚨 ABORT: imlib2 없음 (feh 의존성)"; exit 1; }
[ -e "$LFS/usr/lib/libncursesw.so.6" ] || { echo "🚨 ABORT: ncursesw 없음 (mc 의존성)"; exit 1; }
[ -e "$LFS/usr/lib/libglib-2.0.so" ] || { echo "🚨 ABORT: glib2 없음 (mc 의존성)"; exit 1; }

# ---------- 소스 fetch (호스트, 인터넷) ----------
mkdir -p "$S"
fetch(){  # $1=파일명 $2...=미러 URL들
  local out="$S/$1"; shift
  [ -s "$out" ] && { echo "[fetch] SKIP $(basename "$out")"; return 0; }
  for url in "$@"; do
    echo "[fetch] $url"
    if timeout 180 wget -q -O "$out" "$url"; then
      [ -s "$out" ] && { echo "  OK $(ls -lh "$out" | awk '{print $5}')"; return 0; }
    fi
    rm -f "$out"
  done
  echo "🚨 ABORT: fetch 실패 $1"; return 1
}
fetch "mc-${MC_VER}.tar.xz" \
  "http://ftp.midnight-commander.org/mc-${MC_VER}.tar.xz" \
  "https://ftp.osuosl.org/pub/midnightcommander/mc-${MC_VER}.tar.xz" || exit 1
fetch "feh-${FEH_VER}.tar.bz2" \
  "https://feh.finalrewind.org/feh-${FEH_VER}.tar.bz2" \
  "https://github.com/derf/feh/archive/refs/tags/${FEH_VER}.tar.gz" || exit 1

# ---------- binfmt + qemu + mounts + CA (5c와 동일) ----------
mountpoint -q /proc/sys/fs/binfmt_misc || mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc
if [ ! -e /proc/sys/fs/binfmt_misc/qemu-aarch64 ]; then
  echo ':qemu-aarch64:M::\x7f\x45\x4c\x46\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-aarch64-static:F' > /proc/sys/fs/binfmt_misc/register
fi
: # x86 네이티브 — qemu 불필요
cp -f /etc/resolv.conf "$LFS/etc/resolv.conf" 2>/dev/null || true
mkdir -p "$LFS/etc/ssl/certs"; cp -f /etc/ssl/certs/ca-certificates.crt "$LFS/etc/ssl/certs/" 2>/dev/null || true
rm -f "$LFS"/sources/*.tar.*.1 2>/dev/null || true
for fs in dev dev/pts proc sys run; do
  mkdir -p "$LFS/$fs"; mountpoint -q "$LFS/$fs" && continue
  case $fs in
    dev) mount --bind /dev "$LFS/dev";; dev/pts) mount --bind /dev/pts "$LFS/dev/pts";;
    proc) mount -t proc proc "$LFS/proc";; sys) mount -t sysfs sysfs "$LFS/sys";; run) mount -t tmpfs tmpfs "$LFS/run";;
  esac
done

# ---------- inside-chroot 빌드 ----------
cat > "$LFS/root/5A-inside.sh" <<'INSIDE'
#!/bin/bash
set -uo pipefail
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
export PKG_CONFIG_PATH=/usr/lib/pkgconfig:/usr/lib64/pkgconfig:/usr/share/pkgconfig   # x86: lib64 분리 구조
export LC_ALL=C
JOBS=32
MARKDIR=/sources/.5A-markers; mkdir -p "$MARKDIR"
rm -f /sources/.5A-FAILED /sources/.5A-COMPLETE
log(){ echo "[5A] $*"; }

# ---- mc (autotools) ----
if [ ! -f "$MARKDIR/mc" ]; then
  tf=$(ls /sources/mc-[0-9]*.tar.* 2>/dev/null | tail -1)
  [ -z "$tf" ] && { echo "FAILED_AT=mc(no-source)" > /sources/.5A-FAILED; exit 1; }
  dir=$(tar tf "$tf" | head -1 | cut -d/ -f1)
  log "BUILD $dir [auto]"
  cd /sources && rm -rf "$dir" && tar xf "$tf" && cd "$dir" || { echo "FAILED_AT=mc(extract)" > /sources/.5A-FAILED; exit 1; }
  for cf in $(find . -name config.guess 2>/dev/null); do cp -f /usr/share/automake-1.16/config.guess "$cf" 2>/dev/null; done
  for cf in $(find . -name config.sub   2>/dev/null); do cp -f /usr/share/automake-1.16/config.sub   "$cf" 2>/dev/null; done
  ( ./configure --prefix=/usr --sysconfdir=/etc \
        --with-screen=ncurses --without-x --disable-static \
        --without-gpm-mouse --enable-charset \
        --disable-doc --without-libssh2 \
    && make -j$JOBS && make install ) ; rc=$?
  [ $rc -ne 0 ] && { log "FAIL mc rc=$rc"; echo "FAILED_AT=mc(rc=$rc)" > /sources/.5A-FAILED; exit 1; }
  ldconfig 2>/dev/null || true
  touch "$MARKDIR/mc"; cd /sources && rm -rf "$dir"; log "OK mc"
else log "SKIP mc"; fi

# ---- feh (plain Makefile, no configure) ----
if [ ! -f "$MARKDIR/feh" ]; then
  tf=$(ls /sources/feh-[0-9]*.tar.* 2>/dev/null | tail -1)
  [ -z "$tf" ] && { echo "FAILED_AT=feh(no-source)" > /sources/.5A-FAILED; exit 1; }
  dir=$(tar tf "$tf" | head -1 | cut -d/ -f1)
  log "BUILD $dir [make]"
  cd /sources && rm -rf "$dir" && tar xf "$tf" && cd "$dir" || { echo "FAILED_AT=feh(extract)" > /sources/.5A-FAILED; exit 1; }
  # 최소 feh: curl/exif/inotify/magic off, xinerama on (5c에서 libXinerama 빌드됨)
  ( make PREFIX=/usr curl=0 xinerama=1 exif=0 inotify=0 magic=0 -j$JOBS \
    && make PREFIX=/usr install ) ; rc=$?
  [ $rc -ne 0 ] && { log "FAIL feh rc=$rc"; echo "FAILED_AT=feh(rc=$rc)" > /sources/.5A-FAILED; exit 1; }
  touch "$MARKDIR/feh"; cd /sources && rm -rf "$dir"; log "OK feh"
else log "SKIP feh"; fi

log "===== 5A ALL DONE ====="
ok=1
for b in mc feh; do command -v $b >/dev/null 2>&1 && echo "  ✅ $b ($(command -v $b))" || { echo "  ❌ $b"; ok=0; }; done
[ "$ok" = 1 ] && touch /sources/.5A-COMPLETE || echo "FAILED_AT=final" > /sources/.5A-FAILED
INSIDE
chmod +x "$LFS/root/5A-inside.sh"
echo "===== 5A build 시작 (chroot, JOBS=32) $(date 2>/dev/null) ====="
chroot "$LFS" /bin/bash /root/5A-inside.sh
RC=$?
echo "===== 5A build 종료 rc=$RC $(date 2>/dev/null) ====="
if [ -f "$LFS/sources/.5A-COMPLETE" ]; then
  echo "5A_COMPLETE=YES"
  file "$LFS/usr/bin/feh" "$LFS/usr/bin/mc" 2>&1 | sed 's/^/  /'
else
  echo "5A_COMPLETE=NO"; cat "$LFS/sources/.5A-FAILED" 2>/dev/null
fi
