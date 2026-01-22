# MaruxOS Development Guide

**[English](#english) | [한국어](#한국어)**

---

# English

Guide for developers who want to contribute to or customize MaruxOS.

## Overview

MaruxOS is built entirely from source using **Linux From Scratch (LFS) 12.1**. Unlike Debian-based distributions, every component is compiled from source code.

| Component | Details |
|-----------|---------|
| Base | Linux From Scratch 12.1 |
| Kernel | Linux 6.12 LTS |
| Window Manager | Openbox |
| Panel | tint2 |
| Compression | gzip (squashfs) |
| Boot | GRUB |

## Build Environment

### Requirements

- **WSL** (Windows Subsystem for Linux) - Ubuntu recommended
- **Packages**: `squashfs-tools`, `grub-pc-bin`, `grub-efi-amd64-bin`, `xorriso`, `mtools`

### Directory Structure

```
/home/administrator/MaruxOS/build/
├── rootfs-lfs/                    # LFS root filesystem
│   ├── bin/
│   ├── boot/
│   ├── etc/
│   │   └── X11/xinit/xinitrc     # X startup script
│   ├── home/
│   ├── lib/
│   ├── root/
│   ├── usr/
│   │   ├── share/
│   │   │   ├── applications/     # .desktop files
│   │   │   └── pixmaps/          # Icons, wallpapers
│   │   └── ...
│   └── ...
│
├── iso-build/                     # ISO staging area
│   ├── boot/
│   │   ├── vmlinuz               # Linux kernel
│   │   ├── initrd.img            # Initial ramdisk
│   │   └── grub/
│   │       └── grub.cfg          # GRUB configuration
│   └── live/
│       └── filesystem.squashfs   # Compressed rootfs
│
└── output/                        # Final ISO files
```

## Build Process

### Step 1: Modify Root Filesystem

Edit files directly in `rootfs-lfs/`:

```bash
# Example: Edit xinitrc
nano rootfs-lfs/etc/X11/xinit/xinitrc

# Example: Add desktop entry
nano rootfs-lfs/usr/share/applications/myapp.desktop
```

### Step 2: Create Squashfs

```bash
cd /home/administrator/MaruxOS/build

# IMPORTANT: Use gzip compression (kernel doesn't support xz)
sudo mksquashfs rootfs-lfs iso-build/live/filesystem.squashfs \
    -comp gzip \
    -e boot \
    -noappend
```

### Step 3: Create ISO

```bash
sudo grub-mkrescue -o MaruxOS-1.0.iso iso-build
```

### Step 4: Copy to Windows (optional)

```bash
cp MaruxOS-1.0.iso /mnt/c/Users/Administrator/Desktop/
```

## Configuration Files

### xinitrc (`/etc/X11/xinit/xinitrc`)

The main X session startup script:

```bash
#!/bin/sh
# Environment setup
export XDG_RUNTIME_DIR=/tmp/runtime-root
mkdir -p $XDG_RUNTIME_DIR

# Network initialization
for iface in /sys/class/net/*; do
    iface_name=$(basename $iface)
    if [ "$iface_name" != "lo" ]; then
        ip link set $iface_name up
        /usr/sbin/dhcpcd $iface_name &
    fi
done

# Set wallpaper
feh --bg-fill /usr/share/pixmaps/maruxos/marux-desktop.png &

# Start window manager
openbox &

# Start panel
sleep 1
tint2 &

# Keep session alive
exec sleep infinity
```

### tint2 Panel (`~/.config/tint2/tint2rc`)

Key settings:

| Setting | Value | Description |
|---------|-------|-------------|
| `panel_items` | `L:SC` | Launcher, Separator, Systray, Clock |
| `panel_position` | `bottom center horizontal` | Bottom taskbar |
| `panel_size` | `100% 40` | Full width, 40px height |

### Desktop Entries

Location: `/usr/share/applications/`

Example `.desktop` file:

```ini
[Desktop Entry]
Name=Terminal
Comment=Terminal Emulator
Exec=xterm
Icon=utilities-terminal
Type=Application
Categories=System;TerminalEmulator;
```

## Customization

### Adding Applications

1. Compile from source in LFS environment
2. Install to `rootfs-lfs/`
3. Create `.desktop` file in `rootfs-lfs/usr/share/applications/`
4. Rebuild squashfs and ISO

### Changing Wallpaper

Replace: `rootfs-lfs/usr/share/pixmaps/maruxos/marux-desktop.png`

### Modifying Panel

Edit: `rootfs-lfs/root/.config/tint2/tint2rc`

Or use auto-sync feature in xinitrc to download from server.

## Important Notes

### Compression

**MUST use gzip**, not xz:

```bash
# CORRECT
mksquashfs ... -comp gzip

# WRONG - Will cause boot failure
mksquashfs ... -comp xz
```

The LFS kernel was compiled without xz/lzma squashfs support.

### Permissions

Run commands with `sudo` to avoid permission errors during squashfs creation.

### Boot Files

Never overwrite `iso-build/boot/` unless copying from a known working ISO.

## Troubleshooting

### Kernel Panic on Boot

- Check if `vmlinuz` and `initrd.img` exist in `iso-build/boot/`
- Verify squashfs uses gzip compression
- Check GRUB configuration

### Black Screen After startx

- Verify xinitrc exists and is executable
- Check for syntax errors in xinitrc
- Ensure openbox and tint2 commands are present

### Network Not Working

Check `/tmp/Network_log.txt` in running system for diagnostics.

## Contact

- **Discord**: `pizzamaru_`
- **Email**: marudev@outlook.kr
- **Portfolio**: https://marulee.dev
- **GitHub Issues**: Bug reports and feature requests

## Credits

| Role | Credit |
|------|--------|
| **UI/UX Design** | **tuna27** |
| **AI Development** | **Claude Code (Anthropic)** |
| Base System | Linux From Scratch |
| Kernel | kernel.org |

**Special Thanks**: Sigterm Co., Ltd. - For sponsoring Claude Code MAX plan

---

# 한국어

MaruxOS에 기여하거나 커스터마이징하려는 개발자를 위한 가이드입니다.

## 개요

MaruxOS는 **Linux From Scratch (LFS) 12.1**을 사용하여 소스 코드에서 완전히 빌드됩니다. Debian 기반 배포판과 달리 모든 구성 요소가 소스 코드에서 컴파일됩니다.

| 구성 요소 | 세부 사항 |
|-----------|-----------|
| 베이스 | Linux From Scratch 12.1 |
| 커널 | Linux 6.12 LTS |
| 윈도우 매니저 | Openbox |
| 패널 | tint2 |
| 압축 | gzip (squashfs) |
| 부트 | GRUB |

## 빌드 환경

### 요구 사항

- **WSL** (Windows Subsystem for Linux) - Ubuntu 권장
- **패키지**: `squashfs-tools`, `grub-pc-bin`, `grub-efi-amd64-bin`, `xorriso`, `mtools`

### 디렉토리 구조

```
/home/administrator/MaruxOS/build/
├── rootfs-lfs/                    # LFS 루트 파일시스템
│   ├── etc/
│   │   └── X11/xinit/xinitrc     # X 시작 스크립트
│   ├── usr/
│   │   └── share/
│   │       ├── applications/     # .desktop 파일
│   │       └── pixmaps/          # 아이콘, 배경화면
│   └── ...
│
├── iso-build/                     # ISO 스테이징 영역
│   ├── boot/
│   │   ├── vmlinuz               # Linux 커널
│   │   ├── initrd.img            # 초기 램디스크
│   │   └── grub/
│   │       └── grub.cfg          # GRUB 설정
│   └── live/
│       └── filesystem.squashfs   # 압축된 rootfs
│
└── output/                        # 최종 ISO 파일
```

## 빌드 프로세스

### 1단계: 루트 파일시스템 수정

`rootfs-lfs/`에서 파일 직접 수정:

```bash
# 예: xinitrc 수정
nano rootfs-lfs/etc/X11/xinit/xinitrc

# 예: desktop entry 추가
nano rootfs-lfs/usr/share/applications/myapp.desktop
```

### 2단계: Squashfs 생성

```bash
cd /home/administrator/MaruxOS/build

# 중요: gzip 압축 사용 (커널이 xz 미지원)
sudo mksquashfs rootfs-lfs iso-build/live/filesystem.squashfs \
    -comp gzip \
    -e boot \
    -noappend
```

### 3단계: ISO 생성

```bash
sudo grub-mkrescue -o MaruxOS-1.0.iso iso-build
```

### 4단계: Windows로 복사 (선택)

```bash
cp MaruxOS-1.0.iso /mnt/c/Users/Administrator/Desktop/
```

## 중요 참고 사항

### 압축

**반드시 gzip 사용**, xz 아님:

```bash
# 올바름
mksquashfs ... -comp gzip

# 틀림 - 부팅 실패 발생
mksquashfs ... -comp xz
```

LFS 커널이 xz/lzma squashfs 지원 없이 컴파일되었습니다.

### 권한

squashfs 생성 중 권한 오류를 방지하려면 `sudo`로 명령 실행.

### 부트 파일

작동하는 ISO에서 복사하지 않는 한 `iso-build/boot/`를 덮어쓰지 마세요.

## 문제 해결

### 부팅 시 커널 패닉

- `iso-build/boot/`에 `vmlinuz`와 `initrd.img` 존재 확인
- squashfs가 gzip 압축 사용 확인
- GRUB 설정 확인

### startx 후 검은 화면

- xinitrc 존재 및 실행 가능 확인
- xinitrc 구문 오류 확인
- openbox와 tint2 명령 존재 확인

### 네트워크 미작동

실행 중인 시스템에서 `/tmp/Network_log.txt` 확인.

## 연락처

- **Discord**: `pizzamaru_`
- **Email**: marudev@outlook.kr
- **Portfolio**: https://marulee.dev
- **GitHub Issues**: 버그 리포트 및 기능 요청

## 크레딧

| 역할 | 크레딧 |
|------|--------|
| **UI/UX 디자인** | **tuna27** |
| **AI 개발** | **Claude Code (Anthropic)** |
| 베이스 시스템 | Linux From Scratch |
| 커널 | kernel.org |

**감사의 말**: Sigterm Co., Ltd. (시그텀 주식회사) - Claude Code MAX 플랜 지원
