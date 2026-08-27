#!/bin/bash
# =============================================================================
# MaruxOS 2.0.0 "Cooked" — ARM64 배치 P: Plank dock (소스 체인 + GSettings 정공 픽스)
# -----------------------------------------------------------------------------
# x86 v3~v7 부검 (2026-07-27 워크플로 정찰) 재규명:
#   - v7 "빈 독"의 실체 = memconf(memory 백엔드)는 **프로세스별·비영속** → gsettings
#     CLI 쓰기가 plank 프로세스에 도달 불가(별개 메모리). 파일 dock1/settings는
#     plank가 안 읽음(설정은 순수 GSettings).
#   - 정공 해법(elementary OS 패턴): ①.gschema.override로 컴파일 기본값에 dock-items
#     박제(relocatable 스키마 override 합법) ②GSETTINGS_BACKEND=keyfile(GLib≥2.60,
#     우리 2.78)로 영속성 — xinitrc에서 export (config v5).
#   - plank 0.11.89는 사전생성 C 없음(75 .vala) + valac/vapigen 하드요구 + bamf 하드의존
#     → **vala 부트스트랩부터 소스 빌드** (vala 타르볼은 생성C 포함 = valac 불요).
#   - x86의 Debian .deb 추출 방식은 ARM64에 안 씀 (from-scratch 정체성 + 화석 라이브러리
#     리스크 — x86 rootfs의 2022 mtime prebuilt 잔재가 반례).
# 체인: vala → libgee → libXres → libwnck → libgtop → gnome-menus → bamf → plank
#   → gschema.override + glib-compile-schemas + **chroot gsettings get 검증**
#     (override 오타는 컴파일러가 조용히 무시 → 게이트 필수. 워크플로 리스크 지적)
# qemu-chroot 네이티브 aarch64. resumable(.p-markers). 완료기준: .p-COMPLETE.
# 실행: wsl -u root bash <this>  (nohup setsid 권장 — 함정#6/#12)
# =============================================================================
set -uo pipefail
B=/home/administrator/MaruxOS-arm64
LFS=$B/rootfs-clfs-arm64
S=$LFS/sources
PLANK_SHA256="a662a46eaeffbd40661d1f36abd2589f7a98baef4b918876b872047b7ca59d9d"  # raw 검증값 (Launchpad MD5 교차확인 완료)
[[ "$LFS" == *"MaruxOS-arm64"* ]] || { echo "🚨 ABORT: $LFS"; exit 1; }
[ -f "$S/.b2-COMPLETE" ] || { echo "🚨 ABORT: B-2(gtk3) 미완 — plank는 gtk3 필요"; exit 1; }
[ -e "$LFS/usr/lib/libgtk-3.so.0" ] || { echo "🚨 ABORT: gtk3 없음"; exit 1; }

# ---------- 소스 fetch (호스트) ----------
fetch(){ [ -s "$2" ] && return 0; echo "[fetch] $(basename "$2")"; timeout 300 wget -q -O "$2" "$1" || { rm -f "$2"; echo "🚨 ABORT: fetch 실패 $1"; exit 1; }; echo "  OK $(ls -lh "$2" | awk '{print $5}')"; }
fetch "https://download.gnome.org/sources/gobject-introspection/1.78/gobject-introspection-1.78.1.tar.xz" "$S/gobject-introspection-1.78.1.tar.xz"
fetch "https://download.gnome.org/sources/vala/0.56/vala-0.56.17.tar.xz"            "$S/vala-0.56.17.tar.xz"
fetch "https://download.gnome.org/sources/libgee/0.20/libgee-0.20.6.tar.xz"         "$S/libgee-0.20.6.tar.xz"
fetch "https://www.x.org/pub/individual/lib/libXres-1.2.2.tar.xz"                   "$S/libXres-1.2.2.tar.xz"
# libwnck 43.2 필수 — 43.0은 invalidate_icons에 screens NULL 가드가 없어서 bamf처럼
# 스크린 생성 전에 wnck_set_default_icon_size()를 부르는 클라이언트가 즉사(segv).
# (v16 실기기서 dmesg 트레이스→디스어셈블→43.0↔43.2 소스 diff로 근원 특정, 2026-08-14)
fetch "https://download.gnome.org/sources/libwnck/43/libwnck-43.2.tar.xz"           "$S/libwnck-43.2.tar.xz"
fetch "https://download.gnome.org/sources/libgtop/2.41/libgtop-2.41.3.tar.xz"       "$S/libgtop-2.41.3.tar.xz"
fetch "https://download.gnome.org/sources/gnome-menus/3.36/gnome-menus-3.36.0.tar.xz" "$S/gnome-menus-3.36.0.tar.xz"
fetch "https://xcb.freedesktop.org/dist/xcb-util-0.4.1.tar.xz"                      "$S/xcb-util-0.4.1.tar.xz"
fetch "https://www.freedesktop.org/software/startup-notification/releases/startup-notification-0.12.tar.gz" "$S/startup-notification-0.12.tar.gz"
fetch "https://launchpad.net/bamf/0.5/0.5.6/+download/bamf-0.5.6.tar.gz"            "$S/bamf-0.5.6.tar.gz"
fetch "https://launchpad.net/plank/1.0/0.11.89/+download/plank-0.11.89.tar.xz"      "$S/plank-0.11.89.tar.xz"
ACT=$(sha256sum "$S/plank-0.11.89.tar.xz" | awk '{print $1}')
[ "$ACT" = "$PLANK_SHA256" ] || { echo "🚨 ABORT: plank 타르볼 SHA 불일치 ($ACT)"; exit 1; }
echo "  ✅ plank 타르볼 SHA256 검증 통과"

# ---------- binfmt + mounts (스캐폴드) ----------
mountpoint -q /proc/sys/fs/binfmt_misc || mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc
[ -e /proc/sys/fs/binfmt_misc/qemu-aarch64 ] || echo ':qemu-aarch64:M::\x7f\x45\x4c\x46\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-aarch64-static:F' > /proc/sys/fs/binfmt_misc/register
[ -e "$LFS/usr/bin/qemu-aarch64-static" ] || cp /usr/bin/qemu-aarch64-static "$LFS/usr/bin/"
cp -f /etc/resolv.conf "$LFS/etc/resolv.conf" 2>/dev/null || true
for fs in dev dev/pts proc sys run; do
  mkdir -p "$LFS/$fs"; mountpoint -q "$LFS/$fs" && continue
  case $fs in dev) mount --bind /dev "$LFS/dev";; dev/pts) mount --bind /dev/pts "$LFS/dev/pts";; proc) mount -t proc proc "$LFS/proc";; sys) mount -t sysfs sysfs "$LFS/sys";; run) mount -t tmpfs tmpfs "$LFS/run";; esac
done

# ---------- 패치 훅: bamf configure의 python3-lxml 하드체크 무력화 ----------
# (gtester2xunit = 테스트 결과 XML 변환용 — 테스트 안 돌리므로 불요. lxml 소스빌드는
#  libxslt 사슬 추가라 과잉. 4차 시도서 발견.)
cat > "$S/patch-bamf.sh" <<'BPATCH'
#!/bin/sh
[ -f configure ] && sed -i 's/as_fn_error $? "You need to install python3-lxml"/echo "lxml check skipped (tests unused)"; :/' configure
exit 0
BPATCH

# ---------- chroot 내부 빌드 ----------
cat > "$LFS/root/plank-inside.sh" <<'INSIDE'
#!/bin/bash
set -uo pipefail
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
export PKG_CONFIG_PATH=/usr/lib/pkgconfig:/usr/share/pkgconfig
export LC_ALL=C
JOBS=6
MARKDIR=/sources/.p-markers; mkdir -p "$MARKDIR"
rm -f /sources/.p-FAILED /sources/.p-COMPLETE
log(){ echo "[plank] $(date '+%H:%M:%S') $*"; }
fail(){ echo "FAILED_AT=$1" > /sources/.p-FAILED; exit 1; }
find_tar(){ ls /sources/$1-[0-9v]*.tar.* 2>/dev/null | grep -vE '\.(sha256|sig|asc)$' | sort -V | tail -1; }
topdir(){ tar tf "$1" 2>/dev/null | grep -vE '^\./?$' | sed 's#^\./##' | head -1 | cut -d/ -f1; }
do_auto(){ # autotools
  local glob=$1; shift
  [ -f "$MARKDIR/$glob" ] && { log "SKIP $glob"; return 0; }
  local tf; tf=$(find_tar "$glob"); [ -z "$tf" ] && fail "$glob(no-source)"
  local dir; dir=$(topdir "$tf")
  log "BUILD $dir [auto]"
  cd /sources && rm -rf "$dir" && tar xf "$tf" && cd "$dir" || fail "$glob(extract)"
  [ -f "/sources/patch-$glob.sh" ] && { log "patch $glob"; sh "/sources/patch-$glob.sh" || fail "$glob(patch)"; }
  for cf in $(find . -name config.guess); do cp -f /usr/share/automake-1.16/config.guess "$cf" 2>/dev/null; done
  for cf in $(find . -name config.sub); do cp -f /usr/share/automake-1.16/config.sub "$cf" 2>/dev/null; done
  ( ./configure --prefix=/usr "$@" && make -j$JOBS && make install ) > "/sources/$glob-build.log" 2>&1; local rc=$?
  [ $rc -ne 0 ] && { log "FAIL $dir rc=$rc"; tail -30 "/sources/$glob-build.log"; fail "$glob(rc=$rc)"; }
  ldconfig 2>/dev/null || true
  touch "$MARKDIR/$glob"; cd /sources && rm -rf "$dir"; log "OK $dir"
}
do_meson(){ # meson
  local glob=$1; shift
  [ -f "$MARKDIR/$glob" ] && { log "SKIP $glob"; return 0; }
  local tf; tf=$(find_tar "$glob"); [ -z "$tf" ] && fail "$glob(no-source)"
  local dir; dir=$(topdir "$tf")
  log "BUILD $dir [meson]"
  cd /sources && rm -rf "$dir" && tar xf "$tf" && cd "$dir" || fail "$glob(extract)"
  [ -f "/sources/patch-$glob.sh" ] && { log "patch $glob"; sh "/sources/patch-$glob.sh" || fail "$glob(patch)"; }
  ( meson setup _build --prefix=/usr --buildtype=release --wrap-mode=nofallback "$@" \
    && ninja -C _build -j$JOBS && ninja -C _build install ) > "/sources/$glob-build.log" 2>&1; local rc=$?
  [ $rc -ne 0 ] && { log "FAIL $dir rc=$rc"; tail -30 "/sources/$glob-build.log"; fail "$glob(rc=$rc)"; }
  ldconfig 2>/dev/null || true
  touch "$MARKDIR/$glob"; cd /sources && rm -rf "$dir"; log "OK $dir"
}

# ---- ⓪ gobject-introspection (vala 0.56 configure가 girdir 하드요구 — 1차 시도서 발견.
#      glib 2.78 페어 = g-i 1.78. g-ir 덤퍼가 타겟 바이너리 실행 = qemu-chroot 네이티브 OK) ----
do_meson gobject-introspection
pkg-config --exists gobject-introspection-1.0 || fail "g-i(pkgconfig)"

# ---- ① vala 부트스트랩 (타르볼은 생성C 포함 → valac 불요. valadoc은 graphviz 요구 → off) ----
do_auto vala --disable-valadoc
command -v valac >/dev/null || fail "vala(valac-missing)"
log "valac = $(valac --version 2>/dev/null)"

# ---- ② libgee 0.20 (vala 라이브러리) ----
do_auto libgee --disable-static
pkg-config --exists gee-0.8 || fail "libgee(pkgconfig)"

# ---- ③ X 보조: libXres ----
do_auto libXres --disable-static

# ---- ④a xcb-util + startup-notification — ⚠️ libwnck보다 먼저!
#      (1차 빌드 순서 실수: SN 없이 컴파일된 wnck에서 bamfdaemon이
#       wnck_handle_set_default_icon_size 구간 segv — 실기기 dmesg 트레이스로 특정.
#       데비안 검증조합(bamf 0.5.6+wnck 43)은 SN 포함 빌드) ----
do_auto xcb-util --disable-static
do_auto startup-notification
pkg-config --exists libstartup-notification-1.0 || fail "sn(pkgconfig)"

# ---- ④ libwnck 43 (meson; SN 포함 필수, g-i/gtk-doc off) ----
do_meson libwnck -Dgtk_doc=false -Dintrospection=disabled
pkg-config --exists libwnck-3.0 || fail "libwnck(pkgconfig)"
grep -q "libstartup-notification-1.0 found: YES" /sources/libwnck-build.log || fail "libwnck(SN 미감지 — 순서 버그 재발)"

# ---- ⑤ libgtop (bamf 의존; g-i off) ----
do_auto libgtop --disable-static --disable-introspection
pkg-config --exists libgtop-2.0 || fail "libgtop(pkgconfig)"

# ---- ⑥ gnome-menus (plank 하드의존; g-i off) ----
do_auto gnome-menus --disable-static --disable-introspection
pkg-config --exists libgnome-menu-3.0 || fail "gnome-menus(pkgconfig)"

# (⑦ xcb-util/startup-notification은 ④a로 이동 — wnck 앞 필수)

# ---- ⑧ bamf (창 매칭 데몬 + libbamf3) ----
do_auto bamf --disable-static --enable-introspection=no --disable-gtk-doc --disable-tests
pkg-config --exists libbamf3 || fail "bamf(pkgconfig)"
[ -x /usr/lib/bamf/bamfdaemon ] || ls /usr/libexec/bamf* >/dev/null 2>&1 || log "⚠️ bamfdaemon 위치 비표준 — 후속 확인"

# ---- ⑨ plank 0.11.89 ----
do_auto plank --disable-static --disable-apport --disable-docs
[ -x /usr/bin/plank ] || fail "plank(binary)"
[ -f /usr/share/glib-2.0/schemas/net.launchpad.plank.gschema.xml ] || fail "plank(gschema-xml)"

# ---- ⑩ 🔴 정공 픽스: gschema.override (dock-items 기본값 박제) + 컴파일 + 검증 ----
log "gschema.override 배포 + glib-compile-schemas"
cat > /usr/share/glib-2.0/schemas/40_maruxos.gschema.override <<'OVR'
[net.launchpad.plank.dock.settings]
dock-items=['xterm.dockitem','mc.dockitem','firefox.dockitem']
icon-size=48
hide-mode='none'
theme='Marux'
position='bottom'
alignment='center'
zoom-enabled=true
zoom-percent=150
OVR
glib-compile-schemas /usr/share/glib-2.0/schemas/ 2>&1 | tee /sources/plank-schema-compile.log
strings /usr/share/glib-2.0/schemas/gschemas.compiled | grep -q "net.launchpad.plank" || fail "override(compiled-cache에 plank 없음)"
# ⚠️ 컴파일러는 잘못된 override를 조용히 무시 → gsettings로 실효값 검증 (게이트 원칙)
GOT=$(gsettings get net.launchpad.plank.dock.settings:/net/launchpad/plank/docks/dock1/ dock-items 2>/dev/null)
echo "$GOT" | grep -q "xterm.dockitem" || fail "override(gsettings 실효값 미반영: $GOT)"
log "✅ dock-items 실효 기본값 = $GOT"

log "===== 최종 검증 ====="
ok=1
for f in /usr/bin/valac /usr/bin/plank /usr/lib/libplank.so.1 /usr/lib/libgee-0.8.so \
         /usr/lib/libwnck-3.so /usr/lib/libbamf3.so.2 \
         /usr/share/glib-2.0/schemas/net.launchpad.plank.gschema.xml \
         /usr/share/glib-2.0/schemas/40_maruxos.gschema.override; do
  ls $f* >/dev/null 2>&1 && echo "  ✅ $f" || { echo "  ❌ $f"; ok=0; }
done
ldd /usr/bin/plank 2>/dev/null | grep "not found" && { echo "  ❌ plank ldd 미해결"; ok=0; } || echo "  ✅ plank ldd 클린"
[ "$ok" = 1 ] && touch /sources/.p-COMPLETE || fail final
log "===== PLANK ALL DONE ====="
INSIDE
chmod +x "$LFS/root/plank-inside.sh"
echo "===== Plank 배치 build 시작 (chroot, JOBS=6) $(date) ====="
chroot "$LFS" /bin/bash /root/plank-inside.sh
RC=$?
echo "===== Plank 배치 build 종료 rc=$RC $(date) ====="
if [ -f "$S/.p-COMPLETE" ]; then echo "P_COMPLETE=YES"; else echo "P_COMPLETE=NO"; cat "$S/.p-FAILED" 2>/dev/null; exit 1; fi
