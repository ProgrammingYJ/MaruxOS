#!/bin/bash
# =============================================================================
# MaruxOS 2.0.0 "Cooked" — ARM64 배치 Q: Qt5 (QTerminal/PCManFM-Qt 기반)
# -----------------------------------------------------------------------------
# ⚠️ 지금까지의 모든 빌드는 qemu-aarch64 chroot 네이티브였으나, Qt는 규모상 그 방식이
#    비현실적이다(qtbase만 10시간+ 추정). → **호스트 크로스 컴파일**로 전환.
#    Qt5는 -xplatform/-sysroot로 크로스를 공식 지원한다.
#      -sysroot    : 우리 rootfs (헤더/라이브러리 탐색 기준)
#      -prefix     : 타겟에서의 경로 (/usr)
#      -extprefix  : 실제 설치 위치 ($LFS/usr)
#      -hostprefix : moc/rcc/uic 등 x86 호스트 도구 (타겟에 안 들어감)
# 의존성은 이미 rootfs에 존재(xcb 12종·xkbcommon·fontconfig·freetype — 사전점검 통과).
# ⚠️ 소스·빌드 트리는 **rootfs 밖**($B/qt-src)에 둔다 — /sources는 이미지에 실려 나가므로
#    Qt 소스(50MB)+빌드산출물(수 GB)이 이미지를 부풀린다. 설치(-extprefix)만 $LFS/usr.
# resumable($B/.q-markers). 완료기준: $B/.q-COMPLETE. 실행: wsl -u root bash <this>
# =============================================================================
set -uo pipefail
B=/home/administrator/MaruxOS-arm64
LFS=$B/rootfs-clfs-arm64
QSRC=$B/qt-src            # 소스·빌드는 rootfs 밖 (이미지에 안 들어감)
QTHOST=$B/qt-host          # 호스트(x86) 도구 — 이미지에 미포함
QTVER=5.15.2
JOBS=${JOBS:-32}
MARKDIR=$B/.q-markers; mkdir -p "$MARKDIR" "$QSRC"
LOG=$B/qt5-build.log

# ---------- CLAUDE.md ARM64 의무 게이트 ----------
[[ "$LFS" == *"MaruxOS-arm64"* ]] || { echo "🚨 ABORT: $LFS"; exit 1; }
[[ "$LFS" == *"/MaruxOS/build"* ]] && { echo "🚨 ABORT: x86_64 디렉토리"; exit 1; }
aarch64-linux-gnu-g++ -dumpmachine | grep -q aarch64 || { echo "🚨 ABORT: 크로스 g++ 아님"; exit 1; }
[ -d "$LFS/usr/include" ] || { echo "🚨 ABORT: sysroot 헤더 없음"; exit 1; }
ls "$LFS"/usr/lib/libxcb.so* >/dev/null 2>&1 || { echo "🚨 ABORT: sysroot에 libxcb 없음"; exit 1; }
ls "$LFS"/usr/lib/libxkbcommon.so* >/dev/null 2>&1 || { echo "🚨 ABORT: sysroot에 libxkbcommon 없음"; exit 1; }

fetch(){ [ -s "$2" ] && { echo "  (캐시) $(basename "$2")"; return 0; }
  echo "[fetch] $(basename "$2")"
  timeout 1200 wget -q -O "$2" "$1" || { rm -f "$2"; echo "🚨 ABORT: fetch 실패 $1"; exit 1; }
  echo "  OK $(ls -lh "$2" | awk '{print $5}')"; }

QTURL="https://download.qt.io/archive/qt/5.15/$QTVER/submodules"

# ---------- [0-pre] libtool .la 절대경로 무력화 (크로스 빌드 필수) ----------
# rootfs의 *.la는 dependency_libs에 '/usr/lib/libXau.la' 같은 **타겟 절대경로**를 담는다.
# 크로스 빌드에서 libtool이 이를 호스트 경로로 해석해 "not a valid libtool archive"로 죽는다.
# Buildroot/Yocto와 동일하게 dependency_libs를 비운다(링크 정보는 pkg-config가 제공).
# 멱등: 이미 비워진 파일은 건드리지 않는다. 런타임에는 .la가 쓰이지 않으므로 영향 없음.
LA_FIXED=0
while IFS= read -r la; do
  grep -q "^dependency_libs=''" "$la" 2>/dev/null && continue
  sed -i "s|^dependency_libs=.*|dependency_libs=''|" "$la" && LA_FIXED=$((LA_FIXED+1))
done < <(find "$LFS/usr/lib" -maxdepth 1 -name '*.la' 2>/dev/null)
echo "[0-pre] libtool .la 정리: $LA_FIXED건" | tee -a "$LOG"

# ---------- [0-pre2] glibc math-vector.h SVE 블록 비활성 ----------
# glibc 2.38의 bits/math-vector.h는 GCC 10+이면 SVE(Scalable Vector Extension) 벡터 수학
# 함수를 선언한다. 그런데 **Pi 4B의 Cortex-A72는 SVE 미지원**이고, 일부 빌드 경로(CMake의
# 컴파일러 검사 등)에서 `__SVFloat64_t`가 해석되지 않아 '__sv_f64_t does not name a type'로
# 죽는다(단독 컴파일은 통과하는 조건부 현상 — 실측 확인). 어차피 이 타겟에서 쓰이지 않는
# 선언이므로 블록 자체를 끈다. 원본은 .orig로 백업.
MVH="$LFS/usr/include/bits/math-vector.h"
if [ -f "$MVH" ] && ! grep -q "MaruxOS: SVE" "$MVH"; then
  cp -n "$MVH" "$MVH.orig"
  sed -i 's|^#if __GNUC_PREREQ(10, 0) .*|#if 0 /* MaruxOS: SVE — Pi4B(Cortex-A72) 미지원이라 비활성 */|' "$MVH"
  grep -q "MaruxOS: SVE" "$MVH" || { echo "🚨 ABORT: math-vector.h SVE 패치 실패"; exit 1; }
  echo "[0-pre2] math-vector.h SVE 블록 비활성 ✓" | tee -a "$LOG"
fi

# ---------- [0] Qt xcb 플러그인 의존성 보강 + 사전 게이트 ----------
# Qt5 xcb 플러그인이 요구하는 시스템 라이브러리 목록(공식 xcb_syslibs 테스트 기준).
# plank/picom 배치에서 xcb-util 계열을 넣었으나 **keysyms만 누락**되어 있었다(v-Q 1차 실패).
QT_XCB_PC="xcb xcb-icccm xcb-image xcb-keysyms xcb-randr xcb-render xcb-renderutil            xcb-shape xcb-shm xcb-sync xcb-xfixes xcb-xinerama xcb-xkb xkbcommon-x11"

pc_missing(){ local m=""; for pc in $QT_XCB_PC; do
    [ -f "$LFS/usr/lib/pkgconfig/$pc.pc" ] || [ -f "$LFS/usr/share/pkgconfig/$pc.pc" ] || m="$m $pc"
  done; echo "$m"; }

MISS=$(pc_missing)
if [ -n "$MISS" ]; then
  echo "[0] xcb 의존성 누락 →$MISS" | tee -a "$LOG"
  for pc in $MISS; do
    case "$pc" in
      xcb-keysyms) KPKG="xcb-util-keysyms-0.4.1"; KURL="https://xcb.freedesktop.org/dist/$KPKG.tar.gz" ;;
      *) echo "🚨 ABORT: 자동 보강 규칙 없는 누락: $pc (수동 조치 필요)"; exit 1 ;;
    esac
    fetch "$KURL" "$QSRC/$KPKG.tar.gz"
    cd "$QSRC" && rm -rf "$KPKG" && tar xf "$KPKG.tar.gz" && cd "$KPKG" || { echo "🚨 ABORT: $KPKG 전개"; exit 1; }
    # 작은 autotools 라이브러리는 크로스가 qemu보다 훨씬 빠르다
    # ⚠️ --host= 만으로는 sysroot가 안 잡힌다. rootfs의 libc.so는 링커 스크립트로
    #    '/usr/lib/libc.so.6' 절대경로를 담아, sysroot 없이는 ld가 호스트 경로로 해석해
    #    "cannot find /usr/lib/libc.so.6"로 죽는다 → CC/CXX에 --sysroot 명시.
    env PKG_CONFIG_SYSROOT_DIR="$LFS" PKG_CONFIG_LIBDIR="$LFS/usr/lib/pkgconfig:$LFS/usr/share/pkgconfig" CC="aarch64-linux-gnu-gcc --sysroot=$LFS" CXX="aarch64-linux-gnu-g++ --sysroot=$LFS" ./configure --host=aarch64-linux-gnu --prefix=/usr --disable-static >> "$LOG" 2>&1 && make -j"$JOBS" >> "$LOG" 2>&1 && make install DESTDIR="$LFS" >> "$LOG" 2>&1 || { echo "🚨 ABORT: $KPKG 빌드 실패"; tail -20 "$LOG"; exit 1; }
    echo "  ✓ $KPKG 설치" | tee -a "$LOG"
  done
fi
MISS=$(pc_missing)
[ -z "$MISS" ] || { echo "🚨 ABORT: xcb 의존성 여전히 누락 →$MISS"; exit 1; }
echo "[0] Qt xcb 의존성 14종 확인 ✓" | tee -a "$LOG"

# ---------- [1] qtbase ----------
if [ ! -f "$MARKDIR/qtbase" ]; then
  echo "===== [1] qtbase $QTVER 크로스 빌드 =====" | tee "$LOG"
  fetch "$QTURL/qtbase-everywhere-src-$QTVER.tar.xz" "$QSRC/qtbase-everywhere-src-$QTVER.tar.xz"
  # 이미 전개된 트리가 있으면 재사용 — 재전개하면 빌드 산출물(수십 분)이 날아간다.
  # 패치는 모두 멱등이므로 재적용해도 안전.
  if [ ! -d "$QSRC/qtbase-everywhere-src-$QTVER" ]; then
    cd "$QSRC" && tar xf "qtbase-everywhere-src-$QTVER.tar.xz" || { echo "🚨 ABORT: qtbase 전개 실패"; exit 1; }
  else
    echo "  (재사용) 기존 qtbase 트리 — 증분 빌드" | tee -a "$LOG"
  fi
  cd "$QSRC/qtbase-everywhere-src-$QTVER" || { echo "🚨 ABORT: qtbase 디렉토리 없음"; exit 1; }

  # ── Qt 5.15.2 + GCC 11+ 비호환 패치 (<limits> 누락) ──────────────────────────
  # GCC 11부터 <limits>가 다른 헤더에 전이 포함되지 않는다. Qt 5.15.2(2020, GCC 9 시절)는
  # 이를 전제해 std::numeric_limits를 직접 include 없이 쓴다 → "numeric_limits is not a
  # class template"로 전량 실패. 5.15.3+는 수정됐으나 그때부터 상업 라이선스라 오픈소스
  # tarball이 없다. 업스트림 커밋과 동일하게 각 헤더에 #include <limits>를 주입한다.
  for hf in src/corelib/global/qfloat16.h             src/corelib/global/qendian.h             src/corelib/text/qbytearraymatcher.h             src/corelib/tools/qoffsetstringarray_p.h             src/corelib/kernel/qmetatype.h             src/gui/painting/qdrawhelper_p.h             src/gui/kernel/qguiapplication.cpp; do
    [ -f "$hf" ] || continue
    grep -q "^#include <limits>" "$hf" && continue
    # <limits>는 자체 include guard가 있어 파일 최상단 삽입이 안전 (개행 이스케이프 회피)
    sed -i '1i #include <limits>' "$hf"
  done
  PATCHED=$(grep -l "^#include <limits>" src/corelib/global/qfloat16.h src/corelib/global/qendian.h 2>/dev/null | wc -l)
  [ "$PATCHED" -ge 2 ] || { echo "🚨 ABORT: <limits> 패치 실패($PATCHED/2)"; exit 1; }
  echo "  ✓ <limits> 패치 적용 (GCC 11+ 호환)" | tee -a "$LOG"

  # ── xkbcommon keysym 보강 (rootfs의 libxkbcommon이 Qt 5.15보다 구버전) ──────────
  # Qt 5.15의 qxkbcommon.cpp는 libxkbcommon 0.8.0(2017)에서 추가된 데드키 심볼을 쓴다.
  # 우리 rootfs 버전엔 없어 "XKB_KEY_dead_lowline was not declared"로 실패.
  # 라이브러리를 올리면 X.org/GTK까지 파급되므로, X11 keysymdef.h의 **고정 표준값**만
  # 정의해 준다(동일 값 재정의는 C 표준상 무해). cat 합성 = 개행 이스케이프 회피(함정 #32).
  XKBCPP=src/platformsupport/input/xkbcommon/qxkbcommon.cpp
  if [ -f "$XKBCPP" ] && ! grep -q "MaruxOS xkb keysym" "$XKBCPP"; then
    cat > "$QSRC/xkbfix.h" <<'XKBFIX'
/* MaruxOS xkb keysym 보강 — X11 keysymdef.h 표준값 */
#ifndef XKB_KEY_dead_lowline
#define XKB_KEY_dead_lowline 0xfe90
#endif
#ifndef XKB_KEY_dead_aboveverticalline
#define XKB_KEY_dead_aboveverticalline 0xfe91
#endif
#ifndef XKB_KEY_dead_belowverticalline
#define XKB_KEY_dead_belowverticalline 0xfe92
#endif
#ifndef XKB_KEY_dead_longsolidusoverlay
#define XKB_KEY_dead_longsolidusoverlay 0xfe93
#endif
XKBFIX
    cat "$QSRC/xkbfix.h" "$XKBCPP" > "$QSRC/.x.tmp" && mv "$QSRC/.x.tmp" "$XKBCPP"
    grep -q "MaruxOS xkb keysym" "$XKBCPP" || { echo "🚨 ABORT: xkb keysym 패치 실패"; exit 1; }
    echo "  ✓ xkb keysym 4종 보강" | tee -a "$LOG"
  fi


  # sysroot의 pkg-config를 보도록 (호스트 .pc가 섞이면 x86 라이브러리를 잡는다)
  export PKG_CONFIG_SYSROOT_DIR="$LFS"
  export PKG_CONFIG_LIBDIR="$LFS/usr/lib/pkgconfig:$LFS/usr/share/pkgconfig"
  export PKG_CONFIG_PATH=""

  # [1-pre] mkspec FORTIFY 주입 (함정 #35, 2026-08-26): Ubuntu 크로스 gcc는 -O2에서 암묵적으로
  # -D_FORTIFY_SOURCE=3을 켜고, 그 동적 크기 추정이 Qt 5.15.2 QByteArray 인라인 데이터를 오판해
  # qt_readlink()의 readlink를 "buffer overflow"로 죽인다(qterminal 즉사·pcmanfm-qt 종료 시 사망).
  # 2로 고정(정적 추정만 → 오탐 없음). 재빌드 절차는 rebuild-qt-fortify-arm64.sh 참조.
  # (sed 한 줄에 한 행 — \n 이스케이프 함정 #32 회피)
  MKS="mkspecs/linux-aarch64-gnu-g++/qmake.conf"
  if ! grep -q 'MaruxOS: FORTIFY' "$MKS"; then
    sed -i '/^load(qt_config)/i # MaruxOS: FORTIFY — Ubuntu 크로스 gcc의 암묵 _FORTIFY_SOURCE=3 무력화 (함정 #35, 2026-08-26)' "$MKS"
    sed -i '/^load(qt_config)/i QMAKE_CFLAGS   += -D_FORTIFY_SOURCE=2' "$MKS"
    sed -i '/^load(qt_config)/i QMAKE_CXXFLAGS += -D_FORTIFY_SOURCE=2' "$MKS"
  fi
  grep -q 'QMAKE_CXXFLAGS += -D_FORTIFY_SOURCE=2' "$MKS" || { echo "🚨 ABORT: mkspec FORTIFY 패치 실패"; exit 1; }
  echo "  ✓ mkspec FORTIFY=2 주입" | tee -a "$LOG"

  if [ -f Makefile ] && [ -f .qmake.cache ]; then
    echo "  (재사용) 기존 configure 결과 — make만 재개" | tee -a "$LOG"
  else
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
    >> "$LOG" 2>&1
  rc=$?
  [ $rc -ne 0 ] && { echo "🚨 ABORT: qtbase configure 실패(rc=$rc)"; tail -40 "$LOG"; exit 1; }
  # configure 결과 게이트: xcb 플러그인이 켜졌는가 (없으면 GUI가 안 뜬다)
  grep -qE "^\s*xcb\s*\.+ yes|QPA backends:" "$LOG" || echo "  (경고) configure 요약에서 xcb 확인 불가 — 로그 확인 필요"
  fi

  make -j"$JOBS" >> "$LOG" 2>&1 || { echo "🚨 ABORT: qtbase make 실패"; tail -40 "$LOG"; exit 1; }
  make install >> "$LOG" 2>&1 || { echo "🚨 ABORT: qtbase install 실패"; tail -20 "$LOG"; exit 1; }
  touch "$MARKDIR/qtbase"
  echo "===== qtbase 완료 ====="
else echo "SKIP qtbase"; fi

# ---------- [2] Qt 애드온 모듈 (qmake 기반 — qtbase 설정을 그대로 상속) ----------
# 호스트 qmake($QTHOST/bin/qmake)가 sysroot·크로스 정보를 이미 담고 있어 추가 설정이 없다.
build_qt_module(){   # $1 = 모듈명 (예: qtx11extras)
  local m="$1"
  [ -f "$MARKDIR/$m" ] && { echo "SKIP $m"; return 0; }
  echo "===== [2] $m 크로스 빌드 =====" | tee -a "$LOG"
  fetch "$QTURL/$m-everywhere-src-$QTVER.tar.xz" "$QSRC/$m-everywhere-src-$QTVER.tar.xz"
  [ -d "$QSRC/$m-everywhere-src-$QTVER" ] || { cd "$QSRC" && tar xf "$m-everywhere-src-$QTVER.tar.xz"; }
  cd "$QSRC/$m-everywhere-src-$QTVER" || { echo "🚨 ABORT: $m 디렉토리"; exit 1; }
  if [ ! -f Makefile ]; then
    "$QTHOST/bin/qmake" >> "$LOG" 2>&1 || { echo "🚨 ABORT: $m qmake 실패"; tail -20 "$LOG"; exit 1; }
  fi
  make -j"$JOBS" >> "$LOG" 2>&1 || { echo "🚨 ABORT: $m make 실패"; tail -25 "$LOG"; exit 1; }
  make install >> "$LOG" 2>&1 || { echo "🚨 ABORT: $m install 실패"; tail -15 "$LOG"; exit 1; }
  touch "$MARKDIR/$m"; echo "  ✓ $m 완료" | tee -a "$LOG"
}

build_qt_module qtx11extras     # qterminal이 요구
# qttools는 **빌드하지 않는다**.
#   이유: qttools는 lrelease/lupdate 같은 **호스트(x86) 도구**도 함께 빌드하는데, 그 과정에서
#   aarch64 sysroot 헤더(bits/math-vector.h)를 x86 컴파일러가 읽어 '__Float32x4_t does not
#   name a type'로 실패한다(ARM 전용 벡터 타입). 컴파일러·헤더 자체는 정상임을 실측 확인:
#     · C++ + <cmath> 크로스 컴파일 ✅   · __Float32x4_t 단독 사용 ✅
#   용도가 번역 파일(.ts→.qm) 컴파일뿐이라 생략해도 기능 영향이 없다(UI 영문 표기).
#   ⇒ 아래 CMake 패키지들은 번역 비활성으로 빌드한다.

# lrelease는 **호스트에서 실행**되어야 한다(크로스 산출물은 aarch64라 실행 불가).
# qttools 빌드 시 호스트 도구도 $QTHOST/bin에 생성되는지 확인.
if [ ! -x "$QTHOST/bin/lrelease" ]; then
  echo "  (주의) 호스트 lrelease 없음 — 번역 비활성 옵션으로 우회 예정" | tee -a "$LOG"
fi

# ---------- [3] CMake 크로스 툴체인 파일 생성 ----------
# qtermwidget·qterminal은 qmake가 아니라 **CMake**를 쓴다. CMake는 sysroot·컴파일러·
# 탐색규칙을 툴체인 파일로 받으므로 별도 작성이 필요하다(qtbase 설정은 상속되지 않는다).
#   FIND_ROOT_PATH_MODE_PROGRAM=NEVER  : 실행파일은 호스트에서 찾는다(moc/lrelease)
#   ...LIBRARY/INCLUDE=ONLY            : 라이브러리·헤더는 sysroot에서만 찾는다
#   (이 분리가 없으면 x86 라이브러리를 링크하거나 aarch64 도구를 실행하려다 실패한다)
TC="$B/qt-cross-toolchain.cmake"
cat > "$TC" <<TOOLCHAIN
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)
set(CMAKE_SYSROOT $LFS)
set(CMAKE_C_COMPILER aarch64-linux-gnu-gcc)
set(CMAKE_CXX_COMPILER aarch64-linux-gnu-g++)
# MaruxOS: FORTIFY — Ubuntu 크로스 gcc의 암묵 _FORTIFY_SOURCE=3 무력화 (함정 #35, 2026-08-26)
set(CMAKE_C_FLAGS_INIT "-D_FORTIFY_SOURCE=2")
set(CMAKE_CXX_FLAGS_INIT "-D_FORTIFY_SOURCE=2")
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
[ -s "$TC" ] || { echo "🚨 ABORT: CMake 툴체인 파일 생성 실패"; exit 1; }
echo "[3] CMake 크로스 툴체인 준비 ✓ ($TC)" | tee -a "$LOG"

# ---------- [4] QTerminal 사슬 (CMake) ----------
# qtermwidget(터미널 위젯) → qterminal(앱). 둘 다 CMake + lxqt 계열 관례를 따른다.
# 번역(lrelease)은 호스트 도구가 필요한데 크로스 산출물은 aarch64라 실행 불가 →
# 번역 비활성 옵션으로 우회한다(기능에는 영향 없음, UI는 영문).
# 호스트(x86) Qt5LinguistTools — lrelease는 **빌드 호스트에서 실행**되어야 하므로 타겟이 아닌
# 호스트 것을 쓴다(크로스 산출물은 aarch64라 실행 불가). CMAKE_FIND_ROOT_PATH 규칙을 우회해
# 이 패키지만 명시 경로로 지정한다.
HOST_LINGUIST_DIR=$(dirname "$(find /usr/lib -name Qt5LinguistToolsConfig.cmake 2>/dev/null | head -1)")
[ -n "$HOST_LINGUIST_DIR" ] && [ -d "$HOST_LINGUIST_DIR" ] || { echo "🚨 ABORT: 호스트 Qt5LinguistTools 없음 (apt install qttools5-dev)"; exit 1; }
echo "[4] 호스트 LinguistTools: $HOST_LINGUIST_DIR" | tee -a "$LOG"

QTW_VER=${QTW_VER:-0.17.0}
QTERM_VER=${QTERM_VER:-0.17.0}

build_cmake_pkg(){   # $1=이름 $2=버전 $3=tarball URL $4... = 추가 cmake 옵션
  local name="$1" ver="$2" url="$3"; shift 3
  [ -f "$MARKDIR/$name" ] && { echo "SKIP $name"; return 0; }
  echo "===== [4] $name $ver 크로스 빌드 (CMake) =====" | tee -a "$LOG"
  fetch "$url" "$QSRC/$name-$ver.tar.gz"
  [ -d "$QSRC/$name-$ver" ] || { cd "$QSRC" && tar xf "$name-$ver.tar.gz"; }
  cd "$QSRC/$name-$ver" || { echo "🚨 ABORT: $name 디렉토리"; exit 1; }
  patch_linguist "$QSRC/$name-$ver"
  rm -rf _b && mkdir _b && cd _b
  cmake .. -DCMAKE_TOOLCHAIN_FILE="$TC"            -DCMAKE_BUILD_TYPE=Release            -DCMAKE_INSTALL_PREFIX=/usr            -DQT_QMAKE_EXECUTABLE="$QTHOST/bin/qmake"            -DCMAKE_PREFIX_PATH="$LFS/usr" -DPERL_EXECUTABLE=/usr/bin/perl            "$@" >> "$LOG" 2>&1 || { echo "🚨 ABORT: $name cmake 실패"; tail -30 "$LOG"; exit 1; }
  make -j"$JOBS" >> "$LOG" 2>&1 || { echo "🚨 ABORT: $name make 실패"; tail -30 "$LOG"; exit 1; }
  make install DESTDIR="$LFS" >> "$LOG" 2>&1 || { echo "🚨 ABORT: $name install 실패"; tail -15 "$LOG"; exit 1; }
  touch "$MARKDIR/$name"; echo "  ✓ $name 완료" | tee -a "$LOG"
}

# qtermwidget은 find_package(Qt5LinguistTools REQUIRED)로 번역 도구를 강제한다.
# qttools를 빌드하지 않으므로(호스트/타겟 헤더 혼선) 해당 요구를 선택적으로 낮춘다.
patch_linguist(){   # $1 = 소스 디렉토리
  local d="$1"
  [ -f "$d/CMakeLists.txt" ] || return 0
  grep -q "MaruxOS: LinguistTools" "$d/CMakeLists.txt" && return 0
  sed -i 's|find_package(Qt5LinguistTools|# MaruxOS: LinguistTools 선택화(qttools 미빌드)
  find_package(Qt5LinguistTools QUIET) # |' "$d/CMakeLists.txt" 2>/dev/null || true
}

# lxqt-build-tools: qtermwidget/qterminal이 요구하는 **CMake 매크로 모음**(lxqt_translate_ts 등).
# 아키텍처 무관한 .cmake 파일만 설치하므로 크로스 이슈가 없다 → sysroot에 그대로 설치.
LBT_VER=${LBT_VER:-0.13.0}
if [ ! -f "$MARKDIR/lxqt-build-tools" ]; then
  echo "===== [4] lxqt-build-tools $LBT_VER =====" | tee -a "$LOG"
  fetch "https://github.com/lxqt/lxqt-build-tools/releases/download/$LBT_VER/lxqt-build-tools-$LBT_VER.tar.xz"         "$QSRC/lxqt-build-tools-$LBT_VER.tar.gz"
  [ -d "$QSRC/lxqt-build-tools-$LBT_VER" ] || { cd "$QSRC" && tar xf "lxqt-build-tools-$LBT_VER.tar.gz"; }
  cd "$QSRC/lxqt-build-tools-$LBT_VER" || { echo "🚨 ABORT: lxqt-build-tools 전개"; exit 1; }
  rm -rf _b && mkdir _b && cd _b
  cmake .. -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release     -DQt5LinguistTools_DIR="$HOST_LINGUIST_DIR" >> "$LOG" 2>&1     || { echo "🚨 ABORT: lxqt-build-tools cmake 실패"; tail -20 "$LOG"; exit 1; }
  make install DESTDIR="$LFS" >> "$LOG" 2>&1     || { echo "🚨 ABORT: lxqt-build-tools install 실패"; tail -15 "$LOG"; exit 1; }
  touch "$MARKDIR/lxqt-build-tools"; echo "  ✓ lxqt-build-tools 완료" | tee -a "$LOG"
fi

build_cmake_pkg qtermwidget "$QTW_VER"   "https://github.com/lxqt/qtermwidget/releases/download/$QTW_VER/qtermwidget-$QTW_VER.tar.xz"   -DBUILD_TESTING=OFF -DQTERMWIDGET_BUILD_PYTHON_BINDING=OFF -DQt5LinguistTools_DIR="$HOST_LINGUIST_DIR"

build_cmake_pkg qterminal "$QTERM_VER"   "https://github.com/lxqt/qterminal/releases/download/$QTERM_VER/qterminal-$QTERM_VER.tar.xz"   -DBUILD_TESTING=OFF -DQt5LinguistTools_DIR="$HOST_LINGUIST_DIR"

# ---------- [2] 산출물 게이트 ----------
echo "===== 검증 ====="
ok=1
for f in "$LFS/usr/lib/libQt5Core.so" "$LFS/usr/lib/libQt5Gui.so" "$LFS/usr/lib/libQt5Widgets.so"; do
  [ -e "$f" ] && echo "  ✅ $(basename "$f")" || { echo "  ❌ $(basename "$f")"; ok=0; }
done
[ -e "$LFS/usr/plugins/platforms/libqxcb.so" ] || [ -e "$LFS/usr/lib/qt5/plugins/platforms/libqxcb.so" ] \
  && echo "  ✅ xcb 플랫폼 플러그인" || { echo "  ❌ xcb 플랫폼 플러그인(GUI 불가)"; ok=0; }
[ -x "$QTHOST/bin/moc" ] && echo "  ✅ 호스트 moc" || { echo "  ❌ 호스트 moc"; ok=0; }
[ -e "$LFS/usr/lib/libQt5X11Extras.so" ] && echo "  ✅ Qt5X11Extras" || echo "  ⚠️ Qt5X11Extras 미설치(qterminal 필요)"
[ -x "$LFS/usr/bin/qterminal" ] && { echo "  ✅ qterminal"; readelf -h "$LFS/usr/bin/qterminal" | grep -q AArch64 && echo "  ✅ qterminal AArch64" || { echo "  🚨 qterminal 아키텍처 오류"; ok=0; }; } || echo "  ⏳ qterminal 미빌드"
# 아키텍처 확인 — 크로스가 아니라 x86을 만들었으면 즉시 발각
if [ -e "$LFS/usr/lib/libQt5Core.so" ]; then
  readelf -h "$LFS/usr/lib/libQt5Core.so" | grep -q AArch64 && echo "  ✅ AArch64 ELF" || { echo "  🚨 libQt5Core가 AArch64가 아님"; ok=0; }
fi
# 존재 검사 ≠ 기동 검사 (2026-08-26 교훈): 실제 chroot 기동 게이트. pcmanfm-qt가 없으면(배치 F 전) 건너뜀.
if [ -x "$LFS/usr/bin/pcmanfm-qt" ]; then
  bash "$(dirname "$0")/gate-qt-launch-arm64.sh" || { echo "🚨 ABORT: Qt 기동 게이트 실패"; ok=0; }
else echo "  (기동 게이트는 배치 F 후 install-pcmanfm-qt-arm64.sh 에서 실행)"; fi
[ "$ok" = 1 ] && { touch "$B/.q-COMPLETE"; echo "QT5_BASE_COMPLETE=YES"; } || { echo "QT5_BASE_COMPLETE=NO"; exit 1; }
