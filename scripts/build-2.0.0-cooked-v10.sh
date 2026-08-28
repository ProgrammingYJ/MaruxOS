#!/bin/bash
# MaruxOS 2.0.0 "Cooked" - cooked-v10 Build Script (x86_64 **데스크톱 패리티** ISO)
# =================================================
# v10 (2026-08-28, 사용자 "ISO도 img처럼 Qt랑 앱 7종 등등 다"):
#   - squashfs 원천 = **x86 패리티 rootfs** (/home/administrator/MaruxOS/x86-parity/rootfs-lfs-parity)
#     = v9의 rootfs-lfs 사본 + 호스트 크로스(gcc-13 래퍼 + --sysroot)로 넣은 ARM64 v34 동등 데스크톱:
#     Qt5 5.15.2 · QTerminal · PCManFM-Qt · FeatherPad · LXImage-Qt · SpeedCrunch · LXQt Archiver · qps
#     · Plank(libwnck 43.2) · picom · marux-quicksettings(상태 바) · alsa-utils · ibus-hangul 한/영 노출 패치.
#     원본 build/rootfs-lfs 는 그대로(1.x~v9 롤백 자산).
#   - config = setup-desktop-config-x86-v1.sh (ARM64 v15 이식). 공유 menu.xml(Qt) 사용 — v9의 menu-x86.xml 은 유산.
#   - **스테이징 슬림**(ARM64 v33 방식): rootfs → stage-v10 rsync(소스·헤더·컴파일러·python·정적lib·문서 제외)
#     + strip + /usr/share/licenses 동봉 + NEEDED 해석·python 참조·라이선스 게이트 → mksquashfs 는 stage 에서.
#   - 게이트 승격 그대로: FORTIFY=2 통과본 SHA 대조 / .desktop config 바이트 일치 / **네이티브 chroot 기동 게이트**
#     (gate-qt-launch-x86.sh, Xvfb xcb, 슬림 사본에서 재실행).
#   - root 비번 marux, tty1 자동 로그인(x86 유산 inittab) + startx(비exec) — v9와 동일 체감.
#   - 릴리즈 사본 MaruxOS-2.0.0-x86_64.iso 갱신 → GitHub 자산 교체 대상.
#   (v9 이전 헤더/롤백 서사는 build-2.0.0-cooked-v9.sh 참조)
#
# 실행: WSL root. WSL_KERNEL_BUILD_ROOT=/home/administrator/MaruxOS-kernel-build (root로 돌리면 $USER=root 함정)
#   qemu-system-x86_64 -m 4G -enable-kvm -device intel-hda -device hda-duplex -cdrom output/MaruxOS-2.0.0-cooked-v10.iso

set -e
set -o pipefail
BUILD_START=$(date +%s)
log() { local stage="$1"; shift; printf "[%s][+%4ds][%s] %s\n" "$(date +%H:%M:%S)" "$(( $(date +%s) - BUILD_START ))" "$stage" "$*"; }

# ============================================================================
# Paths & config
# ============================================================================
PROJECT_ROOT="/mnt/c/Users/Administrator/Desktop/MaruxOS"
WORK_DIR="/home/administrator/MaruxOS/build"
PARITY_B="/home/administrator/MaruxOS/x86-parity"
SQUASHFS_ROOT="$PARITY_B/rootfs-lfs-parity"      # v10: 패리티 rootfs
STAGE="$PARITY_B/stage-v10"                       # v10: 슬림 스테이징(이미지에 실리는 실체)
ISO_DIR="$WORK_DIR/iso-build"
EFFECTIVE_USER="${SUDO_USER:-$USER}"
WSL_KERNEL_BUILD_ROOT="${WSL_KERNEL_BUILD_ROOT:-/home/$EFFECTIVE_USER/MaruxOS-kernel-build}"
KERNEL_BUILD_DIR="$WSL_KERNEL_BUILD_ROOT/output"
KERNEL_MODULES_STAGING="$WSL_KERNEL_BUILD_ROOT/modules"
CONFIG_DIR="$PROJECT_ROOT/config"
SCRIPT_DIR="$PROJECT_ROOT/scripts"
OUTPUT_DIR="$PROJECT_ROOT/output"
LICSRC="/home/administrator/MaruxOS-arm64/licenses"   # gen-sources-and-patches-arm64.sh 수집본(패키지별 라이선스 원문) 재사용
GATE_X86="$SCRIPT_DIR/gate-qt-launch-x86.sh"

source "$CONFIG_DIR/marux-release.conf"
source "$CONFIG_DIR/lfs-versions.conf"

VERSION="cooked-v10"
ISO_FILENAME="MaruxOS-${DISTRO_VERSION}-${VERSION}.iso"

echo "=========================================="
echo "MaruxOS $DISTRO_VERSION \"$DISTRO_CODENAME\" - $VERSION (x86_64 데스크톱 패리티)"
echo "Kernel: Linux $KERNEL_VERSION $KERNEL_TYPE"
echo "=========================================="
cd "$WORK_DIR"

# ============================================================================
# [PRE] 게이트
# ============================================================================
echo "[PRE] Pre-flight checks..."
[[ "$SQUASHFS_ROOT" == *"x86-parity"* ]] || { echo "🚨 ABORT: squashfs 원천이 패리티 rootfs가 아님"; exit 1; }
[[ "$SQUASHFS_ROOT" == *"MaruxOS-arm64"* ]] && { echo "🚨 ABORT: ARM64 rootfs로 x86 ISO"; exit 1; }
MISSING_TOOLS=()
for tool in mksquashfs xorriso cpio gzip gunzip sed find chroot sha256sum sha512sum rsync strip file readelf openssl Xvfb; do
    command -v "$tool" >/dev/null 2>&1 || MISSING_TOOLS+=("$tool")
done
[ ${#MISSING_TOOLS[@]} -eq 0 ] || { echo "ERROR: Missing tools: ${MISSING_TOOLS[*]} (apt install squashfs-tools xorriso cpio rsync binutils file xvfb)"; exit 1; }
echo "  ✓ build tools present"

NEW_VMLINUZ="$KERNEL_BUILD_DIR/vmlinuz-$KERNEL_VERSION"
NEW_MODULES_DIR="$KERNEL_MODULES_STAGING/lib/modules/$KERNEL_VERSION"
[ -f "$NEW_VMLINUZ" ] || { echo "ERROR: $NEW_VMLINUZ not found (WSL_KERNEL_BUILD_ROOT=$WSL_KERNEL_BUILD_ROOT)"; exit 1; }
[ -f "$NEW_MODULES_DIR/modules.dep" ] || { echo "ERROR: modules.dep not found in $NEW_MODULES_DIR"; exit 1; }
[ -d "$SQUASHFS_ROOT/usr" ] || { echo "ERROR: parity rootfs not found at $SQUASHFS_ROOT"; exit 1; }
[ -f "$ISO_DIR/boot/initrd.img" ] || { echo "ERROR: carry-over initrd.img not found at $ISO_DIR/boot/initrd.img"; exit 1; }
AVAIL_GB=$(( $(df -k "$PARITY_B" | awk 'NR==2 {print $4}') / 1024 / 1024 ))
[ "$AVAIL_GB" -ge 8 ] || { echo "ERROR: 공간 부족 ${AVAIL_GB}GB (스테이징+squashfs+ISO ≥ 8GB)"; exit 1; }
echo "  ✓ kernel artifacts / rootfs / initrd / disk ${AVAIL_GB}GB"

# --- 패리티 배치 마커 ---
for m in .q-COMPLETE .f-COMPLETE .e-COMPLETE .t-COMPLETE .x-COMPLETE .cfg-x86-v1; do
    [ -f "$PARITY_B/$m" ] || { echo "🚨 ABORT: 배치 마커 $PARITY_B/$m 없음"; exit 1; }; done
for m in .p-COMPLETE .p2-COMPLETE .q-COMPLETE .5A-COMPLETE .x-COMPLETE; do
    [ -f "$SQUASHFS_ROOT/sources/$m" ] || { echo "🚨 ABORT: rootfs 마커 sources/$m 없음"; exit 1; }; done
echo "  ✓ 배치 Q/F/E/T/X + P/P2/QS/5A + config x86 v1"

# --- 아키텍처 ---
for b in usr/bin/qterminal usr/bin/pcmanfm-qt usr/bin/featherpad usr/bin/lximage-qt usr/bin/speedcrunch usr/bin/lxqt-archiver usr/bin/qps usr/bin/plank usr/bin/picom usr/bin/marux-quicksettings usr/bin/amixer usr/lib/libQt5Core.so.5 usr/lib/ibus/ibus-engine-hangul; do
    [ -e "$SQUASHFS_ROOT/$b" ] || { echo "🚨 ABORT: $b 없음"; exit 1; }
    readelf -h "$SQUASHFS_ROOT/$b" | grep -q 'X86-64' || { echo "🚨 ABORT: $b 가 X86-64 아님"; exit 1; }
done
echo "  ✓ 데스크톱 바이너리 13종 X86-64"

# --- Qt FORTIFY=2 통과본 SHA 대조 (함정 #35) ---
[ -f "$PARITY_B/.q-FORTIFY2-OK" ] || { echo "🚨 ABORT: .q-FORTIFY2-OK 없음 — gate-qt-fortify-x86.sh 먼저"; exit 1; }
while read -r sha path; do
    [[ "$sha" == \#* ]] && continue
    cur=$(sha256sum "$SQUASHFS_ROOT/$path" | awk '{print $1}')
    [ "$cur" = "$sha" ] || { echo "🚨 ABORT: $path 가 기동 게이트 통과본과 다름"; exit 1; }
done < "$PARITY_B/.q-FORTIFY2-OK"
echo "  ✓ Qt 스택 = FORTIFY 게이트 통과본 (SHA 일치)"

# --- config → rootfs 무결성 (존재 ≠ 내용, 함정 #36) ---
for d in xterm mc firefox qterminal pcmanfm-qt featherpad lximage-qt speedcrunch lxqt-archiver qps; do
    cmp -s "$CONFIG_DIR/applications/$d.desktop" "$SQUASHFS_ROOT/usr/share/applications/$d.desktop" || { echo "🚨 ABORT: $d.desktop ≠ config 원본 (setup-desktop-config-x86 재적용)"; exit 1; }
    ic=$(grep -m1 '^Icon=' "$SQUASHFS_ROOT/usr/share/applications/$d.desktop" | cut -d= -f2-)
    [[ "$ic" == /* ]] && [ -f "$SQUASHFS_ROOT$ic" ] || { echo "🚨 ABORT: $d.desktop Icon 부재/테마명: $ic"; exit 1; }
done
for l in "$SQUASHFS_ROOT"/root/.idesktop/*.lnk; do
    ic=$(grep -m1 'Icon:' "$l" | awk '{print $2}'); [ -f "$SQUASHFS_ROOT$ic" ] || { echo "🚨 ABORT: idesk $(basename "$l") Icon 없음"; exit 1; }
done
XI="$SQUASHFS_ROOT/etc/X11/xinit/xinitrc"
for k in QT_QPA_PLATFORM_PLUGIN_PATH GSETTINGS_BACKEND=keyfile /usr/bin/plank marux-quicksettings picom bamfdaemon 'aplay -q -f S16_LE'; do
    grep -q "$k" "$XI" || { echo "🚨 ABORT: xinitrc에 '$k' 없음(config x86 v1 미적용)"; exit 1; }; done
grep -q tint2 "$XI" && { echo "🚨 ABORT: xinitrc tint2 잔재"; exit 1; }
[ -f "$SQUASHFS_ROOT/etc/xdg/tint2/tint2rc" ] && { echo "🚨 ABORT: tint2rc 잔존"; exit 1; }
cmp -s "$XI" "$SQUASHFS_ROOT/root/.xinitrc" && cmp -s "$XI" "$SQUASHFS_ROOT/etc/skel/.xinitrc" || { echo "🚨 ABORT: xinitrc 3경로 불일치"; exit 1; }
grep -q '<command>featherpad</command>' "$SQUASHFS_ROOT/etc/xdg/openbox/menu.xml" || { echo "🚨 ABORT: 메뉴에 Text Editor 없음"; exit 1; }
grep -q 'xterm' "$SQUASHFS_ROOT/etc/xdg/openbox/menu.xml" && { echo "🚨 ABORT: 메뉴에 xterm 잔재(menu-x86.xml 유산?)"; exit 1; }
[ -x "$SQUASHFS_ROOT/usr/bin/xterm" ] && [ -x "$SQUASHFS_ROOT/usr/bin/mc" ] || { echo "🚨 ABORT: xterm/mc 폴백이 사라짐"; exit 1; }
grep -q '^text/plain=featherpad.desktop' "$SQUASHFS_ROOT/etc/xdg/mimeapps.list" && grep -q '^image/png=lximage-qt.desktop' "$SQUASHFS_ROOT/etc/xdg/mimeapps.list" && grep -q '^text/plain=.*featherpad' "$SQUASHFS_ROOT/usr/share/applications/mimeinfo.cache" || { echo "🚨 ABORT: MIME 기본앱 미적용"; exit 1; }
for d in qterminal pcmanfm-qt firefox; do [ -f "$SQUASHFS_ROOT/root/.config/plank/dock1/launchers/$d.dockitem" ] || { echo "🚨 ABORT: $d.dockitem 없음"; exit 1; }; done
grep -qE '^1:2345:respawn:/sbin/agetty --autologin root .*tty1' "$SQUASHFS_ROOT/etc/inittab" || { echo "🚨 ABORT: inittab tty1 autologin 없음"; exit 1; }
grep -a -q autologin "$SQUASHFS_ROOT/sbin/agetty" || { echo "🚨 ABORT: agetty --autologin 미지원"; exit 1; }
for bp in "$SQUASHFS_ROOT/root/.bash_profile" "$SQUASHFS_ROOT/etc/skel/.bash_profile"; do
    grep -q '/dev/tty1' "$bp" && grep -q '^  startx' "$bp" || { echo "🚨 ABORT: $bp tty1 startx 가드 없음"; exit 1; }
    grep -q 'exec startx' "$bp" && { echo "🚨 ABORT: $bp 가 exec startx (respawn 루프 위험)"; exit 1; }
done
# plank 전제: libwnck 43.2 (43.0 = bamf 즉사). x86엔 /usr/lib64 에 43.0 잔재가 공존 → *실제 해석*이 /usr/lib 이어야 함
grep -q "^Version: 43.2" "$SQUASHFS_ROOT/usr/lib/pkgconfig/libwnck-3.0.pc" || { echo "🚨 ABORT: libwnck 43.2 아님"; exit 1; }
WNCK=$(chroot "$SQUASHFS_ROOT" /usr/bin/ldd /usr/libexec/bamf/bamfdaemon 2>/dev/null | awk '/libwnck-3.so.0/{print $3}')
[ "$WNCK" = "/usr/lib/libwnck-3.so.0" ] || { echo "🚨 ABORT: bamfdaemon이 해석하는 libwnck = '$WNCK' (≠ /usr/lib 43.2)"; exit 1; }
[ -f "$SQUASHFS_ROOT/usr/share/glib-2.0/schemas/40_maruxos.gschema.override" ] && grep -qa "net.launchpad.plank" "$SQUASHFS_ROOT/usr/share/glib-2.0/schemas/gschemas.compiled" || { echo "🚨 ABORT: plank gschema/override"; exit 1; }
grep -qa "marux-ime-mode" "$SQUASHFS_ROOT/usr/lib/ibus/ibus-engine-hangul" || { echo "🚨 ABORT: 한/영 노출 패치 미반영"; exit 1; }
echo "  ✓ config x86 v1 무결성 (desktop·icons·xinitrc·menu·MIME·dock·autologin·wnck·ime)"

# --- 라이선스 자산 ---
for f in UNLICENSE.txt GPL-2.0.txt GPL-3.0.txt LGPL-2.1.txt LGPL-3.0.txt MPL-2.0.txt OFL-1.1.txt GCC-RUNTIME-EXCEPTION-3.1.txt Info-ZIP-LICENSE.txt; do
    [ -s "$CONFIG_DIR/licenses/$f" ] || { echo "🚨 ABORT: config/licenses/$f 없음"; exit 1; }
    grep -qi '<html' "$CONFIG_DIR/licenses/$f" && { echo "🚨 ABORT: $f 가 HTML"; exit 1; }
done
for f in LICENSE THIRD-PARTY-LICENSES.md SOURCES.md patches/README.md; do [ -s "$PROJECT_ROOT/$f" ] || { echo "🚨 ABORT: $f 없음"; exit 1; }; done
[ "$(ls "$LICSRC/pkg" 2>/dev/null | wc -l)" -ge 150 ] || { echo "🚨 ABORT: 패키지별 라이선스 수집본($LICSRC/pkg) 부족"; exit 1; }
grep -q "Unlicense" "$PROJECT_ROOT/LICENSE" || { echo "🚨 ABORT: LICENSE가 Unlicense 아님"; exit 1; }
echo "  ✓ 라이선스 자산 (공통 9 + pkg $(ls "$LICSRC/pkg" | wc -l) + MaruxOS 4)"
# --- sanitize ---
[ -f "$SQUASHFS_ROOT/etc/wpa_supplicant.conf" ] && grep -q 'psk=' "$SQUASHFS_ROOT/etc/wpa_supplicant.conf" && { echo "🚨 ABORT: wpa_supplicant.conf에 자격증명"; exit 1; }
[ -f "$GATE_X86" ] || { echo "🚨 ABORT: $GATE_X86 없음"; exit 1; }
echo "✅ [PRE] 게이트 통과"
echo ""

# ============================================================================
# [1] Cleanup mounts / [2] ISO dir
# ============================================================================
echo "[1] Cleaning up..."
for R in "$SQUASHFS_ROOT" "$STAGE"; do for m in tmp/.X11-unix dev/pts dev sys proc run; do mountpoint -q "$R/$m" 2>/dev/null && umount "$R/$m" || true; done; done
mountpoint -q "$STAGE" 2>/dev/null && umount "$STAGE" || true
echo "[2] Setting up ISO directory..."
mkdir -p "$ISO_DIR/boot/grub" "$ISO_DIR/live"

# ============================================================================
# [KERNEL] Sync kernel + modules into parity rootfs (v9 동일 로직)
# ============================================================================
echo "==== [KERNEL] 6.18.26 sync ===="
LEGACY_BACKUP_DIR="$WORK_DIR/legacy-1.x-kernel"
rm -rf "$SQUASHFS_ROOT/lib/modules"; rm -f "$SQUASHFS_ROOT/boot"/vmlinuz*
mkdir -p "$SQUASHFS_ROOT/boot" "$SQUASHFS_ROOT/lib/modules"
cp "$NEW_VMLINUZ" "$SQUASHFS_ROOT/boot/vmlinuz-$KERNEL_VERSION-maruxos"
ln -sf "vmlinuz-$KERNEL_VERSION-maruxos" "$SQUASHFS_ROOT/boot/vmlinuz"
cp -a "$NEW_MODULES_DIR" "$SQUASHFS_ROOT/lib/modules/"
STAGING_COUNT=$(find "$NEW_MODULES_DIR" -name "*.ko*" | wc -l)
SYNCED_MODULES=$(find "$SQUASHFS_ROOT/lib/modules/$KERNEL_VERSION" -name "*.ko*" | wc -l)
[ "$SYNCED_MODULES" -gt 0 ] && [ "$STAGING_COUNT" = "$SYNCED_MODULES" ] || { echo "ERROR: module sync mismatch staging=$STAGING_COUNT synced=$SYNCED_MODULES"; exit 1; }
[ -f "$SQUASHFS_ROOT/lib/modules/$KERNEL_VERSION/modules.dep" ] || { echo "ERROR: modules.dep not synced"; exit 1; }
ROOTFS_KERNEL=$(strings "$SQUASHFS_ROOT/boot/vmlinuz-$KERNEL_VERSION-maruxos" 2>/dev/null | grep -m1 "^Linux version " | awk '{print $3}' || echo "")
if [ -n "$ROOTFS_KERNEL" ] && [[ "$ROOTFS_KERNEL" != "$KERNEL_VERSION"* ]]; then echo "ERROR: vmlinuz mismatch $ROOTFS_KERNEL"; exit 1; fi
[ -f "$KERNEL_BUILD_DIR/System.map-$KERNEL_VERSION" ] && cp "$KERNEL_BUILD_DIR/System.map-$KERNEL_VERSION" "$SQUASHFS_ROOT/boot/"
[ -f "$KERNEL_BUILD_DIR/config-$KERNEL_VERSION" ] && cp "$KERNEL_BUILD_DIR/config-$KERNEL_VERSION" "$SQUASHFS_ROOT/boot/"
log KERNEL "✓ $SYNCED_MODULES modules synced (${ROOTFS_KERNEL:-strings-n/a})"

# ============================================================================
# [3] kernel + initrd → ISO staging / [4] GRUB
# ============================================================================
echo "[3] Copying kernel + initrd to ISO staging..."
cp "$SQUASHFS_ROOT/boot/vmlinuz-$KERNEL_VERSION-maruxos" "$ISO_DIR/boot/vmlinuz"
cat > "$ISO_DIR/boot/grub/grub.cfg" << GRUB_EOF
set default=0
set timeout=5

menuentry "MaruxOS $DISTRO_VERSION \"$DISTRO_CODENAME\" - Desktop" {
    linux /boot/vmlinuz boot=live quiet
    initrd /boot/initrd.img
}

menuentry "MaruxOS $DISTRO_VERSION \"$DISTRO_CODENAME\" - Safe Mode (CLI, no KMS, no mitigations)" {
    linux /boot/vmlinuz boot=live systemd.unit=multi-user.target nomodeset mitigations=off
    initrd /boot/initrd.img
}

menuentry "MaruxOS $DISTRO_VERSION \"$DISTRO_CODENAME\" - Debug" {
    linux /boot/vmlinuz boot=live debug
    initrd /boot/initrd.img
}
GRUB_EOF
echo "[4] GRUB cfg generated"

# ============================================================================
# [5] rootfs 마무리 (locale · ibus/glib 캐시 · 메타데이터 · root 비번) — v9 [11]~[13]
# ============================================================================
echo "[5] Korean locale + caches..."
cat > "$SQUASHFS_ROOT/etc/locale.gen" << 'EOF'
en_US.UTF-8 UTF-8
ko_KR.UTF-8 UTF-8
ko_KR.EUC-KR EUC-KR
C.UTF-8 UTF-8
EOF
{ echo "LANG=ko_KR.UTF-8"; for v in LC_ALL LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY LC_MESSAGES LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT LC_IDENTIFICATION; do echo "$v=ko_KR.UTF-8"; done; } > "$SQUASHFS_ROOT/etc/locale.conf"
printf 'LANG=ko_KR.UTF-8\nLC_ALL=ko_KR.UTF-8\n' > "$SQUASHFS_ROOT/etc/environment"
mkdir -p "$SQUASHFS_ROOT/usr/lib/locale"
chroot "$SQUASHFS_ROOT" /usr/bin/localedef -i ko_KR -f UTF-8 ko_KR.UTF-8 2>/dev/null || echo "  Warning: localedef ko_KR"
chroot "$SQUASHFS_ROOT" /usr/bin/localedef -i en_US -f UTF-8 en_US.UTF-8 2>/dev/null || true
chroot "$SQUASHFS_ROOT" /usr/bin/fc-cache -f 2>/dev/null || true
chroot "$SQUASHFS_ROOT" /usr/sbin/ldconfig 2>/dev/null || true
chroot "$SQUASHFS_ROOT" /usr/bin/ibus write-cache 2>/dev/null || true
chroot "$SQUASHFS_ROOT" /usr/bin/glib-compile-schemas /usr/share/glib-2.0/schemas/ 2>/dev/null || true
chroot "$SQUASHFS_ROOT" /bin/bash -c '/usr/bin/gtk-query-immodules-3.0 > /usr/lib/gtk-3.0/3.0.0/immodules.cache 2>/dev/null' || true
grep -q ibus "$SQUASHFS_ROOT/usr/lib/gtk-3.0/3.0.0/immodules.cache" || cat >> "$SQUASHFS_ROOT/usr/lib/gtk-3.0/3.0.0/immodules.cache" << 'EOF'

"/usr/lib/gtk-3.0/3.0.0/immodules/im-ibus.so"
"ibus" "Intelligent Input Bus" "ibus10" "/usr/share/locale" ""

EOF
grep -qa "net.launchpad.plank" "$SQUASHFS_ROOT/usr/share/glib-2.0/schemas/gschemas.compiled" || { echo "🚨 ABORT: gschemas.compiled에 plank 없음(재컴파일 실패)"; exit 1; }

echo "[5b] Version metadata..."
cat > "$SQUASHFS_ROOT/etc/os-release" << OSRELEOF
NAME="$DISTRO_NAME"
PRETTY_NAME="$DISTRO_NAME $DISTRO_VERSION \"$DISTRO_CODENAME\""
ID=maruxos
ID_LIKE=lfs
VERSION="$DISTRO_VERSION"
VERSION_ID="$DISTRO_VERSION"
VERSION_CODENAME=$(echo "$DISTRO_CODENAME" | tr '[:upper:]' '[:lower:]')
HOME_URL="https://github.com/ProgrammingYJ/MaruxOS"
SUPPORT_URL="https://github.com/ProgrammingYJ/MaruxOS/issues"
BUG_REPORT_URL="https://github.com/ProgrammingYJ/MaruxOS/issues"
OSRELEOF
echo "$DISTRO_NAME $DISTRO_VERSION ($DISTRO_CODENAME)" > "$SQUASHFS_ROOT/etc/maruxos-release"
printf '%s %s "%s" \\n \\l\n\n' "$DISTRO_NAME" "$DISTRO_VERSION" "$DISTRO_CODENAME" > "$SQUASHFS_ROOT/etc/issue"
printf 'DISTRIB_ID=MaruxOS\nDISTRIB_RELEASE=%s\nDISTRIB_CODENAME=%s\nDISTRIB_DESCRIPTION="%s %s (%s)"\n' "$DISTRO_VERSION" "$DISTRO_CODENAME" "$DISTRO_NAME" "$DISTRO_VERSION" "$DISTRO_CODENAME" > "$SQUASHFS_ROOT/etc/lsb-release"
if [ -f "$SQUASHFS_ROOT/usr/bin/marux-splash" ]; then
    sed -i "s/MaruxOS [0-9]\+\.[0-9]\+\(\.[0-9]\+\)\?/MaruxOS $DISTRO_VERSION/g; s/\bPhoenix\b/$DISTRO_CODENAME/g; s/\b67\b/$DISTRO_CODENAME/g" "$SQUASHFS_ROOT/usr/bin/marux-splash"
fi
echo "[5c] root 비번 = marux (공개 기본값)"
ROOT_PW="${MARUX_ROOT_PW:-marux}"
PWHASH=$(openssl passwd -6 "$ROOT_PW")
awk -v h="$PWHASH" 'BEGIN{FS=OFS=":"} $1=="root"{$2=h} {print}' "$SQUASHFS_ROOT/etc/shadow" > "$SQUASHFS_ROOT/etc/shadow.new" && cat "$SQUASHFS_ROOT/etc/shadow.new" > "$SQUASHFS_ROOT/etc/shadow" && rm -f "$SQUASHFS_ROOT/etc/shadow.new"; chmod 600 "$SQUASHFS_ROOT/etc/shadow"
CUR=$(awk -F: '$1=="root"{print $2}' "$SQUASHFS_ROOT/etc/shadow"); SALT=$(echo "$CUR" | cut -d'$' -f3)
[ "$(openssl passwd -6 -salt "$SALT" "$ROOT_PW")" = "$CUR" ] || { echo "🚨 ABORT: root 비번 검증 실패"; exit 1; }
chmod 644 "$SQUASHFS_ROOT/etc/locale.gen" "$SQUASHFS_ROOT/etc/locale.conf" "$SQUASHFS_ROOT/etc/environment" 2>/dev/null || true
chmod 755 "$SQUASHFS_ROOT/usr/lib/ibus/ibus-engine-hangul" "$SQUASHFS_ROOT/usr/bin/idesk" 2>/dev/null || true

# ============================================================================
# [6] initrd splash text (v9 [14])
# ============================================================================
echo "[6] Updating initrd splash text..."
INITRD_WORK="/tmp/initrd-modify-$$"; mkdir -p "$INITRD_WORK"
( cd "$INITRD_WORK" && gunzip -c "$ISO_DIR/boot/initrd.img" | cpio -id 2>/dev/null )
[ -f "$INITRD_WORK/init" ] && sed -i "s/MaruxOS [0-9]\+\.[0-9]\+\(\.[0-9]\+\)\? [^ ]*/MaruxOS $DISTRO_VERSION $DISTRO_CODENAME/g" "$INITRD_WORK/init"
( cd "$INITRD_WORK" && find . | cpio -o -H newc 2>/dev/null | gzip -9 > "$ISO_DIR/boot/initrd.img" )
rm -rf "$INITRD_WORK"

# ============================================================================
# [7] 스테이징 슬림 (ARM64 v33 방식, x86 배치) — 이미지에 실리는 실체
# ============================================================================
echo "[7] Staging (slim) → $STAGE  $(date +%H:%M)"
rm -rf "$STAGE"; mkdir -p "$STAGE"
EXCL=( --exclude='/tools' --exclude='/sources' --exclude='/boot' --exclude='/proc/*' --exclude='/sys/*' --exclude='/run/*' --exclude='/tmp/*'
  --exclude='/usr/include' --exclude='/usr/share/doc' --exclude='/usr/share/man' --exclude='/usr/share/info' --exclude='/usr/share/gtk-doc'
  --exclude='/usr/share/gir-1.0' --exclude='/usr/share/vala' --exclude='/usr/share/vala-*' --exclude='/usr/share/i18n' --exclude='/usr/share/aclocal'
  --exclude='/usr/lib/cmake' --exclude='/usr/lib64/cmake' --exclude='/usr/lib/pkgconfig' --exclude='/usr/lib64/pkgconfig' --exclude='/usr/share/pkgconfig'
  --exclude='/usr/mkspecs' --exclude='/usr/lib/qt5/mkspecs'
  --exclude='*.la' --exclude='/usr/lib/*.a' --exclude='/usr/lib64/*.a' --exclude='/usr/lib/python3*' --exclude='/usr/lib64/python3*'
  --exclude='/usr/bin/python3*' --exclude='/usr/bin/pip3*' --exclude='/usr/bin/idle3*' --exclude='/usr/bin/pydoc3*' --exclude='/usr/bin/2to3*'
  --exclude='/usr/share/vim/vim*/doc' --exclude='/usr/share/vim/vim*/tutor' --exclude='/usr/doc' --exclude='/var/log/*' --exclude='/root/.cache' --exclude='/usr/src'
  --exclude='/root/*.sh' --exclude='/root/.bash_history' )
if [ -z "${SLIM_KEEP_GCC:-}" ]; then
  EXCL+=( --exclude='/usr/libexec/gcc' --exclude='/usr/lib/gcc' --exclude='/usr/lib64/gcc' --exclude='/usr/lib/bfd-plugins' --exclude='/usr/lib/ldscripts' --exclude='/usr/x86_64-*' )
  for b in gcc g++ c++ cpp cc gcc-ar gcc-nm gcc-ranlib gcov gcov-dump gcov-tool lto-dump 'x86_64-*-linux-gnu-*' as ld ld.bfd ld.gold objdump objcopy ar ranlib nm strip readelf addr2line c++filt size strings gprof elfedit dwp; do
    EXCL+=( --exclude="/usr/bin/$b" ); done
  echo "  컴파일러 제외 (SLIM_KEEP_GCC 미설정)"
fi
rsync -aHAX --numeric-ids "${EXCL[@]}" "$SQUASHFS_ROOT"/ "$STAGE"/
mkdir -p "$STAGE"/{proc,sys,run,tmp,dev,boot}; chmod 1777 "$STAGE/tmp"
find "$STAGE/usr/share/locale" -mindepth 1 -maxdepth 1 -type d ! -name 'ko*' ! -name 'en*' -exec rm -rf {} + 2>/dev/null || true
rm -rf "$STAGE/usr/share/gettext" 2>/dev/null || true
echo "  복사+정리 후: $(du -sh "$STAGE" | cut -f1) $(date +%H:%M)"

echo "  [7b] strip --strip-unneeded (ELF .so/+x, /opt 제외, 커널 모듈 제외)"
find "$STAGE/usr" "$STAGE/lib" "$STAGE/lib64" "$STAGE/bin" "$STAGE/sbin" -xdev -type f \( -name '*.so*' -o -perm /111 \) -not -path "$STAGE/opt/*" -not -path "$STAGE/lib/modules/*" -print0 2>/dev/null \
  | xargs -0 -P 16 -n 50 sh -c 'for f in "$@"; do case "$(head -c 4 "$f" | od -An -c | tr -d " ")" in *177ELF*) strip --strip-unneeded "$f" 2>/dev/null || true;; esac; done' _
file -L "$STAGE/usr/lib/libc.so.6" | grep -q ' stripped' || { echo "🚨 ABORT: libc.so.6 여전히 unstripped"; exit 1; }
echo "  strip 후: $(du -sh "$STAGE" | cut -f1) $(date +%H:%M)"

echo "  [7c] 라이선스 동봉"
LD="$STAGE/usr/share/licenses"; mkdir -p "$LD/MaruxOS/patches" "$LD/pkg"
cp -f "$CONFIG_DIR"/licenses/*.txt "$LD/"; rm -f "$LD/CC0-1.0.txt"
cp -a "$LICSRC/pkg/." "$LD/pkg/"
cp -f "$PROJECT_ROOT/LICENSE" "$LD/MaruxOS/LICENSE"; cp -f "$PROJECT_ROOT/THIRD-PARTY-LICENSES.md" "$PROJECT_ROOT/SOURCES.md" "$LD/MaruxOS/"
cp -f "$PROJECT_ROOT"/patches/*.patch "$PROJECT_ROOT/patches/README.md" "$LD/MaruxOS/patches/"
[ -d "$STAGE/usr/share/fonts/truetype/nanum" ] && cp -f "$CONFIG_DIR/licenses/OFL-1.1.txt" "$STAGE/usr/share/fonts/truetype/nanum/OFL.txt"
[ -f "$STAGE/lib/firmware/regulatory.db" ] && cp -f "$CONFIG_DIR/licenses/wireless-regdb-LICENSE.txt" "$STAGE/lib/firmware/LICENSE.wireless-regdb"
cat > "$LD/README" <<'LR'
MaruxOS 2.0.0 (x86_64) — licenses
  MaruxOS/            MaruxOS's own work: The Unlicense (public domain). THIRD-PARTY-LICENSES.md lists every component.
  pkg/<package>/      license text taken from each upstream source tarball (collection shared with the ARM64 image;
                      packages only in the ARM64 image — Pi firmware, wpa_supplicant, libnl — are listed but not shipped here)
  *.txt               common license texts (GPL/LGPL/MPL/OFL/Unlicense/...)
  Sources & patches:  MaruxOS/SOURCES.md, MaruxOS/patches/ (also https://github.com/ProgrammingYJ/MaruxOS)
LR

echo "  [7d] 슬림 게이트"
[ -e "$STAGE/sources" ] && { echo "🚨 ABORT: /sources 남음"; exit 1; }
[ -e "$STAGE/usr/include" ] && { echo "🚨 ABORT: /usr/include 남음"; exit 1; }
[ -e "$STAGE/tools" ] && { echo "🚨 ABORT: /tools 남음"; exit 1; }
[ -z "${SLIM_KEEP_GCC:-}" ] && [ -e "$STAGE/usr/libexec/gcc" ] && { echo "🚨 ABORT: gcc libexec 남음"; exit 1; }
for l in libgcc_s.so.1 libstdc++.so.6 libc.so.6 libQt5Core.so.5 libgtk-3.so.0 libasound.so.2; do
  [ -e "$STAGE/usr/lib/$l" ] || [ -e "$STAGE/lib/$l" ] || [ -e "$STAGE/usr/lib64/$l" ] || { echo "🚨 ABORT: 런타임 $l 없음"; exit 1; }; done
[ -d "$STAGE/lib/modules/$KERNEL_VERSION" ] || { echo "🚨 ABORT: 커널 모듈이 스테이지에 없음"; exit 1; }
# NEEDED 해석 (실행파일·so 전부, 누락 0). readelf가 비-ELF에 에러 → 파이프라인 격리(v33 교훈)
# x86 특수: 원본 rootfs(1.x deb 유입 모듈)에 **처음부터 dangling**인 참조 14종이 있었다(libcups·libcolord·libgif·libheif·libjxl·
# libproxy·libgvfscommon·libpulsecommon·liblzo2·libopenjp2·libspectre·libwebpdemux·libid3tag — 참조자 = gtk cups 프린트백엔드·
# imlib2 로더·gio 모듈·libpulse·cairo-script, 전부 로드 실패하는 죽은 모듈). 정책: **참조자가 아무도 NEEDED로 요구하지 않는
# leaf 모듈(usr/lib*·libexec·plugins)이면 삭제(반복)** → 이미지에 dangling 0. 실행파일(usr/bin·sbin)이 깨졌으면 ABORT.
lib_exists(){ [ -e "$STAGE/usr/lib/$1" ] || [ -e "$STAGE/lib/$1" ] || [ -e "$STAGE/lib64/$1" ] || [ -e "$STAGE/usr/lib64/$1" ] || compgen -G "$STAGE/usr/lib/*/$1" >/dev/null \
    || [ -n "$(find "$STAGE/usr/lib" "$STAGE/usr/lib64" "$STAGE/opt" -name "$1" -print -quit 2>/dev/null)" ]; }
NEEDED_MAP=$(mktemp); NEEDED_LIST=$(mktemp); PASS=0; PRUNED=0
while :; do
  PASS=$((PASS+1)); [ "$PASS" -le 8 ] || { echo "🚨 ABORT: dangling 정리 8회 초과(순환?)"; exit 1; }
  # 맵: "<NEEDED>\t<파일>" (xargs 배치가 1개면 readelf가 File: 헤더를 안 찍으므로 파일별 호출)
  { find "$STAGE/usr/bin" "$STAGE/usr/sbin" "$STAGE/usr/lib" "$STAGE/usr/lib64" "$STAGE/usr/libexec" "$STAGE/usr/plugins" "$STAGE/opt" -xdev -type f \( -name '*.so*' -o -perm /111 \) -print0 2>/dev/null \
    | xargs -0 -P 16 -n 1 sh -c 'readelf -d "$1" 2>/dev/null | grep -o "Shared library: \[[^]]*\]" | awk -v f="$1" '"'"'{gsub(/.*\[|\]/,""); print $0 "\t" f}'"'"'' _ | sed "s|\t$STAGE|\t|" > "$NEEDED_MAP"; } || true
  [ -s "$NEEDED_MAP" ] || { echo "🚨 ABORT: NEEDED 맵 비어있음(readelf 실패?)"; exit 1; }
  cut -f1 "$NEEDED_MAP" | sort -u > "$NEEDED_LIST"
  MISS=""; while read -r n; do lib_exists "$n" || MISS="$MISS $n"; done < "$NEEDED_LIST"
  [ -n "$MISS" ] || break
  DEL=""; BAD=""; DEFER=""
  for n in $MISS; do
    for who in $(awk -F'\t' -v n="$n" '$1==n{print $2}' "$NEEDED_MAP" | sort -u); do
      case "$who" in /usr/bin/*|/usr/sbin/*|/opt/*) BAD="$BAD $who(→$n)"; continue;; esac
      soname=$(readelf -d "$STAGE$who" 2>/dev/null | grep -o 'Library soname: \[[^]]*\]' | sed 's/.*\[\(.*\)\]/\1/' || true)   # SONAME 없는 모듈 → grep 비0 → set -e 침묵사 방지(v33 교훈)
      # 비-leaf(남이 NEEDED로 요구)는 이번 패스엔 보류 — 요구자가 dangling leaf라면 다음 패스에서 leaf가 된다(libpulse ← libpulse-simple 사례)
      if [ -n "$soname" ] && grep -qx "$soname" "$NEEDED_LIST"; then DEFER="$DEFER $who(→$n, $soname 요구자 있음)"; else DEL="$DEL $who"; fi
    done
  done
  [ -z "$BAD" ] || { echo "🚨 ABORT: NEEDED 누락 참조자가 실행파일:$BAD"; exit 1; }
  [ -n "$DEL" ] || { echo "🚨 ABORT: 진전 없음 — 비-leaf 참조자만 남음(살아있는 사용자가 있는 dangling 라이브러리):$DEFER"; exit 1; }
  echo "  [pass $PASS] dangling 모듈 삭제(누락:$MISS):"
  for f in $(echo "$DEL" | tr ' ' '\n' | sort -u); do echo "    - $f"; rm -f "$STAGE$f"; PRUNED=$((PRUNED+1)); done
  # 삭제된 실체를 가리키던 심볼릭링크 정리 — 반드시 **chroot 안에서**: x86 rootfs엔 `/usr/lib/libpciaccess.so.0 → /usr/lib64/…` 같은
  # *절대* 심볼릭링크가 있어 호스트에서 `-xtype l`을 돌리면 호스트 fs 기준으로 dangling 오판 → 멀쩡한 Xorg 의존성이 지워졌다(2026-08-28 실사고)
  chroot "$STAGE" /usr/bin/find /usr/lib /usr/lib64 /usr/libexec -xtype l -delete 2>/dev/null || true
done
echo "  NEEDED 고유 $(wc -l < "$NEEDED_LIST")개 전부 해석 (dangling 모듈 ${PRUNED}개 제거, ${PASS}회)"; rm -f "$NEEDED_MAP" "$NEEDED_LIST"
# 핵심 바이너리는 chroot ldd로 실해석까지 (NEEDED 파일 존재 ≠ 로더가 찾는다)
for b in usr/bin/plank usr/bin/marux-quicksettings usr/libexec/bamf/bamfdaemon usr/bin/openbox usr/bin/idesk usr/bin/feh usr/bin/picom usr/bin/ibus-daemon usr/lib/ibus/ibus-engine-hangul usr/bin/Xorg usr/bin/qterminal usr/bin/pcmanfm-qt usr/bin/featherpad opt/firefox/firefox usr/bin/amixer usr/bin/dbus-daemon; do
  [ -e "$STAGE/$b" ] || { echo "🚨 ABORT: 핵심 바이너리 $b 없음"; exit 1; }
  nf=$(chroot "$STAGE" /usr/bin/ldd "/$b" 2>&1 | grep -c 'not found' || true)
  [ "$nf" = 0 ] || { echo "🚨 ABORT: $b ldd not found ×$nf"; chroot "$STAGE" /usr/bin/ldd "/$b" | grep 'not found'; exit 1; }
done
echo "  ✓ 핵심 바이너리 16종 chroot ldd 전부 해석"
grep -rlE '(^Exec=.*python|^#!.*python|/usr/bin/python)' "$STAGE/etc/X11/xinit/xinitrc" "$STAGE/etc/rc.d/init.d" "$STAGE/usr/share/applications" "$STAGE/root/.config/plank" 2>/dev/null && { echo "🚨 ABORT: python 실행 참조가 부팅/데스크톱 경로에 있음"; exit 1; }
for f in usr/share/licenses/MaruxOS/LICENSE usr/share/licenses/UNLICENSE.txt usr/share/licenses/GPL-2.0.txt usr/share/licenses/LGPL-3.0.txt usr/share/licenses/MPL-2.0.txt usr/share/fonts/truetype/nanum/OFL.txt usr/share/licenses/pkg/openbox-3.6.1/COPYING; do
  [ -s "$STAGE/$f" ] || { echo "🚨 ABORT: $f 없음"; exit 1; }; done
echo "  ✓ 슬림 게이트 (NEEDED 전부 해석 · python 참조 0 · 라이선스 $(ls "$LD/pkg" | wc -l) pkg)"

echo "  [7e] 기동 게이트 — 슬림 사본에서 네이티브 chroot 실행 $(date +%H:%M)"
mount --bind "$STAGE" "$STAGE"     # 게이트는 QTGATE_ROOT가 마운트포인트여야 함(이미지 사본 보호 규칙)
set +e; QTGATE_ROOT="$STAGE" bash "$GATE_X86"; GRC=$?; set -e
for m in tmp/.X11-unix dev/pts dev sys proc; do mountpoint -q "$STAGE/$m" 2>/dev/null && { umount "$STAGE/$m" 2>/dev/null || umount -l "$STAGE/$m"; } || true; done   # busy → lazy (1차 실행 때 dev busy 경고)
umount "$STAGE"
for m in dev/pts dev sys proc; do mountpoint -q "$STAGE/$m" 2>/dev/null && { echo "🚨 ABORT: $STAGE/$m 이 아직 마운트됨 — squashfs에 호스트 fs가 실린다"; exit 1; }; done
[ "$GRC" = 0 ] || { echo "🚨 ABORT: 슬림 사본 기동 게이트 실패 (strip/제거가 무언가를 깼다)"; exit 1; }
rm -rf "$STAGE/tmp/"* "$STAGE/run/"* "$STAGE/root/.config/glib-2.0/settings/keyfile" 2>/dev/null || true
echo "  최종 스테이지: $(du -sh "$STAGE" | cut -f1)"

# ============================================================================
# [8] squashfs / [9] ISO / [POST]
# ============================================================================
echo "[8] Building squashfs (from stage)..."
rm -f "$ISO_DIR/live/filesystem.squashfs"
mksquashfs "$STAGE" "$ISO_DIR/live/filesystem.squashfs" -comp xz -b 1M -Xdict-size 1M -e boot -noappend
echo "[9] Building ISO..."
mkdir -p "$OUTPUT_DIR"
xorriso -as mkisofs -iso-level 3 -full-iso9660-filenames -volid "MARUXOS" \
    -eltorito-boot boot/grub/bios.img -no-emul-boot -boot-load-size 4 -boot-info-table --grub2-boot-info \
    --grub2-mbr /usr/lib/grub/i386-pc/boot_hybrid.img -eltorito-catalog boot/grub/boot.cat --protective-msdos-label \
    -output "$OUTPUT_DIR/$ISO_FILENAME" "$ISO_DIR" 2>/dev/null || grub-mkrescue -o "$OUTPUT_DIR/$ISO_FILENAME" "$ISO_DIR"

echo "[POST] checksums + 릴리즈 사본"
sha256sum "$OUTPUT_DIR/$ISO_FILENAME" > "$OUTPUT_DIR/$ISO_FILENAME.sha256"
sha512sum "$OUTPUT_DIR/$ISO_FILENAME" > "$OUTPUT_DIR/$ISO_FILENAME.sha512"
cp -f "$OUTPUT_DIR/$ISO_FILENAME" "$OUTPUT_DIR/MaruxOS-${DISTRO_VERSION}-x86_64.iso"
(cd "$OUTPUT_DIR" && sha256sum "MaruxOS-${DISTRO_VERSION}-x86_64.iso" > "MaruxOS-${DISTRO_VERSION}-x86_64.iso.sha256")
echo "=========================================="
echo "✓ Build complete: $ISO_FILENAME  ($(ls -lh "$OUTPUT_DIR/$ISO_FILENAME" | awk '{print $5}'))"
cat "$OUTPUT_DIR/$ISO_FILENAME.sha256"
echo "  Kernel: $KERNEL_VERSION / modules $SYNCED_MODULES / stage $(du -sh "$STAGE" | cut -f1)"
echo "  릴리즈 사본: $OUTPUT_DIR/MaruxOS-${DISTRO_VERSION}-x86_64.iso"
echo "  QEMU: qemu-system-x86_64 -m 4G -enable-kvm -device intel-hda -device hda-duplex -cdrom $OUTPUT_DIR/$ISO_FILENAME"
echo "=========================================="
