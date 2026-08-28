#!/bin/bash
# =============================================================================
# MaruxOS 2.0.0 ARM64 — 데스크톱 config를 $LFS rootfs에 populate
# (v7 이미지에 들어감). DejaVu 폰트 + xinitrc + openbox 메뉴 + tint2rc.
# 한글 입력(ibus)은 아직 없음(Pi 네이티브 후속) — 여기선 그래픽 데스크톱 코어만.
# =============================================================================
set -uo pipefail
B=/home/administrator/MaruxOS-arm64
LFS=$B/rootfs-clfs-arm64
[[ "$LFS" == *"MaruxOS-arm64"* ]] || { echo "🚨 ABORT: $LFS"; exit 1; }

# ---------- 1. DejaVu TTF 폰트 (tint2/pango 텍스트 렌더링 필수) ----------
S=$LFS/sources
if [ ! -f "$S/dejavu-fonts-ttf-2.37.tar.bz2" ]; then
  echo "[font] DejaVu fetch"
  ( cd "$S" && timeout 90 wget -q "https://github.com/dejavu-fonts/dejavu-fonts/releases/download/version_2_37/dejavu-fonts-ttf-2.37.tar.bz2" ) || echo "  🚨 DejaVu fetch 실패"
fi
mkdir -p "$LFS/usr/share/fonts/TTF"
if [ -f "$S/dejavu-fonts-ttf-2.37.tar.bz2" ]; then
  tmp=$(mktemp -d); tar xf "$S/dejavu-fonts-ttf-2.37.tar.bz2" -C "$tmp"
  cp "$tmp"/dejavu-fonts-ttf-2.37/ttf/*.ttf "$LFS/usr/share/fonts/TTF/" 2>/dev/null
  rm -rf "$tmp"
  echo "  DejaVu 설치: $(ls "$LFS/usr/share/fonts/TTF/"*.ttf 2>/dev/null | wc -l)개 ttf"
fi

# ---------- 2. /etc/X11/xinit/xinitrc (startx 진입점) ----------
mkdir -p "$LFS/etc/X11/xinit"
cat > "$LFS/etc/X11/xinit/xinitrc" <<'XINIT'
#!/bin/sh
# MaruxOS X 세션 (openbox + tint2). 한글(ibus)은 Pi 네이티브 빌드 후 추가.
export XDG_RUNTIME_DIR=/tmp/runtime-$(id -u)
mkdir -p "$XDG_RUNTIME_DIR"; chmod 700 "$XDG_RUNTIME_DIR"
export LANG=ko_KR.UTF-8 LC_ALL=ko_KR.UTF-8
export XDG_SESSION_TYPE=x11 XDG_CURRENT_DESKTOP=MaruxOS XDG_CONFIG_HOME="$HOME/.config"

# Xresources (xterm 등)
[ -f /etc/X11/Xresources ] && command -v xrdb >/dev/null 2>&1 && xrdb -merge /etc/X11/Xresources

# 배경색 (Nord dark)
command -v xsetroot >/dev/null 2>&1 && xsetroot -solid "#2E3440"

# 패널 + 아이콘 (백그라운드 — tint2/idesk가 죽어도 openbox가 세션 유지)
tint2 &
if [ -x /usr/bin/idesk ] && [ -f /etc/skel/.ideskrc ]; then
  [ -f "$HOME/.ideskrc" ]  || cp /etc/skel/.ideskrc  "$HOME/.ideskrc"
  [ -d "$HOME/.idesktop" ] || cp -r /etc/skel/.idesktop "$HOME/.idesktop"
  idesk &
fi

# WM = 세션 리더 (foreground). openbox 종료 시 세션 종료. (exec tint2는 tint2 크래시 시 세션 즉사 → openbox exec로 견고화)
exec openbox
XINIT
chmod +x "$LFS/etc/X11/xinit/xinitrc"
# ⚠️ xinit이 --sysconfdir=/etc 없이 빌드돼 startx는 /usr/etc/X11/xinit/xinitrc(sysclientrc)를 봄.
# → xinitrc를 startx가 참조하는 모든 경로에 복사 (안 하면 xinit 기본세션 xterm×3 + WM없음 → 입력불가).
mkdir -p "$LFS/root" "$LFS/etc/skel" "$LFS/usr/etc/X11/xinit"
cp "$LFS/etc/X11/xinit/xinitrc" "$LFS/root/.xinitrc"
cp "$LFS/etc/X11/xinit/xinitrc" "$LFS/etc/skel/.xinitrc"
cp "$LFS/etc/X11/xinit/xinitrc" "$LFS/usr/etc/X11/xinit/xinitrc"

# ---------- 3. openbox 메뉴 (우클릭) — 터미널 실행 ----------
mkdir -p "$LFS/etc/xdg/openbox"
cat > "$LFS/etc/xdg/openbox/menu.xml" <<'MENU'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_menu xmlns="http://openbox.org/3.4/menu">
<menu id="root-menu" label="MaruxOS">
  <separator label="MaruxOS 2.0.0 Cooked"/>
  <item label="Terminal (xterm)">
    <action name="Execute"><command>xterm -fa "DejaVu Sans Mono" -fs 11</command></action>
  </item>
  <separator/>
  <item label="Reconfigure"><action name="Reconfigure"/></item>
  <item label="Restart"><action name="Restart"/></item>
  <separator/>
  <item label="Exit"><action name="Exit"><prompt>yes</prompt></action></item>
</menu>
</openbox_menu>
MENU

# ---------- 4. tint2 패널 (taskbar + clock) ----------
mkdir -p "$LFS/etc/xdg/tint2"
# ⚠️ 직접 작성한 tint2rc가 'panel_background_id rounded is too big'로 tint2 크래시 → X 세션 즉사.
# tint2가 설치한 검증된 샘플을 그대로 사용 (taskbar+clock+tray 포함).
if [ -f "$LFS/usr/share/tint2/horizontal-light-opaque.tint2rc" ]; then
  cp "$LFS/usr/share/tint2/horizontal-light-opaque.tint2rc" "$LFS/etc/xdg/tint2/tint2rc"
else
  echo "  ⚠️ tint2 샘플 없음 (tint2 빌드 먼저 필요)"
fi

# ---------- 5. idesk skel (터미널 아이콘 1개) ----------
mkdir -p "$LFS/etc/skel/.idesktop"
cat > "$LFS/etc/skel/.ideskrc" <<'IDESKRC'
table Config
  FontName: DejaVu Sans
  FontSize: 10
  FontColor: #ECEFF4
  Locked: false
  Transparency: 150
  Shadow: true
  ShadowColor: #000000
  ShadowX: 1
  ShadowY: 1
  IconSnap: true
  SnapWidth: 80
  SnapHeight: 80
  Background.Delay: 0
end
table Actions
  Lock: control right doubleClk
  Reload: middle doubleClk
  Drag: left held
  EndDrag: left released
  Execute[0]: left doubleClk
end
IDESKRC
cat > "$LFS/etc/skel/.idesktop/terminal.lnk" <<'LNK'
table Icon
  Caption: Terminal
  Command: xterm -fa "DejaVu Sans Mono" -fs 11
  Icon: /usr/share/tint2/default_icon.png
  X: 40
  Y: 40
end
LNK

echo "===== 데스크톱 config populate 완료 ====="
echo "  xinitrc: $([ -f "$LFS/etc/X11/xinit/xinitrc" ] && echo OK)"
echo "  openbox menu: $([ -f "$LFS/etc/xdg/openbox/menu.xml" ] && echo OK)"
echo "  tint2rc: $([ -f "$LFS/etc/xdg/tint2/tint2rc" ] && echo OK)"
echo "  DejaVu ttf: $(ls "$LFS/usr/share/fonts/TTF/"*.ttf 2>/dev/null | wc -l)개"
