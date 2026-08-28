#!/bin/bash
# =============================================================================
# MaruxOS 2.0.0 ARM64 — 데스크톱 config populate v2 (x86_64 패리티)
# -----------------------------------------------------------------------------
# v1(setup-desktop-config-arm64.sh)은 openbox+tint2 코어만. v2는 x86 최신버전 이식:
#   PNG 자산(배경/아이콘) + idesk 2아이콘(terminal/files) + 헬퍼 3종 +
#   openbox 풀메뉴/키바인드(W-t/W-e/W-d) + .Xdefaults(xterm) + full xinitrc(feh배경+network).
# firefox/ibus/NanumGothic은 배치 B(gtk3 Pi 네이티브 후). 여기선 가드로 안전 스킵.
# 순수 파일복사+생성 (chroot 불요). root로 실행. 성공기준: xinitrc 4경로 + menu + PNG.
# =============================================================================
set -uo pipefail
B=/home/administrator/MaruxOS-arm64
LFS=$B/rootfs-clfs-arm64
X86=/home/administrator/MaruxOS/build/rootfs-lfs
CFG=/mnt/c/Users/Administrator/Desktop/MaruxOS/config
DZN="/mnt/c/Users/Administrator/Desktop/MaruxOS/MaruxOS 디자인"
[[ "$LFS" == *"MaruxOS-arm64"* ]] || { echo "🚨 ABORT: $LFS"; exit 1; }
[ -d "$LFS/usr" ] || { echo "🚨 ABORT: rootfs 없음"; exit 1; }

# ---------- 1. PNG 자산 (배경화면 + 아이콘) ----------
echo "[1] PNG 자산 이식"
mkdir -p "$LFS/usr/share/pixmaps/maruxos" "$LFS/usr/share/backgrounds"
if [ -d "$X86/usr/share/pixmaps/maruxos" ]; then
  cp -f "$X86/usr/share/pixmaps/maruxos/"*.png "$LFS/usr/share/pixmaps/maruxos/" 2>/dev/null
  echo "  x86 rootfs pixmaps → $(ls "$LFS/usr/share/pixmaps/maruxos/"*.png 2>/dev/null | wc -l)개"
fi
# 배경화면: x86 rootfs 우선, 없으면 디자인 원본
if [ -f "$X86/usr/share/backgrounds/marux-desktop.png" ]; then
  cp -f "$X86/usr/share/backgrounds/marux-desktop.png" "$LFS/usr/share/backgrounds/"
elif [ -f "$DZN/marux-desktop.png" ]; then
  cp -f "$DZN/marux-desktop.png" "$LFS/usr/share/backgrounds/"
fi
# pixmaps에도 배경화면 있어야 (x86 xinitrc 참조 경로)
[ -f "$LFS/usr/share/backgrounds/marux-desktop.png" ] && cp -f "$LFS/usr/share/backgrounds/marux-desktop.png" "$LFS/usr/share/pixmaps/maruxos/" 2>/dev/null || true
echo "  배경화면: $(ls "$LFS/usr/share/backgrounds/"*.png 2>/dev/null | wc -l)개"

# ---------- 2. 헬퍼 3종 (marux-wallpaper/-new-desktop-item/-desktop-refresh) ----------
echo "[2] 헬퍼 스크립트 이식"
for h in marux-wallpaper marux-new-desktop-item marux-desktop-refresh; do
  if [ -f "$CFG/scripts/$h" ]; then
    cp -f "$CFG/scripts/$h" "$LFS/usr/bin/$h"
    chmod +x "$LFS/usr/bin/$h"
    echo "  ✓ $h"
  else echo "  ⚠️ $CFG/scripts/$h 없음"; fi
done

# ---------- 3. .Xdefaults (xterm — xrdb 없이 Xt앱이 자동 로드) ----------
echo "[3] .Xdefaults (xterm 한글/색상)"
if [ -f "$CFG/Xresources" ]; then
  cp -f "$CFG/Xresources" "$LFS/etc/X11/Xresources"
  cp -f "$CFG/Xresources" "$LFS/etc/skel/.Xdefaults"
  cp -f "$CFG/Xresources" "$LFS/root/.Xdefaults"
  echo "  ✓ Xresources → /etc/X11 + skel/.Xdefaults + root/.Xdefaults"
fi

# ---------- 4. openbox 풀 메뉴 + rc.xml (키바인드 W-t/W-e/W-d) ----------
echo "[4] openbox 메뉴/키바인드"
mkdir -p "$LFS/etc/xdg/openbox"
cp -f "$CFG/openbox/menu.xml" "$LFS/etc/xdg/openbox/menu.xml"
cp -f "$CFG/openbox/rc.xml"   "$LFS/etc/xdg/openbox/rc.xml"
# 배치 A: NanumGothic 미설치 → openbox 폰트 DejaVu Sans로 (폴백이지만 명시). 배치 B에서 NanumGothic 복원.
sed -i 's/<name>NanumGothic<\/name>/<name>DejaVu Sans<\/name>/g' "$LFS/etc/xdg/openbox/rc.xml"
echo "  ✓ menu.xml + rc.xml (font→DejaVu Sans, 키바인드 유지)"

# ---------- 5. idesk skel (terminal + files, firefox는 배치 B) ----------
echo "[5] idesk 아이콘 (terminal+files)"
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
# root 홈에도 즉시 배치 (skel 복사 실패 대비)
cp -f "$LFS/etc/skel/.ideskrc" "$LFS/root/.ideskrc"
cp -f "$LFS/etc/skel/.idesktop/"*.lnk "$LFS/root/.idesktop/"
echo "  ✓ ideskrc + terminal.lnk + filemanager.lnk (skel + root)"

# ---------- 6. tint2rc (검증된 샘플 + 실기기 픽스) ----------
# ⚠️ 직접작성 tint2rc는 크래시 → 검증 샘플 복사 후 sed로 최소 픽스만.
# 실기기(2026-07-20) 발견: ①시계 time2_format=%A %d %B → ko_KR 로케일 한국어(요일/월)인데
#   한국어 폰트 없어서 tofu 깨짐 → ASCII(%Y-%m-%d)+DejaVu 폰트 명시. ②mouse_effects/tooltip은
#   VC4 hover redraw 소지 → off(단 실기기 지지직 진범은 HW커서였고 xorg SWcursor로 해결).
echo "[6] tint2rc (+시계 ASCII/폰트, hover off)"
mkdir -p "$LFS/etc/xdg/tint2"
if [ -f "$LFS/usr/share/tint2/horizontal-light-opaque.tint2rc" ]; then
  cp -f "$LFS/usr/share/tint2/horizontal-light-opaque.tint2rc" "$LFS/etc/xdg/tint2/tint2rc"
  sed -i \
    -e 's/^time1_format = .*/time1_format = %H:%M/' \
    -e 's/^time2_format = .*/time2_format = %Y-%m-%d/' \
    -e 's/^time1_font = .*/time1_font = DejaVu Sans Bold 11/' \
    -e 's/^time2_font = .*/time2_font = DejaVu Sans 8/' \
    -e 's/^mouse_effects = 1/mouse_effects = 0/' \
    -e 's/^task_tooltip = 1/task_tooltip = 0/' \
    -e 's/^launcher_tooltip = 1/launcher_tooltip = 0/' \
    -e 's/^battery_tooltip = 1/battery_tooltip = 0/' \
    "$LFS/etc/xdg/tint2/tint2rc"
  echo "  ✓ tint2rc (샘플 + 시계 ASCII + hover off)"
else echo "  ⚠️ tint2 샘플 없음"; fi

# ---------- 6b. xorg.conf.d — VC4 SWcursor (HW커서 지지직 해결, 실기기 2026-07-20 확정) ----------
# Pi 4B VC4 하드웨어 커서가 마우스 이동 시 화면 글리치("지지직") → SWcursor로 소프트커서 강제.
# (SW커서는 컴포지터 부재 시 미세 깜빡 잔존 — VC4 고질, 추후 picom 등 폴리시.)
echo "[6b] xorg.conf SWcursor (VC4 지지직 픽스)"
mkdir -p "$LFS/etc/X11/xorg.conf.d"
cat > "$LFS/etc/X11/xorg.conf.d/99-swcursor.conf" <<'XORGCONF'
Section "Device"
    Identifier "card0"
    Driver "modesetting"
    Option "SWcursor" "true"
    Option "TearFree" "true"
EndSection
XORGCONF
echo "  ✓ 99-swcursor.conf"

# ---------- 7. full xinitrc (x86 패리티: feh배경 + network + idesk, ibus/firefox 가드) ----------
echo "[7] full xinitrc"
mkdir -p "$LFS/etc/X11/xinit" "$LFS/usr/etc/X11/xinit"
cat > "$LFS/etc/X11/xinit/xinitrc" <<'XINIT'
#!/bin/sh
# MaruxOS 2.0.0 ARM64 X 세션 (x86 패리티). 한글입력(ibus)/Firefox는 존재 시 자동 활성(배치 B).
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

# 한글 입력기 ibus-hangul (XIM). ibus-x11이 XIM 서버 제공 → xterm 등 X앱 한글입력.
# 한영토글: ibus-hangul 기본 = Shift+space 또는 Hangul 키. (gtk3 불요 = 배치 B-1)
if [ -x /usr/bin/ibus-daemon ]; then
  mkdir -p "$XDG_CONFIG_HOME/ibus/bus"
  eval "$(dbus-launch --sh-syntax)"; export DBUS_SESSION_BUS_ADDRESS
  # -x XIM서버, --panel disable(gtk3 패널없음), -r 기존대체, -d 데몬화
  ibus-daemon --xim --panel disable -r -d >/tmp/ibus-daemon.log 2>&1
  sleep 5
  # 한글 엔진 활성 (실패해도 무해 — setxkbmap 경고로 rc=1 나도 엔진은 활성). 한/영 토글 = Shift+Space.
  ibus engine hangul >>/tmp/ibus-daemon.log 2>&1 || true
fi

# 네트워크 (eth0 dhcpcd)
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

# WM = 세션 리더 (foreground). openbox 종료 = 세션 종료. (tint2 크래시에 안 죽게 exec openbox)
exec openbox
XINIT
chmod +x "$LFS/etc/X11/xinit/xinitrc"
# startx는 xinit sysclientrc(/usr/etc/X11/xinit/xinitrc)를 봄 → 4경로 복사 (v7 버그 #1)
cp -f "$LFS/etc/X11/xinit/xinitrc" "$LFS/root/.xinitrc"
cp -f "$LFS/etc/X11/xinit/xinitrc" "$LFS/etc/skel/.xinitrc"
cp -f "$LFS/etc/X11/xinit/xinitrc" "$LFS/usr/etc/X11/xinit/xinitrc"
echo "  ✓ xinitrc 4경로 배포"

# ---------- 검증 ----------
echo "===== config populate v2 완료 ====="
echo "  PNG pixmaps : $(ls "$LFS/usr/share/pixmaps/maruxos/"*.png 2>/dev/null | wc -l)개"
echo "  배경화면    : $(ls "$LFS/usr/share/backgrounds/"*.png 2>/dev/null | wc -l)개"
echo "  헬퍼        : $(ls "$LFS/usr/bin/marux-"* 2>/dev/null | wc -l)개"
echo "  xinitrc     : $(for p in "$LFS/etc/X11/xinit/xinitrc" "$LFS/root/.xinitrc" "$LFS/etc/skel/.xinitrc" "$LFS/usr/etc/X11/xinit/xinitrc"; do [ -f "$p" ] && echo -n "O" || echo -n "X"; done) (4경로)"
echo "  menu/rc.xml : $([ -f "$LFS/etc/xdg/openbox/menu.xml" ] && echo -n menuO)$([ -f "$LFS/etc/xdg/openbox/rc.xml" ] && echo " rcO")"
echo "  idesk lnk   : $(ls "$LFS/etc/skel/.idesktop/"*.lnk 2>/dev/null | wc -l)개"
echo "  .Xdefaults  : $([ -f "$LFS/root/.Xdefaults" ] && echo O)"
