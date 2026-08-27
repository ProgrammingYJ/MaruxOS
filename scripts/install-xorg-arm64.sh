#!/bin/bash
# =============================================================================
# MaruxOS 2.0.0 "Cooked" — ARM64 Stage 5b: X.org minimal stack (qemu-chroot 네이티브 aarch64 빌드)
# -----------------------------------------------------------------------------
# ~25개 패키지를 $LFS 안에 네이티브 aarch64로 빌드 (qemu-user 에뮬레이션).
# - Resumable: 패키지별 마커(/sources/.5b-markers/<pkg>) → 재실행 시 완료분 스킵.
# - Idempotent binfmt 재등록 preamble (트랩 #5: WSL 유휴 재시작 시 binfmt 소실 대응).
# - 실패 시 해당 패키지에서 정지 + /sources/.5b-FAILED 마커.
# 성공기준: Xorg 바이너리 빌드 → 다음 세션에 `X :0`로 HDMI 회색 root+커서 검증.
# =============================================================================
set -uo pipefail
B=/home/administrator/MaruxOS-arm64
LFS=$B/rootfs-clfs-arm64

# ---------- 게이트: ARM64 빌드 루트 분리 ----------
[[ "$LFS" == *"MaruxOS-arm64"* ]] || { echo "🚨 ABORT: LFS가 arm64 루트 아님: $LFS"; exit 1; }
[[ "$LFS" == *"/MaruxOS/build"* ]] && { echo "🚨 ABORT: x86_64 디렉토리"; exit 1; }
[ -x "$LFS/tools/bin/aarch64-lfs-linux-gnu-gcc" ] || { echo "🚨 ABORT: aarch64 툴체인 없음"; exit 1; }

# ---------- host-side: binfmt + qemu + resolv + CA + bind mounts ----------
mountpoint -q /proc/sys/fs/binfmt_misc || mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc
if [ ! -e /proc/sys/fs/binfmt_misc/qemu-aarch64 ]; then
  echo ':qemu-aarch64:M::\x7f\x45\x4c\x46\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-aarch64-static:F' > /proc/sys/fs/binfmt_misc/register
  echo "[5b] binfmt 재등록"
fi
[ -e "$LFS/usr/bin/qemu-aarch64-static" ] || cp /usr/bin/qemu-aarch64-static "$LFS/usr/bin/"
cp -f /etc/resolv.conf "$LFS/etc/resolv.conf" 2>/dev/null || true
mkdir -p "$LFS/etc/ssl/certs"
cp -f /etc/ssl/certs/ca-certificates.crt "$LFS/etc/ssl/certs/" 2>/dev/null || true
# 중복 다운로드(.tar.xz.1) 제거 — glob 모호성 방지 (mesa 등)
rm -f "$LFS"/sources/*.tar.*.1 2>/dev/null || true

for fs in dev dev/pts proc sys run; do
  mkdir -p "$LFS/$fs"
  mountpoint -q "$LFS/$fs" && continue
  case $fs in
    dev)     mount --bind /dev     "$LFS/dev" ;;
    dev/pts) mount --bind /dev/pts "$LFS/dev/pts" ;;
    proc)    mount -t proc  proc   "$LFS/proc" ;;
    sys)     mount -t sysfs sysfs  "$LFS/sys" ;;
    run)     mount -t tmpfs tmpfs  "$LFS/run" ;;
  esac
done

# ---------- inside-chroot 빌드 스크립트 생성 ----------
cat > "$LFS/root/5b-inside.sh" <<'INSIDE'
#!/bin/bash
set -uo pipefail
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
export PKG_CONFIG_PATH=/usr/lib/pkgconfig:/usr/share/pkgconfig
export LC_ALL=C
JOBS=6
MARKDIR=/sources/.5b-markers
mkdir -p "$MARKDIR"
rm -f /sources/.5b-FAILED /sources/.5b-COMPLETE

log(){ echo "[5b] $*"; }

# mesa 빌드용 python-mako (CA 없어도 --trusted-host로)
if ! python3 -c 'import mako' 2>/dev/null; then
  log "installing python-mako"
  pip3 install --break-system-packages --trusted-host pypi.org --trusted-host files.pythonhosted.org mako 2>&1 | tail -3
  python3 -c 'import mako; print("  mako", mako.__version__)' 2>&1 | tail -1
fi

find_tar(){ ls /sources/$1-[0-9]*.tar.* 2>/dev/null | grep -vE '\.(sha256|sig|asc)$' | sort -V | tail -1; }
topdir(){ tar tf "$1" 2>/dev/null | head -1 | cut -d/ -f1; }

do_build(){  # $1=auto|meson  $2=pkgglob  rest=args
  local tool=$1 glob=$2; shift 2
  local mk="$MARKDIR/$glob"
  if [ -f "$mk" ]; then log "SKIP $glob (done)"; return 0; fi
  local tf; tf=$(find_tar "$glob")
  if [ -z "$tf" ]; then log "FAIL $glob: 소스 없음"; echo "FAILED_AT=$glob(no-source)" > /sources/.5b-FAILED; exit 1; fi
  local dir; dir=$(topdir "$tf")
  log "BUILD $dir  [$tool]"
  cd /sources && rm -rf "$dir" && tar xf "$tf" && cd "$dir" || { echo "FAILED_AT=$glob(extract)" > /sources/.5b-FAILED; exit 1; }
  local rc=0
  if [ "$tool" = meson ]; then
    ( meson setup _b --prefix=/usr --buildtype=release "$@" && ninja -C _b -j"$JOBS" && ninja -C _b install ); rc=$?
  else
    # 낡은 autotools(mtdev 등) config.guess aarch64 미인식 → automake 최신본으로 갱신
    for cf in $(find . -name config.guess 2>/dev/null); do cp -f /usr/share/automake-1.16/config.guess "$cf" 2>/dev/null; done
    for cf in $(find . -name config.sub   2>/dev/null); do cp -f /usr/share/automake-1.16/config.sub   "$cf" 2>/dev/null; done
    ( ./configure --prefix=/usr "$@" && make -j"$JOBS" && make install ); rc=$?
  fi
  if [ $rc -ne 0 ]; then log "FAIL $dir (rc=$rc)"; echo "FAILED_AT=$glob" > /sources/.5b-FAILED; exit 1; fi
  ldconfig 2>/dev/null || true
  touch "$mk"; cd /sources && rm -rf "$dir"
  log "OK $dir"
}

# ---- protos / macros ----
do_build auto  util-macros
do_build meson xorgproto
do_build auto  xtrans
# ---- xcb 체인 ----
do_build auto  libXau        --disable-static
do_build auto  libXdmcp      --disable-static
do_build auto  xcb-proto
do_build auto  libxcb        --disable-static --without-doxygen
# ---- libX11 + 확장 ----
do_build auto  libX11        --disable-static
do_build auto  libXext       --disable-static
do_build auto  libXrender    --disable-static
do_build auto  libXfixes     --disable-static
do_build auto  libXi         --disable-static
do_build auto  libXrandr     --disable-static
do_build auto  libXdamage    --disable-static
do_build auto  libXcomposite --disable-static
do_build auto  libXcursor    --disable-static
do_build auto  libXtst       --disable-static
do_build auto  libXres       --disable-static
# ---- render / font libs ----
do_build meson pixman
do_build auto  freetype      --disable-static --enable-freetype-config
do_build auto  fontconfig    --sysconfdir=/etc --localstatedir=/var --disable-docs
do_build auto  libXft        --disable-static
# ---- drm / gl ----
do_build meson libdrm        -Dvalgrind=disabled -Dtests=false
do_build meson libpciaccess
do_build auto  libxshmfence  --disable-static
do_build auto  libXxf86vm    --disable-static
# mesa가 EGL/GL/GLES 헤더를 설치 → libepoxy가 그 뒤에 빌드돼야 EGL/eglplatform.h 찾음 (순서 중요)
do_build meson mesa          -Dplatforms=x11 -Dgallium-drivers=vc4,v3d -Dvulkan-drivers= -Dllvm=disabled -Dglx=dri -Dgles2=enabled -Dgbm=enabled -Ddri3=enabled -Dgallium-vdpau=disabled -Dgallium-va=disabled -Dvalgrind=disabled -Dlibunwind=disabled -Dbuild-tests=false
do_build meson libepoxy
# ---- xkb ----
do_build meson xkeyboard-config
do_build auto  libxkbfile    --disable-static
do_build meson libxkbcommon  -Denable-wayland=false -Denable-docs=false -Denable-xkbregistry=false
do_build auto  xkbcomp
do_build meson libxcvt
# ---- fonts (순서: enc→util→mkfontscale→encodings→libXfont2→bdftopcf→fonts) ----
do_build auto  libfontenc    --disable-static
do_build auto  font-util
do_build auto  mkfontscale
do_build auto  encodings
do_build auto  libXfont2     --disable-static
do_build auto  bdftopcf
do_build auto  font-alias
do_build auto  font-cursor-misc
do_build auto  font-misc-misc
# ---- server + xinit ----
do_build meson xorg-server   -Dxorg=true -Dxephyr=false -Dxnest=false -Dxvfb=false -Dglamor=true -Ddri1=false -Ddri2=true -Ddri3=true -Dsystemd_logind=false -Dsuid_wrapper=false -Dudev=true -Dint10=false -Dsecure-rpc=false
do_build auto  xinit
# ---- xauth (startx 인증 쿠키) ----
do_build auto  xauth
# ---- 입력 드라이버 (libinput 체인) — 키보드/마우스 X 입력 ----
do_build auto  mtdev
do_build meson libevdev   -Dtests=disabled -Ddocumentation=disabled
do_build meson libinput   -Dtests=false -Dlibwacom=false -Ddebug-gui=false -Ddocumentation=false
do_build auto  xf86-input-libinput

log "===== 5b ALL DONE ====="
if command -v Xorg >/dev/null 2>&1; then echo "  Xorg: $(command -v Xorg)"; Xorg -version 2>&1 | head -2; touch /sources/.5b-COMPLETE; else echo "  🚨 Xorg 바이너리 없음"; echo "FAILED_AT=xorg-server(no-binary)" > /sources/.5b-FAILED; fi
INSIDE
chmod +x "$LFS/root/5b-inside.sh"

# ---------- chroot 실행 ----------
echo "===== 5b build 시작 (chroot, JOBS=6) $(date 2>/dev/null) ====="
chroot "$LFS" /bin/bash /root/5b-inside.sh
RC=$?
echo "===== 5b build 종료 rc=$RC $(date 2>/dev/null) ====="
if [ -f "$LFS/sources/.5b-COMPLETE" ]; then
  echo "5B_COMPLETE=YES"
else
  echo "5B_COMPLETE=NO"
  cat "$LFS/sources/.5b-FAILED" 2>/dev/null || echo "(FAILED 마커 없음 — rc=$RC)"
fi
