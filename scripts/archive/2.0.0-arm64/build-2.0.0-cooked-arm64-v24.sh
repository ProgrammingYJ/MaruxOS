#!/bin/bash
###############################################################################
# MaruxOS 2.0.0 "Cooked" — ARM64 이미지 빌드 v24 (호버·실패알림·목록아이콘 실제 반영)
#
# v23 대비 변경 (2026-08-23 실기기 피드백 — v23에서 "적용 안 됨"으로 보고된 항목들):
#   ⚠️ 전제: v23 빌드 이후 GUI를 수정했으므로 **재빌드해야 실기기에 반영**된다(사용자 지적 정확).
#   ① **호버 하이라이트 방식 교체** — CSS로 창 배경을 밝히려던 것이 미발현. 배경은 이미
#      cairo가 그리므로 **cairo에서 직접 밝기 전환**(draw_glass_hl(hot))하고, 마우스 감지도
#      EventBox가 아닌 **창(bar) 레벨 enter/leave**로 이동 → CSS 의존 제거.
#   ② **연결 실패 알림을 별도 창으로** — v23의 POPUP_MENU 전환(독 유령창 픽스)이 부작용을
#      냈다: 패널이 포커스를 잃으면 닫히므로 패널 안 라벨로는 실패를 볼 수 없었다.
#      → Gtk.MessageDialog로 표시("비밀번호를 확인해 주세요").
#   ③ **드롭다운 목록도 WiFi 아이콘** — 바만 아이콘이고 목록은 여전히 텍스트였음(피드백).
#      각 행에 cairo 아이콘(신호 3단계) 추가.
#   (v23 유지: 한영 상태 노출 엔진 패치 + WiFi 아이콘 + POPUP_MENU + 커널 FWSUP + 통합 바)
#   🐛 조사 중: plank 우클릭 "닫기" 무동작 / 한영 표시(엔진은 입력 포커스 시에만 기동 —
#      xterm 안에서 타이핑 상태로 Shift+Space를 눌러야 상태 파일이 생성된다).
#
# 사용법: 부팅 → startx → WiFi 스캔/연결 + 볼륨 + 플로팅 시계 + 회귀.
###############################################################################
set -euo pipefail
BUILD_TARGET="arm64"
OUTPUT_NAME="MaruxOS-2.0.0-arm64.img"
B="/home/administrator/MaruxOS-arm64"
LFS="$B/rootfs-clfs-arm64"
KIMG="$B/kernel/linux-6.18.26/arch/arm64/boot/Image"
KDTB="$B/kernel/linux-6.18.26/arch/arm64/boot/dts/broadcom/bcm2711-rpi-4-b.dtb"
FW="$B/firmware"
WORK="$B/iso-build"
OUT="$B/output"
WINOUT="/mnt/c/Users/Administrator/Desktop/MaruxOS/output"
IMGSIZE="27G"
ROOT_PARTUUID="4d415258-02"   # MBR disk-id 0x4d415258("MARX") 고정 → 번호 시프트 면역
KIMG_SHA_EXPECTED="13bd3415cad00b66ae75b756ddf19591f8c25fbc011992476ef023201c48c10c"   # FWSUP 패치본 (실기기 WiFi 성공 검증, 2026-08-23)
MNT=""; LOOP=""
cleanup(){ set +e; [ -n "$MNT" ] && mountpoint -q "$MNT" && umount "$MNT"; [ -n "$LOOP" ] && losetup -d "$LOOP" 2>/dev/null; [ -n "$MNT" ] && [ -d "$MNT" ] && rmdir "$MNT" 2>/dev/null; }
trap cleanup EXIT
echo "===== MaruxOS 2.0.0 ARM64 v24 (호버·실패알림·목록아이콘) 빌드 $(date) ====="

# ============================ 게이트 ============================
[[ "$OUTPUT_NAME" == *arm64* ]] || { echo "🚨 ABORT: OUTPUT_NAME"; exit 1; }
[[ "$B" == *MaruxOS-arm64* ]] || { echo "🚨 ABORT: 빌드루트"; exit 1; }
[[ "$B" == *"/MaruxOS/build"* ]] && { echo "🚨 ABORT: x86_64 디렉토리"; exit 1; }
[ -f "$KIMG" ] || { echo "🚨 ABORT: 커널"; exit 1; }
KMAGIC="$(od -An -tx1 -j56 -N4 "$KIMG" | tr -d ' ')"
[ "$KMAGIC" = "41524d64" ] || { echo "🚨 ABORT: 커널 arm64 매직 ($KMAGIC)"; exit 1; }
grep -q "vc4.ko" "$B/kernel/linux-6.18.26/modules.builtin" || { echo "🚨 ABORT: VC4 builtin 아님"; exit 1; }
# 🔴 v18: WiFi 커널 게이트 (임베드 실측 + builtin 실측 + SHA 고정)
KIMG_SHA="$(sha256sum "$KIMG" | awk '{print $1}')"
[ "$KIMG_SHA" = "$KIMG_SHA_EXPECTED" ] || { echo "🚨 ABORT: 커널 SHA ≠ WiFi 재빌드본 ($KIMG_SHA)"; exit 1; }
for m in cfg80211.ko mac80211.ko brcmfmac.ko brcmutil.ko reset-gpio.ko; do
  grep -q "$m" "$B/kernel/linux-6.18.26/modules.builtin" || { echo "🚨 ABORT: $m builtin 아님"; exit 1; }
done
grep -aq "brcmfmac43455-sdio" "$KIMG" || { echo "🚨 ABORT: Image에 43455 펌웨어 임베드 흔적 없음"; exit 1; }
grep -aq "regulatory.db" "$KIMG" || { echo "🚨 ABORT: Image에 regulatory.db 임베드 흔적 없음"; exit 1; }
# 데스크톱 코어 (v8)
for f in usr/bin/Xorg usr/bin/openbox usr/bin/tint2 usr/bin/idesk usr/bin/feh usr/bin/mc usr/sbin/syslogd; do
  [ -x "$LFS/$f" ] || { echo "🚨 ABORT: $f 없음(v8 스택)"; exit 1; }
done
# 한글 B-1 (v9/v10)
[ -x "$LFS/usr/bin/ibus-daemon" ] || { echo "🚨 ABORT: ibus-daemon 없음"; exit 1; }
[ -x "$LFS/usr/libexec/ibus-x11" ] || { echo "🚨 ABORT: ibus-x11(XIM) 없음"; exit 1; }
[ -x "$LFS/usr/libexec/ibus-engine-hangul" ] || { echo "🚨 ABORT: ibus-engine-hangul 없음"; exit 1; }
[ -f "$LFS/usr/share/glib-2.0/schemas/org.freedesktop.ibus.gschema.xml" ] || { echo "🚨 ABORT: ibus 코어 gschema 없음"; exit 1; }
[ -f "$LFS/usr/share/glib-2.0/schemas/gschemas.compiled" ] || { echo "🚨 ABORT: gschemas.compiled 없음"; exit 1; }
[ -s "$LFS/etc/machine-id" ] || { echo "🚨 ABORT: /etc/machine-id 없음"; exit 1; }
[ -e "$LFS/usr/lib/libhangul.so" ] || { echo "🚨 ABORT: libhangul 없음"; exit 1; }
ls "$LFS"/usr/lib/libgtk-x11-2.0.so* >/dev/null 2>&1 || { echo "🚨 ABORT: gtk2 없음"; exit 1; }
[ -f "$LFS/usr/share/fonts/nanum/NanumGothic-Regular.ttf" ] || { echo "🚨 ABORT: NanumGothic 없음"; exit 1; }
[ -f "$LFS/usr/share/fonts/nanum/NanumGothic-Bold.ttf" ] || { echo "🚨 ABORT: NanumGothic-Bold 없음(플로팅 시계 폰트)"; exit 1; }
# 배치 B-2 (v11)
[ -f "$LFS/sources/.b2-COMPLETE" ] || { echo "🚨 ABORT: B-2 미완"; exit 1; }
[ -e "$LFS/usr/lib/libgtk-3.so.0" ] || { echo "🚨 ABORT: gtk3 없음"; exit 1; }
[ -e "$LFS/usr/lib/gtk-3.0/3.0.0/immodules/im-ibus.so" ] || { echo "🚨 ABORT: gtk3 im-ibus.so 없음"; exit 1; }
grep -q ibus "$LFS/usr/lib/gtk-3.0/3.0.0/immodules.cache" || { echo "🚨 ABORT: immodules.cache에 ibus 없음"; exit 1; }
[ -x "$LFS/opt/firefox/firefox" ] || { echo "🚨 ABORT: Firefox 없음"; exit 1; }
grep -q "^Version=140\." "$LFS/opt/firefox/application.ini" || { echo "🚨 ABORT: Firefox 버전 불일치"; exit 1; }
[ -L "$LFS/usr/bin/firefox" ] || { echo "🚨 ABORT: firefox 심링크 없음"; exit 1; }
[ -e "$LFS/usr/lib/libasound.so.2" ] || { echo "🚨 ABORT: alsa-lib 없음"; exit 1; }
[ -x "$LFS/usr/bin/setxkbmap" ] || { echo "🚨 ABORT: setxkbmap 없음"; exit 1; }
[ -f "$LFS/usr/share/mime/mime.cache" ] || { echo "🚨 ABORT: shared-mime-info 없음"; exit 1; }
[ ! -f "$LFS/sources/.b2-FFDEPS" ] || { echo "🚨 ABORT: Firefox 의존성 미해결"; exit 1; }
[ -f "$LFS/etc/skel/.idesktop/firefox.lnk" ] || { echo "🚨 ABORT: firefox.lnk 없음"; exit 1; }
grep -q "NanumGothic" "$LFS/etc/xdg/openbox/rc.xml" || { echo "🚨 ABORT: rc.xml NanumGothic 없음"; exit 1; }
grep -q "GTK_IM_MODULE=ibus" "$LFS/etc/X11/xinit/xinitrc" || { echo "🚨 ABORT: xinitrc GTK_IM_MODULE 없음"; exit 1; }
# 네트워크 (v12)
[ -f "$LFS/sources/.n-COMPLETE" ] || { echo "🚨 ABORT: 네트워크 빌드 미완"; exit 1; }
[ -x "$LFS/usr/sbin/dhcpcd" ] || { echo "🚨 ABORT: dhcpcd 없음"; exit 1; }
[ -x "$LFS/usr/sbin/chronyd" ] || { echo "🚨 ABORT: chronyd 없음"; exit 1; }
[ -f "$LFS/lib/services/dhcpcd" ] || { echo "🚨 ABORT: /lib/services/dhcpcd 없음"; exit 1; }
grep -q "SERVICE=dhcpcd" "$LFS/etc/sysconfig/ifconfig.eth0" || { echo "🚨 ABORT: ifconfig.eth0 static 잔재"; exit 1; }
[ -f "$LFS/etc/chrony.conf" ] || { echo "🚨 ABORT: chrony.conf 없음"; exit 1; }
[ -e "$LFS/etc/rc.d/rc3.d/S25chronyd" ] || { echo "🚨 ABORT: S25chronyd 없음"; exit 1; }
# 🔴 v18: WiFi userspace (배치 W)
[ -f "$LFS/sources/.w-COMPLETE" ] || { echo "🚨 ABORT: WiFi userspace 미완(.w-COMPLETE 없음)"; exit 1; }
[ -x "$LFS/usr/sbin/wpa_supplicant" ] || { echo "🚨 ABORT: wpa_supplicant 없음"; exit 1; }
[ -x "$LFS/usr/sbin/wpa_cli" ] || { echo "🚨 ABORT: wpa_cli 없음"; exit 1; }
[ -e "$LFS/usr/lib/libnl-genl-3.so" ] || { echo "🚨 ABORT: libnl 없음"; exit 1; }
[ -f "$LFS/etc/wpa_supplicant.conf" ] || { echo "🚨 ABORT: wpa_supplicant.conf 없음"; exit 1; }
grep -q "psk=" "$LFS/etc/wpa_supplicant.conf" && { echo "🚨 ABORT: conf에 자격증명! (sanitize 위반)"; exit 1; }
grep -q "update_config=1" "$LFS/etc/wpa_supplicant.conf" || { echo "🚨 ABORT: conf 템플릿 아님"; exit 1; }
[ -e "$LFS/etc/rc.d/rc3.d/S24wpasupplicant" ] || { echo "🚨 ABORT: S24wpasupplicant 없음"; exit 1; }
[ -f "$LFS/lib/firmware/brcm/brcmfmac43455-sdio.bin" ] || { echo "🚨 ABORT: rootfs 43455 펌웨어 없음"; exit 1; }
[ -f "$LFS/lib/firmware/regulatory.db" ] || { echo "🚨 ABORT: rootfs regulatory.db 없음"; exit 1; }
# 🔴 v23: 한/영 상태 노출 패치 (ibus-hangul 엔진에 마커 문자열)
grep -qa "marux-ime-mode" "$LFS/usr/libexec/ibus-engine-hangul" || { echo "🚨 ABORT: ibus-hangul 한영 상태 노출 패치 미반영(한영 표시 고정 재발)"; exit 1; }
# 🔴 v22: WiFi 4-way 정공 (함정 #31) — 커널 FWSUP 패치 + wpa offload 차단
[ -f "$LFS/sources/.w-markers/wpa-offload-patched" ] || { echo "🚨 ABORT: wpa offload 차단 패치 미적용(4-way 실패 재발)"; exit 1; }
grep -q "MaruxOS: FWSUP" "$B/kernel/linux-6.18.26/drivers/net/wireless/broadcom/brcm80211/brcmfmac/feature.c" || { echo "🚨 ABORT: 커널 FWSUP 패치 없음"; exit 1; }
# 🔴 v22: tint2 은퇴 + 통합 상태 바 (config v10)
[ ! -f "$LFS/etc/xdg/tint2/tint2rc" ] || { echo "🚨 ABORT: tint2rc 잔존(config v10 미적용)"; exit 1; }
grep -q "tint2" "$LFS/etc/X11/xinit/xinitrc" && { echo "🚨 ABORT: xinitrc에 tint2 기동 잔재"; exit 1; }
grep -q "marux-quicksettings" "$LFS/etc/X11/xinit/xinitrc" || { echo "🚨 ABORT: xinitrc 통합 상태 바 기동 없음"; exit 1; }
# 🔴 v21: wpa_supplicant BRCM 확장 (4-way offload 함정 #30 해소분)
# ⚠️ 파이프 금지(strings|grep -q): grep -q 조기 종료가 strings를 SIGPIPE로 죽여 pipefail 오탐
grep -qa "BRCM vendor event" "$LFS/usr/sbin/wpa_supplicant" || { echo "🚨 ABORT: wpa에 DRIVER_NL80211_BRCM 미반영(4-way 실패 재발)"; exit 1; }
# 🔴 v21: 볼륨 컨트롤 부트스트랩 (softvol Master 지연 생성 대응)
grep -q "aplay -q -f S16_LE" "$LFS/etc/X11/xinit/xinitrc" || { echo "🚨 ABORT: xinitrc 볼륨 부트스트랩 없음(config v9 미적용)"; exit 1; }
# 🔴 v20: fstab LABEL 강제 (함정 #29 2차 얼굴 — cmdline만 고치면 checkfs가 부팅을 halt시킴)
grep -q "mmcblk" "$LFS/etc/fstab" && { echo "🚨 ABORT: fstab에 /dev/mmcblkN 하드코딩 잔재(호스트 시프트 취약)"; exit 1; }
grep -q "^LABEL=maruxroot" "$LFS/etc/fstab" || { echo "🚨 ABORT: fstab root가 LABEL=maruxroot 아님"; exit 1; }
grep -q "^LABEL=MARUXBOOT" "$LFS/etc/fstab" || { echo "🚨 ABORT: fstab boot가 LABEL=MARUXBOOT 아님"; exit 1; }
# 🔴 v19: 볼륨 백엔드 (v18 실기기: amixer 부재 버그)
[ -x "$LFS/usr/bin/amixer" ] || { echo "🚨 ABORT: amixer 없음(alsa-utils 미설치)"; exit 1; }
[ -x "$LFS/usr/bin/aplay" ] || { echo "🚨 ABORT: aplay 없음"; exit 1; }
grep -q 'name "Master"' "$LFS/etc/asound.conf" || { echo "🚨 ABORT: asound.conf softvol Master 없음"; exit 1; }
# 🔴 v18: 퀵설정 GUI
[ -f "$LFS/sources/.q-COMPLETE" ] || { echo "🚨 ABORT: 퀵설정 미완(.q-COMPLETE 없음)"; exit 1; }
[ -x "$LFS/usr/bin/marux-quicksettings" ] || { echo "🚨 ABORT: marux-quicksettings 없음"; exit 1; }
readelf -h "$LFS/usr/bin/marux-quicksettings" | grep -q AArch64 || { echo "🚨 ABORT: quicksettings 아키텍처"; exit 1; }
grep -q "marux-quicksettings" "$LFS/etc/X11/xinit/xinitrc" || { echo "🚨 ABORT: xinitrc 퀵설정 기동 없음(config v9 미적용)"; exit 1; }
# 커서 폴리시 (v13 — config v4/v5)
grep -q '"SWcursor" "false"' "$LFS/etc/X11/xorg.conf.d/99-swcursor.conf" || { echo "🚨 ABORT: HW커서 미적용"; exit 1; }
grep -q '"TearFree"' "$LFS/etc/X11/xorg.conf.d/99-swcursor.conf" && { echo "🚨 ABORT: 죽은 TearFree 옵션 잔재"; exit 1; }
[ -f "$LFS/etc/X11/xorg.conf.d/50-mouse-flat.conf" ] || { echo "🚨 ABORT: flat 가속 conf 없음"; exit 1; }
# 🔴 배치 P: Plank (v14 신규)
[ -f "$LFS/sources/.p-COMPLETE" ] || { echo "🚨 ABORT: Plank 빌드 미완(.p-COMPLETE 없음)"; exit 1; }
[ -x "$LFS/usr/bin/plank" ] || { echo "🚨 ABORT: plank 바이너리 없음"; exit 1; }
ls "$LFS"/usr/lib/libplank.so.1* >/dev/null 2>&1 || { echo "🚨 ABORT: libplank 없음"; exit 1; }
ls "$LFS"/usr/lib/libbamf3.so.2* >/dev/null 2>&1 || { echo "🚨 ABORT: libbamf3 없음"; exit 1; }
[ -x "$LFS/usr/bin/valac" ] || { echo "🚨 ABORT: valac 없음(vala 부트스트랩 미완)"; exit 1; }
[ -f "$LFS/usr/share/glib-2.0/schemas/net.launchpad.plank.gschema.xml" ] || { echo "🚨 ABORT: plank gschema 없음(SIGTRAP 크래시 원인)"; exit 1; }
[ -f "$LFS/usr/share/glib-2.0/schemas/40_maruxos.gschema.override" ] || { echo "🚨 ABORT: gschema.override 없음(빈 독 원인)"; exit 1; }
grep -q "xterm.dockitem" "$LFS/usr/share/glib-2.0/schemas/40_maruxos.gschema.override" || { echo "🚨 ABORT: override에 dock-items 없음"; exit 1; }
grep -qa "net.launchpad.plank" "$LFS/usr/share/glib-2.0/schemas/gschemas.compiled" || { echo "🚨 ABORT: gschemas.compiled에 plank 없음"; exit 1; }
# config v9 적용 확인
grep -q "GSETTINGS_BACKEND=keyfile" "$LFS/etc/X11/xinit/xinitrc" || { echo "🚨 ABORT: xinitrc keyfile 백엔드 없음"; exit 1; }
grep -q "/usr/bin/plank" "$LFS/etc/X11/xinit/xinitrc" || { echo "🚨 ABORT: xinitrc plank 블록 없음"; exit 1; }
for d in xterm mc firefox; do
  [ -f "$LFS/usr/share/applications/$d.desktop" ] || { echo "🚨 ABORT: $d.desktop 없음"; exit 1; }
  [ -f "$LFS/root/.config/plank/dock1/launchers/$d.dockitem" ] || { echo "🚨 ABORT: $d.dockitem 없음"; exit 1; }
done
# 배치 P2: 폴리시 (v15)
[ -f "$LFS/sources/.p2-COMPLETE" ] || { echo "🚨 ABORT: P2 빌드 미완(.p2-COMPLETE 없음)"; exit 1; }
[ -x "$LFS/usr/bin/picom" ] || { echo "🚨 ABORT: picom 없음"; exit 1; }
[ -f "$LFS/etc/xdg/picom.conf" ] || { echo "🚨 ABORT: picom.conf 없음"; exit 1; }
[ -f "$LFS/usr/share/plank/themes/Marux/dock.theme" ] || { echo "🚨 ABORT: Marux 테마 없음"; exit 1; }
grep -q "theme='Marux'" "$LFS/usr/share/glib-2.0/schemas/40_maruxos.gschema.override" || { echo "🚨 ABORT: override theme≠Marux"; exit 1; }
grep -q "picom" "$LFS/etc/X11/xinit/xinitrc" || { echo "🚨 ABORT: xinitrc picom 기동 없음"; exit 1; }
# v17: libwnck 43.2 강제 (43.0 = bamf 즉사 버그)
grep -q "^Version: 43.2" "$LFS/usr/lib/pkgconfig/libwnck-3.0.pc" || { echo "🚨 ABORT: libwnck 43.2 아님(43.0=bamf segv 버그)"; exit 1; }
# v16 라이브픽스 게이트
grep -q 'context name="Client"' "$LFS/etc/xdg/openbox/rc.xml" || { echo "🚨 ABORT: rc.xml Client 컨텍스트 없음(클릭 창전환 버그)"; exit 1; }
readelf -d "$LFS/usr/lib/libwnck-3.so.0.3.0" | grep -q startup-notification || { echo "🚨 ABORT: libwnck SN 미링크"; exit 1; }
grep -q "bamfdaemon" "$LFS/etc/X11/xinit/xinitrc" || { echo "🚨 ABORT: xinitrc bamfdaemon 기동 없음"; exit 1; }
grep -q "dmesg -n 1" "$LFS/etc/X11/xinit/xinitrc" || { echo "🚨 ABORT: xinitrc dmesg 조용화 없음"; exit 1; }
grep -q "TopRoundness=10" "$LFS/usr/share/plank/themes/Marux/dock.theme" || { echo "🚨 ABORT: 테마 라운드 확정값(10) 미적용"; exit 1; }
grep -q ";;95$" "$LFS/usr/share/plank/themes/Marux/dock.theme" || { echo "🚨 ABORT: 테마 알파 확정값(95) 미적용"; exit 1; }
[ -f "$KDTB" ] || { echo "🚨 ABORT: dtb"; exit 1; }
[ "$(stat -c%s "$FW/start4.elf")" -eq 2306400 ] || { echo "🚨 ABORT: start4.elf"; exit 1; }
echo "✅ 게이트 통과 (v17 전체 + WiFi커널/wpa/퀵설정/플로팅시계/sanitize)"

mkdir -p "$WORK" "$OUT"; IMG="$WORK/$OUTPUT_NAME"; rm -f "$IMG" "$IMG.xz"
echo "[1/8] $IMGSIZE sparse"; truncate -s "$IMGSIZE" "$IMG"
echo "[2/8] 파티션"; sfdisk "$IMG" <<'SFDISK'
label: dos
label-id: 0x4d415258
unit: sectors
start=2048, size=1048576, type=c, bootable
start=1050624, type=83
SFDISK
# 🔴 v20: MBR disk-id 실측 게이트 (PARTUUID 결정성 보장)
MBRSIG="$(od -An -tx1 -j440 -N4 "$IMG" | tr -dc '0-9a-f')"
[ "$MBRSIG" = "5852414d" ] || { echo "🚨 ABORT: MBR disk-id($MBRSIG) ≠ 4d415258 LE — PARTUUID 불일치"; exit 1; }
echo "  ✓ MBR disk-id 0x4d415258 (PARTUUID $ROOT_PARTUUID)"
echo "[3/8] losetup"; LOOP="$(losetup -fP --show "$IMG")"; echo "  loop=$LOOP"
echo "[4/8] mkfs"; mkfs.vfat -F 32 -n MARUXBOOT "${LOOP}p1" >/dev/null; mkfs.ext4 -q -F -L maruxroot "${LOOP}p2"
echo "[5/8] rootfs 복사 (/tools 제외 · /sources 유지)"
MNT="$(mktemp -d)"; mount "${LOOP}p2" "$MNT"
rsync -aHAX --numeric-ids --exclude='/tools' --exclude='/proc/*' --exclude='/sys/*' --exclude='/run/*' --exclude='/tmp/*' "$LFS"/ "$MNT"/
echo "  [5b] rootfs 픽스 (idempotent)"
ln -sf /usr/sbin/udevadm "$MNT/bin/udevadm"
# fstab mmcblk → LABEL 보정 (멱등 — 이미지 측 최종 방어선)
sed -i -e 's|^/dev/mmcblk0p2|LABEL=maruxroot|' -e 's|^/dev/mmcblk0p1|LABEL=MARUXBOOT|' "$MNT/etc/fstab"
grep -q "mmcblk" "$MNT/etc/fstab" && { echo "🚨 ABORT: 이미지 fstab에 mmcblk 잔재"; exit 1; }
grep -q "/dev/shm" "$MNT/etc/fstab" || printf "tmpfs           /dev/shm    tmpfs     nosuid,nodev        0    0\ncgroup2         /sys/fs/cgroup cgroup2 nosuid,noexec,nodev 0   0\n" >> "$MNT/etc/fstab"
[ -e "$MNT/etc/rc.d/rcS.d/S70console" ] && mv "$MNT/etc/rc.d/rcS.d/S70console" "$MNT/etc/rc.d/rcS.d/DISABLED-S70console"
grep -q "agetty.*ttyS0" "$MNT/etc/inittab" || echo 's0:2345:respawn:/sbin/agetty --keep-baud 115200,38400,9600 ttyS0 vt220' >> "$MNT/etc/inittab"
cat > "$MNT/etc/resolv.conf" <<'RESOLV'
# MaruxOS — dhcpcd가 DHCP 응답의 DNS로 갱신함. 아래는 클린 폴백.
nameserver 1.1.1.1
nameserver 8.8.8.8
RESOLV
sync; umount "$MNT"
echo "[6/8] boot 파티션"
mount "${LOOP}p1" "$MNT"
cp "$KIMG" "$MNT/kernel8.img"; cp "$KDTB" "$MNT/bcm2711-rpi-4-b.dtb"; cp "$FW/start4.elf" "$MNT/start4.elf"; cp "$FW/fixup4.dat" "$MNT/fixup4.dat"
cat > "$MNT/config.txt" <<'CFG'
arm_64bit=1
kernel=kernel8.img
enable_uart=1
max_framebuffers=2
CFG
# v13: video= 1080p60 강제(TV 픽스). v16: 미연결 HDMI-A-2 강제 제거(vc4 RGB 경고 스팸 원인 유력)
printf 'earlycon=uart8250,mmio32,0xfe215040 8250.nr_uarts=1 console=tty1 console=ttyS0,115200 loglevel=4 root=PARTUUID=4d415258-02 rootfstype=ext4 rootwait fsck.repair=yes net.ifnames=0 video=HDMI-A-1:1920x1080@60\n' > "$MNT/cmdline.txt"
grep -q "root=PARTUUID=$ROOT_PARTUUID" "$MNT/cmdline.txt" || { echo "🚨 ABORT: cmdline PARTUUID 불일치"; exit 1; }
grep -q "mmcblk0p2" "$MNT/cmdline.txt" && { echo "🚨 ABORT: cmdline에 취약한 mmcblk 하드코딩 잔재"; exit 1; }
sync; umount "$MNT"; rmdir "$MNT"; MNT=""
echo "[7/8] loop 해제"; losetup -d "$LOOP"; LOOP=""
echo "[8/8] xz 압축"; xz -T0 -f "$IMG"; cp -f "$IMG.xz" "$OUT/"
mkdir -p "$WINOUT" && cp -f "$IMG.xz" "$WINOUT/" && echo "  Windows output 복사 완료"
echo "===== ✅ v24 완료 $(date) ====="
ls -lh "$OUT/$OUTPUT_NAME.xz"; sha256sum "$OUT/$OUTPUT_NAME.xz"
