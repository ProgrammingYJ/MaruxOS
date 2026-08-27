#!/bin/bash
# =============================================================================
# MaruxOS 2.0.0 ARM64 — 데스크톱 config populate v5 (배치 P: Plank dock)
# -----------------------------------------------------------------------------
# v4 대비 델타 (x86 v3~v7 부검 결론 반영 — ARM64-Update-Log 2026-07-27 배치 P):
#   ① xinitrc에 **GSETTINGS_BACKEND=keyfile** export — memconf(memory)=프로세스별·
#      비영속이 v7 "빈 독"의 근본원인. keyfile(GLib≥2.60)로 영속+프로세스간 공유.
#   ② .desktop 3종(xterm/mc/firefox) → /usr/share/applications/ 배포 — plank
#      .dockitem의 Launcher가 참조 (x86 자산 그대로, 경로 전부 ARM64 유효 확인).
#   ③ config/plank/dock1/launchers/*.dockitem → skel+root 배포. ⚠️dock1/settings
#      키파일은 배포 안 함 — plank는 파일 설정 안 읽음(순수 GSettings, 부검 확정).
#      설정값은 install-plank-arm64.sh의 40_maruxos.gschema.override가 담당.
#   ④ xinitrc plank 블록 풀버전(x86 스타일: skel→home 시드 + 기동) — 기존 한 줄
#      가드 대체. plank 존재 시 tint2는 systray-only로 (⑤).
#   ⑤ tint2rc-systray(x86 v7 검증자산) 배포 — plank(bottom center)와 공존하는
#      bottom right systray+clock. 1.x 전용 execp 헬퍼 3종은 ARM64에 없음 → panel_items
#      ESC→SC sed(빈 executor 방지). 시계 폰트 NanumGothic 명시.
#   나머지는 v4 동일 (HW커서, flat 가속, NanumGothic, 한국어 시계, idesk 3아이콘).
# 실행 전제: install-plank-arm64.sh 완료(.p-COMPLETE — plank/override 설치됨).
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
# 배치 P 게이트
[ -f "$LFS/sources/.p-COMPLETE" ] || { echo "🚨 ABORT: Plank 빌드 미완(.p-COMPLETE 없음)"; exit 1; }
[ -x "$LFS/usr/bin/plank" ] || { echo "🚨 ABORT: plank 바이너리 없음"; exit 1; }
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
sed -i \
  -e 's/^panel_items = .*/panel_items = SC/' \
  -e 's/^time1_font = .*/time1_font = DejaVu Sans Bold 11/' \
  -e 's/^time2_font = .*/time2_font = NanumGothic 8/' \
  "$LFS/etc/xdg/tint2/tint2rc"
echo "  ✓ tint2rc (systray+clock only, panel_items=SC)"

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

# Plank dock (배치 P — bottom center launcher+taskbar. 비컴포지트 환경 = 불투명 모드 정상)
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
