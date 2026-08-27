#!/bin/bash
# =============================================================================
# MaruxOS 2.0.0 ARM64 — 배치 B-1 한글 config: NanumGothic 폰트 + ibus 활성 검증
# -----------------------------------------------------------------------------
# install-hangul-arm64-v2.sh(ibus/ibus-hangul 빌드) 성공 후 실행.
#  ① NanumGothic TTF 설치 (18x18ko 비트맵 → 예쁜 한글 벡터폰트) + fc-cache
#  ② ibus 바이너리 존재 검증 (ibus-x11 XIM, ibus-engine-hangul)
#  ③ xinitrc ibus 블록은 config-v2가 이미 배포(guard) — 여기선 pkill로 개선 + hangul 활성 확인
# 순수 파일 + chroot fc-cache. root 실행. (실기기서 한영토글키 테스트 후 hotkey 미세조정)
# =============================================================================
set -uo pipefail
B=/home/administrator/MaruxOS-arm64
LFS=$B/rootfs-clfs-arm64
S=$LFS/sources
[[ "$LFS" == *"MaruxOS-arm64"* ]] || { echo "🚨 ABORT: $LFS"; exit 1; }

# ---------- 1. NanumGothic TTF ----------
echo "[1] NanumGothic 폰트"
mkdir -p "$LFS/usr/share/fonts/nanum"
fetch_font(){ # $1=파일 $2..=url
  local out="$S/$1"; shift
  [ -s "$out" ] && return 0
  for u in "$@"; do timeout 90 wget -q -O "$out" "$u" && [ -s "$out" ] && return 0; rm -f "$out"; done
  return 1
}
for f in Regular Bold ExtraBold; do
  if fetch_font "NanumGothic-$f.ttf" \
       "https://github.com/google/fonts/raw/main/ofl/nanumgothic/NanumGothic-$f.ttf" \
       "https://raw.githubusercontent.com/google/fonts/main/ofl/nanumgothic/NanumGothic-$f.ttf"; then
    cp -f "$S/NanumGothic-$f.ttf" "$LFS/usr/share/fonts/nanum/"
    echo "  ✓ NanumGothic-$f.ttf"
  else echo "  ⚠️ NanumGothic-$f fetch 실패"; fi
done
NCOUNT=$(ls "$LFS/usr/share/fonts/nanum/"*.ttf 2>/dev/null | wc -l)
echo "  NanumGothic $NCOUNT개 설치"

# ---------- 2. ibus 바이너리 검증 ----------
echo "[2] ibus/hangul 바이너리 검증"
ALLOK=1
for f in usr/bin/ibus usr/bin/ibus-daemon usr/libexec/ibus-x11 \
         usr/libexec/ibus-engine-hangul usr/lib/libibus-1.0.so \
         usr/share/ibus/component/hangul.xml; do
  if [ -e "$LFS/$f" ]; then echo "  ✅ $f"; else echo "  ❌ $f"; ALLOK=0; fi
done
[ "$ALLOK" = 1 ] && echo "  → ibus XIM 한글 스택 완비" || echo "  ⚠️ 일부 누락 (빌드 확인 필요)"

# ---------- 3. fc-cache (chroot, NanumGothic 등록) ----------
echo "[3] fc-cache (chroot)"
mountpoint -q /proc/sys/fs/binfmt_misc || mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc
[ -e /proc/sys/fs/binfmt_misc/qemu-aarch64 ] || echo ':qemu-aarch64:M::\x7f\x45\x4c\x46\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-aarch64-static:F' > /proc/sys/fs/binfmt_misc/register
[ -e "$LFS/usr/bin/qemu-aarch64-static" ] || cp /usr/bin/qemu-aarch64-static "$LFS/usr/bin/"
for fs in dev proc sys; do mkdir -p "$LFS/$fs"; mountpoint -q "$LFS/$fs" || case $fs in dev) mount --bind /dev "$LFS/dev";; proc) mount -t proc proc "$LFS/proc";; sys) mount -t sysfs sysfs "$LFS/sys";; esac; done
chroot "$LFS" /bin/bash -c 'fc-cache -f >/dev/null 2>&1; echo "  NanumGothic fc-match: $(fc-match NanumGothic 2>/dev/null)"'

echo "===== 한글 config 완료 ====="
echo "  다음: v9 이미지 빌드 → 플래시 → xterm에서 한영토글(Shift+Space) 후 한글 타이핑 테스트"
