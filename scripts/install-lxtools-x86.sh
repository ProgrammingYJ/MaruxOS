#!/bin/bash
# =============================================================================
# ⚠️ x86_64 변환본 (2026-08-28, "ISO도 img처럼" — x86 데스크톱 패리티)
#   원본 = ARM64 스크립트(같은 이름 -arm64.sh)를 gen(mk-x86-scripts.py)으로 자동 변환:
#   · 빌드 루트 $B = /home/administrator/MaruxOS/x86-parity, sysroot = rootfs-lfs-parity (x86 rootfs 사본)
#   · 크로스 접두어 x86_64-linux-gnu-* = $B/bin 래퍼 → 호스트 **gcc-13**(rootfs libstdc++ 13.2와 ABI 일치; 14는 GLIBCXX_3.4.33 요구)
#   · Qt mkspec linux-g++-64 / CMake SYSTEM_PROCESSOR x86_64 / readelf 게이트 X86-64
#   · glibc SVE 헤더 패치(ARM 전용)는 비활성
#   ARM64 원본의 주석은 그대로 두었다 — "aarch64"라 적힌 설명은 원본 맥락이다.
# =============================================================================
# =============================================================================
# MaruxOS 2.0.0 "Cooked" — ARM64 배치 T: 데스크톱 툴 4종 (LXImage-Qt · SpeedCrunch · LXQt Archiver · qps)
# -----------------------------------------------------------------------------
# 요청(2026-08-27 출품 당일): "LXImage-Qt, SpeedCrunch, LXQt Archiver, qps 넣자 다".
# 전부 Qt5 CMake 크로스 — 배치 Q/F/E의 체계(툴체인 파일 FORTIFY=2, 호스트 도구 명시, LinguistTools) 재사용.
#   · LXImage-Qt 0.17.0  : 이미지 뷰어 + 스크린샷 (libfm-qt·libexif·Qt5Svg ✓ 기존)
#   · SpeedCrunch 0.12.0 : 계산기 (Qt5만; 소스 루트 = src/)
#   · LXQt Archiver 0.2.0: 압축 관리자 (libfm-qt + **json-glib** 필요 → 없으면 meson 크로스로 추가)
#                          zip 백엔드 unzip/zip(Info-ZIP)은 **비치명**(실패해도 tar.* 는 동작)
#   · qps 1.10.20        : GUI 작업관리자 (Qt5 + lxqt-build-tools ✓; 2.x는 liblxqt 요구라 제외)
# 마커 $B/.t-markers, 완료 $B/.t-COMPLETE. 각 툴은 독립 마커라 하나가 벽에 막히면 그것만 빼고 갈 수 있다
#   (환경변수 SKIP_ARCHIVER=1 등으로 제외).
# ⚠️ make install 후 config 재적용 필수(함정 #36 — .desktop 덮어씀). 실행: wsl -u root bash <this>
# =============================================================================
set -uo pipefail
B=/home/administrator/MaruxOS/x86-parity
export PATH="$B/bin:$PATH"   # gcc-13 래퍼 접두어
LFS=$B/rootfs-lfs-parity
TSRC=$B/tools-src; QTHOST=$B/qt-host
TC=$B/qt-cross-toolchain.cmake
JOBS=${JOBS:-32}
MARKDIR=$B/.t-markers; mkdir -p "$MARKDIR" "$TSRC"
LOG=$B/lxtools-build.log
SCRIPTS=/mnt/c/Users/Administrator/Desktop/MaruxOS/scripts
FORT="-D_FORTIFY_SOURCE=2"

# ---------- 게이트 ----------
[[ "$LFS" == *"x86-parity"* ]] || { echo "🚨 ABORT: $LFS"; exit 1; }
[ -f "$B/.q-FORTIFY2-OK" ] && [ -f "$B/.f-COMPLETE" ] && [ -f "$B/.e-COMPLETE" ] || { echo "🚨 ABORT: 배치 Q/F/E 미완"; exit 1; }
grep -q FORTIFY "$TC" || { echo "🚨 ABORT: CMake 툴체인에 FORTIFY 없음"; exit 1; }
[ -x "$QTHOST/bin/qmake" ] || { echo "🚨 ABORT: 호스트 qmake 없음"; exit 1; }
ls "$LFS/usr/lib/libfm-qt.so"* >/dev/null 2>&1 || { echo "🚨 ABORT: libfm-qt 없음"; exit 1; }
ls "$LFS/usr/lib/libQt5Svg.so.5"* >/dev/null 2>&1 || { echo "🚨 ABORT: libQt5Svg 없음"; exit 1; }
x86_64-linux-gnu-g++ -dumpmachine | grep -q x86_64 || { echo "🚨 ABORT: 크로스 g++ 아님"; exit 1; }
HOST_LINGUIST_DIR=$(dirname "$(find /usr/lib -name Qt5LinguistToolsConfig.cmake 2>/dev/null | head -1)")
[ -d "$HOST_LINGUIST_DIR" ] || { echo "🚨 ABORT: 호스트 Qt5LinguistTools 없음"; exit 1; }
export PKG_CONFIG_SYSROOT_DIR="$LFS" PKG_CONFIG_LIBDIR="$LFS/usr/lib/pkgconfig:$LFS/usr/lib64/pkgconfig:$LFS/usr/share/pkgconfig" PKG_CONFIG_PATH=""
echo "===== 배치 T 시작 $(date) =====" | tee -a "$LOG"

fetch(){ [ -s "$2" ] && { echo "  (캐시) $(basename "$2")"; return 0; }
  echo "[fetch] $(basename "$2")"
  timeout 900 wget -q -O "$2" "$1" || { rm -f "$2"; return 1; }
  echo "  OK $(ls -lh "$2" | awk '{print $5}')"; }

# CMake 크로스 빌드 공통 — $1=마커명 $2=소스디렉토리 $3=CMakeLists 상대경로(보통 .) $4...=추가 옵션
build_cmake(){
  local name="$1" d="$2" sub="$3"; shift 3
  [ -f "$MARKDIR/$name" ] && { echo "SKIP $name"; return 0; }
  echo "===== $name (CMake 크로스) =====" | tee -a "$LOG"
  cd "$d" || { echo "🚨 ABORT: $name 디렉토리 $d"; return 1; }
  rm -rf _b && mkdir _b && cd _b
  cmake "../$sub" -DCMAKE_TOOLCHAIN_FILE="$TC" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr \
    -DQT_QMAKE_EXECUTABLE="$QTHOST/bin/qmake" -DCMAKE_PREFIX_PATH="$LFS/usr" \
    -DPERL_EXECUTABLE=/usr/bin/perl -DPKG_CONFIG_EXECUTABLE=/usr/bin/pkg-config \
    -DQt5LinguistTools_DIR="$HOST_LINGUIST_DIR" -DBUILD_TESTING=OFF "$@" >> "$LOG" 2>&1 \
    || { echo "🚨 $name cmake 실패"; tail -30 "$LOG"; return 1; }
  grep -q -- "$FORT" CMakeCache.txt || { echo "🚨 $name CMakeCache에 FORTIFY=2 없음"; return 1; }
  make -j"$JOBS" >> "$LOG" 2>&1 && make install DESTDIR="$LFS" >> "$LOG" 2>&1 \
    || { echo "🚨 $name 빌드 실패"; tail -30 "$LOG"; return 1; }
  touch "$MARKDIR/$name"; echo "  ✓ $name 완료" | tee -a "$LOG"
}

# ---------- [1] SpeedCrunch 0.12.0 (소스 루트 = src/) ----------
if [ -z "${SKIP_CALC:-}" ]; then
  V=0.12.0
  fetch "http://deb.debian.org/debian/pool/main/s/speedcrunch/speedcrunch_$V.orig.tar.gz" "$TSRC/speedcrunch-$V.tar.gz" \
    || fetch "https://bitbucket.org/heldercorreia/speedcrunch/get/release-$V.tar.gz" "$TSRC/speedcrunch-$V.tar.gz" \
    || { echo "🚨 ABORT: speedcrunch fetch"; exit 1; }
  if [ ! -d "$TSRC/speedcrunch-$V" ]; then mkdir -p "$TSRC/speedcrunch-$V" && tar xf "$TSRC/speedcrunch-$V.tar.gz" -C "$TSRC/speedcrunch-$V" --strip-components=1; fi
  SUB=. ; [ -f "$TSRC/speedcrunch-$V/src/CMakeLists.txt" ] && SUB=src
  # 0.12.0은 QtHelp를 **헤더까지** 쓴다(core/manualserver.cpp `#include <QtHelp/QHelpEngineCore>` — 2차 발사에서 실측;
  # 1차는 -j32 병렬이라 그 파일 전에 테스트 링크가 먼저 터져 "헤더 미사용"으로 오판했었다). 링크 제거 패치는 되돌린다.
  SCM="$TSRC/speedcrunch-$V/$SUB/CMakeLists.txt"
  sed -i 's|^set(QT_LIBRARIES Qt5::Widgets) # MaruxOS: Qt5Help 제거.*$|set(QT_LIBRARIES Qt5::Widgets Qt5::Help)|' "$SCM"
  grep -q '^set(QT_LIBRARIES Qt5::Widgets Qt5::Help)$' "$SCM" || { echo "🚨 ABORT: speedcrunch CMakeLists 원상복구 실패"; exit 1; }
  # [1a] QtHelp — qttools 전체는 호스트 도구가 타겟 헤더를 읽어 실패(함정 #34-9)했지만, **src/assistant/help 모듈만**은
  #      순수 타겟 라이브러리(Core/Gui/Widgets/Sql)라 호스트 qmake로 단독 크로스 빌드 가능. (매뉴얼 창은 sqlite 드라이버가
  #      없어 런타임에 비어 보일 수 있음 — 계산기 본기능과 무관.)
  if ! ls "$LFS/usr/lib/libQt5Help.so.5"* >/dev/null 2>&1; then
    echo "===== [1a] QtHelp (qttools/src/assistant/help 단독) =====" | tee -a "$LOG"
    QTV=5.15.2
    fetch "https://download.qt.io/archive/qt/5.15/$QTV/submodules/qttools-everywhere-src-$QTV.tar.xz" "$B/qt-src/qttools-everywhere-src-$QTV.tar.xz" || { echo "🚨 ABORT: qttools fetch"; exit 1; }
    [ -d "$B/qt-src/qttools-everywhere-src-$QTV" ] || tar xf "$B/qt-src/qttools-everywhere-src-$QTV.tar.xz" -C "$B/qt-src"
    cd "$B/qt-src/qttools-everywhere-src-$QTV/src/assistant/help" || { echo "🚨 ABORT: qttools help 디렉토리"; exit 1; }
    # PCH: 크로스에서 "one or more PCH files were found, but they were invalid"(1차 발사) → 사전컴파일 헤더 비활성
    rm -rf Makefile .pch .obj .moc; "$QTHOST/bin/qmake" CONFIG-=precompile_header >> "$LOG" 2>&1 || { echo "🚨 ABORT: qthelp qmake 실패"; tail -20 "$LOG"; exit 1; }
    make -j"$JOBS" >> "$LOG" 2>&1 && make install >> "$LOG" 2>&1 || { echo "🚨 ABORT: qthelp 빌드 실패"; tail -30 "$LOG"; exit 1; }
    ls "$LFS/usr/lib/libQt5Help.so.5"* >/dev/null 2>&1 && [ -d "$LFS/usr/lib/cmake/Qt5Help" ] || { echo "🚨 ABORT: libQt5Help/cmake 미설치"; ls "$LFS/usr/lib/cmake" | grep -i help; exit 1; }
    grep -rq -- "$FORT" --include=Makefile . || { echo "🚨 ABORT: qthelp Makefile에 FORTIFY=2 없음"; exit 1; }
    echo "  ✓ QtHelp 완료" | tee -a "$LOG"
  else echo "  QtHelp 이미 있음"; fi
  # Qt5HelpConfigExtras.cmake는 호스트 도구 qhelpgenerator/qcollectiongenerator(미빌드)의 실존을 검사해 find_package를
  # 실패시킨다(2차 발사 실측). 매뉴얼 재생성(REBUILD_MANUAL=FALSE)에만 쓰이므로 검사 줄만 제거(멱등, 가짜 바이너리 안 만듦).
  QHX="$LFS/usr/lib/cmake/Qt5Help/Qt5HelpConfigExtras.cmake"
  [ -f "$QHX" ] && sed -i '/_qt5_Help_check_file_exists(${imported_location})/d' "$QHX"
  grep -q '_qt5_Help_check_file_exists(${imported_location})' "$QHX" 2>/dev/null && { echo "🚨 ABORT: Qt5HelpConfigExtras 패치 실패"; exit 1; }
  build_cmake speedcrunch "$TSRC/speedcrunch-$V" "$SUB" || { echo "🚨 ABORT: speedcrunch"; exit 1; }
fi

# ---------- [2] qps 1.10.20 ----------
# 2.3.0(LXQt 0.17 시대)은 find_package(lxqt 0.17.0) = **liblxqt** 요구(→ libqtxdg·KF5WindowSystem 사슬) — 3차 발사 실측.
# liblxqt 의존이 생기기 전 마지막 계열 1.10.20(2018)로 내림: Qt5 Widgets/X11Extras + lxqt-build-tools만.
if [ -z "${SKIP_QPS:-}" ]; then
  V=${QPS_VER:-1.10.20}
  fetch "https://github.com/lxqt/qps/releases/download/$V/qps-$V.tar.xz" "$TSRC/qps-$V.tar.xz" || { echo "🚨 ABORT: qps fetch"; exit 1; }
  [ -d "$TSRC/qps-$V" ] || tar xf "$TSRC/qps-$V.tar.xz" -C "$TSRC"
  # 시대차: lxqt-build-tools 0.13의 LXQtCompilerSettings가 QT_NO_CAST_FROM_ASCII 등을 강제 → 2018년 qps 코드의
  # `QString("...")`가 전부 private 생성자 에러(4차 발사 실측). 설정 include 직후 remove_definitions로 되돌린다(멱등).
  QCM="$TSRC/qps-$V/CMakeLists.txt"
  grep -q 'MaruxOS: ASCII cast' "$QCM" || sed -i '/include(LXQtCompilerSettings/a remove_definitions(-DQT_NO_CAST_FROM_ASCII -DQT_NO_CAST_TO_ASCII -DQT_NO_CAST_FROM_BYTEARRAY -DQT_NO_URL_CAST_FROM_STRING) # MaruxOS: ASCII cast 허용 (2018 코드 x build-tools 0.13)' "$QCM"
  grep -q 'MaruxOS: ASCII cast' "$QCM" || { echo "🚨 ABORT: qps CMakeLists 패치 실패(LXQtCompilerSettings include 없음?)"; grep -n 'include(' "$QCM" | head; exit 1; }
  build_cmake qps "$TSRC/qps-$V" . || { echo "🚨 ABORT: qps"; exit 1; }
fi

# ---------- [3] LXImage-Qt 0.17.0 ----------
if [ -z "${SKIP_IMAGE:-}" ]; then
  V=0.17.0
  fetch "https://github.com/lxqt/lximage-qt/releases/download/$V/lximage-qt-$V.tar.xz" "$TSRC/lximage-qt-$V.tar.xz" || { echo "🚨 ABORT: lximage-qt fetch"; exit 1; }
  [ -d "$TSRC/lximage-qt-$V" ] || tar xf "$TSRC/lximage-qt-$V.tar.xz" -C "$TSRC"
  build_cmake lximage-qt "$TSRC/lximage-qt-$V" . || { echo "🚨 ABORT: lximage-qt"; exit 1; }
fi

# ---------- [4] LXQt Archiver 0.2.0 (+ json-glib, + Info-ZIP 비치명) ----------
if [ -z "${SKIP_ARCHIVER:-}" ]; then
  # json-glib: rootfs에 없으면 meson 크로스
  if ! ls "$LFS/usr/lib/libjson-glib-1.0.so"* >/dev/null 2>&1; then
    if [ ! -f "$MARKDIR/json-glib" ]; then
      echo "===== json-glib 1.6.6 (meson 크로스) =====" | tee -a "$LOG"
      command -v meson >/dev/null || { echo "  (meson 없음 → pip 설치)"; pip3 install -q meson ninja >/dev/null 2>&1 || apt-get install -y -q meson ninja-build >/dev/null 2>&1; }
      command -v meson >/dev/null || { echo "🚨 ABORT: meson 없음"; exit 1; }
      JV=1.6.6
      fetch "https://download.gnome.org/sources/json-glib/1.6/json-glib-$JV.tar.xz" "$TSRC/json-glib-$JV.tar.xz" || { echo "🚨 ABORT: json-glib fetch"; exit 1; }
      [ -d "$TSRC/json-glib-$JV" ] || tar xf "$TSRC/json-glib-$JV.tar.xz" -C "$TSRC"
      cat > "$TSRC/cross-x86_64.ini" <<CROSS
[binaries]
c = ['x86_64-linux-gnu-gcc', '--sysroot=$LFS']
cpp = ['x86_64-linux-gnu-g++', '--sysroot=$LFS']
ar = 'x86_64-linux-gnu-ar'
strip = 'x86_64-linux-gnu-strip'
pkg-config = '/usr/bin/pkg-config'
[built-in options]
c_args = ['$FORT']
[properties]
sys_root = '$LFS'
pkg_config_libdir = '$LFS/usr/lib/pkgconfig:$LFS/usr/lib64/pkgconfig:$LFS/usr/share/pkgconfig'
[host_machine]
system = 'linux'
cpu_family = 'x86_64'
cpu = 'x86_64'
endian = 'little'
CROSS
      cd "$TSRC/json-glib-$JV" && rm -rf _b \
        && meson setup _b --libdir=lib --cross-file "$TSRC/cross-x86_64.ini" --prefix=/usr -Dintrospection=disabled -Dgtk_doc=disabled -Dman=false -Dtests=false >> "$LOG" 2>&1 \
        && ninja -C _b >> "$LOG" 2>&1 && DESTDIR="$LFS" ninja -C _b install >> "$LOG" 2>&1 \
        || { echo "🚨 ABORT: json-glib 빌드 실패"; tail -30 "$LOG"; exit 1; }
      ls "$LFS/usr/lib/libjson-glib-1.0.so"* >/dev/null 2>&1 || { echo "🚨 ABORT: json-glib 미설치"; exit 1; }
      touch "$MARKDIR/json-glib"; echo "  ✓ json-glib 완료" | tee -a "$LOG"
    fi
  else echo "  json-glib 이미 있음"; fi

  V=0.2.0
  fetch "https://github.com/lxqt/lxqt-archiver/releases/download/$V/lxqt-archiver-$V.tar.xz" "$TSRC/lxqt-archiver-$V.tar.xz" || { echo "🚨 ABORT: lxqt-archiver fetch"; exit 1; }
  [ -d "$TSRC/lxqt-archiver-$V" ] || tar xf "$TSRC/lxqt-archiver-$V.tar.xz" -C "$TSRC"
  build_cmake lxqt-archiver "$TSRC/lxqt-archiver-$V" . || { echo "🚨 ABORT: lxqt-archiver"; exit 1; }

  # Info-ZIP unzip/zip — 비치명 (binfmt로 conftest 실행 가능 전제)
  if [ ! -f "$MARKDIR/infozip" ]; then
    echo "===== Info-ZIP unzip60 / zip30 (비치명) =====" | tee -a "$LOG"
    ZC="x86_64-linux-gnu-gcc --sysroot=$LFS"
    ok=1
    if [ ! -x "$LFS/usr/bin/unzip" ]; then
      fetch "https://downloads.sourceforge.net/infozip/unzip60.tar.gz" "$TSRC/unzip60.tar.gz" && { [ -d "$TSRC/unzip60" ] || tar xf "$TSRC/unzip60.tar.gz" -C "$TSRC"; } \
        && cd "$TSRC/unzip60" && make -f unix/Makefile generic CC="$ZC" CF="-O2 $FORT -DNO_LCHMOD -I. -DUNIX" >> "$LOG" 2>&1 \
        && install -m755 unzip "$LFS/usr/bin/unzip" && echo "  ✓ unzip" | tee -a "$LOG" || { echo "  ⚠️ unzip 실패(비치명)"; ok=0; }
    fi
    if [ ! -x "$LFS/usr/bin/zip" ]; then
      fetch "https://downloads.sourceforge.net/infozip/zip30.tar.gz" "$TSRC/zip30.tar.gz" && { [ -d "$TSRC/zip30" ] || tar xf "$TSRC/zip30.tar.gz" -C "$TSRC"; } \
        && cd "$TSRC/zip30" && make -f unix/Makefile generic CC="$ZC" CFLAGS_NOOPT="-I. -DUNIX $FORT" >> "$LOG" 2>&1 \
        && install -m755 zip "$LFS/usr/bin/zip" && echo "  ✓ zip" | tee -a "$LOG" || { echo "  ⚠️ zip 실패(비치명)"; ok=0; }
    fi
    [ $ok = 1 ] && touch "$MARKDIR/infozip"
  fi
fi

# ---------- [5] 검증 ----------
echo "===== 검증 =====" | tee -a "$LOG"
ok=1
for b in speedcrunch qps lximage-qt lxqt-archiver; do
  case $b in speedcrunch) [ -n "${SKIP_CALC:-}" ] && continue;; qps) [ -n "${SKIP_QPS:-}" ] && continue;; lximage-qt) [ -n "${SKIP_IMAGE:-}" ] && continue;; lxqt-archiver) [ -n "${SKIP_ARCHIVER:-}" ] && continue;; esac
  if [ -x "$LFS/usr/bin/$b" ]; then
    readelf -h "$LFS/usr/bin/$b" | grep -q 'X86-64' && echo "  ✅ $b (x86-64)" || { echo "  🚨 $b 아키텍처 오류"; ok=0; }
    for n in $(readelf -d "$LFS/usr/bin/$b" | grep NEEDED | sed 's/.*\[\(.*\)\]/\1/'); do
      ls "$LFS/usr/lib/$n" "$LFS/lib/$n" >/dev/null 2>&1 || { echo "  ❌ $b NEEDED 누락: $n"; ok=0; }; done
  else echo "  ❌ $b 없음"; ok=0; fi
done
echo "  zip 백엔드: unzip $([ -x "$LFS/usr/bin/unzip" ] && echo ✓ || echo ✗) / zip $([ -x "$LFS/usr/bin/zip" ] && echo ✓ || echo ✗) (비치명)"
bash "$SCRIPTS/gate-qt-launch-x86.sh" || { echo "🚨 ABORT: Qt 기동 게이트 실패"; ok=0; }
[ "$ok" = 1 ] && { touch "$B/.t-COMPLETE"; echo "LXTOOLS_COMPLETE=YES"; } || { echo "LXTOOLS_COMPLETE=NO"; exit 1; }
