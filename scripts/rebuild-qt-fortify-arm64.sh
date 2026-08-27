#!/bin/bash
# =============================================================================
# MaruxOS 2.0.0 "Cooked" — ARM64 Qt 스택 **FORTIFY 재빌드** (함정 #35 픽스)
# -----------------------------------------------------------------------------
# 증상(2026-08-26 실기기 + chroot gdb 동일): qterminal 기동 즉시
#   *** buffer overflow detected ***  → SIGABRT
#   __chk_fail ← __readlink_chk ← qt_readlink ← QLockFilePrivate::processNameByPid
#            ← QLockFile::tryLock ← QSettings::~QSettings ← Properties::migrate_settings
# 원인: Ubuntu 24.04 크로스 gcc(aarch64-linux-gnu-gcc 13.3)는 -O2 이상에서 **암묵적으로
#   -D_FORTIFY_SOURCE=3**을 켠다(실측: `-dM -E`에 #define _FORTIFY_SOURCE 3). FORTIFY 3의
#   동적 객체크기 추정(__builtin_dynamic_object_size)이 Qt 5.15.2 QByteArray의 인라인
#   데이터 포인터(헤더 구조체 + offset)를 오판 → 실제 오버플로가 없는 readlink()를 죽인다.
#   pcmanfm-qt도 종료 시(설정 저장) 같은 지점에서 죽는다.
# 픽스: Qt 스택 전체를 **-D_FORTIFY_SOURCE=2** 로 재빌드(정적 크기 추정만 → 오탐 없음,
#   하드닝은 유지). qtbase 전체 재빌드 실측 5분(32코어)이라 부분 재빌드 안 함.
#   · qmake 계열(qtbase, qtx11extras): mkspec linux-aarch64-gnu-g++/qmake.conf에 플래그 주입
#   · CMake 계열(qtermwidget, qterminal, libfm-qt, pcmanfm-qt): 툴체인 파일 *_FLAGS_INIT
#   · autotools C(libexif, libfm-extra, menu-cache): CFLAGS 명시 (일관성)
# 게이트: 각 단계 Makefile/CMakeCache에 플래그 실존 grep + 끝에 **기동 게이트**(gate-qt-launch)
#   + 통과한 바이너리 SHA를 $B/.q-FORTIFY2-OK 에 기록(이미지 빌드가 대조).
# 실행: nohup setsid (안전패턴 #6) — 로그 $B/qt-fortify-rebuild.log
#   `--gate-only`: [1]~[6] 건너뛰고 [7] 게이트+SHA 기록만 (게이트 스크립트 수정 후 재판정용)
# =============================================================================
set -uo pipefail
B=/home/administrator/MaruxOS-arm64
LFS=$B/rootfs-clfs-arm64
QSRC=$B/qt-src; FSRC=$B/fm-src; QTHOST=$B/qt-host
QTVER=5.15.2; QT=$QSRC/qtbase-everywhere-src-$QTVER
TC=$B/qt-cross-toolchain.cmake
JOBS=${JOBS:-32}
LOG=$B/qt-fortify-rebuild.log
FORT="-D_FORTIFY_SOURCE=2"
SCRIPTS=/mnt/c/Users/Administrator/Desktop/MaruxOS/scripts
MODE="${1:-full}"
[ "$MODE" = "--gate-only" ] || : > "$LOG"
echo "===== Qt FORTIFY 재빌드 시작 ($MODE) $(date) =====" | tee -a "$LOG"

# ---------- 게이트 ----------
[[ "$LFS" == *"MaruxOS-arm64"* ]] || { echo "🚨 ABORT: $LFS"; exit 1; }
[[ "$LFS" == *"/MaruxOS/build"* ]] && { echo "🚨 ABORT: x86_64 디렉토리"; exit 1; }
aarch64-linux-gnu-g++ -dumpmachine | grep -q aarch64 || { echo "🚨 ABORT: 크로스 g++ 아님"; exit 1; }
[ -d "$QT" ] || { echo "🚨 ABORT: qtbase 트리 없음 $QT"; exit 1; }
[ -x "$QTHOST/bin/qmake" ] || { echo "🚨 ABORT: 호스트 qmake 없음"; exit 1; }
[ -f "$B/.q-COMPLETE" ] && [ -f "$B/.f-COMPLETE" ] || { echo "🚨 ABORT: 배치 Q/F 미완 — 이 스크립트는 *재*빌드용"; exit 1; }
# 원인 실증: 컴파일러 기본값이 정말 3인가 (아니면 이 스크립트의 전제가 틀린 것)
DEF=$(echo | aarch64-linux-gnu-gcc -O2 -dM -E - | awk '/_FORTIFY_SOURCE/{print $3}')
echo "  컴파일러 암묵 _FORTIFY_SOURCE = ${DEF:-없음}" | tee -a "$LOG"
[ "${DEF:-}" = 3 ] || echo "  (주의) 기본값이 3이 아님 — 원인 전제 재검토 필요하나 2 강제는 무해하므로 진행" | tee -a "$LOG"
echo | aarch64-linux-gnu-gcc -O2 $FORT -dM -E - | grep -q '_FORTIFY_SOURCE 2' || { echo "🚨 ABORT: $FORT 가 기본값을 덮지 못함"; exit 1; }
HOST_LINGUIST_DIR=$(dirname "$(find /usr/lib -name Qt5LinguistToolsConfig.cmake 2>/dev/null | head -1)")
[ -d "$HOST_LINGUIST_DIR" ] || { echo "🚨 ABORT: 호스트 Qt5LinguistTools 없음"; exit 1; }

export PKG_CONFIG_SYSROOT_DIR="$LFS" PKG_CONFIG_LIBDIR="$LFS/usr/lib/pkgconfig:$LFS/usr/share/pkgconfig" PKG_CONFIG_PATH=""

if [ "$MODE" != "--gate-only" ]; then
# ---------- [1] mkspec 플래그 주입 (멱등, sed 한 줄에 한 행 — \n 이스케이프 함정 #32 회피) ----------
MKS="$QT/mkspecs/linux-aarch64-gnu-g++/qmake.conf"
[ -f "$MKS" ] || { echo "🚨 ABORT: mkspec 없음 $MKS"; exit 1; }
if ! grep -q 'MaruxOS: FORTIFY' "$MKS"; then
  sed -i '/^load(qt_config)/i # MaruxOS: FORTIFY — Ubuntu 크로스 gcc의 암묵 _FORTIFY_SOURCE=3 무력화 (함정 #35, 2026-08-26)' "$MKS"
  sed -i "/^load(qt_config)/i QMAKE_CFLAGS   += $FORT" "$MKS"
  sed -i "/^load(qt_config)/i QMAKE_CXXFLAGS += $FORT" "$MKS"
fi
grep -q "QMAKE_CXXFLAGS += $FORT" "$MKS" || { echo "🚨 ABORT: mkspec 패치 실패"; exit 1; }
echo "[1] mkspec 패치 ✓" | tee -a "$LOG"; tail -5 "$MKS" | tee -a "$LOG"

# ---------- [2] qtbase 재구성 + 재빌드 ----------
echo "===== [2] qtbase clean + configure + make =====" | tee -a "$LOG"
cd "$QT" || exit 1
make clean >> "$LOG" 2>&1 || echo "  (clean 경고 무시)" | tee -a "$LOG"
rm -f .qmake.cache config.cache config.log config.summary
./configure -opensource -confirm-license \
  -xplatform linux-aarch64-gnu-g++ \
  -device-option CROSS_COMPILE=aarch64-linux-gnu- \
  -sysroot "$LFS" \
  -prefix /usr \
  -extprefix "$LFS/usr" \
  -hostprefix "$QTHOST" \
  -release -strip \
  -nomake examples -nomake tests \
  -no-opengl -no-icu -no-cups -no-sql-sqlite \
  -qt-zlib -qt-libpng -qt-libjpeg -qt-pcre -qt-harfbuzz \
  -fontconfig -system-freetype \
  -xcb -xcb-xlib \
  -no-feature-vulkan \
  >> "$LOG" 2>&1 || { echo "🚨 ABORT: qtbase configure 실패"; tail -40 "$LOG"; exit 1; }
grep -q -- "$FORT" src/corelib/Makefile || { echo "🚨 ABORT: corelib Makefile에 $FORT 없음 — 플래그 미주입"; exit 1; }
grep -qE '^\s*xcb\s*\.+ yes' "$LOG" || echo "  (경고) configure 요약에서 xcb yes 확인 불가" | tee -a "$LOG"
echo "  플래그 주입 확인 ✓ (corelib Makefile)" | tee -a "$LOG"
make -j"$JOBS" >> "$LOG" 2>&1 || { echo "🚨 ABORT: qtbase make 실패"; tail -40 "$LOG"; exit 1; }
make install >> "$LOG" 2>&1 || { echo "🚨 ABORT: qtbase install 실패"; tail -20 "$LOG"; exit 1; }
grep -q -- "$FORT" "$QTHOST/mkspecs/linux-aarch64-gnu-g++/qmake.conf" || { echo "🚨 ABORT: 호스트 mkspec에 플래그 미반영"; exit 1; }
echo "  ✓ qtbase 완료 $(date +%H:%M)" | tee -a "$LOG"

# ---------- [3] qtx11extras (host qmake — 새 mkspec 상속) ----------
X11=$QSRC/qtx11extras-everywhere-src-$QTVER
echo "===== [3] qtx11extras =====" | tee -a "$LOG"
cd "$X11" || { echo "🚨 ABORT: x11extras 트리 없음"; exit 1; }
make clean >> "$LOG" 2>&1 || true; rm -f Makefile .qmake.cache
"$QTHOST/bin/qmake" >> "$LOG" 2>&1 || { echo "🚨 ABORT: x11extras qmake 실패"; exit 1; }
grep -rq -- "$FORT" src/x11extras/Makefile 2>/dev/null || grep -rq -- "$FORT" Makefile src/*/Makefile 2>/dev/null || { echo "🚨 ABORT: x11extras Makefile에 플래그 없음"; exit 1; }
make -j"$JOBS" >> "$LOG" 2>&1 && make install >> "$LOG" 2>&1 || { echo "🚨 ABORT: x11extras 빌드 실패"; tail -25 "$LOG"; exit 1; }
echo "  ✓ qtx11extras 완료" | tee -a "$LOG"

# ---------- [4] CMake 툴체인 파일 (플래그 포함) — install-qt5-arm64.sh [3]과 동일 내용 ----------
cat > "$TC" <<TOOLCHAIN
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)
set(CMAKE_SYSROOT $LFS)
set(CMAKE_C_COMPILER aarch64-linux-gnu-gcc)
set(CMAKE_CXX_COMPILER aarch64-linux-gnu-g++)
# MaruxOS: FORTIFY — Ubuntu 크로스 gcc의 암묵 _FORTIFY_SOURCE=3 무력화 (함정 #35)
set(CMAKE_C_FLAGS_INIT "$FORT")
set(CMAKE_CXX_FLAGS_INIT "$FORT")
set(CMAKE_FIND_ROOT_PATH $LFS $LFS/usr)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
set(CMAKE_PREFIX_PATH $LFS/usr)
set(ENV{PKG_CONFIG_SYSROOT_DIR} $LFS)
set(ENV{PKG_CONFIG_LIBDIR} $LFS/usr/lib/pkgconfig:$LFS/usr/share/pkgconfig)
set(CMAKE_INSTALL_PREFIX /usr)
TOOLCHAIN
echo "[4] 툴체인 파일 갱신 ✓" | tee -a "$LOG"

# ---------- [5] CMake 패키지 재빌드 ----------
rebuild_cmake(){   # $1=소스디렉토리 $2=이름 $3...=추가 옵션
  local d="$1" name="$2"; shift 2
  echo "===== [5] $name =====" | tee -a "$LOG"
  cd "$d" || { echo "🚨 ABORT: $name 트리 없음 $d"; exit 1; }
  rm -rf _b && mkdir _b && cd _b
  cmake .. -DCMAKE_TOOLCHAIN_FILE="$TC" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr \
    -DQT_QMAKE_EXECUTABLE="$QTHOST/bin/qmake" -DCMAKE_PREFIX_PATH="$LFS/usr" \
    -DPERL_EXECUTABLE=/usr/bin/perl -DPKG_CONFIG_EXECUTABLE=/usr/bin/pkg-config \
    -DQt5LinguistTools_DIR="$HOST_LINGUIST_DIR" -DBUILD_TESTING=OFF "$@" >> "$LOG" 2>&1 \
    || { echo "🚨 ABORT: $name cmake 실패"; tail -30 "$LOG"; exit 1; }
  grep -q -- "$FORT" CMakeCache.txt || { echo "🚨 ABORT: $name CMakeCache에 플래그 없음"; exit 1; }
  make -j"$JOBS" >> "$LOG" 2>&1 && make install DESTDIR="$LFS" >> "$LOG" 2>&1 \
    || { echo "🚨 ABORT: $name 빌드 실패"; tail -30 "$LOG"; exit 1; }
  echo "  ✓ $name 완료" | tee -a "$LOG"
}
rebuild_cmake "$QSRC/qtermwidget-0.17.0" qtermwidget -DQTERMWIDGET_BUILD_PYTHON_BINDING=OFF
rebuild_cmake "$QSRC/qterminal-0.17.0"   qterminal

# ---------- [6] autotools C 라이브러리 (일관성 — 같은 컴파일러 기본값의 영향권) ----------
rebuild_autotools(){   # $1=디렉토리 $2=이름 $3...=configure 옵션
  local d="$1" name="$2"; shift 2
  echo "===== [6] $name =====" | tee -a "$LOG"
  cd "$d" || { echo "🚨 ABORT: $name 트리 없음"; exit 1; }
  make clean >> "$LOG" 2>&1 || true
  env CC="aarch64-linux-gnu-gcc --sysroot=$LFS" CXX="aarch64-linux-gnu-g++ --sysroot=$LFS" \
      CFLAGS="-O2 -fcommon $FORT" CXXFLAGS="-O2 -fcommon $FORT" \
      ./configure --host=aarch64-linux-gnu --prefix=/usr --disable-static "$@" >> "$LOG" 2>&1 \
    && grep -q -- "$FORT" Makefile \
    && make -j"$JOBS" >> "$LOG" 2>&1 && make install DESTDIR="$LFS" >> "$LOG" 2>&1 \
    || { echo "🚨 ABORT: $name 빌드 실패"; tail -25 "$LOG"; exit 1; }
  echo "  ✓ $name 완료" | tee -a "$LOG"
}
rebuild_autotools "$FSRC/libexif-0.6.24"   libexif    --disable-docs
rebuild_autotools "$FSRC/libfm-1.3.2"      libfm      --with-extra-only --disable-gtk-doc
rebuild_autotools "$FSRC/menu-cache-1.1.0" menu-cache
rebuild_cmake "$FSRC/libfm-qt-0.17.0"   libfm-qt
rebuild_cmake "$FSRC/pcmanfm-qt-0.17.0" pcmanfm-qt

fi   # MODE != --gate-only

# ---------- [7] 산출물 정적 게이트 + **기동 게이트** ----------
echo "===== [7] 게이트 =====" | tee -a "$LOG"
for f in usr/bin/qterminal usr/bin/pcmanfm-qt usr/lib/libQt5Core.so.5.15.2; do
  readelf -h "$LFS/$f" | grep -q AArch64 || { echo "🚨 ABORT: $f 아키텍처 오류"; exit 1; }
done
bash "$SCRIPTS/gate-qt-launch-arm64.sh" 2>&1 | tee -a "$LOG"
[ "${PIPESTATUS[0]}" = 0 ] || { echo "🚨 ABORT: 기동 게이트 실패 — FORTIFY=2로도 안 잡힘, 원인 재검토"; exit 1; }

# 통과한 바이너리의 SHA를 기록 → 이미지 빌드(v28+)가 "게이트 통과본이 그대로 실리는가"를 대조
{ echo "# Qt 스택 FORTIFY=2 재빌드 + 기동 게이트 통과 $(date)"
  for f in usr/lib/libQt5Core.so.5.15.2 usr/bin/qterminal usr/bin/pcmanfm-qt usr/lib/libfm-qt.so.0.17.0; do
    [ -e "$LFS/$f" ] && sha256sum "$LFS/$f" | sed "s|$LFS/||"
  done; } > "$B/.q-FORTIFY2-OK"
echo "===== ✅ Qt FORTIFY 재빌드 완료 $(date) =====" | tee -a "$LOG"; cat "$B/.q-FORTIFY2-OK"
# ⚠️ (2026-08-26 v28 실기기 발각) make install은 config가 배포한 /usr/share/applications/*.desktop 을
#    업스트림 원본으로 덮어쓴다 → 독/데스크톱 아이콘 투명. **이 스크립트 후 setup-desktop-config 최신판 재적용 필수.**
#    이미지 빌드(v29+)가 .desktop 바이트 일치 게이트로 강제한다.
echo "⚠️  make install이 .desktop을 덮어썼을 수 있음 → setup-desktop-config-arm64-v12.sh(최신판) 재적용 후 이미지 빌드" | tee -a "$LOG"
