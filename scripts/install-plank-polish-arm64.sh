#!/bin/bash
# =============================================================================
# MaruxOS 2.0.0 "Cooked" — ARM64 배치 P2: Plank 폴리시 (picom + Marux 테마)
# -----------------------------------------------------------------------------
# 사용자 요구 (2026-07-29, macOS 독 스크린샷 레퍼런스):
#   둥근 모서리 + 가로로 긴 반투명 바 + 앱 추가 시 가로 확장(plank 네이티브).
# 반투명·줌 애니메이션은 컴포지터 필수 (비컴포지트=불투명 강제, plank 소스 확인) →
#   **picom 도입 결정** (xrender 백엔드 + vsync — vc4 GL 리스크 회피, 티어링 보너스 픽스).
# 구성:
#   ① picom 의존 6종: libev 4.33 / libconfig 1.7.3 / uthash(헤더만) /
#      xcb-util-renderutil / xcb-util-image / xcb-util-wm  [qemu-chroot]
#   ② picom v11.2 (meson, -Dwith_docs=false)  [qemu-chroot]
#   ③ /etc/xdg/picom.conf — 미니멀: 컴포지팅+vsync만 (그림자/페이드 off — plank 자체
#      애니메이션과 충돌 방지, 기존 데스크톱 룩 보존)
#   ④ **Marux 테마** (/usr/share/plank/themes/Marux/dock.theme) — 라운드 6 + 반투명
#      화이트 채움 + HorizPadding(긴 바) + ItemPadding(아이콘 여백)
#   ⑤ override theme='Marux' 갱신 → glib-compile-schemas → gsettings 실효값 검증
# resumable(.p2-markers). 완료기준: .p2-COMPLETE. 실행: wsl -u root bash <this>
# =============================================================================
set -uo pipefail
B=/home/administrator/MaruxOS-arm64
LFS=$B/rootfs-clfs-arm64
S=$LFS/sources
[[ "$LFS" == *"MaruxOS-arm64"* ]] || { echo "🚨 ABORT: $LFS"; exit 1; }
[ -f "$S/.p-COMPLETE" ] || { echo "🚨 ABORT: 배치 P(plank) 미완"; exit 1; }
[ -x "$LFS/usr/bin/plank" ] || { echo "🚨 ABORT: plank 없음"; exit 1; }

# ---------- 소스 fetch (호스트) ----------
fetch(){ [ -s "$2" ] && return 0; echo "[fetch] $(basename "$2")"; timeout 300 wget -q -O "$2" "$1" || { rm -f "$2"; echo "🚨 ABORT: fetch 실패 $1"; exit 1; }; echo "  OK $(ls -lh "$2" | awk '{print $5}')"; }
fetch "http://dist.schmorp.de/libev/Attic/libev-4.33.tar.gz"                        "$S/libev-4.33.tar.gz"
fetch "https://github.com/hyperrealm/libconfig/releases/download/v1.7.3/libconfig-1.7.3.tar.gz" "$S/libconfig-1.7.3.tar.gz"
fetch "https://github.com/troydhanson/uthash/archive/refs/tags/v2.3.0.tar.gz"       "$S/uthash-2.3.0.tar.gz"
fetch "https://xcb.freedesktop.org/dist/xcb-util-renderutil-0.3.10.tar.xz"          "$S/xcb-util-renderutil-0.3.10.tar.xz"
fetch "https://xcb.freedesktop.org/dist/xcb-util-image-0.4.1.tar.xz"                "$S/xcb-util-image-0.4.1.tar.xz"
fetch "https://xcb.freedesktop.org/dist/xcb-util-wm-0.4.2.tar.xz"                   "$S/xcb-util-wm-0.4.2.tar.xz"
fetch "https://github.com/yshui/picom/archive/refs/tags/v11.2.tar.gz"               "$S/picom-11.2.tar.gz"

# uthash = 헤더 온리 → 호스트에서 바로 주입 (빌드 불요)
if [ ! -f "$LFS/usr/include/uthash.h" ]; then
  tmpd=$(mktemp -d); tar -C "$tmpd" -xf "$S/uthash-2.3.0.tar.gz"
  cp -f "$tmpd"/uthash-*/src/*.h "$LFS/usr/include/"
  rm -rf "$tmpd"; echo "  ✓ uthash 헤더 주입"
fi

# ---------- binfmt + mounts ----------
mountpoint -q /proc/sys/fs/binfmt_misc || mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc
[ -e /proc/sys/fs/binfmt_misc/qemu-aarch64 ] || echo ':qemu-aarch64:M::\x7f\x45\x4c\x46\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-aarch64-static:F' > /proc/sys/fs/binfmt_misc/register
[ -e "$LFS/usr/bin/qemu-aarch64-static" ] || cp /usr/bin/qemu-aarch64-static "$LFS/usr/bin/"
cp -f /etc/resolv.conf "$LFS/etc/resolv.conf" 2>/dev/null || true
for fs in dev dev/pts proc sys run; do
  mkdir -p "$LFS/$fs"; mountpoint -q "$LFS/$fs" && continue
  case $fs in dev) mount --bind /dev "$LFS/dev";; dev/pts) mount --bind /dev/pts "$LFS/dev/pts";; proc) mount -t proc proc "$LFS/proc";; sys) mount -t sysfs sysfs "$LFS/sys";; run) mount -t tmpfs tmpfs "$LFS/run";; esac
done

# ---------- chroot 내부 빌드 ----------
cat > "$LFS/root/p2-inside.sh" <<'INSIDE'
#!/bin/bash
set -uo pipefail
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
export PKG_CONFIG_PATH=/usr/lib/pkgconfig:/usr/share/pkgconfig
export LC_ALL=C
JOBS=6
MARKDIR=/sources/.p2-markers; mkdir -p "$MARKDIR"
rm -f /sources/.p2-FAILED /sources/.p2-COMPLETE
log(){ echo "[p2] $(date '+%H:%M:%S') $*"; }
fail(){ echo "FAILED_AT=$1" > /sources/.p2-FAILED; exit 1; }
find_tar(){ ls /sources/$1-[0-9v]*.tar.* 2>/dev/null | grep -vE '\.(sha256|sig|asc)$' | sort -V | tail -1; }
topdir(){ tar tf "$1" 2>/dev/null | grep -vE '^\./?$' | sed 's#^\./##' | head -1 | cut -d/ -f1; }
do_auto(){
  local glob=$1; shift
  [ -f "$MARKDIR/$glob" ] && { log "SKIP $glob"; return 0; }
  local tf; tf=$(find_tar "$glob"); [ -z "$tf" ] && fail "$glob(no-source)"
  local dir; dir=$(topdir "$tf")
  log "BUILD $dir [auto]"
  cd /sources && rm -rf "$dir" && tar xf "$tf" && cd "$dir" || fail "$glob(extract)"
  [ -f "/sources/patch-$glob.sh" ] && { sh "/sources/patch-$glob.sh" || fail "$glob(patch)"; }
  for cf in $(find . -name config.guess); do cp -f /usr/share/automake-1.16/config.guess "$cf" 2>/dev/null; done
  for cf in $(find . -name config.sub); do cp -f /usr/share/automake-1.16/config.sub "$cf" 2>/dev/null; done
  ( ./configure --prefix=/usr "$@" && make -j$JOBS && make install ) > "/sources/$glob-build.log" 2>&1; local rc=$?
  [ $rc -ne 0 ] && { log "FAIL $dir rc=$rc"; tail -25 "/sources/$glob-build.log"; fail "$glob(rc=$rc)"; }
  ldconfig 2>/dev/null || true
  touch "$MARKDIR/$glob"; cd /sources && rm -rf "$dir"; log "OK $dir"
}

# ---- picom 의존 ----
do_auto libev
do_auto libconfig --disable-examples --disable-tests
do_auto xcb-util-renderutil --disable-static
do_auto xcb-util-image --disable-static
do_auto xcb-util-wm --disable-static
[ -f /usr/include/uthash.h ] || fail uthash-header

# ---- picom (meson) ----
if [ ! -f "$MARKDIR/picom" ]; then
  tf=$(ls /sources/picom-*.tar.gz | tail -1); dir=$(topdir "$tf")
  log "BUILD $dir [meson]"
  cd /sources && rm -rf "$dir" && tar xf "$tf" && cd "$dir" || fail "picom(extract)"
  ( meson setup _build --prefix=/usr --buildtype=release --wrap-mode=nofallback \
      -Dwith_docs=false && ninja -C _build -j$JOBS && ninja -C _build install ) \
    > /sources/picom-build.log 2>&1; rc=$?
  [ $rc -ne 0 ] && { tail -30 /sources/picom-build.log; fail "picom(rc=$rc)"; }
  ldconfig 2>/dev/null || true
  touch "$MARKDIR/picom"; cd /sources && rm -rf "$dir"; log "OK picom"
else log "SKIP picom"; fi
[ -x /usr/bin/picom ] || fail "picom(binary)"

# ---- picom 설정 (미니멀: 컴포지팅+vsync만) ----
mkdir -p /etc/xdg
cat > /etc/xdg/picom.conf <<'CONF'
# MaruxOS — plank 반투명/애니메이션용 미니멀 컴포지터 설정
# xrender = vc4에서 가장 보수적 백엔드. vsync = 티어링 방지(보너스).
backend = "xrender";
vsync = true;
# plank 자체 애니메이션과 충돌 방지 + 기존 데스크톱 룩 보존 — 효과 전부 off
shadow = false;
fading = false;
corner-radius = 0;
CONF
log "picom.conf 생성"

# ---- Marux 테마 (macOS풍: 라운드 + 반투명 화이트 + 긴 바) ----
mkdir -p /usr/share/plank/themes/Marux
cat > /usr/share/plank/themes/Marux/dock.theme <<'THEME'
#MaruxOS Marux theme — macOS-like: rounded translucent bar (needs compositor)
# 라이브 실험(2026-07-29): 색톤은 비컴포지트에서도 즉시 반영, 라운드는 컴포지터 필수(사각 폴백).
[PlankTheme]
TopRoundness=10
BottomRoundness=0
LineWidth=1
OuterStrokeColor=120;;120;;120;;90
FillStartColor=248;;248;;248;;95
FillEndColor=235;;235;;235;;95
InnerStrokeColor=255;;255;;255;;70

[PlankDockTheme]
HorizPadding=5
TopPadding=2
BottomPadding=2.5
ItemPadding=4
IndicatorSize=4.5
IconShadowSize=1
UrgentBounceHeight=1.6666666666666667
LaunchBounceHeight=0.625
FadeOpacity=1
ClickTime=300
UrgentBounceTime=600
LaunchBounceTime=600
ActiveTime=300
SlideTime=300
FadeTime=250
HideTime=250
GlowSize=30
GlowTime=10000
GlowPulseTime=2000
UrgentHueShift=150
THEME
log "Marux 테마 설치"

# ---- override 갱신: theme='Marux' → 컴파일 → 실효값 검증 ----
sed -i "s/^theme='Default'/theme='Marux'/" /usr/share/glib-2.0/schemas/40_maruxos.gschema.override
grep -q "theme='Marux'" /usr/share/glib-2.0/schemas/40_maruxos.gschema.override || fail "override(theme sed)"
glib-compile-schemas /usr/share/glib-2.0/schemas/ >/dev/null 2>&1 || true
GOT=$(gsettings get net.launchpad.plank.dock.settings:/net/launchpad/plank/docks/dock1/ theme 2>/dev/null)
echo "$GOT" | grep -q "Marux" || fail "override(theme 실효값: $GOT)"
GOT2=$(gsettings get net.launchpad.plank.dock.settings:/net/launchpad/plank/docks/dock1/ dock-items 2>/dev/null)
echo "$GOT2" | grep -q "xterm.dockitem" || fail "override(dock-items 회귀: $GOT2)"
log "✅ theme=$GOT / dock-items 회귀 OK"

log "===== 최종 검증 ====="
ok=1
for f in /usr/bin/picom /etc/xdg/picom.conf /usr/share/plank/themes/Marux/dock.theme /usr/include/uthash.h; do
  [ -e "$f" ] && echo "  ✅ $f" || { echo "  ❌ $f"; ok=0; }
done
ldd /usr/bin/picom 2>/dev/null | grep "not found" && { echo "  ❌ picom ldd"; ok=0; } || echo "  ✅ picom ldd 클린"
[ "$ok" = 1 ] && touch /sources/.p2-COMPLETE || fail final
log "===== P2 ALL DONE ====="
INSIDE
chmod +x "$LFS/root/p2-inside.sh"
echo "===== P2(폴리시) build 시작 (chroot) $(date) ====="
chroot "$LFS" /bin/bash /root/p2-inside.sh
RC=$?
echo "===== P2 build 종료 rc=$RC ====="
[ -f "$S/.p2-COMPLETE" ] && echo "P2_COMPLETE=YES" || { echo "P2_COMPLETE=NO"; cat "$S/.p2-FAILED" 2>/dev/null; exit 1; }
