# Changelog

All notable changes to MaruxOS will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Custom package repository
- Automatic update system
- Backup and restore utility
- System monitoring dashboard

## [2.0.0] "Cooked" - 2026-08-27 (GitHub Release v2.0.0 — OSS Korea 8/11 발표 ✅, 오픈소스 개발자대회 8/27 출품 ✅; x86_64 데스크톱 패리티 2026-08-28)

### Added
- **Linux Kernel 6.18.26 LTS** — MaruxOS 역사상 첫 진짜 의도-일치 커널 빌드. 1.x 시리즈는 광고가 "6.12 LTS"였으나 실제로는 Genesis(2025-12-14)에 빌드된 6.7.4 vmlinuz를 92회 빌드 동안 재사용해온 사실이 2026-05-05 발견됨 (errata 참고).
- 검증 게이트 5종 신규 — 같은 사고 재발 방지:
  - `01-download-kernel.sh`: SHA256 검증 (`KERNEL_SHA256` 미설정 시 abort)
  - `02-build-kernel.sh`: critical builtin 옵션 (squashfs/iso9660/virtio/ahci/nvme/xhci 등) `=y` 강제 + 빌드 후 grep 검증
  - `02-build-kernel.sh`: `make modules_install` + `depmod -a` (1.x에서 누락)
  - `02-build-kernel.sh`: vmlinuz 임베드 버전 vs `KERNEL_VERSION` 매칭 검증
  - `build-2.0.0-cooked-v1.sh`: rootfs 동기화 후 모듈 수 카운트 sanity check
- GRUB Safe Mode 메뉴 엔트리 — 베어메탈 회귀 폴백 (`nomodeset mitigations=off systemd.unit=multi-user.target`)
- 코드네임 "Cooked" — LLM 양면성("ㅈㄴ 잘 만들기도 하지만 개같이 망치기도 함, Hallucination") 메타-자기풍자
- ISO SHA256/SHA512 자동 생성 (다운로드 검증용)
- `Kernel-Update-Log.md` 작성 — 커널 업그레이드 작업 일지 (발표/공유 용 1차 자료)

### Added (ARM64 / Raspberry Pi 4B)
- **aarch64 from-scratch rootfs** — 커널 6.18.26 LTS (aarch64) + glibc 2.38 / binutils 2.41 / gcc 13.2.0 크로스 툴체인으로 처음부터 빌드. mainline 커널 + Pi 4 builtin 강제 (RPi 포크 안 씀).
- **그래픽 데스크톱 실기기 검증** — 실물 Raspberry Pi 4B 8GB에서 Openbox + tint2 + idesk + xterm + mc + feh(배경화면) + 바탕화면 아이콘 + 우클릭 메뉴 + 키바인드(W-t/W-e/W-d) 동작 확인 (HDMI 출력 + libinput 입력).
- **한글 입력 (ibus-hangul XIM)** — Shift+Space 한/영 토글, libhangul + gtk2 im-ibus + NanumGothic 폰트로 실기기 타이핑 동작. (GTK3 앱 / Firefox 한글 입력은 arm64-v11에서 gtk3 immodule로 완성.)
- **GTK3 + Firefox (arm64-v11, 2026-07-25)** — gtk+-3.24.41 qemu-chroot 빌드(옛 "gtk3 벽"은 binfmt 중도사 오진으로 판명) + **Firefox ESR 140.13.0esr 공식 aarch64 한국어 빌드**(`/opt/firefox`) + gtk3 ibus immodule(GTK3 앱/Firefox 한글 입력) + alsa-lib + setxkbmap.
- **유선 네트워크 out-of-box (arm64-v12, 2026-07-27, 실기기 검증)** — dhcpcd 10.0.6(DHCP) + chrony 4.5(NTP — RTC 없는 Pi의 "1970년 시계" 버그 완치). 실물 Pi 4B에서 Firefox 실사용 웹서핑 검증.
- **커서/디스플레이 폴리시 (arm64-v13, 2026-07-27)** — HW 커서 복권(깜빡임·딜레이 완치) + HDMI 1080p60 강제(TV 호환) + libinput flat 가속.
- **Plank dock 소스빌드 (arm64-v14, 2026-07-28, 실기기 검증)** — aarch64에서 Plank 0.11.89를 소스로 빌드: **Vala 0.56.17 컴파일러 부트스트랩(MaruxOS 자체 valac 보유)** + 11종 체인(gobject-introspection·vala·libgee·libXres·libwnck·libgtop·gnome-menus·xcb-util·startup-notification·bamf·plank). x86-era "빈 독" 버그 근본원인(GSettings memory 백엔드 = 프로세스별·비영속) 규명 → gschema.override 기본값 + `GSETTINGS_BACKEND=keyfile`로 정공 해결.
- **picom 컴포지터 + Marux 유리 테마 (arm64-v15, 2026-07-29)** — picom v11.2(xrender+vsync) + macOS풍 라운드 반투명 유리 독 테마.
- **라이브 디버그 픽스 4종 (arm64-v16, 2026-07-29, SHA `57daa20a…`)** — ①클릭 창전환(openbox rc.xml Client 컨텍스트 마우스바인드 부재 — 1.x부터 잠복한 버그, 공유 `config/openbox/rc.xml` 수정으로 x86 트랙도 동시 픽스) ②bamfdaemon 세그폴트 근원 규명(libwnck가 startup-notification 없이 빌드됨) 후 재빌드 *(→ 후일 재규명 2026-08-14: SN 부재는 근원 아님 — v16 실기기에서도 세그폴트 재현. 실근원 = libwnck 43.0 업스트림 버그(`invalidate_icons` NULL 가드 부재, 43.2에서 수정) → 43.2 버전업으로 해결, v17 탑재 예정)* ③유리 테마 확정값(라운드 10 + 알파 95) ④HDMI 콘솔 경고 스팸 제거.
- **하이브리드 디스크 이미지** — `MaruxOS-2.0.0-arm64.img.xz` (Pi는 ISO9660 부팅 불가 → USB dd → microSD 설치 패턴). 릴리즈 이미지 **arm64-v34** (2026-08-27, 384 MB, root/marux, tty1 자동 로그인 — SHA `1a6cbcc0…`; v28 Qt FORTIFY 픽스, v31 FeatherPad, v32 LXImage-Qt·SpeedCrunch·LXQt Archiver·qps, v33 다이어트+라이선스 동봉).
- ARM64 빌드 게이트 — 빌드 루트 / cross-toolchain / 산출물명 / 커널 ARCH를 강제 검증해 x86_64 트랙과 완전 분리.
- **libwnck 43.2 진짜 픽스 (arm64-v17, 2026-08-14, 실기기 전항목 검증 ✅, SHA `767ec40e…`)** — bamfdaemon 세그폴트의 실근원은 startup-notification 부재가 아니라 **libwnck 43.0 업스트림 버그**(`invalidate_icons` NULL 가드 부재)였고 43.2로 해결. 독 실행 점·실행 앱 클릭 창전환까지 동작 → **배치 P(Plank) 공식 종결**.
- **WiFi 무선 네트워크 (arm64-v18~v24, 2026-08-14~23, 실기기 검증 ✅)** — 커널 wireless 스택 7종 `=y` 재빌드 + brcmfmac + Cypress 43455 펌웨어/NVRAM/regulatory.db를 `CONFIG_EXTRA_FIRMWARE`로 임베드(builtin 드라이버는 rootfs 마운트 전에 펌웨어를 요청하므로 initrd로는 늦다) + wpa_supplicant 2.11(`CONFIG_DRIVER_NL80211_BRCM`). **`ASSOCIATED` 무한루프의 진범은 brcmfmac FWSUP** — 펌웨어 supplicant가 EAPOL을 가로채고 4-way를 완주하지 못했다. `feature.c` 패치로 FWSUP를 끄고 **host 4-way를 강제**해 정복. 유선을 뽑은 상태에서 DHCP·인터넷 검증 완료.
- **자체 제작 퀵설정 GUI + 우상단 통합 상태 바 (arm64-v18~v25, vala/GTK3)** — `marux-quicksettings`: `한/A · WiFi 아이콘 · 볼륨% │ 2줄 시계`를 한 덩어리로 묶은 상태 바 + 드롭다운(WiFi 스캔/연결·볼륨 슬라이더·IP 표시). 배경은 GTK CSS가 아닌 **cairo 직접 페인팅**(호버 밝기 전환 포함), 창은 **override-redirect**로 띄워 독 유령창 회피. **v22에서 tint2 은퇴**.
- **한/영 입력 상태 정확 표시** — ibus 패널 D-Bus를 구현하는 대신 **ibus-hangul 엔진 소스에 상태 export 패치**를 넣어 `ibus_hangul_engine_set_input_mode` 단일 수렴점에서 상태를 파일로 내보내는 정공 우회. 실기기 검증 완료.
- **부팅 안정성: `root=PARTUUID` + fstab `LABEL` (arm64-v20)** — SDIO WiFi가 mmc 호스트 인덱스를 밀어 `mmcblk` 번호가 바뀌는 문제. 커널 cmdline은 udev가 없으므로 **PARTUUID**, 유저스페이스 fstab은 **LABEL** — 계층마다 다른 해법. MBR disk-id를 `0x4d415258`로 고정해 PARTUUID를 결정론적으로 만듦.
- **음량 제어** — alsa-utils 1.2.10 + `/etc/asound.conf` softvol `Master` (그전까지 alsa-lib만 있어 `amixer`가 없었음).
- **QTerminal (arm64-v26, 2026-08-25)** — `xterm` → **QTerminal 0.17.0**. Qt5 5.15.2 12종 + xcb 플랫폼 플러그인 + qtermwidget + lxqt-build-tools를 **호스트 크로스 컴파일**로 빌드(MaruxOS 최초 — 그전까지는 전부 qemu chroot 네이티브).
- **PCManFM-Qt (arm64-v27, 2026-08-25)** — `mc` → **PCManFM-Qt 0.17.0**. `libexif → libfm(--with-extra-only) → menu-cache → libfm-qt → pcmanfm-qt` 사슬을 전부 소스에서 크로스 빌드. **1.x에서 PCManFM(GTK)이 GLib 2.68을 요구해 시스템을 망가뜨린 사고를 Qt 경로로 정공 해소.** `mc`·`xterm`은 폴백으로 잔류.

### Added (x86_64 desktop parity — cooked-v10, 2026-08-28)
- **x86_64 ISO도 Pi 이미지와 동일한 Qt 데스크톱** — ARM64 크로스 체계(호스트 gcc-13 + `--sysroot`)를 x86 rootfs 사본(`x86-parity/`)에 재사용해 Qt5 5.15.2·QTerminal·PCManFM-Qt·FeatherPad·LXImage-Qt·SpeedCrunch·LXQt Archiver·qps·Plank(libwnck 43.2)·picom·`marux-quicksettings`·alsa-utils·ibus-hangul 한/A 패치·shared-mime DB 이식. tint2/xterm/mc는 폴백으로만 잔류. rc.xml Win+T/E → qterminal/pcmanfm-qt.
- **이미지 다이어트 1.24 GB → 238 MB** — 스테이징 슬림(소스·헤더·컴파일러·python 제거, strip) + squashfs **xz**(2.0.0 커널 내장; 1.x는 gzip만) + `/usr/share/licenses/` 동봉 + 원본 rootfs부터 깨져 있던 dangling 모듈 18개 자동 제거.
- 게이트: FORTIFY=2 검증 마커, `.desktop` config 바이트 일치, libwnck 실해석, 핵심 바이너리 16종 chroot ldd, 슬림 사본에서 Qt 7종 기동(Xvfb). **QEMU/KVM 스크린샷 검증**: 자동 로그인 → 데스크톱 → QTerminal 한글 입력 → FeatherPad → PCManFM-Qt.
- 함정: x86 rootfs의 GLib 이중 상태(/usr/lib 2.80 deb 출신 런타임 vs /usr/lib64 2.78 LFS 헤더·pc), `/usr/lib/*.so → /usr/lib64` 절대 심볼릭링크를 호스트 `find -xtype l`이 오판 — Kernel-Update-Log §34.

### Status (2.0.0 릴리즈 시점)
- **2.0.0 로드맵 4/4 완주 (2026-08-25, `arm64-v27`)** — ①ARM64 데스크톱+한글 ②WiFi+퀵설정 GUI ③xterm→QTerminal ④mc→PCManFM-Qt. v27 실기기에서 QTerminal 즉사(함정 #35: 크로스 gcc 암묵 `_FORTIFY_SOURCE=3` 오탐) → v28 `=2` 재빌드로 실기기 기동 실증. 릴리즈 = v34(ARM64) + cooked-v10(x86_64).
- 알려진 미해결(릴리즈 블로커 아님): Plank 아이콘 우클릭 "닫기" 무동작 / 독 인디케이터 점 위치·크기.

### Changed
- `DISTRO_VERSION` 1.2.1 → 2.0.0
- `DISTRO_CODENAME` "Genesis" → "Cooked"
- `KERNEL_VERSION` 6.12 → 6.18.26 (실제 의도와 동기화 완료)
- 1.x 6.7.4 vmlinuz + `/lib/modules/6.7.4` → `legacy-1.x-kernel/` 백업 후 제거 (롤백 보존)

### Errata (1.x 시리즈 정정)
- 1.0~1.2.1 모든 ISO에 박혀있던 커널은 광고와 달리 **Linux 6.7.4** (2024년 1월 stable). Genesis 단계의 AI hallucination이 검증 게이트 부재로 5개월간 인프라가 됨. 2.0.0에서 정공 정정.
- 자세한 내용: `Kernel-Update-Log.md` 및 발표 자료 참고.

## [1.2.1] - 2026-05-05

### Fixed
- New File / Refresh Desktop 후 모든 바탕화면 아이콘 사라지는 버그 (v3) — `setsid`로 idesk 재시작 시 SIGHUP 차단
- 일부 바탕화면 아이콘 미표시 / 새 파일 아이콘 미표시 (v4) — PNG `marux-*` prefix 참조 통일
- 터미널 아이콘 불투명 배경 (v4) — 빌드 시 `MaruxOS 디자인/` → rootfs 아이콘 자동 동기화

### Changed
- `MaruxOS 디자인/terminal.png` → `marux-terminal.png` (이름 prefix 통일)
- CLAUDE.md 신규 — Claude Code 협업 컴파스

## [1.2.0] - 2026-05-05

### Added
- 바탕화면 우클릭 메뉴 (Openbox menu.xml) — 앱 실행, 설정, 시스템, New File/Folder/Script
- 키보드 단축키 (Alt+F4, Alt+Tab, Win+D/T/E, F11, Win+Arrow 창 스냅)
- 배경화면 변경 도구 `marux-wallpaper`
- 바탕화면 아이콘 매니저 idesk (Terminal, Files, Firefox 기본 + ~/Desktop 동기화)
- 바탕화면 헬퍼: `marux-desktop-refresh`, `marux-new-desktop-item`
- neofetch 시스템 정보 도구

## [1.0.0] - 2024-11-23

### Added
- Initial release of MaruxOS
- Linux Kernel 6.12 LTS support
- Debian Bookworm base system
- GRUB2 bootloader with custom theme
- Plymouth boot splash
- Calamares graphical installer
- Desktop environment options:
  - GNOME
  - KDE Plasma
  - XFCE
  - Cinnamon
- Live USB/CD support (Try Marux mode)
- Custom MaruxOS branding and themes
- Automated build system
- Comprehensive build scripts:
  - Environment preparation
  - Kernel download and compilation
  - Root filesystem creation
  - Desktop installation
  - GRUB configuration
  - Plymouth setup
  - Installer configuration
  - Live system creation
  - ISO generation
- Documentation:
  - README.md
  - BUILD.md - Build instructions
  - DEVELOPMENT.md - Development guide
  - FAQ.md - Frequently asked questions
  - CONTRIBUTING.md - Contribution guidelines
- Utility scripts:
  - Master build script (build-all.sh)
  - Clean script
  - VM test script
- Default applications:
  - Firefox ESR web browser
  - Thunderbird email client
  - LibreOffice suite
  - GIMP image editor
  - VLC media player
  - File manager
  - Text editor
  - Terminal
  - Calculator
  - Document viewer
- System tools:
  - Network Manager
  - PulseAudio
  - GParted
  - Synaptic
  - htop
  - neofetch
- Configuration files:
  - Release configuration
  - System defaults
  - Korean locale support (ko_KR.UTF-8)
  - English fallback (en_US.UTF-8)
  - Asia/Seoul timezone default

### Features
- BIOS and UEFI boot support
- Dual-boot capable
- Live session with persistence option
- Graphical installer with slideshow
- Multiple partition schemes support
- ext4, Btrfs, XFS filesystem support
- Automatic hardware detection
- Network configuration during install
- User account creation
- Root password configuration
- Hostname customization
- Timezone selection
- Keyboard layout selection
- Modern blue and black color scheme
- Custom plymouth theme with animation
- Branded boot menu
- Welcome screen in live mode
- Desktop wallpaper
- Login screen background
- System logos (64px, 128px, 256px, 512px)

### Technical Details
- Architecture: x86_64 (AMD64)
- Kernel: Linux 6.12 LTS
- Init System: systemd
- Package Manager: APT (Debian)
- Bootloader: GRUB2
- Installer: Calamares
- Boot Splash: Plymouth
- Base: Debian Bookworm
- Compression: squashfs with xz

### Build System
- Modular build scripts
- Parallel build support
- Incremental build capability
- Clean build option
- Skip kernel build option
- Automated dependency checking
- Error handling and validation
- Progress indication
- Build time optimization
- Checksum generation (MD5, SHA256)

### Security
- LTS kernel for long-term security updates
- Debian security repository enabled
- sudo for privilege escalation
- AppArmor profiles (from Debian)
- Firewall ready (ufw available)
- SSH server included

### Known Issues
- Initial boot may be slow on HDD
- Some WiFi adapters may need additional firmware
- Nvidia proprietary drivers not included (install post-install)
- Secure Boot not configured by default

### Notes
- First stable release
- Ready for testing and feedback
- Not recommended for production use yet
- Please report bugs and issues

---

## Release Types

- **Major** (X.0.0): Significant changes, new features, breaking changes
- **Minor** (1.X.0): New features, improvements, backwards compatible
- **Patch** (1.0.X): Bug fixes, security updates, minor improvements

## Versioning

MaruxOS follows semantic versioning:
- Version format: MAJOR.MINOR.PATCH
- Codenames: Each major version has a codename
  - 1.0 "Genesis" - The beginning

---

[Unreleased]: https://github.com/maruxos/maruxos/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/maruxos/maruxos/releases/tag/v1.0.0
