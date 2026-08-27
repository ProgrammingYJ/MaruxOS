#!/bin/bash
###############################################################################
# MaruxOS 2.0.0 "Cooked" — ARM64 이미지 빌드 v34 (🔐 공개 릴리즈용 root 비번 + v33 다이어트/라이선스)
#
# v33 대비 변경 (2026-08-27 — GitHub 공개 직전 보안 점검):
#   ① **root 비번을 공개용 기본값 `marux`로 교체** — 이미지 사본의 /etc/shadow 를 sha512 해시로 갱신.
#      이전 값은 개발자 개인 비번과 동일했음(저장소 문서에선 <ROOT_PW>로 치환, config/system-defaults.conf 도 marux).
#      tty1 자동 로그인이라 데스크톱 사용엔 비번 불필요; 시리얼/tty2 로그인 = root / marux (README 명시).
#   ② 게이트: 이미지 shadow의 root 해시가 `marux`와 일치하는지 openssl로 검증 + 개인 비번 해시 부재.
#   (v33 유지 전부)
# --- 이하 v33 헤더 ---
#
# v32 대비 변경 (2026-08-27 — 사용자: "딱 운영체제 구동에 필요한 것만, 슬림하게"):
#   ① **다이어트** (rootfs 18G 실측 → 이미지 사본에서만 제거, $LFS 원본은 빌드 sysroot로 유지):
#      /sources 12G(tarball — 소스는 SOURCES.md·릴리즈로 제공) · gcc 컴파일러 본체 1.6G(libexec/gcc·lib/gcc·binutils
#      실행파일; 런타임 libgcc_s/libstdc++는 유지) · python 297M · 정적 .a 187M · doc/man/info/gtk-doc 192M ·
#      locale(ko/en 외) · /usr/include 86M · gir/vala/cmake/pkgconfig/mkspecs/.la · i18n 소스 · vim 문서 등
#      + **strip --strip-unneeded**(unstripped ELF 827개). 이미지 크기 27G → 8G sparse (dd 시간 1/3).
#      SLIM_KEEP_GCC=1 로 컴파일러 유지 가능(self-hosting 데모용).
#   ② **라이선스 동봉**: /usr/share/licenses/ (공통 13 + 패키지별 216 + MaruxOS LICENSE·THIRD-PARTY·SOURCES·patches),
#      boot 파티션 LICENCE.broadcom, /lib/firmware/LICENCE.cypress·LICENCE.broadcom_bcm43xx·wireless-regdb, 폰트 OFL.
#   ③ 게이트(슬림 사본 대상): /sources·/usr/include 부재 / libgcc_s·libstdc++ 실존 / 모든 ELF NEEDED 해석 0누락 /
#      python 런타임 참조 0 / strip 표본 / 라이선스 파일 실존 / **기동 게이트 7종을 슬림 사본에서 재실행**.
#   (v32 유지: 툴 4종·FeatherPad·MIME·자동 로그인·Qt FORTIFY=2·한글·WiFi)
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
IMGSIZE="8G"   # v33: 슬림 rootfs(≈2G)에 맞춰 축소 — dd·압축 시간 단축
ROOT_PARTUUID="4d415258-02"   # MBR disk-id 0x4d415258("MARX") 고정 → 번호 시프트 면역
KIMG_SHA_EXPECTED="13bd3415cad00b66ae75b756ddf19591f8c25fbc011992476ef023201c48c10c"   # FWSUP 패치본 (실기기 WiFi 성공 검증, 2026-08-23)
MNT=""; LOOP=""
cleanup(){ set +e; [ -n "$MNT" ] && mountpoint -q "$MNT" && umount "$MNT"; [ -n "$LOOP" ] && losetup -d "$LOOP" 2>/dev/null; [ -n "$MNT" ] && [ -d "$MNT" ] && rmdir "$MNT" 2>/dev/null; }
trap cleanup EXIT
echo "===== MaruxOS 2.0.0 ARM64 v34 (공개용 root 비번 + 다이어트 + 라이선스) 빌드 $(date) ====="

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
# 🔴 v33: 라이선스 자산 (gen-sources-and-patches-arm64.sh 산출물)
LICSRC="$B/licenses"; WINROOT="/mnt/c/Users/Administrator/Desktop/MaruxOS"
for f in UNLICENSE.txt GPL-2.0.txt GPL-3.0.txt LGPL-2.1.txt LGPL-3.0.txt MPL-2.0.txt OFL-1.1.txt LICENCE.broadcom LICENCE.cypress LICENCE.broadcom_bcm43xx wireless-regdb-LICENSE.txt Info-ZIP-LICENSE.txt GCC-RUNTIME-EXCEPTION-3.1.txt; do
  [ -s "$WINROOT/config/licenses/$f" ] || { echo "🚨 ABORT: config/licenses/$f 없음"; exit 1; }
  grep -qi '<html' "$WINROOT/config/licenses/$f" && { echo "🚨 ABORT: $f 가 HTML(봇 차단 페이지)"; exit 1; }
done
[ "$(ls "$LICSRC/pkg" 2>/dev/null | wc -l)" -ge 150 ] || { echo "🚨 ABORT: 패키지별 라이선스 수집본 부족 — gen-sources-and-patches-arm64.sh 먼저"; exit 1; }
for f in LICENSE THIRD-PARTY-LICENSES.md SOURCES.md patches/README.md; do [ -s "$WINROOT/$f" ] || { echo "🚨 ABORT: $f 없음"; exit 1; }; done
grep -q 'Unlicense' "$WINROOT/LICENSE" || { echo "🚨 ABORT: LICENSE가 Unlicense 판이 아님"; exit 1; }
echo "  ✓ 라이선스 자산 (공통 13 + pkg $(ls "$LICSRC/pkg" | wc -l) + MaruxOS 4)"
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
# 🔴 v27: PCManFM-Qt (배치 F — 로드맵 4번)
[ -f "$B/.f-COMPLETE" ] || { echo "🚨 ABORT: 배치 F 미완(.f-COMPLETE 없음)"; exit 1; }
[ -x "$LFS/usr/bin/pcmanfm-qt" ] || { echo "🚨 ABORT: pcmanfm-qt 없음"; exit 1; }
readelf -h "$LFS/usr/bin/pcmanfm-qt" | grep -q AArch64 || { echo "🚨 ABORT: pcmanfm-qt가 AArch64가 아님"; exit 1; }
for flib in libfm-qt libfm-extra libmenu-cache libexif; do
  ls "$LFS/usr/lib/$flib".so* >/dev/null 2>&1 || { echo "🚨 ABORT: $flib 없음"; exit 1; }
done
[ -f "$LFS/usr/share/applications/pcmanfm-qt.desktop" ] || { echo "🚨 ABORT: pcmanfm-qt.desktop 없음"; exit 1; }
[ -f "$LFS/root/.config/plank/dock1/launchers/pcmanfm-qt.dockitem" ] || { echo "🚨 ABORT: pcmanfm-qt dockitem 없음"; exit 1; }
grep -q "mc " "$LFS/etc/xdg/openbox/menu.xml" && { echo "🚨 ABORT: openbox 메뉴에 mc 잔재"; exit 1; }
[ -x "$LFS/usr/bin/mc" ] || { echo "🚨 ABORT: mc 폴백이 사라짐(잔류 정책)"; exit 1; }

# 🔴 v26: Qt5 런타임 + QTerminal (배치 Q)
[ -f "$B/.q-COMPLETE" ] || { echo "🚨 ABORT: 배치 Q 미완(.q-COMPLETE 없음)"; exit 1; }
for qlib in libQt5Core libQt5Gui libQt5Widgets libQt5X11Extras libQt5XcbQpa; do
  ls "$LFS/usr/lib/$qlib".so.5.15* >/dev/null 2>&1 || { echo "🚨 ABORT: $qlib 없음"; exit 1; }
done
[ -e "$LFS/usr/plugins/platforms/libqxcb.so" ] || { echo "🚨 ABORT: xcb 플랫폼 플러그인 없음(Qt 앱 기동 불가)"; exit 1; }
ls "$LFS/usr/lib/libqtermwidget5.so"* >/dev/null 2>&1 || { echo "🚨 ABORT: qtermwidget 없음"; exit 1; }
[ -x "$LFS/usr/bin/qterminal" ] || { echo "🚨 ABORT: qterminal 없음"; exit 1; }
readelf -h "$LFS/usr/bin/qterminal" | grep -q AArch64 || { echo "🚨 ABORT: qterminal이 AArch64가 아님(크로스 오설정)"; exit 1; }
readelf -h "$LFS/usr/lib/libQt5Core.so.5.15" 2>/dev/null | grep -q AArch64 || { echo "🚨 ABORT: libQt5Core가 AArch64가 아님"; exit 1; }
# config v11: 터미널 전환 + Qt 런타임 환경변수
grep -q "QT_QPA_PLATFORM_PLUGIN_PATH" "$LFS/etc/X11/xinit/xinitrc" || { echo "🚨 ABORT: xinitrc Qt 플러그인 경로 없음(config v11 미적용)"; exit 1; }
[ -f "$LFS/usr/share/applications/qterminal.desktop" ] || { echo "🚨 ABORT: qterminal.desktop 없음"; exit 1; }
[ -f "$LFS/root/.config/plank/dock1/launchers/qterminal.dockitem" ] || { echo "🚨 ABORT: qterminal dockitem 없음"; exit 1; }
grep -q "xterm" "$LFS/etc/xdg/openbox/menu.xml" && { echo "🚨 ABORT: openbox 메뉴에 xterm 잔재"; exit 1; }
[ -x "$LFS/usr/bin/xterm" ] || { echo "🚨 ABORT: xterm 폴백이 사라짐(대피로 유지 정책)"; exit 1; }

# 🔴 v28: Qt FORTIFY 픽스 (함정 #35) — 재빌드 통과본 SHA 대조 + **기동 게이트**
[ -f "$B/.q-FORTIFY2-OK" ] || { echo "🚨 ABORT: Qt FORTIFY 재빌드 미실행(.q-FORTIFY2-OK 없음) — rebuild-qt-fortify-arm64.sh 먼저"; exit 1; }
while read -r sha path; do
  [[ "$sha" == \#* ]] && continue
  cur=$(sha256sum "$LFS/$path" | awk '{print $1}')
  [ "$cur" = "$sha" ] || { echo "🚨 ABORT: $path 가 기동 게이트 통과본과 다름 ($cur ≠ $sha)"; exit 1; }
done < "$B/.q-FORTIFY2-OK"
echo "  ✓ Qt 스택 = 기동 게이트 통과본 (SHA 일치)"

# 🔴 v29: config → rootfs 무결성 (존재 ≠ 내용). 패키지 make install이 .desktop을 덮어쓴 사고(v28) 재발 방지
CFGWIN="/mnt/c/Users/Administrator/Desktop/MaruxOS/config"
for d in xterm mc firefox qterminal pcmanfm-qt featherpad lximage-qt speedcrunch lxqt-archiver qps; do
  cmp -s "$CFGWIN/applications/$d.desktop" "$LFS/usr/share/applications/$d.desktop" || { echo "🚨 ABORT: $d.desktop이 config 원본과 다름(패키지 재설치가 덮어씀? → setup-desktop-config 재적용)"; exit 1; }
  ic=$(grep -m1 '^Icon=' "$LFS/usr/share/applications/$d.desktop" | cut -d= -f2-)
  if [[ "$ic" == /* ]]; then [ -f "$LFS$ic" ] || { echo "🚨 ABORT: $d.desktop Icon 파일 없음 $ic"; exit 1; }
  else echo "🚨 ABORT: $d.desktop Icon이 테마 이름($ic) — 아이콘 테마 부재로 투명 표시됨"; exit 1; fi
done
for l in "$LFS"/root/.idesktop/*.lnk; do
  ic=$(grep -m1 'Icon:' "$l" | awk '{print $2}'); [ -f "$LFS$ic" ] || { echo "🚨 ABORT: idesk $(basename "$l") Icon 파일 없음 $ic"; exit 1; }
done
echo "  ✓ .desktop 10종 = config 원본 (바이트 일치) + Icon 파일 실존 + idesk 아이콘 실존"

# 🔴 v30: 자동 로그인 + X 자동 기동 (config v13)
grep -q '^1:2345:respawn:/sbin/agetty --autologin root --noclear tty1 9600$' "$LFS/etc/inittab" || { echo "🚨 ABORT: inittab tty1 autologin 없음(config v13 미적용)"; exit 1; }
grep -a -q autologin "$LFS/sbin/agetty" || { echo "🚨 ABORT: agetty --autologin 미지원"; exit 1; }   # strings|grep -q 는 pipefail 아래 SIGPIPE 거짓 실패
for bp in "$LFS/root/.bash_profile" "$LFS/etc/skel/.bash_profile"; do
  [ -f "$bp" ] || { echo "🚨 ABORT: $bp 없음"; exit 1; }
  grep -q '/dev/tty1' "$bp" && grep -q '^  startx' "$bp" || { echo "🚨 ABORT: $bp 에 tty1 startx 가드 없음"; exit 1; }
  grep -q 'exec startx' "$bp" && { echo "🚨 ABORT: $bp 가 exec startx (실패 시 respawn 루프 위험) — 정책 위반"; exit 1; }
  bash -n "$bp" || { echo "🚨 ABORT: $bp 문법 오류"; exit 1; }
done
echo "  ✓ tty1 autologin + startx 프로필(root/skel) + 시리얼 getty 유지 정책"

# 🔴 v31: FeatherPad (배치 E) + MIME 기본앱 (config v14)
[ -f "$B/.e-COMPLETE" ] || { echo "🚨 ABORT: 배치 E 미완(.e-COMPLETE 없음)"; exit 1; }
[ -x "$LFS/usr/bin/featherpad" ] || { echo "🚨 ABORT: featherpad 없음"; exit 1; }
readelf -h "$LFS/usr/bin/featherpad" | grep -q AArch64 || { echo "🚨 ABORT: featherpad가 AArch64가 아님"; exit 1; }
ls "$LFS/usr/lib/libQt5Svg.so.5"* >/dev/null 2>&1 || { echo "🚨 ABORT: libQt5Svg 없음(FeatherPad 기동 불가)"; exit 1; }
grep -q '^text/plain=featherpad.desktop' "$LFS/etc/xdg/mimeapps.list" && grep -q '^text/plain=featherpad.desktop' "$LFS/usr/share/applications/mimeapps.list" || { echo "🚨 ABORT: mimeapps.list text/plain→featherpad 없음"; exit 1; }
grep -q '^text/plain=.*featherpad.desktop' "$LFS/usr/share/applications/mimeinfo.cache" || { echo "🚨 ABORT: mimeinfo.cache 없음/불일치"; exit 1; }
grep -q '<command>featherpad</command>' "$LFS/etc/xdg/openbox/menu.xml" || { echo "🚨 ABORT: openbox 메뉴에 Text Editor 없음"; exit 1; }
[ -f "$LFS/root/.idesktop/editor.lnk" ] || { echo "🚨 ABORT: idesk editor.lnk 없음"; exit 1; }
echo "  ✓ FeatherPad + qtsvg + MIME 기본앱 + 메뉴/바탕화면"
[ -f "$LFS/usr/share/pixmaps/maruxos/marux-editor.png" ] || { echo "🚨 ABORT: marux-editor.png 없음(config v15 미적용)"; exit 1; }
grep -q 'marux-editor.png' "$LFS/usr/share/applications/featherpad.desktop" && grep -q 'marux-editor.png' "$LFS/root/.idesktop/editor.lnk" || { echo "🚨 ABORT: 편집기 아이콘이 marux-editor.png가 아님"; exit 1; }
echo "  ✓ 편집기 아이콘 marux-editor.png"

# 🔴 v32: 배치 T 툴 4종
[ -f "$B/.t-COMPLETE" ] || { echo "🚨 ABORT: 배치 T 미완(.t-COMPLETE 없음)"; exit 1; }
for t in lximage-qt speedcrunch lxqt-archiver qps; do
  [ -x "$LFS/usr/bin/$t" ] || { echo "🚨 ABORT: $t 없음"; exit 1; }
  readelf -h "$LFS/usr/bin/$t" | grep -q AArch64 || { echo "🚨 ABORT: $t 아키텍처 오류"; exit 1; }
  grep -q "<command>$t" "$LFS/etc/xdg/openbox/menu.xml" || { echo "🚨 ABORT: 메뉴에 $t 없음"; exit 1; }
done
ls "$LFS/usr/lib/libjson-glib-1.0.so"* >/dev/null 2>&1 || { echo "🚨 ABORT: json-glib 없음(archiver 기동 불가)"; exit 1; }
grep -q '^image/png=lximage-qt.desktop' "$LFS/etc/xdg/mimeapps.list" && grep -q '^application/zip=lxqt-archiver.desktop' "$LFS/etc/xdg/mimeapps.list" || { echo "🚨 ABORT: mimeapps 이미지/압축 기본앱 없음"; exit 1; }
echo "  ✓ 배치 T: lximage-qt·speedcrunch·lxqt-archiver·qps + MIME"
grep -q 'MaruxOS: FORTIFY' "$B/qt-cross-toolchain.cmake" || { echo "🚨 ABORT: CMake 툴체인에 FORTIFY 주입 없음"; exit 1; }
bash /mnt/c/Users/Administrator/Desktop/MaruxOS/scripts/gate-qt-launch-arm64.sh || { echo "🚨 ABORT: Qt 기동 게이트 실패"; exit 1; }

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
for d in qterminal pcmanfm-qt firefox; do
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
echo "[5/8] rootfs 복사 — 슬림 (개발 파일·소스·컴파일러 제외) $(date +%H:%M)"
MNT="$(mktemp -d)"; mount "${LOOP}p2" "$MNT"
EXCL=( --exclude='/tools' --exclude='/sources' --exclude='/proc/*' --exclude='/sys/*' --exclude='/run/*' --exclude='/tmp/*'
  --exclude='/usr/include' --exclude='/usr/share/doc' --exclude='/usr/share/man' --exclude='/usr/share/info' --exclude='/usr/share/gtk-doc'
  --exclude='/usr/share/gir-1.0' --exclude='/usr/share/vala-0.56' --exclude='/usr/share/vala' --exclude='/usr/share/i18n' --exclude='/usr/share/aclocal'
  --exclude='/usr/lib/cmake' --exclude='/usr/lib/pkgconfig' --exclude='/usr/share/pkgconfig' --exclude='/usr/mkspecs' --exclude='/usr/lib/qt5/mkspecs'
  --exclude='*.la' --exclude='/usr/lib/*.a' --exclude='/usr/lib/python3*' --exclude='/usr/bin/python3*' --exclude='/usr/bin/pip3*' --exclude='/usr/bin/idle3*' --exclude='/usr/bin/pydoc3*'
  --exclude='/usr/share/vim/vim*/doc' --exclude='/usr/share/vim/vim*/tutor' --exclude='/usr/doc' --exclude='/var/log/*' --exclude='/root/.cache' --exclude='/usr/src' )
if [ -z "${SLIM_KEEP_GCC:-}" ]; then
  EXCL+=( --exclude='/usr/libexec/gcc' --exclude='/usr/lib/gcc' --exclude='/usr/aarch64-lfs-linux-gnu' --exclude='/usr/lib/bfd-plugins' --exclude='/usr/lib/ldscripts' )
  for b in gcc g++ c++ cpp cc gcc-ar gcc-nm gcc-ranlib gcov gcov-dump gcov-tool lto-dump aarch64-lfs-linux-gnu-* as ld ld.bfd ld.gold objdump objcopy ar ranlib nm strip readelf addr2line c++filt size strings gprof elfedit dwp; do
    EXCL+=( --exclude="/usr/bin/$b" ); done
  echo "  컴파일러 제외 (SLIM_KEEP_GCC 미설정)"
fi
rsync -aHAX --numeric-ids "${EXCL[@]}" "$LFS"/ "$MNT"/
# locale: ko·en만 (컴파일된 /usr/lib/locale은 유지)
find "$MNT/usr/share/locale" -mindepth 1 -maxdepth 1 -type d ! -name 'ko*' ! -name 'en*' -exec rm -rf {} + 2>/dev/null || true
rm -rf "$MNT/usr/share/gettext" 2>/dev/null || true
echo "  복사+정리 후: $(du -sh "$MNT" | cut -f1) $(date +%H:%M)"
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
echo "  [5b2] root 비번 → 공개용 기본값 (marux)"
ROOT_PW="${MARUX_ROOT_PW:-marux}"
PWHASH=$(openssl passwd -6 "$ROOT_PW") || { echo "🚨 ABORT: openssl passwd 실패"; exit 1; }
# shadow: root 행의 2번째 필드 교체 (sed 구분자 충돌 방지 위해 awk)
awk -v h="$PWHASH" 'BEGIN{FS=OFS=":"} $1=="root"{$2=h} {print}' "$MNT/etc/shadow" > "$MNT/etc/shadow.new" && cat "$MNT/etc/shadow.new" > "$MNT/etc/shadow" && rm -f "$MNT/etc/shadow.new"
chmod 600 "$MNT/etc/shadow"
CUR=$(awk -F: '$1=="root"{print $2}' "$MNT/etc/shadow")
SALT=$(echo "$CUR" | cut -d'$' -f3)
[ "$(openssl passwd -6 -salt "$SALT" "$ROOT_PW")" = "$CUR" ] && echo "  ✓ root 비번 = $ROOT_PW (sha512 검증)" || { echo "🚨 ABORT: root 비번 해시 검증 실패"; exit 1; }
echo "  [5c] strip --strip-unneeded (ELF, /opt/firefox 제외) $(date +%H:%M)"
STRIP=aarch64-linux-gnu-strip; command -v $STRIP >/dev/null || { echo "🚨 ABORT: $STRIP 없음"; exit 1; }
find "$MNT/usr" "$MNT/lib" "$MNT/bin" "$MNT/sbin" -xdev -type f \( -name '*.so*' -o -perm /111 \) -not -path "$MNT/opt/*" -print0 2>/dev/null \
  | xargs -0 -P 16 -n 50 sh -c 'for f in "$@"; do case "$(head -c 4 "$f" | od -An -c | tr -d " ")" in *177ELF*) '"$STRIP"' --strip-unneeded "$f" 2>/dev/null || true;; esac; done' _
file -L "$MNT/usr/lib/libc.so.6" | grep -q ' stripped' && echo "  ✓ strip 표본: libc.so.6 stripped" || { echo "🚨 ABORT: libc.so.6 여전히 unstripped"; exit 1; }
echo "  strip 후: $(du -sh "$MNT" | cut -f1) $(date +%H:%M)"
echo "  [5d] 라이선스 동봉"
LD="$MNT/usr/share/licenses"; mkdir -p "$LD/MaruxOS" "$LD/pkg"
cp -f "$WINROOT"/config/licenses/* "$LD/"; rm -f "$LD/CC0-1.0.txt"; cp -a "$LICSRC/pkg/." "$LD/pkg/"
cp -f "$WINROOT/LICENSE" "$LD/MaruxOS/LICENSE"; cp -f "$WINROOT/THIRD-PARTY-LICENSES.md" "$WINROOT/SOURCES.md" "$LD/MaruxOS/"; mkdir -p "$LD/MaruxOS/patches"; cp -f "$WINROOT"/patches/*.patch "$WINROOT/patches/README.md" "$LD/MaruxOS/patches/"
mkdir -p "$MNT/lib/firmware"; cp -f "$WINROOT/config/licenses/LICENCE.cypress" "$WINROOT/config/licenses/LICENCE.broadcom_bcm43xx" "$MNT/lib/firmware/"; cp -f "$WINROOT/config/licenses/wireless-regdb-LICENSE.txt" "$MNT/lib/firmware/LICENSE.wireless-regdb"
[ -d "$MNT/usr/share/fonts/nanum" ] && cp -f "$WINROOT/config/licenses/OFL-1.1.txt" "$MNT/usr/share/fonts/nanum/OFL.txt"
cat > "$LD/README" <<'LR'
MaruxOS 2.0.0 — licenses
  MaruxOS/            MaruxOS's own work: The Unlicense (public domain). THIRD-PARTY-LICENSES.md lists every component.
  pkg/<package>/      license text taken from each upstream source tarball
  *.txt, LICENCE.*    common license texts (GPL/LGPL/MPL/OFL/...) and firmware redistribution licenses
  Sources & patches:  MaruxOS/SOURCES.md, MaruxOS/patches/ (also https://github.com/ProgrammingYJ/MaruxOS)
LR
echo "  [5e] 슬림 게이트"
[ -e "$MNT/sources" ] && { echo "🚨 ABORT: /sources가 이미지에 남음"; exit 1; }
[ -e "$MNT/usr/include" ] && { echo "🚨 ABORT: /usr/include 남음"; exit 1; }
for l in libgcc_s.so.1 libstdc++.so.6 libc.so.6 libQt5Core.so.5 libgtk-3.so.0; do ls "$MNT/usr/lib/$l" >/dev/null 2>&1 || ls "$MNT/lib/$l" >/dev/null 2>&1 || { echo "🚨 ABORT: 런타임 라이브러리 $l 없음"; exit 1; }; done
[ -z "${SLIM_KEEP_GCC:-}" ] && [ -e "$MNT/usr/libexec/gcc" ] && { echo "🚨 ABORT: gcc libexec 남음"; exit 1; }
# NEEDED 해석: 실행파일·공유라이브러리 전부 (누락 0)
# (1차 발사: readelf가 비-ELF(+x 스크립트)에 에러 → pipefail+set -e가 대입문을 조용히 죽임 → 파이프라인을 || true로 격리)
NEEDED_LIST=$(mktemp)
{ find "$MNT/usr/bin" "$MNT/usr/sbin" "$MNT/usr/lib" "$MNT/usr/libexec" "$MNT/usr/plugins" -xdev -type f \( -name '*.so*' -o -perm /111 \) -print0 2>/dev/null \
  | xargs -0 readelf -d 2>/dev/null | grep -o 'Shared library: \[[^]]*\]' | sed 's/.*\[\(.*\)\]/\1/' | sort -u > "$NEEDED_LIST"; } || true
[ -s "$NEEDED_LIST" ] || { echo "🚨 ABORT: NEEDED 목록이 비어있음(readelf 실패?)"; exit 1; }
# (2차 발사: `ls a b glob`은 하나라도 없으면 실패 → 전부 누락 오판. 경로별 개별 검사 + 글롭은 compgen)
MISS=""; while read -r n; do
  # (3차: libperl.so는 /usr/lib/perl5/…/CORE/ 깊숙이 — RPATH로 해석됨 → 재귀 탐색 폴백)
  [ -e "$MNT/usr/lib/$n" ] || [ -e "$MNT/lib/$n" ] || [ -e "$MNT/lib64/$n" ] || [ -e "$MNT/usr/lib64/$n" ] || compgen -G "$MNT/usr/lib/*/$n" >/dev/null \
    || [ -n "$(find "$MNT/usr/lib" "$MNT/opt" -name "$n" -print -quit 2>/dev/null)" ] || MISS="$MISS $n"
done < "$NEEDED_LIST"
echo "  NEEDED 고유 $(wc -l < "$NEEDED_LIST")개 검사"; rm -f "$NEEDED_LIST"
[ -z "$MISS" ] && echo "  ✓ NEEDED 전부 해석" || { echo "🚨 ABORT: NEEDED 누락: $(echo $MISS | tr '\n' ' ')"; exit 1; }
# python 런타임 참조: xinitrc·init.d·.desktop·독 런처에서 0
# (4차: 'python' 단어 검사는 MimeType=text/x-python 에 오탐 → 실행 참조만: Exec=/shebang/절대경로)
grep -rlE '(^Exec=.*python|^#!.*python|/usr/bin/python)' "$MNT/etc/X11/xinit/xinitrc" "$MNT/etc/rc.d/init.d" "$MNT/usr/share/applications" "$MNT/root/.config/plank" 2>/dev/null && { echo "🚨 ABORT: python 실행 참조가 부팅/데스크톱 경로에 있음"; exit 1; }
echo "  ✓ python 참조 0 (부팅/데스크톱 경로)"
for f in usr/share/licenses/MaruxOS/LICENSE usr/share/licenses/UNLICENSE.txt usr/share/licenses/GPL-2.0.txt usr/share/licenses/LGPL-3.0.txt usr/share/licenses/MPL-2.0.txt lib/firmware/LICENCE.cypress usr/share/fonts/nanum/OFL.txt usr/share/licenses/pkg/openbox-3.6.1/COPYING; do
  [ -s "$MNT/$f" ] || { echo "🚨 ABORT: 이미지에 $f 없음"; exit 1; }; done
echo "  ✓ 라이선스 동봉 ($(ls "$LD/pkg" | wc -l) pkg)"
echo "  [5f] 기동 게이트 — 슬림 사본에서 재실행 $(date +%H:%M)"
QTGATE_ROOT="$MNT" bash "$WINROOT/scripts/gate-qt-launch-arm64.sh" || { echo "🚨 ABORT: 슬림 사본 기동 게이트 실패 (strip/제거가 무언가를 깼다)"; exit 1; }
for m in dev/pts dev sys proc; do mountpoint -q "$MNT/$m" && umount "$MNT/$m"; done
rm -rf "$MNT/tmp/"* "$MNT/run/"* 2>/dev/null || true
echo "  최종 rootfs: $(du -sh "$MNT" | cut -f1)"
sync; umount "$MNT"
echo "[6/8] boot 파티션"
mount "${LOOP}p1" "$MNT"
cp "$KIMG" "$MNT/kernel8.img"; cp "$KDTB" "$MNT/bcm2711-rpi-4-b.dtb"; cp "$FW/start4.elf" "$MNT/start4.elf"; cp "$FW/fixup4.dat" "$MNT/fixup4.dat"
cp -f "$WINROOT/config/licenses/LICENCE.broadcom" "$MNT/LICENCE.broadcom"   # v33: Broadcom 부트 펌웨어 재배포 조건
[ -s "$MNT/LICENCE.broadcom" ] || { echo "🚨 ABORT: boot 파티션 LICENCE.broadcom 없음"; exit 1; }
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
echo "===== ✅ v34 완료 $(date) ====="
ls -lh "$OUT/$OUTPUT_NAME.xz"; sha256sum "$OUT/$OUTPUT_NAME.xz"
