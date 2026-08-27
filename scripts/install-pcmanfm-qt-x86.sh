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
# MaruxOS 2.0.0 "Cooked" — ARM64 배치 F: PCManFM-Qt (mc 대체, 로드맵 4번)
# -----------------------------------------------------------------------------
# 전제: 배치 Q 완료($B/.q-COMPLETE — Qt5 + qterminal). 동일 크로스 체계를 재사용한다.
#   · CMake 툴체인: $B/qt-cross-toolchain.cmake (배치 Q에서 생성)
#   · 호스트 LinguistTools: lrelease는 호스트 실행 필요 → Ubuntu 것 차용
#   · **-D_FORTIFY_SOURCE=2 명시**(함정 #35) — Ubuntu 크로스 gcc의 암묵 3이 Qt를 오탐으로 죽인다
#   · **호스트에서 실행되는 도구는 전부 명시**(PERL/PKG_CONFIG) — CMAKE_PREFIX_PATH에
#     sysroot가 있으면 find_program이 ARM 바이너리를 집어 'Syntax error'/Error 126이 난다
# 사슬: libexif → libfm(extra-only) → menu-cache → libfm-qt → pcmanfm-qt
# resumable($B/.f-markers). 완료기준: $B/.f-COMPLETE. 실행: wsl -u root bash <this>
# =============================================================================
set -uo pipefail
B=/home/administrator/MaruxOS/x86-parity
export PATH="$B/bin:$PATH"   # gcc-13 래퍼 접두어
LFS=$B/rootfs-lfs-parity
FSRC=$B/fm-src
QTHOST=$B/qt-host
TC=$B/qt-cross-toolchain.cmake
JOBS=${JOBS:-32}
MARKDIR=$B/.f-markers; mkdir -p "$MARKDIR" "$FSRC"
LOG=$B/pcmanfm-qt-build.log

# ---------- 게이트 ----------
[[ "$LFS" == *"x86-parity"* ]] || { echo "🚨 ABORT: $LFS"; exit 1; }
[ -f "$B/.q-COMPLETE" ] || { echo "🚨 ABORT: 배치 Q 미완(Qt5 필요)"; exit 1; }
[ -f "$TC" ] || { echo "🚨 ABORT: CMake 툴체인 없음"; exit 1; }
[ -x "$QTHOST/bin/qmake" ] || { echo "🚨 ABORT: 호스트 qmake 없음"; exit 1; }
x86_64-linux-gnu-g++ -dumpmachine | grep -q x86_64 || { echo "🚨 ABORT: 크로스 g++ 아님"; exit 1; }
HOST_LINGUIST_DIR=$(dirname "$(find /usr/lib -name Qt5LinguistToolsConfig.cmake 2>/dev/null | head -1)")
[ -d "$HOST_LINGUIST_DIR" ] || { echo "🚨 ABORT: 호스트 Qt5LinguistTools 없음"; exit 1; }

fetch(){ [ -s "$2" ] && { echo "  (캐시) $(basename "$2")"; return 0; }
  echo "[fetch] $(basename "$2")"
  timeout 900 wget -q -O "$2" "$1" || { rm -f "$2"; echo "🚨 ABORT: fetch 실패 $1"; exit 1; }
  echo "  OK $(ls -lh "$2" | awk '{print $5}')"; }

# ---------- autotools 크로스 빌드 (libexif, menu-cache) ----------
build_autotools(){   # $1=이름 $2=버전 $3=URL $4...=configure 옵션
  local name="$1" ver="$2" url="$3"; shift 3
  [ -f "$MARKDIR/$name" ] && { echo "SKIP $name"; return 0; }
  echo "===== $name $ver (autotools 크로스) =====" | tee -a "$LOG"
  fetch "$url" "$FSRC/$name-$ver.tar.gz"
  [ -d "$FSRC/$name-$ver" ] || { cd "$FSRC" && tar xf "$name-$ver.tar.gz"; }
  cd "$FSRC/$name-$ver" || { echo "🚨 ABORT: $name 전개"; exit 1; }
  env PKG_CONFIG_SYSROOT_DIR="$LFS" PKG_CONFIG_LIBDIR="$LFS/usr/lib/pkgconfig:$LFS/usr/lib64/pkgconfig:$LFS/usr/share/pkgconfig" \
      CC="x86_64-linux-gnu-gcc --sysroot=$LFS" CXX="x86_64-linux-gnu-g++ --sysroot=$LFS" CFLAGS="-O2 -fcommon -D_FORTIFY_SOURCE=2" CXXFLAGS="-O2 -fcommon -D_FORTIFY_SOURCE=2" \
      ./configure --host=x86_64-linux-gnu --prefix=/usr --disable-static "$@" >> "$LOG" 2>&1 \
    && make -j"$JOBS" >> "$LOG" 2>&1 \
    && make install DESTDIR="$LFS" >> "$LOG" 2>&1 \
    || { echo "🚨 ABORT: $name 빌드 실패"; tail -25 "$LOG"; exit 1; }
  touch "$MARKDIR/$name"; echo "  ✓ $name 완료" | tee -a "$LOG"
}

# ---------- CMake 크로스 빌드 (libfm-qt, pcmanfm-qt) ----------
build_cmake(){   # $1=이름 $2=버전 $3=URL $4...=cmake 옵션
  local name="$1" ver="$2" url="$3"; shift 3
  [ -f "$MARKDIR/$name" ] && { echo "SKIP $name"; return 0; }
  echo "===== $name $ver (CMake 크로스) =====" | tee -a "$LOG"
  fetch "$url" "$FSRC/$name-$ver.tar.gz"
  [ -d "$FSRC/$name-$ver" ] || { cd "$FSRC" && tar xf "$name-$ver.tar.gz"; }
  cd "$FSRC/$name-$ver" || { echo "🚨 ABORT: $name 전개"; exit 1; }
  rm -rf _b && mkdir _b && cd _b
  cmake .. -DCMAKE_TOOLCHAIN_FILE="$TC" -DCMAKE_BUILD_TYPE=Release \
           -DCMAKE_INSTALL_PREFIX=/usr -DQT_QMAKE_EXECUTABLE="$QTHOST/bin/qmake" \
           -DCMAKE_PREFIX_PATH="$LFS/usr" -DPERL_EXECUTABLE=/usr/bin/perl -DPKG_CONFIG_EXECUTABLE=/usr/bin/pkg-config \
           -DQt5LinguistTools_DIR="$HOST_LINGUIST_DIR" "$@" >> "$LOG" 2>&1 \
    && make -j"$JOBS" >> "$LOG" 2>&1 \
    && make install DESTDIR="$LFS" >> "$LOG" 2>&1 \
    || { echo "🚨 ABORT: $name 빌드 실패"; tail -30 "$LOG"; exit 1; }
  touch "$MARKDIR/$name"; echo "  ✓ $name 완료" | tee -a "$LOG"
}

build_autotools libexif 0.6.24 \
  "https://github.com/libexif/libexif/releases/download/v0.6.24/libexif-0.6.24.tar.bz2" --disable-docs
# libfm-extra: menu-cache가 요구한다. libfm(GTK판) 소속이지만 GTK 없이 extra만 빌드하는
# --with-extra-only 옵션이 있다(libfm↔menu-cache 순환 의존을 끊으려 업스트림이 제공).
# libfm-qt는 libfm(GTK)에 의존하지 않는 독립 Qt 구현이므로 extra만 있으면 충분하다.
build_autotools libfm 1.3.2   "https://downloads.sourceforge.net/pcmanfm/libfm-1.3.2.tar.xz" --with-extra-only --disable-gtk-doc

build_autotools menu-cache 1.1.0 \
  "https://downloads.sourceforge.net/lxde/menu-cache-1.1.0.tar.xz"
build_cmake libfm-qt 0.17.0 \
  "https://github.com/lxqt/libfm-qt/releases/download/0.17.0/libfm-qt-0.17.0.tar.xz" -DBUILD_TESTING=OFF
build_cmake pcmanfm-qt 0.17.0 \
  "https://github.com/lxqt/pcmanfm-qt/releases/download/0.17.0/pcmanfm-qt-0.17.0.tar.xz" -DBUILD_TESTING=OFF

# ---------- 검증 ----------
echo "===== 검증 =====" | tee -a "$LOG"
ok=1
[ -x "$LFS/usr/bin/pcmanfm-qt" ] && echo "  ✅ pcmanfm-qt" || { echo "  ❌ pcmanfm-qt"; ok=0; }
ls "$LFS/usr/lib/"libfm-qt.so* >/dev/null 2>&1 && echo "  ✅ libfm-qt" || { echo "  ❌ libfm-qt"; ok=0; }
ls "$LFS/usr/lib/"libmenu-cache.so* >/dev/null 2>&1 && echo "  ✅ menu-cache" || { echo "  ❌ menu-cache"; ok=0; }
ls "$LFS/usr/lib/"libexif.so* >/dev/null 2>&1 && echo "  ✅ libexif" || { echo "  ❌ libexif"; ok=0; }
ls "$LFS/usr/lib/"libfm-extra.so* >/dev/null 2>&1 && echo "  ✅ libfm-extra" || { echo "  ❌ libfm-extra"; ok=0; }
if [ -x "$LFS/usr/bin/pcmanfm-qt" ]; then
  readelf -h "$LFS/usr/bin/pcmanfm-qt" | grep -q 'X86-64' && echo "  ✅ x86-64 ELF" || { echo "  🚨 아키텍처 오류"; ok=0; }
fi
# 존재 검사 ≠ 기동 검사 (함정 #35, 2026-08-26): 실제 chroot 기동 게이트
bash "$(dirname "$0")/gate-qt-launch-x86.sh" || { echo "🚨 ABORT: Qt 기동 게이트 실패"; ok=0; }
[ "$ok" = 1 ] && { touch "$B/.f-COMPLETE"; echo "PCMANFM_QT_COMPLETE=YES"; } || { echo "PCMANFM_QT_COMPLETE=NO"; exit 1; }
