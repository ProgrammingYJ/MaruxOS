#!/bin/bash
# =============================================================================
# MaruxOS 2.0.0 ARM64 — 데스크톱 config populate v4 (커서 픽스: HW커서 복권)
# -----------------------------------------------------------------------------
# v3 대비 델타 (실기기 라이브 A/B 2026-07-27, TV+1080p60 강제 환경):
#   ① 99-swcursor.conf: SWcursor true → **false (HW커서)** — 실기기 판정: 지지직 재발
#      없음 + SW커서의 깜빡임·딜레이 완치. v8의 "지지직=HW커서" 판정은 당시
#      모니터+auto EDID 환경 한정이었을 가능성 (현재는 cmdline video= 1080p60 강제).
#      TearFree 라인 제거 — xorg-server 21.1 modesetting은 미지원("not used" 경고 확인).
#      ⚠️ 데스크 모니터(EDID 자동)에서 지지직 재발 시: SWcursor true로 롤백 + video= 유지 재검.
#   ② 50-mouse-flat.conf 추가: libinput AccelProfile flat — 커서 1:1 반응(딜레이 체감 개선).
#   ③ 나머지는 v3 동일 (NanumGothic rc.xml, 한국어 시계, firefox.lnk 3아이콘).
# 순수 파일복사+생성 (chroot 불요). root로 실행.
# =============================================================================
set -uo pipefail
B=/home/administrator/MaruxOS-arm64
LFS=$B/rootfs-clfs-arm64
X86=/home/administrator/MaruxOS/build/rootfs-lfs
CFG=/mnt/c/Users/Administrator/Desktop/MaruxOS/config
DZN="/mnt/c/Users/Administrator/Desktop/MaruxOS/MaruxOS 디자인"
[[ "$LFS" == *"MaruxOS-arm64"* ]] || { echo "🚨 ABORT: $LFS"; exit 1; }
[ -d "$LFS/usr" ] || { echo "🚨 ABORT: rootfs 없음"; exit 1; }
[ -e "$LFS/usr/lib/libgtk-3.so.0" ] || { echo "🚨 ABORT: gtk3 없음 (B-2 미완)"; exit 1; }
[ -x "$LFS/opt/firefox/firefox" ] || { echo "🚨 ABORT: Firefox 없음 (B-2 미완)"; exit 1; }
[ -f "$LFS/usr/share/fonts/nanum/NanumGothic-Regular.ttf" ] || { echo "🚨 ABORT: NanumGothic 없음"; exit 1; }

# ---------- 1. PNG 자산 ----------
echo "[1] PNG 자산 이식"
mkdir -p "$LFS/usr/share/pixmaps/maruxos" "$LFS/usr/share/backgrounds"
if [ -d "$X86/usr/share/pixmaps/maruxos" ]; then
  cp -f "$X86/usr/share/pixmaps/maruxos/"*.png "$LFS/usr/share/pixmaps/maruxos/" 2>/dev/null
  echo "  x86 rootfs pixmaps → $(ls "$LFS/usr/share/pixmaps/maruxos/"*.png 2>/dev/null | wc -l)개"
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
  if [ -f "$CFG/scripts/$h" ]; then
    cp -f "$CFG/scripts/$h" "$LFS/usr/bin/$h"; chmod +x "$LFS/usr/bin/$h"; echo "  ✓ $h"
  else echo "  ⚠️ $CFG/scripts/$h 없음"; fi
done

# ---------- 3. .Xdefaults ----------
echo "[3] .Xdefaults"
if [ -f "$CFG/Xresources" ]; then
  cp -f "$CFG/Xresources" "$LFS/etc/X11/Xresources"
  cp -f "$CFG/Xresources" "$LFS/etc/skel/.Xdefaults"
  cp -f "$CFG/Xresources" "$LFS/root/.Xdefaults"
  echo "  ✓ Xresources 3경로"
fi

# ---------- 4. openbox (NanumGothic 원본 유지 — v3 동일) ----------
echo "[4] openbox 메뉴/키바인드"
mkdir -p "$LFS/etc/xdg/openbox"
cp -f "$CFG/openbox/menu.xml" "$LFS/etc/xdg/openbox/menu.xml"
cp -f "$CFG/openbox/rc.xml"   "$LFS/etc/xdg/openbox/rc.xml"
echo "  ✓ menu.xml + rc.xml (NanumGothic)"

# ---------- 5. idesk 3아이콘 (v3 동일) ----------
echo "[5] idesk 아이콘 (terminal+files+firefox)"
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
echo "  ✓ 3아이콘 (skel + root)"

# ---------- 6. tint2rc (v3 동일 — 한국어 시계) ----------
echo "[6] tint2rc (한국어 시계 + hover off)"
mkdir -p "$LFS/etc/xdg/tint2"
if [ -f "$LFS/usr/share/tint2/horizontal-light-opaque.tint2rc" ]; then
  cp -f "$LFS/usr/share/tint2/horizontal-light-opaque.tint2rc" "$LFS/etc/xdg/tint2/tint2rc"
  sed -i \
    -e 's/^time1_format = .*/time1_format = %H:%M/' \
    -e 's/^time2_format = .*/time2_format = %A %d %B/' \
    -e 's/^time1_font = .*/time1_font = DejaVu Sans Bold 11/' \
    -e 's/^time2_font = .*/time2_font = NanumGothic 8/' \
    -e 's/^mouse_effects = 1/mouse_effects = 0/' \
    -e 's/^task_tooltip = 1/task_tooltip = 0/' \
    -e 's/^launcher_tooltip = 1/launcher_tooltip = 0/' \
    -e 's/^battery_tooltip = 1/battery_tooltip = 0/' \
    "$LFS/etc/xdg/tint2/tint2rc"
  echo "  ✓ tint2rc"
else echo "  ⚠️ tint2 샘플 없음"; fi

# ---------- 6b. 커서 설정 — v4 델타: HW커서 복권 ----------
echo "[6b] xorg.conf.d 커서 (HW커서 + flat 가속)"
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
echo "  ✓ 99-swcursor.conf(HW커서) + 50-mouse-flat.conf"

# ---------- 7. full xinitrc (v3 동일) ----------
echo "[7] full xinitrc"
mkdir -p "$LFS/etc/X11/xinit" "$LFS/usr/etc/X11/xinit"
cat > "$LFS/etc/X11/xinit/xinitrc" <<'XINIT'
#!/bin/sh
# MaruxOS 2.0.0 ARM64 X 세션 (x86 패리티). B-2: gtk3+Firefox+한글(XIM+gtk3 immodule).
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

# 한글 입력기 ibus-hangul. ibus-x11(XIM)→xterm 등 X앱, im-ibus.so(gtk3)→Firefox 등 GTK3앱.
# 한영토글: Shift+space 또는 Hangul 키.
if [ -x /usr/bin/ibus-daemon ]; then
  mkdir -p "$XDG_CONFIG_HOME/ibus/bus"
  eval "$(dbus-launch --sh-syntax)"; export DBUS_SESSION_BUS_ADDRESS
  ibus-daemon --xim --panel disable -r -d >/tmp/ibus-daemon.log 2>&1
  sleep 5
  ibus engine hangul >>/tmp/ibus-daemon.log 2>&1 || true
fi

# 네트워크 (부팅 S20network/dhcpcd가 주 담당 — 여기는 폴백)
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

# 패널 (백그라운드)
[ -x /usr/bin/tint2 ] && tint2 &

# 바탕화면 아이콘 (idesk)
if [ -x /usr/bin/idesk ]; then
  [ -f "$HOME/.ideskrc" ]  || cp /etc/skel/.ideskrc  "$HOME/.ideskrc"  2>/dev/null
  [ -d "$HOME/.idesktop" ] || cp -r /etc/skel/.idesktop "$HOME/.idesktop" 2>/dev/null
  mkdir -p "$HOME/Desktop"
  [ -x /usr/bin/marux-desktop-refresh ] && /usr/bin/marux-desktop-refresh --quiet 2>/dev/null
  idesk &
fi

# Plank / systray (존재 시 — 현재 없음)
[ -x /usr/bin/plank ] && /usr/bin/plank 2>/dev/null &
[ -x /usr/bin/nm-applet ] && /usr/bin/nm-applet 2>/dev/null &
[ -x /usr/bin/volumeicon ] && /usr/bin/volumeicon 2>/dev/null &

# WM = 세션 리더 (foreground). openbox 종료 = 세션 종료.
# ⚠️ X 종료는 우클릭 메뉴 Exit로 — 세션 어중간히 죽으면 DRM master 잔류 → 다음 startx 실패.
exec openbox
XINIT
chmod +x "$LFS/etc/X11/xinit/xinitrc"
cp -f "$LFS/etc/X11/xinit/xinitrc" "$LFS/root/.xinitrc"
cp -f "$LFS/etc/X11/xinit/xinitrc" "$LFS/etc/skel/.xinitrc"
cp -f "$LFS/etc/X11/xinit/xinitrc" "$LFS/usr/etc/X11/xinit/xinitrc"
echo "  ✓ xinitrc 4경로"
rm -f "$LFS/root/.config/tint2/tint2rc" 2>/dev/null || true

# ---------- 검증 ----------
echo "===== config populate v4 완료 ====="
echo "  커서       : $(grep -o '"SWcursor" "false"' "$LFS/etc/X11/xorg.conf.d/99-swcursor.conf" 2>/dev/null && echo HW커서) + $([ -f "$LFS/etc/X11/xorg.conf.d/50-mouse-flat.conf" ] && echo flat가속)"
echo "  xinitrc    : $(for p in "$LFS/etc/X11/xinit/xinitrc" "$LFS/root/.xinitrc" "$LFS/etc/skel/.xinitrc" "$LFS/usr/etc/X11/xinit/xinitrc"; do [ -f "$p" ] && echo -n "O" || echo -n "X"; done) (4경로)"
echo "  idesk lnk  : $(ls "$LFS/etc/skel/.idesktop/"*.lnk 2>/dev/null | wc -l)개"
echo "  tint2 시계 : $(grep '^time2_format' "$LFS/etc/xdg/tint2/tint2rc" 2>/dev/null)"
echo "  rc.xml     : NanumGothic=$(grep -c NanumGothic "$LFS/etc/xdg/openbox/rc.xml" 2>/dev/null)"
