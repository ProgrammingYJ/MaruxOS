#!/bin/bash
# =============================================================================
# MaruxOS 2.0.0 "Cooked" — ARM64 Stage 5c: 데스크톱 (openbox + tint2 + idesk)
# -----------------------------------------------------------------------------
# 미들웨어(pcre2/glib/cairo/pango/harfbuzz/fribidi/imlib2 등) + WM/패널/아이콘.
# qemu-chroot 네이티브 aarch64 빌드. resumable 마커(.5c-markers). binfmt 재등록 preamble.
# cmake는 prebuilt aarch64를 /opt/cmake-tmp에서 transient 사용(tint2/libjpeg-turbo용, 최종이미지 미포함).
# 성공기준: /usr/bin/openbox.
# =============================================================================
set -uo pipefail
B=/home/administrator/MaruxOS-arm64
LFS=$B/rootfs-clfs-arm64

[[ "$LFS" == *"MaruxOS-arm64"* ]] || { echo "🚨 ABORT: $LFS"; exit 1; }
[ -x "$LFS/tools/bin/aarch64-lfs-linux-gnu-gcc" ] || { echo "🚨 ABORT: 툴체인 없음"; exit 1; }

# ---------- binfmt + qemu + mounts + CA ----------
mountpoint -q /proc/sys/fs/binfmt_misc || mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc
if [ ! -e /proc/sys/fs/binfmt_misc/qemu-aarch64 ]; then
  echo ':qemu-aarch64:M::\x7f\x45\x4c\x46\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-aarch64-static:F' > /proc/sys/fs/binfmt_misc/register
fi
[ -e "$LFS/usr/bin/qemu-aarch64-static" ] || cp /usr/bin/qemu-aarch64-static "$LFS/usr/bin/"
cp -f /etc/resolv.conf "$LFS/etc/resolv.conf" 2>/dev/null || true
mkdir -p "$LFS/etc/ssl/certs"; cp -f /etc/ssl/certs/ca-certificates.crt "$LFS/etc/ssl/certs/" 2>/dev/null || true
# transient cmake 확인
[ -x "$LFS/opt/cmake-tmp/bin/cmake" ] || { echo "🚨 ABORT: /opt/cmake-tmp/bin/cmake 없음 (prebuilt cmake 먼저 풀 것)"; exit 1; }
# idesk(2005) 호환: modern imlib2는 imlib2-config 스크립트 없이 pkg-config만 → 셰임 생성
cat > "$LFS/usr/bin/imlib2-config" <<'SHIM'
#!/bin/sh
case "$1" in
  --cflags) exec pkg-config --cflags imlib2 ;;
  --libs)   exec pkg-config --libs imlib2 ;;
  --version) exec pkg-config --modversion imlib2 ;;
  *) exec pkg-config imlib2 ;;
esac
SHIM
chmod +x "$LFS/usr/bin/imlib2-config"
# idesk 0.7.5 patch: stat() → ::stat() (modern g++가 struct stat 타입 생성자로 오인)
cat > "$LFS/sources/patch-idesk.sh" <<'PATCH'
#!/bin/sh
# sys/stat.h 명시 include (구조체만 있고 stat() 함수 프로토타입 없음) + ::stat 명시
for f in src/DesktopConfig.cpp src/XImlib2Background.cpp; do
  grep -q "include <sys/stat.h>" "$f" || { printf '#include <sys/types.h>\n#include <sys/stat.h>\n#include <unistd.h>\n' | cat - "$f" > "$f.tmp" && mv "$f.tmp" "$f"; }
done
sed -i 's/if( stat(/if( ::stat(/g' src/DesktopConfig.cpp src/XImlib2Background.cpp
PATCH
rm -f "$LFS"/sources/*.tar.*.1 2>/dev/null || true
for fs in dev dev/pts proc sys run; do
  mkdir -p "$LFS/$fs"; mountpoint -q "$LFS/$fs" && continue
  case $fs in
    dev) mount --bind /dev "$LFS/dev";; dev/pts) mount --bind /dev/pts "$LFS/dev/pts";;
    proc) mount -t proc proc "$LFS/proc";; sys) mount -t sysfs sysfs "$LFS/sys";; run) mount -t tmpfs tmpfs "$LFS/run";;
  esac
done

# ---------- inside-chroot 빌드 스크립트 ----------
cat > "$LFS/root/5c-inside.sh" <<'INSIDE'
#!/bin/bash
set -uo pipefail
export PATH=/opt/cmake-tmp/bin:/usr/bin:/bin:/usr/sbin:/sbin
export PKG_CONFIG_PATH=/usr/lib/pkgconfig:/usr/share/pkgconfig
export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
export LC_ALL=C
JOBS=6
MARKDIR=/sources/.5c-markers; mkdir -p "$MARKDIR"
rm -f /sources/.5c-FAILED /sources/.5c-COMPLETE
log(){ echo "[5c] $*"; }
find_tar(){ ls /sources/$1-[0-9]*.tar.* 2>/dev/null | grep -vE '\.(sha256|sig|asc)$' | sort -V | tail -1; }
topdir(){ tar tf "$1" 2>/dev/null | grep -vE '^\./?$' | sed 's#^\./##' | head -1 | cut -d/ -f1; }
do_build(){  # $1=auto|meson|cmake  $2=glob  rest=args
  local tool=$1 glob=$2; shift 2
  local mk="$MARKDIR/$glob"
  [ -f "$mk" ] && { log "SKIP $glob"; return 0; }
  local tf; tf=$(find_tar "$glob")
  [ -z "$tf" ] && { log "FAIL $glob no-source"; echo "FAILED_AT=$glob(no-source)" > /sources/.5c-FAILED; exit 1; }
  local dir; dir=$(topdir "$tf")
  log "BUILD $dir [$tool]"
  cd /sources && rm -rf "$dir" && tar xf "$tf" && cd "$dir" || { echo "FAILED_AT=$glob(extract)" > /sources/.5c-FAILED; exit 1; }
  [ -f "/sources/patch-$glob.sh" ] && { log "patch $glob"; sh "/sources/patch-$glob.sh" || { echo "FAILED_AT=$glob(patch)" > /sources/.5c-FAILED; exit 1; }; }
  local rc=0
  case $tool in
    auto)  ( for cf in $(find . -name config.guess 2>/dev/null); do cp -f /usr/share/automake-1.16/config.guess "$cf" 2>/dev/null; done
            for cf in $(find . -name config.sub   2>/dev/null); do cp -f /usr/share/automake-1.16/config.sub   "$cf" 2>/dev/null; done
            ./configure --prefix=/usr "$@" && make -j$JOBS && make install ); rc=$? ;;
    meson) ( meson setup _b --prefix=/usr --buildtype=release "$@" && ninja -C _b -j$JOBS && ninja -C _b install ); rc=$? ;;
    cmake) ( cmake -S . -B _b -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release "$@" && cmake --build _b -j$JOBS && cmake --install _b ); rc=$? ;;
  esac
  [ $rc -ne 0 ] && { log "FAIL $dir rc=$rc"; echo "FAILED_AT=$glob" > /sources/.5c-FAILED; exit 1; }
  ldconfig 2>/dev/null || true
  touch "$mk"; cd /sources && rm -rf "$dir"; log "OK $dir"
}

# ---- 미들웨어 ----
do_build auto  pcre2      --enable-unicode --enable-pcre2-16 --enable-pcre2-32 --disable-static
do_build auto  libxml2    --disable-static --without-python
do_build meson glib       -Dtests=false -Dselinux=disabled -Dsysprof=disabled
do_build auto  libpng     --disable-static
do_build cmake libjpeg-turbo -DCMAKE_INSTALL_LIBDIR=/usr/lib -DENABLE_STATIC=FALSE
do_build meson fribidi    -Dtests=false -Ddocs=false
do_build meson harfbuzz   -Dtests=disabled -Ddocs=disabled -Dbenchmark=disabled -Dfreetype=enabled -Dglib=enabled -Dcairo=disabled
do_build meson cairo      -Dtests=disabled -Dxlib=enabled
do_build meson pango      -Dintrospection=disabled
do_build auto  imlib2     --disable-static
# ---- X 세션/확장 라이브러리 ----
do_build auto  libICE     --disable-static
do_build auto  libSM      --disable-static
do_build auto  libXinerama --disable-static
# startup-notification 스킵: xcb-util 의존 + openbox 선택기능(busy 커서)일뿐 → MVP 제외 (2.0.x에서 재검토)
# ---- WM / 패널 / 아이콘 ----
do_build auto  openbox    --sysconfdir=/etc --disable-static
do_build cmake tint2      -DENABLE_BATTERY=0 -DENABLE_RSVG=0 -DENABLE_SN=0 -DENABLE_TINT2CONF=0
do_build auto  idesk
# ---- 터미널 + 배경 유틸 (데모용) ----
do_build auto  libXt         --disable-static
do_build auto  libXpm        --disable-static
do_build auto  libXmu        --disable-static
do_build auto  libXaw        --disable-static
# xsetroot 스킵(비필수 배경색용, 빌드이슈) — 배경은 X 기본 회색
do_build auto  xterm

log "===== 5c ALL DONE ====="
ok=1
for b in openbox tint2 idesk; do command -v $b >/dev/null 2>&1 && echo "  ✅ $b ($(command -v $b))" || { echo "  ❌ $b"; ok=0; }; done
[ -x /usr/bin/openbox ] && touch /sources/.5c-COMPLETE || echo "FAILED_AT=final" > /sources/.5c-FAILED
INSIDE
chmod +x "$LFS/root/5c-inside.sh"
echo "===== 5c build 시작 (chroot, JOBS=6) $(date 2>/dev/null) ====="
chroot "$LFS" /bin/bash /root/5c-inside.sh
RC=$?
echo "===== 5c build 종료 rc=$RC $(date 2>/dev/null) ====="
[ -f "$LFS/sources/.5c-COMPLETE" ] && echo "5C_COMPLETE=YES" || { echo "5C_COMPLETE=NO"; cat "$LFS/sources/.5c-FAILED" 2>/dev/null; }
