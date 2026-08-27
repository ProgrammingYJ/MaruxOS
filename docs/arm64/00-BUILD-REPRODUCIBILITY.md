# MaruxOS aarch64 rootfs — 스테이지별 완전 재현 가이드 (from-scratch)

> **목적**: MaruxOS 2.0.0 "Cooked"의 aarch64(Raspberry Pi 4B / BCM2711) rootfs를 CLFS from-scratch로 재현하는 정본 절차서.
> **주 소스**: [`ARM64-Update-Log.md`](../../ARM64-Update-Log.md) (전체). 보조: [`Kernel-Update-Log.md`](../../Kernel-Update-Log.md), [`CLAUDE.md`](../../CLAUDE.md), [`config-arm64/`](../../config-arm64/), [`config/lfs-versions.conf`](../../config/lfs-versions.conf).
> **작성일**: 2026-07-05. **재현 대상 빌드**: 2026-06-19 트랙 진입 → 2026-06-23 rootfs 완성 → 2026-07-02 부팅 디버깅.

---

## 0. 이 문서의 출처 표기 규약 (엄수 — 환각 금지)

이 프로젝트는 hallucination을 극도로 배격한다(1.x의 "6.12 광고 → 6.7.4 실체" 5개월 환각 전과). 따라서 이 가이드의 모든 항목에 출처를 명시한다:

| 표기 | 의미 |
|------|------|
| **[원문]** | `ARM64-Update-Log.md` 등 소스 파일에 **verbatim으로 기록된** 명령/값/결과. 그대로 신뢰 가능. |
| **(재구성)** | 로그가 *의도·델타는 기록했으나 정확한 명령줄은 남기지 않은* 단계. 표준 LFS 12.x 절차 + 로그가 명시한 델타로 **재구성한 것**. 로그 자체의 verbatim이 아님 — 실제 재현 시 LFS 12.0/12.1 책과 대조할 것. |
| **미기록** | 소스 파일에 명령/값이 **남아 있지 않은** 항목. 지어내지 않는다. |

**SHA256·크기·경로·버전 등 정확한 값은 원문 그대로(verbatim) 인용했다.** 재구성 명령을 실측 명령으로 오인하지 말 것.

> ## ✅ RESOLVED (2026-07-23): 실기기 부팅은 오래전에 해결됐고, 그 뒤로 그래픽 데스크톱 + 한글 입력까지 완성됐다.
>
> **이 문서는 2026-07-05 스냅샷("부팅 미해결")으로 작성됐으나, 실물 Pi 4B 부팅은 2026-07-08에 이미 해결됐다.** 아래 본문의 "미해결" 서술(특히 §11)은 **역사적 디버깅 기록으로 보존**하되, 실제 결말은 다음과 같다:
> - **2026-07-08 — 무인 클린부팅 → `marux login:`(Stage 4 완료) + root 쉘 self-hosting 증명**(실물 Pi에서 gcc 13.2.0가 C 컴파일+실행). **부팅은 애초에 실패한 적이 없었다** — 관측 불능이었을 뿐.
> - **2026-07-08 — HDMI 콘솔** 부활(커널 VC4/V3D `=y` builtin, Stage 5a).
> - **2026-07-17/18 — 실물 HDMI에 그래픽 데스크톱 렌더링**(openbox+tint2+xterm, v7) → **마우스/키보드 입력(libinput) + 한글 표시**(v7.1, `18x18ko` 비트맵 폰트).
> - **2026-07-20 — 데스크톱 x86 패리티**(feh 배경·mc·바탕화면 아이콘·우클릭 풀메뉴·Win 키바인드, v8).
> - **2026-07-23 — 🎉 한글 입력 실기기 성공**(ibus-hangul XIM, `Shift+Space` → `gksrmf`→`한글`) — v10(out-of-box 한글).
> - **2026-07-25~29 — v11~v16 데스크톱 완성**: GTK3 + Firefox ESR 한국어 + gtk3 한글 입력(v11) → **유선 네트워크 out-of-box + 실기기 웹서핑**(v12) → HW커서·HDMI 1080p60(v13) → **Plank dock 소스빌드(자체 valac 부트스트랩) + GSettings keyfile 정공픽스**(v14, 실기기 검증) → picom + Marux 유리 테마(v15) → 라이브픽스 4종 박제(v16). 최신 이미지 = **v16**(SHA `57daa20a…`, 2026-07-29). 이력 표 = §10.5.
>
> **§11의 두 가설은 둘 다 틀렸다(반증됨)**: (A) FAT 구조 ❌ / (B) 50MB 커널 ❌ — 펌웨어는 우리 커널을 정상적으로 로드해 핸드오프했다(4-CPU SMP·PCIe·USB·eth0·ext4 마운트·`/sbin/init` 실행 전부 확인). **실제 원인**: ① **죽어가던 시리얼 어댑터**(관측 불능 → 새 FT232RL + **흰↔초 배선 스왑** + `enable_uart=1`) ② cmdline **`console=ttyS0,115200`를 맨 뒤로** 배치(= `/dev/console`=시리얼, 유저스페이스는 안 보이는 tty1 더미로 새고 있었음) ③ 경미한 **rootfs 설정 버그**(`/bin/udevadm` 심링크 누락, fstab `/dev/shm`+cgroup 누락, S70console setfont, S10sysklogd)로 rc마다 "Press Enter" 정지. **"짧은 2번 LED"는 부팅 실패가 아니었다.** HDMI 블랙아웃은 단지 디스플레이 드라이버 부재 → VC4/V3D `=y`(+config.txt `max_framebuffers=2`, mainline dtb라 dtoverlay 불요)로 해결.
>
> ---
> **(아래는 2026-07-05 당시 원문 — 역사 보존)**
> ⚠️ **중대 상태 고지 (2026-07-05 기준)**: 아래 절차로 **완전한 aarch64 rootfs 및 부팅 이미지까지는 완성됐으나**, 실기기 Pi 4B **부팅은 아직 성립하지 않았다** (초록 LED 짧은 깜빡 2번 = 펌웨어가 우리 부트 파티션을 못 읽음). rootfs·이미지 조립은 검증됨, 실기 부팅은 **미해결**. §9 참조.

---

## 1. 트랙 메타 / 빌드 호스트 실측 (재현 전제) — [원문]

| 항목 | 값 |
|------|-----|
| 트랙 시작 | 2026-06-19 |
| 브랜치 | `2.0.0-cooked-arm64` (parent: `2.0.0-cooked-kernel`) |
| 빌드 호스트 | x86_64 WSL2 (Ubuntu 24.04) on Windows 11 Pro |
| 타겟 | Raspberry Pi 4B 8GB (aarch64, BCM2711) |
| 유저 / HOME | `administrator` / `/home/administrator` |
| HOME 파일시스템 | **ext4** (`/dev/sdc`, drvfs/NTFS 아님) — 커널 빌드 안전 (xt_TCPMSS 대소문자 트랩 회피) |
| CPU | **32 스레드** |
| 호스트 RAM | 15.2 GB (WSL 기본캡 7.3 GB) |
| 빈 디스크 | 876 GB |
| 빌드 루트 (WSL native) | `/home/$USER/MaruxOS-arm64/` ⭐ x86_64 `/home/$USER/MaruxOS/build/`와 **완전 분리** |
| rootfs 전략 | **CLFS from scratch** (배포판 바이너리 0개, 발판 컴파일러만 distro 제공) |
| 툴체인 베이스라인 | **gcc 13.2.0 / binutils 2.41 / glibc 2.38** (LFS 12.0-era — CLAUDE.md의 "12.1 기반" 라벨과 실체 차이는 함정 #3 참조) |

**빌드 방식 확정** [원문]: host cross-gcc(Ubuntu 13.3.0) → temp tools 크로스컴파일 → `qemu-aarch64-static` binfmt로 aarch64 chroot 진입 → **최종 유저랜드 전부 chroot 안에서 소스 빌드(에뮬 네이티브)**. "LFS가 호스트 gcc를 발판으로 쓰는 것과 정확히 동일 패턴."

**WSL 메모리 튜닝** [원문] — `C:\Users\Administrator\.wslconfig`:

```ini
[wsl2]
memory=11GB
swap=16GB
processors=32
```

적용: heavy 빌드 착수 **전** `wsl --shutdown` **1회만**. (이후 shutdown 금지 — 함정 #2/#5: binfmt 등록이 런타임 상태라 shutdown 시 소실.) 적용 후 실측: Mem available 9.8Gi / Swap 16Gi.

---

## 2. Stage 0 — 호스트 준비 (cross-toolchain + qemu + 빌드 디렉토리)

### 2.1 cross-toolchain / qemu / 커널 빌드 deps 설치 — [원문]

WSL 안에서 root로 실행(사용자 sudo 비번 불필요 확인됨):

```bash
# 1. cross-toolchain + 헬퍼 패키지 설치
sudo apt update
sudo apt install -y \
    gcc-aarch64-linux-gnu \
    g++-aarch64-linux-gnu \
    binutils-aarch64-linux-gnu \
    qemu-user-static \
    qemu-system-arm \
    libc6-arm64-cross \
    libc6-dev-arm64-cross
```

**실제 설치 로그 기록** [원문] (EXIT 0):
- `gcc-aarch64-linux-gnu` / `g++-aarch64-linux-gnu` / `binutils-aarch64-linux-gnu` = **Ubuntu 13.3.0 cross**
- `libc6-dev-arm64-cross`
- `qemu-user-static`(→ `qemu-aarch64-static`), `qemu-system-arm`(→ `qemu-system-aarch64` **8.2.2**)
- 추가 커널 빌드 deps: `bc bison flex libssl-dev libncurses-dev make cpio kmod xz-utils file`

> **호스트 LFS deps 누락분** [원문] (Ch5 착수 시 `makeinfo: not found`로 적발되어 뒤늦게 설치): **`texinfo` `gawk` `m4` `patch` `gettext`**. LFS 호스트 필수 패키지 — Stage 0에서 함께 설치하는 것이 옳다(원본 빌드에선 Stage 0에 누락되어 Ch5.1에서 보강).

### 2.2 빌드 디렉토리 생성 — [원문]

```bash
# 빌드 루트 + 6개 하위 디렉토리
mkdir -p /home/$USER/MaruxOS-arm64/{toolchain,kernel,firmware,rootfs-clfs-arm64,iso-build,output}
ls -la /home/$USER/MaruxOS-arm64/

# 본 경로가 ext4인지 확인 (NTFS drvfs면 abort — case-insensitive 트랩)
df -T /home/$USER/MaruxOS-arm64/ | grep -E "ext4|btrfs"
```

### 2.3 Stage 0 검증 게이트 (전부 통과) — [원문]

```bash
aarch64-linux-gnu-gcc --version
aarch64-linux-gnu-gcc -dumpmachine    # 기대: aarch64-linux-gnu
```

| 게이트 | 결과 |
|--------|------|
| `aarch64-linux-gnu-gcc -dumpmachine` | `aarch64-linux-gnu` ✓ |
| cross-gcc 버전 | Ubuntu 13.3.0 ✓ |
| `qemu-aarch64-static` | `/usr/bin/qemu-aarch64-static` ✓ |
| `qemu-system-aarch64` | `/usr/bin/qemu-system-aarch64` (8.2.2) ✓ |
| binfmt aarch64 등록 | **미등록** → Ch7 chroot 전 `update-binfmts`/수동 등록 필요 (함정 #2) |
| 빌드 디렉토리 6개 | `administrator` 소유 ✓ |
| fs 타입 | `ext4` (`/dev/sdc`) ✓ |

### 2.4 빌드 스크립트 의무 게이트 (모든 `build-*-arm64-*.sh` 헤더) — [원문]

```bash
BUILD_TARGET="arm64"
EXPECTED_BUILD_ROOT="/home/${SUDO_USER:-$USER}/MaruxOS-arm64"

# 게이트 1: 빌드 루트 분리 확인
[[ "$PWD" == "$EXPECTED_BUILD_ROOT"* ]] || { echo "🚨 ABORT: $PWD ≠ $EXPECTED_BUILD_ROOT"; exit 1; }
[[ "$PWD" == *"/MaruxOS/build"* ]] && { echo "🚨 ABORT: x86_64 디렉토리에서 ARM64 빌드"; exit 1; }

# 게이트 2: cross-toolchain ARM64 강제
${CC:-aarch64-linux-gnu-gcc} -dumpmachine | grep -q "aarch64" || { echo "🚨 ABORT: CC가 ARM64 cross 아님"; exit 1; }

# 게이트 3: 산출물명 arm64 강제
[[ "$OUTPUT_NAME" == *"arm64"* ]] || { echo "🚨 ABORT: OUTPUT_NAME에 arm64 누락"; exit 1; }

# 게이트 4: 커널 ARCH 강제
[[ "$ARCH" == "arm64" ]] || { echo "🚨 ABORT: ARCH != arm64"; exit 1; }
```

---

## 3. Stage 1 — 커널 (Linux 6.18.26 mainline, kernel8.img)

> 이 커널은 **Ubuntu cross-gcc(13.3.0)로 빌드**된다 (rootfs 툴체인과 별개). rootfs는 §5부터 host x86_64 gcc로 aarch64 크로스 툴체인을 from source 빌드한다. 즉 커널과 rootfs 툴체인은 서로 다른 컴파일러 경로.

### 3.1 소스 다운로드 + SHA256 게이트 — [원문]

canonical 메타 ([`config/lfs-versions.conf`](../../config/lfs-versions.conf)):
- `KERNEL_VERSION="6.18.26"`
- `KERNEL_SHA256="53772f5d3776e043767c8d81a32240d1f3eb64e822a5d7a510b55ca40707b0ec"`
- `KERNEL_URL="https://cdn.kernel.org/pub/linux/kernel"`

다운로드 대상: `linux-6.18.26.tar.xz` ← `cdn.kernel.org/pub/linux/kernel/v6.x/` → `MaruxOS-arm64/kernel/`

**SHA256 게이트 결과** [원문]:
- 크기: `154,432,584 B`
- `sha256sum` = `53772f5d3776e043767c8d81a32240d1f3eb64e822a5d7a510b55ca40707b0ec` == canonical → **완전 일치 PASS**
- 의미: 6.18.26이 실재 kernel.org 릴리즈임을 확인 + x86_64 canonical SHA 독립 검증. (1.x 6.7.4 환각과 정반대 결과.)

> 다운로드/해제 명령 자체는 **미기록**. (재구성) 예: `wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.18.26.tar.xz`; `sha256sum linux-6.18.26.tar.xz` (게이트); `tar -xf linux-6.18.26.tar.xz` — **반드시 WSL native ext4에서 해제**(Windows 드라이브의 대소문자 무시로 `xt_TCPMSS.c` 트랩).

### 3.2 defconfig — 함정 #1: mainline에 `bcm2711_defconfig`는 없다 — [원문]

```bash
# ❌ 실패 (함정 #1)
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- bcm2711_defconfig
# → *** Can't find default configuration "arch/arm64/configs/bcm2711_defconfig"!

# ✅ 통합 arm64 defconfig 사용
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- defconfig
# → kernelrelease = 6.18.26 ✓
```

**원인**: `bcm2711_defconfig`(및 `bcmrpi3_defconfig` 등)는 **raspberrypi/linux 다운스트림 포크** 전용. mainline `arch/arm64/configs/`에는 `defconfig`, `hardening.config`, `virt.config` **셋뿐**. mainline은 통합 `defconfig` 하나로 Pi4 포함 전 arm64 SoC 커버(`CONFIG_ARCH_BCM2835=y`가 BCM2835~2711 패밀리 전체 포함), Pi4 지원은 `arch/arm64/boot/dts/broadcom/bcm2711-rpi-4-b.dts`(DTS)로 제공. (근원: 이전 세션의 미검증 단정이 RPi 포크 지식을 mainline에 잘못 전이 — Kernel-Update-Log §1.)

### 3.3 builtin 강제 + 브랜딩 (`scripts/config` + `make olddefconfig`) — [원문]

defconfig 기본 상태 감사 후 적용한 델타. **명령 형식은 미기록**, 적용 옵션/결과는 원문 표 그대로:

| 옵션 | defconfig 기본 | 강제 결과 | 이유 |
|------|:---:|:---:|------|
| `PCIE_BRCMSTB` | m | **y** ✓ | Pi4 USB 컨트롤러가 PCIe 뒤 — USB 부팅 필수 |
| `DRM` | m | **y** ✓ | DRM 코어 builtin |
| `DRM_VC4` | m | m (강제 실패) | 의존성으로 모듈 유지 → **안 싸움**. udev 자동로드, 최악도 펌웨어 simplefb로 X |
| `BCMGENET` | m | **y** ✓ | Pi4 기가비트 이더넷 |
| `OVERLAY_FS` | m | **y** ✓ | Phase2 Live overlay |
| `SQUASHFS_ZSTD` / `SQUASHFS_XZ` | n | **y** ✓ | Phase2 Live squashfs 압축 |
| `NLS_UTF8` | — | **y** ✓ | vfat UTF-8 (한글 파일명) |
| `LOCALVERSION` | — | `"-maruxos"`, `LOCALVERSION_AUTO=n` | 브랜딩 |
| USB_STORAGE / XHCI_* / BLK_DEV_SD / SCSI | y | ✓ 유지 | |
| MMC / MMC_SDHCI_IPROC / MMC_BCM2835 | y | ✓ 유지 | SD 부팅 |
| EXT4 / FAT / VFAT / LOOP / INITRD | y | ✓ 유지 | |
| FB / FRAMEBUFFER_CONSOLE | y | ✓ 유지 | 콘솔 |
| HID / USB_HID / INPUT_EVDEV | y | ✓ 유지 | 키보드/마우스 |

(재구성) 강제 절차 예: `ARCH=arm64 scripts/config --enable PCIE_BRCMSTB --enable DRM --enable BCMGENET --enable OVERLAY_FS --enable SQUASHFS_ZSTD --enable SQUASHFS_XZ --enable NLS_UTF8 --set-str LOCALVERSION "-maruxos" --disable LOCALVERSION_AUTO` → `make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- olddefconfig`.

> **아키텍처 통찰** [원문]: x86_64는 minimal busybox initrd(`/lib/modules` 없음)라 전부 builtin 강제였음. **Pi는 진짜 ext4 root에 `/lib/modules` 적재 가능** → 부팅 critical(스토리지+root fs)만 builtin이면 되고 나머지(vc4/genet/sound…)는 모듈로 두고 `make modules_install`로 rootfs에 실으면 됨. **CLAUDE.md의 "필수 드라이버 builtin" 규칙은 x86_64 minimal-initrd 전용, Pi 트랙엔 그대로 적용 안 됨.** (단 MVP 무사고 위해 vc4/genet은 =y 권장.)

### 3.4 커널 빌드 — [원문]

```bash
make -j32 Image dtbs
```

(모듈은 rootfs 조립 때 `modules_install` — 원본 빌드 시점엔 미실행/미기록.)

### 3.5 Stage 1 완료 게이트 (전부 PASS) — [원문]

| 게이트 | 결과 |
|--------|------|
| `MAKE_RC` | **0** ✓ |
| `arch/arm64/boot/Image` | **50,022,912 B** (~47.7 MB, 비압축 arm64 Image = Pi `kernel8.img`) ✓ |
| `arch/arm64/boot/dts/broadcom/bcm2711-rpi-4-b.dtb` | **39,650 B** ✓ |
| baked `include/config/kernel.release` | **`6.18.26-maruxos`** ✓ |
| 빌드 시간 | ~9분 (32스레드, swap 미사용) |

> **관찰**: Image 47.7MB는 통합 defconfig가 전 arm64 SoC builtin을 vmlinux에 박아서 큼. 부팅엔 무해하나, Broadcom/Pi 외 SoC 비활성화로 슬림화(~10-15MB) 가능 — **슬림 vs 풀은 폴리시 패스로 보류(사용자 결정: 풀 유지)**. (§11의 옛 가설 (B)에서 이 50MB가 "로드 실패" 용의선상에 올랐으나 **✅ 반증됨(2026-07-08)** — 펌웨어는 50MB 커널을 정상 로드해 핸드오프했다. 풀 커널 유지가 정답.)

### 3.6 binfmt + qemu-chroot 실증 (Stage 2 진입 전) — [원문]

`.wslconfig` 11G+swap16 적용을 위해 `wsl --shutdown` **1회** 후:

| 항목 | 결과 |
|------|------|
| qemu-aarch64 binfmt 등록 | `enabled`, interpreter `/usr/bin/qemu-aarch64-static`, **`flags: F`(fix_binary, chroot 안전)** ✓ |
| qemu-chroot 실증 | x86_64 호스트가 정적 aarch64 ELF 직접 실행 rc=0 ✓ (end-to-end 검증) |

**함정 #2 — `update-binfmts` 부재** [원문]: 이 Ubuntu 24.04엔 `binfmt-support` 미설치라 qemu-user-static이 binfmt 자동등록을 못 함. systemd-binfmt도 WSL에서 자동 등록 안 함. → **수동 등록**:

```bash
echo ':qemu-aarch64:M::<magic>:<mask>:/usr/bin/qemu-aarch64-static:F' > /proc/sys/fs/binfmt_misc/register
```

(위 `<magic>`/`<mask>`는 원문에도 플레이스홀더로 기록됨 — aarch64 ELF magic/mask 실제 바이트열은 **미기록**. 재현 시 qemu-user-static이 제공하는 표준 aarch64 magic/mask 사용. `F` 플래그(fix_binary)는 필수 — chroot 안전 + 인터프리터를 등록 시점에 열어두므로 qemu 바이너리를 `$LFS` 안에 복사할 필요 없음.)

> ⚠️ **휘발성**: binfmt 등록은 `/proc` 런타임 상태 → `wsl --shutdown` 시 소실. RAM 튜닝은 이미 적용됐으니 **추가 shutdown 금지**. 이후 모든 chroot 청크 스크립트는 **시작 시 binfmt 재등록 + bind 마운트 재확립**을 표준 절차로 수행(함정 #5).

---

## 4. Stage 2 개요 — CLFS aarch64 rootfs

- **$LFS** = `/home/administrator/MaruxOS-arm64/rootfs-clfs-arm64` [원문]
- **$LFS_TGT** = `aarch64-lfs-linux-gnu` [원문]
- **--build** = `x86_64-pc-linux-gnu` (config.guess 경로 패키지별 차이 회피용 고정) [원문]
- **패키지 버전** = [`config/lfs-versions.conf`](../../config/lfs-versions.conf) SSOT 재사용 (x86_64와 동일: binutils 2.41 / gcc 13.2.0 / glibc 2.38 …) [원문]
- 절차 골격은 **LFS 12.0 Ch5/Ch6 커맨드**(툴체인·temp tools) + **12.1-era 유저랜드 버전**(Ch7·Ch8) [원문]. 개별 configure/make 줄은 대부분 **미기록** → 아래에서 (재구성)으로 표기.

### 4.1 Stage 2a — core 툴체인 소스 + SHA256 매니페스트 — [원문]

`$LFS/sources/`에 core 6종 다운로드(~37초). **Ch5 게이트 expected 값 (upstream GNU 공식과 교차검증 일치)**:

| 패키지 | 크기 | SHA256 |
|--------|------|--------|
| binutils-2.41.tar.xz | 26M | `ae9a5789e23459e59606e6714723f2d3ffc31c03174191ef0d015bdf06007450` |
| gcc-13.2.0.tar.xz | 84M | `e275e76442a6067341a27f04c5c6b83d8613144004c0413528863dc6b5c743da` |
| gmp-6.3.0.tar.xz | 2.0M | `a3c2b80201b89e68616f4ad30bc66aee4927c3ce50e33929ca819d5c43538898` |
| mpfr-4.2.1.tar.xz | 1.5M | `277807353a6726978996945af13e52829e3abd7a9a5b7fb2793894e18f1fcbb2` |
| mpc-1.3.1.tar.gz | 756K | `ab642492f5cf882b74aa0cb730cd410a81edcdbec895183ce930e706c1c759b8` |
| glibc-2.38.tar.xz | 19M | `fb82998998b2b29965467bc1b69d152e9c307d2cf301c9eafb4555b770ef3fd2` |

> **함정 #3 — 툴체인 버전 staging ≠ shipped** [원문]: x86_64 소스 dir엔 binutils **2.42**/glibc **2.39** 타르볼이 있었으나 이는 **빌드 안 된 staging 미끼**(glibc 업그레이드 트랙용). 설치된 `libc.so.6`(= release 2.38)가 ground truth. → **arm64는 glibc 2.38 / binutils 2.41 / gcc 13.2.0 베이스라인**으로 매치. **x86_64 소스 dir 무분별 재활용 금지**(정확한 파일명만). 교훈: "다운로드된 것 ≠ 빌드된 것 ≠ 메타데이터 주장. ground truth는 설치된 산출물뿐."

---

## 5. Chapter 4 — $LFS 스켈레톤 (aarch64는 lib64 생략)

**[원문]**: `rootfs-clfs-arm64/{etc,var,tools,usr/{bin,lib,sbin}}` + bin/lib/sbin 심링크 생성. **aarch64라 `lib64` 생략**(x86_64 전용) ✓.

(재구성) — LFS 12.x Ch4 표준 + aarch64 델타(`$LFS/lib64` 생성/심링크 **없음**):

```bash
export LFS=/home/administrator/MaruxOS-arm64/rootfs-clfs-arm64
mkdir -pv $LFS/{etc,var} $LFS/usr/{bin,lib,sbin} $LFS/tools
for i in bin lib sbin; do ln -sv usr/$i $LFS/$i; done
# x86_64와 달리 $LFS/lib64 및 그 심링크는 만들지 않는다 (aarch64 lp64는 /lib 사용 — 함정 #4)
```

> 사용자·권한(`lfs` 유저 생성 등) 및 정확한 `mkdir` 인자는 **미기록**. 원본은 root로 전 과정 드라이브(별도 `lfs` 유저 사용 여부 미기록).

---

## 6. Chapter 5 — 크로스 툴체인 (host x86_64 gcc → aarch64)

빌드 순서 [원문]: binutils pass1 → gcc pass1 → **우리 6.18.26 Linux API 헤더** → glibc 2.38(aarch64) → libstdc++. 로그의 서브스텝 번호는 아래 표 그대로(5.2는 로그에 등장 안 함 = 미기록).

### 6.1 완료 게이트 (전부 통과) — [원문]

| 단계 | 결과 |
|------|------|
| **Ch5.1** binutils pass1 | `aarch64-lfs-linux-gnu-ld` (GNU ld **2.41**) 설치 ✓ |
| **Ch5.3** gcc pass1 | **13.2.0** ✓ (함정 #4 osdir 교정 후 재빌드: osdir `../lib`) |
| **Ch5.4** Linux 헤더 | 우리 6.18.26 트리에서 `$LFS/usr/include` ✓ |
| **Ch5.5** glibc 2.38 | sanity: interpreter `/lib/ld-linux-aarch64.so.1` ✓ |
| **Ch5.6** libstdc++ | `/usr/lib` 설치 ✓, **lib64 잔재 0 (순수 lib)** ✓ |

### 6.2 함정 #4 — aarch64 gcc는 lp64를 `/lib64`로 보낸다 — [원문]

**증상**: Ch5.6 libstdc++가 `$LFS/usr/lib`가 아닌 `$LFS/usr/lib64`에 설치됨 → glibc(`/usr/lib`, `libc_cv_slibdir=/usr/lib` 강제)와 lib 경로 분열.

**원인**: `gcc/config/aarch64/t-aarch64-linux:25` → `MULTILIB_OSDIRNAMES = mabi.lp64=../lib64…`. aarch64 gcc는 lp64 osdir 기본이 `../lib64`. (x86_64의 `gcc/config/i386/t-linux64` `m64=../lib64`를 LFS가 sed로 고치는 그 부분의 aarch64판.)

**해소 — gcc 빌드 *전* sed로 osdir 교정** [원문]:

```bash
sed -e '/mabi.lp64=/s/lib64/lib/' -i.orig gcc/config/aarch64/t-aarch64-linux
```

- 이후 gcc pass1 재빌드 + libstdc++ 재빌드. glibc는 위치(`/usr/lib`) 정상이라 재빌드 불요(새 gcc가 `/lib`에서 링크 — sanity 재확인).
- **이 sed는 Ch6 gcc pass2 + Ch8 gcc final에도 매번 적용 필수.** (gcc 소스 트리에 적용 → pass2도 같은 트리 재사용 시 자동 상속 — 로그: "함정 #4의 sed는 gcc 소스 트리에 적용됨 → gcc pass2(Ch6)도 자동 상속.")

### 6.3 개별 명령 (재구성 경계)

- (재구성) binutils pass1 / gcc pass1 / glibc / libstdc++ 의 configure·make·make install 줄은 **LFS 12.0 Ch5 표준 절차**를 따르되 아래 로그 명시 델타를 반드시 반영: `$LFS_TGT=aarch64-lfs-linux-gnu`, `--build=x86_64-pc-linux-gnu`, `--disable-multilib`(aarch64 특화), `--with-glibc-version=2.38`, **함정 #4 osdir sed**, **lib64 관련 sed(x86_64용)는 생략**, Linux 헤더는 우리 6.18.26 트리 사용.
- 정확한 configure 플래그 전체 줄은 **미기록**.
- **호스트 deps 보강** [원문]: Ch5.1에서 `makeinfo: not found` → `texinfo/gawk/m4/patch/gettext` 설치로 해결(§2.1 각주).

---

## 7. Chapter 6 — temp tools 17개 크로스컴파일 → $LFS/tools

**[원문]** Ch6 완료(~14분): temp tools **17개** 전부. 게이트 통과(bash/ls/make/sed/tar/gawk/grep/gcc pass2/cc ✓).

**패키지 목록(17)** [원문]:
```
m4 · ncurses · bash · coreutils · diffutils · file · findutils · gawk ·
grep · gzip · make · patch · sed · tar · xz · binutils(pass2) · gcc(pass2)
```

- **경미 노트** [원문]: binutils pass2의 `ltmain.sh` 6031 라인 sed는 라인 불일치로 스킵(binutils 2.41은 라인이 다름). 빌드 정상(클린 sysroot라 host-lib 누수 미발생). 필요 시 content-based sed로 교체.
- gcc pass2도 함정 #4 osdir sed를 상속받은 gcc 소스 트리에서 빌드.
- (재구성) 개별 명령은 **LFS 12.0 Ch6 커맨드** 기준 — 정확한 줄은 **미기록**.

---

## 8. Chapter 7 — chroot 준비 + qemu-chroot 진입 + chroot temp tools

### 8.1 chown + 가상 FS bind 마운트 + binfmt — [원문 + 재구성]

- **[원문]** 가상 FS(`dev` `pts` `proc` `sys` `run`) **bind 마운트**.
- **[원문]** chroot 진입 전 binfmt(`/proc/sys/fs/binfmt_misc/qemu-aarch64`) 등록 재확인 — shutdown/슬립 시 소실되므로 매번(함정 #2/#5).
- (재구성) chown — LFS 12.x Ch7.2 표준: `chown -R root:root $LFS/{usr,lib,var,etc,bin,sbin,tools}` (`lib64` 항목은 aarch64라 제외). 정확한 인자는 **미기록**.
- (재구성) 가상 FS 마운트 — LFS 12.x Ch7.3.1 표준:
  ```bash
  mount -v --bind /dev $LFS/dev
  mount -v --bind /dev/pts $LFS/dev/pts
  mount -vt proc proc $LFS/proc
  mount -vt sysfs sysfs $LFS/sys
  mount -vt tmpfs tmpfs $LFS/run
  ```
- **F 플래그(fix_binary)** 덕에 `qemu-aarch64-static`을 `$LFS` 안에 복사할 필요 없음(§3.6).

### 8.2 qemu-chroot 결정적 테스트 — 통과 (심장부) — [원문]

```
chroot 진입 OK
uname -m (qemu): aarch64            ← qemu-user가 aarch64 응답
bash 5.2.21 (aarch64-lfs-linux-gnu) ← 크로스빌드 bash가 qemu로 실행
gcc 13.2.0                          ← gcc pass2도 qemu로 실행
```

→ **cross→emulated 전환 성공.** 이후 시스템을 chroot 안에서 네이티브(에뮬) 빌드. (재구성) chroot 명령은 LFS 12.x Ch7.4 표준 `chroot "$LFS" /usr/bin/env -i … /bin/bash --login` 형태 — 정확한 줄은 **미기록**.

### 8.3 chroot temp tools 6개 + FHS/필수파일 — [원문]

- Ch7.5 FHS 디렉토리 + Ch7.6 필수 파일(`passwd`/`group`/`hosts`/logs) 생성.
- 추가 temp tools **6개**: `gettext · bison · perl · Python · texinfo · util-linux`.
- **버전(x86_64 쉬핑 매치, 12.1-era)** [원문]: gettext **0.22.4**, perl **5.38.2**, Python **3.12.2**, util-linux **2.39.3**, bison **3.8.2**, texinfo **7.1**.
- 완료(chroot 내부, **~1h37m** qemu). 게이트: `perl`·`python3`·`bison`·`msgfmt`·`makeinfo`·`mount` 전부 ✓.

**실행 방식** [원문]:
- chroot 내부 스크립트는 파일로 박아 실행(따옴표 회피). **경미 버그**: 1차 시도 시 `cat > $LFS/root/ch7.sh` 실패 — `/root`가 아직 없었음(7.5에서 생성 예정) → **존재 확실한 `/sources`에 작성**하도록 수정 후 정상.
- qemu 부하 고려 `-j16`.

### 8.4 백업 (Ch8 장기전 대비) — [원문]

- `$LFS` 백업: **`lfs-ch7-snapshot.tar`** (**3.2G**, 가상FS·sources 제외) — Ch8 장기빌드 사고 대비.
- Ch8 소스 pre-stage: `$LFS/sources` = **186 타르볼 + 7 패치** (x86_64에서 복사, staging binutils-2.42/glibc-2.39 **제외**). 버전 = x86_64 쉬핑(12.1-era 유저랜드). Ch8 다운로드 없이 진행.

---

## 9. Chapter 8 — 전체 시스템 ~80 패키지 (glibc/binutils/gcc FINAL + 유저랜드 + init)

> **시간 현실** [원문]: Ch8 전체 ~80패키지 = qemu 에뮬로 누적 **8-15시간+**(밤샘급). glibc/gcc/perl/python 재빌드가 각 30분-2시간.

**실행 전략 — 청크 분할 + resumable** [원문]:
- 각 청크 스크립트는 `$LFS/sources/ch8-N.sh`로 박아 chroot 실행.
- **resumable 마커**: `$LFS/sources/.done/<pkg>` → 실패/중단 시 그 패키지부터 재개.
- **각 청크 스크립트 시작 시 binfmt 재등록 + bind 마운트 재확립**(함정 #2/#5 표준 절차).
- heavy(glibc/binutils/gcc final)는 단독 청크로 게이트 검증.

### 9.1 청크별 패키지 (전부 ✅) — [원문]

| 청크 | 패키지 | 비고 |
|------|--------|------|
| **8-1** | man-pages · iana-etc · **glibc FINAL** · zlib · bzip2 · xz · zstd · file · readline · m4 · bc · flex | **ko_KR.utf8 로케일 + Asia/Seoul 타임존** 박힘 |
| **8-2** | pkgconf · **binutils FINAL** · gmp · mpfr · mpc · attr · acl · libcap · libxcrypt · shadow | shadow: root pw `root`, `ENCRYPT_METHOD=YESCRYPT` |
| **8-3** | **gcc FINAL** | 함정 #5 연쇄장애 → 외과복원 → 클린 재빌드 (§9.2) |
| **8-4** | ncurses · sed · psmisc · gettext · bison · grep · bash · libtool · gdbm · gperf · expat · inetutils · less · perl · XML-Parser · intltool · autoconf · automake | ncurses widec 수정 |
| **8-5** | openssl · kmod · elfutils · libffi · **Python** · flit_core · wheel · setuptools · ninja · meson · coreutils · check · diffutils · gawk · findutils · groff · gzip · iproute2 · kbd · libpipeline · make · patch · tar · texinfo · vim · MarkupSafe · Jinja2 · procps-ng · util-linux · e2fsprogs | pip 24.0 부트스트랩 |
| **8-6** | **eudev** · **sysvinit** · lfs-bootscripts · dbus + 시스템 설정 | init+udev+config. **GRUB 스킵**(Pi 펌웨어 부팅) |

> **init 선택** [원문]: **sysvinit**(systemd 아님) + LFS-bootscripts + **eudev**(udev). GRUB 미설치(Pi는 start4.elf 직접 kernel8.img 로드).
> (재구성) 개별 패키지 configure/make 줄은 **LFS 12.1 Ch8 커맨드** 기준 — 정확한 줄은 대부분 **미기록**. glibc FINAL의 로케일/타임존은 로그 명시(ko_KR.utf8 + Asia/Seoul).

### 9.2 함정 #5 — 호스트 슬립이 binfmt를 죽여 gcc FINAL 연쇄장애 (발표용 핵심) — [원문]

**증상**: gcc final이 make 완주 + install 시작 후, **~4시간 갭(머신 슬립)** 동안 binfmt + bind 마운트 소실 → install 중간 잘림 → `cc1`/`cc1plus` 미설치 → `gcc: cannot execute 'cc1'`.

**연쇄 장애**:
1. **깨진 /usr/bin/gcc**: 중단된 final install이 pass2 gcc를 덮어씀(드라이버는 새 triplet `aarch64-unknown-linux-gnu`로 설치, cc1/cc1plus 미설치).
2. **클린 재빌드도 실패(exit 77)**: gcc final configure가 conftest에 깨진 `/usr/bin/gcc` 사용 → "C compiler cannot create executables".
3. **부트스트랩 부재 확인**: `/tools/bin/aarch64-lfs-linux-gnu-gcc`는 **x86_64 크로스 바이너리**(Ch5 pass1, `--host` 미지정)라 aarch64 chroot에서 실행 불가.

**복구 — 외과적 pass2 gcc 복원(전체 롤백 회피)**:
- Ch7 백업(`lfs-ch7-snapshot.tar`)에서 **gcc 드라이버 17개 + `/usr/libexec/gcc` + `/usr/lib/gcc`만** 추출 복원 (glibc final·binutils final·기타 22패키지는 **보존**).
- 검증: gcc `aarch64-lfs-linux-gnu`, C 컴파일 rc=42 ✓, C++ ✓, glibc final(11.9MB) 보존 ✓, binutils ld 2.41 보존 ✓ → 작동 부트스트랩 확보 → gcc final 클린 재빌드 configure 통과.

**항구 대책** [원문]:
- 호스트 슬립 방지: `powercfg /change standby-timeout-ac 0` + `hibernate-timeout-ac 0`; 이후 lid-close도: `powercfg SUB_BUTTONS LIDACTION 0`. **가역** — 복구: `powercfg /change standby-timeout-ac 30`, `LIDACTION 1`.
- 모든 청크 스크립트 시작 시 binfmt/마운트 재확립 + `.done` 마커 → 중단돼도 자가 복구.

### 9.3 시스템 설정 — [원문]

- **hostname** `marux`; os-release aarch64; **root pw `root`**(Stage 5 정식 설정 예정); 로케일 **C.UTF-8 (+ ko_KR)**.
- **inittab**: `tty1`~`tty6` + **`ttyS0` 시리얼 디버그 콘솔**(TTL-USB용). (v2에서 `ttyAMA0` getty 추가 — §10.3.)
- **fstab**: SD카드 기준 — `/dev/mmcblk0p2` root ext4, `/dev/mmcblk0p1` `/boot` vfat (Stage3 매체 확정 시 조정).

### 9.4 Stage 2 완료 스모크 테스트 (chroot) — [원문]

```
MaruxOS 2.0.0 "Cooked" (aarch64)
bash 5.2.21 | gcc 13.2.0 | glibc 2.38 | Python 3.12.2 | ld 2.41
ko_KR.utf8 ✓ | TZ KST ✓ | C 컴파일+실행 OK(self-hosting) ✓ | python 42 ✓
udevd 251 ✓ | /sbin/init ✓ | /usr/bin 584개 | .so 244개 | rootfs 4.6G
```

- **백업**: `lfs-rootfs-complete.tar` (**4.6G**, 완성 rootfs 스냅샷). (경로: `~/MaruxOS-arm64/lfs-rootfs-complete.tar`.)
- **완성 시각**: 2026-06-23 01:52. **MaruxOS 역사상 첫 aarch64 from-scratch rootfs.**

---

## 10. 부팅 이미지 조립 (Stage 3 — SD 직부팅)

**사용자 결정(2026-06-23)** [원문]: Stage3 = **SD 직부팅**; 펌웨어 = **RPi 공식 Broadcom blob**; 검증 = **실기기 직행**(QEMU virt는 Pi4를 정확히 에뮬 못함).

### 10.1 펌웨어 blob (Broadcom, third-party — BIOS급, 정체성 무관) — [원문]

`config-arm64/firmware/`에 박제된 실제 파일(2026-06-18 RPi OS SD 유래, Broadcom 공식):

| 파일 | 크기 (bytes, 실측) |
|------|------:|
| `start4.elf` | 2,305,632 |
| `start4x.elf` | 3,053,352 |
| `fixup4.dat` | 5,499 |
| `fixup4x.dat` | 8,494 |
| `overlays/disable-bt.dtbo` | 1,073 |
| `overlays/miniuart-bt.dtbo` | 1,566 |
| `overlays/vc4-kms-v3d.dtbo` | 2,760 |

> **절대 원칙** [원문, 사용자 2026-07-02]: "다른 OS 참고한답시고 이 프젝을 라파 그자체로 만들면 안 됨." → **Broadcom 펌웨어(start4.elf=GPU 펌웨어=BIOS급)·overlays·config 형식만 참조/사용. 커널(우리 mainline 6.18.26-maruxos)·rootfs(우리 from-scratch)·dtb(우리 mainline)는 100% 우리 것.**
> ⚠️ (v1은 raspberrypi/firmware master `start4.elf` 2,306,400 사용 → §10.4에서 RPi OS 검증본 2,305,632로 교체됨.)

### 10.2 boot 파티션 (FAT32) 의무 파일 — [원문]

- `bootcode.bin` (Pi 4는 EEPROM에 있어 생략 가능하나 안전상 포함)
- `start4.elf` / `fixup4.dat` (Broadcom blob)
- `bcm2711-rpi-4-b.dtb` (우리 mainline 산출물, **39,650 B**)
- `kernel8.img` (우리 커널 `Image`, **50,022,912 B**)
- `config.txt` / `cmdline.txt` (우리 작성)

### 10.3 config.txt / cmdline.txt (v2, 순수 ASCII) — [원문 파일 verbatim]

`config-arm64/config.txt`:
```
arm_64bit=1
kernel=kernel8.img
enable_uart=1
dtoverlay=disable-bt
disable_overscan=1
```

`config-arm64/cmdline.txt`:
```
console=ttyAMA0,115200 console=ttyS0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 rootwait fsck.repair=yes net.ifnames=0
```

> **부팅 함정(적발·수정됨)** [원문]: v1의 `config.txt`에 **한글 주석 → mojibake** → Pi 원시 파서가 죽음. → **순수 ASCII로 교체(BOM 없음 확인)**. "비ASCII가 Pi 부트로더를 죽인다."
> **시리얼** [원문]: v1은 `console=ttyS0`(mini-UART, baud 흔들려 ▒▒). v2는 **PL011(ttyAMA0) via `dtoverlay=disable-bt`** + cmdline에 ttyAMA0/ttyS0 양쪽 헤지 + inittab에 `ttyAMA0` getty 추가.

### 10.4 이미지 조립 절차 — [원문 요약, 명령 재구성]

**[원문]** 레이아웃/도구: `truncate -s 7G` → `sfdisk`(p1 512M **type c** bootable, p2 **L**=ext4) → `losetup -fP` (loop0, WSL2 OK) → `mkfs.vfat -F32` / `mkfs.ext4` → rootfs `lfs-rootfs-complete.tar` 전개 → boot 파티션 populate → `xz -T0`. WSL root 권한.

(재구성) — 위 원문 요약을 명령으로 편 것(정확한 sfdisk 스크립트/옵션 줄은 **미기록**):
```bash
truncate -s 7G MaruxOS-2.0.0-arm64.img
sfdisk MaruxOS-2.0.0-arm64.img <<'EOF'
label: dos
,512M,c,*
,,L
EOF
losetup -fP MaruxOS-2.0.0-arm64.img          # → /dev/loop0, p1=loop0p1 p2=loop0p2
mkfs.vfat -F32 /dev/loop0p1
mkfs.ext4     /dev/loop0p2
# root 파티션: rootfs tar 전개
mount /dev/loop0p2 /mnt/root && tar -xf ~/MaruxOS-arm64/lfs-rootfs-complete.tar -C /mnt/root
# boot 파티션: 펌웨어 + kernel8.img + dtb + config/cmdline populate
mount /dev/loop0p1 /mnt/boot
cp firmware/{start4.elf,fixup4.dat} kernel8.img bcm2711-rpi-4-b.dtb config.txt cmdline.txt /mnt/boot/
# (inittab에 ttyS0 + ttyAMA0 getty를 이미지 조립 시 sed로 추가 — 원문)
umount /mnt/boot /mnt/root && losetup -d /dev/loop0
xz -T0 MaruxOS-2.0.0-arm64.img               # → MaruxOS-2.0.0-arm64.img.xz
```

### 10.5 산출물 이력 — [원문 + 실측]

> **⚠️ 갱신(2026-07-30)**: 이 절은 v2까지의 부팅-디버깅 스냅샷이었다. 이후 v3~v16으로 진화했다. **파일명은 계속 동일**(`output/MaruxOS-2.0.0-arm64.img.xz`, 매번 덮어씀). 아래 표에 주요 마일스톤 버전을 추가한다.

| 버전 | 압축 크기 | SHA256 | 마일스톤 |
|------|----------:|--------|----------|
| v1 | 1.1G | `605ec90af39ccd262ecd8a9f66b1b279482818c7acf2233078a7b5425173bd59` | 첫 SD 직부팅 이미지 (2026-06-23) |
| v2 | 1.02GB | `eab7dc2bf9553ee1d5f9931e1856c67c5b18acc6cdf697db6e2b35cf40d15131` | 부팅 디버깅 (2026-07-05, 당시 "미해결" — 실제론 시리얼 관측 불능) |
| v4 | — | `93b263645e326e57196d243b477ee0a6be204bc1fc651956512bd59360540fe4` | FAT 256M+config 실험 (2026-07-05, 여전히 관측 불능) |
| **v6** | 2.9G | `894c75e4cfe7bcc3c2031d2c1b5042fe02d46e648eb5acd0c4742dd35d682825` | **🎉 무인 클린부팅 → `marux login:` + self-hosting (2026-07-08)** |
| v7.1 | 3.0G | `29a794cf6243f3418f5e60ccaa19447e4e55fb90cf03ff706eab53ad19b7cd8c` | 실물 HDMI 그래픽 데스크톱 + 입력(libinput) + 한글 표시 (2026-07-17/18) |
| v8 | 3.1G | `a8b733de209288de8fdbe9ec7d71c80d8163b4300d26f1a8807bd16a6508f436` | 데스크톱 x86 패리티 (feh·mc·아이콘·메뉴, 2026-07-20) |
| **v9** | 3.1G (3,251,016,632 B, 실측) | `6829830f87acb73d58c88975d5c0d9a83bb89ab990b14be98fd54ef6746569f3` | **ibus-hangul XIM 빌드 — 한글 입력**(런타임 픽스로 실기기 검증, 2026-07-22). 동일 파일명으로 v10에 덮어써짐. |
| **v10** | 3.03GB (3,249,853,780 B) | `2b73877b24f2d2953509eed36d6fbba4efb2f5314921774ff7ad42846d8a20f2` | **🎉 out-of-box 한글**(ibus 코어 gschema + machine-id baked-in, 수동 픽스 불요, 2026-07-23) |
| v11 | 3.1G (3,328,213,080 B) | `fcb599b3547c33a5496fa0e105aa7efea4edca30c86d0d7aaac5b46911cbbf1a` | gtk+-3.24.41(qemu-chroot — 옛 "gtk3 벽"은 binfmt 중도사 오진) + **Firefox ESR 140.13.0esr 공식 aarch64 한국어**(`/opt/firefox`) + gtk3 ibus immodule(GTK3 앱 한글 입력) + alsa-lib + setxkbmap (2026-07-25) |
| **v12** | 3.2G (3,332,335,020 B) | `294cfade858faeb9d9eb31a39bf3676970d93241b3f4b3f926cec29337f77982` | **🌐 유선 네트워크 out-of-box** — dhcpcd 10.0.6(DHCP) + chrony 4.5(NTP, "1970 시계" 완치). **실기기 웹서핑 검증 ✅** (2026-07-27) |
| v13 | 3.2G (3,329,485,712 B) | `3f3023681d02a2f9bf61603105e7d683301f9c31e02879f295e6610b64c56ce7` | HW커서 복권 + HDMI 1080p60 강제(TV 호환) + libinput flat 가속 (2026-07-27) |
| **v14** | 3.2G (3,340,464,724 B) | `7f836cde37e2f480231e9513eeec4a9d5ac73e02827eab1b09b928d4273bf612` | **🚢 Plank dock 소스빌드**(vala 0.56.17 부트스트랩 = 자체 valac + 11종 체인) + gschema.override/keyfile 정공픽스. **실기기 검증 ✅** (2026-07-28) |
| v15 | 3.2G (3,351,321,332 B) | `5fef190d4922a2a1d8f28ab81ab296095b6121708d719a0a156664f06f2ee4fb` | picom v11.2(xrender+vsync) + Marux 반투명 유리 테마 (2026-07-29) |
| **v16** | 3.2G (3,362,609,608 B, 실측) | `57daa20ad5df363245ae839918b07ff4d2101b61680e5f701626fb7a76fb8e1f` | **라이브픽스 4종**(클릭 창전환 rc.xml Client 컨텍스트·wnck SN 재빌드·유리 확정값 10/95·HDMI RGB 스팸 제거) (2026-07-29, mtime 16:13). **← 현재 `output/`에 물리적으로 존재하는 이미지**(사이드카 SHA 일치 실측). *(→ 2026-08-14 재규명: 4종 중 wnck SN 재빌드는 오진 — bamfdaemon 실근원 = libwnck 43.0 업스트림 버그[함정 #25], 43.2 버전업으로 v17에서 완결(✅ 2026-08-14 빌드·실기기 검증))* |

> **주의(실측, 2026-07-30)**: `output/MaruxOS-2.0.0-arm64.img.xz.sha256` 사이드카는 **v16 SHA(`57daa20a…`)로 갱신 완료** — 현재 디스크상 이미지 v16과 일치.

---

## 11. 실기기 부팅 검증 상태 — ✅ RESOLVED (2026-07-08)

> ### ✅ RESOLVED (2026-07-08, 재확인 2026-07-23)
> **이 절 전체는 2026-07-05 스냅샷의 "미해결" 서술이다. 실제로는 2026-07-08에 해결됐고, 아래 §11.2의 두 가설(A/B)은 둘 다 틀렸다.** 디버깅 추론은 방법론 기록으로 보존하되, 실제 결말을 먼저 못박는다:
> - **실제 원인 = 관측 불능 + 콘솔 라우팅 + 경미한 rootfs 설정.** ① **죽어가던 FT232RL 시리얼 어댑터**(v1~v4 전부 "장님 디버깅"이었다. LED만 보고 추측) → 새 FT232RL + **흰↔초록 배선 스왑**(핀8=초록=어댑터TX, 핀10=흰=어댑터RX) + `enable_uart=1`로 시리얼 부활. ② cmdline **`console=ttyS0,115200`를 맨 뒤로** 이동 → `/dev/console`이 시리얼에 물림(유저스페이스가 안 보이는 tty1 더미 콘솔로 새고 있었음) → init/rc 출력이 처음으로 드러남. ③ 경미한 rootfs 설정 4종(`/bin/udevadm` 심링크 누락, fstab `/dev/shm`+cgroup 누락, S70console setfont, S10sysklogd)이 rc마다 "Press Enter" 정지 유발 → v6에서 픽스 → **무인 클린부팅(FAIL 0) → `marux login:`.**
> - **"짧2 LED"는 부팅 실패 신호가 아니었다.** 커널은 처음부터 완전 부팅했다(4-CPU SMP·PCIe link up·USB xhci·bcmgenet eth0·ext4 root 마운트·`/sbin/init` 실행 전부 확인). **펌웨어는 우리 부트 파티션(start4/config/dtb/cmdline/kernel8 50MB)을 완벽히 읽고 커널로 핸드오프했다.**
> - **§11.2 (A) FAT 구조 ❌ / (B) 50MB 커널 ❌ — 둘 다 반증.** §11.3의 격리 테스트는 실행 전에 무의미해졌다(범인이 이미지가 아니라 관측/콘솔이었으므로).
> - **HDMI 블랙아웃**도 부팅 실패가 아니라 최소 config에 디스플레이 드라이버 부재(dummy console)였을 뿐 → 커널 VC4/V3D `=y` + config.txt `max_framebuffers=2`(mainline dtb라 dtoverlay 불요)로 1080p 콘솔 부활(Stage 5a).
> - 이후: v7.1(실물 그래픽 데스크톱+입력+한글표시) → v8(x86 패리티) → **v10(out-of-box 한글 입력)**.
>
> ---
> **(아래는 2026-07-05 당시 원문 — 역사적 디버깅 추론 보존. "미해결"은 그 시점 기준이며 현재는 위 RESOLVED가 정본.)**
>
> rootfs·이미지 조립은 완료·검증됨. **실기 Pi 4B 부팅은 성립하지 않았다.** 재현 시 여기서 막힌다는 점을 반드시 인지할 것.

### 11.1 확정된 사실 (재검증 완료, 추측 아님) — [원문]

1. **RPi OS Lite가 같은 SD/Pi에서 정상 부팅** → SD카드·리더·Pi 하드웨어·EEPROM 전부 정상. **범인은 우리 이미지.**
2. **우리 부트 파일 PC 검증 완벽**: start4.elf / fixup4.dat / kernel8.img(50,022,912) / bcm2711-rpi-4-b.dtb(39,650) / config.txt / cmdline.txt 다 정확한 크기, FAT32 읽힘.
3. **파티션 레이아웃 정상**: p1 512MB FAT32 + p2 6.5GB ext4. (Windows가 ext4 못 읽어 ~510MB만 보이는 건 정상.)
4. **커널/dtb 산출물 유효**: kernel8.img = 정상 arm64 Image(magic `ARMd@`, "Linux kernel ARM64 boot executable"), dtb = 정상 FDT(magic `d00dfeed`). **파일 안 깨짐.**
5. **펌웨어는 범인 아님**: v1(master 2,306,400) → 짧2. v2(RPi OS 검증본 2,305,632) → **똑같이 짧2**.
6. **증상 = 초록 LED 짧은 깜빡 2번 반복**(공식 표+사용자 확인) = 펌웨어가 부트 파티션/파일을 못 찾음. start4.elf는 로드됨(무지개 0.1초) → 그 다음 kernel8/config 읽기 실패로 추정.

### 11.2 남은 가설 (둘 중 하나) — [원문] · ❌ 둘 다 반증됨 (2026-07-08)

> ❌ **반증**: 아래 두 가설은 모두 틀렸다. 시리얼이 부활하자 커널·펌웨어 모두 정상임이 드러났다(범인은 이미지가 아니라 죽은 어댑터 + 콘솔 라우팅). 역사 보존용으로 남긴다.

- **(A) FAT 파티션 구조**를 Pi 원시 파서가 못 읽음 (`mkfs.vfat` 산출 FAT를 Pi가 싫어함. Windows는 관대). RPi OS FAT는 됨. — ❌ **반증**: 펌웨어가 우리 FAT 부트 파티션을 완벽히 읽었다.
- **(B) 50MB 커널**(통합 defconfig, 전 SoC builtin)이 로드 실패 (RPi 포크는 ~10MB). 크기/로드주소 문제. — ❌ **반증**: 50MB 커널은 정상 로드·완전 부팅됐다.

### 11.3 다음 액션 = 격리 테스트 (kernel vs FAT 못박기) — [원문] · ⏭️ 실행 전 무의미해짐 (2026-07-08)

> ⏭️ **무의미해짐**: 이 격리 테스트는 "이미지가 범인"이라는 전제였는데 그 전제가 틀렸다(범인 = 죽은 시리얼 어댑터 + `console=ttyS0` 순서). 시리얼 부활 + 콘솔 라우팅 픽스로 곧장 부팅에 도달해 실행 불요가 됐다. 방법론 예시로 보존.

**우리 kernel8.img+dtb를 RPi OS의 "작동하는 부트체인" 위에 얹어 부팅** → 변수 하나로 좁힘:
- 준비물: `config-arm64/isolation-test/{kernel8.img (50,022,912), bcm2711-rpi-4-b.dtb (39,650)}` (우리 것 복사됨).
- 절차: RPi OS Lite 재플래시 → PC(F:)에서 우리 kernel8.img+dtb 덮어쓰기 + config.txt 최소세팅(RPi 펌웨어/FAT 유지) → 부팅.
- 판정: 시리얼에 `Booting Linux…` 뜨면 → **커널 정상 = FAT가 범인** / 여전히 짧2 → **커널이 범인**.
- **FAT 범인 픽스(준비됨)**: mkfs.vfat 대신 Pi-friendly FAT 재조립(RPi OS FAT 파라미터 복제 or `mkfs.fat -F32 -s <cluster>` 명시).
- **커널 범인 픽스(준비됨)**: 통합 defconfig에서 Broadcom/Pi 외 SoC(MediaTek/Rockchip/Qualcomm/Tegra…) 비활성 → ~10-15MB.

### 11.4 시리얼 배선 — [원문]

FT232RL, **COM9**, 115200. 배선: GND→핀6, TX→핀8, RX→핀10, 3.3V; 빨강(VCC) **연결 안 함**. (▒▒ 깨진 글자 = mini-UART baud 흔들림 → v2에서 PL011/ttyAMA0로 전환.)

---

## 12. ARM64 함정 카탈로그 (5종 + 부팅) — [원문]

| # | 함정 | 요지 |
|---|------|------|
| **#1** | mainline엔 `bcm2711_defconfig` 없음 | RPi 포크 전용. 통합 `make defconfig` + Pi4 builtin 강제로 해소 (§3.2). |
| **#2** | `update-binfmts` 부재 | binfmt-support 미설치 → 수동 등록(F 플래그). shutdown/슬립 시 소실 → 매번 재등록 (§3.6). |
| **#3** | 툴체인 staging ≠ shipped | 소스 dir glibc 2.39/binutils 2.42는 빌드 안 된 미끼. 설치된 libc.so.6(2.38)이 진실 → glibc 2.38 베이스라인 (§4.1). |
| **#4** | aarch64 gcc lib → lib64 | `t-aarch64-linux` osdir `../lib64` → `mabi.lp64` sed로 `../lib` 교정. gcc 빌드마다 적용 (§6.2). |
| **#5** | 슬립이 binfmt 죽여 연쇄장애 | 호스트 슬립 → gcc final install 중단 → 컴파일러+부트스트랩 붕괴 → 외과적 pass2 복원. 슬립방지 + resumable 마커 (§9.2). |
| 부팅 | 비ASCII config.txt / 짧2 | config.txt 한글 주석 mojibake가 Pi 파서 죽임(수정). 짧2 = 부팅 실패 아님 — **✅ 해결(2026-07-08)**: 실제 원인은 죽은 시리얼 어댑터(관측 불능) + `console=ttyS0` 순서 + 경미 rootfs 설정. FAT/50MB 커널 가설 둘 다 반증(§11). |

---

## 13. 자산·경로 요약 (핸드오프) — [원문]

| 자산 | 경로 / 값 |
|------|-----------|
| 빌드 루트 | `/home/administrator/MaruxOS-arm64/` |
| `$LFS` | `/home/administrator/MaruxOS-arm64/rootfs-clfs-arm64` |
| 커널 산출물 | `~/MaruxOS-arm64/kernel/linux-6.18.26/arch/arm64/boot/{Image, dts/broadcom/bcm2711-rpi-4-b.dtb}` |
| rootfs 백업(완성) | `~/MaruxOS-arm64/lfs-rootfs-complete.tar` (4.6G) |
| rootfs 백업(Ch7) | `~/MaruxOS-arm64/lfs-ch7-snapshot.tar` (3.2G) |
| 검증 펌웨어 | `config-arm64/firmware/` (start4.elf 2,305,632 등) |
| 격리 테스트용 (미실행 — §11.3 무의미해짐) | `config-arm64/isolation-test/{kernel8.img 50,022,912, bcm2711-rpi-4-b.dtb 39,650}` |
| Pi boot config | `config-arm64/config.txt`, `config-arm64/cmdline.txt` (부팅 해결 후 `console=ttyS0` 맨 뒤 + rootfs fstab 픽스 반영) |
| 이미지 (현재 디스크상) | `output/MaruxOS-2.0.0-arm64.img.xz` = **v16** (3,362,609,608 B, SHA `57daa20a…b8e1f` 사이드카 일치 실측, mtime 2026-07-29 16:13 — Plank+picom 데스크톱 완성 + 라이브픽스 4종). 직전 v15(`5fef190d…`)를 동일 파일명으로 덮어씀. 이력 표 = §10.5. |
| 버전 SSOT | `config/lfs-versions.conf` (KERNEL 6.18.26 / SHA `53772f5d…b0ec` / gcc 13.2.0 / binutils 2.41 / glibc 2.38) |

---

## 14. 재현 체크리스트 (요약)

1. **Stage 0**: apt cross-toolchain + qemu-user-static + 커널 deps + (호스트 LFS deps: texinfo/gawk/m4/patch/gettext) → `~/MaruxOS-arm64/{toolchain,kernel,firmware,rootfs-clfs-arm64,iso-build,output}` 생성 → 게이트(dumpmachine=aarch64-linux-gnu, ext4) → `.wslconfig` 11G/swap16 후 `wsl --shutdown` 1회.
2. **Stage 1**: linux-6.18.26.tar.xz 다운(**SHA `53772f5d…b0ec` 게이트**) → `make defconfig`(함정 #1) → builtin 강제(PCIE_BRCMSTB=y 등)+`LOCALVERSION=-maruxos` → `make -j32 Image dtbs` → 게이트(Image 50,022,912 B / dtb 39,650 B / kernelrelease `6.18.26-maruxos`).
3. **binfmt 수동 등록(F) + qemu-chroot 실증**(함정 #2).
4. **Ch4** 스켈레톤(lib64 생략) → **Ch5** 크로스 툴체인(binutils1→gcc1→헤더→glibc2.38→libstdc++, 함정 #4 sed) → **Ch6** temp tools 17 → **Ch7** chown+bind마운트+chroot+temp tools 6(백업 lfs-ch7-snapshot.tar).
5. **Ch8** 청크 8-1~8-6(~80패키지, glibc/binutils/gcc FINAL + 유저랜드 + eudev/sysvinit/bootscripts/dbus + hostname=marux/inittab/fstab), resumable `.done` 마커 + 슬립방지(함정 #5) → 스모크 테스트 → 백업 lfs-rootfs-complete.tar (4.6G).
6. **이미지 조립**: truncate 7G → sfdisk(p1 512M type c, p2 L) → losetup -fP → mkfs.vfat/ext4 → rootfs tar 전개 → boot populate(펌웨어+kernel8.img+dtb+config/cmdline) → xz -T0.
7. **실기 부팅**: ✅ **해결(2026-07-08)** — 시리얼 어댑터 부활(새 FT232RL + 흰↔초 배선 스왑) + cmdline `console=ttyS0` 맨 뒤 배치 + rootfs 설정 4종 픽스(udevadm 심링크/fstab shm·cgroup/S70console/S10sysklogd) → 무인 클린부팅(FAIL 0) → `marux login:` → self-hosting 증명(§11). 이후 HDMI(VC4=y) → 그래픽 데스크톱(v7.1) → x86 패리티(v8) → **out-of-box 한글(v10)** → GTK3/Firefox 한국어(v11) → 유선 네트워크(v12) → **Plank dock+picom 유리 데스크톱(v14~v16, 현재 이미지 — §10.5)**. (옛 kernel-vs-FAT 격리 테스트는 전제 오류로 불요가 됨.)
