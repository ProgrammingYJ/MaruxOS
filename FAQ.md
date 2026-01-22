# MaruxOS FAQ

**[English](#english) | [한국어](#한국어)**

---

# English

## General Questions

### Q: What is MaruxOS?
**A:** MaruxOS is **the world's first operating system built 100% with AI (Claude Code)**. It's a lightweight Linux distribution built entirely from source using Linux From Scratch (LFS) 12.1, not based on any existing distribution like Debian, Ubuntu, or Arch.

### Q: What makes MaruxOS special?
**A:** MaruxOS is unique because:
- **World's first 100% AI-built OS** - Every script, configuration, and build process was created using Claude Code
- **Not distribution-based** - Built directly from Linux kernel using LFS, not forked from Ubuntu/Debian/Arch
- **Pure from-scratch build** - Every component compiled from source code

### Q: Is MaruxOS based on Debian/Ubuntu?
**A:** No. MaruxOS is built from scratch using LFS (Linux From Scratch). Unlike most Linux distros that fork from existing distributions, MaruxOS starts from the Linux kernel itself. Every component is compiled from source code, making it a completely independent operating system.

### Q: What kernel version does MaruxOS use?
**A:** MaruxOS 1.0 uses Linux kernel 6.12 LTS.

### Q: Can I install MaruxOS to my hard drive?
**A:** Not yet. MaruxOS 1.0 only supports live boot mode. Disk installation will be added in a future release.

---

## Technical Questions

### Q: Why does the boot screen show "Phoenix"?
**A:** "Phoenix" was the original codename during development. The current codename is "67". Some boot messages may still show the old name.

### Q: Why is there no GUI file manager?
**A:** GUI file managers like PCManFM require newer GLib versions that are incompatible with the current LFS system. We use mc (Midnight Commander), a powerful terminal-based file manager instead.

### Q: Why does Firefox show security warnings?
**A:** Firefox runs with `--no-sandbox` flag for compatibility with the LFS environment. This is expected behavior and doesn't affect normal browsing.

### Q: Why doesn't the network work?
**A:** Network should work automatically via DHCP. If it doesn't:
1. Check if the interface is up: `ip link`
2. Manually bring it up: `ip link set <interface> up`
3. Run DHCP: `dhcpcd <interface>`
4. Check the network log: `cat /tmp/Network_log.txt`

### Q: How do I change the desktop wallpaper?
**A:** Use feh:
```bash
feh --bg-fill /path/to/your/image.png
```

### Q: How do I restart the panel?
**A:**
```bash
killall tint2
tint2 &
```

### Q: Where are configuration files located?
**A:**
- Panel: `~/.config/tint2/tint2rc`
- Openbox: `~/.config/openbox/rc.xml`
- System-wide xinitrc: `/etc/X11/xinit/xinitrc`

---

## Troubleshooting

### Q: Screen is black after startx
**A:** Check the xinitrc file:
```bash
cat /etc/X11/xinit/xinitrc
```
Make sure openbox and tint2 commands are present and not corrupted.

### Q: startx doesn't start automatically
**A:** Check if `.bash_profile` exists and contains:
```bash
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec startx
fi
```

### Q: "command not found" errors
**A:** The command may not be installed in the LFS system. MaruxOS includes only essential software.

### Q: How do I shut down?
**A:**
```bash
poweroff
```
Or:
```bash
shutdown -h now
```

---

## Development Questions

### Q: How is the ISO built?
**A:** Using WSL with these steps:
1. Modify files in `rootfs-lfs/`
2. Create squashfs: `mksquashfs rootfs-lfs iso-build/live/filesystem.squashfs -comp gzip -e boot -noappend`
3. Create ISO: `grub-mkrescue -o output.iso iso-build`

### Q: Why gzip compression instead of xz?
**A:** The LFS kernel was compiled without xz/lzma squashfs support. Using xz would cause boot failures.

### Q: Can I contribute?
**A:** Yes! Contact us on Discord: `pizzamaru_`

---

## Contact

For questions not covered here:
- **Discord**: `pizzamaru_`
- **Email**: marudev@outlook.kr
- **Portfolio**: https://marulee.dev
- **GitHub Issues**: Report bugs and feature requests

---

# 한국어

## 일반 질문

### Q: MaruxOS가 뭔가요?
**A:** MaruxOS는 **세계 최초로 100% AI(Claude Code)만으로 제작된 운영체제**입니다. Linux From Scratch (LFS) 12.1을 사용하여 소스 코드부터 완전히 빌드된 경량 리눅스로, 데비안, 우분투, 아치 등 기존 배포판을 기반으로 하지 않습니다.

### Q: MaruxOS의 특별한 점은?
**A:** MaruxOS가 특별한 이유:
- **세계 최초 100% AI 제작 OS** - 모든 스크립트, 설정, 빌드 과정이 Claude Code로 제작됨
- **배포판 기반 아님** - 우분투/데비안/아치에서 포크하지 않고 리눅스 커널부터 LFS로 직접 빌드
- **순수 처음부터 빌드** - 모든 구성 요소가 소스 코드에서 컴파일됨

### Q: MaruxOS는 데비안/우분투 기반인가요?
**A:** 아니요. MaruxOS는 LFS (Linux From Scratch)를 사용하여 처음부터 빌드됩니다. 대부분의 리눅스 배포판이 기존 배포판에서 포크하는 것과 달리, MaruxOS는 리눅스 커널 자체부터 시작합니다. 모든 구성 요소가 소스 코드에서 컴파일되어 완전히 독립적인 운영체제입니다.

### Q: MaruxOS는 어떤 커널 버전을 사용하나요?
**A:** MaruxOS 1.0은 Linux 커널 6.12 LTS를 사용합니다.

### Q: MaruxOS를 하드 드라이브에 설치할 수 있나요?
**A:** 아직 안 됩니다. MaruxOS 1.0은 라이브 부팅 모드만 지원합니다. 디스크 설치는 향후 릴리스에서 추가될 예정입니다.

---

## 기술 질문

### Q: 부팅 화면에 "Phoenix"가 표시되는 이유는?
**A:** "Phoenix"는 개발 중 사용된 원래 코드네임입니다. 현재 코드네임은 "67"입니다. 일부 부팅 메시지에는 여전히 이전 이름이 표시될 수 있습니다.

### Q: GUI 파일 관리자가 없는 이유는?
**A:** PCManFM 같은 GUI 파일 관리자는 현재 LFS 시스템과 호환되지 않는 최신 GLib 버전이 필요합니다. 대신 강력한 터미널 기반 파일 관리자인 mc (Midnight Commander)를 사용합니다.

### Q: Firefox에서 보안 경고가 표시되는 이유는?
**A:** Firefox는 LFS 환경과의 호환성을 위해 `--no-sandbox` 플래그로 실행됩니다. 이는 예상된 동작이며 일반 브라우징에 영향을 미치지 않습니다.

### Q: 네트워크가 작동하지 않는 이유는?
**A:** 네트워크는 DHCP를 통해 자동으로 작동해야 합니다. 작동하지 않으면:
1. 인터페이스 확인: `ip link`
2. 수동 활성화: `ip link set <인터페이스> up`
3. DHCP 실행: `dhcpcd <인터페이스>`
4. 네트워크 로그 확인: `cat /tmp/Network_log.txt`

### Q: 바탕화면 배경을 어떻게 변경하나요?
**A:** feh 사용:
```bash
feh --bg-fill /path/to/your/image.png
```

### Q: 패널을 어떻게 재시작하나요?
**A:**
```bash
killall tint2
tint2 &
```

### Q: 설정 파일 위치는 어디인가요?
**A:**
- 패널: `~/.config/tint2/tint2rc`
- Openbox: `~/.config/openbox/rc.xml`
- 시스템 전역 xinitrc: `/etc/X11/xinit/xinitrc`

---

## 문제 해결

### Q: startx 후 검은 화면
**A:** xinitrc 파일 확인:
```bash
cat /etc/X11/xinit/xinitrc
```
openbox와 tint2 명령이 있고 손상되지 않았는지 확인하세요.

### Q: startx가 자동으로 시작되지 않음
**A:** `.bash_profile`이 존재하고 다음 내용이 포함되어 있는지 확인:
```bash
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec startx
fi
```

### Q: "command not found" 오류
**A:** 해당 명령이 LFS 시스템에 설치되어 있지 않을 수 있습니다. MaruxOS에는 필수 소프트웨어만 포함되어 있습니다.

### Q: 어떻게 종료하나요?
**A:**
```bash
poweroff
```
또는:
```bash
shutdown -h now
```

---

## 개발 질문

### Q: ISO는 어떻게 빌드하나요?
**A:** WSL에서 다음 단계로 빌드:
1. `rootfs-lfs/`의 파일 수정
2. squashfs 생성: `mksquashfs rootfs-lfs iso-build/live/filesystem.squashfs -comp gzip -e boot -noappend`
3. ISO 생성: `grub-mkrescue -o output.iso iso-build`

### Q: xz 대신 gzip 압축을 사용하는 이유는?
**A:** LFS 커널이 xz/lzma squashfs 지원 없이 컴파일되었습니다. xz를 사용하면 부팅 실패가 발생합니다.

### Q: 기여할 수 있나요?
**A:** 네! Discord로 연락주세요: `pizzamaru_`

---

## 문의

여기서 다루지 않은 질문이 있으시면:
- **Discord**: `pizzamaru_`
- **Email**: marudev@outlook.kr
- **Portfolio**: https://marulee.dev
- **GitHub Issues**: 버그 및 기능 요청
