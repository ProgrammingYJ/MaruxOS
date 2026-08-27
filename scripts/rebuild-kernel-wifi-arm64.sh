#!/bin/bash
# =============================================================================
# MaruxOS 2.0.0 ARM64 — 배치 W 스텝1: WiFi 커널 재빌드 (2026-08-14)
# -----------------------------------------------------------------------------
# 목적: Pi 4B 내장 WiFi (BCM43455, SDIO) 활성화. no-modules 원칙 유지.
#   ① CFG80211/MAC80211/RFKILL/BRCMFMAC =m → =y (builtin 강제)
#   ② 펌웨어 5종을 커널에 임베드 (CONFIG_EXTRA_FIRMWARE) — builtin 드라이버는
#      rootfs 마운트 전에 request_firmware 하므로 rootfs 배치만으론 타이밍 실패.
#      임베드가 no-modules 정합 해법 (Image ~650KB 증가).
#      - brcm/brcmfmac43455-sdio.bin (메인 펌웨어)
#      - brcm/brcmfmac43455-sdio.raspberrypi,4-model-b.txt (Pi4B NVRAM — 보드전용명 우선 요청됨)
#      - brcm/brcmfmac43455-sdio.clm_blob (규제 CLM)
#      - regulatory.db + regulatory.db.p7s (cfg80211 regdb — REQUIRE_SIGNED_REGDB=y라 서명 포함)
#   ③ 소스 (2026-08-14 HTTP 200 실측 — raw bytes 원칙):
#      - bin/clm: linux-firmware **cypress/cyfmac43455-*** (brcm/*.bin은 cgit서 404 — 업스트림 개편,
#        brcm/엔 NVRAM txt만 남음. 드라이버 요청명 brcm/brcmfmac43455-sdio.*로 리네임 저장)
#      - NVRAM: linux-firmware brcm/brcmfmac43455-sdio.raspberrypi,4-model-b.txt
#      - regulatory.db(+p7s): **wireless-regdb 레포**(정본 업스트림 — linux-firmware cgit plain엔 미노출)
#   ④ 게이트: 매직바이트/크기/SHA256 박제 + .config 실효값 + Image 임베드 실측.
# 실행: WSL host (cross), wsl -u root bash <이 파일> — 안전패턴 #8.
# =============================================================================
set -uo pipefail
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
BUILD_TARGET="arm64"
B=/home/administrator/MaruxOS-arm64
K=$B/kernel/linux-6.18.26
FWDIR=$B/firmware/wifi
LFS=$B/rootfs-clfs-arm64
LOG=$B/wifi-kernel-rebuild.log
MARKER=$B/.wifi-kernel-COMPLETE

# ---------- CLAUDE.md ARM64 의무 게이트 ----------
[[ "$K" == *"MaruxOS-arm64"* ]] || { echo "🚨 ABORT: 커널 경로가 ARM64 트리 아님: $K"; exit 1; }
[[ "$K" == *"/MaruxOS/build"* ]] && { echo "🚨 ABORT: x86_64 디렉토리"; exit 1; }
aarch64-linux-gnu-gcc -dumpmachine | grep -q aarch64 || { echo "🚨 ABORT: CC가 ARM64 cross 아님"; exit 1; }
[[ "$ARCH" == "arm64" ]] || { echo "🚨 ABORT: ARCH != arm64"; exit 1; }
[ -f "$K/Makefile" ] || { echo "🚨 ABORT: 커널 트리 없음"; exit 1; }
[ -f "$K/.config" ] || { echo "🚨 ABORT: .config 없음"; exit 1; }
grep -q '6.18.26-maruxos' "$K/include/config/kernel.release" || { echo "🚨 ABORT: kernel.release ≠ 6.18.26-maruxos"; exit 1; }
rm -f "$MARKER"

# ---------- [1] 펌웨어 다운로드 (실측 200 확인된 URL 5종) ----------
echo "[1] 펌웨어 다운로드 → $FWDIR" | tee "$LOG"
mkdir -p "$FWDIR/brcm"
LFW="https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain"
RDB_REPO="https://git.kernel.org/pub/scm/linux/kernel/git/sforshee/wireless-regdb.git/plain"

fetch_fw() {  # $1=URL, $2=저장 경로
  local url="$1" dest="$2"
  wget -q -O "$dest" "$url" || { echo "  ✗ wget 실패: $url"; return 1; }
  echo "  ✓ $(basename "$dest") ($(stat -c %s "$dest") B)"
}

fetch_fw "$LFW/cypress/cyfmac43455-sdio.bin"                         "$FWDIR/brcm/brcmfmac43455-sdio.bin"                       || exit 1
fetch_fw "$LFW/brcm/brcmfmac43455-sdio.raspberrypi,4-model-b.txt"    "$FWDIR/brcm/brcmfmac43455-sdio.raspberrypi,4-model-b.txt" || exit 1
fetch_fw "$LFW/cypress/cyfmac43455-sdio.clm_blob"                    "$FWDIR/brcm/brcmfmac43455-sdio.clm_blob"                  || exit 1
fetch_fw "$RDB_REPO/regulatory.db"                                   "$FWDIR/regulatory.db"                                     || exit 1
fetch_fw "$RDB_REPO/regulatory.db.p7s"                               "$FWDIR/regulatory.db.p7s"                                 || exit 1

# ---------- [2] 펌웨어 게이트 (매직/크기) + SHA256 박제 ----------
echo "[2] 펌웨어 게이트" | tee -a "$LOG"
BIN=$FWDIR/brcm/brcmfmac43455-sdio.bin
NVR="$FWDIR/brcm/brcmfmac43455-sdio.raspberrypi,4-model-b.txt"
CLM=$FWDIR/brcm/brcmfmac43455-sdio.clm_blob
RDB=$FWDIR/regulatory.db
P7S=$FWDIR/regulatory.db.p7s
[ "$(stat -c %s "$BIN")" -gt 400000 ] || { echo "🚨 ABORT: bin 크기 이상 ($(stat -c %s "$BIN") B)"; exit 1; }
grep -q "boardflags" "$NVR" || { echo "🚨 ABORT: NVRAM에 boardflags 없음 (심링크 텍스트?)"; exit 1; }
# clm_blob 실물 매직 = "BLOB" (4B, 오프셋0) — "CLM DATA"는 AI 기억 환각이었음(2026-08-14 od 실측 정정)
[ "$(head -c 4 "$CLM")" = "BLOB" ] || { echo "🚨 ABORT: clm_blob 매직(BLOB) 아님"; exit 1; }
grep -q "CLM" "$CLM" || { echo "🚨 ABORT: clm_blob에 CLM 마커 없음"; exit 1; }
[ "$(head -c 4 "$RDB")" = "RGDB" ] || { echo "🚨 ABORT: regulatory.db 매직(RGDB) 아님"; exit 1; }
[ "$(stat -c %s "$P7S")" -gt 300 ] || { echo "🚨 ABORT: p7s 크기 이상"; exit 1; }
( cd "$FWDIR" && sha256sum brcm/* regulatory.db regulatory.db.p7s | tee SHA256-MANIFEST ) | tee -a "$LOG"

# rootfs에도 배치 (userspace 재프로브/도구용 — 임베드가 1차, 이건 보강)
mkdir -p "$LFS/lib/firmware/brcm"
cp -f "$BIN" "$NVR" "$CLM" "$LFS/lib/firmware/brcm/"
cp -f "$NVR" "$LFS/lib/firmware/brcm/brcmfmac43455-sdio.txt"   # 제네릭명 폴백
cp -f "$RDB" "$P7S" "$LFS/lib/firmware/"
echo "  ✓ rootfs /lib/firmware 배치" | tee -a "$LOG"

# ---------- [2.5] brcmfmac FWSUP 비활성 패치 (host 4-way 강제) ----------
# v21 실기기 실측: 펌웨어 supplicant(sup_wpa)가 4-way를 떠맡지만 완주하지 못해
#   - wpa offload 신뢰 시 : port-authorized 무응답 → CONN_FAILED (함정 #30)
#   - wpa offload 차단 시 : 펌웨어가 PSK 없이 인증 → AP가 reason23으로 DEAUTH
# 어느 쪽이든 EAPOL이 host로 올라오지 않음. FWSUP 감지를 제거해 드라이버가
# 항상 host supplicant 모드로 동작하게 만든다(EAPOL → wpa_supplicant 정상 경로).
FEATC="$K/drivers/net/wireless/broadcom/brcm80211/brcmfmac/feature.c"
[ -f "$FEATC" ] || { echo "🚨 ABORT: feature.c 없음"; exit 1; }
if ! grep -q "MaruxOS: FWSUP" "$FEATC"; then
  grep -q 'BRCMF_FEAT_FWSUP, "sup_wpa"' "$FEATC" || { echo "🚨 ABORT: FWSUP 감지 라인 없음(커널 버전 변경?)"; exit 1; }
  sed -i 's|brcmf_feat_iovar_int_get(ifp, BRCMF_FEAT_FWSUP, "sup_wpa");|/* MaruxOS: FWSUP 비활성 — host 4-way 강제 (펌웨어 supplicant 미완주) */|' "$FEATC"
  echo "  ✓ FWSUP 패치 적용"
else
  echo "  ✓ FWSUP 패치 기적용"
fi
grep -q "MaruxOS: FWSUP" "$FEATC" || { echo "🚨 ABORT: FWSUP 패치 실패"; exit 1; }

# ---------- [3] .config 무선 스택 =y + 펌웨어 임베드 ----------
echo "[3] .config 강제" | tee -a "$LOG"
cd "$K"
# RESET_GPIO: 6.18 pwrseq_simple은 reset 컨트롤러 프레임워크 우선(devm_reset_control_get_optional)
# — DT reset-gpios를 reset 컨트롤러로 브리지하는 드라이버가 =m이면 "reset control not ready"로
# wifi-pwrseq 영구 deferred → mmc1(WiFi SDIO 호스트) 미기동 → wlan0 부재 (v18 실기기 실측)
scripts/config -e CFG80211 -e MAC80211 -e RFKILL \
  -e WLAN_VENDOR_BROADCOM -e BRCMFMAC -e BRCMFMAC_SDIO -e BRCMUTIL \
  -e RESET_GPIO \
  --set-str EXTRA_FIRMWARE "brcm/brcmfmac43455-sdio.bin brcm/brcmfmac43455-sdio.raspberrypi,4-model-b.txt brcm/brcmfmac43455-sdio.clm_blob regulatory.db regulatory.db.p7s" \
  --set-str EXTRA_FIRMWARE_DIR "$FWDIR"
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- olddefconfig >>"$LOG" 2>&1 || { echo "🚨 ABORT: olddefconfig 실패"; exit 1; }

# 게이트: 실효값 (olddefconfig가 의존성으로 되돌렸을 가능성 검증)
for opt in CONFIG_CFG80211=y CONFIG_MAC80211=y CONFIG_RFKILL=y CONFIG_BRCMFMAC=y CONFIG_BRCMFMAC_SDIO=y CONFIG_BRCMUTIL=y CONFIG_WLAN_VENDOR_BROADCOM=y CONFIG_RESET_GPIO=y; do
  grep -q "^$opt$" .config || { echo "🚨 ABORT: $opt 미달성 → $(grep "^${opt%%=*}[= ]" .config || echo 부재)"; exit 1; }
done
grep -q '^CONFIG_EXTRA_FIRMWARE=".*43455.*"' .config || { echo "🚨 ABORT: EXTRA_FIRMWARE 미설정"; exit 1; }
grep -q '^CONFIG_MMC_SDHCI_IPROC=y' .config || { echo "🚨 ABORT: SDIO 버스(MMC_SDHCI_IPROC) 소실"; exit 1; }
echo "  ✓ 무선 7종 =y + EXTRA_FIRMWARE 확인" | tee -a "$LOG"

# ---------- [4] 빌드 ----------
echo "[4] make -j32 Image dtbs (증분)" | tee -a "$LOG"
make -j32 ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- Image dtbs >>"$LOG" 2>&1 || { echo "🚨 ABORT: 커널 빌드 실패 — tail $LOG"; tail -30 "$LOG"; exit 1; }

# ---------- [5] 산출물 게이트 ----------
echo "[5] 산출물 게이트" | tee -a "$LOG"
IMG=$K/arch/arm64/boot/Image
DTB=$K/arch/arm64/boot/dts/broadcom/bcm2711-rpi-4-b.dtb
[ -f "$IMG" ] || { echo "🚨 ABORT: Image 없음"; exit 1; }
[ -f "$DTB" ] || { echo "🚨 ABORT: dtb 없음"; exit 1; }
grep -q '6.18.26-maruxos' "$K/include/config/kernel.release" || { echo "🚨 ABORT: kernel.release 변조"; exit 1; }
# 임베드 실측: Image 안에 펌웨어 파일명 문자열 존재해야 함 (builtin fw 테이블)
grep -ac "brcmfmac43455-sdio" "$IMG" >/dev/null || { echo "🚨 ABORT: Image에 43455 임베드 흔적 없음"; exit 1; }
grep -ac "regulatory.db" "$IMG" >/dev/null || { echo "🚨 ABORT: Image에 regulatory.db 임베드 흔적 없음"; exit 1; }
NEWSZ=$(stat -c %s "$IMG")
NEWSHA=$(sha256sum "$IMG" | awk '{print $1}')
echo "===== WiFi 커널 재빌드 완료 =====" | tee -a "$LOG"
echo "  Image: $NEWSZ B (구 51,149,312 — 임베드로 증가 정상)" | tee -a "$LOG"
echo "  SHA256: $NEWSHA" | tee -a "$LOG"
echo "  kernel.release: $(cat "$K/include/config/kernel.release")" | tee -a "$LOG"
date > "$MARKER"
echo "WIFI_KERNEL_OK"
