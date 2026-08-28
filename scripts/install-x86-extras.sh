#!/bin/bash
# =============================================================================
# install-x86-extras.sh — x86 데스크톱 패리티 배치 X (2026-08-28)
#   ARM64 이미지엔 있고 x86 패리티 rootfs엔 없던 "퀵설정의 전제" 2종을 x86 rootfs 안에서
#   **네이티브 chroot 빌드**로 채운다 (x86 rootfs는 gcc 13.2.0·autotools를 갖고 있어 크로스 불요).
#   ① alsa-lib 1.2.10(헤더 — x86엔 libasound.so.2만 있고 /usr/include/alsa 없음) + alsa-utils 1.2.10
#      → amixer/aplay = marux-quicksettings 볼륨 백엔드 (ARM64 v19 픽스와 동일)
#   ② ibus-hangul 1.5.5 재빌드 + **한/영 상태 노출 패치**(patches/ibus-hangul-1.5.5-export-input-mode.patch)
#      → /tmp/marux-ime-mode 로 통합 상태 바의 한A 표시가 실제 모드를 따라감 (ARM64 v23)
#   마커: $B/.x-COMPLETE (+ rootfs /sources/.x-markers/*). 멱등 — 완료분은 SKIP.
#   ⚠️ 규칙(함정 #36): 패키지 (재)설치 뒤엔 setup-desktop-config-x86 재적용.
# =============================================================================
set -uo pipefail
B=/home/administrator/MaruxOS/x86-parity
LFS=$B/rootfs-lfs-parity
S=$LFS/sources
ARMSRC=/home/administrator/MaruxOS-arm64/rootfs-clfs-arm64/sources   # 타르볼 재사용(동일 버전)
WINROOT=/mnt/c/Users/Administrator/Desktop/MaruxOS
JOBS=${JOBS:-32}

[[ "$LFS" == *"x86-parity"* ]] || { echo "🚨 ABORT: $LFS"; exit 1; }
[[ "$LFS" == *"/MaruxOS/build/"* ]] && { echo "🚨 ABORT: 원본 x86 rootfs를 건드리려 함"; exit 1; }
[ -d "$LFS/usr" ] || { echo "🚨 ABORT: rootfs 없음"; exit 1; }
[ -e "$LFS/usr/lib/libasound.so.2" ] || { echo "🚨 ABORT: alsa-lib 런타임 없음(전제 불일치)"; exit 1; }
[ -d "$LFS/usr/include/ibus-1.0" ] && [ -d "$LFS/usr/include/hangul-1.0" ] || { echo "🚨 ABORT: ibus/libhangul 헤더 없음"; exit 1; }
[ -s "$WINROOT/patches/ibus-hangul-1.5.5-export-input-mode.patch" ] || { echo "🚨 ABORT: 한/영 노출 패치 파일 없음"; exit 1; }

# ---------- 타르볼 (ARM64 sources 재사용 → 없으면 fetch) ----------
mkdir -p "$S"
fetch(){ [ -s "$2" ] && return 0; echo "[fetch] $(basename "$2")"; timeout 300 wget -q -O "$2" "$1" || { rm -f "$2"; echo "🚨 ABORT: fetch 실패 $1"; exit 1; }; }
for t in alsa-lib-1.2.10.tar.bz2 alsa-utils-1.2.10.tar.bz2 ibus-hangul-1.5.5.tar.gz; do
  [ -s "$S/$t" ] || { [ -s "$ARMSRC/$t" ] && cp -f "$ARMSRC/$t" "$S/$t"; }
done
fetch "https://www.alsa-project.org/files/pub/lib/alsa-lib-1.2.10.tar.bz2"      "$S/alsa-lib-1.2.10.tar.bz2"
fetch "https://www.alsa-project.org/files/pub/utils/alsa-utils-1.2.10.tar.bz2"  "$S/alsa-utils-1.2.10.tar.bz2"
fetch "https://github.com/libhangul/ibus-hangul/releases/download/1.5.5/ibus-hangul-1.5.5.tar.gz" "$S/ibus-hangul-1.5.5.tar.gz"
cp -f "$WINROOT/patches/ibus-hangul-1.5.5-export-input-mode.patch" "$S/ibus-hangul-export-input-mode.patch"
echo "  타르볼: $(ls -la "$S"/alsa-lib-1.2.10.tar.bz2 "$S"/alsa-utils-1.2.10.tar.bz2 "$S"/ibus-hangul-1.5.5.tar.gz | awk '{print $5}' | tr '\n' ' ')"

# ---------- mounts ----------
cp -f /etc/resolv.conf "$LFS/etc/resolv.conf" 2>/dev/null || true
for fs in dev dev/pts proc sys run; do
  mkdir -p "$LFS/$fs"; mountpoint -q "$LFS/$fs" && continue
  case $fs in dev) mount --bind /dev "$LFS/dev";; dev/pts) mount --bind /dev/pts "$LFS/dev/pts";; proc) mount -t proc proc "$LFS/proc";; sys) mount -t sysfs sysfs "$LFS/sys";; run) mount -t tmpfs tmpfs "$LFS/run";; esac
done
cleanup(){ for m in run sys proc dev/pts dev; do mountpoint -q "$LFS/$m" && umount "$LFS/$m"; done; }
trap cleanup EXIT

# ---------- chroot 내부 빌드 ----------
cat > "$LFS/root/extras-inside.sh" <<INSIDE
#!/bin/bash
set -uo pipefail
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
export PKG_CONFIG_PATH=/usr/lib/pkgconfig:/usr/share/pkgconfig:/usr/lib64/pkgconfig
export LC_ALL=C
export ISOCODES_CFLAGS=" " ISOCODES_LIBS=" "    # iso-codes 불요(ARM64 5d2와 동일)
JOBS=$JOBS
MARKDIR=/sources/.x-markers; mkdir -p "\$MARKDIR"
rm -f /sources/.x-FAILED /sources/.x-COMPLETE
log(){ echo "[X] \$*"; }
fail(){ echo "FAILED_AT=\$1" > /sources/.x-FAILED; echo "🚨 \$1"; exit 1; }

# ---- alsa-lib 1.2.10 (헤더 목적 — 런타임 so는 같은 버전으로 덮임) ----
if [ ! -f "\$MARKDIR/alsalib" ]; then
  log "BUILD alsa-lib-1.2.10"
  cd /sources && rm -rf alsa-lib-1.2.10 && tar xf alsa-lib-1.2.10.tar.bz2 && cd alsa-lib-1.2.10 || fail alsalib-extract
  ( ./configure --prefix=/usr --disable-static && make -j\$JOBS && make install ) > /sources/x-alsalib-build.log 2>&1; rc=\$?
  [ \$rc -ne 0 ] && { tail -25 /sources/x-alsalib-build.log; fail "alsalib(rc=\$rc)"; }
  ldconfig; touch "\$MARKDIR/alsalib"; cd /sources && rm -rf alsa-lib-1.2.10; log "OK alsa-lib"
else log "SKIP alsa-lib"; fi
[ -f /usr/include/alsa/asoundlib.h ] || fail alsalib-header
[ -e /usr/lib/libasound.so.2 ] || fail alsalib-runtime

# ---- alsa-utils 1.2.10 (amixer/aplay — 퀵설정 볼륨 백엔드) ----
if [ ! -f "\$MARKDIR/alsautils" ]; then
  log "BUILD alsa-utils-1.2.10"
  AM=""; { [ -f /usr/include/curses.h ] || [ -f /usr/include/ncursesw/curses.h ]; } || { AM="--disable-alsamixer"; log "  (ncurses 헤더 없음 → alsamixer 제외, amixer/aplay만)"; }
  cd /sources && rm -rf alsa-utils-1.2.10 && tar xf alsa-utils-1.2.10.tar.bz2 && cd alsa-utils-1.2.10 || fail alsautils-extract
  ( ./configure --prefix=/usr --disable-alsaconf --disable-bat --disable-xmlto --disable-rst2man \$AM \\
    && make -j\$JOBS && make install ) > /sources/x-alsautils-build.log 2>&1; rc=\$?
  [ \$rc -ne 0 ] && { tail -25 /sources/x-alsautils-build.log; fail "alsautils(rc=\$rc)"; }
  touch "\$MARKDIR/alsautils"; cd /sources && rm -rf alsa-utils-1.2.10; log "OK alsa-utils"
else log "SKIP alsa-utils"; fi
/usr/bin/amixer --version >/dev/null 2>&1 || fail amixer-run
/usr/bin/aplay --version  >/dev/null 2>&1 || fail aplay-run

# ---- ibus-hangul 1.5.5 + 한/영 상태 노출 패치 ----
if [ ! -f "\$MARKDIR/ibushangul" ]; then
  log "BUILD ibus-hangul-1.5.5 (+export-input-mode)"
  cd /sources && rm -rf ibus-hangul-1.5.5 && tar xf ibus-hangul-1.5.5.tar.gz && cd ibus-hangul-1.5.5 || fail hangul-extract
  # 공개 patches/ 의 diff를 그대로 적용(SBOM/공개 소스와 바이트 일치). 안 맞으면 등가 sed 폴백 + 경고.
  if patch -p1 --dry-run -s < /sources/ibus-hangul-export-input-mode.patch >/dev/null 2>&1; then
    patch -p1 -s < /sources/ibus-hangul-export-input-mode.patch || fail hangul-patch
    log "  patches/ibus-hangul-1.5.5-export-input-mode.patch 적용"
  else
    log "  ⚠ 공개 패치가 dry-run에서 안 맞음 → 등가 sed 폴백 (패치 파일 점검 필요)"
    sed -i 's|^    hangul->input_mode = input_mode;|    hangul->input_mode = input_mode; { FILE *mf = fopen ("/tmp/marux-ime-mode", "w"); if (mf != NULL) { fputs ((input_mode == INPUT_MODE_HANGUL) ? "han" : "eng", mf); fclose (mf); } }|' src/engine.c
  fi
  grep -q "marux-ime-mode" src/engine.c || fail hangul-patch-verify
  # GitHub 릴리즈 타르볼엔 configure가 없다 → autogen (ARM64 5d2 patch-ibus-hangul.sh와 동일 전처리):
  #  ① gtk+-3.0 필수 PKG_CHECK 제거(setup GUI 불요, 엔진만) ② tests/ 제거(gtk 컴파일) ③ GTK_DOC_CHECK → enable_gtk_doc=no
  #  ④ GNU strictness 파일 + gtk-doc.make 더미 → intltoolize → autoreconf
  if [ ! -f configure ]; then
    sed -i '/PKG_CHECK_MODULES(GTK,/,/^])/d' configure.ac
    sed -i 's/^GTK_DOC_CHECK.*/enable_gtk_doc=no/' configure.ac
    sed -i '/^\ttests \\\\\$/d' Makefile.am
    touch ChangeLog NEWS AUTHORS README gtk-doc.make
    ( intltoolize --force --copy --automake && NOCONFIGURE=1 autoreconf -fi ) > /sources/x-ibushangul-autogen.log 2>&1 || { tail -20 /sources/x-ibushangul-autogen.log; fail hangul-autogen; }
    [ -f configure ] || fail hangul-autogen-noconfigure
    log "  autogen OK"
  fi
  ( ./configure --prefix=/usr --libexecdir=/usr/lib/ibus --disable-static && make -j\$JOBS && make install ) > /sources/x-ibushangul-build.log 2>&1; rc=\$?
  [ \$rc -ne 0 ] && { tail -30 /sources/x-ibushangul-build.log; fail "ibushangul(rc=\$rc)"; }
  touch "\$MARKDIR/ibushangul"; cd /sources && rm -rf ibus-hangul-1.5.5; log "OK ibus-hangul"
else log "SKIP ibus-hangul"; fi
grep -qa "marux-ime-mode" /usr/lib/ibus/ibus-engine-hangul || fail hangul-marker
EXEC=\$(grep -o '<exec>[^< ]*' /usr/share/ibus/component/hangul.xml | sed 's|<exec>||')
[ -x "\$EXEC" ] || fail "hangul-xml-exec(\$EXEC)"
ldconfig
touch /sources/.x-COMPLETE
log "===== EXTRAS DONE ====="
INSIDE
chmod +x "$LFS/root/extras-inside.sh"
echo "===== x86 extras 빌드 시작 (chroot native) $(date) ====="
chroot "$LFS" /bin/bash /root/extras-inside.sh; RC=$?
echo "===== 종료 rc=$RC ====="
[ -f "$S/.x-COMPLETE" ] || { echo "X_COMPLETE=NO"; cat "$S/.x-FAILED" 2>/dev/null; exit 1; }

# ---------- 호스트측 게이트 ----------
ok=1
for f in usr/bin/amixer usr/bin/aplay usr/lib/ibus/ibus-engine-hangul usr/include/alsa/asoundlib.h; do
  [ -e "$LFS/$f" ] && echo "  ✅ $f" || { echo "  ❌ $f"; ok=0; }; done
for f in usr/bin/amixer usr/lib/ibus/ibus-engine-hangul; do
  readelf -h "$LFS/$f" | grep -q 'X86-64' || { echo "  ❌ $f 아키텍처"; ok=0; }; done
grep -qa "marux-ime-mode" "$LFS/usr/lib/ibus/ibus-engine-hangul" && echo "  ✅ 한/영 노출 마커" || { echo "  ❌ 한/영 노출 마커 없음"; ok=0; }
rm -f "$LFS/root/extras-inside.sh"
[ "$ok" = 1 ] && { touch "$B/.x-COMPLETE"; echo "X86_EXTRAS_COMPLETE=YES"; echo "  ⚠️ 다음: setup-desktop-config-x86 재적용(함정 #36)"; } || { echo "X86_EXTRAS_COMPLETE=NO"; exit 1; }
