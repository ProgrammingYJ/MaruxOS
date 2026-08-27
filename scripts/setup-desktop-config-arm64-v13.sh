#!/bin/bash
# =============================================================================
# MaruxOS 2.0.0 ARM64 — 데스크톱 config populate v13 (자동 로그인 + X 자동 기동)
# -----------------------------------------------------------------------------
# v12 대비 델타 (2026-08-26, 8/27 출품 직전 — "진짜 운영체제처럼 부팅하면 바로 화면"):
#   ① **tty1 자동 로그인**: inittab의 tty1 getty에 `--autologin root` (util-linux agetty 2.39.3 지원 실측).
#      ttyS0 시리얼 getty는 그대로 = 디버깅 통로 유지 (자동 로그인은 tty1만).
#   ② **X 자동 기동**: /root/.bash_profile(+/etc/skel) — 로그인 셸이 tty1이고 DISPLAY이 없으면 `startx`.
#      exec가 아니라 일반 호출 → X가 죽거나 로그아웃하면 tty1 셸로 떨어져 디버깅 가능(자동 재기동 루프 없음).
#      로그아웃 시 agetty가 respawn → 자동 로그인 → startx = 디스플레이 매니저와 동일한 체감.
#   ③ 멱등: inittab sed는 원본 줄 패턴에만 매치, .bash_profile은 통째로 재작성.
#   나머지는 v12 동일.
# (v12 델타 — 이력)
# v11 대비 델타 (2026-08-25, 배치 F 완주 — 2.0.0 로드맵 4번 = 마지막):
#   ① **기본 파일관리자를 pcmanfm-qt로 교체** — .desktop/dockitem/openbox 메뉴/idesk 아이콘.
#      mc는 **제거하지 않고 잔류**(터미널 파일관리 용도 + 폴백). 1.x의 PCManFM(GTK) 사고
#      (GLib 2.68 요구 → glibc 덮어쓰기 참사)를 Qt 경로로 정공 해소한 것이 이 교체의 의미.
#   ② 독 구성: qterminal · pcmanfm-qt · firefox (3종).
#   나머지는 v11 동일 (Qt 런타임 환경변수, 통합 상태 바, 볼륨 부트스트랩, picom, keyfile).
# 실행 전제: .p-COMPLETE + .p2-COMPLETE (+libwnck 43.2 — v17 게이트는 빌드 스크립트가 강제).
# =============================================================================
set -uo pipefail
B=/home/administrator/MaruxOS-arm64
LFS=$B/rootfs-clfs-arm64
X86=/home/administrator/MaruxOS/build/rootfs-lfs
CFG=/mnt/c/Users/Administrator/Desktop/MaruxOS/config
DZN="/mnt/c/Users/Administrator/Desktop/MaruxOS/MaruxOS 디자인"
[[ "$LFS" == *"MaruxOS-arm64"* ]] || { echo "🚨 ABORT: $LFS"; exit 1; }
[ -d "$LFS/usr" ] || { echo "🚨 ABORT: rootfs 없음"; exit 1; }
[ -e "$LFS/usr/lib/libgtk-3.so.0" ] || { echo "🚨 ABORT: gtk3 없음"; exit 1; }
[ -x "$LFS/opt/firefox/firefox" ] || { echo "🚨 ABORT: Firefox 없음"; exit 1; }
[ -f "$LFS/usr/share/fonts/nanum/NanumGothic-Regular.ttf" ] || { echo "🚨 ABORT: NanumGothic 없음"; exit 1; }
[ -f "$LFS/usr/share/fonts/nanum/NanumGothic-Bold.ttf" ] || { echo "🚨 ABORT: NanumGothic-Bold 없음(플로팅 시계 폰트)"; exit 1; }
# 배치 P/P2 게이트
[ -f "$LFS/sources/.p-COMPLETE" ] || { echo "🚨 ABORT: Plank 빌드 미완(.p-COMPLETE 없음)"; exit 1; }
[ -f "$LFS/sources/.p2-COMPLETE" ] || { echo "🚨 ABORT: P2(폴리시) 미완(.p2-COMPLETE 없음)"; exit 1; }
[ -x "$LFS/usr/bin/plank" ] || { echo "🚨 ABORT: plank 바이너리 없음"; exit 1; }
[ -x "$LFS/usr/bin/picom" ] || { echo "🚨 ABORT: picom 없음"; exit 1; }
[ -x "$LFS/usr/bin/qterminal" ] || { echo "🚨 ABORT: qterminal 없음(배치 Q 미완)"; exit 1; }
[ -x "$LFS/usr/bin/pcmanfm-qt" ] || { echo "🚨 ABORT: pcmanfm-qt 없음(배치 F 미완)"; exit 1; }
[ -f "$CFG/applications/pcmanfm-qt.desktop" ] || { echo "🚨 ABORT: pcmanfm-qt.desktop 자산 없음"; exit 1; }
[ -f "$CFG/applications/qterminal.desktop" ] || { echo "🚨 ABORT: qterminal.desktop 자산 없음"; exit 1; }
[ -f "$LFS/usr/share/plank/themes/Marux/dock.theme" ] || { echo "🚨 ABORT: Marux 테마 없음"; exit 1; }
[ -f "$LFS/usr/share/glib-2.0/schemas/40_maruxos.gschema.override" ] || { echo "🚨 ABORT: gschema.override 없음"; exit 1; }
for d in xterm mc firefox; do
  [ -f "$CFG/applications/$d.desktop" ] || { echo "🚨 ABORT: $d.desktop 자산 없음"; exit 1; }
  [ -f "$CFG/plank/dock1/launchers/$d.dockitem" ] || { echo "🚨 ABORT: $d.dockitem 자산 없음"; exit 1; }
done

# ---------- 1. PNG 자산 ----------
echo "[1] PNG 자산 이식"
mkdir -p "$LFS/usr/share/pixmaps/maruxos" "$LFS/usr/share/backgrounds"
if [ -d "$X86/usr/share/pixmaps/maruxos" ]; then
  cp -f "$X86/usr/share/pixmaps/maruxos/"*.png "$LFS/usr/share/pixmaps/maruxos/" 2>/dev/null
fi
if [ -f "$X86/usr/share/backgrounds/marux-desktop.png" ]; then
  cp -f "$X86/usr/share/backgrounds/marux-desktop.png" "$LFS/usr/share/backgrounds/"
elif [ -f "$DZN/marux-desktop.png" ]; then
  cp -f "$DZN/marux-desktop.png" "$LFS/usr/share/backgrounds/"
fi
[ -f "$LFS/usr/share/backgrounds/marux-desktop.png" ] && cp -f "$LFS/usr/share/backgrounds/marux-desktop.png" "$LFS/usr/share/pixmaps/maruxos/" 2>/dev/null || true

# ---------- 2. 헬퍼 3종 ----------
echo "[2] 헬퍼 스크립트 이식"
for h in marux-wallpaper marux-new-desktop-item marux-desktop-refresh; do
  [ -f "$CFG/scripts/$h" ] && { cp -f "$CFG/scripts/$h" "$LFS/usr/bin/$h"; chmod +x "$LFS/usr/bin/$h"; }
done

# ---------- 3. .Xdefaults ----------
echo "[3] .Xdefaults"
if [ -f "$CFG/Xresources" ]; then
  cp -f "$CFG/Xresources" "$LFS/etc/X11/Xresources"
  cp -f "$CFG/Xresources" "$LFS/etc/skel/.Xdefaults"
  cp -f "$CFG/Xresources" "$LFS/root/.Xdefaults"
fi

# ---------- 4. openbox ----------
echo "[4] openbox 메뉴/키바인드"
mkdir -p "$LFS/etc/xdg/openbox"
cp -f "$CFG/openbox/menu.xml" "$LFS/etc/xdg/openbox/menu.xml"
cp -f "$CFG/openbox/rc.xml"   "$LFS/etc/xdg/openbox/rc.xml"

# ---------- 5. .desktop 3종 (plank .dockitem 참조 대상 — v5 신규) ----------
echo "[5] applications .desktop 3종"
mkdir -p "$LFS/usr/share/applications"
for d in xterm mc firefox qterminal pcmanfm-qt; do
  cp -f "$CFG/applications/$d.desktop" "$LFS/usr/share/applications/$d.desktop"
done
echo "  ✓ xterm/mc/firefox/qterminal/pcmanfm-qt.desktop"

# ---------- 5b. plank 독 설정 (launchers만 — settings 키파일은 안 읽힘) ----------
echo "[5b] plank dock1/launchers (skel + root)"
mkdir -p "$LFS/etc/skel/.config/plank/dock1/launchers" "$LFS/root/.config/plank/dock1/launchers"
# 독 구성: qterminal(기본 터미널) + mc + firefox. xterm은 독에서 내리되 실행은 가능.
for d in qterminal pcmanfm-qt firefox; do
  cp -f "$CFG/plank/dock1/launchers/$d.dockitem" "$LFS/etc/skel/.config/plank/dock1/launchers/"
  cp -f "$CFG/plank/dock1/launchers/$d.dockitem" "$LFS/root/.config/plank/dock1/launchers/"
done
rm -f "$LFS/etc/skel/.config/plank/dock1/launchers/xterm.dockitem"       "$LFS/root/.config/plank/dock1/launchers/xterm.dockitem"       "$LFS/etc/skel/.config/plank/dock1/launchers/mc.dockitem"       "$LFS/root/.config/plank/dock1/launchers/mc.dockitem" 2>/dev/null || true
echo "  ✓ 3 dockitem × 2경로 (터미널=qterminal, 파일=pcmanfm-qt)"

# ---------- 5c. idesk 3아이콘 (v4 동일 — 데스크톱 아이콘은 유지) ----------
echo "[5c] idesk 아이콘"
mkdir -p "$LFS/etc/skel/.idesktop" "$LFS/root/.idesktop"
cat > "$LFS/etc/skel/.ideskrc" <<'IDESKRC'
table Config
  FontName: DejaVu Sans
  FontSize: 10
  FontColor: #FFFFFF
  Locked: false
  Transparency: 150
  Shadow: true
  ShadowColor: #000000
  ShadowX: 1
  ShadowY: 2
  Bold: false
  ClickDelay: 300
  IconSnap: true
  SnapWidth: 80
  SnapHeight: 80
  SnapOrigin: BottomRight
  SnapShadow: true
  SnapShadowTrans: 200
  CaptionOnHover: false
  CaptionPlacement: Bottom
  FillStyle: None
  Background.Delay: 0
  Background.Source: None
  Background.File: None
  Background.Mode: Scale
  Background.Color: #000000
end
table Actions
  Lock: control right
  Reload: middle
  Drag: left
  EndDrag: left
  Execute[0]: left doubleClk
  Execute[1]: right
end
IDESKRC
cat > "$LFS/etc/skel/.idesktop/terminal.lnk" <<'LNK'
table Icon
  Caption: Terminal
  Command: qterminal
  Icon: /usr/share/pixmaps/maruxos/marux-terminal.png
  X: 80
  Y: 80
  Width: 48
  Height: 48
end
LNK
cat > "$LFS/etc/skel/.idesktop/filemanager.lnk" <<'LNK'
table Icon
  Caption: Files
  Command: pcmanfm-qt
  Icon: /usr/share/pixmaps/maruxos/marux-file-manager.png
  X: 80
  Y: 180
  Width: 48
  Height: 48
end
LNK
cat > "$LFS/etc/skel/.idesktop/firefox.lnk" <<'LNK'
table Icon
  Caption: Firefox
  Command: /usr/bin/firefox
  Icon: /opt/firefox/browser/chrome/icons/default/default128.png
  X: 80
  Y: 280
  Width: 48
  Height: 48
end
LNK
cp -f "$LFS/etc/skel/.ideskrc" "$LFS/root/.ideskrc"
cp -f "$LFS/etc/skel/.idesktop/"*.lnk "$LFS/root/.idesktop/"

# ---------- 6. (삭제) tint2 — v10에서 은퇴. 시계는 통합 상태 바가 담당 ----------
echo "[6] tint2 은퇴 — 배포/기동 없음 (시계는 marux-quicksettings 통합 바)"
rm -f "$LFS/etc/xdg/tint2/tint2rc" 2>/dev/null || true

# ---------- 6b. 커서 (v4 동일 — HW커서 + flat) ----------
echo "[6b] xorg.conf.d 커서"
mkdir -p "$LFS/etc/X11/xorg.conf.d"
cat > "$LFS/etc/X11/xorg.conf.d/99-swcursor.conf" <<'XORGCONF'
Section "Device"
    Identifier "card0"
    Driver "modesetting"
    Option "SWcursor" "false"
EndSection
XORGCONF
cat > "$LFS/etc/X11/xorg.conf.d/50-mouse-flat.conf" <<'XORGCONF'
Section "InputClass"
    Identifier "flat pointer accel"
    MatchIsPointer "on"
    Driver "libinput"
    Option "AccelProfile" "flat"
EndSection
XORGCONF

# ---------- 7. full xinitrc — v10: tint2 없음 (통합 상태 바가 시계 담당) ----------
echo "[7] full xinitrc (keyfile GSettings + plank)"
mkdir -p "$LFS/etc/X11/xinit" "$LFS/usr/etc/X11/xinit"
cat > "$LFS/etc/X11/xinit/xinitrc" <<'XINIT'
#!/bin/sh
# MaruxOS 2.0.0 ARM64 X 세션. 배치 P: Plank dock + GSettings keyfile 백엔드.
# XDG / locale
export XDG_RUNTIME_DIR=/tmp/runtime-$(id -u)
mkdir -p "$XDG_RUNTIME_DIR"; chmod 700 "$XDG_RUNTIME_DIR"
export XDG_SESSION_TYPE=x11 XDG_SESSION_CLASS=user
export XDG_SESSION_DESKTOP=MaruxOS XDG_CURRENT_DESKTOP=MaruxOS DESKTOP_SESSION=MaruxOS
export XDG_DATA_DIRS=/usr/local/share:/usr/share XDG_CONFIG_DIRS=/etc/xdg
export XDG_CONFIG_HOME="$HOME/.config"
export LANG=ko_KR.UTF-8 LC_ALL=ko_KR.UTF-8
export GTK_IM_MODULE=ibus QT_IM_MODULE=ibus XMODIFIERS=@im=ibus
export GTK_THEME=Adwaita
# Qt5 런타임: 플랫폼 플러그인 경로 명시(못 찾으면 Qt 앱이 기동 실패한다)
export QT_QPA_PLATFORM_PLUGIN_PATH=/usr/plugins/platforms
export QT_QPA_PLATFORM=xcb
# GSettings: memory(비영속·프로세스별) → keyfile(영속·공유, ~/.config/glib-2.0/settings/keyfile)
# plank dock-items 등 GSettings 값이 세션 간 유지됨. 기본값은 gschema.override가 공급.
export GSETTINGS_BACKEND=keyfile

# 한글 입력기 ibus-hangul (XIM + gtk3 immodule). 토글 = Shift+Space.
if [ -x /usr/bin/ibus-daemon ]; then
  mkdir -p "$XDG_CONFIG_HOME/ibus/bus"
  eval "$(dbus-launch --sh-syntax)"; export DBUS_SESSION_BUS_ADDRESS
  ibus-daemon --xim --panel disable -r -d >/tmp/ibus-daemon.log 2>&1
  sleep 5
  ibus engine hangul >>/tmp/ibus-daemon.log 2>&1 || true
fi

# 네트워크 (부팅 S20network/dhcpcd가 주 담당 — 폴백)
for iface in /sys/class/net/*; do
  n=$(basename "$iface"); [ "$n" = "lo" ] && continue
  ip link set "$n" up 2>/dev/null
  [ -x /usr/sbin/dhcpcd ] && /usr/sbin/dhcpcd "$n" >/dev/null 2>&1 &
done

# 배경화면 (feh)
if [ -x /usr/bin/feh ]; then
  for bg in /usr/share/backgrounds/marux-desktop.png /usr/share/pixmaps/maruxos/marux-desktop.png; do
    [ -f "$bg" ] && { feh --bg-scale "$bg" 2>/dev/null; break; }
  done
fi

# 커널 콘솔 스팸 차단 (vc4 HDMI RGB 경고 등 — syslog엔 계속 기록. v15 실기기 침수 픽스)
dmesg -n 1 2>/dev/null

# 컴포지터 picom (배치 P2 — plank 반투명·라운드·줌 + 플로팅 시계 라운드의 전제)
[ -x /usr/bin/picom ] && picom -b --config /etc/xdg/picom.conf >/tmp/picom.log 2>&1

# bamf 창매칭 데몬 명시 기동 (독 실행중 점 표시. D-Bus runner=우분투 전용이라 직접 기동)
[ -x /usr/libexec/bamf/bamfdaemon ] && /usr/libexec/bamf/bamfdaemon >/tmp/bamf.log 2>&1 &

# Plank dock (배치 P — bottom center launcher+taskbar. picom 있으면 Marux 반투명 발현)
if [ -x /usr/bin/plank ]; then
  [ -d "$HOME/.config/plank" ] || cp -r /etc/skel/.config/plank "$HOME/.config/plank" 2>/dev/null
  /usr/bin/plank >/tmp/plank.log 2>&1 &
  sleep 0.3
fi

# 볼륨 컨트롤 부트스트랩 — asound.conf softvol의 "Master"는 첫 재생 때 생성된다.
# 무음 1초를 흘려 컨트롤을 미리 만들어야 퀵설정 슬라이더가 처음부터 동작 (v19 실기기 피드백).
[ -x /usr/bin/aplay ] && (aplay -q -f S16_LE -r 44100 -c 2 -d 1 /dev/zero >/dev/null 2>&1 &)

# 퀵설정 (배치 W — 우상단 인디케이터/드롭다운: WiFi+볼륨. wlan0 없어도 무해)
[ -x /usr/bin/marux-quicksettings ] && /usr/bin/marux-quicksettings >/tmp/quicksettings.log 2>&1 &

# 바탕화면 아이콘 (idesk)
if [ -x /usr/bin/idesk ]; then
  [ -f "$HOME/.ideskrc" ]  || cp /etc/skel/.ideskrc  "$HOME/.ideskrc"  2>/dev/null
  [ -d "$HOME/.idesktop" ] || cp -r /etc/skel/.idesktop "$HOME/.idesktop" 2>/dev/null
  mkdir -p "$HOME/Desktop"
  [ -x /usr/bin/marux-desktop-refresh ] && /usr/bin/marux-desktop-refresh --quiet 2>/dev/null
  idesk &
fi

# WM = 세션 리더 (foreground). openbox 종료 = 세션 종료.
# ⚠️ X 종료는 우클릭 메뉴 Exit로 — 어중간히 죽으면 DRM master 잔류 → 다음 startx 실패.
exec openbox
XINIT
chmod +x "$LFS/etc/X11/xinit/xinitrc"
cp -f "$LFS/etc/X11/xinit/xinitrc" "$LFS/root/.xinitrc"
cp -f "$LFS/etc/X11/xinit/xinitrc" "$LFS/etc/skel/.xinitrc"
cp -f "$LFS/etc/X11/xinit/xinitrc" "$LFS/usr/etc/X11/xinit/xinitrc"
# tint2rc 홈 캐시 제거 (우선순위 함정 — 새 플로팅 rc 강제)
rm -f "$LFS/root/.config/tint2/tint2rc" 2>/dev/null || true
# keyfile 백엔드 홈 잔재 클린 (이전 세션 실험값 제거 — 기본값=override가 공급)
rm -f "$LFS/root/.config/glib-2.0/settings/keyfile" 2>/dev/null || true

# ---------- 8. 자동 로그인 + X 자동 기동 (v13) ----------
echo "[8] tty1 자동 로그인 + startx"
INITTAB="$LFS/etc/inittab"
[ -f "$INITTAB" ] || { echo "🚨 ABORT: inittab 없음"; exit 1; }
grep -q '^1:2345:respawn:/sbin/agetty --autologin root --noclear tty1 9600$' "$INITTAB"   || sed -i 's|^1:2345:respawn:/sbin/agetty --noclear tty1 9600$|1:2345:respawn:/sbin/agetty --autologin root --noclear tty1 9600|' "$INITTAB"
grep -q '^1:2345:respawn:/sbin/agetty --autologin root --noclear tty1 9600$' "$INITTAB" || { echo "🚨 ABORT: inittab tty1 autologin 패치 실패(원본 줄 패턴 불일치?)"; grep -n tty1 "$INITTAB"; exit 1; }
grep -q 'agetty.*ttyS0' "$INITTAB" || echo "  (참고) ttyS0 getty는 이미지 빌드 [5b]가 보강"
# (주의) `strings | grep -q` 는 set -o pipefail 아래서 grep이 먼저 닫아 strings가 SIGPIPE(141) → 거짓 실패. 파이프 없이 검사.
grep -a -q 'autologin' "$LFS/sbin/agetty" || { echo "🚨 ABORT: agetty가 --autologin 미지원"; exit 1; }
cat > "$LFS/root/.bash_profile" <<'BPROF'
# MaruxOS: tty1 자동 로그인 후 X 자동 기동 (2.0.0, config v13, 2026-08-26)
# - 로그인 셸이 tty1이고 X가 없으면 startx. 시리얼(ttyS0)/기타 tty는 해당 없음.
# - exec가 아니므로 X 종료/실패 시 이 셸로 돌아온다(디버깅 가능). 로그아웃하면 agetty가 다시 자동 로그인 → X.
[ -f ~/.bashrc ] && . ~/.bashrc
if [ -z "$DISPLAY" ] && [ "$(tty 2>/dev/null)" = /dev/tty1 ] && [ -x /usr/bin/startx ]; then
  startx
  echo "[MaruxOS] X 세션 종료 — 'startx'로 재시작하거나 로그아웃(exit)하면 자동 재로그인됩니다"
fi
BPROF
cp -f "$LFS/root/.bash_profile" "$LFS/etc/skel/.bash_profile"
bash -n "$LFS/root/.bash_profile" || { echo "🚨 ABORT: .bash_profile 문법"; exit 1; }
echo "  ✓ inittab tty1 autologin + .bash_profile(root, skel)"

# ---------- 검증 ----------
echo "===== config populate v13 완료 ====="
echo "  자동로그인  : $(grep -c 'autologin root' "$LFS/etc/inittab") / startx프로필: $(grep -c '^  startx' "$LFS/root/.bash_profile")"
echo "  keyfile백엔드: $(grep -c 'GSETTINGS_BACKEND=keyfile' "$LFS/etc/X11/xinit/xinitrc")"
echo "  plank 블록  : $(grep -c '/usr/bin/plank' "$LFS/etc/X11/xinit/xinitrc")"
echo "  .desktop    : $(ls "$LFS/usr/share/applications/"{xterm,mc,firefox,qterminal,pcmanfm-qt}.desktop 2>/dev/null | wc -l)/5"
echo "  dockitem    : $(ls "$LFS/root/.config/plank/dock1/launchers/"*.dockitem 2>/dev/null | wc -l)/3"
echo "  tint2       : $([ -f "$LFS/etc/xdg/tint2/tint2rc" ] && echo "잔존(비정상)" || echo "은퇴 ✓")"
echo "  통합상태바  : $(grep -c 'marux-quicksettings' "$LFS/etc/X11/xinit/xinitrc")"
echo "  Qt 앱       : qterminal $([ -x "$LFS/usr/bin/qterminal" ] && echo ✓ || echo ❌) / pcmanfm-qt $([ -x "$LFS/usr/bin/pcmanfm-qt" ] && echo ✓ || echo ❌) / 플러그인경로 $(grep -c QT_QPA_PLATFORM_PLUGIN_PATH "$LFS/etc/X11/xinit/xinitrc")"
echo "  xinitrc 4경로: $(for p in "$LFS/etc/X11/xinit/xinitrc" "$LFS/root/.xinitrc" "$LFS/etc/skel/.xinitrc" "$LFS/usr/etc/X11/xinit/xinitrc"; do [ -f "$p" ] && echo -n O || echo -n X; done)"
