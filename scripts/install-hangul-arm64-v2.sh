#!/bin/bash
# =============================================================================
# MaruxOS 2.0.0 "Cooked" — ARM64 배치 B-1: 한글 입력 (ibus-hangul XIM)
# -----------------------------------------------------------------------------
# 5d 재규명: ibus XIM 서버(ibus-x11)는 GTK2 필수(client/x11/main.c #include <gtk/gtk.h>).
#   5d는 gtk2 안 만들고 --disable-gtk2 → configure "gtk+-2.0 not found"로 죽음.
# → GTK2 빌드(의존성 glib2/gdk-pixbuf/pango/cairo/atk 이미 있음, GTK3와 달리 심볼릭SVG 이슈 없음)
#   → ibus --enable-gtk2 --enable-xim → ibus-hangul → xterm XIM 한글입력. (gtk3/Firefox는 배치 B-2)
# qemu-chroot 네이티브 aarch64. resumable(.5d2-markers). 성공기준: ibus-x11 + ibus-engine-hangul.
# 실행: wsl -u root bash <this>
# =============================================================================
set -uo pipefail
B=/home/administrator/MaruxOS-arm64
LFS=$B/rootfs-clfs-arm64
S=$LFS/sources
GTK2_VER=2.24.33
[[ "$LFS" == *"MaruxOS-arm64"* ]] || { echo "🚨 ABORT: $LFS"; exit 1; }
[ -e "$LFS/usr/lib/libhangul.so" ] || { echo "🚨 ABORT: libhangul 없음(5d 미완)"; exit 1; }
[ -e "$LFS/usr/lib/libgdk_pixbuf-2.0.so" ] || { echo "🚨 ABORT: gdk-pixbuf 없음"; exit 1; }

# ---------- 소스 fetch (GTK2; ibus/ibus-hangul은 이미 staged) ----------
mkdir -p "$S"
if [ ! -s "$S/gtk+-${GTK2_VER}.tar.xz" ]; then
  echo "[fetch] gtk+-${GTK2_VER}"
  timeout 180 wget -q -O "$S/gtk+-${GTK2_VER}.tar.xz" \
    "https://download.gnome.org/sources/gtk+/2.24/gtk+-${GTK2_VER}.tar.xz" \
    || { echo "🚨 ABORT: gtk2 fetch 실패"; exit 1; }
  echo "  OK $(ls -lh "$S/gtk+-${GTK2_VER}.tar.xz" | awk '{print $5}')"
fi

# ---------- binfmt + mounts + CA ----------
mountpoint -q /proc/sys/fs/binfmt_misc || mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc
[ -e /proc/sys/fs/binfmt_misc/qemu-aarch64 ] || echo ':qemu-aarch64:M::\x7f\x45\x4c\x46\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-aarch64-static:F' > /proc/sys/fs/binfmt_misc/register
[ -e "$LFS/usr/bin/qemu-aarch64-static" ] || cp /usr/bin/qemu-aarch64-static "$LFS/usr/bin/"
cp -f /etc/resolv.conf "$LFS/etc/resolv.conf" 2>/dev/null || true
mkdir -p "$LFS/etc/ssl/certs"; cp -f /etc/ssl/certs/ca-certificates.crt "$LFS/etc/ssl/certs/" 2>/dev/null || true
rm -f "$LFS"/sources/*.tar.*.1 2>/dev/null || true
for fs in dev dev/pts proc sys run; do
  mkdir -p "$LFS/$fs"; mountpoint -q "$LFS/$fs" && continue
  case $fs in dev) mount --bind /dev "$LFS/dev";; dev/pts) mount --bind /dev/pts "$LFS/dev/pts";; proc) mount -t proc proc "$LFS/proc";; sys) mount -t sysfs sysfs "$LFS/sys";; run) mount -t tmpfs tmpfs "$LFS/run";; esac
done

# gtk-doc.m4 스텁 + ibus autogen 패치 (5d와 동일)
mkdir -p "$LFS/usr/share/aclocal"
cat > "$LFS/usr/share/aclocal/gtk-doc.m4" <<'M4'
AC_DEFUN([GTK_DOC_CHECK],[
AC_ARG_ENABLE([gtk-doc],[],[],[enable_gtk_doc=no])
AM_CONDITIONAL([ENABLE_GTK_DOC],[false])
AM_CONDITIONAL([GTK_DOC_USE_LIBTOOL],[false])
AM_CONDITIONAL([GTK_DOC_USE_REBASE],[false])
AM_CONDITIONAL([GTK_DOC_BUILD_HTML],[false])
AM_CONDITIONAL([GTK_DOC_BUILD_PDF],[false])
HTML_DIR='${datadir}/gtk-doc/html'
AC_SUBST([HTML_DIR])
])
AC_DEFUN([GTK_DOC_IGNORE],[])
M4
cat > "$LFS/sources/patch-ibus.sh" <<'PATCH'
#!/bin/sh
[ -f configure ] && { echo "configure 존재 - autogen 스킵"; exit 0; }
[ -f configure.ac ] && { sed -i 's/^GTK_DOC_CHECK.*/enable_gtk_doc=no/' configure.ac; sed -i '\#^docs/#d' configure.ac; }
[ -f Makefile.am ] && sed -i '/^\tdocs \\$/d' Makefile.am
# automake 실패 원인 2종 픽스: ①GNU strictness가 ChangeLog/NEWS/AUTHORS/README 요구 ②gtk-doc.make include(gtkdocize 없음)
# 이게 없으면 automake rc=1 → 일부 Makefile.in(bindings 등) 미생성 → config.status "cannot find bindings/Makefile.in"
touch ChangeLog NEWS AUTHORS README gtk-doc.make
intltoolize --force --copy --automake 2>&1 | tail -2
NOCONFIGURE=1 autoreconf -fi 2>&1 | tail -6
# 검증: configure 생성 + (bindings 디렉토리 있으면) bindings/Makefile.in도 생성돼야 config.status 성공
[ -f configure ] || { echo "autogen 실패: configure 미생성"; exit 1; }
if [ -d bindings ] && [ ! -f bindings/Makefile.in ]; then echo "autogen 실패: bindings/Makefile.in 미생성(automake 부분실패)"; exit 1; fi
exit 0
PATCH
# ibus-hangul 전용 패치: GTK3 setup GUI 불필요(엔진만) → gtk+-3.0 필수 PKG_CHECK 제거
# (setup/은 .py/.ui 설치만·C컴파일 없음 → GTK_CFLAGS 미사용이라 안전)
cat > "$LFS/sources/patch-ibus-hangul.sh" <<'HPATCH'
#!/bin/sh
# ── MaruxOS: 한/영 상태 노출 패치 (configure 유무와 무관하게 항상 적용) ──────────
# ibus-hangul은 Shift+Space로 *엔진 내부 모드*만 바꾸므로 `ibus engine`으로는 한/영을
# 구분할 수 없다(퀵설정 통합 바가 항상 "한"으로 고정되던 원인). ibus 패널 D-Bus를
# 구현하는 대신, 모든 전환이 통과하는 단일 지점에서 상태를 파일로 내보낸다.
#   /tmp/marux-ime-mode : "han" | "eng"   (없으면 latin=기본값으로 간주)
if [ -f src/engine.c ] && ! grep -q "marux-ime-mode" src/engine.c; then
  sed -i 's|^    hangul->input_mode = input_mode;|    hangul->input_mode = input_mode; { FILE *mf = fopen ("/tmp/marux-ime-mode", "w"); if (mf != NULL) { fputs ((input_mode == INPUT_MODE_HANGUL) ? "han" : "eng", mf); fclose (mf); } }|' src/engine.c
  grep -q "marux-ime-mode" src/engine.c || { echo "MaruxOS ime-mode 패치 실패"; exit 1; }
  echo "MaruxOS: ime-mode 노출 패치 적용"
fi
[ -f configure ] && exit 0
# ①gtk+-3.0 필수 PKG_CHECK 제거(setup GUI 불요, 엔진만) ②tests/는 gtk/gtk.h 컴파일→제거(엔진 무관)
[ -f configure.ac ] && sed -i '/PKG_CHECK_MODULES(GTK,/,/^])/d' configure.ac
[ -f configure.ac ] && sed -i 's/^GTK_DOC_CHECK.*/enable_gtk_doc=no/' configure.ac
[ -f Makefile.am ] && sed -i '/^\ttests \\$/d' Makefile.am
touch ChangeLog NEWS AUTHORS README gtk-doc.make
intltoolize --force --copy --automake 2>&1 | tail -2
NOCONFIGURE=1 autoreconf -fi 2>&1 | tail -6
[ -f configure ] || { echo "ibus-hangul autogen 실패: configure 미생성"; exit 1; }
exit 0
HPATCH

cat > "$LFS/root/5d2-inside.sh" <<'INSIDE'
#!/bin/bash
set -uo pipefail
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
export PKG_CONFIG_PATH=/usr/lib/pkgconfig:/usr/share/pkgconfig
export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
export LC_ALL=C
# gdk-pixbuf 로더 경로 명시 (qemu에서 loaders.cache 못 찾는 경우 대비)
export GDK_PIXBUF_MODULE_FILE=/usr/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache
export GDK_PIXBUF_MODULEDIR=/usr/lib/gdk-pixbuf-2.0/2.10.0/loaders
# iso-codes(언어명 데이터, Hangul 입력 불요) pkg-config 체크 우회 — 값 설정 시 PKG_CHECK_MODULES 스킵
export ISOCODES_CFLAGS=" " ISOCODES_LIBS=" "
JOBS=6
MARKDIR=/sources/.5d2-markers; mkdir -p "$MARKDIR"
rm -f /sources/.5d2-FAILED /sources/.5d2-COMPLETE
log(){ echo "[5d2] $*"; }

# ---- GTK2 (명시적 타르볼 — gtk+ glob이 3.24와 충돌하므로 직접) ----
if [ ! -f "$MARKDIR/gtk2" ]; then
  tf=$(ls /sources/gtk+-2.*.tar.* 2>/dev/null | tail -1)
  [ -z "$tf" ] && { echo "FAILED_AT=gtk2(no-source)" > /sources/.5d2-FAILED; exit 1; }
  dir=$(tar tf "$tf" | head -1 | cut -d/ -f1)
  log "BUILD $dir [auto]"
  cd /sources && rm -rf "$dir" && tar xf "$tf" && cd "$dir" || { echo "FAILED_AT=gtk2(extract)" > /sources/.5d2-FAILED; exit 1; }
  for cf in $(find . -name config.guess); do cp -f /usr/share/automake-1.16/config.guess "$cf" 2>/dev/null; done
  for cf in $(find . -name config.sub); do cp -f /usr/share/automake-1.16/config.sub "$cf" 2>/dev/null; done
  # demos/tests/perf는 gdk-pixbuf-csource로 PNG 로드(qemu에서 실패) → SUBDIRS에서 제거.
  # GTK2 코어 라이브러리(libgtk-x11-2.0)엔 무관.
  ( ./configure --prefix=/usr --sysconfdir=/etc --disable-static --disable-gtk-doc --disable-cups \
    && sed -i '/^SRC_SUBDIRS *=/ s/ demos tests perf//' Makefile \
    && make -j$JOBS && make install ) > /sources/gtk2-build.log 2>&1; rc=$?
  [ $rc -ne 0 ] && { log "FAIL gtk2 rc=$rc"; tail -30 /sources/gtk2-build.log; echo "FAILED_AT=gtk2(rc=$rc)" > /sources/.5d2-FAILED; exit 1; }
  ldconfig 2>/dev/null || true
  touch "$MARKDIR/gtk2"; cd /sources && rm -rf "$dir"; log "OK gtk2"
else log "SKIP gtk2"; fi
pkg-config --exists gtk+-2.0 && log "gtk+-2.0 = $(pkg-config --modversion gtk+-2.0)" || { echo "FAILED_AT=gtk2(pkgconfig)" > /sources/.5d2-FAILED; exit 1; }

# ---- do_build helper (ibus/ibus-hangul, autogen patch) ----
find_tar(){ ls /sources/$1-[0-9v]*.tar.* 2>/dev/null | grep -vE '\.(sha256|sig|asc)$' | sort -V | tail -1; }
topdir(){ tar tf "$1" 2>/dev/null | grep -vE '^\./?$' | sed 's#^\./##' | head -1 | cut -d/ -f1; }
do_build(){
  local glob=$1; shift
  local mk="$MARKDIR/$glob"
  [ -f "$mk" ] && { log "SKIP $glob"; return 0; }
  local tf; tf=$(find_tar "$glob"); [ -z "$tf" ] && { echo "FAILED_AT=$glob(no-source)" > /sources/.5d2-FAILED; exit 1; }
  local dir; dir=$(topdir "$tf")
  log "BUILD $dir"
  cd /sources && rm -rf "$dir" && tar xf "$tf" && cd "$dir" || { echo "FAILED_AT=$glob(extract)" > /sources/.5d2-FAILED; exit 1; }
  [ -f "/sources/patch-$glob.sh" ] && { log "patch $glob"; sh "/sources/patch-$glob.sh" || { echo "FAILED_AT=$glob(patch)" > /sources/.5d2-FAILED; exit 1; }; }
  for cf in $(find . -name config.guess); do cp -f /usr/share/automake-1.16/config.guess "$cf" 2>/dev/null; done
  for cf in $(find . -name config.sub); do cp -f /usr/share/automake-1.16/config.sub "$cf" 2>/dev/null; done
  ( ./configure --prefix=/usr "$@" && make -j$JOBS && make install ) > "/sources/$glob-build.log" 2>&1; local rc=$?
  [ $rc -ne 0 ] && { log "FAIL $dir rc=$rc"; tail -30 "/sources/$glob-build.log"; echo "FAILED_AT=$glob(rc=$rc)" > /sources/.5d2-FAILED; exit 1; }
  ldconfig 2>/dev/null || true
  touch "$mk"; cd /sources && rm -rf "$dir"; log "OK $dir"
}

# ---- ibus (XIM 서버 + gtk2 immodule + libibus + ibus-daemon) ----
do_build ibus --sysconfdir=/etc \
  --enable-gtk2 --enable-xim --disable-gtk3 --disable-gtk4 --disable-vala \
  --disable-introspection --disable-appindicator --disable-tests --disable-gtk-doc \
  --disable-systemd-services --disable-emoji-dict --disable-unicode-dict \
  --disable-python2 --disable-python-library --disable-dbus-python-check \
  --disable-libnotify --disable-wayland --enable-memconf --disable-dconf --disable-setup

# ---- ibus-hangul (ibus-engine-hangul, libhangul 사용) ----
do_build ibus-hangul --disable-static

# ---- 🔴 실기기 필수픽스 2종 (마커 무관 항상 실행, 없으면 한글엔진 크래시/타임아웃) ----
# ① ibus 코어 gschema: --disable-dconf가 data/dconf/ 설치를 스킵 → 엔진이 org.freedesktop.ibus.panel
#    GSettings 스키마 못 찾아 크래시(Trace/breakpoint) → SetGlobalEngine 타임아웃. 소스서 추출·설치·컴파일.
log "install ibus core gschema (data/dconf/) + glib-compile-schemas"
cd /sources && tar xf ibus-1.5.29.tar.gz ibus-1.5.29/data/dconf/org.freedesktop.ibus.gschema.xml 2>/dev/null
if [ -f ibus-1.5.29/data/dconf/org.freedesktop.ibus.gschema.xml ]; then
  cp -f ibus-1.5.29/data/dconf/org.freedesktop.ibus.gschema.xml /usr/share/glib-2.0/schemas/
  glib-compile-schemas /usr/share/glib-2.0/schemas/ >/dev/null 2>&1 && log "  gschema compiled" || log "  ⚠️ gschema compile 경고(무해)"
  rm -rf ibus-1.5.29
else log "  ⚠️ 코어 gschema 추출 실패"; fi
# ② dbus machine-id: from-scratch rootfs가 dbus-uuidgen 안 함 → ibus dbus 통신 실패(machine-id 로드 에러).
[ -s /etc/machine-id ] || dbus-uuidgen > /etc/machine-id 2>/dev/null
mkdir -p /var/lib/dbus; [ -s /var/lib/dbus/machine-id ] || cp -f /etc/machine-id /var/lib/dbus/machine-id
log "machine-id = $(cat /etc/machine-id 2>/dev/null)"

log "===== 5d2 ALL DONE ====="
ok=1
for f in /usr/libexec/ibus-x11 /usr/libexec/ibus-engine-hangul /usr/bin/ibus-daemon /usr/lib/libibus-1.0.so \
         /usr/share/glib-2.0/schemas/org.freedesktop.ibus.gschema.xml /etc/machine-id; do
  [ -e "$f" ] && echo "  ✅ $f" || { echo "  ❌ $f"; ok=0; }
done
# gschema에 panel 스키마 컴파일됐나 (엔진 크래시 방지 핵심)
gsettings list-schemas 2>/dev/null | grep -q "org.freedesktop.ibus.panel" && echo "  ✅ ibus.panel 스키마 컴파일됨" || echo "  ⚠️ panel 스키마 확인불가(gsettings)"
ls /usr/share/ibus/component/hangul.xml >/dev/null 2>&1 && echo "  ✅ hangul.xml 컴포넌트" || { echo "  ❌ hangul.xml"; ok=0; }
[ "$ok" = 1 ] && touch /sources/.5d2-COMPLETE || echo "FAILED_AT=final" > /sources/.5d2-FAILED
INSIDE
chmod +x "$LFS/root/5d2-inside.sh"
echo "===== 5d2 build 시작 (chroot, JOBS=6) $(date 2>/dev/null) ====="
chroot "$LFS" /bin/bash /root/5d2-inside.sh
RC=$?
echo "===== 5d2 build 종료 rc=$RC $(date 2>/dev/null) ====="
if [ -f "$LFS/sources/.5d2-COMPLETE" ]; then
  echo "5D2_COMPLETE=YES"
else
  echo "5D2_COMPLETE=NO"; cat "$LFS/sources/.5d2-FAILED" 2>/dev/null
fi
