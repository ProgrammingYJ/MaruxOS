# MaruxOS

<div align="center">

![MaruxOS Logo](MaruxOS%20디자인/marux-logo-512.png)

**The World's First OS Built 100% with AI**

*Not based on Ubuntu, Debian, or any distribution - Pure Linux From Scratch*

[![Download ISO](https://img.shields.io/badge/Download-MaruxOS%202.0.0-blue.svg?style=for-the-badge)](https://github.com/ProgrammingYJ/MaruxOS/releases/latest)

[![License: Unlicense (MaruxOS) + component licenses](https://img.shields.io/badge/License-Unlicense_%2B_component_licenses-brightgreen.svg)](LICENSE)
[![Linux](https://img.shields.io/badge/Kernel-6.18.26%20LTS-orange.svg)](https://kernel.org/)
[![LFS](https://img.shields.io/badge/Base-LFS%2012.0-green.svg)](https://www.linuxfromscratch.org/)
[![AI](https://img.shields.io/badge/Built%20with-Claude%20Code-blueviolet.svg)](https://claude.ai/)
[![Design](https://img.shields.io/badge/Design-tuna27-ff69b4.svg)]()

**[English](#english) | [한국어](#한국어)**

</div>

---

# English

## What is MaruxOS?

MaruxOS is **the world's first operating system built 100% with AI (Claude Code)**.

Unlike Ubuntu, Fedora, or Arch which are based on existing Linux distributions, MaruxOS is built **entirely from the Linux kernel** using [Linux From Scratch (LFS)](https://www.linuxfromscratch.org/). Every single component - from the bootloader to the desktop environment - was compiled from source code with AI assistance.

### World's First

- **100% AI-Built OS** - Every script, configuration, and build process created with Claude Code
- **Not Distribution-Based** - Built directly from Linux kernel, not forked from Ubuntu/Debian/Arch
- **Pure LFS** - Following Linux From Scratch methodology from scratch

### Key Features

- **Pure LFS Base** - Not based on Debian, Ubuntu, or any other distribution
- **Lightweight** - Minimal footprint with only essential components
- **Custom Desktop** - Openbox + Plank dock + picom compositor + self-made `marux-quicksettings` status bar, Qt5 app set (QTerminal, PCManFM-Qt, FeatherPad, LXImage-Qt, SpeedCrunch, LXQt Archiver, qps)
- **Live Boot** - Boot directly from USB/CD without installation
- **Modern Kernel** - Linux 6.18.26 LTS
- **Korean Input** - Full Korean (Hangul) input support via ibus-hangul (Shift+Space toggle; GTK, Qt and XIM apps), 한/A indicator in the status bar

## System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| CPU | x86_64 (64-bit) or ARM64 (Raspberry Pi 4B) | Dual-core 2GHz+ |
| RAM | 1GB | 2GB+ |
| Storage | Live boot only | - |
| Graphics | VGA compatible | Any modern GPU |

## Included Software

| Category | Software |
|----------|----------|
| Window Manager | Openbox |
| Panel | `marux-quicksettings` unified status bar (2.0.0, both arches — tint2 retired) |
| Dock / Compositor (ARM64) | Plank (built from source) + picom |
| Terminal | **QTerminal** (Qt5, 2.0.0, both arches; xterm kept as fallback) |
| File Manager | **PCManFM-Qt** (2.0.0, both arches; mc kept as fallback) |
| Web Browser | Firefox |
| Wallpaper | feh |
| Korean Input | ibus-hangul 1.5.5 (libhangul 0.2.0, ibus 1.5.29) |
| Korean Fonts | Nanum Gothic, Nanum Myeongjo |

## Quick Start

1. **Download** the latest ISO from releases
2. **Create bootable USB** using [Rufus](https://rufus.ie/) (Windows) or `dd` (Linux)
3. **Boot** from USB
4. Login is automatic (root user)
5. Desktop starts automatically via `startx`

## Korean Input Guide

| Action | Key |
|--------|-----|
| Korean/English Toggle | **Shift+Space** (status-bar 한/A indicator follows) |
| Keyboard Layout | Dubeolsik (2-set QWERTY) |
| Hanja Conversion | F9 |

## Known Limitations

| Issue | Description |
|-------|-------------|
| Plank dock quirks | Right-click "Close" on a dock icon does nothing; running-indicator dot placement is off (both arches). |

## Project Structure

```
MaruxOS/
├── config/                 # Configuration files
│   ├── plank/             # Dock launchers (tint2/ = retired 1.x panel config)
│   ├── openbox/           # Window manager settings
│   └── applications/      # Desktop entries
├── kernel/                 # Linux kernel
│   └── source/            # Kernel source (6.18.26 LTS)
├── scripts/               # Build scripts
├── output/                # Built ISO files
├── MaruxOS 디자인/        # Branding assets
│   ├── wallpapers/        # Desktop wallpapers
│   └── icons/             # Custom icons
├── ISO-BUILD-HISTORY.md   # Build changelog (Korean)
├── ISO-BUILD-HISTORY-EN.md # Build changelog (English)
└── README.md              # This file
```

## Build System (WSL)

MaruxOS is built using WSL (Windows Subsystem for Linux) with the following structure:

```
/home/administrator/MaruxOS/build/
├── rootfs-lfs/            # Root filesystem
├── iso-build/             # ISO staging
│   ├── boot/              # Kernel & initrd
│   │   ├── vmlinuz        # Linux kernel
│   │   ├── initrd.img     # Initial ramdisk
│   │   └── grub/          # GRUB bootloader
│   └── live/
│       └── filesystem.squashfs  # Compressed root filesystem
```

### Build Commands

```bash
# Create squashfs
mksquashfs rootfs-lfs iso-build/live/filesystem.squashfs -comp gzip -e boot -noappend

# Create ISO
grub-mkrescue -o MaruxOS-1.0.iso iso-build
```

## Current Limitations

- **Live boot only** - No disk installation support yet
- **No package manager** - Software is pre-installed
- **x86_64 ISO desktop parity landed 2026-08-28 (cooked-v10)** - same Qt5 app set as the Pi image; audio backend in the Live ISO depends on the host card (no PulseAudio, ALSA only)

## Roadmap

- [ ] Disk installation support
- [ ] Package management system
- [x] GUI file manager — **PCManFM-Qt** (Qt5 stack landed with QTerminal) on ARM64 (v27) and x86_64 (cooked-v10, 2026-08-28)
- [x] ~~Korean input support~~ (v1.1)
- [ ] More language support (Japanese, Chinese)
- [x] ARM64 / Raspberry Pi 4B support (2.0.0 — verified on real hardware: full desktop with Plank dock + picom compositor, Korean input in GTK3/Qt5 apps and Firefox, wired networking with NTP)
- [x] ARM64 WiFi + self-made quick-settings panel GUI (verified on real hardware) → QTerminal (Qt5) → PCManFM-Qt — **2.0.0 roadmap complete; final hardware verification pending**

## Support & Contact

- **Discord**: `pizzamaru_`
- **Email**: marudev@outlook.kr
- **Portfolio**: https://marulee.dev
- **Issues**: GitHub Issues

## License

**MaruxOS's own work** (build system, configuration, documentation, `marux-quicksettings`, MaruxOS-drawn icons) is dedicated to the public domain under **The Unlicense** (public domain dedication, OSI-approved) — use it for anything, no attribution required.

A MaruxOS **image is an aggregate**: every third-party component keeps **its own license** — Linux kernel (GPL-2.0), glibc / Qt 5 (LGPL), Firefox (MPL-2.0, unmodified official build), Openbox, Plank, X.org, ibus-hangul, Raspberry Pi / Cypress firmware (proprietary, redistributable), Nanum fonts (OFL 1.1), and more. See:

- [LICENSE](LICENSE) — Unlicense text, scope, and the written offer for corresponding source
- [THIRD-PARTY-LICENSES.md](THIRD-PARTY-LICENSES.md) — component-by-component list and how we comply
- [SOURCES.md](SOURCES.md) — exact upstream tarballs (version, URL, SHA256)
- [patches/](patches/) — every modification we make to upstream code

## Credits

| Role | Credit |
|------|--------|
| **UI/UX Design** | **tuna27** — logo, wallpaper, terminal & file-manager icons (CC BY 4.0) |
| **AI Development** | **Claude Code (Anthropic)** |
| Base System | [Linux From Scratch](https://www.linuxfromscratch.org/) |
| Kernel | [kernel.org](https://kernel.org/) |

### Special Thanks

**Sigterm Co., Ltd. (시그텀 주식회사)** - For sponsoring the Claude Code MAX plan that made this project possible.

---

# 한국어

## MaruxOS란?

MaruxOS는 **세계 최초로 100% AI(Claude Code)만으로 제작된 운영체제**입니다.

우분투, 페도라, 아치처럼 기존 리눅스 배포판을 기반으로 하지 않고, [Linux From Scratch (LFS)](https://www.linuxfromscratch.org/)를 사용하여 **리눅스 커널부터 완전히 새로 빌드**했습니다. 부트로더부터 데스크톱 환경까지 모든 구성 요소가 AI의 도움으로 소스 코드에서 컴파일되었습니다.

### 세계 최초

- **100% AI 제작 OS** - 모든 스크립트, 설정, 빌드 과정이 Claude Code로 제작
- **배포판 기반 아님** - 우분투/데비안/아치에서 포크하지 않고 리눅스 커널부터 직접 빌드
- **순수 LFS** - Linux From Scratch 방법론을 처음부터 따름

### 주요 특징

- **순수 LFS 기반** - 데비안, 우분투 등 다른 배포판 기반 아님
- **경량** - 필수 구성 요소만 포함한 최소한의 시스템
- **커스텀 데스크톱** - Openbox + Plank 독 + picom 컴포지터 + 자체 제작 `marux-quicksettings` 상태 바, Qt5 앱 세트(QTerminal, PCManFM-Qt, FeatherPad, LXImage-Qt, SpeedCrunch, LXQt Archiver, qps)
- **라이브 부팅** - USB/CD에서 설치 없이 바로 부팅
- **최신 커널** - Linux 6.18.26 LTS
- **한글 입력 지원** - ibus-hangul 기반 한/영 전환 (Shift+Space; GTK·Qt·XIM 앱), 상태 바 한/A 표시

## 시스템 요구 사항

| 구성 요소 | 최소 | 권장 |
|-----------|------|------|
| CPU | x86_64 (64비트) 또는 ARM64 (Raspberry Pi 4B) | 듀얼코어 2GHz+ |
| RAM | 1GB | 2GB+ |
| 저장 장치 | 라이브 부팅만 가능 | - |
| 그래픽 | VGA 호환 | 최신 GPU |

## 포함 소프트웨어

| 분류 | 소프트웨어 |
|------|-----------|
| 윈도우 매니저 | Openbox |
| 패널 | `marux-quicksettings` 통합 상태 바 (2.0.0, 양 아키텍처 — tint2 은퇴) |
| 독 / 컴포지터 (ARM64) | Plank (소스 빌드) + picom |
| 터미널 | **QTerminal** (Qt5, 2.0.0, 양 아키텍처; xterm은 폴백) |
| 파일 관리자 | **PCManFM-Qt** (2.0.0, 양 아키텍처; mc는 폴백) |
| 웹 브라우저 | Firefox |
| 배경화면 | feh |
| 한글 입력기 | ibus-hangul 1.5.5 (libhangul 0.2.0, ibus 1.5.29) |
| 한국어 폰트 | 나눔고딕, 나눔명조 |

## 빠른 시작

1. releases에서 최신 ISO **다운로드**
2. [Rufus](https://rufus.ie/) (Windows) 또는 `dd` (Linux)로 **부팅 USB 생성**
3. USB로 **부팅**
4. 자동 로그인 (root 사용자)
5. `startx`로 데스크톱 자동 시작

## 한글 입력 가이드

| 동작 | 키 |
|------|-----|
| 한/영 전환 | **Shift+Space** (상태 바 한/A 표시 연동) |
| 자판 배열 | 2벌식 (QWERTY) |
| 한자 변환 | F9 |

## 현재 제한 사항

- **라이브 부팅만 가능** - 디스크 설치 미지원
- **패키지 관리자 없음** - 소프트웨어 사전 설치됨
- **x86_64 ISO 데스크톱 패리티 완료 (2026-08-28, cooked-v10)** - Pi 이미지와 동일한 Qt5 앱 구성. Live ISO의 오디오는 호스트 카드 의존(PulseAudio 없음, ALSA만)

## 지원 및 문의

- **Discord**: `pizzamaru_`
- **Email**: marudev@outlook.kr
- **Portfolio**: https://marulee.dev
- **이슈**: GitHub Issues

## 크레딧

| 역할 | 크레딧 |
|------|--------|
| **UI/UX 디자인** | **tuna27** — 로고·배경화면·터미널/파일관리자 아이콘 (CC BY 4.0) |
| **AI 개발** | **Claude Code (Anthropic)** |
| 베이스 시스템 | [Linux From Scratch](https://www.linuxfromscratch.org/) |
| 커널 | [kernel.org](https://kernel.org/) |

### 감사의 말

**Sigterm Co., Ltd. (시그텀 주식회사)** - 이 프로젝트를 가능하게 해준 Claude Code MAX 플랜 지원에 감사드립니다.

---

<div align="center">

**Current Version: 2.0.0 "Cooked"**

Made with Linux From Scratch 12.0 (toolchain) + 12.1-era userland
**Made with ❤️ for the Linux community**

[Documentation](docs/) | [Contributing](CONTRIBUTING.md) | [License](LICENSE)

</div>
