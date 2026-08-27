#!/bin/bash
# =============================================================================
# MaruxOS 2.0.0 "Cooked" — ARM64 Qt **기동 게이트** (존재 검사 ≠ 기동 검사)
# -----------------------------------------------------------------------------
# 배경(2026-08-26, 함정 #35): v26/v27은 qterminal·pcmanfm-qt의 *존재*와 *아키텍처*만
# 게이트했다. 그런데 실기기에서 qterminal은 첫 QSettings 접근에서
#   *** buffer overflow detected *** (glibc FORTIFY 오탐 — __readlink_chk ← qt_readlink)
# 로 즉사했고, pcmanfm-qt는 종료 시 같은 지점에서 죽었다. `--version`은 QSettings 전에
# 끝나서 그 어떤 정적 검사도 이를 잡지 못했다.
#   ⇒ 이 게이트는 rootfs를 qemu-aarch64 chroot로 **실제 실행**해 N초 생존을 확인한다.
#
# 검사: ① qterminal (xcb → Xvfb)          → 12초 생존 + stderr에 'buffer overflow' 없음
#       ② pcmanfm-qt (xcb+세션버스)      → 12초 생존 + SIGTERM 종료 경로(설정 저장)도 무사
# 플랫폼은 **xcb(호스트 Xvfb :77)** — 실제 배포 경로. 첫 판(2026-08-26)은 offscreen을 썼는데
# offscreen 플러그인이 raise()/propagateSizeHints()를 지원하지 않아 pcmanfm-qt가 SIGSEGV
# → 게이트 오탐(false negative). xcb에선 동일 바이너리가 깨끗이 통과했다. 호스트 의존성: xvfb.
# 부작용 0: 던져버릴 HOME(/tmp/qtgate-home)을 쓰고 끝나면 지운다. 이미지에 흔적 없음.
# 사용: wsl -u root bash <this>   (단독 실행 가능 / 재빌드·이미지 빌드 스크립트가 호출)
# =============================================================================
set -uo pipefail
B=/home/administrator/MaruxOS-arm64
LFS=${QTGATE_ROOT:-$B/rootfs-clfs-arm64}   # v33: 슬림 이미지 *사본*에서도 실행 (QTGATE_ROOT=<마운트 경로>)
GH=/tmp/qtgate-home            # rootfs 내부 경로 (던져버릴 HOME)
SECS=${QTGATE_SECS:-12}

if [ -n "${QTGATE_ROOT:-}" ]; then mountpoint -q "$LFS" || { echo "🚨 ABORT: QTGATE_ROOT($LFS)가 마운트포인트가 아님"; exit 1; }
else [[ "$LFS" == *"MaruxOS-arm64"* ]] || { echo "🚨 ABORT: $LFS"; exit 1; }; fi
[ -x "$LFS/usr/bin/qterminal" ] || { echo "🚨 ABORT: qterminal 없음"; exit 1; }
[ -x "$LFS/usr/bin/pcmanfm-qt" ] || { echo "🚨 ABORT: pcmanfm-qt 없음"; exit 1; }
[ -x "$LFS/usr/bin/dbus-launch" ] || { echo "🚨 ABORT: rootfs에 dbus-launch 없음"; exit 1; }
command -v Xvfb >/dev/null || { echo "  (호스트 Xvfb 없음 → apt 설치 시도)"; apt-get install -y -q xvfb >/dev/null 2>&1; }
command -v Xvfb >/dev/null || { echo "🚨 ABORT: 호스트 Xvfb 없음 (apt install xvfb)"; exit 1; }
XD=77

# --- binfmt 보장 (함정 #5 확장: WSL VM이 유휴 종료되면 수동 등록이 사라진다) ---
if [ ! -e /proc/sys/fs/binfmt_misc/qemu-aarch64 ]; then
  mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc 2>/dev/null
  [ -x /usr/bin/qemu-aarch64-static ] || { echo "🚨 ABORT: 호스트 qemu-aarch64-static 없음"; exit 1; }
  echo ":qemu-aarch64:M::\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-aarch64-static:F" \
    > /proc/sys/fs/binfmt_misc/register || { echo "🚨 ABORT: binfmt 등록 실패"; exit 1; }
  echo "  [binfmt 재등록]"
fi
for m in proc sys dev dev/pts; do mountpoint -q "$LFS/$m" || mount --bind /$m "$LFS/$m" 2>/dev/null; done

cleanup(){
  # 우리가 띄운 ARM 프로세스만 정리 (호스트엔 이 경로의 네이티브 바이너리가 없다)
  pkill -f '^/usr/bin/qterminal$' 2>/dev/null; pkill -f '^/usr/bin/pcmanfm-qt$' 2>/dev/null
  pkill -f "Xvfb :$XD" 2>/dev/null
  mountpoint -q "$LFS/tmp/.X11-unix" && umount "$LFS/tmp/.X11-unix"   # 이미지에 소켓 디렉토리가 실리지 않도록 반드시 해제
  rm -rf "$LFS$GH" "$LFS/run/user/0"; rm -f "$LFS"/tmp/dbus-* 2>/dev/null; rmdir "$LFS/tmp/.X11-unix" 2>/dev/null
  # 사본(QTGATE_ROOT)에서 돌렸으면 bind 마운트도 걷는다 (이미지 umount 가능하도록)
  if [ -n "${QTGATE_ROOT:-}" ]; then for m in dev/pts dev sys proc; do mountpoint -q "$LFS/$m" && umount "$LFS/$m"; done; fi
}
trap cleanup EXIT
rm -rf "$LFS$GH"; mkdir -p "$LFS$GH" "$LFS/run/user/0"; chmod 700 "$LFS/run/user/0"

# 호스트 Xvfb → rootfs로 소켓 bind (xcb 경로)
pkill -f "Xvfb :$XD" 2>/dev/null; sleep 1
Xvfb :$XD -screen 0 1280x800x24 >/tmp/qtgate-xvfb.log 2>&1 &
sleep 3; pgrep -f "Xvfb :$XD" >/dev/null || { echo "🚨 ABORT: Xvfb :$XD 기동 실패"; cat /tmp/qtgate-xvfb.log; exit 1; }
mkdir -p "$LFS/tmp/.X11-unix"; mountpoint -q "$LFS/tmp/.X11-unix" || mount --bind /tmp/.X11-unix "$LFS/tmp/.X11-unix"

ENVV="HOME=$GH XDG_RUNTIME_DIR=/run/user/0 DISPLAY=:$XD QT_QPA_PLATFORM=xcb QT_PLUGIN_PATH=/usr/plugins QT_QPA_PLATFORM_PLUGIN_PATH=/usr/plugins/platforms"
fail=0

echo "===== Qt 기동 게이트 (xcb/Xvfb :$XD, ${SECS}s 생존) ====="
# ① qterminal — 첫 QSettings 접근(Properties::migrate_settings)이 크래시 지점이었다
out=$(timeout -k 5 "$SECS" chroot "$LFS" /usr/bin/env $ENVV /usr/bin/qterminal 2>&1); rc=$?
if echo "$out" | grep -q 'buffer overflow'; then echo "  🚨 qterminal: FORTIFY 오탐 재발 (buffer overflow detected)"; fail=1
elif [ $rc -ne 124 ]; then echo "  🚨 qterminal: ${SECS}초 전에 종료 rc=$rc :: $(echo "$out" | tr '\n' '|' | cut -c1-200)"; fail=1
else echo "  ✅ qterminal ${SECS}초 생존"; fi

# ② pcmanfm-qt — 세션 버스가 있어야 '첫 인스턴스'로 판정돼 실제로 기동한다.
#    SIGTERM 종료 경로(aboutToQuit → 설정 저장)가 두 번째 크래시 지점이었으므로 timeout으로
#    정확히 그 경로를 태운다. 내부 timeout이 pcmanfm-qt를 직접 감싼다(bash가 TERM을 미루는 문제 회피).
out=$(timeout -k 5 $((SECS+20)) chroot "$LFS" /bin/bash -c "eval \$(dbus-launch --sh-syntax); export $ENVV; timeout $SECS /usr/bin/pcmanfm-qt; rc=\$?; kill \$DBUS_SESSION_BUS_PID 2>/dev/null; exit \$rc" 2>&1); rc=$?
if echo "$out" | grep -q 'buffer overflow'; then echo "  🚨 pcmanfm-qt: FORTIFY 오탐 재발 (종료 경로)"; fail=1
elif [ $rc -ne 124 ]; then echo "  🚨 pcmanfm-qt: ${SECS}초 전에 종료 rc=$rc :: $(echo "$out" | tr '\n' '|' | cut -c1-200)"; fail=1
else echo "  ✅ pcmanfm-qt ${SECS}초 생존 + SIGTERM 종료 경로 무사"; fi

# ③ featherpad (배치 E, 2026-08-27) — 있으면 검사. 파일 인자로 열어 편집기 경로까지 태운다.
if [ -x "$LFS/usr/bin/featherpad" ]; then
  printf 'MaruxOS 기동 게이트 테스트
한글 줄
' > "$LFS$GH/test.txt"
  out=$(timeout -k 5 "$SECS" chroot "$LFS" /usr/bin/env $ENVV /usr/bin/featherpad "$GH/test.txt" 2>&1); rc=$?
  if echo "$out" | grep -q 'buffer overflow'; then echo "  🚨 featherpad: FORTIFY 오탐"; fail=1
  elif [ $rc -ne 124 ]; then echo "  🚨 featherpad: ${SECS}초 전에 종료 rc=$rc :: $(echo "$out" | tr '
' '|' | cut -c1-200)"; fail=1
  else echo "  ✅ featherpad ${SECS}초 생존 (test.txt 열기)"; fi
fi

# ④ 배치 T 툴 4종 (있으면) — lximage-qt는 이미지 파일 인자로
if [ -x "$LFS/usr/bin/lximage-qt" ] && [ -f "$LFS/usr/share/pixmaps/maruxos/marux-logo.png" ]; then cp "$LFS/usr/share/pixmaps/maruxos/marux-logo.png" "$LFS$GH/test.png"; fi
# lximage-qt는 pcmanfm-qt처럼 D-Bus 단일 인스턴스 — 세션 버스 없으면 조용히 rc=0 종료(첫 게이트 실측) → 버스 붙여 실행
for app in "speedcrunch" "qps" "lxqt-archiver" "lximage-qt $GH/test.png"; do
  bin=${app%% *}; [ -x "$LFS/usr/bin/$bin" ] || continue
  if [ "$bin" = lximage-qt ]; then
    out=$(timeout -k 5 $((SECS+20)) chroot "$LFS" /bin/bash -c "eval \$(dbus-launch --sh-syntax); export $ENVV; timeout $SECS /usr/bin/$app; rc=\$?; kill \$DBUS_SESSION_BUS_PID 2>/dev/null; exit \$rc" 2>&1); rc=$?
  else
    out=$(timeout -k 5 "$SECS" chroot "$LFS" /usr/bin/env $ENVV /usr/bin/$app 2>&1); rc=$?
  fi
  if echo "$out" | grep -q 'buffer overflow'; then echo "  🚨 $bin: FORTIFY 오탐"; fail=1
  elif [ $rc -ne 124 ]; then echo "  🚨 $bin: ${SECS}초 전에 종료 rc=$rc :: $(echo "$out" | tr '
' '|' | cut -c1-200)"; fail=1
  else echo "  ✅ $bin ${SECS}초 생존"; fi
done

[ $fail = 0 ] && { echo "QT_LAUNCH_GATE=PASS"; exit 0; } || { echo "QT_LAUNCH_GATE=FAIL"; exit 1; }
