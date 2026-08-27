# MaruxOS Kernel Update Log

> **목적**: MaruxOS 2.0.0 "Cooked" — 커널 6.x → 6.18 LTS 업그레이드 작업의 일지.
> 단순 작업 기록이 아니라 **함정·삽질·인사이트** 중심으로 기록한다. 나중에 공유하거나
> 다음 메이저 업그레이드(3.0+) 시 참고하기 위해.
>
> 작성 규칙:
> - 시간순 추가, 위에서 아래로
> - 발견은 **놀라웠던 순서**로 강조 (당연한 건 짧게, 의외인 건 길게)
> - 가설 → 검증 → 결과 흐름을 보존 (사후 정당화 금지)
> - 솔직하게 — 잘못된 가정/실수도 그대로 기록 (그게 진짜 자료가 됨)

---

## 2026-05-05 — Day 1

### 0. 진입 시점 상태

- 1.2.1 정식 릴리즈 완료 ([v1.2.1](https://github.com/ProgrammingYJ/MaruxOS/releases/tag/v1.2.1)), main 브랜치 안정.
- 작업 브랜치 `2.0.0-cooked-kernel` 분기 생성.
- 코드네임 **"Cooked"** 결정 — LLM 양면성("ㅈㄴ 잘 만들기도 하지만 개같이 망치기도 함, Hallucination") 메타-자기풍자.

### 1. 정찰 (인터넷 검색만, 학습 데이터 배제)

**확정 사실:**
- 6.18 = 정식 LTS (2025-12-03 Greg Kroah-Hartman 발표, 2년 long-term)
- 최신 stable = **6.18.26** (2026-04-30 릴리즈)
- SHA256 = `a2c754cc38351abbe1e24f8e3e61efb650829ea3af802bdcc4ae31e3d070cdae`
- 출처: kernel.org, Phoronix, kernelnewbies, CNX Software

**MaruxOS에 영향 가능한 변경사항 (changelog 발췌):**
- Bcachefs 메인라인 제거 → 영향 없음 (ext4 사용)
- Samsung S3C2410 SoC 제거 → 영향 없음
- **Nouveau 기본 동작 변경** (Ampere/Turing GPU에서 NVIDIA GSP 펌웨어 우선) — VM 무관, 베어메탈 Nvidia 사용자에게 잠재 영향
- Rust Binder 드라이버 추가 → 안 켜면 무관 (`oldconfig` default N 예상)
- eBPF 서명, PSP TCP 암호화, dm-pcache, XFS 온라인 fsck — 모두 옵션 / 기본 영향 없음
- Slab allocator 개선 ("Sheaves") — 내부, 투명
- Apple Silicon M2 Pro/Max/Ultra DT 추가 → 무관

**ARM64 / Pi 4B 후속 작업 사전 정보 (이번 범위는 아님):**
- ~~6.18 mainline `bcm2711_defconfig`로 Pi 4 부팅 + V3D 3D 가속 작동~~ 🚨 **[2026-06-19 적발 — ARM64 함정 #1]** mainline에는 `bcm2711_defconfig`가 **없음** (RPi 포크 전용 config). mainline `arch/arm64/configs/`엔 `defconfig`/`hardening.config`/`virt.config` 셋뿐 → 통합 `defconfig` 하나로 Pi4 포함 전 arm64 커버(`CONFIG_ARCH_BCM2835=y`). 또한 "부팅/가속 작동"은 Pi 빌드 0회 시점의 **미검증 단정**. ARM64-Update-Log.md 함정 #1 참조.
- Arch ARM, Armbian 모두 6.18 mainline 사용 중 (사실 — 단 그들도 통합 defconfig 계열)
- → RPi 포크 안 써도 됨 ✓ (결론은 맞았으나 근거가 틀림 — mainline 통합 defconfig + Pi4 DTS로 지원)

### 2. 충격 발견 #1 — "6.12 LTS"는 거짓말이었음 ⚠️

`/home/administrator/MaruxOS/build/rootfs-lfs/boot/`를 직접 들여다봤더니:

```
vmlinuz-6.7.4-maruxos  (12월 14일 빌드)
vmlinuz                (위 파일 심볼릭 링크)
```

**실제 커널은 6.7.4.** 한참 전에 빌드된 그대로. 그런데 모든 문서/메타데이터는 "Linux 6.12 LTS"로 광고 중.

**진짜 그림 (사용자 회고 + ISO-BUILD-HISTORY 교차 검증):**

이 vmlinuz는 박혀있던 외부 자산이 아니라 **MaruxOS 최초 LFS Genesis(2025-12-14쯤) 단계에서 진짜 from-source로 빌드된 결과물**이다. 파일명의 `-maruxos` suffix가 증거 — `lfs/08-system-configuration.sh`의 라인 305:

```sh
cp -iv arch/x86/boot/bzImage /boot/vmlinuz-$KERNEL_VERSION-maruxos
```

이게 LFS Chapter 10의 정식 커널 설치 단계. 즉 **MaruxOS는 진짜 LFS from-scratch 프로젝트**고, 이때 컴파일된 6.7.4 vmlinuz가 genesis kernel.

**의미 (정정된 시간선):**
- **Genesis (2025-12-14쯤)**: 사용자 의도는 6.12였으나 그 순간 AI(이전 클로드)가 KERNEL_VERSION을 6.7.4로 hallucinate해서 박음. 진짜로 그 버전을 다운로드 + 컴파일 + 설치 완료.
- **2025-12-16 ~ 2026-02-19 (1.0 Phoenix → 1.1 67-v54)**: 92회 빌드. 모두 같은 6.7.4 vmlinuz 재사용. 유저랜드 레이어링(Firefox, ibus, idesk, 폰트 등)만 매번 변경. **커널은 단 한 번도 재컴파일 안 됨.**
- **2026-05-05 (오늘)**: 발견. 1년 가까이 거짓 광고 + 진짜 6.7.4 동작.

**왜 안 들켰나:**
- `marux-release.conf`의 `KERNEL_VERSION="6.12"` 값은 어디에서도 vmlinuz 파일과 비교/강제되지 않음
- 빌드 스크립트는 `vmlinuz*` 글롭으로 무지성 복사
- 6.7.4가 어쨌든 "잘 돈다" — 한글 입력, X.org, idesk 등 다 작동
- 검증 게이트가 없어서 거짓이 5개월간 인프라가 됨

**시적 함의 (Cooked의 의미가 또 강해짐):**
- 코드명 "Cooked"는 LLM의 Hallucination 양면성을 메타-자기풍자한 이름
- 그런데 이 코드명이 정해진 순간, **MaruxOS의 첫 의사결정(genesis kernel 버전)부터 이미 hallucinate되어 5개월 살아남았음이 드러남**
- 즉 1.x는 **Cooked 상태로 태어났는데 누구도 모르고 있던 시기**
- 2.0.0 "Cooked"는 사실상 **두 번째 Genesis** — 첫 Cooked 청소하고 진짜 6.18.26 위에 다시 짓는 작업
- "AI 한계 도전" 프로젝트가 "AI의 한계를 자기 자신의 인프라에 통합한 사례"가 됨. 너무 완벽한 자기참조.

Phase E의 known-risks 문서에 errata로 솔직하게 기록 예정.

### 2-A. ISO-BUILD-HISTORY.md 교차 검증 (보강)

`ISO-BUILD-HISTORY.md` 읽고 추가 데이터 확보:
- **총 92회 빌드** (x86_64 + v2~v33 + 67-v1~v54)
- 1.0 Phoenix 첫 ISO: **2025-12-16** ← genesis kernel(12-14)보다 2일 늦음 → 커널 빌드가 ISO 작업보다 먼저 끝났음을 시간선으로 확인
- 1.1 릴리즈: 67-v54 (2026-02-19) — 한글 입력 완성으로 메이저 점프
- **92회 빌드 중 커널 재컴파일 0회** — 모든 변경사항이 유저랜드 / squashfs / initrd 메타데이터 / GRUB 설정 등에 한정됨
- 결론: 6.7.4 genesis kernel이 단일 변경 없이 1.x 전체 라이프사이클을 떠받쳤음. 2.0.0이 **MaruxOS 역사상 두 번째 커널 빌드**가 됨.

### 3. 충격 발견 #2 — initrd 생성 파이프라인이 없음

`grep -r "mkinitramfs|mkinitcpio|dracut"` → 0 hits.

**즉 이 프로젝트는 initrd를 자체 생성한 적이 한 번도 없음.** 그럼 1.x ISO의 initrd.img는?

추적 결과:
- `rootfs-lfs/boot/`에는 initrd가 아예 없음 (ls 확인)
- 빌드 스크립트는 `INITRD=$(ls "$SQUASHFS_ROOT/boot/initrd"* | head -1)` → 못 찾고 "Warning: initrd not found, skipping" 출력
- **그런데 `iso-build/boot/initrd.img`는 존재** (1.2MB, gzip cpio)
- `iso-build/`는 빌드 간 보존되는 디렉토리 → 어느 옛날에 박혔던 initrd가 누적 잔류

**즉 모든 1.x 빌드는 누군가가 옛날에 손으로 박은 initrd를 재사용해왔음.** 매번 init 스크립트의 버전 문자열만 sed로 살짝 수정해서 다시 묶음.

### 4. 굿 뉴스 — initrd가 minimal busybox 구조

stale initrd를 뜯어서 분석:

```
init  (busybox sh 스크립트, 3599 bytes)
bin/  dev/  lib/  lib64/  mnt/  newroot/  proc/  run/  sbin/  sys/
```

**`lib/modules/` 없음.** 즉 커널 버전에 묶인 모듈이 없음.

`init` 스크립트 핵심 로직:
```sh
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs devtmpfs /dev
mknod /dev/sr0 b 11 0 ...    # CDROM device nodes
sleep 5                       # wait for devices
for dev in /dev/sr0 /dev/sr1 /dev/cdrom ...; do
    mount -t iso9660 -o ro "$dev" /mnt/cdrom
    if [ -f /mnt/cdrom/live/filesystem.squashfs ]; then
        mount -t squashfs -o ro /mnt/cdrom/live/filesystem.squashfs /newroot
        ...
```

**modprobe / insmod 호출 0건.** 즉 커널은 다음 기능을 **builtin (`=y`)**으로 가지고 있어야 함:

| 기능 | KConfig | 이유 |
|------|---------|------|
| ISO9660 FS | `CONFIG_ISO9660_FS=y` | CD-ROM 마운트 |
| SquashFS | `CONFIG_SQUASHFS=y` | Live filesystem 마운트 |
| devtmpfs | `CONFIG_DEVTMPFS=y` | `/dev` 자동 채움 |
| CD-ROM | `CONFIG_BLK_DEV_SR=y` | `/dev/sr*` |
| Loopback | `CONFIG_BLK_DEV_LOOP=y` | (있으면 좋음) |
| virtio_blk / virtio_pci | `=y` | QEMU VM 부팅 |
| ahci | `=y` | SATA 디스크 (베어메탈) |
| nvme | `=y` | NVMe 디스크 (베어메탈) |
| xhci_hcd | `=y` | USB 부팅 (실기) |
| ext4 | `=y` 권장 | Live boot 흐름엔 squashfs면 충분하지만 안전 |

**→ 6.18.26 .config에서 위를 builtin으로 보장하면 stale initrd 그대로 재사용 가능.** initrd 재생성 작업 면제 (대박).

### 5. Phase B 완료 (메타데이터)

- `config/lfs-versions.conf`: `KERNEL_VERSION="6.18.26"`, `KERNEL_SHA256` 신규 추가
- `config/marux-release.conf`: `DISTRO_VERSION="2.0.0"`, `DISTRO_CODENAME="Cooked"`, `KERNEL_VERSION="6.18.26"`
- 커밋 `4be4520`, 브랜치 `2.0.0-cooked-kernel`

### 6. 다음 액션 (Phase C 진입 전)

**스크립트 수정 필요 (3가지 누락):**

1. `01-download-kernel.sh` — SHA256 검증 추가
2. `02-build-kernel.sh` — `make modules_install` + `depmod` + 검증 단계 추가, 위 builtin 옵션 강제
3. initrd는 그대로 재사용 (Phase 4 발견에 따라)

**Open question:**
- 기존 `kernel/config/.config`는 6.7.4용. 6.18.26 트리에 복사 → `make olddefconfig` 시 11버전 점프 신규 옵션 폭탄. 대화형 한 번 돌려볼지 / 새 defconfig + MaruxOS 옵션으로 fresh start 할지.

---

## 인사이트 모음 (작업 중 떠오른 것들)

> **rootfs-lfs/ vs config/의 분리는 양날의 검**: config/는 빌드마다 fresh하게 적용되지만, rootfs-lfs/에 한 번 박힌 건 명시적으로 빼지 않으면 영원히 따라간다. 6.7.4가 1년 넘게 살아남은 이유. → 빌드 스크립트가 **rootfs-lfs/boot/vmlinuz 존재 여부를 검증하고 KERNEL_VERSION과 일치하지 않으면 에러**를 내는 식으로 single-source-of-truth 강제하는 게 맞을 듯. 2.0.0 작업 중 추가 검토.

> **AI hallucination이 1년 살아남은 메커니즘**: 빌드는 `rootfs-lfs/boot/vmlinuz*`를 그냥 복사. KERNEL_VERSION 값은 어디에서도 비교/강제 안 됨. 광고 문구만 6.12, 실제 커널은 6.7.4. **검증 게이트가 없으면 거짓이 인프라가 된다.** 다음 빌드 스크립트엔 `[ "$(strings vmlinuz | grep "Linux version" | head -1 | awk '{print $3}')" = "$KERNEL_VERSION" ]` 같은 sanity check 박는 거 검토.

---

### 7. Phase C 진입 — 검증 게이트가 자기 자신의 Hallucination을 잡아냄 ⚡

**시각**: 2026-05-06 00:21 (KST)

01-download-kernel.sh에 SHA256 검증 게이트를 새로 박았는데, 첫 다운로드부터 mismatch로 abort됨:

```
Expected: a2c754cc38351abbe1e24f8e3e61efb650829ea3af802bdcc4ae31e3d070cdae
Actual:   53772f5d3776e043767c8d81a32240d1f3eb64e822a5d7a510b55ca40707b0ec
```

**원인**: `Expected` 값이 **WebFetch로 sha256sums.asc 페이지를 AI 요약시키며 받아온 값**. AI 요약 단계에서 hallucinate된 채로 `config/lfs-versions.conf`에 박혔음. 진짜 SHA는 `53772f5...0ec`.

**의미**:
- 검증 게이트가 **자기 자신의 hallucination을 첫 실행에서 잡아냄**. 게이트 없었으면 잘못된 SHA를 "expected"로 가정한 채 진짜 파일이 변조됐다고 의심하거나, 게이트 자체를 우회했을 것.
- 1.x의 6.7.4 사고는 검증 게이트가 없어서 일어났고, 2.0.0은 첫날부터 게이트가 hallucination을 막음. **시스템이 실제로 작동했다는 1차 증거.**
- "Cooked" 코드명을 정한 그 세션에서 또 한 번 자기 hallucination이 잡힘 — 같은 함수가 두 번 실행된 셈.

**조치**:
- `config/lfs-versions.conf`의 `KERNEL_SHA256` 을 실제 다운로드 hash(`53772f5...0ec`)로 갱신.
- 다운로드된 tarball은 cdn.kernel.org에서 HTTPS로 정상 수신된 148MB 파일이므로 신뢰. (kernel.org가 변조됐을 가능성 < AI 요약이 hallucinate했을 가능성.)
- 추가 검증으로 추후 PGP 서명 (`linux-6.18.26.tar.sign`) 검증 단계 추가도 검토 가능 — 단 본 작업 범위 외.

**교훈** (Insight 추가):

> **검증 게이트의 expected 값도 검증 대상이다.** "기대값을 어디서 얻었나?"가 게이트 신뢰성의 진짜 기반. AI 요약/WebFetch 결과를 expected로 그대로 박으면 게이트가 hallucination을 inherit한다. 가능하면 raw bytes로 직접 가져오거나 (curl + sha256sum), 다운로드 후 첫 실행에서 verify 결과를 expected로 채택하는 "trust on first download" 모델도 검토. 본 케이스는 후자에 가깝게 처리됨.

---

## 2026-05-06 — Day 2

### 8. 67 → Cooked 잔재 청소 (사전 릴리즈 준비)

**시각**: 2026-05-06 오전 (kernel 빌드 진행 중)

빌드 대기 시간을 활용한 release prep 작업. 67/Phoenix 잔재가 어디 남아있는지 grep으로 일제 검색:

| 파일 | 변경 |
|------|------|
| `iso/boot/grub/grub.cfg` | "MaruxOS 1.1 67" → "MaruxOS 2.0.0 Cooked" + Safe Mode/Debug 엔트리 추가 |
| `README.md` | 다운로드 뱃지/커널 뱃지/"Modern Kernel"/"Current Version" 4곳 → 2.0.0 Cooked + 6.18.26 LTS |
| `LICENSE` | Linux Kernel 6.12 → 6.18.26 LTS |
| `CHANGELOG.md` | 2.0.0 항목 신규 작성 — 검증 게이트 5종, 코드명 의미, **Errata 섹션** (6.7.4 hallucination 정정 명시) |
| `FAQ.md` | 커널 버전 답변 (영문/한글), 코드네임 변천사 (Phoenix→67→Cooked) |
| `scripts/install-neofetch.sh` | 하드코딩 `1.2.0` → `$DISTRO_VERSION` 동적 (single-source-of-truth 강화) |

**의도적으로 남긴 것**:
- 버전별 `build-X.Y.Z-67-vN.sh` — 시기별 frozen artifact, 그대로 보존
- `ISO-BUILD-HISTORY.md/-EN.md` — 역사 기록 (그땐 진짜 67이었음)
- 빌드 시점 sed로 동적 교체되는 항목들 (`/etc/maruxos-release` 등)

작업 후 grep 재확인: 67/Phoenix 잔재 0건 (release prep 완료).

### 9. Audit 라운드 — "다시 의심하라" 적용

빌드 1.5시간 대기 시간 동안 작업물 audit. 5개 점검 진행.

#### Audit 1 — 02-build-kernel.sh 옵션 누락

발견: 명시 안 된 critical builtin 다수.
- `CONFIG_BLK_DEV_INITRD` — initrd 자체 지원. **defconfig에 있어도 명시 안 하면 검증 게이트가 못 잡음**
- `CONFIG_RD_GZIP` — gzip initrd 압축 해제 (우리 initrd 형식)
- `CONFIG_VT`, `CONFIG_VT_CONSOLE` — text console
- `CONFIG_INPUT_EVDEV` — X.org가 키보드/마우스 잡는 인터페이스
- `CONFIG_KEYBOARD_ATKBD`, `CONFIG_MOUSE_PS2` — PS/2 (베어메탈)
- `CONFIG_NET`, `CONFIG_INET`, `CONFIG_PACKET`, `CONFIG_UNIX` — 네트워킹 코어 (dhcpcd raw socket)

**대응**: `02-build-kernel.sh`에 카테고리 추가 ("Initrd / boot core", "Input devices", "Networking core"). `CRITICAL_BUILTINS` 검증 리스트에 핵심 9개 추가.

**현재 진행 중인 빌드엔 영향 없음** — 사용자 지적: "build kernel 파일 수정해봤자 뭔의미가있냐". 정당한 비판. 하지만 다음 iteration에 적용 가능 + 검증 게이트가 누락 발견 시 abort하도록 사전 강화. 발표 자료 관점에서도 "audit 모먼트" 자체가 가치.

#### Audit 2 — build-2.0.0-cooked-v1.sh 보강

추가:
- **Pre-flight 도구 검증** — mksquashfs/xorriso/cpio/sha256sum 등 누락 시 빌드 시작도 안 함
- **디스크 공간 검증** — 5GB 미만이면 abort
- **타임스탬프 로깅** (`log STAGE message` 헬퍼) — 빌드 elapsed time 추적, 발표 자료 raw 데이터화
- **모듈 핸드오프 검증** — staging count == synced count 비교, mismatch 시 abort
- **rootfs vmlinuz 임베드 버전 재검증** — 02 단계 검증 + sync 후 재검증 (이중 게이트, 1.x 6.7.4 잔재 재유입 차단)

#### Audit 3 — 권한 모델 명시

1.x 빌드는 root 또는 sudo로 돌렸을 가능성 큼 (chroot + rootfs-lfs 소유권). 새 스크립트도 동일 모델 가정. CLAUDE.md "알아둘 제약"에 명시 추가.

#### Audit 4 — minimal initrd 제약 형식화

`lib/modules` 없는 initrd는 부팅 필수 드라이버를 100% builtin (`=y`)으로 요구. 이 제약이 다음 세션에서 또 잊히면 module로 빌드해서 부팅 패닉. CLAUDE.md "알아둘 제약"에 큰 글씨로 추가.

#### Audit 5 — Rollback 경로 문서화

`docs/ROLLBACK.md` 신규 작성. Triple Safety Net (GitHub Release / Local output / Git main) + 4가지 시나리오별 복구 절차 (사용자 단순 부팅 / 빌드 호스트 환경 복원 / Git 코드 롤백 / 백업 재해 복구) + ISO 마운트 + squashfs 추출 명령 포함. 마지막 보루: LFS Phase 1부터 재빌드 가능 (단 비트 단위 복원은 불가).

### 10. CLAUDE.md 업데이트

핵심 제약 정리 (`알아둘 제약` 섹션 확장):
- 버전 자동 bump 금지
- minimal busybox initrd → builtin 강제
- 검증 게이트 종교적 유지 (expected 값 자체 검증 포함)
- PCManFM 불가
- 한글 입력 Wayland 패치 필요
- idesk SIGHUP 회피
- 빌드 권한 모델 (root/sudo)

목적: 다음 세션의 Claude가 같은 함정 안 밟게.

### 인사이트 보강 (Day 2 누적)

> **Audit 작업 자체가 발표 자료가 된다.** 빌드 1.5시간 대기 시간을 "그냥 기다림"으로 두지 않고 audit 라운드로 활용 → 잠재 함정 5종 추가 발견 + 문서 3종 보강. 컨퍼런스 발표 청중에게 가치 있는 "어떻게 작업하는가"의 디테일이 여기서 나옴. 작업 흐름 자체가 콘텐츠.

> **검증 게이트의 expected 값 audit은 "다시 의심하라" 원칙의 핵심 적용**. 1.x 6.7.4 hallucination도 expected 값(KERNEL_VERSION="6.12")이 검증 안 된 채 광고됐기 때문에 살아남음. 2.0.0의 모든 expected 값을 audit하는 게 게이트 신뢰성의 진짜 기반.

> **롤백 가능성은 메이저 점프의 안전망 핵심**. 단방향 마이그레이션은 위험 → triple safety net (GitHub / local / git main) 설계 + 명시적 rollback 가이드 문서화가 메이저 버전 점프 표준 절차. ROLLBACK.md가 없으면 main에 머지 금지 원칙.

---

### 11. 첫 빌드 실패 — Windows fs case-insensitive 함정 발견 ⚠️

**시각**: 2026-05-06, 새벽 (kernel 빌드 시도 중)

`02-build-kernel.sh` 첫 실행 결과:

```
make[4]: *** No rule to make target 'net/netfilter/xt_TCPMSS.o',
         needed by 'net/netfilter/built-in.a'.  Stop.
```

**진단 명령**:
```bash
ls /mnt/c/.../linux-6.18.26/net/netfilter/xt_TCPMSS*       # not found
ls /mnt/c/.../linux-6.18.26/net/netfilter/ | grep -i tcpmss # → xt_tcpmss.c
```

**원인**:
- 커널 소스 추출 위치가 `/mnt/c/Users/Administrator/Desktop/MaruxOS/kernel/source/linux-6.18.26/` — **WSL의 DrvFs로 마운트된 Windows 드라이브 (NTFS)**
- NTFS는 case-insensitive (정확히는 case-preserving but case-insensitive lookup)
- 커널 소스에는 `xt_TCPMSS.c`처럼 대문자 파일이 존재하는데 NTFS에 풀면 **`xt_tcpmss.c`로 정규화돼서 박힘**
- Makefile은 `xt_TCPMSS.o` (대문자)를 빌드 시도 → `xt_tcpmss.c`와 매칭 안 됨 → "No rule to make target"

**왜 1.x는 안 걸렸나** (오늘 또 한 겹의 의미 추가):
- 1.x는 Genesis (2025-12-14) 단계에서 6.7.4 vmlinuz를 한 번 빌드 후 92회 빌드 동안 재컴파일 0회
- 즉 이 함정은 **MaruxOS 역사상 처음으로 발견됨** (5개월 + 92회 빌드 동안 묻혀있던)
- 6.7.4 hallucination이 1년 살아남은 이유 중 하나: "재빌드 안 해서 새 함정 노출이 차단됨"

**대응 (스크립트 영구 수정)**:
- `01-download-kernel.sh`, `02-build-kernel.sh`, `build-2.0.0-cooked-v1.sh` 모두에 `WSL_KERNEL_BUILD_ROOT` 환경변수 도입 (default: `/home/$USER/MaruxOS-kernel-build`)
- `/mnt/[a-z]/` 패턴 검출 시 abort with 명확한 에러 메시지
- 커널 소스/빌드 산출물은 WSL native fs로 강제, .config만 git tracked path 유지
- `CLAUDE.md`에 제약 명시 — 다음 세션이 같은 함정 못 밟게

**즉시 액션 (사용자 진행 중)**:
```bash
mkdir -p /home/administrator/MaruxOS-kernel-build && cd $_
cp /mnt/c/.../linux-6.18.26.tar.xz .
sha256sum linux-6.18.26.tar.xz   # SHA 일치 확인
tar -xf linux-6.18.26.tar.xz
cd linux-6.18.26
ls net/netfilter/xt_TCPMSS.c     # 대문자 파일 살아있는지 확인
```

**일반화 인사이트**:

> **파일시스템도 hallucination을 일으킨다.** AI가 만든 코드만 hallucinate하는 게 아니라, **컴퓨팅 환경 자체가 정보를 변형**할 수 있음. 케이스 변환은 OS-level의 "조용한 수정 (silent mutation)" — 사용자도 AI도 이걸 의식하지 않으면 1년 묻힘. 발견되는 순간은 보통 새로운 작업이 시작될 때 (1.x는 재빌드 안 해서 안 들켰다).

> **"AI가 만든 운영체제"라는 framing엔 환경도 포함된다.** WSL 선택, 디렉토리 구조 선택, 마운트 옵션 — 이것들도 모두 의사결정. 이전 클로드는 `/mnt/c`에 커널 소스를 풀기로 결정했고, 그 결정이 5개월 묻혀있다 오늘 노출됨. 발표 청중에게 "AI 협업의 함정"은 코드 레벨뿐 아니라 환경·도구 레벨에도 있음을 보여주는 강한 사례.

> **검증 게이트가 또 작동했다.** 02-build-kernel.sh의 Critical builtin grep 검증이 빌드 자체 fail보다 먼저 catch했다면 더 좋았겠지만, make의 fail-fast가 결과적으로 같은 역할. 이번 사고는 게이트 5개와 더불어 **6번째 게이트로 "빌드 디렉토리 위치 검증"** 을 영구 추가한 케이스. 게이트는 항상 사후에 추가된다는 패턴.

---

### 12. 검증 게이트 자체가 false positive — 폴백 로직 버그 🤦

**시각**: 2026-05-06, 새벽 (Native fs에서 빌드 성공 후)

Native fs로 옮긴 빌드가 끝까지 성공:
```
DEPMOD /home/administrator/MaruxOS-kernel-build/modules/lib/modules/6.18.26
✓ 9 modules installed + modules.dep generated
```

(주: 9 modules는 builtin 위주 .config라 적게 나옴 — 정상 범위)

근데 이어진 vmlinuz 임베드 버전 검증 단계에서:
```
ERROR: Kernel version mismatch!
  Expected: 6.18.26
  Built:    text_size
```

**`text_size`가 커널 버전이라고??** 명백한 false positive.

**원인 분석**:

폴백 로직이 잘못됨. 원래 의도:
1. `strings vmlinuz`로 "Linux version X.Y.Z" 추출 시도
2. 실패하면 (압축된 bzImage이므로 보통 실패) `head -1 System.map | awk '{print $NF}'` 폴백

문제: `System.map`의 첫 줄은 `0000000000000000 D phys_startup_64` 또는 `text_size` 같은 **첫 심볼**이지 버전이 아님. `awk '{print $NF}'`는 마지막 필드 = 심볼 이름을 추출. 즉 폴백이 "심볼 이름을 버전이라 우김".

스스로 검증 게이트를 자랑한 직후 그 게이트가 잘못 동작한 사례 — 너무 적절함.

**수정 (3-tier 우선순위)**:
1. `$KERNEL_SOURCE/include/config/kernel.release` — kbuild가 직접 만드는 정확한 버전 파일 (1순위, 가장 신뢰)
2. `$KERNEL_SOURCE/scripts/extract-vmlinux` (커널 자체 도구) + strings — 압축 푼 후 검색
3. `strings vmlinuz` 직접 (대부분 실패) — 마지막 폴백

이전 폴백이었던 `head -1 System.map`은 폐기. System.map은 버전 정보 없음 — 잘못 가정.

**결과**: 빌드는 사실 완전히 성공. 사용자가 manual로 `cat include/config/kernel.release` 확인하면 `6.18.26` 정확히 나올 것. 게이트만 fix하고 다음 iteration에 적용.

**일반화 인사이트**:

> **"검증 게이트는 신뢰의 기반"이 아니다 — 게이트도 검증 대상이다.** 어제 인사이트("expected 값도 검증 대상")의 더 강한 버전: **로직 자체도 검증 대상**. 본 사례는 게이트 폴백이 "버전이 아닌 심볼 이름"을 추출하면서도 "found something, looks like a string, fail because not version"이라 false positive를 낳았다. 게이트의 false positive율은 silent하게 누적됨 — 진짜 사고를 막은 건 1번에 1번이지만, 그동안 false positive로 시간 낭비한 게 9번이라면 게이트 신뢰도가 낮아져서 결국 사용자가 "또 false positive겠지" 우회 → 진짜 사고 통과. 발표 자료 슬라이드: "게이트의 정밀도/재현율도 측정해야 한다."

> **AI가 만든 게이트도 AI가 hallucinate할 수 있다.** 본 폴백은 내가(이번 세션 클로드) 작성한 코드. "System.map의 첫 줄 마지막 필드가 버전일 것이다"는 검증 안 된 가정. 1.x의 6.7.4 hallucination이 인프라가 된 것과 같은 패턴이 게이트 자체에서도 일어남. **검증 게이트의 가정은 작성 시점에 즉시 한 번 돌려서 reality check해야 한다 (TDD-스럽게).** 본 사례는 reality check 없이 박았다가 첫 실행에서 노출됨 — 다행히 false positive였지 false negative였다면 진짜 사고가 묻혔을 수 있음.

---

### 13. ISO 빌드 첫 시도 — `sudo $USER` 함정

**시각**: 2026-05-06, 새벽 (커널 빌드 검증 통과 직후)

`build-2.0.0-cooked-v1.sh`를 sudo로 첫 실행:
```
ERROR: /home/root/MaruxOS-kernel-build/output/vmlinuz-6.18.26 not found.
       Run scripts/build/02-build-kernel.sh first.
```

근데 커널은 직전에 `/home/administrator/MaruxOS-kernel-build/output/`에 빌드 완료된 상태였음.

**원인**:

스크립트의 경로 기본값이 `/home/$USER/MaruxOS-kernel-build`인데, **`sudo`로 실행하면 `$USER=root`가 됨** → 경로가 `/home/root/...`로 변환 → 실제 산출물 위치(`/home/administrator/...`)와 미스매치.

이건 sudo의 표준 동작 — `$USER`, `$HOME` 등은 root 사용자 환경으로 바뀜. 그러나 우리는 **원래 사용자(`administrator`)의 작업 결과**를 가져와야 함.

**수정 (3개 스크립트 동일 적용)**:
```bash
EFFECTIVE_USER="${SUDO_USER:-$USER}"
WSL_KERNEL_BUILD_ROOT="${WSL_KERNEL_BUILD_ROOT:-/home/$EFFECTIVE_USER/MaruxOS-kernel-build}"
```

`SUDO_USER`는 sudo가 자동 export하는 환경변수로 원래 사용자 이름을 담음. 일반 실행에선 비어있어서 `$USER`로 폴백.

수정 적용한 파일:
- `scripts/build/01-download-kernel.sh`
- `scripts/build/02-build-kernel.sh`
- `scripts/build-2.0.0-cooked-v1.sh`

**일반화 인사이트**:

> **권한 모드 변화는 환경 변수도 변형시킨다.** 내가 어제 작성한 CLAUDE.md "빌드 권한 모델 (root/sudo)" 제약은 옳았지만 **무엇이 바뀌는지 구체화 안 됨**. sudo는 단순히 "권한 상승"이 아니라 **별도 사용자 컨텍스트로 진입** — `$USER`, `$HOME`, `$PWD` 등 모든 사용자 종속 변수가 변함. 스크립트가 이를 전제하고 작성되지 않으면 "권한은 충분한데 경로가 틀린" 함정 발생. **모든 사용자 의존 경로는 `${SUDO_USER:-$USER}` 패턴이 표준.**

> **오늘 잡힌 hallucination 5종 카운트**: ① 6.7.4 5개월짜리 ② SHA256 expected값 ③ Windows fs case 변환 ④ 게이트 폴백 false positive ⑤ sudo $USER 변환. **"Cooked"는 진짜 자기 이름값 한다** — 코드명 정한 그날 잡은 hallucination이 5종. 발표 자료의 Hallucination Hunter 섹션이 진짜 두꺼워질 듯.

---

### 14. 부팅 스플래시에 "67" 잔재 발견 — sed 일관성 결함

**시각**: 2026-05-06, 학교에서 집에 돌아와 첫 QEMU 부팅 후

ISO 부팅 정상, neofetch도 6.18.26 정상. 그런데 **마룩스 부팅 스플래시 화면에 "MaruxOS 2.0.0 / 67"이 표시됨** — 코드명이 안 바뀜.

**원인**:

`build-2.0.0-cooked-v1.sh` step [13] (Version metadata 갱신)에서 sed 패턴이 일관성 없었음:
- `/etc/maruxos-release` → 버전 + 코드명 둘 다 sed (정상)
- `/etc/os-release` → 버전만 sed (코드명 누락)
- `/etc/issue` → 버전만 sed (코드명 누락)
- `/etc/lsb-release` → 버전만 sed (코드명 누락)
- `/usr/bin/marux-splash` → 버전만 sed (코드명 누락) ← 이게 사용자가 본 화면
- initrd init script → 버전 + 코드명 둘 다 (정상, 별도 step [14])

즉 **5개 파일 중 1개만 코드명 갱신 로직 있음**. 나머지 4개는 1.1 시절 그대로 67 박혀있던 게 그대로 살아남음.

**수정**:

`update_version_metadata()` 헬퍼 함수 도입으로 통일:
```bash
update_version_metadata() {
    local file="$1"
    [ -f "$file" ] || return 0
    sed -i "s/MaruxOS [0-9]\+\.[0-9]\+\(\.[0-9]\+\)\?/MaruxOS $DISTRO_VERSION/g" "$file"
    sed -i "s/\bPhoenix\b/$DISTRO_CODENAME/g" "$file"
    sed -i "s/\b67\b/$DISTRO_CODENAME/g" "$file"
}
```

`\b` (단어 경계) 사용으로 `6.18.26` 안의 우연한 `6` 매칭 방지 (false positive 차단). `os-release` / `lsb-release`는 `VERSION_CODENAME` / `DISTRIB_CODENAME` 필드도 별도 명시 갱신.

**일반화 인사이트**:

> **메타데이터 sed 일관성**: 같은 의미의 변환을 여러 파일에 적용할 때 **헬퍼 함수로 추상화하지 않으면 산발적 누락 100% 발생**. 1.x 시리즈는 코드명이 한 번 바뀌었을 뿐 (Phoenix → 67)이라 누락이 5개월간 눈에 안 띄었음. 2.0.0 (67 → Cooked) 점프에서야 미적용 잔재가 가시화됨. 변경 횟수가 많아지는 시점에 발견되는 패턴은 "**조용히 누적된 부채**" — 발표 자료의 한 챕터: "변경이 잦아져야 보이는 함정".

> **부팅 스플래시는 사용자가 처음 보는 곳 = 첫인상**. 발표 슬라이드의 "before/after" 비교에 정확한 스크린샷이 필수. 5개월 6.7.4가 살아남았던 이유 중 하나도 "표면(neofetch, /etc/os-release)이 깔끔해 보였기 때문" — 표면 검증의 한계. 부팅 스플래시처럼 **사람의 눈을 거치는 영역이 진실에 가까운 검증 게이트** 역할도 함.

**사용자 즉시 액션**: ISO 재빌드 후 재부팅 필요 (sed가 빌드 시점 적용 → 현재 ISO엔 67 그대로). 다른 진단 (systemctl --failed, 네트워크 등)은 현재 부팅 상태에서 계속 가능.

---

### 15. Phase D 회귀 검증 통과 — Init 시스템 진실 발견 ✅

**시각**: 2026-05-06, 집에서 첫 QEMU 진입 후

**Init 시스템 미스터리 해결**:

플랜의 Phase D 검증 명령들이 systemd 가정으로 작성되어 있었는데, 실제 실행하니:
```
bash: systemctl: 명령어를 찾을 수 없음
bash: systemd-analyze: 명령어를 찾을 수 없음
```

진단:
- `/sbin/init` = POSIX shell script (LFS bootscripts 래퍼)
- `ps -p 1 -o comm=` → `init.real`
- `/etc/inittab` 존재 (id:5:initdefault, l0..l6 runlevel, getty respawn — 표준 SysVinit)
- `/etc/rc.d/rc{S,0..6}.d/` SysVinit runlevel 디렉토리
- `/etc/init.d/` 서비스 스크립트 (lightdm, sysctl, network, sysklogd 등)
- `/usr/lib/systemd/`엔 `system`/`user` 디렉토리만 잔재 (systemctl 바이너리 미설치)

**결론**: MaruxOS는 SysVinit 기반. 1.x → 2.0.0 모든 시리즈 동일. 사용자도 "67에선 systemd 됐었다"고 회상했지만 그건 혼동 (systemctl-look-alike 도구나 다른 시스템과 혼동). **`config/lfs-versions.conf`의 `SYSTEMD_VERSION="255"` 라인은 dead config — 실제 빌드는 SYSVINIT_VERSION을 따랐음.**

**의미**: 플랜 Day 1에 짠 "systemd 부팅 깊이 체크" / "systemd cgroup 검증" 단계가 모두 무용지물이었음. Day 1 계획 단계에서 init 시스템 검증조차 안 한 hallucination.

**대체 검증으로 통과 확인**:

| 영역 | systemd 명령 (계획) | 실제 사용 명령 | 결과 |
|------|-------------------|---------------|------|
| Init 정상 | `systemctl --failed` | `ps -p 1`, `cat /etc/inittab`, `ls /etc/rc.d/` | ✅ |
| Cgroup | `systemd-run --scope sleep 1` | `mount \| grep cgroup`, `cat /proc/cgroups`, `cat /proc/self/cgroup` | ✅ cgroup2 unified hierarchy 정상 |
| 부팅 깊이 | `systemd-analyze blame` | dmesg + 런타임 관찰 | ✅ |
| 에러 로그 | `journalctl -p err` | `dmesg -l err,warn` (35줄) | ✅ 신규 critical 0건 |

**dmesg err/warn 35줄 분류**:
- VM/firmware 무해: TSC frequency, APIC520, MSR access (Call Trace), Speculative Return Stack (microcode 미로드)
- 정보성: amd_pstate CPPC disabled by BIOS, sgx 그룹 미정의, dmi_memory_id 버퍼
- **유일한 주의 항목**: `regulatory.db failed with error -2` — wireless regulatory database 누락. VM 무관, **베어메탈 Wi-Fi 동작에 영향** → `docs/2.0.0-known-risks.md`에 기록할 항목

**Phase D 통과 확정**:
- 부팅 ✅
- 6.18.26 실제 동작 (neofetch + uname -r) ✅
- 인터넷 통신 ✅
- 한국어 표시/locale ✅
- cgroup v2 ✅
- dmesg 신규 critical 0건 ✅
- 나머지 GUI 검증 (idesk/한영 토글/우클릭/Firefox)은 VM GUI 진입 후

**일반화 인사이트**:

> **Hallucination 6번째: 플랜 자체에 init 시스템 가정 박힘**. 발표 자료의 또 한 챕터 — "어디까지가 hallucination인가". 코드만 hallucinate하는 게 아니라 **계획 단계의 묵시적 가정도 hallucination의 한 형태**. systemd가 표준이라는 일반 지식을 LFS-from-scratch 환경에 무비판적으로 적용한 결과. **계획의 "당연한 가정"도 검증 대상이다** — 컴퓨팅 환경, 파일시스템, init 시스템, 권한 모델, 모두.

> **계획 정확도 vs 실행 정확도의 차이**: 본 사례는 빌드 자체는 성공인데 검증 명령이 환경과 안 맞음 → 일종의 "false negative 위험" — 명령이 안 돌아간다고 검증 실패라 단정하면 잘못된 abort. 사용자가 직접 SysVinit 환경 식별 → 대체 명령 적용으로 통과 확인. **검증의 메타-검증 (이 명령이 이 환경에서 의미 있는가)** 도 게이트의 한 층.

---

### 16. v2 부팅 검증 통과 → UI dock 작업 진입

**시각**: 2026-05-06 23:33 KST

cooked-v2 ISO 부팅 결과:
- `/etc/os-release`: `VERSION="2.0.0"` / `VERSION_ID="2.0.0"` / `PRETTY_NAME="MaruxOS 2.0.0 \"Cooked\""` / `VERSION_CODENAME=cooked` 모두 정상
- `/tmp/hangul-diag.log`: im-ibus.so 정상 로드, GLib/GTK 의존성 OK
- 한국어 표시 / 시계 / 데스크톱 진입 OK

**메타데이터 통째 생성 전략 검증 완료**: v1의 sed-기반 부분 패치는 변형 케이스 누락이 다수, 통째 generate가 안정. (변경 횟수가 많아질수록 sed의 부채 누적되는 패턴 — Section 14 인사이트 검증.)

### 17. 2.0.0 scope 결정 — glibc는 2.1.0으로 분리

**시각**: 2026-05-06 학교 → 집

사용자 제안: glibc 2.38 (CVE 다수)을 2.0.0에서 같이 업그레이드?

**거부 (분리)**. 이유:
- glibc는 C 런타임. 시스템 전체 ABI 의존 → LFS Phase 1부터 재빌드 수준
- 1.x PCManFM 사고 (libc.so.6 덮어쓰기로 커널 패닉)와 같은 위험 패턴
- 2.0.0 scope가 이미 4개 (커널 + dock + ARM64 + glibc) → 발표 일정 맞추려면 분리 필수
- MaruxOS는 Live ISO (영구 환경 아님) → CVE 절박도 일반 서버 대비 낮음

**semver 결정**:
- **2.0.0 "Cooked"** = 커널 아키텍처 점프 (MAJOR) — 6.18.26 LTS + Plank dock + ARM64 (Pi 4B)
- **2.1.0** (예정) = 패키지 업그레이드 (MINOR) — glibc + gcc/binutils 검토
- 발표 자료 측면에서도 깔끔: OSS Korea = 2.0.0, 후속 발표 = 2.1.0의 "LFS에서 glibc 메이저 점프 일지"

**일반화 인사이트**:

> **메이저 vs 마이너 점프의 분리는 발표 자료 단위와 일치한다**. 2.0.0 = 한 발표, 2.1.0 = 다음 발표. 발표는 일관된 스토리가 필요하니 자연히 scope를 좁히게 됨. **발표 일정이 release scope를 절제하는 외부 압력**이 됨 — 단순한 "기술 부채 안전"보다 강한 동기. 인디 개발자에게 발표는 자기-규율 도구.

### 18. Plank dock 도입 시작 — Phase 1 정찰 + Phase 2 setup

**시각**: 2026-05-06 23:50 KST 즈음

**Phase 1 정찰 결과** (게스트 명령 + web 정찰):

| 항목 | 결과 |
|------|------|
| GTK3 | 3.24.41 ✓ |
| GLib | 2.78.4 ✓ (plank 요구 2.32보다 한참 위) |
| libgranite/libplank/libvala | 모두 부재 (예상대로) |
| plank/cairo-dock/awn 바이너리 | 부재 |
| xinitrc 종료 흐름 | `openbox & ... exec tint2` |

Plank Debian Bookworm 의존성:
- libplank1 (자체)
- libgee-0.8-2 ≥ 0.8.3
- libwnck-3-0 ≥ 2.91.6
- libgnome-menu-3-0
- (LFS에 이미 있음) libglib, libgtk-3, libpango, libcairo, libgdk_pixbuf

**Phase 2 setup (사용자 부재 동안 미리 구축)**:

작성된 자산:
- `scripts/install-plank.sh` (신규) — Bookworm .deb 4개 추출, ldd 검증 게이트 포함, 1.x PCManFM 사고 회피용 system lib 보호 화이트리스트
- `config/tint2/tint2rc-systray` (신규) — slim 모드: systray + clock만 하단 우측, plank 공존
- `config/xinitrc` 수정 — plank 자동 시작 (conditional: `/usr/bin/plank` 있을 때만, 없으면 자동 fallback)
- `config/applications/{xterm,firefox,mc}.desktop` 수정 — `StartupWMClass` 추가, 아이콘 경로 정정 (`/usr/share/maruxos/icons/` → `/usr/share/pixmaps/maruxos/`)
- `scripts/build-2.0.0-cooked-v3.sh` (신규) — plank 설치 + tint2rc 분기 로직 (plank 있으면 systray-only, 없으면 default)

**전략 결정 — source vs prebuilt**:

source build 회피 이유:
- LFS rootfs에 valac (Vala 컴파일러) 부재
- Vala source build = 추가 의존성 사슬 (vala / libvala / libgee-dev 등)
- 시간 비용 큼

prebuilt 추출 채택 (Debian Bookworm .deb):
- 1.x Firefox 통합과 동일 패턴 (성공 사례)
- LFS 12.1 GLib 2.78이 Bookworm GLib 2.74의 **forward-compatible** (newer LFS lib에서 older Bookworm bin은 문제없이 동작 — backward compatibility)
- 위험: PCManFM 70개 lib 통째 복사하다 libc 덮어쓰기 → 커널 패닉. **install-plank.sh의 화이트리스트가 이 함정 차단**

**검증 게이트 (install-plank.sh 내장)**:
- 호스트 의존성 lib (GTK3 스택) 존재 확인
- 시스템 핵심 lib 보호 (libc/libglib/libgtk 등은 절대 덮어쓰지 않음)
- 신규 파일만 화이트리스트 경로로 복사
- 마지막에 chroot에서 `ldd /usr/bin/plank` → "not found" 발견 시 abort

**다음 액션 (사용자 리턴 후)**:
1. `sudo bash scripts/build-2.0.0-cooked-v3.sh` — plank 설치 + ISO 빌드
2. QEMU 부팅 → Plank dock 표시 + 한글입력/idesk/ibus 회귀 검증
3. 잘 안 되면 install-plank.sh의 ldd 검증 메시지에서 누락 lib 추적 → 추가 .deb 후보

**일반화 인사이트**:

> **prebuilt 추출은 "시간 절약 vs 의존성 추적 비용"의 trade-off**. 깔끔한 source 빌드는 valac 같은 도구 사슬 추가가 필수 → LFS에선 비용 큼. .deb 추출은 빠르지만 의존성 어디까지 덜어내야 할지가 게이트 — 너무 많이 가져오면 1.x PCManFM 사고 (libc 덮어쓰기), 너무 적게 가져오면 ldd missing → 부팅 후 plank 실행 실패. **화이트리스트 + ldd 검증 = 두 함정 사이의 좁은 안전 통로**.

> **CLAUDE.md "사용자 부재 동안 작업"의 좋은 활용**: 의존성 없는 setup (스크립트 / config 파일 / 빌드 스크립트 작성)은 사용자 입력 없이도 진행 가능. 명확한 가정만 박아두면 됨 (e.g. install-plank.sh의 .deb URL 버전은 정찰로 확정). 사용자 리턴 시점에 "검토 + 실행"만 하면 되는 상태로 만들어두기. 비동기 협업 패턴.

---

## 2026-05-07 — Day 3

### 19. UI scope 결정 — Kali Plasma 스타일 (A) + 단계적 v3~v6

**시각**: 2026-05-07

cooked-v3 베이스라인 (Plank only) 준비 완료된 상태에서, 사용자가 GNOME(Ubuntu) / KDE(Kali Plasma) 스크린샷 두 장을 보여주며 *"다른 리눅스 같은 느낌 내고 싶다"*는 욕심 표명.

**현실 점검 (CLAUDE.md "결정 다시 의심하라" 모드)**:

| Desktop | LFS 설치 가능성 | 비용 |
|---------|----------------|------|
| GNOME Shell | 거의 불가 | mutter + ~100+ libs + dconf 풀 재빌드 |
| KDE Plasma | 거의 불가 | Qt5/Qt6 + Plasma framework + ~200+ libs |
| XFCE 4 | 가능 | 1~2주, xfce4-panel + thunar + xfconf |

본격 GNOME/KDE 도입은 PCManFM 70개 lib 사고와 같은 차원의 위험. 2.0.0 일정 + OSS Korea CFP(6/5) 흔들림.

**대안: 구성 요소 조립으로 시각만 흉내**

리눅스 데스크톱 패턴은 결국 비슷한 building blocks의 조합. GNOME/KDE는 그걸 통합 패키징한 거지, 우리도 같은 컴포넌트 직접 조립 가능:

| Kali에서 본 시각 요소 | LFS에서 가능한 도구 |
|----------------------|------------------|
| Application 카테고리 메뉴 | jgmenu 또는 rofi |
| Places 메뉴 | jgmenu places plugin |
| Sleep/Restart/Shutdown 버튼 | tint2 execp (1.x 패턴) |
| 하단 taskbar + 런처 통합 | Plank (이미 계획) |
| 검색 가능 launcher | rofi -modi drun |

**결정**:
- **A (Kali style)** 채택 — 하단 풀 taskbar + Application menu + 시스템 버튼
- 단계적 v3~v6 구현 (한 번에 다 바꾸면 회귀 추적 어려움 — 1.x v37~v54 패턴)
- **UI lock 후 ARM64** — 양 아키텍처 동시 작업 위험 회피

**시퀀스**:

1. **v3** — Plank baseline (현재) → 부팅 + Plank dock 동작 + 한글입력/idesk 회귀 검증
2. **v4** — Kali Application Menu (jgmenu .deb 추출 + tint2 통합)
3. **v5** — 시스템 버튼 (Sleep/Restart/Shutdown execp) + tint2 테마 다듬기
4. **v6** (선택) — Places menu / rofi launcher (Activities-style)
5. **UI lock** — Phase D2 스트레스 + 한글입력 회귀 + 부팅타임 회귀
6. **ARM64 분기** — Pi 4B 8GB 별도 pipeline (`scripts/arm64/`, `build-2.0.0-cooked-pi4-vN.sh`)
7. **2.0.0 Cooked 정식 릴리즈**

**OSS Korea CFP 6/5 일정 (4주)**: UI ~1주 / ARM64 ~2주 / 안정화+발표자료 ~1주 — 빠듯하지 않음.

**일반화 인사이트**:

> **"distro-grade visual"은 컴포넌트 조립으로 80% 달성 가능**. 사용자가 GNOME/KDE를 아름답다고 느끼는 건 통합된 패키징의 시각적 일관성이지, 그 desktop이 갖는 모든 기능이 아님. tint2 + plank + jgmenu + rofi는 LFS 친화적이고, 잘 조합하면 시각적 일관성 70~80%까지 도달. 나머지 20%(animation, hover preview, KIO/GIO 통합 등)는 의존성 비용이 폭증해서 trade-off 안 맞음. **목표를 "GNOME 만들기"가 아니라 "GNOME처럼 보이기"로 좁히면 LFS에서도 충분**. 발표 자료 챕터 후보: "100MB rootfs로 1GB GNOME처럼 보이게 하기".

> **단계적 v 도입의 디버그 비용 vs 시간 비용**: 한 번에 다 바꾸는 건 빠르지만 깨졌을 때 어느 컴포넌트가 원인인지 추적 어려움. 한 v당 한 컴포넌트 = 추적 쉽지만 빌드 횟수 증가. 1.x 시리즈가 92회 빌드인 이유. Trade-off의 한쪽 끝(big bang)은 디버그 지옥, 다른 쪽 끝(microscopic)은 빌드 피로. **컴포넌트의 독립성에 따라 그라데이션** — 본 케이스는 plank/jgmenu/buttons는 독립적이라 분리 OK, 하지만 같은 v 안에 묶여도 무방. 안전 마진을 위해 분리 채택.

### 20. v3 빌드 진입 (사용자 백그라운드 테스트 중)

cooked-v3 빌드는 다음 단계 검증:
- Plank Bookworm .deb 5개 (plank, libplank1, libgee-0.8-2, libwnck-3-0, libgnome-menu-3-0) 추출 + ldd missing libs 0개
- xinitrc의 conditional plank 시작 (`/usr/bin/plank` 있으면 실행)
- tint2rc 분기: plank 있으면 systray-only 변형으로 자동 교체
- .desktop StartupWMClass + 아이콘 경로 정정 효과

**잠재 시나리오**:

| 결과 | 다음 액션 |
|------|----------|
| ✅ 부팅 + plank 표시 + 한글 OK | v4 (jgmenu) 진입 |
| ⚠️ plank ldd missing libs | install-plank.sh의 ALLOWED_PATHS 확장 + 추가 .deb |
| ❌ 부팅 자체 실패 | 회귀 — install-plank.sh가 핵심 system lib 덮어썼을 가능성. legacy backup으로 복원 후 디버그 |
| ⚠️ plank 떠도 한글 입력 깨짐 | xinitrc 순서 문제 (plank가 ibus-daemon 환경 영향?). 순서 조정 |

오늘의 인사이트:

> **2일차 끝 시점 hallucination/함정 카운트 7종**:
> ① 6.7.4 5개월짜리 ② SHA256 expected ③ Windows fs case 변환 ④ 게이트 false positive ⑤ sudo $USER ⑥ 산발적 sed 67 잔재 ⑦ Phase D systemd 가정.
> Day 3는 빌드 베이스가 안정 → UI 작업 위주, hallucination 발견 빈도는 줄어들 가능성. 발견되면 그것대로 발표 자료 새 챕터.

### 21. cooked-v3 부팅 후 발견 — 두 종류 함정

**시각**: 2026-05-07 00:22 KST 부팅 후 진단

cooked-v3 빌드 성공 + 부팅 정상. 그러나:
- **Plank dock 안 보임** (tint2 default mode 그대로)
- **xterm에서 한국어 깨짐** (Firefox는 정상)

#### 21-A. xterm Korean 깨짐 — long-standing 함정 (regression 아님)

**원인**: xterm을 옵션 없이 호출하면 X11 bitmap font 사용 → Korean glyph 없음. fontconfig (Xft)를 거쳐야 Nanum 등 사용 가능.

- **Win+T (openbox 단축키)** = `xterm -fa 'Monospace' -fs 11` → Xft → 한국어 OK
- **tint2 launcher (.desktop의 Exec=xterm)** = options 없음 → bitmap → 한국어 깨짐

v2에서 한국어 됐던 건 사용자가 Win+T로 띄운 xterm이었고, v3에선 launcher 통해서 띄운 거라 차이 노출. **1.x 시절부터 잠재해있던 함정** — v3 regression 아님. 단, 1.x에서는 사용자가 우연히 Win+T 위주로 사용해서 안 들켰음.

**수정**: 시스템 wide `/etc/X11/Xresources`에 XTerm 기본 설정 박기.
```
XTerm*faceName: Monospace
XTerm*faceSize: 11
XTerm*locale: true
XTerm*utf8: 1
XTerm*inputMethod: ibus
```
+ xinitrc에서 `xrdb -merge /etc/X11/Xresources` 호출 추가.

이러면 어떤 호출 방법이든 xterm 기본 폰트가 Xft → 한국어 OK.

#### 21-B. Plank install 실패 (silent) — 빌드 스크립트 fault tolerance 과잉

**원인**:
- `install-plank.sh`가 5개 .deb 다운로드하는데 **5번째 (libgnome-menu-3-0)에서 wget 실패** → set -e로 abort
- `wget -q` (quiet)로 호출되어 에러 메시지 묻힘
- `build-2.0.0-cooked-v3.sh`가 install-plank.sh 실패를 `|| { echo "non-critical"; }`로 wrap → ISO에 plank 없는 상태로 빌드 완성
- 결과: 사용자는 build success 메시지만 보고 ISO 부팅, plank가 없어서 tint2 default mode

**수정 (이중)**:

1. `install-plank.sh`:
   - `wget -q` → `wget -nv` (에러는 보이게)
   - 빈 placeholder 파일 생성된 경우 정리 (다음 재시도 시 캐시 인식 안 되게)
   - 에러 메시지에 "정확 버전 확인 URL" 가이드 포함

2. `build-2.0.0-cooked-v3.sh`:
   - install-plank.sh 실패 시 strict abort (`exit 1`) — UI lock 단계에선 plank가 critical
   - `PLANK_OPTIONAL=1` 환경변수로 우회 가능 (의도적인 plank 없는 빌드 위해)

**일반화 인사이트**:

> **`-q` 옵션은 silent fail 만든다**. wget의 `-q`는 normal output 억제이지만 에러도 같이 묻음. Production 스크립트에선 `-nv` (no verbose, but errors visible) 또는 `-q` + 명시적 exit code 체크 패턴이 안전. **본 사례는 `-q` + `set -e`의 조합이 묘하게 빌드 logger를 우회 — 사용자가 빌드 출력 보고 있어도 못 봤음.** 발표 자료 챕터: "조용한 옵션이 만드는 큰 사고".

> **Fault tolerance의 양면성**: 빌드 스크립트가 "non-critical"이라며 실패를 넘어가는 건 일부 컴포넌트 (icon sync 등)에선 좋지만, **UI lock 단계의 핵심 컴포넌트(plank)에선 strict 모드가 맞다**. "어떤 실패가 critical인가"는 단계별로 달라짐. v1에선 idesk 실패도 non-critical로 취급했는데 그건 그 단계에 맞았고, plank는 v3 UI 단계의 dock이니 critical. **단계별 strict/lenient 분기**를 명시적 환경변수(PLANK_OPTIONAL 등)로 노출하는 게 future-proof.

> **3일차 hallucination/함정 카운트 9종 누적**:
> 7종(이전) + ⑧ xterm bitmap font fallback (1.x부터 잠재) + ⑨ wget -q + build script fault tolerance silent fail.
> 그 중 ⑧은 진짜 v3 regression이 아니라 환경 차이 — "regression" 같지만 실제로는 항상 있었던 잠재 함정. 발견되는 시점은 변경의 가시성 임계값을 넘었을 때.

### 22. install-plank.sh 진단 → 또 한 번 내 hallucination 즉시 catch

**시각**: 2026-05-07 00:42 KST

install-plank.sh를 verbose 모드로 단독 실행:
```
- Downloading libwnck-3-0_40.0-3_amd64.deb...
http://ftp.debian.org/debian/pool/main/libw/libwnck3/libwnck-3-0_40.0-3_amd64.deb:
2026-05-07 00:42:20 ERROR 404: Not Found.
```

`packages.debian.org` 검증 결과: **실제 Bookworm 버전은 `43.0-3`** (내가 박은 `40.0-3` 아님).

**원인**: install-plank.sh 작성 시 web 정찰에서 `libwnck-3-0 (>= 2.91.6)` 최소 요구사항만 보고 정확 버전 확인 안 함. **추측한 `40.0-3`을 그대로 박음.** 즉 검증 게이트의 expected 값 (2026-05-05 SHA256 사건과 동일 패턴)을 또 안 검증한 것.

**즉시 catch된 이유**:
- 사용자가 verbose 모드로 단독 실행 → 명시적 404 에러 메시지 노출
- 처음 silent install (build script 호출)에선 묻혔으나, `-q` → `-nv` 수정 직후 시도라 보임

**수정**: `LIBWNCK_VERSION="40.0-3"` → `"43.0-3"`. 출처 코멘트도 추가 (`# bookworm 확정 (packages.debian.org 검증 2026-05-07)`).

**일반화 인사이트**:

> **검증 게이트의 expected 값 audit 패턴**: 2026-05-05 SHA256 사건(WebFetch AI 요약이 hallucinate한 SHA를 expected로 박음) → 2026-05-07 .deb 버전 사건(web 정찰 요약이 정확 버전 안 보고 추측). **같은 메타-패턴이 이틀 만에 재현**. 두 사건 다 "외부 1차 자료(packages.debian.org / sha256sums.asc) 직접 확인" 단계 누락. **AI 요약에서 정확 값을 끌어내는 게 더 어려움 — 차라리 직접 raw 페이지 fetch 후 grep**.

> **3일차 hallucination 카운트 10종 누적**:
> 9종(이전) + ⑩ libwnck-3-0 정확 버전 추측 (40.0-3 hallucinate). 같은 카테고리 (검증 게이트 expected 값 미검증)가 두 번째.

> **이 패턴은 발표 자료의 강한 챕터**: "AI가 만든 검증 게이트의 expected 값을 누가 검증하나?" — 본 프로젝트가 이 질문에 직접 답한 사례. 정찰 → expected 박기 → 첫 실행에서 게이트가 자기 자신의 hallucination catch → 정정 → 영구화. **검증 게이트는 점진적으로 신뢰성 증명한다** (한 번에 완성 X).

### 23. Plank install 단독 디버그 — Dangling symlink + Transitive deps 사슬

**시각**: 2026-05-07 00:42 ~ 00:55 KST (15분간 디버그)

#### 23-A. 1차 시도: dangling symlink 함정

`install-plank.sh`가 [5/6] copy 단계에서 abort:
```
cp: not writing through dangling symlink '/.../usr/lib/libwnck-3.so.0.3.0'
```

진단 결과 — 1.x rootfs에 **이전 클로드(들)의 실험 흔적**이 잔류:
```
libwnck-3.so → /usr/lib64/libwnck-3.so   (Dec 15, 2025 = MaruxOS Genesis 시점)
libwnck-3.so.0 → /usr/lib64/libwnck-3.so.0  (target 없음 = dangling)
```

`/usr/lib64/`는 LFS 12.1 표준에 없음 (LFS는 `/usr/lib/`만 사용). 즉 누군가 Genesis 단계에서 다른 distro 컨벤션으로 symlink 박았다가 target 안 옮겨서 dangling 상태. **공식 ISO-BUILD-HISTORY에 기록되지 않은 잔재** — 이전 클로드가 실험한 plank/dock 시도의 화석.

또 `libgee-0.8.so.2.6.1` (Sept 2022 timestamp), `libplank.so.1.0.0` (Sept 2022), `libgnome-menu-3.so.0.0.1` (Jan 2023) 도 이미 박혀있었음. 이들은 .deb 파일의 원본 timestamp가 보존된 형태로 rootfs에 들어가 있었음 → 어느 시점 누군가 plank/Debian-deb 통합 시도했었다는 강력한 증거.

**수정**: `copy_safe()`에 dangling 자동 제거 + `cp -n` → `cp --update=none` (deprecated 경고 제거).

#### 23-B. 2차 시도: Transitive deps 사슬 — ldd 4개 missing

dangling 청소 후 재실행 → [6/6] ldd 검증에서 4개 missing:
```
libbamf3.so.2 => not found
libdbusmenu-gtk3.so.4 => not found
libdbusmenu-glib.so.4 => not found
libXRes.so.1 => not found
```

ldd 검증 게이트가 **정확히 자기 일 함**. 안 했으면 v3 ISO에 broken plank 박혀서 부팅 후 segfault.

**원인 분석**: 1차 정찰("plank의 직접 의존성 4개")만 본 것. 2차 의존성 (transitive — 직접 의존 lib들이 또 의존하는 lib)은 ldd로 catch해야 발견됨. 가설/web 정찰만으로는 transitive 사슬 끝까지 못 뽑음.

**수정 (4개 .deb 추가, 정확 버전 packages.debian.org 직접 fetch)**:
- `libbamf3-2_0.5.6+repack-1` — window-app 매칭
- `libdbusmenu-gtk3-4_18.10.20180917~bzr492+repack1-3` — dbus 메뉴 GTK3
- `libdbusmenu-glib4_18.10.20180917~bzr492+repack1-3` — dbus 메뉴 GLib
- `libxres1_1.2.1-1` — X resource extension

총 **9개 .deb**. copy 패턴도 prefix 리스트 (libplank/libgee/libwnck/libgnome-menu/libbamf/libdbusmenu/libXRes)로 확장.

#### 23-C. 3차 시도: 성공

```
[5/6] Installing to rootfs (additive only)...
    ⚠ exists, skipping (보호): libgee-0.8.so.2  (이미 있던 거)
    ⚠ exists, skipping (보호): libgnome-menu-3.so.0  (이미 있던 거)
    ⚠ exists, skipping (보호): libplank.so.1  (이미 있던 거)
    ⚠ exists, skipping (보호): libwnck-3.so.0  (이미 있던 거)
    ⚠ exists, skipping (보호): plank.desktop  (이미 있던 거)
    ... (실제로는 4개 신규 lib만 추가됨: bamf/dbusmenu × 2/XRes)
[6/6] ✓ Plank installed successfully
```

**핵심 발견**: 1.x rootfs에 plank의 1차 의존성은 이미 다 박혀있었음. **누락은 2차 의존성뿐**. 이전 클로드가 plank 시도하다 ldd 검증 게이트 없어서 본인이 누락된 것 모르고 마무리한 듯.

**일반화 인사이트**:

> **"이전 AI의 흔적"이 인프라가 되는 패턴**: 1.x 시리즈는 92회 빌드 동안 plank를 공식적으로 도입한 적 없다고 ISO-BUILD-HISTORY에 기록되어 있음. 그러나 rootfs에는 plank 라이브러리 + .desktop 파일 + dangling symlink가 잔류. **공식 기록과 실제 rootfs 상태가 어긋나는 이유**: 빌드 흐름이 rootfs를 누적 수정하는 방식이라, 어느 시점 실험한 게 commit 안 되고 rootfs에만 살아남으면 영원히 따라감. 6.7.4 vmlinuz가 5개월 살아남은 패턴과 동일 (rootfs는 빌드 결과의 무덤).

> **Transitive dependency = 정찰 한계**: web 정찰로 직접 의존성 파악 가능, 그러나 transitive(2차/3차) 사슬은 **실제 ldd 실행으로만** 끝까지 뽑힘. 정찰 단계에서 ldd 결과 시뮬레이션 불가. 게이트 첫 실행 = transitive 사슬 끝 노출 = 추가 .deb 후속 작업. **ldd 검증 게이트는 정찰의 빈틈을 메우는 안전망** — 없었으면 broken plank가 ISO에 박혀 부팅 후 segfault로 발견됐을 것.

> **3일차 hallucination/함정 카운트 11종 누적**:
> 10종(이전) + ⑪ Transitive deps 사슬 누락 (정찰 한계, ldd가 catch).
> 단, ⑪은 사실상 hallucination 아니라 "정찰 한계"의 합법적 결과. 게이트가 정상 동작 = 함정 안 만남. 9종은 진짜 함정/hallucination, ⑩~⑪은 게이트가 catch한 정찰 한계.

### 24. v3 부팅 결과 — Plank가 GSettings schema 못 찾고 SIGTRAP

**시각**: 2026-05-07 01:00 부팅 후

cooked-v3 빌드 성공 + 부팅 정상 + tint2 systray-only 모드 ✓ + idesk ✓. **그러나 Plank dock 안 보임.**

#### 진단 (xterm에서 plank 직접 실행)

```
[ERROR 01:04:31.849562] [Utils:42] GSettingsSchema 'net.launchpad.plank' not found
Trace/breakpoint trap
exit=133
```

exit 133 = 128+5 = **SIGTRAP**. plank가 자기 GSettings schema 못 찾아서 GLib fatal assert로 즉시 자살. 그래서 stdout/stderr 비어있는 silent exit처럼 보였음 (실제로는 GLib WARN/CRITICAL/ERROR 출력했지만 xinitrc의 `2>/dev/null`로 묻혔음).

부수적으로 [WARN] 다수:
- `XDG_SESSION_CLASS not set`
- `XDG_SESSION_DESKTOP/CURRENT_DESKTOP/DESKTOP_SESSION not set`
- `XDG_SESSION_TYPE not set`

이건 fatal 아니지만 cleanup 가치 있음 (plank가 데스크톱 컨텍스트 인식 + 다른 데스크톱 도구도 만족).

#### 원인 분석

install-plank.sh의 schema 처리 로직 약점 3가지:

1. **schema 복사 시 copy_safe의 "exists, skip" 보호 로직이 schema에도 적용** — rootfs에 이전 클로드 실험 잔재로 schema XML이 이미 박혀있으면 새 정확한 버전이 덮어쓰이지 않음. **schema는 strict force-overwrite 해야 했음.**
2. **chroot의 `glib-compile-schemas` 호출이 `2>/dev/null || true`** — 컴파일 실패가 silent. compiled cache가 stale이거나 plank schema 없는 상태로 빌드 완성.
3. **컴파일 후 검증 부재** — `gschemas.compiled` 안에 진짜 `net.launchpad.plank` 진입했는지 안 봄. Verify gate 한 층 더 필요.

또: install-plank.sh의 early-exit 로직 (`/usr/bin/plank` 있으면 즉시 종료)이 **schema 결손을 catch 안 함** → 사용자가 build script 다시 돌려도 schema 미배포 상태 유지.

#### 수정 (cooked-v4)

`scripts/install-plank.sh`:
- **schema strict force-overwrite** — copy_safe 우회, `cp -af`로 강제 덮어쓰기
- **schema 배포 직후 검증** (`PLANK_SCHEMA` 파일 존재 확인, 없으면 abort)
- **chroot glib-compile-schemas strict mode** — exit code 체크, 출력 노출, silent fail 차단
- **compiled cache 검증** — `strings gschemas.compiled | grep net.launchpad.plank`로 진짜 등록됐는지 확인, 없으면 abort
- **early-exit 강화** — binary + schema XML + compiled cache + cache 안 plank entry까지 모두 OK여야 skip. 하나라도 결손이면 재배포 (self-healing)

`config/xinitrc`:
- **XDG 메타데이터 export** (XDG_SESSION_TYPE=x11, CLASS=user, DESKTOP/CURRENT_DESKTOP/DESKTOP_SESSION=MaruxOS)
- XDG_DATA_DIRS, XDG_CONFIG_DIRS도 명시 (다른 도구들 만족)

`scripts/build-2.0.0-cooked-v4.sh` 신규:
- v3의 모든 변경 + 위 fix 통합
- 헤더에 v4 변경 명시

**일반화 인사이트**:

> **Schema 같은 "보이지 않는 의존성"은 ldd가 못 잡는다**. ldd는 binary linkage만 검증 — runtime에 의존하는 GSettings/GIcons/glib resources는 별개. **검증 게이트를 "binary present + ldd clean + schema compiled + schema in cache" 4단으로 확장해야 cover**. 본 사례는 schema 4단 마지막 (cache 검증)이 빠져서 다 통과한 척하고 부팅 후 SIGTRAP. **검증 게이트는 layer가 깊을수록 더 깊은 검증이 필요**.

> **`2>/dev/null || true` 패턴은 silent fail의 전형**: 디버그 시 stdout 정리 위해 자주 쓰지만 **production 스크립트에선 critical step에 절대 쓰지 말 것**. 본 사례는 chroot glib-compile-schemas 실패가 묻혔음 → ISO 빌드 success 표시 → 부팅 후 자살. **silent fail은 fail보다 더 나쁘다** — fail이라도 즉시 알면 고칠 수 있지만 silent는 누적되다 사용자 체감으로 발견됨 (이번엔 "plank 안 떠요" 시점).

> **3일차 hallucination/함정 카운트 12종 누적**:
> 11종(이전) + ⑫ Plank GSettings schema strict 처리 미흡 (`2>/dev/null || true` + copy_safe 보호 로직 + 검증 부재 3겹).
> 이건 ⑨ wget -q + ⑫ glib-compile-schemas 2>/dev/null 같은 카테고리 — **silent fail 패턴 2회째**. 발표 자료 슬라이드 후보: "조용한 옵션이 만드는 가장 큰 사고들 — wget -q, 2>/dev/null, set -e의 묘한 조합".

#### 사용자 깨고 와서 할 일

```bash
# 단순히 v4 빌드 돌리면 됨 (install-plank.sh이 self-healing이라 schema 자동 fix)
sudo bash /mnt/c/Users/Administrator/Desktop/MaruxOS/scripts/build-2.0.0-cooked-v4.sh
```

기대 동작:
1. install-plank.sh이 plank binary 있어도 schema 결손 detect → 재배포 + force compile + cache 검증
2. 검증 게이트 모두 통과해야 빌드 진행
3. ISO에 schema 정상 박혀서 부팅 시 plank가 init 가능

**주의**: install-plank.sh이 fail하면 build script가 strict abort. 메시지 보고 추가 fix 필요할 수 있음 (예: schema XML 형식 자체에 문제 있다거나).

---

### 25. v4 부팅 — Plank 여전히 안 보임 (검증 게이트 통과했는데 runtime fail)

**시각**: 2026-05-07 10:06 KST 부팅 후

cooked-v4 ISO 빌드 성공 (install-plank.sh strict 검증 게이트 통과 = abort 없이 빌드 완료).

**그러나 부팅 후 plank dock 여전히 안 보임.** 화면 상태:
- 좌측 상단에 idesk 아이콘 3개 (Terminal/Files/Firefox) ✓
- 하단 우측에 tint2 systray-only 패널 (10:06 / 05-07 (목)) ✓
- **하단 중앙에 plank dock 부재** ✗

**의미**: install-plank.sh의 4단 자가치유 검증 게이트(binary + schema XML + compiled cache + cache 안 plank entry)는 모두 통과했음. 즉 정적 의미에선 plank가 "정상 설치"됐다고 판단됨. 그런데 런타임에 dock이 안 뜸.

**가능성 (사용자 진단 명령 결과 대기 중)**:

1. **검증 게이트 false positive** — schema XML 또는 compiled cache가 정적 검사는 통과했는데 plank가 런타임에 사용하는 다른 path/format 요구 (예: 별도 priority hint, 권한 비트 등)
2. **XDG 변수 부작용** — v4에서 새로 추가한 XDG_SESSION_DESKTOP=MaruxOS 등이 plank가 모르는 desktop 이름이라 internal 처리 분기에서 abort
3. **xinitrc plank 호출 자체 실패** — 새 환경변수 export 흐름이 plank의 dbus connect 시점과 충돌
4. **invisible plank** — 프로세스 떠있는데 위치/투명도/크기 문제로 화면에 안 뜸

진단 명령:
```bash
ps aux | grep plank | grep -v grep
plank 2>&1 | head -30
strings /usr/share/glib-2.0/schemas/gschemas.compiled | grep launchpad.plank
grep -A3 plank /etc/X11/xinit/xinitrc
```

**일반화 인사이트 (선제)**:

> **검증 게이트 통과 ≠ 런타임 작동**. 정적 검증(file present, format valid, registered in cache)은 binary가 *시작 가능한지*까지만 보증. 런타임 실패는 검증 게이트 너머의 environment / dependency / behavior 영역. **검증 게이트는 "잘못된 빌드를 잡는 게이트"이지 "올바른 빌드를 보장하는 게이트"가 아니다**. 후자는 부팅 + 동작 검증으로만 가능 (Phase D 의미).

> **iteration의 점진성**: v3 발견 → v4 schema strict fix → v4 같은 증상 → 새 가설 필요. 1.x v37~v54 패턴 재현 — 각 v 가 한 layer씩 벗긴다. 본 사례는 **schema layer는 통과했고 그 다음 layer 노출**. 발표 자료에 좋은 챕터: "검증 게이트는 양파처럼 layer가 있다. 한 겹 벗기면 다음 겹이 보인다."

> **3일차 hallucination/함정 카운트 12종 + α (조사 중)**:
> 12종 누적 + 새 함정 1종 (TBD: schema는 통과했는데 plank 런타임 실패의 진짜 원인). 이게 정찰 한계인지 hallucination인지 함정인지는 plank 실행 출력 보고 분류.

**다음 액션**: 사용자 plank 진단 결과 받고 v5 분기 결정.

---

### 26. Plank schema 진짜 원인 발견 — `libplank-common` 별도 패키지 (2026-06-08)

**시각**: 2026-06-08 (Day 4 — OSS Korea 합격 후 첫 디버그)

**문제 재현**: cooked-v5 부팅. tint2 풀 패널 ✓, xterm 한국어 ✓. 하지만 plank는 여전히 SIGTRAP:
```
[ERROR] [Utils:42] GSettingsSchema 'net.launchpad.plank' not found
Trace/breakpoint trap
```

v4의 schema strict deploy 강화에도 불구하고 같은 에러. "왜 strict 게이트가 안 잡았나"가 진짜 질문.

#### 단계적 정찰 (4단)

게스트 안에서 상태 확인:
1. `ls /usr/share/glib-2.0/schemas/ | grep plank` → empty (schema XML 0개)
2. `strings gschemas.compiled | grep -c launchpad.plank` → 0
3. `env | grep XDG_DATA` → `XDG_DATA_DIRS=/usr/local/share:/usr/share` ✓

**결론**: schema XML 자체가 rootfs에 없음. install-plank.sh이 schema를 못 박았다.

빌드 호스트(WSL)에서 plank.deb 안에 schema 있는지 직접 확인:
```bash
find /tmp/plank-deb-check/ -name "*.xml"
→ ./usr/share/metainfo/plank.appdata.xml   # AppStream만, gschema 없음
```

libplank1.deb도 확인 → 0건.

#### 진짜 원인 발견

`packages.debian.org/source/bookworm/plank` 직접 fetch → plank source package가 만드는 **4개 binary**:
1. plank
2. libplank1
3. libplank-dev
4. libplank-doc
5. **`libplank-common`** ← "shared files" — schema 1순위 후보

libplank-common 받아서 확인:
```bash
ar x libplank-common_0.11.89-4_all.deb && tar -xf data.tar.*
find . -name "*.gschema.xml"
→ ./usr/share/glib-2.0/schemas/net.launchpad.plank.gschema.xml ✓
```

**찾음.** plank의 GSettings schema는 `libplank-common.deb` (architecture-independent, _all.deb)에 박혀있고, plank/libplank1엔 없음.

#### 원인 분석 (왜 발견 못했나)

install-plank.sh 작성 시 plank 의존성을 정찰할 때:
- 1차: plank, libplank1, libgee, libwnck, libgnome-menu (5개)
- 2차 (ldd가 catch): bamf, dbusmenu × 2, libxres (4개 추가)

**둘 다 binary linkage 또는 직접적 runtime 의존성 정찰**. GSettings schema 같은 **데이터 파일 의존성**은 ldd도 안 잡고 정찰에서도 누락. Debian이 schema를 *별도 패키지로 분리하는 관행*을 모르고 plank.deb에 다 있을 거라 가정.

#### 수정 (v6)

`scripts/install-plank.sh`:
- DEBS 배열에 `p/plank/libplank-common_0.11.89-4_all.deb` 추가 (총 9 → 10 .deb)
- schema 스캔 로직은 그대로 — libplank-common 추출본의 `usr/share/glib-2.0/schemas/net.launchpad.plank.gschema.xml`을 자동 매칭
- arch-independent (_all.deb) 형식 처리 OK (extract는 arch 무관)

`scripts/build-2.0.0-cooked-v6.sh`:
- 헤더에 v5 → v6 변경 명시
- 그 외 v5 흐름 동일 (tint2 풀 panel 유지)

#### v5/v6 부팅 검증의 양면성 사건

**v5 부팅 시 발견됐어야 한다**:
v4에 schema strict abort 로직이 있는데도 v5 빌드가 통과한 이유:
- install-plank.sh의 schema strict 검증 (`[ -f $PLANK_SCHEMA ] || exit 1`)이 *deploy 직후* 검사
- 그러나 schema가 어디서도 deploy되지 않으면 deploy 후 검사 시점에 X → abort
- **실제로 v5 빌드 시 install-plank.sh이 schema not found로 abort 했을지 안 했을지 모름**
- 사용자가 ISO 받아서 부팅했다 = build script 통과 = install-plank.sh이 abort 안 했음
- 가능성: install-plank.sh의 early-exit이 binary만 있으면 skip 했을 수도 (4단 체크 중 다른 게 false라 통과해야 하는데 어딘가 잘못)

→ install-plank.sh 자체 디버그 별도 필요. 일단 v6는 schema deploy 보장.

#### 일반화 인사이트

> **데이터 의존성 ≠ binary 의존성**. ldd는 .so linkage만 본다. GSettings schema, icon themes, glib resources, AppStream metadata 같은 "데이터 파일"은 어디서 오는지 ldd로 안 보임. Debian 같은 distro는 데이터를 *별도 패키지로 분리*하는 관행이 많은데 (libplank-common, libfoo-data, foo-common 등), 정찰 단계에서 이걸 알아야 누락 안 함. **"binary 정찰 → ldd 정찰 → 데이터 정찰"의 3단 정찰이 표준이 되어야**.

> **검증 게이트의 "어디서 발견됐어야"의 흥미로운 케이스**. install-plank.sh의 "schema deploy 후 검증" 게이트는 *deploy를 시도*한 결과를 본다. deploy를 *시도조차* 안 했으면(코드 흐름 어딘가에서 schema source 못 찾으면) deploy 후 검증 시점에 schema 없음 → abort. 정상 동작. 그런데 v5가 빌드 통과 = 어딘가 통과로 빠짐 = 추가 디버그 필요. 게이트가 의도된 경로 모두 cover 못한다는 것 자체가 메타-함정.

> **4일차 hallucination/함정 카운트 13종 누적**:
> 12종(이전) + ⑬ plank schema 위치 추측 (plank.deb 가정 → 실제 libplank-common).
> 정찰 한계 카테고리 (⑪ transitive deps와 유사) — AI가 distro의 패키징 관행에 약함. plank source package가 4개 binary로 분할되는 걸 직접 확인 안 하고 "plank.deb면 다 있을 것"으로 가정.

> **OSS Korea 발표의 새 챕터**: "GSettings schema의 분리된 패키지가 만든 4단 의존성 추적 — `binary → ldd → 데이터 → distro 관행`까지 정찰해야 ldd 클린한 plank가 부팅에서 SIGTRAP하는 이유 잡힘." 청중에 강한 케이스 스터디.

---

### 27. v6 빌드의 미스터리 — 같은 스크립트, 다른 결과 (2026-06-08)

**시각**: 2026-06-08, Section 26 직후 v6 빌드 결과 확인

v6 ISO (Jun 8 01:37 빌드) 부팅 후 schema 여전히 0. rootfs도 검사:
```
ls /home/.../rootfs-lfs/usr/share/glib-2.0/schemas/ | grep plank → empty
strings /home/.../rootfs-lfs/.../gschemas.compiled | grep -c launchpad.plank → 0
```

즉 **v6 ISO 빌드 시점에 install-plank.sh이 schema를 안 박았다.**

그러나 같은 install-plank.sh을 **단독 실행하니 정상 작동**:
```
⚠ Plank binary exists but schema/compile 결손 발견 → 재배포 진행
[3/6] Downloading .deb packages... (10개 모두 성공, libplank-common 포함)
[4/6] Extracting .deb packages... (10개)
[5/6] ✓ schema deployed (force): net.launchpad.plank.gschema.xml
[6/6] ✓ Plank schema compiled and registered (net.launchpad.plank)
✓ Plank installed successfully
```

#### 풀리지 않은 미스터리

같은 install-plank.sh 파일이:
- **v6 빌드 시 schema 안 박음** (rootfs 증거)
- **단독 실행 시 schema 정상 박음**

가능성 (검증 미완):
1. v6 build script가 install-plank.sh을 호출 안 했음 (skip 분기 어디선가)
2. v6 빌드 시점에 install-plank.sh의 libplank-common 추가 *전* 버전이 호출됨 (timing/cache?) — 단 strict check 통과 못함, abort 했어야
3. install-plank.sh의 early-exit이 v6 빌드 시점엔 통과 (4단 중 cache 체크가 stale state로 잘못 true 반환) — 단 단독 실행 시엔 fail. 같은 함수가 다른 결과?
4. squashfs 생성이 schema 파일 제외 (mksquashfs `-e boot` 외 다른 exclusion?)

각 가설마다 추가 검증 필요. 발표 자료에 *"같은 스크립트, 다른 결과"*는 강한 모먼트.

#### 실용 해결 (미스터리 별개)

지금 install-plank.sh 단독 실행으로 rootfs에 schema 정상 박힘. 이 상태에서 v6 ISO 재빌드:
- install-plank.sh 4단 early-exit 통과 (binary + schema XML + compiled + cache 다 OK) → full install skip
- squashfs/ISO만 새로 생성 → schema 들어간 ISO

부팅 후 plank 떠야 함. 그제서야 v6 의도와 ISO가 일치.

#### 일반화 인사이트

> **재현 불가능한 차이는 가장 위험한 버그 카테고리**. "단독 실행은 됨, build script 호출은 안 됨" → race / 환경 / 캐싱 / silent skip 어디선가. 한 번 봐서 안 보이면 다음 빌드에서 또 만남. **차이를 발견한 시점에 미스터리를 풀거나 최소한 가설 기록**해두지 않으면 영원히 따라옴 (1.x의 6.7.4 5개월 잠재처럼).

> **건강한 회피 — 시간 우선 처리**: 발표 일정상 미스터리 풀기 < 진전. rootfs 상태가 OK인 상태에서 ISO 재빌드 → 부팅 확인 우선. 미스터리는 plank 떠서 발표 자료 안정화한 후 별도 디버그. **인디 개발자의 데드라인 트레이드오프** — 완벽한 이해 vs 작동하는 시스템. 둘 다 원하면 한쪽 미루는 게 정답.

> **4일차 hallucination/함정 카운트 14종 누적**:
> 13종(이전) + ⑭ 재현 불가능한 빌드 vs 단독 실행 차이 (미스터리, 미해결).

---

### 28. v7 결과 + Plank 롤백 결정 (2026-06-19)

**시각**: 2026-06-19, 학사 종료 + 여름 본격 작업 진입 직전

v7 빌드 후 부팅 결과:
- **Plank 바이너리 실행 ✓** (SIGTRAP 없음 — schema 정복 완료)
- **dockitem 파일 위치 OK** (`/root/.config/plank/dock1/launchers/`에 xterm/mc/firefox 3개)
- **그러나 dock 빈 박스로 표시** — 아이콘 없음

**원인**: Plank는 GSettings의 `dock-items` 키를 우선 참조. memconf 백엔드에서 우리가 박은 `settings` 파일과 별개로 dock-items 키가 빈 리스트 default. 게스트에서 `gsettings set net.launchpad.plank.dock.settings:/net/launchpad/plank/docks/dock1/ dock-items "[...]"` 시도 — **실패 (아이콘 안 뜸)**. 더 깊은 디버그 필요 (relocatable schema + memconf 결합의 특이성).

**결정 — Plank 2.0.x로 deferred (v8 rollback)**:

리스크/가치 분석:
- ARM64 마감 (8/10 슬라이드, 7/1~7/15 본격 작업) 임박
- Plank dock-items GSettings 디버그 = 1~2시간 ~ 수일 (재현 불가 위험)
- 발표 임팩트: **"Plank schema 정복 + 14종 함정 일지"가 이미 핵심 챕터**. dock에 아이콘 3개 떠있는지 여부는 발표 임팩트와 무관
- 1.x v37~v54 패턴: 한 번에 다 안 되면 다음 패치로

**v8 변경사항**:
- Plank 미설치 (`install-plank.sh` 호출 안 함)
- tint2 풀 패널 (1.x 검증된 안정 layout)
- 잔재 청소 ([7.5]에서 rootfs의 기존 plank 흔적 제거)
- `install-plank.sh`, `config/plank/`, `config/tint2/tint2rc-systray` 모두 **frozen artifact로 보존** (2.0.x 부활 시 재사용)
- xinitrc plank 조건부 시작 블록은 유지 (`/usr/bin/plank` 없으면 자동 skip)

**일반화 인사이트**:

> **deliverable과 시연 가능성의 분리**. v7까지의 작업으로 *"Plank 정복" 발표 챕터*는 이미 완성 — schema/transitive deps/libplank-common/14종 함정 등. dock에 아이콘 떠있는지는 별개 axis. *"기술 정복"과 "시연 polish"는 분리할 수 있는 두 axis*. 인디 개발자가 둘 다 만지면 발표 일정 위험. 정복은 발표하고 polish는 후속 패치.

> **롤백 결정의 정신 위생**: "마무리 안친 상태"의 심리적 부담 vs ARM64 가치 비교. 롤백을 *실패*가 아닌 *단계적 deliverable* 으로 명시적 framing하면 부담 사라짐. 1.2.0 → 1.2.1 패턴 그대로 — 메이저는 큰 변화, 마이너는 폴리시.

> **4일차 hallucination/함정 카운트 14종 → 종결 (5일차 ARM64 fresh start로 누적 리셋)**:
> Plank dock-items GSettings/memconf 결합 이슈는 ⑮로 카운트하기보다 *"deferred unknown"*로 명시 — 더 디버그하면 풀릴 가능성 충분, 단지 시간 가치 안 맞아 보류. ARM64 fresh start = 새 함정 카테고리(Pi 4B 부팅, U-Boot, RPi 펌웨어, V3D 등) 진입.

---

## 외부 데드라인 확정 — OSS Korea 2026 합격 (2026-06-06)

**Linux Foundation Open Source Summit Korea 2026** CFP 합격.
- 세션: *"The Era of Vibe Coding: Why High-Skill Engineers are More Critical Than Ever"*
- Track: Open AI & Data — AI Agents
- 일정: 2026-08-11~12 (서울)
- 의미: **한국 최초 10대 (17세) OSS Summit 국제 무대 연사**

이 일정이 모든 작업의 외부 데드라인이 됨:

| 일정 | 마감 |
|------|------|
| 6/19 | Speaker Registration (voucher OSSKO26SPK) |
| 7/14 | AV Needs (데모 장비 결정) |
| **8/10** | **🔥 슬라이드 제출** |
| **8/11 14:15** | **🎤 본 발표 — 그랜드볼룸 (Grand Ballroom) 확정** → ✅ 발표 완료 (2026-08-11) |
| 8/12 | 둘째 날 |

**실질 작업 마감 = 8/10 슬라이드.** 그 전에 ARM64 완성해야 *Pi 4B에서 실제 부팅 데모 슬라이드* 한 장 만들 수 있음.

### 보수적 로드맵 (학사 일정 반영, 정정판)

| 구간 | 가용 시간 | 작업 |
|------|----------|------|
| 지금 ~ 6/23 (~16일) | **2-3h/일 + 쉬는시간** ≒ 30-50h | Plank UI 마무리 (schema → jgmenu → 시스템 버튼 → 테마) |
| **6/24~6/30 (기말)** | **0** | 작업 정지 |
| 7/1~7/15 (2주) | full | ARM64 Pi 4B 부팅 (mainline 6.18.26 + 통합 arm64 defconfig + Pi4 builtin 강제 + RPi 펌웨어 + SD/USB 이미지) |
| 7/15~7/25 | full | 안정화 + 1.x 자산 ARM64 ABI 재빌드 (ibus-hangul, idesk, Plank — x86_64 산출물은 못 씀) |
| 7/25~8/5 | full | 발표 슬라이드 초안 |
| ~8/10 | 마지막 | 슬라이드 최종 + 리허설 |
| 8/11~12 | 본방 | OSS Korea 발표 |

**시간 현실**: 6/23까지 30-50시간 → 거의 Plank UI 완성에 다 씀. ARM64 정찰도 7월 첫 주에 같이 시작.
**Pi 4B 8GB ARM64 부팅을 7월 2주 안에 안정화 = 빠듯하지만 가능**. 정찰 결과 mainline 6.18에서 V3D 가속까지 작동 확인됐고, RPi 포크 안 써도 됨 (Section 1). 본 보수적 일정의 핵심 가정.

### 잠시 멈춘 작업

UI 작업(Plank/jgmenu) 마무리는 ARM64 진입 전 우선 처리. 단 Plank가 GSettings schema 문제로 v4까지 dock 안 뜨는 상태 (Section 25). 이 디버그가 ARM64 작업 시작 가능한 시점을 결정.

**인사이트**:

> **외부 데드라인은 scope를 절제한다**. 인디 개발자에게 무한 정제(2.0.0에 glibc까지 묶기 등)는 자기 동기로만 멈추기 어려운데, 발표 일정 같은 외부 압력은 *명확한 절제선*을 그어줌. 본 프로젝트가 glibc를 2.1.0으로 분리하기로 한 결정도 같은 원리 — 외부 시계와 scope를 묶으면 자기 규율이 자동화됨.

---

## Section 29: ARM64 Genesis — 2.0.0-cooked-arm64 트랙 진입 (2026-06-19)

x86_64 Plank rollback v8 결정 직후, **ARM64 / Pi 4B 8GB 포팅 트랙** 공식 개시. 새 브랜치 `2.0.0-cooked-arm64` 분기.

### 결정 사항 (요약 — 상세 게이트는 CLAUDE.md "ARM64 트랙" 섹션 참조)

| 항목 | 결정 |
|------|------|
| 빌드 방식 | A — cross-compile (aarch64-linux-gnu) on x86_64 WSL2 |
| 커널 | A — **mainline 6.18.26 LTS + 통합 arm64 defconfig + Pi4 builtin 강제** (RPi fork 안 씀. ⚠️ bcm2711_defconfig은 mainline에 없음 — 함정 #1) |
| 출력 포맷 | hybrid disk image (.img.xz, 가짜 .iso 확장자 OK) — Pi가 ISO9660 못 부팅 |
| rootfs | A — **CLFS from scratch** ("World's First 100% LLM OS" 정체성 유지) |
| 부트로더 | A — start4.elf 직접 kernel8.img 로드. U-Boot/GRUB 단계 없음 |
| Installer | Phase 2 — **Qt5 GUI (`marux-installer`)**. TUI 안 함 (사용자 결정 2026-06-19) |
| 브랜치 | `2.0.0-cooked-arm64` (작업), 2.0.0 출시 시 main에 머지 |
| 빌드 스크립트 | `build-2.0.0-cooked-arm64-vN.sh` 새 시리즈 |
| 디렉토리 | `/home/$USER/MaruxOS-arm64/` — **x86_64와 완전 분리** |
| Scope | Full (X.org + Openbox + ibus-hangul + Firefox + installer) |
| glibc | 2.38 유지 (2.x.x에서 별도 업그레이드 트랙) |
| Pi 4B 8GB 하드웨어 | ✓ 손에 있음 (사용자 확인 2026-06-19), SD/HDMI/USB-C 5V3A/TTL-USB 어댑터 ✓ |

### Phase 분리 (8/10 OSS Korea 슬라이드 마감 고려)

| Phase | 범위 | 마감 목표 |
|-------|------|----------|
| **Phase 1 (MVP)** | Live boot까지: 커널 + rootfs + X.org + Openbox + ibus-hangul + Firefox | 7월 2주 (7/14 AV Needs 마감 전) |
| **Phase 2** | Qt5 cross-build + `marux-installer` GUI + QTerminal (보너스) | 8/5 전 (슬라이드 초안 전) |
| 2.0.x 패치 | mc → PCManFM-Qt, Plank 재작업, glibc 2.1.0 | 발표 후 |

### Hallucination 방지 — 디렉토리 분리 게이트

**가장 큰 risk**: AI(나)가 `MaruxOS/` (x86_64 빌드)와 `MaruxOS-arm64/` (ARM64 빌드) 디렉토리를 헷갈리면 5개월 hallucination 재현 가능. → CLAUDE.md에 4종 게이트 박음:
1. 빌드 루트 PWD 검증 (`/home/$USER/MaruxOS-arm64`*)
2. `aarch64-linux-gnu-gcc` `-dumpmachine` aarch64 검증
3. `OUTPUT_NAME`에 `arm64` 포함 검증
4. `ARCH=arm64` 명시 검증

추가로 빌드 스크립트가 x86_64 디렉토리(`/MaruxOS/build*`)에서 실행되면 즉시 abort.

### 시작 지점 — Stage 0: cross-toolchain 설치

```bash
# WSL2 Ubuntu에서:
sudo apt update
sudo apt install -y \
    gcc-aarch64-linux-gnu \
    g++-aarch64-linux-gnu \
    binutils-aarch64-linux-gnu \
    qemu-user-static \
    qemu-system-arm \
    libc6-arm64-cross \
    libc6-dev-arm64-cross

# 검증
aarch64-linux-gnu-gcc --version
aarch64-linux-gnu-gcc -dumpmachine   # → aarch64-linux-gnu

# 빌드 루트 생성
mkdir -p /home/$USER/MaruxOS-arm64/{toolchain,kernel,firmware,rootfs-clfs-arm64,iso-build,output}
ls -la /home/$USER/MaruxOS-arm64/
```

이 명령들은 **사용자가 직접 WSL에서 실행**. 결과 캡처해서 다음 단계 진입.

### 인사이트

> **트랙 분리 = Hallucination 격리**. 1.x 시리즈에서 단일 트랙·단일 디렉토리에 모든 결정이 응축돼서, 한 곳의 환각이 5개월 살아남았음. ARM64를 디렉토리·브랜치·빌드 스크립트·산출물명·게이트 4단계로 분리하면, 환각이 발생해도 트랙 안에 갇혀 다른 트랙으로 번지지 못함. **물리적 분리가 가장 싼 검증.**

> **MVP → Full 단계화의 발표 가치**. Phase 1만으로도 "ARM64 부팅 데모" 슬라이드 한 장 가능. Phase 2의 GUI installer는 보너스. 외부 데드라인 압력 아래선 *부분 deliverable*도 발표 자산이 됨. v8 Plank rollback도 같은 정신 — *완성하지 못한 부분*과 *발표할 부분*을 분리할 수 있어야 함.

> **Qt 도입 시점의 trade-off**. Qt5 cross-build for ARM64는 4-6시간 빌드. Phase 1에 박으면 디버깅 표면 폭증. Phase 2에 미루면 Live MVP 검증이 깔끔해짐. *기술적 의존성 사슬은 늦게 도입할수록 좋다* — 단, 로드맵이 결국 가야 하는 방향이라면 ARM64 트랙에서 도입하는 것 자체는 합리적 (QTerminal/PCManFM-Qt로 재사용).

> **발표 자료로서의 Kernel-Update-Log 가치 재평가**: OSS Korea = Linux Foundation 국제 무대 = 청중이 더 엄격. 본 일지의 raw 형태(욕설 포함, 시간순, 잘못한 가설 포함)가 가공된 corporate post-mortem보다 *발표 청중에게 더 강함* — academia/industry 둘 다 sanitized 자료가 흔하니까. 일지의 "정직성"이 진짜 발표 자산.

---

## Section 30 — 2026-07-29: 공용 rc.xml 잠복 버그 픽스 (ARM64발 → x86 소급)

**ARM64 v15 실기기 첫 창겹침 테스트에서 발각된 x86 시절부터의 잠복 버그**: `config/openbox/rc.xml`에 **Client(창 내용 영역) 컨텍스트 마우스바인드가 아예 없어서 클릭으로 창 전환/포커스가 불가능**했음 (Alt-Tab만 동작). 1.x~2.0.0 내내 창을 겹쳐 쓰는 테스트가 없어서 아무도 몰랐음.

- **픽스**: `config/openbox/rc.xml`에 `<context name="Client">` — Left/Middle/Right Press → Focus+Raise. **공용 자산이라 x86 다음 빌드에 자동 반영** (ARM64는 v16부터).
- **의미**: "실기기 멀티태스킹 테스트가 처음 이뤄진 순간 드러난 구성 결함" — 검증 커버리지의 사각지대 사례. 상세 = ARM64-Update-Log "2026-07-29 (2)".

---

## Section 31 — 2026-08-25: 전 문서 정합성 스윕 (v27 기준 최신화)

**계기**: 사용자 질문 "현재 문서 최신화되었어?" — **주장 대신 실측**으로 답하기로 하고 전 `.md`를 grep 스윕했다.

**적발된 구멍 2군데(핵심)**
1. **`ARM64-Update-Log.md`에 v27 완성 기록 자체가 없었다.** 배치 F 섹션이 "v27 빌드: 게이트 신설"이라는 *계획* 문장으로 끝나 있었고, 실제 SHA `bdf1f50e…`가 어디에도 없었다. **CLAUDE.md가 "최신 핸드오프 = ARM64 로그 맨 아래"라고 지목하는 문서**라 다음 세션이 v26에서 끊긴 상태로 시작할 뻔했다. → v27 완성 + 핸드오프 섹션 신설(참고자료 부록 앞).
2. **`CLAUDE.md`/`AGENTS.md`의 "현재" 문단이 v17 시점 그대로** — "다음 = ②WiFi → ③QTerminal → ④PCManFM-Qt"라고 적혀 있었으나 그 4개가 전부 완료된 상태. → v27/4-4 완주 기준으로 재작성 + 로드맵 1~4에 ✅ 완료 주석.

**함께 정정한 파생 스테일**
- `MEMORY.md`: ▶다음(v26 검증 → **v27 검증**), 로드맵 8항목 전부 완료 표기, "ARM64 파일매니저도 mc" → PCManFM-Qt, tint2 은퇴 반영
- `CHANGELOG.md`: 2.0.0 ARM64 섹션이 v17에서 끊겨 있었음 → **v17~v27 항목 8건 추가**(WiFi/FWSUP, 퀵설정 GUI, 한영 표시, PARTUUID, 음량, QTerminal, PCManFM-Qt), "현재 이미지 = v16" 정정
- `README.md`: 소프트웨어 표를 **아키텍처별 표기**로(터미널 x86=xterm / ARM64=QTerminal, 파일매니저 x86=mc / ARM64=PCManFM-Qt), 로드맵 2건 `[ ]`→`[x]`
- `FAQ.md` / `docs/FAQ.md`: "PCManFM-Qt는 예정" → 완료. docs/FAQ의 Pi 문단(현재 이미지 v16, 남은 로드맵)을 v27 기준으로 교체, Terminal 행 신설
- `docs/arm64/03-ASSET-REFERENCE.md`: 이미지 섹션 v16 → **v27 실측**, 레이아웃 "7 GB raw" → **27 GiB sparse**(v20 이후 실제값), 상태표에 WiFi/GUI/한영/부팅/터미널/파일매니저 행 추가, **§13 배치 W/Q/F 자산 시트 신설**(실측 크기)

**실측 검증**: `output/MaruxOS-2.0.0-arm64.img.xz` 디스크 파일 · 사이드카 `.sha256` · 문서 기재값 **3자 일치 확인** — `bdf1f50e8735ce5b0df5a43f44b7c1b789269e5de799d03f84e41713b4b20190`, 3,370,004,520 B.

**보존한 것 (frozen artifact 원칙)**: ARM64 로그 중간의 옛 "다음 단계" 블록, 04-TALK-NARRATIVE(8/11 발표 시점 서사), CHANGELOG 옛 entry, ISO-BUILD-HISTORY 옛 항목은 그대로 두고 **삭제 대신 날짜 붙인 정정 주석**으로 처리(예: CLAUDE.md "mc → PCManFM-Qt는 2.0.x 패치" 줄은 취소선 + 뒤집힌 경위 주석).

**교훈**: *빌드 완료 알림과 문서 기록은 별개다.* v27은 ISO-BUILD-HISTORY와 MEMORY에는 들어갔지만 **핸드오프로 지정된 문서에는 빠져 있었다** — "여러 곳에 적었다"가 "지정된 곳에 적었다"를 보장하지 않는다. 앞으로 빌드 완료 처리의 마지막 단계는 **CLAUDE.md가 핸드오프로 지목하는 문서에 SHA가 들어갔는지 grep 확인**.

---

## Section 32 — 2026-08-27: 라이선스 전면 재점검 (출품 직전) — "Public Domain" → **The Unlicense + 구성 요소별 라이선스**

**계기**: 출품 문서 작성 중 사용자 요청 "라이선스 다 꼼꼼히 다시 봐봐, Openbox 같은 애들 라이선스 존중하면서".

### 발견한 문제
1. **범위 오류**: LICENSE/README가 "MaruxOS는 Public Domain, 제한 없음"이라 선언 — 배포 *이미지*는 GPL 커널·LGPL glibc/Qt·MPL Firefox 등 수백 프로젝트의 **집합체**라 이 주장은 성립하지 않는다. 우리가 포기할 수 있는 건 *우리 저작물*(스크립트·config·문서·quicksettings·자체 아이콘)뿐.
2. **법적 효력**: 한국 저작권법엔 퍼블릭 도메인 선언 규정이 없음 → **The Unlicense**(퍼블릭 도메인 헌정 + 폴백, OSI 승인)로 전환 — 처음 Unlicense로 썼다가 사용자 확인 후 OSI 승인인 Unlicense로 확정. AI 생성물의 저작권이 불인정되는 흐름과도 정합(주장 대신 포기).
3. **소스 제공 의무**: GPL 바이너리 배포 시 대응 소스 필요. 우리 수정이 스크립트 안 `sed` 조각으로 흩어져 "수정된 소스"로 보기 애매 → `patches/*.patch`(실제 트리 diff) + `SOURCES.md`(tarball·SHA) + LICENSE §3 서면 제안.
4. **펌웨어 재배포 조건**: Broadcom 부트 펌웨어·Cypress WiFi 펌웨어는 "라이선스 파일 동봉 + 무수정 + Pi 기기용"이 허용 조건인데 **`LICENCE.*` 파일이 이미지에 없었다** ❌.
5. **라이선스 텍스트 미동봉**: `/usr/share/licenses/` 부재 — MPL/LGPL/BSD/OFL 고지 의무.
6. **디자이너 자산**: tuna27 배경화면·아이콘은 디자이너 저작권 → Unlicense/CC-BY 동의 확인 필요(미확인 상태에선 헌정에서 제외 명시).
7. 잔재: LICENSE의 "LFS 12.1" → 12.0.

### 조치 (빌드 없이 문서/자산 — 2026-08-27 새벽)
- `LICENSE` 전면 재작성: §1 Unlicense 범위 명시 / §2 비적용 대상(서드파티·펌웨어·디자이너 자산·상표) / §3 **대응 소스 서면 제안(3년)** / §4 Unlicense 원문(unlicense.org 실물)
- 신규 `THIRD-PARTY-LICENSES.md`: 계층별 구성 요소 → 버전 → 라이선스 → 우리 패치 여부(⚙️) → 준수 방식 표
- 신규 `patches/README.md` + `scripts/gen-sources-and-patches-arm64.sh`(SOURCES.md 생성 · 실제 트리 diff로 .patch 추출 · 라이선스 텍스트 수집)
- `config/licenses/`: UNLICENSE, GPL-2/3, LGPL-2.1/3, MPL-2.0, GCC Runtime Exception, OFL-1.1, Info-ZIP, LICENCE.broadcom, LICENCE.cypress 실물 확보(kernel.org·Debian은 봇 차단 → GitHub 미러; broadcom_bcm43xx·wireless-regdb는 WSL 소스에서 추출 예정)
- README 배지·License 절 교체
- **이미지 반영(v33 예정)**: `/usr/share/licenses/` + boot 파티션 `LICENCE.broadcom` + `/lib/firmware/LICENCE.cypress` + 폰트 OFL + 게이트(실존 검사)

### 유지 결정
- Firefox: 공식 빌드 무수정 재배포 → MPL·상표 정책 OK / LGPL 동적 링크 구조 OK / `EXTRA_FIRMWARE` 커널 내장은 커널 제공 기능·펌웨어는 데이터로 통용 → 고지로 충분, 장기 분리 검토.

### 교훈
"Public Domain"은 *태도*였지 *라이선스 문서*가 아니었다. 이념(오픈소스 환원)은 Unlicense로 더 정확히 표현되고, 그 위에서 **남의 라이선스를 존중하는 절차**(텍스트 동봉·소스 제안·패치 공개)가 실제 신뢰를 만든다.
