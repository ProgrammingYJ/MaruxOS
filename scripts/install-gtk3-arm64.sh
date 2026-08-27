#!/bin/bash
# =============================================================================
# MaruxOS 2.0.0 "Cooked" — ARM64 배치 B-2: gtk3 + Firefox + gtk3 한글입력
# -----------------------------------------------------------------------------
# 5d 부검 재규명 (2026-07-24):
#   - gtk+-3.24.41 타르볼은 meson 전용(autotools 제거됨). 5d는 올바른 플래그로
#     meson setup까지 성공했고(_b/build.ninja 존재), ninja_log상 코드젠 6개 완료 후
#     .o 0개에서 중단 = "pixbuf 벽"이 아니라 binfmt 소실(함정#5) 중도사 정황.
#   - gtk3 코어 빌드엔 gdk-pixbuf 실행 스텝이 없음: 심볼릭 PNG 206개는 타르볼에
#     pre-encode 돼있고 gresource로 바이트 임베드만 됨. encode-symbolic-svg 등은
#     도구로 컴파일만 됨(빌드 중 미실행).
#   - 유일한 pixbuf 접점 = ninja install의 build-aux/meson/post-install.py
#     (gtk-update-icon-cache /usr/share/icons/hicolor + gtk-query-immodules-3.0)
#     → hicolor-icon-theme 선설치 + install 실패 시 수동 폴백으로 방어.
# 내용물:
#   ① hicolor-icon-theme 0.17 + shared-mime-info 2.4 (gtk3/Firefox 런타임 데이터)
#   ② alsa-lib 1.2.10 (Firefox 오디오 — 커널 SND는 5a에서 =y)
#   ③ gtk+-3.24.41 (meson, qemu-chroot) ← 배치 B-2 롱폴
#   ④ ibus 1.5.29 재빌드 --enable-gtk2+--enable-gtk3 (gtk3 immodule im-ibus.so)
#      + gtk-query-immodules-3.0 --update-cache + gschema/machine-id 픽스(멱등)
#   ⑤ libxkbfile + setxkbmap (startx 경고 제거)
#   ⑥ Firefox ESR 140.13.0esr 공식 aarch64 **한국어(ko)** prebuilt → /opt/firefox
#      (SHA256SUMS raw 검증 — 게이트 원칙: AI요약 아닌 원본 바이트) + chroot ldd 의존성 검증
#      libXss 요구 시에만 libXScrnSaver 빌드.
# qemu-chroot 네이티브 aarch64. resumable(.b2-markers). 완료기준: .b2-COMPLETE.
# 실행: wsl -u root bash <this>  (nohup setsid 권장 — 함정#6)
# =============================================================================
set -uo pipefail
B=/home/administrator/MaruxOS-arm64
LFS=$B/rootfs-clfs-arm64
S=$LFS/sources
DL=$B/downloads
FF_VER=140.13.0esr
FF_TAR=firefox-$FF_VER.tar.xz
FF_BASE="https://download-installer.cdn.mozilla.net/pub/firefox/releases/$FF_VER"
[[ "$LFS" == *"MaruxOS-arm64"* ]] || { echo "🚨 ABORT: $LFS"; exit 1; }
[ -s "$S/gtk+-3.24.41.tar.xz" ] || { echo "🚨 ABORT: gtk3 타르볼 없음"; exit 1; }
[ -e "$LFS/usr/lib/libgdk_pixbuf-2.0.so" ] || { echo "🚨 ABORT: gdk-pixbuf 없음"; exit 1; }
[ -e "$LFS/usr/lib/libatk-bridge-2.0.so" ] || { echo "🚨 ABORT: atk-bridge 없음"; exit 1; }
[ -e "$LFS/usr/lib/libcairo-gobject.so" ] || { echo "🚨 ABORT: cairo-gobject 없음"; exit 1; }
[ -x "$LFS/usr/libexec/ibus-x11" ] || { echo "🚨 ABORT: B-1(ibus XIM) 미완"; exit 1; }

# ---------- 소스 fetch (호스트) ----------
mkdir -p "$S" "$DL"
fetch(){ # fetch <url> <dest>
  [ -s "$2" ] && return 0
  echo "[fetch] $(basename "$2")"
  timeout 300 wget -q -O "$2" "$1" || { rm -f "$2"; echo "🚨 ABORT: fetch 실패 $1"; exit 1; }
  echo "  OK $(ls -lh "$2" | awk '{print $5}')"
}
fetch "https://www.x.org/pub/individual/lib/libxkbfile-1.1.2.tar.xz"      "$S/libxkbfile-1.1.2.tar.xz"
fetch "https://www.x.org/pub/individual/app/setxkbmap-1.3.4.tar.xz"      "$S/setxkbmap-1.3.4.tar.xz"
fetch "https://icon-theme.freedesktop.org/releases/hicolor-icon-theme-0.17.tar.xz" "$S/hicolor-icon-theme-0.17.tar.xz"
fetch "https://www.x.org/pub/individual/lib/libXScrnSaver-1.2.4.tar.xz"  "$S/libXScrnSaver-1.2.4.tar.xz"
fetch "https://www.alsa-project.org/files/pub/lib/alsa-lib-1.2.10.tar.bz2" "$S/alsa-lib-1.2.10.tar.bz2"

# ---------- Firefox: SHA256SUMS raw 검증 후 다운로드 ----------
fetch "$FF_BASE/SHA256SUMS" "$DL/SHA256SUMS-$FF_VER"
FF_SHA=$(grep -E " linux-aarch64/ko/$FF_TAR\$" "$DL/SHA256SUMS-$FF_VER" | awk '{print $1}')
[ -n "$FF_SHA" ] || { echo "🚨 ABORT: SHA256SUMS에 linux-aarch64/ko/$FF_TAR 없음"; exit 1; }
echo "[firefox] expected SHA256 = $FF_SHA"
if [ -s "$DL/$FF_TAR" ]; then
  ACT=$(sha256sum "$DL/$FF_TAR" | awk '{print $1}')
  [ "$ACT" = "$FF_SHA" ] || { echo "  기존 파일 SHA 불일치 → 재다운로드"; rm -f "$DL/$FF_TAR"; }
fi
fetch "$FF_BASE/linux-aarch64/ko/$FF_TAR" "$DL/$FF_TAR"
ACT=$(sha256sum "$DL/$FF_TAR" | awk '{print $1}')
[ "$ACT" = "$FF_SHA" ] || { echo "🚨 ABORT: Firefox SHA256 불일치 ($ACT)"; exit 1; }
echo "  ✅ Firefox SHA256 검증 통과"

# ---------- binfmt + mounts + CA (B-1 스캐폴드) ----------
mountpoint -q /proc/sys/fs/binfmt_misc || mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc
[ -e /proc/sys/fs/binfmt_misc/qemu-aarch64 ] || echo ':qemu-aarch64:M::\x7f\x45\x4c\x46\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-aarch64-static:F' > /proc/sys/fs/binfmt_misc/register
[ -e "$LFS/usr/bin/qemu-aarch64-static" ] || cp /usr/bin/qemu-aarch64-static "$LFS/usr/bin/"
cp -f /etc/resolv.conf "$LFS/etc/resolv.conf" 2>/dev/null || true
mkdir -p "$LFS/etc/ssl/certs"; cp -f /etc/ssl/certs/ca-certificates.crt "$LFS/etc/ssl/certs/" 2>/dev/null || true
for fs in dev dev/pts proc sys run; do
  mkdir -p "$LFS/$fs"; mountpoint -q "$LFS/$fs" && continue
  case $fs in dev) mount --bind /dev "$LFS/dev";; dev/pts) mount --bind /dev/pts "$LFS/dev/pts";; proc) mount -t proc proc "$LFS/proc";; sys) mount -t sysfs sysfs "$LFS/sys";; run) mount -t tmpfs tmpfs "$LFS/run";; esac
done

# ---------- Firefox 추출 → $LFS/opt/firefox ----------
if [ ! -x "$LFS/opt/firefox/firefox" ]; then
  echo "[firefox] extract → /opt/firefox"
  mkdir -p "$LFS/opt"; rm -rf "$LFS/opt/firefox"
  tar -C "$LFS/opt" -xf "$DL/$FF_TAR" || { echo "🚨 ABORT: firefox 추출 실패"; exit 1; }
  [ -x "$LFS/opt/firefox/firefox" ] || { echo "🚨 ABORT: firefox 바이너리 없음"; exit 1; }
fi
ln -sf /opt/firefox/firefox "$LFS/usr/bin/firefox"

# ---------- ibus autogen 패치 스크립트 (B-1과 동일, 멱등 재생성) ----------
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
touch ChangeLog NEWS AUTHORS README gtk-doc.make
intltoolize --force --copy --automake 2>&1 | tail -2
NOCONFIGURE=1 autoreconf -fi 2>&1 | tail -6
[ -f configure ] || { echo "autogen 실패: configure 미생성"; exit 1; }
if [ -d bindings ] && [ ! -f bindings/Makefile.in ]; then echo "autogen 실패: bindings/Makefile.in 미생성"; exit 1; fi
exit 0
PATCH

# ---------- chroot 내부 빌드 스크립트 ----------
cat > "$LFS/root/b2-inside.sh" <<'INSIDE'
#!/bin/bash
set -uo pipefail
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
export PKG_CONFIG_PATH=/usr/lib/pkgconfig:/usr/share/pkgconfig
export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
export LC_ALL=C
export GDK_PIXBUF_MODULE_FILE=/usr/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache
export GDK_PIXBUF_MODULEDIR=/usr/lib/gdk-pixbuf-2.0/2.10.0/loaders
export ISOCODES_CFLAGS=" " ISOCODES_LIBS=" "
JOBS=6
MARKDIR=/sources/.b2-markers; mkdir -p "$MARKDIR"
rm -f /sources/.b2-FAILED /sources/.b2-COMPLETE
log(){ echo "[b2] $(date '+%H:%M:%S') $*"; }
fail(){ echo "FAILED_AT=$1" > /sources/.b2-FAILED; exit 1; }

# ---- do_build helper (autotools, B-1 패턴) ----
find_tar(){ ls /sources/$1-[0-9v]*.tar.* 2>/dev/null | grep -vE '\.(sha256|sig|asc)$' | sort -V | tail -1; }
topdir(){ tar tf "$1" 2>/dev/null | grep -vE '^\./?$' | sed 's#^\./##' | head -1 | cut -d/ -f1; }
do_build(){
  local glob=$1; shift
  local mk="$MARKDIR/$glob"
  [ -f "$mk" ] && { log "SKIP $glob"; return 0; }
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
  touch "$mk"; cd /sources && rm -rf "$dir"; log "OK $dir"
}

# ---- ① hicolor-icon-theme (gtk3 post-install.py의 icon-cache 대상 — 선설치 필수) ----
do_build hicolor-icon-theme

# ---- ① shared-mime-info (meson; tests는 네트워크 wrap(xdgmime) 요구 → 제거) ----
if [ ! -f "$MARKDIR/shared-mime-info" ]; then
  tf=$(ls /sources/shared-mime-info-2*.tar.* | tail -1); dir=$(topdir "$tf")
  log "BUILD $dir [meson]"
  cd /sources && rm -rf "$dir" && tar xf "$tf" && cd "$dir" || fail "smi(extract)"
  sed -i "/subdir('tests')/d" meson.build 2>/dev/null || true
  ( meson setup _build --prefix=/usr --buildtype=release --wrap-mode=nofallback \
      -Dupdate-mimedb=true && ninja -C _build -j$JOBS && ninja -C _build install ) \
    > /sources/shared-mime-info-build.log 2>&1; rc=$?
  [ $rc -ne 0 ] && { tail -30 /sources/shared-mime-info-build.log; fail "shared-mime-info(rc=$rc)"; }
  touch "$MARKDIR/shared-mime-info"; cd /sources && rm -rf "$dir"; log "OK $dir"
else log "SKIP shared-mime-info"; fi

# ---- ② alsa-lib (Firefox 오디오; 커널 SND는 5a =y) ----
do_build alsa-lib --disable-static

# ---- ③ gtk+-3.24.41 (meson — B-2 롱폴. 5d와 동일 플래그, 완주만 하면 됨) ----
if [ ! -f "$MARKDIR/gtk3" ]; then
  log "BUILD gtk+-3.24.41 [meson] — 롱폴 시작 (qemu에서 수시간 가능)"
  cd /sources && rm -rf gtk+-3.24.41 && tar xf gtk+-3.24.41.tar.xz && cd gtk+-3.24.41 || fail "gtk3(extract)"
  meson setup _build --prefix=/usr --sysconfdir=/etc --buildtype=release --wrap-mode=nofallback \
    -Dx11_backend=true -Dwayland_backend=false -Dbroadway_backend=false \
    -Dintrospection=false -Dgtk_doc=false -Dman=false \
    -Ddemos=false -Dexamples=false -Dtests=false -Dinstalled_tests=false \
    -Dcolord=no > /sources/gtk3-build.log 2>&1; rc=$?
  [ $rc -ne 0 ] && { tail -40 /sources/gtk3-build.log; fail "gtk3(setup rc=$rc)"; }
  log "gtk3 meson setup OK → ninja"
  ninja -C _build -j$JOBS >> /sources/gtk3-build.log 2>&1; rc=$?
  [ $rc -ne 0 ] && { tail -40 /sources/gtk3-build.log; fail "gtk3(ninja rc=$rc)"; }
  log "gtk3 ninja OK → install"
  ninja -C _build install >> /sources/gtk3-build.log 2>&1; rc=$?
  if [ $rc -ne 0 ]; then
    # post-install.py(icon-cache/immodules 쿼리)가 qemu에서 죽었을 가능성 — 라이브러리 자체가
    # 설치됐으면 수동 폴백으로 살린다 (아니면 진짜 실패)
    if [ -e /usr/lib/libgtk-3.so.0 ]; then
      log "⚠️ ninja install rc=$rc — 라이브러리는 설치됨, post-install 수동 폴백"
      /usr/bin/gtk-query-immodules-3.0 --update-cache 2>/dev/null || log "  ⚠️ immodules 쿼리 실패(ibus 단계서 재시도)"
      gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null || log "  ⚠️ icon-cache 실패(비치명)"
      glib-compile-schemas /usr/share/glib-2.0/schemas/ 2>/dev/null || true
    else
      tail -40 /sources/gtk3-build.log; fail "gtk3(install rc=$rc)"
    fi
  fi
  ldconfig 2>/dev/null || true
  pkg-config --exists 'gtk+-3.0 >= 3.24' || fail "gtk3(pkgconfig)"
  log "OK gtk+-3.0 = $(pkg-config --modversion gtk+-3.0)"
  touch "$MARKDIR/gtk3"; cd /sources && rm -rf gtk+-3.24.41
else log "SKIP gtk3"; fi
pkg-config --exists gtk+-3.0 || fail "gtk3(pkgconfig-recheck)"

# ---- ④ ibus 재빌드: gtk2 + gtk3 immodule (B-1 플래그 + --enable-gtk3 + --disable-ui) ----
# ⚠️ --disable-ui 필수: ui/gtk3(패널/이모지피커)의 vala 사전생성 C가 wayland 헤더
# (gdk/gdkwayland.h, ibuswaylandim.h)를 --disable-wayland여도 하드 include → 우리 gtk3는
# wayland 백엔드 없음 → 컴파일 사망(1차 시도 rc=2). 패널은 --panel disable로 안 쓰므로 통째 스킵.
# im-ibus.so(client/gtk3)는 GDK_WINDOWING_WAYLAND 미정의라 무사.
do_build ibus --sysconfdir=/etc \
  --enable-gtk2 --enable-gtk3 --enable-xim --disable-gtk4 --disable-vala \
  --disable-ui --disable-introspection --disable-appindicator --disable-tests --disable-gtk-doc \
  --disable-systemd-services --disable-emoji-dict --disable-unicode-dict \
  --disable-python2 --disable-python-library --disable-dbus-python-check \
  --disable-libnotify --disable-wayland --enable-memconf --disable-dconf --disable-setup
[ -e /usr/lib/gtk-3.0/3.0.0/immodules/im-ibus.so ] || fail "ibus(gtk3-immodule 미설치)"
/usr/bin/gtk-query-immodules-3.0 --update-cache || fail "ibus(gtk3 immodules.cache)"
grep -q ibus /usr/lib/gtk-3.0/3.0.0/immodules.cache || fail "ibus(cache에 ibus 없음)"
log "OK gtk3 im-ibus.so + immodules.cache"

# ---- 🔴 B-1 실기기 필수픽스 재적용 (멱등 — ibus 재설치가 지워도 복원) ----
log "re-apply: ibus core gschema + machine-id"
cd /sources && tar xf ibus-1.5.29.tar.gz ibus-1.5.29/data/dconf/org.freedesktop.ibus.gschema.xml 2>/dev/null
if [ -f ibus-1.5.29/data/dconf/org.freedesktop.ibus.gschema.xml ]; then
  cp -f ibus-1.5.29/data/dconf/org.freedesktop.ibus.gschema.xml /usr/share/glib-2.0/schemas/
  glib-compile-schemas /usr/share/glib-2.0/schemas/ >/dev/null 2>&1 || true
  rm -rf ibus-1.5.29
fi
[ -s /etc/machine-id ] || dbus-uuidgen > /etc/machine-id 2>/dev/null
mkdir -p /var/lib/dbus; [ -s /var/lib/dbus/machine-id ] || cp -f /etc/machine-id /var/lib/dbus/machine-id

# ---- ⑤ libxkbfile + setxkbmap ----
do_build libxkbfile --disable-static
do_build setxkbmap

# ---- ⑥ Firefox 의존성 검증 (chroot ldd) — libXss 필요 시에만 XScrnSaver 빌드 ----
# ⚠️ qemu chroot ldd는 RPATH($ORIGIN) 못 풀어 FF 자기 번들 라이브러리(libnspr4/libnss3/
# libmozgtk 등)를 not found로 오탐(1차 시도 FAILED_AT=final 원인) → /opt/firefox 안에
# 실존하는 건 실기기서 RPATH로 해결되므로 필터. 진짜 시스템 의존성 미해결만 남김.
ffdeps(){ (ldd /opt/firefox/firefox /opt/firefox/libxul.so 2>/dev/null || true) | grep "not found" | awk '{print $1}' | sort -u | while read -r l; do [ -e "/opt/firefox/$l" ] || echo "$l"; done; }
MISS=$(ffdeps)
if echo "$MISS" | grep -q "libXss"; then
  log "Firefox가 libXss 요구 → libXScrnSaver 빌드"
  do_build libXScrnSaver --disable-static
  MISS=$(ffdeps)
fi
if [ -n "$MISS" ]; then
  log "🔴 Firefox 미해결 의존성:"; echo "$MISS" | sed 's/^/    /'
  echo "$MISS" > /sources/.b2-FFDEPS
else
  log "✅ Firefox ldd 의존성 전부 해결"
  rm -f /sources/.b2-FFDEPS
fi

# ---- 최종 검증 ----
log "===== B-2 최종 검증 ====="
ok=1
for f in /usr/lib/libgtk-3.so.0 /usr/lib/gtk-3.0/3.0.0/immodules/im-ibus.so \
         /usr/lib/gtk-3.0/3.0.0/immodules.cache /usr/bin/setxkbmap \
         /usr/share/mime/mime.cache /usr/lib/libasound.so.2 \
         /opt/firefox/firefox /usr/bin/firefox \
         /usr/libexec/ibus-x11 /usr/libexec/ibus-engine-hangul \
         /usr/share/glib-2.0/schemas/org.freedesktop.ibus.gschema.xml /etc/machine-id; do
  [ -e "$f" ] && echo "  ✅ $f" || { echo "  ❌ $f"; ok=0; }
done
[ -f /sources/.b2-FFDEPS ] && { echo "  ❌ Firefox deps 미해결"; ok=0; }
gsettings list-schemas 2>/dev/null | grep -q "org.freedesktop.ibus.panel" && echo "  ✅ ibus.panel 스키마" || echo "  ⚠️ panel 스키마 확인불가"
[ "$ok" = 1 ] && touch /sources/.b2-COMPLETE || fail "final"
log "===== B-2 ALL DONE ====="
INSIDE
chmod +x "$LFS/root/b2-inside.sh"
echo "===== B-2 build 시작 (chroot, JOBS=6) $(date 2>/dev/null) ====="
chroot "$LFS" /bin/bash /root/b2-inside.sh
RC=$?
echo "===== B-2 build 종료 rc=$RC $(date 2>/dev/null) ====="
if [ -f "$LFS/sources/.b2-COMPLETE" ]; then
  echo "B2_COMPLETE=YES"
else
  echo "B2_COMPLETE=NO"; cat "$LFS/sources/.b2-FAILED" 2>/dev/null
fi
