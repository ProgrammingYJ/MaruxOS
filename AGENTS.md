# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## MaruxOS

LFS 12.0 툴체인 (glibc 2.38/binutils 2.41/gcc 13.2.0) + 12.1-era 유저랜드 기반 커스텀 Linux 배포판. WSL2에서 빌드 → squashfs Live ISO. 한글 입력기 ibus-hangul 내장. (라벨 실체: `config/lfs-versions.conf`가 SSOT — glibc 2.38+binutils 2.41 = LFS 12.0. 과거 "12.1" 표기는 genesis 잔재였고 2026-07-08 정정.)

## 협업 원칙

- **한국어로 소통한다.**
- **항상 결정을 다시 의심하라** — 사용자가 동의했어도, 코드 작성 직전 한 번 더 자문: "이게 진짜 최선인가? 더 단순한 길은? 잘못된 가정은 없나?" 의심이 남으면 코드 치기 전에 사용자에게 다시 묻는다. 침묵하고 진행하지 말 것.
- **안정성 최우선.** 의존성/버전은 이중 체크. 커널·빌드·부트 영역 변경은 가설 → 검증 → 실행 순서로.
- **빌드 스크립트는 `set -e` 사용 중** — 한 줄 실패 = 전체 중단. 에러 핸들링/`|| true` 신중히.
- **이 프로젝트는 "AI의 한계를 도전"하는 실험.** 이 파일은 컴파스이지 족쇄가 아님. 정책이 길을 막으면 사용자에게 알리고 협의.

## 📌 세션 시작 시 반드시 참조 (Living Docs)

**이 AGENTS.md는 *변하지 않는 것*만 담는다. *현재 진행 상황·다음 할 일*은 아래 로그에 있으니, 작업 시작 전 반드시 먼저 읽는다.** (특히 compact/새 세션 직후)

- **`ARM64-Update-Log.md`** ⭐ — ARM64 트랙 모든 작업/결정/함정/검증. **맨 아래 최신 날짜 섹션 = 핸드오프**(현재 위치·다음 할 일·정찰 데이터·자산 경로·게이트). **ARM64 작업은 무조건 이 핸드오프부터 읽고 시작.** (8/10 OSS Korea 슬라이드 1차 소스)
- **`Kernel-Update-Log.md`** — x86_64 트랙 / 메타 / 일반 작업 (Section 1~31).
- **`ISO-BUILD-HISTORY.md`** — 빌드 스크립트 히스토리 (x86_64 `cooked-vN` + ARM64 `arm64-vN` 별도 트랙).
- **`MEMORY.md`** (자동 메모리, `~/.Codex/.../memory/`) — 크로스세션 요약 상태 + 현재 상태 헤더.
- **`C:\Users\Administrator\.Codex\plans\`** plan 파일 + `git log` — 상세 진행.

**기록은 양방향**: 세션 시작엔 위 문서를 *읽고*, 작업하며 나온 새 결정·함정·검증·마일스톤은 즉시 *쓴다* (아래 "진행 중 작업 / 로드맵"의 "기록 의무" 참조). 세션 끝/compact 전엔 최신 핸드오프 섹션을 갱신해 다음 세션이 끊김 없이 잇게 한다.

## 빌드 환경 & 명령

- 빌드 호스트: WSL2 (Ubuntu). 프로젝트 자체는 Windows에 있고 WSL이 `/mnt/c/...`로 마운트해 빌드함.
- WSL 빌드 디렉토리: `/home/administrator/MaruxOS/build/` (`rootfs-lfs/`, `iso-build/` 하위 구조)
- Windows 프로젝트 루트: `c:\Users\Administrator\Desktop\MaruxOS`
- ISO 산출물: `output/MaruxOS-X.Y.Z-67-vN.iso` (Windows side)

**빌드 (WSL 안에서 실행):**
```bash
bash /mnt/c/Users/Administrator/Desktop/MaruxOS/scripts/build-X.Y.Z-67-vN.sh
```
빌드 스크립트는 한 파일에 모든 단계가 들어있음 (cleanup → 커널/initrd 복사 → 패키지 설치 → config 적용 → squashfs → xorriso/grub-mkrescue ISO 생성).

**부팅 테스트:**
```bash
qemu-system-x86_64 -m 4G -enable-kvm -cdrom output/MaruxOS-X.Y.Z-67-vN.iso
```

테스트 프레임워크 없음 — 검증은 ISO 빌드 + QEMU 부팅 + 게스트 안에서 수동 회귀 확인.

## 아키텍처 큰 그림

빌드는 **두 단계 합성**:
1. **rootfs-lfs/** — LFS 베이스 + 패키지가 누적된 chroot. 빌드 스크립트는 이걸 직접 수정 (chroot로 들어가서 fc-cache, localedef, glib-compile-schemas 등 실행).
2. **config/ → rootfs-lfs/** — Windows 쪽 `config/` 파일들이 빌드 스크립트에 의해 rootfs 안의 적절한 경로로 복사됨. 즉 **사용자 변경 흐름은: `config/` 수정 → 빌드 스크립트 재실행 → ISO 재생성.** rootfs를 직접 수정하면 다음 빌드에 덮어써져서 사라짐.

**핵심 경로:**
- `config/lfs-versions.conf`, `config/marux-release.conf` — 버전/패키지 메타데이터 single source of truth. 빌드 스크립트와 다른 모든 메타파일이 여기 참조.
- `config/xinitrc` — 1.x/x86 v9까지의 X 세션 시작점(tint2 기반, 유산). **2.0.0 데스크톱은 `setup-desktop-config-*.sh`가 xinitrc를 생성**(ibus-daemon, dhcpcd 폴백, feh, picom, bamf, plank, marux-quicksettings, idesk, openbox — ARM64 v15 / x86 v1 이식본).
- `config/openbox/{rc.xml,menu.xml}` — 우클릭 메뉴 + 키바인드 (Win+T/D/E 등).
- `config/scripts/marux-*` — 게스트 시스템에서 동작하는 헬퍼 (wallpaper, desktop-refresh, new-desktop-item).
- `scripts/build-X.Y.Z-67-vN.sh` — 릴리즈별 빌드 스크립트. 버전별로 새 파일 생성 (이전 버전 보존 — 대체된 버전은 `scripts/archive/{1.x,2.0.0-x86_64,2.0.0-arm64}/`로 이동, 2026-08-28). 헤더에 변경/버그픽스 코멘트 명시. 현재 진입점 인덱스 = `scripts/README.md`.
- `scripts/install-*.sh` — 빌드 스크립트가 호출하는 패키지별 설치 모듈 (ibus-hangul, idesk, neofetch).
- `iso/boot/grub/grub.cfg` — GRUB 부트로더 (정적 경로 `/boot/vmlinuz` 사용 — 커널 버전 무관).
- `/usr/bin/marux-splash` — 부팅 스플래시 (게스트 측 경로).

## 알아둘 제약

- **버전은 사용자가 지정한다.** 자동 bump 금지. 1.2.1 정식 릴리즈됨 → 2.0.0 "Cooked" 작업 중 (커널 6.18.26 LTS + ARM64 후속).
- **Minimal busybox initrd** — `/lib/modules` 디렉토리 없음. 부팅 필수 드라이버는 모두 **builtin (`=y`)** 필수. 모듈 (`=m`)로 빌드되면 initrd가 못 로드해서 부팅 패닉. `scripts/build/02-build-kernel.sh`에 명시적 `enable_builtin` 호출 + critical 옵션 grep 검증 게이트 있음.
- **검증 게이트는 거의 종교적으로 유지** — 1.x 시리즈가 검증 게이트 부재로 6.12 의도 → 6.7.4 hallucination이 5개월 살아남아 92회 빌드 인프라가 됨. 모든 단일진실값(KERNEL_VERSION, SHA256, 코드명 등)은 빌드 산출물과 비교/강제하는 게이트가 있어야 한다. 게이트의 expected 값 자체도 검증 대상 — AI 요약/WebFetch 결과를 그대로 박지 말고 raw bytes로 가져오거나 첫 다운로드 결과를 채택.
- **라이선스 정책(2026-08-27 확정)**: MaruxOS 고유 저작물 = **The Unlicense**(OSI 승인 퍼블릭 도메인 헌정, LICENSE §1 범위). 배포 이미지는 *집합체* — 서드파티는 각자 라이선스(THIRD-PARTY-LICENSES.md), 우리 수정은 반드시 `patches/`에 diff로 공개(GPL 대응 소스), 이미지엔 `/usr/share/licenses/`·펌웨어 `LICENCE.*` 동봉. "MaruxOS는 Public Domain, 제한 없음" 식의 이미지 전체 주장 금지. tuna27 자산(로고·배경화면·터미널/파일관리자 아이콘 4종)은 **CC BY 4.0**(2026-08-28 디자이너 오픈소스 배포 동의, 저작자 표시 유지) — Unlicense 헌정엔 미포함.
- **PCManFM(GTK) 사용 불가** — GLib 2.68+ 필요, v2~v5 빌드 실패 이력. GTK판 대신 **PCManFM-Qt**를 Qt 의존성 사슬째 크로스 빌드해 정공 해소 — ARM64 v27(2026-08-25) · **x86_64 cooked-v10(2026-08-28, 같은 크로스 체계를 x86 sysroot에 재사용)**. mc는 양쪽 폴백으로 잔류. x86 rootfs엔 1.x Plank 사고 때 deb에서 들어온 GLib 2.80 런타임(/usr/lib)과 LFS 2.78(헤더·pc, /usr/lib64)이 공존 — Kernel-Log §34 벽 9 참조.
- **한글 입력**: ibus-hangul + memconf 백엔드. WSL2의 GTK3 헤더가 `GDK_WINDOWING_WAYLAND`를 정의해서 im-ibus.so에 Wayland 심볼이 박힘 → 소스 코드에서 `MARUX_DISABLED_WAYLAND`로 sed 패치 필요. X.org 환경 전용.
- **바탕화면 아이콘**: idesk. `setsid`로 세션 분리 안 하면 SIGHUP에 죽음 (1.2.1 v3에서 수정). PNG는 `marux-*` prefix 통일 (1.2.1 v4에서 정정).
- **빌드 권한**: 1.x 빌드는 root 또는 sudo 환경 가정. `chroot` 호출 + `rootfs-lfs/` 소유권이 root일 가능성 → 새 빌드 스크립트 작성 시 동일 권한 모델 유지.
- **커널 소스/빌드는 반드시 WSL native fs** (`/home/$USER/...`)에서. Windows 드라이브 (`/mnt/c/...`)에서 풀면 case-insensitive 때문에 `xt_TCPMSS.c` (대문자) → `xt_tcpmss.c`로 박혀서 빌드 시 `No rule to make target xt_TCPMSS.o` 에러 (2026-05-06 발견). `WSL_KERNEL_BUILD_ROOT` 환경변수로 제어. 01/02 build 스크립트가 `/mnt/[a-z]/` 패턴 검사해서 abort. **rootfs-lfs/ 와 iso-build/ 는 이미 WSL native, 커널만 예외였음.**

## ARM64 트랙 — Hallucination 방지 (절대 헷갈리지 말 것)

2.0.0부터 **x86_64 + ARM64 동시 트랙**. 디렉토리/브랜치/빌드 스크립트/산출물 모두 분리. 폴더 헷갈리면 5개월 hallucination 재현 가능 — 게이트로 강제.

### 디렉토리 (절대 헷갈리면 안 됨)

| 용도 | 경로 |
|------|------|
| Windows 프로젝트 루트 (공통) | `c:\Users\Administrator\Desktop\MaruxOS\` |
| WSL x86_64 빌드 (기존) | `/home/$USER/MaruxOS/build/` — **건드림 ❌** |
| WSL ARM64 빌드 (NEW) | `/home/$USER/MaruxOS-arm64/` — **완전 분리** ⭐ |
| WSL x86 패리티 작업(2026-08-28~) | `/home/$USER/MaruxOS/x86-parity/` — x86 rootfs **사본** + gcc-13 래퍼 + Qt 크로스(`scripts/*-x86.sh`). 기존 `build/`는 건드리지 않음 |
| ARM64 하위 | `toolchain/`, `kernel/`, `firmware/`, `rootfs-clfs-arm64/`, `iso-build/`, `output/` |
| ARM64 전용 config (Pi boot용) | `config-arm64/` (config.txt, cmdline.txt 등) |

### 브랜치 / 빌드 스크립트 / 산출물

- 브랜치: `2.0.0-cooked-arm64` (ARM64 작업), `2.0.0-cooked-kernel` (x86_64). 2.0.0 출시 시 둘 다 main에 머지
- 빌드 스크립트: `scripts/build-2.0.0-cooked-arm64-vN.sh` (x86_64는 `build-2.0.0-cooked-vN.sh`)
- 산출물: `MaruxOS-2.0.0-arm64.img.xz` / `MaruxOS-2.0.0-x86_64.iso`
- 출력 포맷: ARM64는 hybrid disk image (.img.xz, 가짜 .iso 확장자 OK). Pi 4B는 ISO9660 못 부팅하므로 USB stick에 dd → USB 부팅 → microSD 설치 패턴

### ARM64 빌드 스크립트 의무 게이트

모든 `build-*-arm64-*.sh` 헤더에 박을 것:
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

### Pi 4B 부팅 체인 (절대 건드리지 말 것)

EEPROM → `start4.elf` → `kernel8.img` 직접 로드. **U-Boot/GRUB 단계 없음.**
- boot 파티션 (FAT32): `bootcode.bin`, `start4.elf`, `fixup4.dat`, `bcm2711-rpi-4-b.dtb`, `kernel8.img`, `config.txt`, `cmdline.txt`
- root 파티션 (ext4 — Live는 squashfs+overlay 검토)
- USB stick에 dd → Pi 4B USB 부팅 → installer가 microSD에 설치 (Phase 2)

### Phase 분리 (8/10 마감 고려)

- **Phase 1 (MVP)**: Live boot까지. Qt 없음, installer 없음. 커널 + rootfs + X.org + Openbox + ibus-hangul + Firefox.
- **Phase 2**: Qt5 cross-build + `marux-installer` GUI + (보너스로) QTerminal 같이 도입.
- ~~mc → PCManFM-Qt는 **2.0.x 패치** (Phase 2에 욱여넣지 말 것).~~ *(2026-08-25 뒤집힘: 사용자 결정으로 **2.0.0 릴리즈 스코프에 포함** → v27에서 완료. 이 줄은 8/11 발표 MVP 기준의 옛 판단으로 박제.)*

## 진행 중 작업 / 로드맵

**현재**: 2.0.0 "Cooked" — 커널 6.18.26 LTS ✓. **🏆 2026-08-25 `arm64-v27`로 2.0.0 로드맵 4/4 완주** — ①ARM64 데스크톱+한글 ✅(실기기) ②WiFi+우상단 통합 상태 바/퀵설정 GUI ✅(실기기, FWSUP 패치로 정복) ③xterm→**QTerminal**(Qt5) ✅ ④mc→**PCManFM-Qt** ✅. 배치 Q/F는 MaruxOS 최초 **호스트 크로스 컴파일**(qemu chroot 아님) — 규칙: *호스트에서 실행되는 도구는 전부 명시*(PERL/PKG_CONFIG…), `--sysroot` 필수, `.la` 정리, 시대 보정(`<limits>`/`-fcommon`), SVE 비활성. **v27 실기기 검증(2026-08-26): QTerminal 기동 즉시 SIGABRT** — 함정 #35 = Ubuntu 크로스 gcc의 암묵 `-D_FORTIFY_SOURCE=3`이 Qt 5.15.2 `qt_readlink`를 오탐(가짜 buffer overflow). 크로스 규칙 ⑥: *호스트 컴파일러 암묵 기본값을 `-dM -E`로 실측.* → Qt 스택 전체 `=2` 재빌드(`rebuild-qt-fortify-arm64.sh`) + **게이트 승격 "존재≠기동"**(`gate-qt-launch-arm64.sh`: qemu chroot 실제 실행) → v28 실기기 **기동 실증 ✅**(단 독 아이콘 투명 = 함정 #36: 재빌드 `make install`이 config `.desktop`을 덮어씀 → **규칙: 패키지 (재)설치 후 config 재적용 필수**, 게이트 "존재≠내용" = `.desktop` config 바이트 일치) → v29 `312e4706…` → **v30 ✅ (`29579682…`, 2026-08-26 23:30) = 자동 로그인(inittab `agetty --autologin root` tty1) + X 자동 기동(`.bash_profile` tty1 startx, exec 아님, ttyS0 getty 유지) — 출품 후보**. → v31(FeatherPad) → v32(LXImage·SpeedCrunch·Archiver·qps) → **v33 `fc3e038f…` 361M = 출품 제출본**(다이어트: /sources·gcc·개발파일 제거+strip, /usr/share/licenses 동봉). 다음 = v33 실기기 검증(⚠️ Qt 앱 한글 입력 — 실패 시 ibus Qt5 immodule or `QT_IM_MODULE=xim`). 미해결(블로커 아님): plank 우클릭 닫기 무동작 / 독 인디케이터 점 위치·크기. **최신 진행·핸드오프 = `ARM64-Update-Log.md` 맨 아래.** (8/11 OSS Korea 발표 ✅ / **8/27 오픈소스대회 출품 D-2**)

**2.0.0 완성 로드맵 — 아래 1~4 전부 2.0.0 릴리즈에 포함** (사용자 의도 2026-07-11 재확인, 순서 고정):
> ⚠️ **범위 명확화**: 1~4는 *2.0.0 이후*가 아니라 **2.0.0 릴리즈 자체에 다 넣고 배포**하는 게 사용자 플랜(= 8/27 오픈소스대회 출품작 스코프). **8/11 OSS Korea 발표는 그 시점까지 완성된 MVP 스냅샷(한글 데스크톱)을 시연**(✅ 발표 완료 2026-08-11) — 발표 타이밍상 Qt는 발표 후 8/27까지 완성. (아래 "Phase 분리"의 Phase1/Phase2는 *8/11 발표 MVP 기준* 구분이지 릴리즈 스코프 아님 — 혼동 말 것.)
1. **ARM64 패치 완료** (그래픽 데스크톱까지) + **한글(ibus-hangul)** — Pi 네이티브 빌드 *(✅ 완료 — v10 한글, v11 GTK3/Firefox, v12 네트워크, 실기기 검증)*
2. **Plank 재작업** — dock-items GSettings/memconf 결합 디버그. v3~v7 자산 (install-plank.sh, config/plank/, tint2rc-systray) frozen 상태로 보존됨 *(✅ 완료 — v14 소스빌드+keyfile 정공픽스, v17 libwnck 43.2로 배치 P 공식 종결·실기기 전항목 검증; 잔여 = 인디케이터 점 위치/크기 + 우클릭 닫기 무동작, 둘 다 블로커 아님)*
3. **xterm → QTerminal** 교체 — Qt5/Qt6 의존성 사슬 통째 도입. 일관된 Qt-based UI 시작 *(✅ 완료 — v26. Qt5 5.15.2 12종 + xcb 플러그인 + qtermwidget + QTerminal 0.17.0, MaruxOS 최초 호스트 크로스 컴파일. 실기기 검증 대기)*
4. **mc → PCManFM-Qt** 교체 — QTerminal이 Qt deps 박은 후라 "공짜". 1.x PCManFM 사고(GLib 2.68 + 70 lib 사고)의 정공 해소 *(✅ 완료 — v27. libexif→libfm(extra-only)→menu-cache→libfm-qt→pcmanfm-qt. 실기기 검증 대기)*

**별도 트랙**: glibc 2.38 → 최신 (2.x.x) — 보안 패치, 별도 마이너 버전 (이건 진짜 2.0.0 밖)

- 상세한 진행 상황은 `C:\Users\Administrator\.Codex\plans\` 의 plan 파일과 git log를 참조한다. 이 파일은 변하지 않는 것만 적는다.
- **양 트랙 기록 의무 (반드시 분리)**:
  - **x86_64 트랙 / 메타 / 일반 작업** → `Kernel-Update-Log.md` (Section 1~31)
  - **ARM64 트랙 모든 작업** → `ARM64-Update-Log.md` (8/10 OSS Korea 슬라이드 1차 소스 — *빠짐없이 박을 것*)
  - 빌드 스크립트 추가/변경 → `ISO-BUILD-HISTORY.md`도 동시에 항목 추가
- **빌드 스크립트 변경 시 `ISO-BUILD-HISTORY.md` 에 항목 추가** — 1.x v1~v54 패턴 유지. version 점프(v1.2.0 v4 → 2.0.0 cooked-v1) 시에도 한 항목씩 기록.
- **코드 관련 작업할 때마다 프로젝트 내 모든 `.md` 파일 점검** — 6.12 → 6.18.26 같은 버전 잔재, 코드명 잔재(Phoenix/67), Debian 기반 가정(apt/systemd) 등 옛 정보가 새 작업과 충돌하면 즉시 갱신. 단 *historical artifact* (ISO-BUILD-HISTORY 옛 항목, BUILD-STATUS, CHANGELOG 옛 entry, frozen build script)은 박제 유지.
