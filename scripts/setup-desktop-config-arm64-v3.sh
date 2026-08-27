#!/bin/bash
# =============================================================================
# MaruxOS 2.0.0 ARM64 — 데스크톱 config populate v3 (배치 B-2: gtk3/Firefox 시대)
# -----------------------------------------------------------------------------
# v2(배치 A) 대비 델타:
#   ① openbox rc.xml 폰트 NanumGothic **복원** (v2는 폰트 미설치라 DejaVu 강등,
#      v9부터 NanumGothic 3종 설치됨 → x86 원본 그대로)
#   ② tint2 시계 한국어 날짜 **복원** (%A %d %B + NanumGothic — v8 ASCII 강등의
#      원인이던 '한국어 글리프 폰트 부재'가 해소됨. x86 패리티)
#   ③ idesk **firefox.lnk 추가** (x86 skel 패리티 — Firefox 번들 아이콘 사용)
#   ④ xinitrc의 ibus/firefox 가드는 v2 그대로 — B-2 설치로 자동 활성됨
#      (GTK_IM_MODULE=ibus 등 gtk3 IM env는 v2부터 이미 선반영돼 있음)
# 순수 파일복사+생성 (chroot 불요). root로 실행. 성공기준: xinitrc 4경로 + menu +
# firefox.lnk + NanumGothic rc.xml.
# =============================================================================
set -uo pipefail
B=/home/administrator/MaruxOS-arm64
LFS=$B/rootfs-clfs-arm64
X86=/home/administrator/MaruxOS/build/rootfs-lfs
CFG=/mnt/c/Users/Administrator/Desktop/MaruxOS/config
DZN="/mnt/c/Users/Administrator/Desktop/MaruxOS/MaruxOS 디자인"
[[ "$LFS" == *"MaruxOS-arm64"* ]] || { echo "🚨 ABORT: $LFS"; exit 1; }
[ -d "$LFS/usr" ] || { echo "🚨 ABORT: rootfs 없음"; exit 1; }
# B-2 게이트: v3는 gtk3/Firefox/NanumGothic 존재를 전제
[ -e "$LFS/usr/lib/libgtk-3.so.0" ] || { echo "🚨 ABORT: gtk3 없음 (B-2 미완 — v2 쓸 것)"; exit 1; }
[ -x "$LFS/opt/firefox/firefox" ] || { echo "🚨 ABORT: Firefox 없음 (B-2 미완)"; exit 1; }
[ -f "$LFS/usr/share/fonts/nanum/NanumGothic-Regular.ttf" ] || { echo "🚨 ABORT: NanumGothic 없음"; exit 1; }

# ---------- 1. PNG 자산 (배경화면 + 아이콘) ----------
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
echo "  배경화면: $(ls "$LFS/usr/share/backgrounds/"*.png 2>/dev/null | wc -l)개"

# ---------- 2. 헬퍼 3종 ----------
echo "[2] 헬퍼 스크립트 이식"
for h in marux-wallpaper marux-new-desktop-item marux-desktop-refresh; do
  if [ -f "$CFG/scripts/$h" ]; then
    cp -f "$CFG/scripts/$h" "$LFS/usr/bin/$h"
    chmod +x "$LFS/usr/bin/$h"
    echo "  ✓ $h"
  else echo "  ⚠️ $CFG/scripts/$h 없음"; fi
done

# ---------- 3. .Xdefaults ----------
echo "[3] .Xdefaults (xterm 한글/색상)"
if [ -f "$CFG/Xresources" ]; then
  cp -f "$CFG/Xresources" "$LFS/etc/X11/Xresources"
  cp -f "$CFG/Xresources" "$LFS/etc/skel/.Xdefaults"
  cp -f "$CFG/Xresources" "$LFS/root/.Xdefaults"
  echo "  ✓ Xresources → /etc/X11 + skel/.Xdefaults + root/.Xdefaults"
fi

# ---------- 4. openbox 풀 메뉴 + rc.xml — v3: NanumGothic 복원 (sed 강등 제거) ----------
echo "[4] openbox 메뉴/키바인드 (NanumGothic 원본 유지)"
mkdir -p "$LFS/etc/xdg/openbox"
cp -f "$CFG/openbox/menu.xml" "$LFS/etc/xdg/openbox/menu.xml"
cp -f "$CFG/openbox/rc.xml"   "$LFS/etc/xdg/openbox/rc.xml"
echo "  ✓ menu.xml + rc.xml (x86 원본 그대로 — NanumGothic, Firefox 메뉴 → /usr/bin/firefox 활성)"

# ---------- 5. idesk skel — v3: firefox.lnk 추가 (3아이콘 = x86 풀 패리티) ----------
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
# x86 skel/.idesktop/firefox.lnk 패리티 — 아이콘은 Firefox 번들 default128.png (같은 경로에 풀림)
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
[ -f "$LFS/opt/firefox/browser/chrome/icons/default/default128.png" ] || echo "  ⚠️ FF 번들 아이콘 경로 확인 필요 (lnk는 배포됨)"
cp -f "$LFS/etc/skel/.ideskrc" "$LFS/root/.ideskrc"
cp -f "$LFS/etc/skel/.idesktop/"*.lnk "$LFS/root/.idesktop/"
echo "  ✓ ideskrc + terminal/filemanager/firefox.lnk (skel + root)"

# ---------- 6. tint2rc — v3: 시계 한국어 날짜 복원 (NanumGothic) ----------
# v8에서 ASCII(%Y-%m-%d) 강등한 원인 = ko_KR 로케일 %A/%B 한국어 글리프 폰트 부재(tofu).
# v9부터 NanumGothic 설치 → x86 패리티 포맷(%A %d %B) + NanumGothic 폰트로 복원.
# hover off(mouse_effects/tooltip)는 유지. ⚠️ 직접작성 tint2rc 크래시 이력 → 샘플+sed 방식 유지.
echo "[6] tint2rc (샘플 + 한국어 시계 + hover off)"
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
  echo "  ✓ tint2rc (시계: %H:%M + %A %d %B/NanumGothic, hover off)"
else echo "  ⚠️ tint2 샘플 없음"; fi

# ---------- 6b. xorg.conf.d — VC4 SWcursor (v2와 동일) ----------
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

# ---------- 7. full xinitrc (v2와 동일 — ibus/firefox 가드가 B-2 설치로 자동 활성) ----------
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

# WM = 세션 리더 (foreground). openbox 종료 = 세션 종료.
exec openbox
XINIT
chmod +x "$LFS/etc/X11/xinit/xinitrc"
cp -f "$LFS/etc/X11/xinit/xinitrc" "$LFS/root/.xinitrc"
cp -f "$LFS/etc/X11/xinit/xinitrc" "$LFS/etc/skel/.xinitrc"
cp -f "$LFS/etc/X11/xinit/xinitrc" "$LFS/usr/etc/X11/xinit/xinitrc"
echo "  ✓ xinitrc 4경로 배포"

# ⚠️ 함정(v8, tint2rc 우선순위): tint2가 /etc/xdg/tint2/tint2rc를 ~/.config/tint2/tint2rc로
# 복사해 그걸 씀 → 기존 홈 캐시가 있으면 새 tint2rc 무시. root 홈 캐시 제거로 강제 갱신.
rm -f "$LFS/root/.config/tint2/tint2rc" 2>/dev/null || true

# ---------- 검증 ----------
echo "===== config populate v3 완료 ====="
echo "  PNG pixmaps : $(ls "$LFS/usr/share/pixmaps/maruxos/"*.png 2>/dev/null | wc -l)개"
echo "  배경화면    : $(ls "$LFS/usr/share/backgrounds/"*.png 2>/dev/null | wc -l)개"
echo "  헬퍼        : $(ls "$LFS/usr/bin/marux-"* 2>/dev/null | wc -l)개"
echo "  xinitrc     : $(for p in "$LFS/etc/X11/xinit/xinitrc" "$LFS/root/.xinitrc" "$LFS/etc/skel/.xinitrc" "$LFS/usr/etc/X11/xinit/xinitrc"; do [ -f "$p" ] && echo -n "O" || echo -n "X"; done) (4경로)"
echo "  menu/rc.xml : $([ -f "$LFS/etc/xdg/openbox/menu.xml" ] && echo -n menuO)$([ -f "$LFS/etc/xdg/openbox/rc.xml" ] && echo " rcO") (NanumGothic=$(grep -c NanumGothic "$LFS/etc/xdg/openbox/rc.xml" 2>/dev/null))"
echo "  idesk lnk   : $(ls "$LFS/etc/skel/.idesktop/"*.lnk 2>/dev/null | wc -l)개 (firefox 포함)"
echo "  tint2 시계  : $(grep '^time2_format' "$LFS/etc/xdg/tint2/tint2rc" 2>/dev/null)"
echo "  .Xdefaults  : $([ -f "$LFS/root/.Xdefaults" ] && echo O)"
