# MaruxOS Frequently Asked Questions

> 이 문서는 MaruxOS의 **현재 상태 (2.0.0 "Cooked" 진행 중)** 기준 FAQ입니다. 1.x 시리즈 (Debian 기반 가정 + 6.12 LTS 광고 등)는 historical errata로 [CHANGELOG.md](../CHANGELOG.md) 참고.

## General

### What is MaruxOS?

**The world's first operating system built 100% with AI (Claude Code)**, based on Linux From Scratch (LFS) 12.0 toolchain + 12.1-era userland. **Not based on Debian, Ubuntu, or any other distribution** — every component is compiled from source code.

| Component | Reality |
|-----------|---------|
| Base | LFS 12.0 툴체인 + 12.1-era 유저랜드 (from-scratch, 비-파생) |
| Kernel | **Linux 6.18.26 LTS** (2.0.0 "Cooked") — 1.x 시리즈는 6.7.4 의도-불일치 hallucination 박혀있었음, 2.0.0에서 정정 |
| Init | **SysVinit** (systemd 아님) |
| WM | Openbox |
| Panel / Dock | x86_64: tint2 (풀 모드). ARM64(v14+): **Plank dock 소스빌드**(자체 valac 부트스트랩) + **picom v11.2** 컴포지터. **v22에서 tint2 은퇴** → 자체 제작 `marux-quicksettings`(vala/GTK3) 우상단 통합 상태 바(한/A · WiFi · 볼륨 · 시계) |
| Terminal | x86_64 = **xterm** / ARM64 2.0.0 = **QTerminal 0.17.0** (v26, Qt5 크로스 빌드 — xterm은 폴백 잔류) |
| Desktop Icons | idesk |
| File Manager | x86_64 = **mc (Midnight Commander)** (터미널 기반, PCManFM-GTK은 GLib 호환성으로 사용 불가) / ARM64 2.0.0 = **PCManFM-Qt** (v27, Qt 경로로 정공 해소 — mc는 폴백 잔류) |
| Korean Input | ibus-hangul (x86: memconf 백엔드 / ARM64 v14+: keyfile 백엔드 — XIM + gtk3 immodule) |
| Boot | GRUB2 + minimal busybox initrd + squashfs Live ISO |
| Compression | gzip (커널이 xz/lzma squashfs 미지원) |
| License | **Public Domain** |

### Why create another Linux distribution?

MaruxOS는 단순 "또 다른 배포판"이 아니라 **AI(LLM)와 협업해서 OS를 from-scratch로 만드는 실험**:
- AI 협업 한계 정직 노출 (Hallucination Hunter / Dementia Doctor / Final Decider)
- 오픈소스를 받았으니 환원 (Public Domain)
- 발표/콘퍼런스로 인사이트 공유 (OSS Korea 2026, 우분투한국커뮤니티 등)

### Is MaruxOS free?

**Public Domain** — 저작권 자체 포기. 완전히 자유롭게 사용/수정/재배포 가능.

### What does "Cooked" mean?

2.0.0 코드명. **LLM의 양면성을 메타-자기풍자**:
- "We cooked" — *잘 만들었다* (긍정 슬랭)
- "We're cooked" — *망했다* (부정 슬랭)
- Genesis 단계 AI hallucination (6.12 → 6.7.4)이 5개월간 92회 빌드 위 살아남았다 = "Cooked 상태로 태어났는데 누구도 몰랐던" 시기. 2.0.0이 그걸 정정. 코드명이 프로젝트 본질을 짚어버림.

## System Requirements

### Minimum
- **CPU**: x86_64 (64-bit)
- **RAM**: 1GB
- **Storage**: Live boot only (HDD 설치 미지원 — 2.0.x 후속 작업)
- **Boot**: BIOS or UEFI

### Recommended
- **CPU**: Dual-core 2GHz+
- **RAM**: 2GB+
- **Graphics**: Any modern GPU (VM 권장)

### Will MaruxOS run on Raspberry Pi?

**된다.** 2.0.0 "Cooked"에서 실물 Raspberry Pi 4B 8GB가 완전한 그래픽 데스크톱(Openbox + **Plank dock** + picom + idesk + **QTerminal** + **PCManFM-Qt** + feh)을 구동하며, **ibus-hangul 한글 입력(Shift+Space 토글)이 XIM은 물론 GTK3 앱/Firefox(gtk3 immodule, v11)까지 실기기에서 동작**합니다. **Firefox ESR 140.13.0esr(공식 aarch64 한국어 빌드) 실사용 웹서핑 + 유선 네트워크 out-of-box(dhcpcd DHCP + chrony NTP — RTC 없는 Pi의 "1970년 시계" 버그 완치)** 실기기 검증 완료(v12, 2026-07-27). 이후 **WiFi 무선 연결(brcmfmac FWSUP 패치로 host 4-way 강제) + 자체 제작 퀵설정 GUI(우상단 통합 상태 바: 한/A · WiFi · 볼륨 · 시계)까지 실기기 검증 완료**(v24, 2026-08-23).

**현재 이미지 = `arm64-v27`**(2026-08-25, SHA `bdf1f50e…`) — **2.0.0 로드맵 4/4 완주**: ①ARM64 데스크톱+한글 ②WiFi+퀵설정 GUI ③xterm→QTerminal(Qt5) ④mc→PCManFM-Qt. v26/v27의 Qt 계열은 빌드·게이트 통과 상태이며 **실기기 최종 검증 대기 중**입니다.

## Installation

### How do I "install" MaruxOS?

**현재는 Live boot only**. 디스크 설치 미지원. ISO 다운로드 → USB 굽기 → 부팅하면 끝.

```bash
# Linux/macOS — USB 굽기
sudo dd if=MaruxOS-2.0.0-cooked-v7.iso of=/dev/sdX bs=4M status=progress
sync
```

### Can I dual-boot?
지원 안 함. Live boot only.

### Can I try MaruxOS in QEMU?
권장 방법:
```bash
qemu-system-x86_64 -m 4G -enable-kvm -cdrom MaruxOS-2.0.0-cooked-v7.iso
```

## Desktop Environment

### Why Openbox + tint2 instead of GNOME/KDE/XFCE?

**LFS 환경에서 본격 데스크톱 환경 도입의 의존성 사슬이 너무 큼**. GNOME/KDE는 100~200개의 추가 라이브러리 + dconf/Qt 등 풀 재빌드 필요. XFCE도 1~2주 작업.

대신 **Openbox(WM) + tint2(panel) + idesk(icons)** 조합으로 비슷한 시각적 효과를 LFS 친화적으로 달성. x86 cooked-v3~v7의 Plank dock 시도는 dock-items GSettings 주입 이슈로 한때 중단됐으나, **ARM64 v14(2026-07-28)에서 근본원인(GSettings memory 백엔드 = 프로세스별·비영속)을 규명하고 gschema.override + keyfile 백엔드로 정공 해결 — Plank를 소스에서 빌드해(Vala 컴파일러 부트스트랩 포함) 실기기 탑재 완료.** v15부터 picom 컴포지터 + "Marux" 반투명 유리 테마.

### How do I change wallpaper?

```bash
# 우클릭 메뉴 → Settings → Change Wallpaper
# 또는 직접:
marux-wallpaper
```

### Korean input not working?

Ctrl+Y로 한영 토글 (ARM64/Pi에서는 **Shift+Space**). 만약 안 되면:
```bash
cat /tmp/hangul-diag.log | head -50
```

진단 로그 분석. 1.1 시리즈에서 ibus-hangul + memconf 백엔드 + Wayland 패치로 해결한 영역.

### Why no GUI file manager?

**PCManFM은 GLib 2.68+ 요구로 1.x v3~v5 빌드 실패**. xfe는 FOX 툴킷 호환성 문제로 Segfault. 그래서 `mc` (Midnight Commander) 사용. 터미널 기반이지만 안정적.

**(2026-08-25 완료)** ARM64는 **v27부터 PCManFM-Qt 탑재**. QTerminal(v26)로 Qt5 사슬이 들어온 뒤 `libexif → libfm(--with-extra-only) → menu-cache → libfm-qt → pcmanfm-qt`를 전부 소스 크로스 빌드 — GTK판이 아니라 **Qt판**이라 1.x의 GLib 2.68 충돌 자체가 재현되지 않는다. x86_64는 계속 mc.

## Software Management

### How do I install new software?

**현재 패키지 관리자 없음**. 모든 소프트웨어가 ISO에 사전 컴파일되어 있고, 추가 설치는:
1. 빌드 환경(WSL)에서 소스 컴파일 → rootfs-lfs에 통합
2. 또는 공식 바이너리/.deb 통합 (1.x Firefox 방식 — 단 ARM64 2.0.0은 Plank까지 전부 소스 빌드로 전환, deb 추출 안 씀. 예외는 Firefox 공식 aarch64 빌드뿐)

각 사례마다 의존성 사슬 (ldd) + 데이터 의존성 (GSettings schema 등) 추적 필요.

### Why no APT?

APT는 Debian 인프라. MaruxOS는 LFS from-scratch라 사용 불가. 자체 패키지 관리 시스템은 향후 계획 (현재 미정).

## Kernel and Boot

### Why Linux 6.18.26 LTS?

- **6.7.4 → 6.18.26** 정공 정정 (1.x hallucination 해소)
- LTS = 2년 long-term 유지보수 (Greg KH 2025-12-03 발표)
- 6.18 mainline에서 Pi 4 / V3D 3D 가속 작동 → ARM64 트랙에서 실기기로 실증됨

### Can I update the kernel?

ISO 자체가 frozen. 커널 변경은 빌드 시점에 결정. 다음 메이저 릴리즈에서 변경됨.

### How do I access GRUB menu?

ISO 부팅 직후 5초 timeout. 메뉴 항목:
- **Desktop** (기본)
- **Safe Mode** (`nomodeset mitigations=off systemd.unit=multi-user.target` — 베어메탈 회귀 폴백)
- **Debug**

### Boot is slow?

```bash
# dmesg 분석
dmesg -l err,warn | head -30
# /tmp/Network_log.txt — 네트워크 초기화 로그
cat /tmp/Network_log.txt
```

systemd 명령 (`systemd-analyze` 등)은 안 됨 — MaruxOS는 **SysVinit**.

## Troubleshooting

### "systemctl: 명령어를 찾을 수 없음"
정상. SysVinit이라 없음. 대체:
```bash
ps -p 1 -o comm=        # init 시스템 확인 (init.real)
cat /etc/inittab        # runlevel 설정
ls /etc/rc.d/           # SysVinit runlevel 디렉토리
```

### xterm에서 한국어가 박스로 나옴
xterm을 옵션 없이 띄우면 X11 bitmap font 사용 → 한국어 미지원. tint2 launcher에서 띄우는 xterm은 fix됨 (`/etc/X11/Xresources`에서 XTerm*faceName: Monospace 설정). *(ARM64 2.0.0은 기본 터미널이 QTerminal이라 이 문제가 없다. xterm은 폴백으로만 잔류.)*

### No WiFi
VM에서는 virtio-net이 동작. 베어메탈에선 펌웨어 blob 필요할 수 있음 (linux-firmware 패키지). regulatory.db 누락 시 wireless regulatory 영향. 자세한 known-risks는 [CHANGELOG.md](../CHANGELOG.md) 2.0.0 Errata 섹션. **ARM64/Pi 4B는 유선 이더넷이 out-of-box로 동작(v12+, dhcpcd)** — WiFi는 커널 재빌드(CFG80211/MAC80211=y + brcmfmac + 펌웨어 blob)와 자체 제작 퀵설정 GUI로 다음 배치에서 진행 중.

### plank dock은 어디 갔나요? (2.0.0)
**ARM64 이미지(v14+, 2026-07-28)에 있다 — 실기기 검증 완료.** 히스토리: x86 v3~v6에서 GSettings schema 누락으로 SIGTRAP, v7에서 schema 정복 후에도 dock-items가 주입 안 돼 빈 독 → 한때 2.0.x로 deferred. 이후 부검으로 근본원인 확정: **GSettings memory(memconf) 백엔드는 프로세스별·비영속이라 `gsettings set`이 plank 프로세스에 도달할 수 없다.** 해법(elementary OS 패턴) = ①`gschema.override`로 dock-items 기본값 박제 ②`GSETTINGS_BACKEND=keyfile`(영속·프로세스간 공유). ARM64는 Plank 0.11.89를 **소스에서 빌드**(Vala 0.56.17 부트스트랩 포함 11종 체인 — deb 추출 안 씀), v15부터 picom 컴포지터 + "Marux" 반투명 유리 테마. x86 ISO는 아직 tint2 풀 패널 (픽스 포팅은 추후).

### Network not working
1.x에서 가장 사고가 많았던 영역 (67-v28 ~ 67-v35 — 3주 디버그). 진단:
```bash
ip a                                 # IP 할당 확인
ping -c 3 8.8.8.8                    # 통신
ping -c 3 google.com                 # DNS
cat /tmp/Network_log.txt             # xinitrc가 만드는 로그
```

## Building and Customization

### How do I build MaruxOS from source?

```bash
# WSL2 (Ubuntu) 안에서
bash /mnt/c/Users/Administrator/Desktop/MaruxOS/scripts/build-2.0.0-cooked-vN.sh
```

자세한 가이드: [LFS-BUILD-GUIDE.md](LFS-BUILD-GUIDE.md), [DEVELOPMENT.md](DEVELOPMENT.md).

### Build environment
- **WSL2 (Ubuntu)** — Windows 호스트에서 Linux 빌드
- **WSL native fs 필수** for 커널 소스 — `/mnt/c/` (NTFS)는 case-insensitive라 `xt_TCPMSS.c` 같은 대문자 파일 손상. 02-build-kernel.sh가 abort.

### Can I customize the theme?

```bash
# 아이콘/배경화면 교체
# MaruxOS 디자인/marux-*.png 변경 후 빌드
# 빌드 시 자동으로 rootfs에 sync
```

UI/UX 디자인은 **tuna27** 협업.

### Why does the build take so long?

LFS Phase 7 (최종 시스템 빌드)이 8-15시간. 2.0.0 시리즈는 rootfs를 1.x 시점부터 누적 재사용해서 매 빌드는 10-30분 (커널 빌드 제외).

## Project Details

### Who made MaruxOS?

| 역할 | 크레딧 |
|------|--------|
| 개발자 / Vibe Coder | **이용진 (Maru / 마루)** |
| UI/UX Design | **tuna27** |
| AI Pair Programmer | **Claude Code (Anthropic)** |
| Sponsor | **Sigterm Co., Ltd. (시그텀 주식회사)** — Claude Code MAX plan |

### Contact

- **Discord**: `pizzamaru_`
- **Email**: marudev@outlook.kr
- **Portfolio**: https://marulee.dev
- **GitHub**: github.com/ProgrammingYJ/MaruxOS

### Talks / Conferences

- 2026-02 IGNITION (서울, YHHS): MaruxOS 개발기 + Hallucination 사건들
- 2026-03 우분투한국커뮤니티: "바이브코딩 시대에 능력있는 개발자는 더 중요해진다"
- **2026-08-11~12 OSS Korea 2026 (Linux Foundation, 서울) — 한국 최초 10대 연사**: *"The Era of Vibe Coding: Why High-Skill Engineers are More Critical Than Ever"*

### Why is the codename history weird (Phoenix → 67 → Cooked)?

| 코드명 | 버전 | 시기 |
|--------|------|------|
| Phoenix | 1.0 초기 | 2025-12 (Genesis) |
| 67 | 1.0 ~ 1.2.x | 2025-12 ~ 2026-05 (밈 시기) |
| **Cooked** | 2.0.0+ | 2026-05 ~ (LLM 양면성 메타) |

## Comparison

### MaruxOS vs Ubuntu

| Feature | MaruxOS | Ubuntu |
|---------|---------|--------|
| 베이스 | LFS 12.0 툴체인 + 12.1-era 유저랜드 (from-scratch) | Debian |
| 릴리즈 주기 | When Maru wants | 6 months |
| 커널 | 6.18.26 LTS | Latest |
| 빌드 도구 | Bash + AI (Claude Code) | apt + maintainers |
| 패키지 관리 | 없음 (from-source) | APT |
| Init | SysVinit | systemd |
| Branding | Public Domain | Canonical 소유 |
| Use case | AI 협업 학습 + 발표 자료 | 데일리 |

### MaruxOS vs Arch

| Feature | MaruxOS | Arch |
|---------|---------|------|
| 난이도 | Live boot은 쉬움, 빌드는 어려움 | Advanced |
| 철학 | "남자는 다른 걸 빌려쓰지 않는다" | DIY |
| 패키지 | 없음 (사전 컴파일) | pacman |
| 타깃 | AI 협업 실험자 | Linux power user |

## Licensing

### License?
**Public Domain** — 저작권 포기. 무제한 사용/수정/재배포/상용화 가능.

### Constituent packages?
Linux Kernel (GPL-2.0), GRUB (GPL-3.0), Openbox (GPL-2.0), Firefox (MPL-2.0), 등 각자 라이선스. [LICENSE](../LICENSE) 참조.

---

**MaruxOS의 진짜 정체성은 "코드가 아니라 개발 과정 자체가 자산"입니다.** [Kernel-Update-Log.md](../Kernel-Update-Log.md)가 그 증거.
