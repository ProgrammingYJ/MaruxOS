#!/bin/bash
# =============================================================================
# MaruxOS 2.0.0 x86_64 — 데스크톱 config populate **x86 v1** (2026-08-28, "ISO도 img처럼")
# -----------------------------------------------------------------------------
# ARM64 config v15(setup-desktop-config-arm64-v15.sh)를 x86 패리티 rootfs에 이식한 것.
# 대상 = /home/administrator/MaruxOS/x86-parity/rootfs-lfs-parity (원본 build/rootfs-lfs 는 건드리지 않음).
# 델타 (ARM64 v15 → x86 v1):
#   · 경로: $B/$LFS x86 패리티. 폰트는 x86 배치상 /usr/share/fonts/truetype/nanum/.
#   · inittab: x86 rootfs는 이미 `agetty --autologin root --noclear 38400 tty1 linux` (1.x 유산) → 그대로 인정(패턴만 게이트).
#   · .bash_profile: x86 기존은 `exec startx`(실패 시 respawn 루프) → ARM64 v13 정책(일반 호출, 셸로 복귀)으로 교체.
#   · xorg.conf.d: Pi 전용 99-swcursor(modesetting HW커서 강제)는 이식 안 함. 50-mouse-flat(libinput flat)만.
#   · xinitrc: ARM64 v15 본문 + x86 유산인 `xrdb -merge /etc/X11/Xresources` 추가. `startx`가 읽는 시스템 xinitrc 경로를
#     /usr/bin/startx 에서 실측해 거기에도 배포(BLFS xinit는 xinitdir이 배포판마다 다름).
#   · tint2 은퇴(ARM64 v10과 동일) → /etc/xdg/tint2/tint2rc 제거, 우상단 통합 상태 바(marux-quicksettings)가 대체.
#   · 그 외(.desktop 10종·독 3종·idesk 4종·MIME·keyfile·Qt 플러그인 경로·picom·bamf·볼륨 부트스트랩) v15 동일.
# 실행 전제: .p/.p2/.q(quicksettings)/.5A (rootfs sources 마커) + $B/.q/.f/.e/.t/.x-COMPLETE
# =============================================================================
set -uo pipefail
B=/home/administrator/MaruxOS/x86-parity
LFS=$B/rootfs-lfs-parity
CFG=/mnt/c/Users/Administrator/Desktop/MaruxOS/config
DZN="/mnt/c/Users/Administrator/Desktop/MaruxOS/MaruxOS 디자인"
[[ "$LFS" == *"x86-parity"* ]] || { echo "🚨 ABORT: $LFS"; exit 1; }
[[ "$LFS" == *"/MaruxOS/build/"* ]] && { echo "🚨 ABORT: 원본 x86 rootfs"; exit 1; }
[ -d "$LFS/usr" ] || { echo "🚨 ABORT: rootfs 없음"; exit 1; }
[ -e "$LFS/usr/lib/libgtk-3.so.0" ] || { echo "🚨 ABORT: gtk3 없음"; exit 1; }
[ -x "$LFS/opt/firefox/firefox" ] || { echo "🚨 ABORT: Firefox 없음"; exit 1; }
[ -f "$LFS/usr/share/fonts/truetype/nanum/NanumGothic-Bold.ttf" ] || { echo "🚨 ABORT: NanumGothic-Bold 없음(상태 바 폰트)"; exit 1; }
for m in .p-COMPLETE .p2-COMPLETE .q-COMPLETE .5A-COMPLETE; do [ -f "$LFS/sources/$m" ] || { echo "🚨 ABORT: rootfs 마커 $m 없음"; exit 1; }; done
for m in .q-COMPLETE .f-COMPLETE .e-COMPLETE .t-COMPLETE .x-COMPLETE; do [ -f "$B/$m" ] || { echo "🚨 ABORT: 배치 마커 $B/$m 없음"; exit 1; }; done
for b in plank picom marux-quicksettings qterminal pcmanfm-qt featherpad lximage-qt speedcrunch lxqt-archiver qps idesk feh amixer aplay; do
  [ -x "$LFS/usr/bin/$b" ] || { echo "🚨 ABORT: $b 없음"; exit 1; }; done
[ -x "$LFS/usr/libexec/bamf/bamfdaemon" ] || { echo "🚨 ABORT: bamfdaemon 없음"; exit 1; }
[ -f "$LFS/usr/plugins/platforms/libqxcb.so" ] || { echo "🚨 ABORT: Qt xcb 플러그인 없음"; exit 1; }
[ -f "$LFS/usr/share/plank/themes/Marux/dock.theme" ] || { echo "🚨 ABORT: Marux 테마 없음"; exit 1; }
[ -f "$LFS/usr/share/glib-2.0/schemas/40_maruxos.gschema.override" ] || { echo "🚨 ABORT: gschema.override 없음"; exit 1; }
[ -f "$LFS/etc/xdg/picom.conf" ] || { echo "🚨 ABORT: picom.conf 없음"; exit 1; }
for d in xterm mc firefox qterminal pcmanfm-qt featherpad lximage-qt speedcrunch lxqt-archiver qps; do
  [ -f "$CFG/applications/$d.desktop" ] || { echo "🚨 ABORT: $d.desktop 자산 없음"; exit 1; }; done
for d in qterminal pcmanfm-qt firefox; do
  [ -f "$CFG/plank/dock1/launchers/$d.dockitem" ] || { echo "🚨 ABORT: $d.dockitem 자산 없음"; exit 1; }; done
grep -q 'featherpad' "$CFG/openbox/menu.xml" || { echo "🚨 ABORT: 공유 menu.xml이 Qt 메뉴가 아님"; exit 1; }

# ---------- 1. PNG 자산 (DZN SSOT) ----------
echo "[1] PNG 자산"
mkdir -p "$LFS/usr/share/pixmaps/maruxos" "$LFS/usr/share/backgrounds"
for ic in marux-terminal marux-file-manager marux-desktop marux-editor marux-image marux-calc marux-archive marux-taskmgr; do
  [ -f "$DZN/$ic.png" ] || { echo "🚨 ABORT: $DZN/$ic.png 없음"; exit 1; }
  cp -f "$DZN/$ic.png" "$LFS/usr/share/pixmaps/maruxos/$ic.png"
done
[ -f "$DZN/marux-logo-128.png" ] && cp -f "$DZN/marux-logo-128.png" "$LFS/usr/share/pixmaps/maruxos/marux-logo.png"
cp -f "$LFS/usr/share/pixmaps/maruxos/marux-desktop.png" "$LFS/usr/share/backgrounds/marux-desktop.png"
for icon_name in file-generic folder file-text file-image; do
  [ -e "$LFS/usr/share/pixmaps/maruxos/$icon_name.png" ] || ln -sf marux-file-manager.png "$LFS/usr/share/pixmaps/maruxos/$icon_name.png"
done

# ---------- 2. 헬퍼 3종 ----------
echo "[2] 헬퍼 스크립트"
for h in marux-wallpaper marux-new-desktop-item marux-desktop-refresh; do
  [ -f "$CFG/scripts/$h" ] || { echo "🚨 ABORT: config/scripts/$h 없음"; exit 1; }
  cp -f "$CFG/scripts/$h" "$LFS/usr/bin/$h"; chmod 755 "$LFS/usr/bin/$h"
done

# ---------- 3. Xresources ----------
echo "[3] Xresources"
[ -f "$CFG/Xresources" ] || { echo "🚨 ABORT: config/Xresources 없음"; exit 1; }
cp -f "$CFG/Xresources" "$LFS/etc/X11/Xresources"; chmod 644 "$LFS/etc/X11/Xresources"
cp -f "$CFG/Xresources" "$LFS/etc/skel/.Xdefaults"; cp -f "$CFG/Xresources" "$LFS/root/.Xdefaults"

# ---------- 4. openbox (공유 Qt 메뉴 — x86 전용 menu-x86.xml은 v9까지의 유산) ----------
echo "[4] openbox 메뉴/키바인드 (공유 menu.xml = Qt 앱 기준)"
mkdir -p "$LFS/etc/xdg/openbox"
cp -f "$CFG/openbox/menu.xml" "$LFS/etc/xdg/openbox/menu.xml"
cp -f "$CFG/openbox/rc.xml"   "$LFS/etc/xdg/openbox/rc.xml"
chmod 644 "$LFS/etc/xdg/openbox"/{rc,menu}.xml
for cmd in qterminal pcmanfm-qt featherpad lximage-qt speedcrunch lxqt-archiver qps firefox; do
  grep -q "<command>$cmd" "$LFS/etc/xdg/openbox/menu.xml" || [ "$cmd" = firefox ] || { echo "🚨 ABORT: 메뉴에 $cmd 없음"; exit 1; }; done

# ---------- 5. .desktop 10종 (config SSOT — 패키지 make install이 덮어쓴 것 되돌림, 함정 #36) ----------
echo "[5] applications .desktop 10종"
mkdir -p "$LFS/usr/share/applications"
for d in xterm mc firefox qterminal pcmanfm-qt featherpad lximage-qt speedcrunch lxqt-archiver qps; do
  cp -f "$CFG/applications/$d.desktop" "$LFS/usr/share/applications/$d.desktop"; chmod 644 "$LFS/usr/share/applications/$d.desktop"
  ic=$(grep -m1 '^Icon=' "$LFS/usr/share/applications/$d.desktop" | cut -d= -f2-)
  [[ "$ic" == /* ]] && [ -f "$LFS$ic" ] || { echo "🚨 ABORT: $d.desktop Icon 실존 안 함: $ic"; exit 1; }
done
# tint2 시절 런처 .desktop(battery/network/volume/marux-menu)은 배포 안 함 — 상태 바가 대체

# ---------- 5b. plank 독 (launchers 3종 — settings 키파일은 override가 공급) ----------
echo "[5b] plank dock1/launchers (skel + root)"
mkdir -p "$LFS/etc/skel/.config/plank/dock1/launchers" "$LFS/root/.config/plank/dock1/launchers"
for d in qterminal pcmanfm-qt firefox; do
  cp -f "$CFG/plank/dock1/launchers/$d.dockitem" "$LFS/etc/skel/.config/plank/dock1/launchers/"
  cp -f "$CFG/plank/dock1/launchers/$d.dockitem" "$LFS/root/.config/plank/dock1/launchers/"
done
rm -f "$LFS"/etc/skel/.config/plank/dock1/launchers/{xterm,mc}.dockitem "$LFS"/root/.config/plank/dock1/launchers/{xterm,mc}.dockitem 2>/dev/null || true

# ---------- 5c. idesk 4아이콘 (v15 동일) ----------
echo "[5c] idesk 아이콘"
mkdir -p "$LFS/etc/skel/.idesktop" "$LFS/root/.idesktop"
rm -f "$LFS"/etc/skel/.idesktop/*.lnk "$LFS"/root/.idesktop/*.lnk 2>/dev/null || true
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
mklnk(){ cat > "$LFS/etc/skel/.idesktop/$1.lnk" <<LNK
table Icon
  Caption: $2
  Command: $3
  Icon: $4
  X: 80
  Y: $5
  Width: 48
  Height: 48
end
LNK
}
mklnk terminal    "Terminal"    qterminal          /usr/share/pixmaps/maruxos/marux-terminal.png     80
mklnk filemanager "Files"       pcmanfm-qt         /usr/share/pixmaps/maruxos/marux-file-manager.png 180
mklnk firefox     "Firefox"     /usr/bin/firefox   /opt/firefox/browser/chrome/icons/default/default128.png 280
mklnk editor      "Text Editor" featherpad         /usr/share/pixmaps/maruxos/marux-editor.png       380
for l in "$LFS"/etc/skel/.idesktop/*.lnk; do ic=$(grep -m1 'Icon:' "$l" | awk '{print $2}'); [ -f "$LFS$ic" ] || { echo "🚨 ABORT: idesk $(basename "$l") Icon 없음 $ic"; exit 1; }; done
cp -f "$LFS/etc/skel/.ideskrc" "$LFS/root/.ideskrc"; cp -f "$LFS/etc/skel/.idesktop/"*.lnk "$LFS/root/.idesktop/"

# ---------- 6. tint2 은퇴 ----------
echo "[6] tint2 은퇴 (상태 바 = marux-quicksettings)"
rm -f "$LFS/etc/xdg/tint2/tint2rc" "$LFS/root/.config/tint2/tint2rc" 2>/dev/null || true

# ---------- 6b. xorg.conf.d (x86: flat 가속만) ----------
echo "[6b] xorg.conf.d"
mkdir -p "$LFS/etc/X11/xorg.conf.d"
rm -f "$LFS/etc/X11/xorg.conf.d/99-swcursor.conf"
[ -f "$LFS/usr/lib/xorg/modules/input/libinput_drv.so" ] && cat > "$LFS/etc/X11/xorg.conf.d/50-mouse-flat.conf" <<'XORGCONF'
Section "InputClass"
    Identifier "flat pointer accel"
    MatchIsPointer "on"
    Driver "libinput"
    Option "AccelProfile" "flat"
EndSection
XORGCONF

# ---------- 7. xinitrc (ARM64 v15 본문 + xrdb) ----------
echo "[7] xinitrc"
mkdir -p "$LFS/etc/X11/xinit"
cat > "$LFS/etc/X11/xinit/xinitrc" <<'XINIT'
#!/bin/sh
# MaruxOS 2.0.0 x86_64 X 세션 (ARM64 config v15 이식, x86 v1). Plank dock + GSettings keyfile + Qt5 앱.
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
# GSettings keyfile 백엔드 (plank dock-items 영속). 기본값은 gschema.override가 공급.
export GSETTINGS_BACKEND=keyfile

# X 클라이언트 기본값 (xterm 폴백의 한국어 Xft 폰트 등)
[ -f /etc/X11/Xresources ] && command -v xrdb >/dev/null 2>&1 && xrdb -merge /etc/X11/Xresources

# 한글 입력기 ibus-hangul (XIM + gtk3 immodule + Qt5 플러그인). 토글 = Shift+Space.
if [ -x /usr/bin/ibus-daemon ]; then
  mkdir -p "$XDG_CONFIG_HOME/ibus/bus"
  eval "$(dbus-launch --sh-syntax)"; export DBUS_SESSION_BUS_ADDRESS
  ibus-daemon --xim --panel disable -r -d >/tmp/ibus-daemon.log 2>&1
  sleep 5
  ibus engine hangul >>/tmp/ibus-daemon.log 2>&1 || true
fi

# 네트워크 (부팅 rc가 주 담당 — 폴백)
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

# 커널 콘솔 스팸 차단 (syslog엔 계속 기록)
dmesg -n 1 2>/dev/null

# 컴포지터 picom (plank 반투명·라운드의 전제)
[ -x /usr/bin/picom ] && picom -b --config /etc/xdg/picom.conf >/tmp/picom.log 2>&1

# bamf 창매칭 데몬 (독 실행중 점 표시)
[ -x /usr/libexec/bamf/bamfdaemon ] && /usr/libexec/bamf/bamfdaemon >/tmp/bamf.log 2>&1 &

# Plank dock
if [ -x /usr/bin/plank ]; then
  [ -d "$HOME/.config/plank" ] || cp -r /etc/skel/.config/plank "$HOME/.config/plank" 2>/dev/null
  /usr/bin/plank >/tmp/plank.log 2>&1 &
  sleep 0.3
fi

# 볼륨 컨트롤 부트스트랩 (softvol 카드 대비 — HW 믹서 카드엔 무해)
[ -x /usr/bin/aplay ] && (aplay -q -f S16_LE -r 44100 -c 2 -d 1 /dev/zero >/dev/null 2>&1 &)

# 우상단 통합 상태 바 (한/영·WiFi·볼륨·시계). wlan0 없어도 무해.
[ -x /usr/bin/marux-quicksettings ] && /usr/bin/marux-quicksettings >/tmp/quicksettings.log 2>&1 &

# 바탕화면 아이콘 (idesk)
if [ -x /usr/bin/idesk ]; then
  [ -f "$HOME/.ideskrc" ]  || cp /etc/skel/.ideskrc  "$HOME/.ideskrc"  2>/dev/null
  [ -d "$HOME/.idesktop" ] || cp -r /etc/skel/.idesktop "$HOME/.idesktop" 2>/dev/null
  mkdir -p "$HOME/Desktop"
  [ -x /usr/bin/marux-desktop-refresh ] && /usr/bin/marux-desktop-refresh --quiet 2>/dev/null
  idesk &
fi

# WM = 세션 리더. openbox 종료 = 세션 종료 (우클릭 메뉴 Exit).
exec openbox
XINIT
chmod 755 "$LFS/etc/X11/xinit/xinitrc"
cp -f "$LFS/etc/X11/xinit/xinitrc" "$LFS/root/.xinitrc"
cp -f "$LFS/etc/X11/xinit/xinitrc" "$LFS/etc/skel/.xinitrc"
# startx가 참조하는 시스템 xinitrc 경로 실측 배포 (BLFS xinit는 xinitdir이 다를 수 있음)
SYSX=$(grep -m1 -o 'sysxinitrc=[^ ]*' "$LFS/usr/bin/startx" 2>/dev/null | cut -d= -f2 | tr -d '"')
if [ -n "$SYSX" ] && [ "$SYSX" != "/etc/X11/xinit/xinitrc" ]; then
  mkdir -p "$LFS$(dirname "$SYSX")"; cp -f "$LFS/etc/X11/xinit/xinitrc" "$LFS$SYSX"; echo "  + startx sysxinitrc=$SYSX 에도 배포"
fi
rm -f "$LFS/root/.config/glib-2.0/settings/keyfile" 2>/dev/null || true

# ---------- 7b. MIME 기본앱 (v14/v15 동일) ----------
echo "[7b] MIME 기본앱"
MIMEAPPS="[Default Applications]
text/plain=featherpad.desktop
text/x-shellscript=featherpad.desktop
application/x-shellscript=featherpad.desktop
text/x-c=featherpad.desktop
text/x-python=featherpad.desktop
text/css=featherpad.desktop
text/html=firefox.desktop
inode/directory=pcmanfm-qt.desktop
image/png=lximage-qt.desktop
image/jpeg=lximage-qt.desktop
image/gif=lximage-qt.desktop
image/bmp=lximage-qt.desktop
image/webp=lximage-qt.desktop
image/svg+xml=lximage-qt.desktop
application/zip=lxqt-archiver.desktop
application/x-tar=lxqt-archiver.desktop
application/x-compressed-tar=lxqt-archiver.desktop
application/x-xz-compressed-tar=lxqt-archiver.desktop
application/x-bzip-compressed-tar=lxqt-archiver.desktop
application/gzip=lxqt-archiver.desktop
application/x-7z-compressed=lxqt-archiver.desktop

[Added Associations]
text/plain=featherpad.desktop;
text/html=featherpad.desktop;firefox.desktop;
"
mkdir -p "$LFS/etc/xdg"
printf '%s' "$MIMEAPPS" > "$LFS/usr/share/applications/mimeapps.list"
printf '%s' "$MIMEAPPS" > "$LFS/etc/xdg/mimeapps.list"
{ echo "[MIME Cache]"
  for f in "$LFS"/usr/share/applications/*.desktop; do
    mt=$(grep -m1 '^MimeType=' "$f" | cut -d= -f2-); [ -n "$mt" ] || continue
    for t in $(echo "$mt" | tr ';' ' '); do echo "$t=$(basename "$f");"; done
  done | sort | awk -F= '{a[$1]=a[$1]$2} END{for(k in a) print k"="a[k]}' | sort; } > "$LFS/usr/share/applications/mimeinfo.cache"
grep -q '^text/plain=.*featherpad.desktop' "$LFS/usr/share/applications/mimeinfo.cache" || { echo "🚨 ABORT: mimeinfo.cache text/plain→featherpad 없음"; exit 1; }
# x86 rootfs엔 shared-mime-info DB가 없다(.txt 판별 불가 → 더블클릭 기본앱 실패). DB는 아키텍처 무관 데이터라 ARM64 rootfs의 /usr/share/mime를 이식.
if [ ! -f "$LFS/usr/share/mime/mime.cache" ]; then
  ARMMIME=/home/administrator/MaruxOS-arm64/rootfs-clfs-arm64/usr/share/mime
  [ -f "$ARMMIME/mime.cache" ] || { echo "🚨 ABORT: shared-mime DB 없음(x86·ARM64 둘 다)"; exit 1; }
  rm -rf "$LFS/usr/share/mime"; cp -a "$ARMMIME" "$LFS/usr/share/mime"; echo "  + shared-mime DB 이식(ARM64 rootfs, $(du -sh "$LFS/usr/share/mime" | cut -f1))"
fi
[ -f "$LFS/usr/share/mime/mime.cache" ] || { echo "🚨 ABORT: mime.cache 없음"; exit 1; }
grep -q "text/plain" "$LFS/usr/share/mime/globs2" || { echo "🚨 ABORT: mime globs2에 text/plain 없음"; exit 1; }

# ---------- 8. 자동 로그인(기존 인정) + X 자동 기동(exec 제거) ----------
echo "[8] tty1 자동 로그인 + startx 프로필"
INITTAB="$LFS/etc/inittab"
grep -qE '^1:2345:respawn:/sbin/agetty --autologin root .*tty1' "$INITTAB" || { echo "🚨 ABORT: inittab tty1 autologin 줄 없음"; grep -n tty1 "$INITTAB"; exit 1; }
grep -a -q 'autologin' "$LFS/sbin/agetty" || { echo "🚨 ABORT: agetty가 --autologin 미지원"; exit 1; }   # 파이프 금지(pipefail SIGPIPE)
cat > "$LFS/root/.bash_profile" <<'BPROF'
# MaruxOS: tty1 자동 로그인 후 X 자동 기동 (2.0.0, x86 config v1 = ARM64 v13 정책)
# - 로그인 셸이 tty1이고 X가 없으면 startx. 시리얼/기타 tty는 해당 없음.
# - exec가 아니므로 X 종료/실패 시 이 셸로 돌아온다(디버깅 가능). 로그아웃하면 agetty가 다시 자동 로그인 → X.
[ -f ~/.bashrc ] && . ~/.bashrc
if [ -z "$DISPLAY" ] && [ "$(tty 2>/dev/null)" = /dev/tty1 ] && [ -x /usr/bin/startx ]; then
  startx
  echo "[MaruxOS] X 세션 종료 — 'startx'로 재시작하거나 로그아웃(exit)하면 자동 재로그인됩니다"
fi
BPROF
cp -f "$LFS/root/.bash_profile" "$LFS/etc/skel/.bash_profile"
bash -n "$LFS/root/.bash_profile" || { echo "🚨 ABORT: .bash_profile 문법"; exit 1; }

# ---------- 검증 ----------
touch "$B/.cfg-x86-v1"
echo "===== config x86 v1 완료 ====="
echo "  .desktop     : $(ls "$LFS/usr/share/applications/"{xterm,mc,firefox,qterminal,pcmanfm-qt,featherpad,lximage-qt,speedcrunch,lxqt-archiver,qps}.desktop 2>/dev/null | wc -l)/10"
echo "  dockitem     : $(ls "$LFS/root/.config/plank/dock1/launchers/"*.dockitem 2>/dev/null | wc -l)/3 / idesk: $(ls "$LFS/root/.idesktop/"*.lnk | wc -l)/4"
echo "  xinitrc      : Qt플러그인 $(grep -c QT_QPA_PLATFORM_PLUGIN_PATH "$LFS/etc/X11/xinit/xinitrc") keyfile $(grep -c GSETTINGS_BACKEND=keyfile "$LFS/etc/X11/xinit/xinitrc") plank $(grep -c /usr/bin/plank "$LFS/etc/X11/xinit/xinitrc") 상태바 $(grep -c marux-quicksettings "$LFS/etc/X11/xinit/xinitrc") tint2 $(grep -c tint2 "$LFS/etc/X11/xinit/xinitrc")"
echo "  MIME         : text/plain→$(grep '^text/plain=' "$LFS/etc/xdg/mimeapps.list" | cut -d= -f2) / image/png→$(grep '^image/png=' "$LFS/etc/xdg/mimeapps.list" | cut -d= -f2)"
echo "  자동로그인   : $(grep -c 'autologin root' "$INITTAB") / startx 프로필(비exec): $(grep -c '^  startx' "$LFS/root/.bash_profile")"
echo "  tint2rc      : $([ -f "$LFS/etc/xdg/tint2/tint2rc" ] && echo 잔존 || echo '은퇴 ✓')"
