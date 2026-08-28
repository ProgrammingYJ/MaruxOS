#!/bin/bash
# =============================================================================
# MaruxOS 2.0.0 "Cooked" — ARM64 Stage 5d: 한글 입력 (ibus-hangul) + gtk3
# -----------------------------------------------------------------------------
# atk/at-spi2-core/gdk-pixbuf/shared-mime-info → gtk3(3.24) → libhangul/ibus/ibus-hangul.
# qemu-chroot 네이티브 aarch64 빌드. resumable(.5d-markers). binfmt 재등록 preamble.
# 성공기준: /usr/lib/ibus/ibus-engine-hangul (또는 ibus-daemon + hangul 엔진).
# =============================================================================
set -uo pipefail
B=/home/administrator/MaruxOS-arm64
LFS=$B/rootfs-clfs-arm64

[[ "$LFS" == *"MaruxOS-arm64"* ]] || { echo "🚨 ABORT: $LFS"; exit 1; }
[ -x "$LFS/tools/bin/aarch64-lfs-linux-gnu-gcc" ] || { echo "🚨 ABORT: 툴체인 없음"; exit 1; }

mountpoint -q /proc/sys/fs/binfmt_misc || mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc
if [ ! -e /proc/sys/fs/binfmt_misc/qemu-aarch64 ]; then
  echo ':qemu-aarch64:M::\x7f\x45\x4c\x46\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-aarch64-static:F' > /proc/sys/fs/binfmt_misc/register
fi
[ -e "$LFS/usr/bin/qemu-aarch64-static" ] || cp /usr/bin/qemu-aarch64-static "$LFS/usr/bin/"
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

# ibus/ibus-hangul(git-archive 타르볼)용: gtk-doc.m4 스텁(gtkdocize 없음, --disable-gtk-doc이라 no-op면 충분)
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
# ibus: autogen(configure 생성). intltoolize + autoreconf. (NOCONFIGURE=1로 configure는 do_build이 실행)
cat > "$LFS/sources/patch-ibus.sh" <<'PATCH'
#!/bin/sh
[ -f configure ] && { echo "configure 존재 - autogen 스킵"; exit 0; }
# gtk-doc/docs 제거: gtkdocize 없음 → autoreconf가 GTK_DOC_CHECK 보고 gtkdocize 호출하는 것 차단
[ -f configure.ac ] && { sed -i 's/^GTK_DOC_CHECK.*/enable_gtk_doc=no/' configure.ac; sed -i '\#^docs/#d' configure.ac; }
[ -f Makefile.am ] && sed -i '/^\tdocs \\$/d' Makefile.am
intltoolize --force --copy --automake 2>&1 | tail -2
NOCONFIGURE=1 autoreconf -fi 2>&1 | tail -6
PATCH
# ibus-hangul도 git-archive면 동일 처리
cp "$LFS/sources/patch-ibus.sh" "$LFS/sources/patch-ibus-hangul.sh"

cat > "$LFS/root/5d-inside.sh" <<'INSIDE'
#!/bin/bash
set -uo pipefail
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
export PKG_CONFIG_PATH=/usr/lib/pkgconfig:/usr/share/pkgconfig
export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
export LC_ALL=C
JOBS=6
MARKDIR=/sources/.5d-markers; mkdir -p "$MARKDIR"
rm -f /sources/.5d-FAILED /sources/.5d-COMPLETE
log(){ echo "[5d] $*"; }
find_tar(){ ls /sources/$1-[0-9v]*.tar.* 2>/dev/null | grep -vE '\.(sha256|sig|asc)$' | sort -V | tail -1; }
topdir(){ tar tf "$1" 2>/dev/null | grep -vE '^\./?$' | sed 's#^\./##' | head -1 | cut -d/ -f1; }
do_build(){  # $1=auto|meson  $2=glob  rest=args
  local tool=$1 glob=$2; shift 2
  local mk="$MARKDIR/$glob"
  [ -f "$mk" ] && { log "SKIP $glob"; return 0; }
  local tf; tf=$(find_tar "$glob")
  [ -z "$tf" ] && { log "FAIL $glob no-source"; echo "FAILED_AT=$glob(no-source)" > /sources/.5d-FAILED; exit 1; }
  local dir; dir=$(topdir "$tf")
  log "BUILD $dir [$tool]"
  cd /sources && rm -rf "$dir" && tar xf "$tf" && cd "$dir" || { echo "FAILED_AT=$glob(extract)" > /sources/.5d-FAILED; exit 1; }
  [ -f "/sources/patch-$glob.sh" ] && { log "patch $glob"; sh "/sources/patch-$glob.sh" || { echo "FAILED_AT=$glob(patch)" > /sources/.5d-FAILED; exit 1; }; }
  local rc=0
  case $tool in
    auto)  ( for cf in $(find . -name config.guess 2>/dev/null); do cp -f /usr/share/automake-1.16/config.guess "$cf" 2>/dev/null; done
            for cf in $(find . -name config.sub   2>/dev/null); do cp -f /usr/share/automake-1.16/config.sub   "$cf" 2>/dev/null; done
            ./configure --prefix=/usr "$@" && make -j$JOBS && make install ); rc=$? ;;
    meson) ( meson setup _b --prefix=/usr --buildtype=release "$@" && ninja -C _b -j$JOBS && ninja -C _b install ); rc=$? ;;
  esac
  [ $rc -ne 0 ] && { log "FAIL $dir rc=$rc"; echo "FAILED_AT=$glob" > /sources/.5d-FAILED; exit 1; }
  ldconfig 2>/dev/null || true
  touch "$mk"; cd /sources && rm -rf "$dir"; log "OK $dir"
}

# ---- a11y / 이미지 / mime (gtk3 의존) ----
do_build meson atk              -Dintrospection=false
do_build meson at-spi2-core     -Dintrospection=disabled -Dx11=enabled
do_build meson shared-mime-info
do_build meson gdk-pixbuf       -Dintrospection=disabled -Dman=false -Dtests=false
# gdk-pixbuf 로더 캐시 생성 (없으면 PNG 등 로드 불가 → gtk3 리소스 컴파일이 심볼릭아이콘 PNG 못읽어 실패)
gdk-pixbuf-query-loaders --update-cache 2>/dev/null || true
log "loaders.cache = $(wc -l < /usr/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache 2>/dev/null) lines"
# ---- GTK3: qemu-chroot에서 gdk-pixbuf 로더 등록 실패(에뮬 한계)로 SKIP. 실기기 Pi 네이티브 빌드 예정 ----
# do_build meson gtk+           -Dintrospection=false -Dwayland_backend=false -Dx11_backend=true -Dtests=false -Ddemos=false -Dexamples=false -Dcolord=no -Dgtk_doc=false -Dman=false
# ---- 한글 (gtk3 없이 엔진만: libibus+ibus-daemon+ibus-engine-hangul) ----
do_build auto  libhangul        --disable-static
do_build auto  ibus             --disable-vala --disable-python2 --disable-emoji-dict --disable-unicode-dict --disable-introspection --disable-gtk2 --disable-gtk3 --disable-gtk4 --disable-appindicator --disable-tests --disable-gtk-doc --disable-systemd-services --disable-ui
do_build auto  ibus-hangul

log "===== 5d ALL DONE ====="
ok=1
ls /usr/lib/ibus/ibus-engine-hangul >/dev/null 2>&1 && echo "  ✅ ibus-engine-hangul" || { echo "  ❌ ibus-engine-hangul"; ok=0; }
command -v ibus-daemon >/dev/null 2>&1 && echo "  ✅ ibus-daemon" || { echo "  ❌ ibus-daemon"; ok=0; }
pkg-config --exists hangul && echo "  ✅ libhangul $(pkg-config --modversion hangul)" || { echo "  ❌ libhangul"; ok=0; }
pkg-config --exists gtk+-3.0 && echo "  (i) gtk+-3.0 있음" || echo "  (i) gtk3 없음(예정대로 SKIP — 실기기 네이티브 빌드)"
[ "$ok" = 1 ] && touch /sources/.5d-COMPLETE || echo "FAILED_AT=final" > /sources/.5d-FAILED
INSIDE
chmod +x "$LFS/root/5d-inside.sh"
echo "===== 5d build 시작 (chroot, JOBS=6) $(date 2>/dev/null) ====="
chroot "$LFS" /bin/bash /root/5d-inside.sh
RC=$?
echo "===== 5d build 종료 rc=$RC $(date 2>/dev/null) ====="
[ -f "$LFS/sources/.5d-COMPLETE" ] && echo "5D_COMPLETE=YES" || { echo "5D_COMPLETE=NO"; cat "$LFS/sources/.5d-FAILED" 2>/dev/null; }
