#!/bin/bash
# =============================================================================
# MaruxOS 2.0.0 ARM64 — 데스크톱 config populate v8 (v16 실기기 세션 확정값: 시계 clock-only)
# -----------------------------------------------------------------------------
# v6 대비 델타 (2026-07-29 라이브픽스 실기기 검증 — 사용자 "창전환 유리 룩 다 됨"):
#   ① rc.xml — 레포 원본에 **Client 컨텍스트 마우스바인드** 추가됨(클릭 창전환.
#      x86 시절부터 잠복, 첫 창겹침 테스트서 발각. 레포 복사라 자동 반영).
#   ② xinitrc **bamfdaemon 명시 기동** (plank 앞) — D-Bus 자동기동 runner가
#      우분투 전용(UPSTART/systemctl 참조)이라 sysvinit서 침묵 실패 → 우회.
#   ③ xinitrc **dmesg -n 1** — vc4 HDMI RGB 경고 등 커널 콘솔 스팸이 X 세션/시리얼
#      침수시키는 것 차단 (syslog엔 계속 기록됨).
#   나머지는 v6 동일 (picom, panel 200, keyfile, HW커서 등).
# 실행 전제: .p-COMPLETE + .p2-COMPLETE (+wnck SN 재빌드 완료).
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
# 배치 P/P2 게이트
[ -f "$LFS/sources/.p-COMPLETE" ] || { echo "🚨 ABORT: Plank 빌드 미완(.p-COMPLETE 없음)"; exit 1; }
[ -f "$LFS/sources/.p2-COMPLETE" ] || { echo "🚨 ABORT: P2(폴리시) 미완(.p2-COMPLETE 없음)"; exit 1; }
[ -x "$LFS/usr/bin/plank" ] || { echo "🚨 ABORT: plank 바이너리 없음"; exit 1; }
[ -x "$LFS/usr/bin/picom" ] || { echo "🚨 ABORT: picom 없음"; exit 1; }
[ -f "$LFS/usr/share/plank/themes/Marux/dock.theme" ] || { echo "🚨 ABORT: Marux 테마 없음"; exit 1; }
[ -f "$LFS/usr/share/glib-2.0/schemas/40_maruxos.gschema.override" ] || { echo "🚨 ABORT: gschema.override 없음"; exit 1; }
[ -f "$CFG/tint2/tint2rc-systray" ] || { echo "🚨 ABORT: tint2rc-systray 자산 없음"; exit 1; }
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
for d in xterm mc firefox; do
  cp -f "$CFG/applications/$d.desktop" "$LFS/usr/share/applications/$d.desktop"
done
echo "  ✓ xterm/mc/firefox.desktop"

# ---------- 5b. plank 독 설정 (launchers만 — settings 키파일은 안 읽힘) ----------
echo "[5b] plank dock1/launchers (skel + root)"
mkdir -p "$LFS/etc/skel/.config/plank/dock1/launchers" "$LFS/root/.config/plank/dock1/launchers"
for d in xterm mc firefox; do
  cp -f "$CFG/plank/dock1/launchers/$d.dockitem" "$LFS/etc/skel/.config/plank/dock1/launchers/"
  cp -f "$CFG/plank/dock1/launchers/$d.dockitem" "$LFS/root/.config/plank/dock1/launchers/"
done
echo "  ✓ 3 dockitem × 2경로"

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
  Command: xterm -fa 'Monospace' -fs 11
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
  Command: xterm -e mc ~ /
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

# ---------- 6. tint2 — v5: plank 공존용 systray-only (x86 v7 검증자산 + ARM64 sed) ----------
echo "[6] tint2rc-systray (plank 공존: bottom-right systray+clock)"
mkdir -p "$LFS/etc/xdg/tint2"
cp -f "$CFG/tint2/tint2rc-systray" "$LFS/etc/xdg/tint2/tint2rc"
# ARM64엔 1.x execp 헬퍼(tint2-network-icon 등) 없음 → executor 제거(E), 시계 폰트 명시
# v6: panel_size 360→200 — 트레이 빈 상태서 시계 왼쪽 치우침 픽스(v14 실기기 사진)
sed -i \
  -e 's/^panel_items = .*/panel_items = C/' \
  -e 's/^panel_size = .*/panel_size = 100 36/' \
  -e 's/^time1_font = .*/time1_font = DejaVu Sans Bold 11/' \
  -e 's/^time2_font = .*/time2_font = NanumGothic 8/' \
  "$LFS/etc/xdg/tint2/tint2rc"
echo "  ✓ tint2rc (systray+clock, panel_size=200)"

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

# ---------- 7. full xinitrc — v5: keyfile 백엔드 + plank 풀블록 ----------
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

# 컴포지터 picom (배치 P2 — plank 반투명·라운드·줌의 전제. 미니멀 conf: vsync만)
[ -x /usr/bin/picom ] && picom -b --config /etc/xdg/picom.conf >/tmp/picom.log 2>&1

# bamf 창매칭 데몬 명시 기동 (독 실행중 점 표시. D-Bus runner=우분투 전용이라 직접 기동)
[ -x /usr/libexec/bamf/bamfdaemon ] && /usr/libexec/bamf/bamfdaemon >/tmp/bamf.log 2>&1 &

# Plank dock (배치 P — bottom center launcher+taskbar. picom 있으면 Marux 반투명 발현)
if [ -x /usr/bin/plank ]; then
  [ -d "$HOME/.config/plank" ] || cp -r /etc/skel/.config/plank "$HOME/.config/plank" 2>/dev/null
  /usr/bin/plank >/tmp/plank.log 2>&1 &
  sleep 0.3
fi

# 패널 tint2 (plank 공존: systray+clock only, bottom right)
[ -x /usr/bin/tint2 ] && tint2 &

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
# tint2rc 홈 캐시 제거 (우선순위 함정 — 새 systray rc 강제)
rm -f "$LFS/root/.config/tint2/tint2rc" 2>/dev/null || true
# keyfile 백엔드 홈 잔재 클린 (이전 세션 실험값 제거 — 기본값=override가 공급)
rm -f "$LFS/root/.config/glib-2.0/settings/keyfile" 2>/dev/null || true

# ---------- 검증 ----------
echo "===== config populate v5 완료 ====="
echo "  keyfile백엔드: $(grep -c 'GSETTINGS_BACKEND=keyfile' "$LFS/etc/X11/xinit/xinitrc")"
echo "  plank 블록  : $(grep -c '/usr/bin/plank' "$LFS/etc/X11/xinit/xinitrc")"
echo "  .desktop    : $(ls "$LFS/usr/share/applications/"{xterm,mc,firefox}.desktop 2>/dev/null | wc -l)/3"
echo "  dockitem    : $(ls "$LFS/root/.config/plank/dock1/launchers/"*.dockitem 2>/dev/null | wc -l)/3"
echo "  tint2       : $(grep '^panel_items' "$LFS/etc/xdg/tint2/tint2rc")"
echo "  xinitrc 4경로: $(for p in "$LFS/etc/X11/xinit/xinitrc" "$LFS/root/.xinitrc" "$LFS/etc/skel/.xinitrc" "$LFS/usr/etc/X11/xinit/xinitrc"; do [ -f "$p" ] && echo -n O || echo -n X; done)"
