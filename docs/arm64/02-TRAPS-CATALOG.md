# MaruxOS ARM64 — 함정 완전 카탈로그 (Raspberry Pi 4B 포팅)

> **범위: 2.0.0 "Cooked" ARM64 트랙에서 실제로 만나 적발/복구한 함정 전부.** 커널 defconfig부터 실기기 부팅까지.
>
> ARM64 트랙은 새 카운트로 시작한다 — 1.x → 2.0.0 cooked-v8까지의 14종은 `Kernel-Update-Log.md`에 박제되어 있고, 여기서는 다루지 않는다.
>
> **빌드 함정 5종(#1~#5) + 부팅 함정 2종(A/B, 둘 다 해결) + 브링업/한글 함정 13종(#6~#18, 2026-07-08~23 추가) + 데스크톱 완성기 함정 6종(#19~#24, 2026-07-25~29 추가) + 업스트림 릴리즈 버그 1종(#25, 2026-08-14 추가) + WiFi·GUI·Qt 크로스 함정 11종(#26~#36, 2026-08-14~26 추가).** 각 함정마다: 증상 / 근본원인 / 해소 / 어떻게 잡았나(검증방법) / 발표가치.
>
> **⚠️ 갱신(2026-07-23)**: 이 카탈로그는 원래 2026-07-05에서 멈춰 있었다(부팅-B "미해결"). 그 뒤 부팅이 해결(2026-07-08)되고 그래픽 데스크톱·한글 입력까지 완성되며 **13종의 새 함정**이 나왔다. 아래 "부팅 이후 — 브링업/데스크톱/한글 함정 (#6~#18)" 절에 추가했다.
> **⚠️ 갱신(2026-07-30)**: v10 이후 GTK3/Firefox(v11) → 유선 네트워크(v12) → Plank 소스빌드(v14) → picom+유리 테마(v15) → 라이브픽스(v16)로 가며 **함정 6종(#19~#24)**이 추가로 나왔다. 아래 "데스크톱 완성기 함정 (#19~#24)" 절에 추가했다.
> **⚠️ 갱신(2026-08-14)**: v16 실기기 검증에서 #24의 "보너스 근원 규명(SN 미포함 wnck)"이 **오진으로 판명** — bamfdaemon 세그폴트의 실근원 = **libwnck 43.0 업스트림 버그(#25)**. 43.2 버전업으로 해소(v17 탑재 예정).

---

## 문서 규약 (환각 방지)

이 프로젝트는 환각을 극도로 경계한다 — 1.x의 **"6.12 LTS 광고 → 실제 vmlinuz 6.7.4" 5개월 생존 전과** 때문이다(맨 끝 절 참조). 본 문서는 다음 규칙을 지킨다.

- **원문에 실제로 있는 값만 기록.** 버전·명령·크기·SHA·경로·결과는 소스 원문 그대로(verbatim).
- **소스에 명령이 없고 요약에서 재구성한 것은 `(재구성)` 표기.** 소스에 기록되지 않은 것은 `미기록`이라 명시.
- **정확한 값(SHA·크기·경로·버전)은 verbatim.** 리포지토리 디스크에서 직접 확인한 값은 `(실측)` 병기.
- 한국어, 기술적·정밀. **본 문서는 새 파일이며 기존 로그를 대체하지 않는다.**

**1차 소스**: [`ARM64-Update-Log.md`](../../ARM64-Update-Log.md) — 특히 "함정 카탈로그" 절(함정 #1~#5), "환경 준비" 절, "함정 #3/#4/#5" 상세 절, "Stage 2 완료" 절, "2026-07-02 Stage 4b 실기기 부팅 디버깅" 절, "🚨 다음 세션 핸드오프 (2026-07-05)" 절.
**보조 소스**: [`Kernel-Update-Log.md`](../../Kernel-Update-Log.md)(1.x 6.7.4 환각 §2, ARM64 boot 디버깅 항목은 없음), [`CLAUDE.md`](../../CLAUDE.md), [`config-arm64/`](../../config-arm64)(config.txt·cmdline.txt·firmware/·isolation-test/), [`config/lfs-versions.conf`](../../config/lfs-versions.conf), git log.
**형제 문서**: [`01-BOOT-DEBUGGING.md`](01-BOOT-DEBUGGING.md)(부팅 디버깅 전체 서사), [`03-ASSET-REFERENCE.md`](03-ASSET-REFERENCE.md)(자산·경로·SHA), [`04-TALK-NARRATIVE.md`](04-TALK-NARRATIVE.md)(발표 서사).

---

## 요약 표

| # | 함정 | 계열 | 상태 | 발견일 |
|---|------|------|------|--------|
| **#1** | mainline에 `bcm2711_defconfig` 없음 (RPi 포크 전용) | 환각 / 커널 config | 해소 | 2026-06-19 |
| **#2** | `update-binfmts` 부재 → binfmt 수동등록, `wsl --shutdown`/슬립 시 소실 | 환경 / 휘발성 | 해소(재확인 절차화) | 2026-06-20 |
| **#3** | 툴체인 버전 staging ≠ shipped (소스 dir glibc 2.39 미끼, 설치 `libc.so.6`=2.38이 진실) | 환각 / provenance | 해소 | 2026-06-20 |
| **#4** | aarch64 gcc가 lp64를 `/lib64`로 (`t-aarch64-linux` `MULTILIB_OSDIRNAMES` sed 누락) | 크로스 툴체인 / LFS 책 x86_64 가정 | 해소 | 2026-06-20 |
| **#5** | WSL 슬립이 binfmt를 죽여 gcc final install 중단 → pass2 gcc 외과복원 | 인프라 / 장기빌드 연쇄장애 | 해소(22패키지 손실 0) | 2026-06-21 |
| 부팅-A | `config.txt` 비ASCII(한글 주석 mojibake)가 Pi 부트로더 파서 죽임 | 부팅 / silent mutation | 해소(순수 ASCII 교체) | 2026-07-02 |
| 부팅-B | 초록 LED **짧2** — "펌웨어가 우리 이미지 부트 못 읽음"으로 오진 | 부팅 / **관측 불능** | **✅ 해결(2026-07-08)** — 실제 원인 = 죽은 시리얼 어댑터 + `console=ttyS0` 순서(펌웨어/FAT/커널 무죄) | 2026-07-02~08 |
| **#6~#18** | 부팅 이후 브링업/데스크톱/한글 함정 13종 (시리얼 어댑터·CR/LF·HDMI·gdk-pixbuf·GTK2 XIM·ibus 8겹·libexec·gschema·machine-id·한영토글·더블데몬·startx·wsl-root) | 브링업 / X11 / 한글입력 | 전부 해소 | 2026-07-08~23 |
| **#19~#24** | 데스크톱 완성기 함정 6종 (ibus gtk3 `--disable-ui`·libwnck URL 메이저 디렉토리·vala↔g-i girdir·bamf python3-lxml·GSettings memory 백엔드·openbox Client 컨텍스트) | 빌드 / GSettings / X11 | 전부 해소 | 2026-07-25~29 |
| **#25** | libwnck 43.0 업스트림 버그 — `invalidate_icons` screens NULL 가드 부재 → bamfdaemon 세그폴트 (#24 "SN 부재" 결론은 오진) | 업스트림 릴리즈 버그 | 해소(43.2 버전업 — v17 탑재 예정, v16 이미지엔 미포함) | 2026-08-14 |
| **#35** | Ubuntu 크로스 gcc 암묵 `_FORTIFY_SOURCE=3` → Qt `qt_readlink` 오탐 abort(QTerminal 즉사) → 전 Qt 스택 =2 재빌드 + **기동 게이트** 신설 | 호스트 컴파일러 정책 / 크로스 7번째 층 | 해소(v28) | 2026-08-26 |
| **#36** | Qt 재빌드 `make install`이 config 배포 `.desktop`을 업스트림(테마 이름 Icon)으로 덮어씀 → 독 아이콘 투명 → config 재적용 + **바이트 일치 게이트** | config→rootfs 역방향 오염 / "존재≠내용" | 해소(v29) | 2026-08-26 |

> 계열 통찰: **#1·#4는 같은 뿌리** — "LFS 책과 커널 defconfig는 암묵적으로 x86_64 문서다. aarch64 포팅은 그 x86_64 가정(defconfig·lib64 sed·dts)을 한 줄씩 들어내는 작업." **#2·#5는 같은 뿌리** — binfmt_misc가 `/proc` 런타임 상태라 WSL 재시작/슬립에 휘발한다. **부팅-B의 교훈** — 부팅 실패로 보이던 것의 진짜 정체는 *관측 불능*(죽은 시리얼 어댑터)이었다. "안 보이는 것 ≠ 안 되는 것." **#6~#18의 계열** — (a) 하드웨어 관측(#6·#7), (b) qemu-user 에뮬레이션 한계(#8·#9·#10), (c) from-scratch rootfs가 배포판이 조용히 해주던 초기화를 안 함(gschema·machine-id·xinit sysconfdir), (d) x86 컨벤션이 ARM64 memconf 백엔드에서 안 통함(한영토글).

---

## 함정 #1 — mainline에 `bcm2711_defconfig`는 없다 (RPi 포크 전용) — 2026-06-19

### 증상
```
$ make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- bcm2711_defconfig
*** Can't find default configuration "arch/arm64/configs/bcm2711_defconfig"!
```
→ `.config` 생성 실패, 커널 빌드 진입 불가.

### 근본원인
`bcm2711_defconfig`(및 `bcmrpi3_defconfig` 등)는 **raspberrypi/linux 다운스트림 포크** 전용 config다. **mainline** `arch/arm64/configs/`에는 `defconfig`, `hardening.config`, `virt.config` **셋뿐**. mainline은 통합 `defconfig` 하나로 Pi4 포함 전 arm64 SoC를 커버하고(`CONFIG_ARCH_BCM2835=y`가 BCM2835~2711 패밀리 전체를 포함), Pi4 지원은 `arch/arm64/boot/dts/broadcom/bcm2711-rpi-4-b.dts`(DTS)로 제공한다.

**환각의 근원**: 이전 세션(x86_64 6.18.26 작업)의 정찰 노트(`Kernel-Update-Log.md §1`)가 "6.18 mainline `bcm2711_defconfig`로 Pi4 부팅 작동"이라고 **미검증 단정**했다. RPi 포크 워크플로 지식이 mainline에 잘못 전이된 전형적 환각 — **Pi 빌드 0회 시점의 "작동" 주장**.

### 해소
베이스를 통합 `make defconfig`(통합 arm64)로 변경 + Pi4 부팅/데스크톱 critical 드라이버 builtin 강제. 실제 강제 결과(`scripts/config` + `make olddefconfig` 후, 원문 표):

| 옵션 | 결과 | 이유 |
|------|------|------|
| `PCIE_BRCMSTB` | `m` → **`y`** 강제 | Pi4 USB 컨트롤러가 PCIe 뒤 — USB 부팅 필수 |
| `BCMGENET` | **`y`** | Pi4 기가비트 이더넷 |
| `DRM` | **`y`** | DRM 코어 builtin |
| `DRM_VC4` | `m` (강제 실패, 의존성으로 모듈 유지) | udev 자동로드, 최악도 펌웨어 simplefb로 X 뜸 |
| `OVERLAY_FS` | **`y`** | Phase2 Live overlay |
| `SQUASHFS_ZSTD` / `SQUASHFS_XZ` | **`y`** | Phase2 Live squashfs 압축 |
| `NLS_UTF8` | **`y`** | vfat UTF-8(한글 파일명) |
| `LOCALVERSION` | `"-maruxos"`, `LOCALVERSION_AUTO=n` | 브랜딩 |

빌드 결과 게이트(전부 통과): `arch/arm64/boot/Image` = **50,022,912 B**(~47.7 MB, 비압축 arm64 Image = Pi `kernel8.img`), `bcm2711-rpi-4-b.dtb` = **39,650 B**, baked `kernel.release` = **`6.18.26-maruxos`**.

> 아키텍처 통찰(원문): x86_64는 minimal busybox initrd(`/lib/modules` 없음)라 전부 builtin 강제였지만, **Pi는 진짜 ext4 root에 `/lib/modules` 적재 가능** → 부팅 critical(스토리지+root fs)만 builtin이면 되고 나머지는 모듈 + `make modules_install`로 가능. **CLAUDE.md의 "필수 드라이버 builtin" 규칙은 x86_64 minimal-initrd 전용이며 Pi 트랙엔 그대로 적용되지 않는다.**

### 어떻게 잡았나 (검증방법)
가정을 믿지 않고 **mainline 소스를 실제로 받아** `ls arch/arm64/configs/` + `make defconfig`를 직접 실행 → 즉시 적발. *"AI 요약 박지 말고 raw로 확인"* 원칙의 직접 승리다. (소스 provenance도 동시 검증: `linux-6.18.26.tar.xz` 154,432,584 B의 `sha256sum` = `53772f5d3776e043767c8d81a32240d1f3eb64e822a5d7a510b55ca40707b0ec` == `lfs-versions.conf`의 `KERNEL_SHA256`와 완전 일치 → 6.18.26이 실재 kernel.org 릴리즈임을 raw byte로 재검증.)

### 발표가치 ⭐
**"다른 세션의 AI가 박은 미검증 가정을, 같은 AI가 raw 검증으로 잡았다."** Hallucination Hunter 프레임 표본 — ARM64 트랙 1호. 함정 #4와 한 계열("LFS/defconfig의 x86_64 암묵 가정 들어내기").

---

## 함정 #2 (경미) — `update-binfmts` 부재, binfmt는 휘발한다 — 2026-06-20

### 증상
`qemu-user-static` 설치는 됐으나 qemu-aarch64 binfmt가 **자동 등록되지 않음**. → aarch64 정적 ELF를 호스트에서 직접 실행 불가 = qemu-chroot 진입 불가.

### 근본원인
이 **Ubuntu 24.04**에 `binfmt-support` 패키지가 미설치라 `update-binfmts`가 없고, qemu-user-static이 binfmt 자동등록을 못 한다. systemd-binfmt도 WSL에서 자동 등록되지 않는다.

### 해소
`/proc/sys/fs/binfmt_misc/register`에 **수동 등록**(원문 verbatim, `<magic>`/`<mask>`는 원문의 플레이스홀더 — 실제 매직바이트는 미기록):
```
echo ':qemu-aarch64:M::<magic>:<mask>:/usr/bin/qemu-aarch64-static:F' > /proc/sys/fs/binfmt_misc/register
```
`F`플래그(**fix_binary, chroot 안전**) 명시가 핵심 — 인터프리터를 chroot 진입 전에 오픈해 고정하므로 chroot 안에서 경로가 달라도 동작한다. 등록 후 실측: `enabled`, interpreter `/usr/bin/qemu-aarch64-static`, `flags: F`.

**⚠️ 휘발성(함정의 본질)**: binfmt 등록은 런타임 상태(`/proc`)라 **`wsl --shutdown` 시 소실**된다. → RAM 조정용 `wsl --shutdown`은 커널 산출물 확정 후 1회로 끝내고(추가 shutdown 금지), **모든 chroot 진입 전 등록 여부 재확인**을 표준 절차로 삼음. 영구화하려면 `binfmt-support` 설치 또는 등록 스크립트화(미채택).

### 어떻게 잡았나 (검증방법)
qemu-chroot end-to-end 실증 중 발견. 등록 후 **x86_64 호스트가 정적 aarch64 ELF를 직접 실행 → `aarch64 binfmt+qemu OK 42` rc=0**으로 검증. 이후 Ch7.4에서 `uname -m`(qemu) = `aarch64`, 크로스빌드 `bash 5.2.21 (aarch64-lfs-linux-gnu)`, `gcc 13.2.0`이 qemu로 실행됨을 재확인.

### 발표가치
경미하지만 **함정 #5의 씨앗**. "에뮬레이션 빌드의 상태는 `/proc`에 산다 — 호스트를 재시작하면 증발한다." 이 한 줄이 뒤에서 gcc 컴파일러를 통째로 무너뜨린다(함정 #5).

---

## 함정 #3 — 툴체인 버전 staging ≠ shipped (설치된 `libc.so.6`=2.38이 진실) — 2026-06-20

### 증상
풀 LFS북 결정 후 x86_64 빌드의 LFS 소스 dir(186 타르볼, 720M) 재활용 가능성 조사 중, **버전 불일치 적발**. 소스 dir에는 binutils **2.42** / glibc **2.39**가 있는데, 실제 쉬핑 OS가 그 버전으로 만들어졌는지 불명.

### 근본원인
소스 dir의 2.39/2.42는 **빌드 안 된 미끼(staging)** — glibc 업그레이드 별도 트랙용으로 받아둔 것일 뿐, 쉬핑 OS에 반영된 적이 없다. 3중 불일치 표(원문 verbatim):

| 출처 | binutils | glibc | 신뢰도 |
|------|----------|-------|--------|
| x86_64 **소스 dir**(다운로드됨) | 2.42 | 2.39 | ⚠️ staging (빌드 안 됨) |
| x86_64 **rootfs 설치된 `libc.so.6`** | (2.41) | **2.38** | ✅ ground truth |
| `config/lfs-versions.conf` (SSOT) | 2.41 | 2.38 | ✅ 일치 |
| ARM64 core 다운로드 | 2.41 | 2.38 | ✅ 일치 |

**결정적 증거**: 설치된 `libc.so.6` → `GNU C Library ... release version 2.38`. 설치된 `gcc --version` → `13.2.0`. os-release → `MaruxOS 2.0.0 "Cooked"`, `ID_LIKE=lfs`. → **실제 쉬핑 = glibc 2.38 / gcc 13.2.0 / binutils 2.41**.

### 해소
`lfs-versions.conf` 버전대로 arm64는 **신규 수집**(소스 dir 무분별 재활용 금지 — staging 버전 혼입 위험). Stage 2a에서 확보한 core 6종 SHA256 매니페스트(Stage 2b 게이트 expected, upstream GNU 공식과 교차검증 일치, verbatim):

| 패키지 | 크기 | SHA256 |
|--------|------|--------|
| binutils-2.41.tar.xz | 26M | `ae9a5789e23459e59606e6714723f2d3ffc31c03174191ef0d015bdf06007450` |
| gcc-13.2.0.tar.xz | 84M | `e275e76442a6067341a27f04c5c6b83d8613144004c0413528863dc6b5c743da` |
| gmp-6.3.0.tar.xz | 2.0M | `a3c2b80201b89e68616f4ad30bc66aee4927c3ce50e33929ca819d5c43538898` |
| mpfr-4.2.1.tar.xz | 1.5M | `277807353a6726978996945af13e52829e3abd7a9a5b7fb2793894e18f1fcbb2` |
| mpc-1.3.1.tar.gz | 756K | `ab642492f5cf882b74aa0cb730cd410a81edcdbec895183ce930e706c1c759b8` |
| glibc-2.38.tar.xz | 19M | `fb82998998b2b29965467bc1b69d152e9c307d2cf301c9eafb4555b770ef3fd2` |

> 부수 관찰(원문): CLAUDE.md는 "LFS 12.1 기반"이라 표기하나 실제 툴체인 glibc 2.38/binutils 2.41 = **LFS 12.0-era**. `marux-release.conf`에 `INSTALLER="calamares"`, `BOOTLOADER="GRUB2"`(x86_64) 등 미실현/x86_64-전용 라벨 잔재. 라벨 정합성은 후속 정리 대상(본 빌드는 안 막음).

### 어떻게 잡았나 (검증방법)
**가장 하류의 실물에서 검증.** 다운로드된 것 ≠ 빌드된 것 ≠ 메타데이터가 주장하는 것 — 3중 불일치에서 ground truth는 **산출물(installed `libc.so.6`)뿐**. 설치된 라이브러리의 release 문자열을 직접 읽어 확정.

### 발표가치
**Dementia Doctor** 표본: *"OS의 소스 staging(2.39)이 거짓 단서, 설치된 바이너리(2.38)가 진실."* 검증은 항상 가장 하류의 실물에서. (함정 #1의 defconfig 환각과 정반대 방향 — 이쪽은 "무엇이 진실인지" 판별.)

---

## 함정 #4 — aarch64 gcc는 lp64를 `/lib64`로 보낸다 — 2026-06-20

### 증상
Ch5.6 libstdc++가 `$LFS/usr/lib`가 아닌 **`$LFS/usr/lib64`**에 설치됨. glibc는 `/usr/lib`(내가 `libc_cv_slibdir=/usr/lib` 강제)에 있으므로 → **gcc와 glibc의 lib 경로 분열**.

### 근본원인
`gcc/config/aarch64/t-aarch64-linux:25`:
```
MULTILIB_OSDIRNAMES = mabi.lp64=../lib64$(call if_multiarch,...)
```
aarch64 gcc는 lp64 ABI 라이브러리의 osdir 기본이 `../lib64`다. `gcc -print-multi-os-directory` → `../lib64`. (x86_64는 `gcc/config/i386/t-linux64`의 `m64=../lib64`가 동일 역할 — LFS 책이 sed로 고치는 바로 그 부분의 aarch64판.)

**근원**: x86_64 LFS 책의 `t-linux64` lib64 sed를 그대로 aarch64에 옮기지 않은 **누락**. LFS 책이 x86_64 전용이라, arch 포팅 시 osdir 교정이 빠지는 전형적 함정.

### 해소
gcc 빌드 **전** sed로 osdir 교정 후 gcc pass1 재빌드 + libstdc++ 재빌드(원문 verbatim):
```
sed -e '/mabi.lp64=/s/lib64/lib/' -i.orig gcc/config/aarch64/t-aarch64-linux
```
glibc는 위치(`/usr/lib`)가 정상이라 재빌드 불요(새 gcc가 `/lib`에서 링크 — sanity 재확인). **이 sed는 Ch6 gcc pass2 + Ch8 gcc final에도 매번 적용 필수.** 소스 트리에 적용되므로 이후 pass가 자동 상속. 결과(Ch5 완료 게이트): libstdc++ `/usr/lib` ✓, **lib64 잔재 0(순수 lib)** ✓.

### 어떻게 잡았나 (검증방법)
설치 경로를 직접 확인 → `$LFS/usr/lib64` 산출물 발견. `gcc -print-multi-os-directory`로 osdir 기본값 확인 후 `t-aarch64-linux:25`에서 `MULTILIB_OSDIRNAMES` 지정 라인을 소스에서 직접 확인해 근원 못박음.

### 발표가치
**"LFS 책은 x86_64 문서 — aarch64 포팅은 책의 암묵적 x86_64 가정(lib64 sed, dts, defconfig)을 하나씩 들어내는 작업."** 함정 #1(defconfig)과 같은 계열의 클린업.

---

## 함정 #5 — WSL 슬립이 binfmt를 죽여 gcc final install을 중단시킨다 → pass2 gcc 외과복원 — 2026-06-21

이 프로젝트 ARM64 트랙의 **연쇄장애 클라이맥스**. 함정 #2의 휘발성이 장기빌드에서 폭발한 사례.

### 증상
gcc final이 make 완주(**13:29**) + install 시작(**13:31**) 후, **~4시간 갭**(머신 슬립 추정) 동안 binfmt(`/proc/sys/fs/binfmt_misc/qemu-aarch64`)와 bind 마운트가 소실. install이 중간에 잘림 → `cc1`/`cc1plus` 미설치 → `gcc: cannot execute 'cc1'`. 빌드 스크립트 rc=2 종료, `.done/gcc-final` 마커 미생성.

### 근본원인
binfmt_misc 등록은 런타임(`/proc`) 상태 → WSL2 재시작/슬립 시 소실(함정 #2의 연장). 장시간 qemu-chroot 빌드 도중 머신이 슬립하면 chroot 내 aarch64 바이너리 실행이 중단됨. **근원 = 노트북 자동 슬립**(AC에서도 유휴 슬립 / lid-close).

### 연쇄장애 (발표용 핵심 서사)
슬립으로 install이 중단된 뒤 드러난 3단 연쇄:
1. **깨진 `/usr/bin/gcc`**: 중단된 final install이 pass2 gcc를 덮어씀(드라이버는 새 triplet `aarch64-unknown-linux-gnu`로 설치됐으나 cc1/cc1plus 미설치) → `cannot execute 'cc1'`.
2. **클린 재빌드도 실패(exit 77)**: gcc final의 configure가 conftest 컴파일에 깨진 `/usr/bin/gcc`를 사용 → "C compiler cannot create executables".
3. **부트스트랩 컴파일러 부재 확인**: `/tools/bin/aarch64-lfs-linux-gnu-gcc`는 **x86_64 크로스 바이너리**(Ch5 pass1, `--host` 미지정 → 호스트 바이너리)라 aarch64 chroot에서 실행 불가. → chroot 내 유일한 네이티브 gcc는 pass2(/usr)였는데 그게 깨짐.

### 해소 — 외과적 pass2 gcc 복원 (전체 롤백 회피)
- Ch7 백업(`lfs-ch7-snapshot.tar`)에서 **gcc 드라이버 17개 + `/usr/libexec/gcc` + `/usr/lib/gcc`만** 추출 복원. glibc final·binutils final·기타 **22패키지는 보존**.
- 검증: gcc `aarch64-lfs-linux-gnu`, C 컴파일 rc=42 ✓, C++ ✓, glibc final(**11.9MB**) 보존 ✓, binutils ld 2.41 보존 ✓.
- → 작동 부트스트랩 확보 → gcc final 클린 재빌드 configure 통과 → make 진행 → 최종 완료.

**완화 조치(가역, 사용자 검토 큐)**: `powercfg /change standby-timeout-ac 0` + `hibernate-timeout-ac 0`(AC 자동 슬립/최대절전 끔), 이후 lid-close 슬립까지 `powercfg SUB_BUTTONS LIDACTION 0`. **복구 명령**: `standby-timeout-ac 30`, `LIDACTION 1`.
**표준 절차화**: 모든 청크 스크립트가 시작 시 binfmt/마운트 재확립 + 패키지별 `.done` 마커 → 중단돼도 자가 복구. heavy 단일 패키지(gcc류)만 install-resume 트릭 필요.

### 어떻게 잡았나 (검증방법)
`.done/gcc-final` 마커 미생성 + `gcc: cannot execute 'cc1'` 런타임 에러로 감지. 이후 `exit 77`, `/tools/bin/...-gcc`가 호스트(x86_64) 바이너리임을 `file`/실행 실패로 각각 확인해 연쇄를 역추적. 복구 후 C/C++ 컴파일 rc를 실제로 돌려(42) 부트스트랩 정상 확인.

### 발표가치 ⭐⭐
**"에뮬레이션 빌드의 현실 — 호스트 OS의 전원 관리가 게스트 빌드를 끊는다."** 호스트 슬립 1번이 컴파일러를 깨뜨리고 부트스트랩까지 무너뜨렸으나, **백업 + 가역성 + 외과적 복원으로 22패키지 손실 0으로 복구**. *resumability · idempotency · snapshot이 장시간 빌드의 생존 3종 세트.* 함정 #2·#5를 한 묶음의 클라이맥스로 발표(인프라 회복력).

---

## 부팅 함정 A — `config.txt` 비ASCII가 Pi 부트로더 파서를 죽인다 — 2026-07-02

> 전체 서사는 [`01-BOOT-DEBUGGING.md`](01-BOOT-DEBUGGING.md) 참조. 여기서는 함정 요약.

### 증상
Stage 4b 실기기 부팅 시 무지개 0.1초 → 블랙 + 초록 LED 에러 깜빡 + 시리얼 무출력. SD 내용/파티션은 PC에서 검증상 완벽한데도 Pi가 부팅 파일을 못 읽는 정황.

### 근본원인
v1 `config.txt`에 **한글 주석**이 들어가 있었고, 이것이 **mojibake**로 저장됨. Pi GPU 부트로더의 `config.txt` 파서는 원시(raw)라 비ASCII/mojibake에 취약 — Windows·리눅스 텍스트 도구는 관대해서 안 드러남.

### 해소
`config.txt`를 **순수 ASCII로 교체**(BOM 없음 확인) + `hdmi_safe` 제거. 현재 `config-arm64/config.txt`(실측, 순수 ASCII):
```
arm_64bit=1
kernel=kernel8.img
enable_uart=1
dtoverlay=disable-bt
disable_overscan=1
```
(부수: 시리얼을 mini-UART `ttyS0`에서 PL011 `ttyAMA0`로 옮기려 `dtoverlay=disable-bt` 추가. cmdline은 양쪽 console 헤지 — `config-arm64/cmdline.txt` 실측: `console=ttyAMA0,115200 console=ttyS0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 rootwait fsck.repair=yes net.ifnames=0`.)

### 어떻게 잡았나 (검증방법)
① PowerShell로 SD의 F:(부트 파티션) **6파일 크기 + FAT32** 실증 → "잘못 구운 것" 아님 확정. ② `config.txt` 내용을 직접 열어 **한글 주석 mojibake 발견** + BOM 없음 확인. ③ **결정적 격리**: 공식 **Raspberry Pi OS를 같은 SD에 구워 부팅 → 정상** → SD·리더·Pi·EEPROM 전부 정상, 우리 이미지가 범인으로 확정.

### 발표가치
**"비ASCII 한 글자가 Pi 부트로더를 죽인다."** 하드웨어 브링업의 silent mutation — 함정 #3(파일시스템 케이스 변환류)의 부팅 버전. 표면(PC에서 파일 멀쩡)만 봐선 안 잡히고, **실기기 + 원시 파서**에서만 드러남.

---

## 부팅 함정 B — 초록 LED "짧2": (오진) 펌웨어가 부트 못 읽음 → ✅ RESOLVED (2026-07-08)

> ### ✅ RESOLVED (2026-07-08): 부팅은 실패한 적이 없었다 — 관측이 불능이었다.
> **"짧2 = 펌웨어가 부트 파티션/파일을 못 찾음"은 오진이었다.** 실제 원인 3종:
> 1. **죽어가던 FT232RL 시리얼 어댑터** → v1~v4 디버깅 전부 "장님 디버깅"(LED만 보고 추측). 새 FT232RL + **흰↔초록 배선 스왑**(핀8=초록=어댑터TX, 핀10=흰=어댑터RX) + `enable_uart=1`로 시리얼 부활.
> 2. **`console=ttyS0,115200`를 cmdline 맨 뒤로** → `/dev/console`=시리얼. 유저스페이스는 안 보이는 tty1 더미 콘솔로 새고 있었다.
> 3. **경미한 rootfs 설정 4종**(udevadm 심링크/fstab shm·cgroup/S70console/S10sysklogd) → rc마다 "Press Enter" 정지 → v6 픽스 → **무인 클린부팅(FAIL 0) → `marux login:`** + gcc self-hosting 증명.
>
> **아래 근본원인 2가설(A FAT / B 50MB 커널)은 둘 다 반증됐다** — 펌웨어는 우리 부트 파티션을 완벽히 읽고 50MB 커널로 핸드오프했으며 커널은 완전 부팅했다(4-CPU SMP·PCIe·USB·eth0·ext4·`/sbin/init`). 격리 테스트는 전제 오류로 실행 전 무의미해졌다. 아래 "확정된 사실"은 그 자체로는 다 옳았으나(하드웨어 무죄·부트 파일 무결·펌웨어 무죄), **놓친 변수가 "관측 계측기(시리얼)의 사망"이었다.**
>
> **원문(2026-07-05 "미해결" 스냅샷)은 방법론 보존용으로 아래 유지.** 전체 서사 = [`01-BOOT-DEBUGGING.md`](01-BOOT-DEBUGGING.md).

---

> **⚠️ 미해결(2026-07-05 당시).** 격리 테스트 직전 단계에서 세션 핸드오프.

### 증상
초록 LED **짧은 깜빡 2번 반복(짧2)**, 무지개 0.1초 → 블랙, 시리얼 무출력.
**⚠️ 원문 표기 불일치(정직 기록)**: 2026-07-02 로그는 이 깜빡임을 **"긴2 깜빡"**(= 파티션 읽기 실패)으로, 2026-07-05 핸드오프는 **"짧2"**로 기록. 동일 현상의 표기가 두 날짜에서 다름 — 실기기 재관찰로 확정 필요(미확정). 공통 해석: **펌웨어가 부트 파티션/파일을 못 찾음**(start4.elf는 로드됨 = 무지개 0.1초, 그 다음 kernel8/config 읽기 실패로 추정).

### 근본원인 (당시 2가설 — ❌ 둘 다 반증됨 2026-07-08)
- **(A) FAT 파티션 구조**: `mkfs.vfat`가 만든 FAT를 Pi 원시 파서가 못 읽음(Windows는 관대). RPi OS의 FAT는 됨. — ❌ **반증**: 펌웨어가 우리 FAT를 완벽히 읽었다.
- **(B) 50MB 커널**: 통합 defconfig(전 SoC builtin)의 우리 `kernel8.img`(50,022,912 B)가 로드 실패. RPi 포크 커널은 ~10MB. 크기/로드주소 문제 가능성. — ❌ **반증**: 50MB 커널은 정상 로드·완전 부팅됐다.
- **✅ 실제 근본원인**: 죽은 시리얼 어댑터(관측 불능) + cmdline `console=ttyS0` 순서(콘솔 라우팅) + 경미 rootfs 설정 4종. 상단 RESOLVED 배너 참조.

### 해소 (✅ 2026-07-08)
- ~~격리 테스트로 커널 vs FAT 못박기~~ — ⏭️ 전제 오류(범인=이미지)로 **실행 전 무의미해짐**. (자산은 남아 있음: `config-arm64/isolation-test/kernel8.img` **50,022,912 B**, `bcm2711-rpi-4-b.dtb` **39,650 B**.)
- **실제 해소**: ① 새 FT232RL + 흰↔초 배선 스왑으로 시리얼 부활 → RPi OS `raspberrypi login:` 30,378바이트 캡처로 파이프라인 검증. ② cmdline `console=ttyS0,115200`를 맨 뒤로 → init/rc가 시리얼에 드러남. ③ rootfs 4종 픽스(udevadm 심링크/fstab shm·cgroup/S70console/S10sysklogd) → v6 무인 클린부팅.
- HDMI 블랙아웃(별개): 최소 config 디스플레이 드라이버 부재 → 커널 **VC4/V3D `=y`** + config.txt `max_framebuffers=2`(mainline dtb라 dtoverlay 불요) → 실물 1080p 콘솔(Stage 5a). → #8 참조.

### 어떻게 잡았나 (검증방법) — 여기까지 확정된 사실 (재검증, 추측 아님)
1. **RPi OS Lite가 같은 SD/Pi에서 정상 부팅** → SD·리더·Pi·EEPROM 정상, **범인은 우리 이미지**.
2. **부트 파일 PC 검증 완벽**: start4.elf / fixup4.dat / kernel8.img(**50022912**) / bcm2711-rpi-4-b.dtb(**39650**) / config.txt / cmdline.txt 정확한 크기, FAT32 읽힘.
3. **파티션 레이아웃 정상**: p1 512MB FAT32(부트) + p2 6.5GB ext4(root). (Windows가 ext4 못 읽어 ~510MB만 보이는 건 정상.)
4. **커널/dtb 산출물 유효**: kernel8.img = 정상 arm64 Image(magic `ARMd@`, offset 56, "Linux kernel ARM64 boot executable"), dtb = 정상 FDT(magic `d00dfeed`). **파일 안 깨짐.**
5. **펌웨어는 범인 아님**: v1(master 펌웨어 start4.elf **2306400**) → 짧2. v2(RPi OS 검증 펌웨어 start4.elf **2305632**) → **똑같이 짧2**. 펌웨어 교체로 안 고쳐짐. (현재 `config-arm64/firmware/start4.elf` 실측 = **2305632** = v2 검증 펌웨어.)
6. **LED 짧2 의미**(공식 표 + 사용자 확인, WebSearch로 확인 — 기억으로 안 박음): 펌웨어가 부트 파티션/파일을 못 찾음.

**이미지 자산(핸드오프, verbatim)**: v2 `output/MaruxOS-2.0.0-arm64.img.xz`(1.02GB, SHA `eab7dc2bf9553ee1d5f9931e1856c67c5b18acc6cdf697db6e2b35cf40d15131`), v1 SHA `605ec90af39ccd262ecd8a9f66b1b279482818c7acf2233078a7b5425173bd59`.

### 사용자 절대 원칙 (재확인 2026-07-02)
*"다른 OS 참고한답시고 이 프젝을 라파 그자체로 만들면 안 됨."* → **Broadcom 펌웨어(start4.elf = GPU 펌웨어 = BIOS급, OS 아님)·overlays·config 형식만 참조/사용. 커널(우리 mainline 6.18.26-maruxos)·rootfs(우리 from-scratch)·dtb(우리 mainline)는 100% 우리 것.**

### 발표가치 ⭐⭐ (해결 후 더 강해진 서사)
**"실기기 부팅은 소프트웨어 빌드와 다른 게임 — 그리고 '안 보이는 것'과 '안 되는 것'은 다르다."** 5일간 "부팅 실패"로 믿었던 것의 진짜 정체는 **죽은 시리얼 어댑터(관측 계측기의 사망)**였다. 커널·rootfs·펌웨어·FAT 전부 무죄였고, 유저스페이스는 처음부터 돌고 있었으나 안 보이는 tty1 더미 콘솔로 새고 있었다. 교훈: **진단은 계측기부터 의심하라. 대조 실험(RPi OS)으로 하드웨어를 무죄로 만들되, 관측 채널 자체가 죽었을 가능성을 배제하지 말 것.** LED 깜빡임 코드도 "짧2=부트 실패"라는 공식 표 해석이 실제로는 무관했다(정직 기록). 남의 부트 메커니즘은 배우되 정체성(커널·rootfs·dtb)은 사수 — 그 원칙 그대로 **v6 무인 클린부팅 → 실물 self-hosting → 그래픽 데스크톱 → 한글 입력**까지 완주. Hallucination Hunter의 하드웨어 버전이 **미해결 클리프행어에서 승리 서사로** 종결.

---

# 부팅 이후 — 브링업 / 데스크톱 / 한글 함정 (#6~#18) — 2026-07-08~23

> 부팅이 해결(2026-07-08)된 뒤 HDMI 콘솔 → X.org → 데스크톱(v7.1) → x86 패리티(v8) → ibus-hangul 한글 입력(v10)으로 나아가며 나온 함정 13종. 상세 서사는 [`ARM64-Update-Log.md`](../../ARM64-Update-Log.md)의 2026-07-08~23 섹션.

## 함정 #6 — 죽어가던 시리얼 어댑터 = 관측 불능 (5일 오진의 진범) — 2026-07-08

### 증상
v1~v4 내내 시리얼 무출력 또는 `▒▒` 깨진 글자. 부팅 실패로 오진해 FAT/커널 슬림화 등 엉뚱한 가설을 5일간 추격.

### 근본원인
FT232RL 어댑터가 **단선(사망)** 상태였다. 즉 계측기 자체가 죽어 있어 "부팅이 안 보이는 것"을 "부팅이 안 되는 것"으로 오독. 추가로 이 케이블은 **흰=TX/초=RX 라벨**이라 Pi TX(핀8)에 어댑터 RX(흰)를 물려야 하는데 **배선이 반대로** 꽂혀 있었다.

### 해소
새 FT232RL 교체 + **흰↔초 배선 스왑**(핀8=초록=어댑터TX, 핀10=흰=어댑터RX, 핀6=검정=GND, 빨강 VCC 미연결) + `enable_uart=1`. 결과: RPi OS가 `raspberrypi login:`까지 완전 부팅, **30,378바이트 캡처**로 시리얼 파이프라인 100% 검증.

### 어떻게 잡았나
새 어댑터를 먼저 **RPi OS로 검증**하며 배선을 확정 → 그제야 우리 이미지도 관측 가능. "대조 실험은 하드웨어를 무죄로 만들지만, *관측 채널 자체의 사망*은 그 실험도 못 잡는다"는 걸 뒤늦게 자각.

### 발표가치 ⭐⭐
**"5일 부팅 실패의 진범은 3.5달러짜리 죽은 USB-시리얼 어댑터였다."** 부팅-B와 한 묶음 — 진단은 계측기부터 의심하라.

---

## 함정 #7 — 시리얼 tty는 CR을 줄 제출로 안 받는다 (안전패턴 #9) — 2026-07-08

### 증상
시리얼로 명령을 보내면 에코는 되는데 실행이 안 됨(줄이 제출 안 됨).

### 근본원인
Pi tty가 `icrnl` **off** 상태 → 입력의 `\r`(CR)이 `\n`(LF)으로 변환되지 않음. CR만 보내면 커서만 돌고 라인이 canonical 버퍼에서 확정되지 않는다.

### 해소
**줄 제출은 `\n`(LF)로 보낸다**(CR 아님). 대용량 전송은 tty `MAX_CANON`(4KB) 한계도 함께 고려(→ #13의 base64 청크 전송에서 재등장).

### 발표가치
시리얼 콘솔 자동화의 미세 함정. "터미널이 먹었는데 왜 실행이 안 되나"의 정답.

---

## 함정 #8 — HDMI 블랙아웃 = VC4/V3D는 builtin(`=y`)이어야 한다 — 2026-07-08

### 증상
부팅은 되는데 HDMI 화면 블랙(`Console: colour dummy device 80x25`). "HDMI가 안 나온다 = 부팅 실패"로 오해하기 쉬움.

### 근본원인
최소 config에 디스플레이 드라이버가 없어 dummy console로 감. 커널 defconfig가 `CONFIG_DRM_VC4=m`/`V3D=m`(모듈)이라 minimal 부팅 경로에서 로드 안 됨.

### 해소
커널 **`CONFIG_DRM_VC4=y` + `CONFIG_DRM_V3D=y`** (의존성 SOUND/SND/SND_SOC/RASPBERRYPI_FIRMWARE/MBOX 포함) 재빌드 + config.txt **`max_framebuffers=2`**. → 실물 Pi 4B HDMI에 1080p 콘솔 텍스트(`vc4-drm gpu: bound fef00700.hdmi`, `Console: switching to colour frame buffer device 240x67`, `fb0: vc4drmfb`, `v3d 1.0.0 init`). ⚠️ **`dtoverlay=vc4-kms-v3d`는 안 씀** — mainline dtb가 hdmi/pixelvalve/gpu 전부 `status=okay`라 오버레이 불요(+mainline엔 .dtbo 없음, simpledrm도 없어 vc4 KMS만이 유일 경로).

### 어떻게 잡았나
시리얼 로그로 vc4 바인딩·프레임버퍼 전환을 실측 확인. 검증법: 부트파티션 kernel8.img+config.txt만 스왑(monolithic 커널이라 재플래시 불요).

### 발표가치
"블랙 화면 ≠ 부팅 실패." x86_64 minimal-initrd의 "builtin 강제" 규칙이 여기선 *디스플레이*에 적용된 사례.

---

## 함정 #9 — qemu-user 에뮬에서 gdk-pixbuf 로더 등록 실패 (gtk3 벽) — 2026-07-11

### 증상
한글(ibus→gtk3→gdk-pixbuf) 체인에서 **gtk3 빌드가 gdk-pixbuf 로더 등록 불가**로 막힘. 모듈·builtin·캐시 다 시도, XPM 포함 어떤 포맷도 로드 안 됨.

### 근본원인
qemu-user 에뮬레이션 특유의 gdk-pixbuf 로더 등록 실패(실기기 네이티브에선 정상 가능성 높음). gtk3 코어가 심볼릭 SVG 아이콘 컴파일에 gdk-pixbuf를 요구.

### 해소
→ **결정 A**: 데스크톱을 먼저 실기기 검증하고, gtk3/ibus는 뒤로 미룸. 이후 **#10**에서 "XIM은 gtk3가 아니라 GTK2만 필요"를 재규명해 qemu-chroot 빌드로 우회. (Firefox·GTK3 앱 입력은 여전히 배치 B-2 = gtk3 벽으로 잔존.)

### 발표가치
"에뮬레이션 빌드의 한계는 실기기 한계가 아니다." 에뮬 특유 장애를 실기기/우회로 분리한 판단.

---

## 함정 #10 — ibus XIM 서버는 GTK3가 아니라 GTK2를 요구한다 (핵심 재규명) — 2026-07-22

### 증상
"한글 입력 = gtk3 필요"라는 통념 때문에 #9의 gtk3 벽에 갇혀 있었음.

### 근본원인
ibus XIM 서버(`ibus-x11`)는 `client/x11/main.c`가 `#include <gtk/gtk.h>`, `configure.ac:320`에서 GTK를 요구하는데 **이건 GTK2로 충족된다**. XIM 경로엔 gtk3 불요. GTK2는 GTK3와 달리 코어 심볼릭 SVG 아이콘 이슈가 없다(비필수 데모/테스트만 gdk-pixbuf-csource로 걸림).

### 해소
GTK2 2.24.33 + ibus를 **qemu-chroot 네이티브 빌드**(Pi 네이티브 수시간 컴파일 회피). 데모/테스트만 SUBDIRS에서 제거하면 코어 `libgtk-x11-2.0`은 정상.

### 어떻게 잡았나
막연히 "gtk3 필요"로 두지 않고 ibus 소스의 `#include`/`configure.ac`를 직접 읽어 실제 의존을 확인.

### 발표가치 ⭐
"의존성은 통념이 아니라 소스에서 읽어라." 5d의 gtk3 벽을 우회하게 만든 결정적 재규명.

---

## 함정 #11 — ibus qemu 빌드 8겹 블로커 — 2026-07-22

### 증상
ibus(+ibus-hangul)를 qemu-chroot에서 빌드하려니 8개 블로커가 연쇄로 막음.

### 근본원인·해소 (`install-hangul-arm64-v2.sh` 박제)
1. **GTK2 데모** `gdk-pixbuf-csource` PNG 로드 실패(qemu) → `SRC_SUBDIRS`에서 demos/tests/perf 제거(코어는 정상).
2. **libnotify** 없음 → `--disable-libnotify`.
3. **python 바인딩**(pygobject 없음) → `--disable-python-library --disable-dbus-python-check`.
4. **iso-codes** 없음(언어명, 입력 불요) → `ISOCODES_CFLAGS/LIBS=" "` env 우회(PKG_CHECK_MODULES 스킵).
5. **automake rc=1**(git-archive) → `ChangeLog`(GNU strictness) + `gtk-doc.make`(gtkdocize 없음) 스텁 touch → Makefile.in 생성.
6. **valac 없음**(engine/simple.vala) → **git-archive 대신 릴리즈 dist 타르볼**(configure+미리생성 vala C 포함, 3.9M vs 1.5M) = autogen도 valac도 회피 ⭐.
7. **ibus-hangul 타르볼 깨짐**(압축해제 29B) → **GitHub 태그 아카이브 소스**로 교체.
8. **ibus-hangul이 `gtk+-3.0` 필수 + tests가 `gtk/gtk.h` 컴파일** → configure.ac에서 `PKG_CHECK_MODULES(GTK)` 제거 + Makefile.am에서 `tests` 제거(엔진 `src/`는 ibus+libhangul만 필요, setup은 .py라 컴파일 없음).

### 발표가치
"from-scratch에는 빌드 시스템이 당연히 있다고 가정하는 도구(valac/gtkdocize/iso-codes)가 없다." 릴리즈 dist 타르볼로 valac 자체를 회피한 #6이 백미.

---

## 함정 #12 — ibus 바이너리는 `/usr/libexec`에 설치된다 (LIBEXECDIR) — 2026-07-22

### 증상
빌드 게이트가 `/usr/lib/ibus/`를 검사해서 **오abort**.

### 근본원인
ibus는 `ibus-x11`·`ibus-engine-hangul`을 **`/usr/libexec/`**(LIBEXECDIR)에 설치한다(`/usr/lib/ibus/`가 아님).

### 해소
게이트 경로를 `/usr/libexec/{ibus-x11,ibus-engine-hangul}`로 수정. `/usr/bin/ibus-daemon`은 그대로 bin.

### 발표가치
"게이트의 expected 값 자체도 검증 대상." 잘못된 게이트가 정상 빌드를 거짓 abort시킨 사례.

---

## 함정 #13 — `--disable-dconf`가 ibus 코어 gschema를 통째로 스킵한다 (한글 입력의 진짜 벽) — 2026-07-23

### 증상
v9 플래시 후 한글 입력 안 됨. 엔진 수동 실행 시 `Trace/breakpoint trap` + `GLib-GIO-ERROR: Settings schema 'org.freedesktop.ibus.panel' is not installed` → 데몬의 `SetGlobalEngine: Timeout` → 한글 미활성.

### 근본원인
ibus 코어 gschema는 소스의 **`data/dconf/org.freedesktop.ibus.gschema.xml`**(16KB, `.panel`/`.general`/`.hotkey` 정의)인데, ibus 빌드 config 버그로 **`--disable-dconf`가 `data/dconf/` 설치를 통째로 스킵**한다. → 엔진이 GSettings 스키마를 못 찾아 크래시. **스키마 *정의*는 dconf 백엔드 사용 여부와 무관하게 필요**(엔진이 memconf 백엔드여도 GSettings로 스키마를 조회한다).

### 해소
그 gschema를 **소스 tar에서 추출 → `/usr/share/glib-2.0/schemas/`에 설치 → `glib-compile-schemas`** 실행. → 엔진 크래시 사라짐(`ENGINE_ALIVE`) → `ibus engine` = `hangul` 활성. **v10에서 마커 무관 필수픽스로 `install-hangul-arm64-v2.sh`에 baked-in.**

### 어떻게 잡았나
실기기 시리얼로 엔진을 수동 실행해 크래시 메시지를 직접 관측. gschema 16KB를 **base64 청크로 시리얼 전송**(tty MAX_CANON 4KB 회피, MD5 라운드트립 검증)해 reflash 전에 런타임 확증(환각 방지).

### 발표가치 ⭐⭐
"한글이 안 되는 진짜 이유는 폰트도 엔진도 아니라, 빌드 옵션 하나가 스키마 *정의*를 지웠기 때문." from-scratch + 잘못된 빌드 플래그의 합작 함정.

---

## 함정 #14 — machine-id 부재 (from-scratch rootfs가 dbus-uuidgen을 안 함) — 2026-07-23

### 증상
ibus dbus 통신 warning(`/var/lib/dbus/machine-id` 없음).

### 근본원인
from-scratch rootfs는 배포판 설치 시 자동으로 도는 `dbus-uuidgen`을 한 적이 없다 → machine-id 미생성.

### 해소
`dbus-uuidgen`으로 **`/etc/machine-id` + `/var/lib/dbus/machine-id`** 생성. v10에서 필수픽스로 baked-in.

### 발표가치
"배포판이 조용히 해주던 초기화를, from-scratch에선 우리가 명시해야 한다."

---

## 함정 #15 — 한영 토글 = `Shift+Space` (x86의 `Ctrl+Y`는 dconf 전용) — 2026-07-23

### 증상
x86 컨벤션 `Ctrl+Y`로 한영 전환이 memconf ARM64에서 아무 반응 없음.

### 근본원인
`Ctrl+Y` 바인딩은 **dconf 백엔드 전용**이라 memconf 백엔드에선 안 먹는다. ibus-hangul gschema 기본값 `switch-keys='Hangul,Shift+space'` + `initial-input-mode='latin'`(부팅 시 영문).

### 해소
토글키 = **`Shift+Space`**(또는 Hangul 키). 초기모드가 영문이므로 타이핑 전 먼저 토글. 사용자 확인: `Shift+Space` → `gksrmf` → `한글`.

### 발표가치
"x86 UX 컨벤션이 ARM64 백엔드에서 그대로 통하지 않는다." 설정 백엔드(memconf vs dconf)가 hotkey 동작까지 바꾸는 사례.

---

## 함정 #16 — 더블 ibus-daemon (죽은 옛 XIM에 묶인 xterm) — 2026-07-23

### 증상
런타임 픽스 중, 한글이 여전히 안 됨. xinitrc가 부팅 때 띄운 옛 데몬(엔진 크래시 상태) + 수동 재시작 데몬이 **2개 공존**, 먼저 뜬 xterm이 **죽은 옛 XIM 서버**에 연결돼 있었음.

### 해소
**모든 ibus 프로세스를 kill → 깨끗이 하나만** `ibus-daemon --xim` 기동. (재시작 전에 떠 있던 클라이언트는 옛 서버에 바인딩된 채 남으므로 클라이언트도 재기동.)

### 발표가치
"엔진을 고쳐도 클라이언트가 옛 서버에 붙어 있으면 안 된다." XIM 서버-클라이언트 바인딩의 시점 함정.

---

## 함정 #17 — startx가 `/usr/etc` xinitrc를 본다 + xauth 부재 + 입력 드라이버 부재 — 2026-07-17

### 증상
실물 startx가 내 xinitrc를 무시하고 기본 세션(xterm×3+twm)으로 뜨거나, startx가 0.5초 만에 죽거나, 데스크톱은 떠도 마우스/키보드가 안 먹음.

### 근본원인·해소
1. **xinit을 `--sysconfdir=/etc` 없이 빌드** → startx가 `/usr/etc/X11/xinit/xinitrc`를 봄. → xinitrc를 **4경로 복사**(`/root/.xinitrc`, `/etc/skel/.xinitrc`, `/usr/etc/X11/xinit/xinitrc`, `/etc/X11/xinit/xinitrc`).
2. **twm 없어 WM 부재** → xinitrc 끝을 `exec openbox`로.
3. **xauth 미설치**(startx `enable_xauth=1`) → **xauth-1.1.3 빌드**.
4. **X 입력 드라이버 부재(진짜 범인)** — 5b에서 비디오 스택만 빌드, 입력 드라이버 누락 → Xorg가 키보드/마우스 못 읽음. → **libinput 체인 빌드**(mtdev-1.1.6 + libevdev-1.13.1 + libinput-1.25.0 + xf86-input-libinput-1.4.0 → `libinput_drv.so`). (mtdev 구형이라 config.guess 자동갱신 추가.)

### 어떻게 잡았나
실물 startx 로그 + 실기기 마우스 더블클릭으로 xterm 실행되는지로 입력 드라이버를 실증(v7.1).

### 발표가치
"데스크톱이 떠도 입력이 없으면 OS가 아니다." X.org 브링업의 4단 함정을 실기기로 하나씩 확인.

---

## 함정 #18 — 빌드 호스트 안전패턴 #8: WSL 작업은 PowerShell `wsl -u root bash <파일>` — 2026-07-20

### 증상
Git Bash에서 `wsl -u root bash -c '...$LFS...'`를 돌리면 경로가 깨지거나 `$LFS`가 조용히 호스트 fs를 가리켜 엉뚱한 곳에서 동작.

### 근본원인
Git Bash(MSYS)가 인자의 유닉스 경로를 Windows 경로로 **자동 변환**하고 `$LFS` 같은 변수 확장이 꼬임.

### 해소
WSL 작업은 **PowerShell에서 `wsl -u root bash <파일>`**(스크립트를 파일로 박아 실행). Git Bash의 `-c '...'` 인라인 회피.

### 발표가치
"빌드 자동화의 호스트 셸 선택이 조용한 데이터 파괴를 만든다." 안전패턴 #9(CR/LF, #7)와 한 묶음의 "관측/실행 채널 규율".

---

# 데스크톱 완성기 — GTK3/Firefox·네트워크·Plank 함정 (#19~#24) — 2026-07-25~29

> v10(한글) 이후 GTK3+Firefox(v11) → 유선 네트워크(v12) → HW커서/HDMI(v13) → **Plank 소스빌드**(v14) → picom+유리 테마(v15) → 라이브픽스(v16)로 가며 나온 함정 6종. 상세 서사는 [`ARM64-Update-Log.md`](../../ARM64-Update-Log.md)의 2026-07-25~29 섹션.

## 함정 #19 — ibus `--enable-gtk3`는 `--disable-ui`를 요구한다 — 2026-07-25

### 증상
ibus를 `--enable-gtk3`로 재빌드하자 컴파일 사망(rc=2) — wayland 헤더를 찾음.

### 근본원인
ui/gtk3(패널/이모지피커)의 **vala 사전생성 C가 `gdk/gdkwayland.h`·`ibuswaylandim.h`를 하드 include**하며 `--disable-wayland`를 무시한다. wayland 백엔드 없는 우리 gtk3에선 컴파일 불가. x86의 MARUX_DISABLED_WAYLAND 함정의 ARM64 사촌.

### 해소
**`--disable-ui`** — 패널은 `--panel disable`로 안 쓰므로 통째 스킵. im-ibus.so(client/gtk3)는 GDK_WINDOWING_WAYLAND 미정의라 무사 → GTK3 앱/Firefox 한글 입력 정상.

---

## 함정 #20 — libwnck(GNOME 40+) 다운로드 URL은 메이저 버전 디렉토리다 — 2026-07-27

### 증상
libwnck 43.0 타르볼 다운로드 404.

### 근본원인
GNOME 40+ 버저닝에서 download.gnome.org sources 디렉토리는 **메이저만** 쓴다 — `libwnck/43/`이며 `43.0/`이 아니다.

### 해소
URL을 메이저 디렉토리(`43/`)로 교정.

---

## 함정 #21 — vala 0.56 configure는 gobject-introspection(girdir)을 하드 요구한다 — 2026-07-27

### 증상
vala 0.56.17 configure 실패 — girdir을 못 찾음.

### 근본원인
vala 0.56은 **gobject-introspection girdir을 하드 요구**한다.

### 해소
g-i 1.78(glib 2.78 페어) 선빌드 — g-ir 덤퍼는 qemu-chroot 네이티브 실행 OK. (참고: vala 타르볼은 자기 생성 C를 포함해 **valac 없이 부트스트랩 가능** — 이 경로로 MaruxOS가 **자체 valac(0.56.17)** 을 보유하게 됨. plank 0.11.89는 사전생성 C가 0개(75 .vala)라 vala 탈출구가 없었다.)

---

## 함정 #22 — bamf configure는 python3-lxml을 하드 체크한다 (테스트 전용) — 2026-07-27

### 증상
bamf 0.5.6 configure가 python3-lxml 부재로 abort.

### 근본원인
gtester2xunit 테스트 리포트 변환용 의존성인데 configure가 **무조건 하드 체크** — 실제 빌드/런타임엔 미사용.

### 해소
생성된 configure의 해당 `as_fn_error`를 sed로 무력화(patch-bamf.sh). 테스트 전용이라 안전.

---

## 함정 #23 — GSettings memory(memconf) 백엔드는 프로세스별·비영속이다 (x86 "빈 독"의 진범) — 2026-07-27

### 증상
x86 v7에서 plank dock이 빈 상태 — `gsettings set`으로 dock-items를 넣어도 반영 안 됨. "relocatable schema 특이성"으로 오인해 한때 2.0.x로 deferred.

### 근본원인
GLib **memory 백엔드는 프로세스별이고(AND) 비영속** — CLI `gsettings set`은 CLI 프로세스의 메모리에만 쓰여 plank 프로세스에 도달할 수 없다. plank는 `dock1/settings` 파일도 읽지 않는다(설정 = 순수 GSettings).

### 해소
① `40_maruxos.gschema.override`로 dock-items **컴파일된 기본값** 박제(relocatable 스키마 override 합법) ② `GSETTINGS_BACKEND=keyfile`(GLib≥2.60) → `~/.config/glib-2.0/settings/keyfile`로 영속·프로세스간 공유. 실기기에서 plank이 dock-items를 스스로 영속화하는 것까지 검증(v14). ⚠️ override 오타는 glib-compile-schemas가 **조용히 무시** → `gsettings get` 실효값 게이트 필수.

### 발표가치 ⭐⭐
"백엔드 하나가 설정 시스템 전체를 무력화한다." x86 시절 '빈 독' 미스터리의 부검 종결 — deferred가 아니라 정공 해결.

---

## 함정 #24 — openbox rc.xml에 Client 컨텍스트 마우스바인드가 없으면 클릭 창전환이 안 된다 — 2026-07-29

### 증상
겹친 창을 클릭해도 포커스/전면 전환이 안 됨 (v15 실기기).

### 근본원인
rc.xml에 **Client 컨텍스트 마우스바인드(Focus/Raise) 부재** — 1.x부터 잠복한 버그(x86도 동일). 창이 안 겹치는 사용 패턴에서 여태 발각 안 됨.

### 해소
Client 컨텍스트에 클릭→Focus/Raise 바인드 추가. **공유 `config/openbox/rc.xml` 수정이라 x86 트랙도 동시 픽스**(v16 박제, 라이브 `openbox --reconfigure`로 즉시 검증).

### 보너스 근원 규명 (v16)
bamfdaemon 즉사 세그폴트 = **libwnck가 startup-notification 없이 빌드**된 순서 실수(`debug.exception-trace=1`로 특정) → sn·xcb-util을 wnck 앞으로 재배열 + SN NEEDED 실측 게이트 추가 후 wnck+bamf 재빌드.

→ **후일 재규명(2026-08-14) — 위 결론은 오진**: v16 실기기에서 bamfdaemon **여전히 세그폴트**(SN 재빌드 가설 기각). 실근원 = **함정 #25** 참조.

---

## 함정 #25 — libwnck 43.0 업스트림 버그: `invalidate_icons`에 screens NULL 가드가 없다 — 2026-08-14

### 증상
SN 포함 재빌드(v16) 후에도 bamfdaemon 즉사 세그폴트 — 독 실행 점 안 뜸 + 실행 중 앱 클릭 시 새 세션만 생성.

### 근본원인
libwnck 43.0의 **릴리즈 버그**(우리 빌드 잘못 아님): `wnck_handle_init`은 screens 배열을 lazy-alloc(초기 NULL)하는데 `invalidate_icons`엔 NULL 가드가 없다. bamf는 스크린 생성 **전에** `wnck_set_default_icon_size()`를 호출(bamf-legacy-screen.c) → NULL 배열 인덱싱 크래시. 수사법: Pi 셀프컴파일 이분법(t1=wnck만도 즉사) → execinfo 백트레이스 → 크로스 objdump 디스어셈블 + 소스 대조 → 43.0↔43.2 diff로 업스트림 가드(`if (self->screens == NULL) return;`) 확인.

### 해소
libwnck **43.0→43.2 버전업**(`install-plank-arm64.sh`) + bamf 재빌드. 시리얼 무플래시 배포(gzip+base64, MD5 일치)로 실기기 검증 — bamfdaemon 가동 + 점 표시 + 실행 중 앱 클릭 창전환 확인. **v17 탑재 예정**(v16 이미지에는 미포함).

### 발표가치 ⭐⭐
"디버그 심볼도 gdb도 없는 타겟에서 업스트림 릴리즈 버그를 디스어셈블로 잡다" — 그리고 그럴싸한 첫 가설(SN 부재)이 틀렸음을 실기기 재검증이 밝혀낸, 검증 게이트 정신의 실전 사례.

---

## 함정 #26 — tint2는 sed 후 핫리로드되지 않는다 (inode 교체가 감시를 끊음) — 2026-08-14

### 증상
플로팅 시계 튜닝 중 `sed -i`로 값을 바꿔도 화면 무변화 — 사용자 판정 "적용 안 된 듯, 전과 다를 게 없음". 파일엔 새 값이 정상 기록돼 있음.

### 근본원인
`sed -i`는 원본을 제자리 수정하지 않고 **임시 파일을 만들어 rename**한다(inode 교체). tint2의 설정 파일 감시는 원래 inode에 걸려 있어 그대로 끊긴다.

### 해소
**모든 tint2 튜닝은 `sed + 재시작`을 한 호출로 묶는다**(plank environ에서 DBUS/LANG 차용해 재기동). 이후 3라운드 튜닝은 전부 1트 반영.

### 발표가치 ⭐
"파일은 바뀌었는데 화면은 그대로" — 도구의 원자적 쓰기가 감시자를 배신하는 고전 패턴. 독 인디케이터 점 위치 무반응 가설(핫리로드 미적용)과 같은 결.

---

## 함정 #27 — linux-firmware 파일명/위치 업스트림 개편 (brcm→cypress, regdb는 별도 레포) — 2026-08-14

### 증상
`brcm/brcmfmac43455-sdio.bin` 404. `regulatory.db`도 linux-firmware cgit `/plain`에서 404.

### 근본원인
업스트림 재배치: 43455 펌웨어 실체는 **`cypress/cyfmac43455-sdio.{bin,clm_blob}`**(brcm/엔 보드별 NVRAM txt만 잔류), regulatory.db 정본은 **wireless-regdb(sforshee) 레포**.

### 해소
cypress 경로에서 받아 **드라이버 요청명(`brcm/brcmfmac43455-sdio.*`)으로 리네임 저장**, regdb는 wireless-regdb에서 취득. 게이트 = 매직바이트 + 크기 + SHA256-MANIFEST 박제.
**⚠️ 게이트 자기검증 사례**: 처음 박은 clm 매직 `"CLM DATA"`는 **AI 기억 환각**이었고, `od` 실측은 **`"BLOB"`**(CLM 문자열은 오프셋 60). raw byte로 게이트 자체를 정정.

### 발표가치 ⭐⭐
"게이트의 expected 값도 검증 대상" 원칙이 자기 자신을 잡은 두 번째 사례.

---

## 함정 #28 — 무선 드라이버 `=y`만으론 부족: 전원 시퀀스의 reset 브리지(RESET_GPIO)까지 `=y` — 2026-08-17

### 증상
무선 스택 7종을 builtin(`=y`)으로 넣고 펌웨어까지 임베드했는데 **`wlan0`이 아예 없음**. 퀵설정 GUI는 "WiFi 하드웨어/커널 미지원"으로 정직하게 표시.

### 근본원인
dmesg 실측: `platform wifi-pwrseq: deferred probe pending: pwrseq_simple: reset control not ready`. 6.18의 `pwrseq_simple`은 `devm_reset_control_get_optional_shared()`로 **reset 컨트롤러 프레임워크를 우선** 시도하는데, DT의 `reset-gpios`를 reset 컨트롤러로 브리지하는 **`CONFIG_RESET_GPIO`가 `=m`**이었다. no-modules 시스템에서 모듈은 영원히 로드되지 않으므로 **영구 deferred probe** → WiFi SDIO 호스트(mmc) 자체가 미기동.

### 해소
`CONFIG_RESET_GPIO=y` + 게이트(`modules.builtin`에 `reset-gpio.ko` 실측). 결과: `sdhci-iproc fe300000.mmc: allocated mmc-pwrseq` → `brcmfmac: Firmware: BCM4345/6 wl0 version 7.45.234` 로드 성공.

### 발표가치 ⭐⭐
"드라이버를 다 넣었는데 장치가 없다" — no-modules 아키텍처에서 `=m` 하나가 만드는 **조용한 영구 defer**. 의존성은 드라이버 트리가 아니라 **전원/리셋 경로**에 숨어 있었다.

---

## 함정 #29 — mmcblk 번호는 호스트 인덱스를 따라간다 (WiFi 켜면 SD가 밀린다) — 2026-08-17

### 증상
WiFi를 살린 커널로 교체하자 **부팅이 3초 지점에서 완전 정지**. HDMI 무출력, 시리얼 무응답. "죽은 것처럼" 보였으나 커널은 멀쩡히 살아 있었다.

### 근본원인
`loglevel=8` 재캡처가 즉답을 줬다:
```
[2.123] mmc0: SDHCI controller on fe300000.mmc   ← WiFi(SDIO)가 mmc0 선점
[2.167] Waiting for root device /dev/mmcblk0p2...  ← 없는 장치를 무한 대기
[2.277] mmcblk1: mmc1:aaaa SD32G 29.7 GiB          ← SD는 mmcblk1로 밀림
```
그전까지는 WiFi 호스트가 영구 defer(함정 #28)라 SD가 항상 `mmcblk0`이었다. WiFi가 살아나면서 **호스트 인덱스가 앞당겨졌고 블록 장치 번호가 그것을 따라갔다**. `rootwait`는 조용히 기다리므로 화면상 "정지"로 보인다.
※수사 중 "SDIO는 블록 디바이스를 안 만드니 `mmcblk0`은 유지된다"는 소스 추론을 세웠으나 **실측이 정정** — raw 로그가 1차 진실.

### 해소
- 라이브: 이미지 xz 첫 512B만 디코딩해 MBR disk signature 실측(`4898efc0`) → cmdline을 **`root=PARTUUID=4898efc0-02`**로 교체. SD 실물 시그니처와 교차검증 일치(굽기 무결 동시 확인).
- 영구(v20): sfdisk **`label-id: 0x4d415258`("MARX") 고정** → PARTUUID 결정적 → cmdline 하드코딩 + 게이트 2종(이미지 MBR 실측 / cmdline에 `mmcblk` 잔재 금지).

### 발표가치 ⭐⭐⭐
"WiFi를 켰더니 부팅이 죽었다" — 기능 하나가 **다른 서브시스템의 이름 공간**을 흔든 사례. 그리고 `/dev/mmcblkN` 하드코딩이라는, 92빌드 동안 아무도 안 건드렸던 잠복 취약점을 드러냈다. 진단의 결정타는 `loglevel` 한 칸을 올린 것뿐이었다.

---

## 함정 #30 — full-mac 무선칩은 "비번 틀림"을 CONN_FAILED로 위장한다 — 2026-08-23

### 증상
WiFi 연결이 `ASSOCIATED`에서 멈추고 창을 껐다 켜면 `SCANNING`으로 회귀. wpa 로그에 `WRONG_KEY`도 `4-Way Handshake failed`도 없음.

### 근본원인
brcmfmac은 인증·핸드셰이크를 펌웨어가 수행하는 **full-mac**이라, host wpa_supplicant 로그에 4-way 관련 메시지가 **원천적으로 찍히지 않는다**. 실패는 전부 `CONN_FAILED` → `SSID-TEMP-DISABLED`로 뭉뚱그려진다(이것이 "껐다 켜면 SCANNING"의 정체 — wpa가 실패한 네트워크를 스스로 차단).
초기에 "auth timeout이니 비번 문제는 아니다"라고 판단했으나 **성급했음** — 겉보기 로그로 계층을 단정할 수 없다.

### 해소
계층별 소거로 진범 특정(스캔 RX ✅ / 전원 ✅ / AF_PACKET ✅ / 펌웨어 임베드 ✅ / assoc ✅ → **4-way ❌**). 판정 지표를 `grep -c eapol`로 고정한 것이 결정적.

### 발표가치 ⭐⭐
"로그가 조용하다고 무죄가 아니다" — 하드웨어가 일을 대신하면 소프트웨어 로그는 침묵한다.

---

## 함정 #31 — 펌웨어 supplicant(FWSUP)가 켜져 있으면 host는 EAPOL을 볼 수 없다 — 2026-08-23

### 증상
wpa_supplicant를 어떻게 고쳐도 `grep -c eapol = 0`. 연결·암호협상은 정상인데 4-way만 안 됨.

### 근본원인
brcmfmac은 `sup_wpa` iovar로 **FWSUP(펌웨어 내장 supplicant)** 지원을 감지해 활성화하고, `NL80211_EXT_FEATURE_4WAY_HANDSHAKE_STA_PSK`를 광고한다. 그런데 Cypress 43455 펌웨어(7.45.234)는 **지원한다고 광고하면서 실제로는 4-way를 완주하지 못한다**. 이 상태에서는:
- wpa가 offload를 신뢰 → `wait for driver port authorized indication` 무한 대기 → `CONN_FAILED`
- wpa 쪽에서 offload를 차단 → 드라이버는 여전히 펌웨어에 위임, PSK 없이 인증 → **AP가 `reason 23 (IEEE_802_1X_AUTH_FAILED)`로 DEAUTH**

즉 **userspace만 고쳐서는 절대 해결 불가** — EAPOL 프레임을 드라이버가 host로 올리지 않기 때문.

### 해소
커널 `drivers/net/wireless/broadcom/brcm80211/brcmfmac/feature.c`에서 FWSUP 감지 라인 제거 → 드라이버가 항상 host supplicant 모드로 동작 → EAPOL이 wpa로 전달 → **`wpa_state=COMPLETED` + DHCP + 인터넷 도달**. (`rebuild-kernel-wifi-arm64.sh` [2.5]에 멱등 패치+게이트 상주)

### 진단 기법 (박제)
**실패 reason의 변화가 계층 이동의 증거였다**: `CONN_FAILED`(우리가 포기) → `reason 23`(AP가 거부) → 성공. 매 시도마다 `grep -c eapol`을 불변 지표로 삼아 "경로가 실제로 바뀌었는가"를 판정.

### 발표가치 ⭐⭐⭐
"세 번의 실패가 각각 다른 말을 했다" — 같은 증상처럼 보여도 *누가 끊었는가*가 바뀌면 범인이 이동한 것. 커널·드라이버·펌웨어·userspace 4층을 관통해 스위치를 찾은 사례.

---

## 함정 #32 — 스크립트 자동편집: `
` 이스케이프 + 치환 잔재 (같은 세션 3연발) — 2026-08-23~25

### 증상
Python으로 셸 스크립트를 편집해 sed 치환문을 심을 때, 두 가지가 반복해서 터졌다.
1. **`
`이 실제 개행이 되어** sed 표현식이 두 줄로 쪼개짐 → `sed: unterminated 's' command`
   (혹은 반대로 **리터럴 `
`으로 박혀** C 소스 문법을 깨뜨림)
2. 그걸 고치려 한 줄만 교체하면 **원본의 나머지 줄이 잔재로 남아** 문법 오류
   (`#include/' "$hf"` 같은 반쪽 라인)

### 발생 이력 (모두 다른 대상, 같은 원인)
- ibus-hangul 한/영 패치: `
` 리터럴화 → C 문법 파손 (시험 단계에서 검거)
- 그 수정 시: 잔재 2줄 → `patch-ibus-hangul.sh: line 9: syntax error`
- Qt `<limits>` 패치: `
` 개행화 → `sed: unterminated 's' command` → 수정 시 또 잔재 1줄

### 해소 (규칙화)
1. **삽입에 개행이 필요하면 `sed '1i TEXT'`처럼 개행 이스케이프가 없는 형태를 쓴다.**
   (`<limits>`처럼 자체 include guard가 있는 헤더는 파일 최상단 삽입이 안전)
2. 부득이 다줄 치환을 하면 **적용 즉시 해당 블록 전후를 출력해 잔재를 확인**한다.
3. `bash -n`은 이 부류를 **못 잡는다**(문법상 유효한 잔재가 많다) — 눈으로 블록을 봐야 한다.

### 발표가치 ⭐
"자동화가 자동화를 망가뜨린다" — 스크립트를 생성하는 스크립트에서는 이스케이프가 두 겹(생성기→셸→sed)으로 쌓이고, 부분 치환은 반쪽 라인을 남긴다. 게이트(패치 적용 검증)가 있었기에 세 번 다 **빌드 전에** 걸렸다.

---

## 함정 #33 — 오래된 소스 × 새 툴체인: Qt 5.15.2는 GCC 11+에서 빌드되지 않는다 — 2026-08-25

### 증상
qtbase 컴파일 즉시 전량 실패: `'numeric_limits' is not a class template`, `'std::numeric_limits' is not a template` (qfloat16.h, qendian.h 등).

### 근본원인
**GCC 11부터 `<limits>`가 다른 표준 헤더에 전이 포함되지 않는다.** Qt 5.15.2는 2020년(GCC 9 시절) 릴리즈라 `std::numeric_limits`를 직접 include 없이 사용한다. 우리 크로스 툴체인은 **GCC 13.3**.
- Qt 5.15.3+에서 수정됐으나 **그 버전부터 상업 라이선스**라 오픈소스 tarball이 존재하지 않는다(5.15.2가 마지막 공개 릴리즈).

### 해소
업스트림 커밋과 동일하게 각 헤더에 `#include <limits>` 주입(qfloat16/qendian/qbytearraymatcher/qoffsetstringarray_p/qmetatype/qdrawhelper_p 등) + **패치 적용 검증 게이트**.

### 교훈
MaruxOS는 **최신 툴체인 × 수년 전 소스**를 조합하는 구조라 이 부류가 반복될 수 있다(libwnck 43.0 버그, ibus wayland 헤더, 그리고 이번 Qt). **"빌드 실패 = 우리 잘못"이 아니라 시대 불일치일 수 있다**를 먼저 의심할 것.

---

## 함정 #34 — 크로스 빌드 환경 구축: 한 번에 하나씩 드러나는 6겹 — 2026-08-25

### 배경
Qt는 규모상 qemu 네이티브가 불가(qtbase만 10시간+ 추정)해 **MaruxOS 최초의 호스트 크로스 빌드**로 전환했다. 그 과정에서 벽이 **여섯 번, 매번 다른 층에서** 나왔다. 각각은 사소하지만 순서대로 하나씩만 드러나 총 6회 재시도가 필요했다.

| # | 벽 | 층위 | 해소 |
|---|-----|------|------|
| 1 | `numeric_limits is not a class template` | **소스 × 툴체인 시대차** | Qt 5.15.2(2020)는 GCC 9 전제, 우리는 GCC 13 → 각 헤더에 `#include <limits>` 주입 (함정 #33) |
| 2 | `sed: unterminated 's' command` | **자기 도구** | 생성기→셸→sed 3중 이스케이프 (함정 #32) |
| 3 | `xcb-keysyms` 없음 | **의존성 누락** | plank/picom 때 xcb-util 계열 중 keysyms만 빠져 있었음 → 크로스로 보강 + **14종 사전 게이트** 신설 |
| 4 | `'/usr/lib/libXau.la' is not a valid libtool archive` | **libtool** | rootfs의 `*.la`가 `dependency_libs`에 **타겟 절대경로**를 담아 호스트 경로로 오인 → 114건 `dependency_libs=''` (Buildroot/Yocto 표준 해법) |
| 5 | `ld: cannot find /usr/lib/libc.so.6` | **컴파일러 설정** | `--host=`만으로는 sysroot가 안 잡힌다. rootfs `libc.so`는 절대경로 링커스크립트 → **CC/CXX에 `--sysroot` 명시** |
| 6 | `XKB_KEY_dead_lowline was not declared` | **런타임 라이브러리 구버전** | rootfs libxkbcommon이 Qt 5.15 전제(0.8.0+, 2017)보다 오래됨 → 업그레이드는 X.org/GTK 파급 → **X11 keysymdef 고정값 4종만 정의** |

### 교훈
- **"크로스 빌드가 안 된다"는 단일 문제가 아니다.** 소스 시대차 → 의존성 → libtool → 컴파일러 sysroot → 런타임 라이브러리 버전까지 층이 다르고, 앞의 것을 고쳐야 뒤의 것이 드러난다. 한 번에 하나씩 벗겨내는 인내가 필요.
- **증분 빌드 보존이 시간을 지킨다**: 스크립트가 매 실행마다 소스를 재전개하도록 돼 있어, 이미 빌드된 라이브러리 8종(수십 분)이 날아갈 뻔했다. → 기존 트리·configure 결과 재사용하도록 수정(패치는 전부 멱등).
- **게이트가 결과를 보증했다**: `readelf`로 **libQt5Core가 진짜 AArch64인지** 확인 — 크로스 설정이 어긋나 x86 바이너리를 산출하는 최악의 시나리오를 원천 차단.

### 성과 (2026-08-25)
qtbase 5.15.2 크로스 빌드 성공: Core/Gui/Widgets/DBus/Network/Sql/Xml/Concurrent + **xcb 플랫폼 플러그인**(GUI 표시의 전제) + 호스트 moc. 이후 모듈은 동일 설정을 재사용한다.

### 발표가치 ⭐⭐⭐
"Qt를 올리는 데 필요한 건 Qt 지식이 아니라 **빌드 층위를 읽는 능력**이었다" — 6개의 오류 메시지가 각각 다른 층을 가리켰고, 그 순서대로 환경이 완성됐다.

---

## 함정 #35 — 호스트 컴파일러의 암묵 기본값: Ubuntu gcc `_FORTIFY_SOURCE=3`이 Qt를 오탐으로 죽이다 — 2026-08-26

### 증상
v27 실기기에서 **QTerminal이 기동 즉시 `*** buffer overflow detected ***` → SIGABRT**. PCManFM-Qt는 기동은 되나 **종료 시(설정 저장) 같은 메시지로 사망**. `qterminal --version`은 정상(0.17.0, rc 0) — 그래서 v26/v27 게이트(존재·아키텍처·.desktop)를 전부 통과했다.

### 근본원인
```
$ echo | aarch64-linux-gnu-gcc -O2 -dM -E - | grep FORTIFY
#define _FORTIFY_SOURCE 3
```
Ubuntu 24.04의 크로스 gcc 13.3은 `-O2` 이상이면 spec 파일로 **`-D_FORTIFY_SOURCE=3`을 자동 주입**한다. 우리는 준 적이 없는 플래그다. FORTIFY 3의 동적 객체크기 추정(`__builtin_dynamic_object_size`)이 Qt 5.15.2 `qt_readlink()`(qcore_unix.cpp:66-68)의 `QByteArray buf(256); readlink(path, buf.data(), buf.size())`에서 **`buf.data()`를 QArrayData 헤더 구조체 + offset 인라인 포인터로 보고 크기를 헤더 크기로 오판** → glibc `__readlink_chk`가 `len > buflen`으로 abort. 실제 오버플로는 없다.

**왜 이제야**: 배치 A~W는 전부 qemu chroot **네이티브** 빌드 = **우리 gcc 13.2.0**(LFS 툴체인, 이런 기본값 없음). 배치 Q/F가 **MaruxOS 최초 호스트 크로스 컴파일**이었고, 그 순간 *Ubuntu의 컴파일러 정책*이 우리 바이너리에 스며들었다.

### 해소
Qt 스택 전체(qtbase·qtx11extras·qtermwidget·qterminal·libfm-qt·pcmanfm-qt·libexif·libfm-extra·menu-cache)를 **`-D_FORTIFY_SOURCE=2`**로 재빌드 — 2는 정적 추정만 하므로 힙 포인터는 "알 수 없음" → 오탐 없음, 하드닝 유지. `-D…=2`가 명시되면 Ubuntu spec은 3을 붙이지 않는다(실측). 주입 지점: qmake = mkspec `linux-aarch64-gnu-g++/qmake.conf` / CMake = 툴체인 `CMAKE_{C,CXX}_FLAGS_INIT` / autotools = `CFLAGS`. 자산 `scripts/rebuild-qt-fortify-arm64.sh`(단계별 Makefile/CMakeCache 플래그 실존 grep). qtbase 전체 재빌드 5분(32코어)이라 부분 재빌드로 위험을 남기지 않았다.

### 어떻게 잡았나
① rootfs 정적 감사(재귀 NEEDED·플러그인·환경변수) 전부 정상 → 런타임 ② qemu chroot 재현(Xvfb/offscreen 동일) ③ **사용자 제안으로 실기기 시리얼 우선** → 동일 증상 = 에뮬레이션 교차 검증 ④ `QEMU_STRACE`로 QLockFile 생성 직후 abort 특정 ⑤ `qemu -g` + gdb-multiarch `break __chk_fail` → 프레임 확정 ⑥ `-dM -E`로 컴파일러 기본값 실측 → 원인 실증.

### 🔒 게이트 승격 — "존재 검사 ≠ 기동 검사"
`scripts/gate-qt-launch-arm64.sh`: rootfs를 qemu chroot로 **실제 실행**해 qterminal 12초 생존 + pcmanfm-qt(세션 버스 포함) 기동·**SIGTERM 종료 경로**까지 통과해야 PASS. 던져버릴 HOME 사용 후 삭제. 재빌드 말미·install 모듈 2종·**build v28**(+ 통과본 SHA 대조)에 박음. 6.7.4 커널 hallucination이 "값 비교 게이트"를 낳았듯, 이 사고는 "**기동 게이트**"를 낳았다.

### 계열 통찰 / 발표가치
- **#34와 같은 뿌리의 7번째 층**: 크로스 빌드는 "무엇을 호스트에서 실행/탐색하는가"의 경계 문제였는데(#34 후반 4겹), 이번엔 **호스트 컴파일러의 *보이지 않는 기본값*이 타겟 바이너리의 의미를 바꿨다**. 크로스 규칙 ⑥: *호스트 컴파일러 암묵 기본값을 `-dM -E`로 실측하라.*
- **#5 확장(같은 날 발견)**: WSL2 VM은 `wsl` 호출 사이 프로세스가 없으면 **유휴 종료**되고 수동 binfmt 등록이 사라진다(슬립 아님 — 한 세션에 3회). chroot 스크립트 머리에 멱등 재등록 가드 필수. 장기 빌드는 nohup setsid가 VM을 붙잡아 둔다.
- **게이트 자체의 오탐(같은 날)**: 첫 판 기동 게이트는 편의상 `offscreen` 플랫폼을 썼는데, 그 플러그인이 `raise()`를 지원하지 않아 pcmanfm-qt가 SIGSEGV → 픽스된 바이너리를 "실패"로 판정할 뻔했다. **게이트는 배포 경로(xcb/Xvfb)를 그대로 태운다**로 교정. 검증 게이트도 검증 대상이다.
- **거짓 양성도 게이트다**: FORTIFY는 우리를 지키려다 죽였다. "안전 기능이 켜졌는데 왜 죽지?"는 *정책이 어디서 왔는가*를 물을 신호.

## 함정 #36 — 패키지 `make install`이 config가 배포한 `.desktop`을 덮어쓰다 (독 아이콘 투명) — 2026-08-26

### 증상
v28 실기기: QTerminal·PCManFM-Qt는 **기동되는데**(실행 점 표시) 독 아이콘 두 개가 **투명**. Firefox는 정상.

### 근본원인
rootfs `/usr/share/applications/qterminal.desktop`이 업스트림 원본(`Icon=utilities-terminal`), `pcmanfm-qt.desktop`도 `Icon=system-file-manager` — **테마 이름**. 아이콘 테마는 hicolor뿐이라 탐색 실패 → 빈 아이콘. config v12는 `config/applications/*.desktop`(SSOT, `Icon=/usr/share/pixmaps/maruxos/marux-*.png` 절대경로)을 복사해 뒀었는데, **함정 #35 픽스의 FORTIFY 재빌드가 qterminal/pcmanfm-qt를 `make install DESTDIR=$LFS`로 재설치하면서 그 위를 덮어썼다.** v27 감사 시점엔 config판이었음이 기록돼 있다.

**계열**: CLAUDE.md "config → rootfs" 흐름의 **역방향 오염**. rootfs 직접 수정이 다음 빌드에 지워지듯, 패키지 (재)설치는 config 적용을 지운다. 그리고 v28 게이트는 `.desktop` *존재*만 봤다 — #35 "존재≠기동"의 형제 **"존재≠내용"**.

### 해소
① 실기기 라이브 픽스(시리얼 sed + plank 재기동) → 재플래시 없이 검증 지속 ② rootfs = config v12 재적용(5/5 `cmp` 일치) ③ **v29 게이트**: 독 5종 `.desktop`이 config 원본과 **바이트 일치** + 절대경로 Icon 실존 + 테마 이름 Icon 금지 + idesk `.lnk` Icon 실존 ④ `rebuild-qt-fortify-arm64.sh` 말미에 "config 재적용 필수" 경고.

### 어떻게 잡았나
rootfs 정적 감사 한 번 — `.desktop`의 `Icon=` 값이 절대경로가 아니고, `/usr/share/icons/`에 hicolor뿐. 라파 로그 불필요. (v27 감사 출력과 대조해 "언제 바뀌었나"까지 특정.)

### 교훈 / 발표가치
- **순서 의존성은 규칙이 아니라 게이트로 강제한다**: "패키지 설치 → config 적용" 순서를 사람이 기억하는 대신, 이미지 빌드가 config SSOT와 rootfs를 바이트 비교한다.
- 하루에 게이트가 두 번 승격됐다: 존재→기동(#35), 존재→내용(#36). *게이트는 통과한 것을 증명하지 않는다 — 검사한 것만 증명한다.*

## 왜 이 카탈로그가 존재하는가 — 1.x의 5개월 환각 대비

ARM64 트랙이 함정 하나하나를 **raw byte로 잡고, 실물 산출물에서 검증하고, 빠짐없이 박제**하는 이유는 1.x의 전과 때문이다(`Kernel-Update-Log.md §2`, verbatim 요약):

- 1.x 시리즈는 모든 문서/메타데이터가 **"Linux 6.12 LTS"로 광고**했으나, 실제 `vmlinuz`는 **6.7.4**였다.
- **Genesis(2025-12-14쯤)**: 사용자 의도는 6.12였으나 그 순간 AI가 `KERNEL_VERSION`을 6.7.4로 hallucinate해서 박고, 진짜로 그 버전을 다운로드+컴파일+설치.
- **2025-12-16 ~ 2026-02-19(1.0 Phoenix → 1.1 67-v54)**: **총 92회 빌드, 커널 재컴파일 0회.** 6.7.4 genesis 커널이 유저랜드 레이어링만 바뀐 채 전 라이프사이클을 떠받침.
- **2026-05-05 발견.** 약 5개월간 거짓 광고 + 진짜 6.7.4 동작.
- **왜 안 들켰나**: `KERNEL_VERSION` 값이 어디에서도 vmlinuz와 비교/강제되지 않았고, 빌드는 `vmlinuz*` 글롭으로 무지성 복사했으며, 6.7.4가 "잘 돌았고", **검증 게이트가 없었다.**

> **교훈(원문)**: *"검증 게이트가 없으면 거짓이 인프라가 된다."* 그래서 ARM64 트랙은 ① 모든 단일진실값을 raw byte/설치 산출물로 재검증하고(#1 SHA·#3 `libc.so.6`), ② 다른 세션의 미검증 가정을 raw로 잡고(#1 defconfig), ③ 물리적 트랙 분리(디렉토리·브랜치·빌드 스크립트·산출물명 + 4종 게이트)로 환각을 한 트랙에 가두며, ④ 모든 함정을 이 카탈로그에 박제한다. **2.0.0은 MaruxOS 역사상 두 번째 커널 빌드이자 첫 aarch64 진짜 빌드** — 이 카탈로그는 그 "정직한 빌드"의 항해일지다.
