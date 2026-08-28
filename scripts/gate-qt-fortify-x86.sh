#!/bin/bash
# =============================================================================
# gate-qt-fortify-x86.sh — x86 패리티: Qt 스택 FORTIFY=2 *검증* + .q-FORTIFY2-OK 기록 (2026-08-28)
#   ARM64는 함정 #35(암묵 FORTIFY=3) 발각 후 rebuild-qt-fortify-arm64.sh 로 *재*빌드했지만,
#   x86 패리티는 install-qt5-x86.sh 가 처음부터 mkspec/CMake에 =2 를 박고 빌드했다.
#   그러나 "박았다 ≠ 적용됐다" — 실제 빌드 트리의 Makefile 플래그와 기동 게이트로 실증한 뒤에만
#   마커를 쓴다(featherpad/lxtools 설치 모듈이 이 마커를 전제로 요구).
# =============================================================================
set -uo pipefail
B=/home/administrator/MaruxOS/x86-parity
export PATH="$B/bin:$PATH"
LFS=$B/rootfs-lfs-parity
QSRC=$B/qt-src; QTVER=5.15.2; QT=$QSRC/qtbase-everywhere-src-$QTVER
GATE=${GATE:-$B/gate-qt-launch-x86.sh}
[[ "$LFS" == *"x86-parity"* ]] || { echo "🚨 ABORT: $LFS"; exit 1; }
[ -f "$B/.q-COMPLETE" ] && [ -f "$B/.f-COMPLETE" ] || { echo "🚨 ABORT: 배치 Q/F 미완"; exit 1; }
x86_64-linux-gnu-g++ -dumpmachine | grep -q x86_64 || { echo "🚨 ABORT: 래퍼 g++ 아님"; exit 1; }

# [1] 컴파일러 암묵 기본값 실측 (크로스 규칙 ⑥)
DEF=$(echo | x86_64-linux-gnu-gcc -O2 -dM -E - | awk '/_FORTIFY_SOURCE/{print $3}')
echo "  gcc-13 래퍼 암묵 _FORTIFY_SOURCE = ${DEF:-없음}"
echo | x86_64-linux-gnu-gcc -O2 -D_FORTIFY_SOURCE=2 -dM -E - | grep -q '_FORTIFY_SOURCE 2' || { echo "🚨 ABORT: =2 가 기본값을 덮지 못함"; exit 1; }

# [2] 실제 빌드 트리 플래그: qtbase corelib Makefile + qterminal/pcmanfm-qt CMake 캐시
MK=$QT/src/corelib/Makefile
[ -f "$MK" ] || { echo "🚨 ABORT: $MK 없음"; exit 1; }
grep -q -- '-D_FORTIFY_SOURCE=2' "$MK" || { echo "🚨 ABORT: qtbase corelib Makefile에 FORTIFY=2 없음 — Qt가 =3으로 빌드됐을 수 있음(재빌드 필요)"; exit 1; }
echo "  ✅ qtbase corelib Makefile: -D_FORTIFY_SOURCE=2"
# 빌드 디렉토리는 `_b` (lxqt-build-tools는 CMake 모듈만 — 컴파일 없음 → 제외). 0개면 게이트 자기 오류로 간주해 실패.
# (첫 판은 `build/`를 가정해 0개인데도 통과 — 2026-08-28 교정)
n=0
for c in $QSRC/*/_b/CMakeCache.txt $B/fm-src/*/_b/CMakeCache.txt; do
  [ -f "$c" ] || continue; [[ "$c" == *lxqt-build-tools* ]] && continue
  grep -q '_FORTIFY_SOURCE=2' "$c" || { echo "🚨 ABORT: $c 에 FORTIFY=2 없음"; exit 1; }
  n=$((n+1))
done
[ "$n" -ge 4 ] || { echo "🚨 ABORT: CMake 캐시가 ${n}개뿐 — 경로 가정 오류(qterminal·qtermwidget·libfm-qt·pcmanfm-qt 4개 기대)"; exit 1; }
echo "  ✅ CMake 캐시 FORTIFY=2: ${n}개"

# [3] 아키텍처 + 기동 게이트(실제 실행)
for f in usr/bin/qterminal usr/bin/pcmanfm-qt usr/lib/libQt5Core.so.5.15.2; do
  readelf -h "$LFS/$f" | grep -q 'X86-64' || { echo "🚨 ABORT: $f 아키텍처 오류"; exit 1; }
done
bash "$GATE" || { echo "🚨 ABORT: 기동 게이트 실패"; exit 1; }

{ echo "# x86 Qt 스택 FORTIFY=2 빌드 검증 + 기동 게이트 통과 $(date)"
  for f in usr/lib/libQt5Core.so.5.15.2 usr/bin/qterminal usr/bin/pcmanfm-qt usr/lib/libfm-qt.so.9.0.0; do
    [ -e "$LFS/$f" ] && sha256sum "$LFS/$f" | sed "s|$LFS/||"
  done; } > "$B/.q-FORTIFY2-OK"
echo "===== ✅ FORTIFY 검증 완료 ====="; cat "$B/.q-FORTIFY2-OK"
