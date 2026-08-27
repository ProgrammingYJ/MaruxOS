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
# MaruxOS 2.0.0 "Cooked" — ARM64 배치 E: FeatherPad (GUI 텍스트 편집기, "notepad")
# -----------------------------------------------------------------------------
# 요청(2026-08-27, 출품 당일): "txt 같은 텍스트 여는 notepad 같은 거 포함".
# 선택: FeatherPad(LXQt 계열, Qt5) — QTerminal·PCManFM-Qt와 같은 Qt 크로스 체계를 그대로 재사용.
# 사슬: qtsvg(qmake 모듈, FeatherPad 필수 — rootfs에 libQt5Svg 없음) → FeatherPad(CMake)
#   · hunspell 1.7.2 크로스 빌드 (FeatherPad 0.17.1 REQUIRED — 첫 발사에서 확인)
#   · FORTIFY: mkspec(qtsvg)·CMake 툴체인(featherpad) 모두 -D_FORTIFY_SOURCE=2 (함정 #35)
#   · 호스트 실행 도구 명시(PERL/PKG_CONFIG/LinguistTools) (함정 #34)
#   · ⚠️ make install이 featherpad.desktop을 깔지만 config(v14)가 우리 .desktop으로 덮는다(함정 #36 순서).
# resumable($B/.e-markers). 완료기준: $B/.e-COMPLETE. 실행: wsl -u root bash <this>
# =============================================================================
set -uo pipefail
B=/home/administrator/MaruxOS/x86-parity
export PATH="$B/bin:$PATH"   # gcc-13 래퍼 접두어
LFS=$B/rootfs-lfs-parity
QSRC=$B/qt-src; ESRC=$B/ed-src; QTHOST=$B/qt-host
TC=$B/qt-cross-toolchain.cmake
QTVER=5.15.2
FP_VER=${FP_VER:-0.17.1}
JOBS=${JOBS:-32}
MARKDIR=$B/.e-markers; mkdir -p "$MARKDIR" "$ESRC"
LOG=$B/featherpad-build.log
SCRIPTS=/mnt/c/Users/Administrator/Desktop/MaruxOS/scripts

# ---------- 게이트 ----------
[[ "$LFS" == *"x86-parity"* ]] || { echo "🚨 ABORT: $LFS"; exit 1; }
[ -f "$B/.q-COMPLETE" ] && [ -f "$B/.q-FORTIFY2-OK" ] || { echo "🚨 ABORT: 배치 Q(+FORTIFY 재빌드) 미완"; exit 1; }
[ -f "$TC" ] && grep -q FORTIFY "$TC" || { echo "🚨 ABORT: CMake 툴체인에 FORTIFY 없음"; exit 1; }
[ -x "$QTHOST/bin/qmake" ] || { echo "🚨 ABORT: 호스트 qmake 없음"; exit 1; }
grep -q -- '-D_FORTIFY_SOURCE=2' "$QTHOST/mkspecs/linux-g++-64/qmake.conf" || { echo "🚨 ABORT: 호스트 mkspec FORTIFY 없음"; exit 1; }
x86_64-linux-gnu-g++ -dumpmachine | grep -q x86_64 || { echo "🚨 ABORT: 크로스 g++ 아님"; exit 1; }
HOST_LINGUIST_DIR=$(dirname "$(find /usr/lib -name Qt5LinguistToolsConfig.cmake 2>/dev/null | head -1)")
[ -d "$HOST_LINGUIST_DIR" ] || { echo "🚨 ABORT: 호스트 Qt5LinguistTools 없음"; exit 1; }
export PKG_CONFIG_SYSROOT_DIR="$LFS" PKG_CONFIG_LIBDIR="$LFS/usr/lib/pkgconfig:$LFS/usr/lib64/pkgconfig:$LFS/usr/share/pkgconfig" PKG_CONFIG_PATH=""

fetch(){ [ -s "$2" ] && { echo "  (캐시) $(basename "$2")"; return 0; }
  echo "[fetch] $(basename "$2")"
  timeout 900 wget -q -O "$2" "$1" || { rm -f "$2"; return 1; }
  echo "  OK $(ls -lh "$2" | awk '{print $5}')"; }

# ---------- [1] qtsvg (qmake 모듈 — 호스트 qmake가 sysroot/FORTIFY mkspec을 상속) ----------
if [ ! -f "$MARKDIR/qtsvg" ]; then
  echo "===== [1] qtsvg $QTVER 크로스 빌드 =====" | tee -a "$LOG"
  fetch "https://download.qt.io/archive/qt/5.15/$QTVER/submodules/qtsvg-everywhere-src-$QTVER.tar.xz" "$QSRC/qtsvg-everywhere-src-$QTVER.tar.xz" || { echo "🚨 ABORT: qtsvg fetch"; exit 1; }
  [ -d "$QSRC/qtsvg-everywhere-src-$QTVER" ] || { cd "$QSRC" && tar xf "qtsvg-everywhere-src-$QTVER.tar.xz"; }
  cd "$QSRC/qtsvg-everywhere-src-$QTVER" || { echo "🚨 ABORT: qtsvg 디렉토리"; exit 1; }
  rm -f Makefile .qmake.cache
  "$QTHOST/bin/qmake" >> "$LOG" 2>&1 || { echo "🚨 ABORT: qtsvg qmake 실패"; tail -20 "$LOG"; exit 1; }
  make -j"$JOBS" >> "$LOG" 2>&1 || { echo "🚨 ABORT: qtsvg make 실패"; tail -30 "$LOG"; exit 1; }
  # 하위 Makefile은 make 시점에 생성되므로 플래그 검사는 make *후* (사전 grep은 빈손 — 첫 발사 오탐)
  grep -rq --include=Makefile -- '-D_FORTIFY_SOURCE=2' src/ || { echo "🚨 ABORT: qtsvg 하위 Makefile에 FORTIFY=2 없음"; exit 1; }
  make install >> "$LOG" 2>&1 || { echo "🚨 ABORT: qtsvg install 실패"; tail -15 "$LOG"; exit 1; }
  ls "$LFS/usr/lib/libQt5Svg.so.5"* >/dev/null 2>&1 || { echo "🚨 ABORT: libQt5Svg 미설치"; exit 1; }
  touch "$MARKDIR/qtsvg"; echo "  ✓ qtsvg 완료" | tee -a "$LOG"
else echo "SKIP qtsvg"; fi

# ---------- [1b] hunspell (FeatherPad 0.17.1은 REQUIRED — 첫 발사에서 확인, WITH_HUNSPELL 옵션은 후속 버전) ----------
HS_VER=${HS_VER:-1.7.2}
if [ ! -f "$MARKDIR/hunspell" ]; then
  echo "===== [1b] hunspell $HS_VER 크로스 빌드 (autotools) =====" | tee -a "$LOG"
  fetch "https://github.com/hunspell/hunspell/releases/download/v$HS_VER/hunspell-$HS_VER.tar.gz" "$ESRC/hunspell-$HS_VER.tar.gz" || { echo "🚨 ABORT: hunspell fetch"; exit 1; }
  [ -d "$ESRC/hunspell-$HS_VER" ] || { cd "$ESRC" && tar xf "hunspell-$HS_VER.tar.gz"; }
  cd "$ESRC/hunspell-$HS_VER" || { echo "🚨 ABORT: hunspell 디렉토리"; exit 1; }
  [ -x configure ] || autoreconf -fi >> "$LOG" 2>&1 || { echo "🚨 ABORT: hunspell autoreconf"; exit 1; }
  env CC="x86_64-linux-gnu-gcc --sysroot=$LFS" CXX="x86_64-linux-gnu-g++ --sysroot=$LFS" \
      CFLAGS="-O2 -D_FORTIFY_SOURCE=2" CXXFLAGS="-O2 -D_FORTIFY_SOURCE=2" \
      ./configure --host=x86_64-linux-gnu --prefix=/usr --disable-static >> "$LOG" 2>&1 \
    && make -j"$JOBS" >> "$LOG" 2>&1 && make install DESTDIR="$LFS" >> "$LOG" 2>&1 \
    || { echo "🚨 ABORT: hunspell 빌드 실패"; tail -25 "$LOG"; exit 1; }
  ls "$LFS/usr/lib/libhunspell-1.7.so"* >/dev/null 2>&1 || { echo "🚨 ABORT: libhunspell 미설치"; exit 1; }
  # .la 절대경로 무력화 (함정 #34-4) — 다음 CMake/libtool 소비자 보호
  sed -i "s|^dependency_libs=.*|dependency_libs=''|" "$LFS"/usr/lib/libhunspell-1.7.la 2>/dev/null || true
  touch "$MARKDIR/hunspell"; echo "  ✓ hunspell 완료" | tee -a "$LOG"
else echo "SKIP hunspell"; fi

# ---------- [2] FeatherPad (CMake 크로스) ----------
if [ ! -f "$MARKDIR/featherpad" ]; then
  echo "===== [2] FeatherPad $FP_VER 크로스 빌드 (CMake) =====" | tee -a "$LOG"
  TB="$ESRC/FeatherPad-$FP_VER.tar.xz"
  fetch "https://github.com/tsujan/FeatherPad/releases/download/V$FP_VER/FeatherPad-$FP_VER.tar.xz" "$TB" \
    || { echo "  (릴리즈 자산 없음 → 태그 아카이브로)"; TB="$ESRC/FeatherPad-$FP_VER.tar.gz"
         fetch "https://github.com/tsujan/FeatherPad/archive/refs/tags/V$FP_VER.tar.gz" "$TB" || { echo "🚨 ABORT: FeatherPad fetch 실패"; exit 1; }; }
  if [ ! -d "$ESRC/FeatherPad-$FP_VER" ]; then cd "$ESRC" && tar xf "$TB"; fi
  cd "$ESRC/FeatherPad-$FP_VER" || { echo "🚨 ABORT: FeatherPad 디렉토리"; ls "$ESRC"; exit 1; }
  rm -rf _b && mkdir _b && cd _b
  cmake .. -DCMAKE_TOOLCHAIN_FILE="$TC" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr \
    -DQT_QMAKE_EXECUTABLE="$QTHOST/bin/qmake" -DCMAKE_PREFIX_PATH="$LFS/usr" \
    -DPERL_EXECUTABLE=/usr/bin/perl -DPKG_CONFIG_EXECUTABLE=/usr/bin/pkg-config \
    -DQt5LinguistTools_DIR="$HOST_LINGUIST_DIR" >> "$LOG" 2>&1 \
    || { echo "🚨 ABORT: FeatherPad cmake 실패"; tail -30 "$LOG"; exit 1; }
  grep -q -- '-D_FORTIFY_SOURCE=2' CMakeCache.txt || { echo "🚨 ABORT: CMakeCache에 FORTIFY=2 없음"; exit 1; }
  make -j"$JOBS" >> "$LOG" 2>&1 || { echo "🚨 ABORT: FeatherPad make 실패"; tail -40 "$LOG"; exit 1; }
  make install DESTDIR="$LFS" >> "$LOG" 2>&1 || { echo "🚨 ABORT: FeatherPad install 실패"; tail -15 "$LOG"; exit 1; }
  touch "$MARKDIR/featherpad"; echo "  ✓ FeatherPad 완료" | tee -a "$LOG"
else echo "SKIP featherpad"; fi

# ---------- [3] 검증 ----------
echo "===== 검증 =====" | tee -a "$LOG"
ok=1
[ -x "$LFS/usr/bin/featherpad" ] && echo "  ✅ featherpad" || { echo "  ❌ featherpad"; ok=0; }
ls "$LFS/usr/lib/libQt5Svg.so.5"* >/dev/null 2>&1 && echo "  ✅ libQt5Svg" || { echo "  ❌ libQt5Svg"; ok=0; }
if [ -x "$LFS/usr/bin/featherpad" ]; then
  readelf -h "$LFS/usr/bin/featherpad" | grep -q 'X86-64' && echo "  ✅ x86-64 ELF" || { echo "  🚨 아키텍처 오류"; ok=0; }
  # 재귀 의존성 누락 검사 (rootfs 안에서 해석되는가)
  miss=0; for n in $(readelf -d "$LFS/usr/bin/featherpad" | grep NEEDED | sed 's/.*\[\(.*\)\]/\1/'); do
    ls "$LFS/usr/lib/$n" "$LFS/lib/$n" >/dev/null 2>&1 || { echo "  ❌ NEEDED 누락: $n"; miss=1; }; done
  [ $miss = 0 ] && echo "  ✅ NEEDED 전부 rootfs에 존재" || ok=0
fi
# 존재 ≠ 기동: 기동 게이트(featherpad 포함판)
bash "$SCRIPTS/gate-qt-launch-x86.sh" || { echo "🚨 ABORT: Qt 기동 게이트 실패"; ok=0; }
[ "$ok" = 1 ] && { touch "$B/.e-COMPLETE"; echo "FEATHERPAD_COMPLETE=YES"; } || { echo "FEATHERPAD_COMPLETE=NO"; exit 1; }
