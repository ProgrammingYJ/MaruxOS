# MaruxOS FAQ

**[English](#english) | [한국어](#한국어)**

---

# English

## General Questions

### Q: What is MaruxOS?
**A:** MaruxOS is **the world's first operating system built 100% with AI (Claude Code)**. It's a lightweight Linux distribution built entirely from source using Linux From Scratch (LFS) 12.0 toolchain + 12.1-era userland, not based on any existing distribution like Debian, Ubuntu, or Arch.

### Q: What makes MaruxOS special?
**A:** MaruxOS is unique because:
- **World's first 100% AI-built OS** - Every script, configuration, and build process was created using Claude Code
- **Not distribution-based** - Built directly from Linux kernel using LFS, not forked from Ubuntu/Debian/Arch
- **Pure from-scratch build** - Every component compiled from source code

### Q: Is MaruxOS based on Debian/Ubuntu?
**A:** No. MaruxOS is built from scratch using LFS (Linux From Scratch). Unlike most Linux distros that fork from existing distributions, MaruxOS starts from the Linux kernel itself. Every component is compiled from source code, making it a completely independent operating system.

### Q: What kernel version does MaruxOS use?
**A:** MaruxOS 2.0.0 "Cooked" uses Linux kernel 6.18.26 LTS. The 1.x series advertised 6.12 LTS but was actually shipping 6.7.4 due to a Genesis-stage AI hallucination that survived 5 months until 2026-05-05 (see CHANGELOG Errata).

### Q: Can I install MaruxOS to my hard drive?
**A:** Not yet. MaruxOS only supports live boot mode. Disk installation will be added in a future release.

---

## Technical Questions

### Q: Why does the boot screen show "Phoenix" or "67"?
**A:** Codename history:
- "Phoenix" — original codename (1.0 early development)
- "67" — 1.0 release through 1.2.x (the meme era)
- **"Cooked"** — 2.0.0 onwards. Meta-self-reference to LLM hallucination duality ("AI is brilliant but a chronic liar"). Older boot messages from cached squashfs may still show the previous codenames.

### Q: Is there a GUI file manager?
**A:** Yes — **PCManFM-Qt** (2.0.0, both architectures: dock icon "Files", Win+E). History: the GTK PCManFM needed a newer GLib than the LFS base, so 1.x shipped mc (Midnight Commander). In 2.0.0 the Qt5 stack landed with QTerminal and the whole chain (libexif → libfm → menu-cache → libfm-qt → pcmanfm-qt) was cross-built from source — ARM64 v27, x86_64 cooked-v10 — so the GLib conflict never arises. mc is kept as a terminal fallback.

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

### Q: How do I restart the dock / status bar?
**A:**
```bash
killall plank
/usr/bin/plank &   # status bar: killall marux-quicksettings; /usr/bin/marux-quicksettings &
```

### Q: Where are configuration files located?
**A:**
- Dock launchers: `~/.config/plank/dock1/launchers/*.dockitem` (defaults in `/etc/skel`) · dock settings: GSettings keyfile `~/.config/glib-2.0/settings/keyfile` (defaults `/usr/share/glib-2.0/schemas/40_maruxos.gschema.override`)
- Openbox: `~/.config/openbox/rc.xml`
- System-wide xinitrc: `/etc/X11/xinit/xinitrc`

---

## Troubleshooting

### Q: Screen is black after startx
**A:** Check the xinitrc file:
```bash
cat /etc/X11/xinit/xinitrc
```
Make sure the `openbox`, `plank` and `marux-quicksettings` commands are present, then check `/tmp/plank.log`, `/tmp/quicksettings.log`, `/tmp/picom.log`.

### Q: startx doesn't start automatically
**A:** Check if `.bash_profile` exists and contains:
```bash
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    startx   # not exec: if X exits you get the shell back (2.0.0 policy)
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
- **Email**: contact@marulee.dev
- **Portfolio**: https://marulee.dev
- **GitHub Issues**: Report bugs and feature requests

---

# 한국어

## 일반 질문

### Q: MaruxOS가 뭔가요?
**A:** MaruxOS는 **세계 최초로 100% AI(Claude Code)만으로 제작된 운영체제**입니다. Linux From Scratch (LFS) 12.0 툴체인 + 12.1-era 유저랜드를 사용하여 소스 코드부터 완전히 빌드된 경량 리눅스로, 데비안, 우분투, 아치 등 기존 배포판을 기반으로 하지 않습니다.

### Q: MaruxOS의 특별한 점은?
**A:** MaruxOS가 특별한 이유:
- **세계 최초 100% AI 제작 OS** - 모든 스크립트, 설정, 빌드 과정이 Claude Code로 제작됨
- **배포판 기반 아님** - 우분투/데비안/아치에서 포크하지 않고 리눅스 커널부터 LFS로 직접 빌드
- **순수 처음부터 빌드** - 모든 구성 요소가 소스 코드에서 컴파일됨

### Q: MaruxOS는 데비안/우분투 기반인가요?
**A:** 아니요. MaruxOS는 LFS (Linux From Scratch)를 사용하여 처음부터 빌드됩니다. 대부분의 리눅스 배포판이 기존 배포판에서 포크하는 것과 달리, MaruxOS는 리눅스 커널 자체부터 시작합니다. 모든 구성 요소가 소스 코드에서 컴파일되어 완전히 독립적인 운영체제입니다.

### Q: MaruxOS는 어떤 커널 버전을 사용하나요?
**A:** MaruxOS 2.0.0 "Cooked"는 Linux 커널 6.18.26 LTS를 사용합니다. 1.x 시리즈는 광고로는 6.12 LTS였으나 실제로는 Genesis 단계 AI hallucination으로 6.7.4가 박혀있었고, 2026-05-05에 발견되어 정공으로 정정되었습니다 (CHANGELOG Errata 참고).

### Q: MaruxOS를 하드 드라이브에 설치할 수 있나요?
**A:** 아직 안 됩니다. MaruxOS는 라이브 부팅 모드만 지원합니다. 디스크 설치는 향후 릴리스에서 추가될 예정입니다.

---

## 기술 질문

### Q: 부팅 화면에 "Phoenix"가 표시되는 이유는?
**A:** 코드네임 변천사:
- "Phoenix" — 1.0 초기 개발 중 사용된 원래 코드네임
- "67" — 1.0 릴리즈부터 1.2.x까지 (밈 시기)
- **"Cooked"** — 2.0.0부터. LLM hallucination 양면성("AI는 명석하지만 거짓말쟁이")의 메타-자기참조. 이전 squashfs 캐시에서 옛 코드네임이 표시될 수 있습니다.

### Q: GUI 파일 관리자가 있나요?
**A:** 있습니다 — **PCManFM-Qt**(2.0.0, 양 아키텍처: 독 "Files" 아이콘, Win+E). 역사: 1.x에서는 GTK판 PCManFM이 LFS 베이스보다 새 GLib을 요구해 mc(Midnight Commander)를 썼습니다. 2.0.0에서 QTerminal과 함께 Qt5 스택이 들어왔고 의존성 사슬(libexif → libfm → menu-cache → libfm-qt → pcmanfm-qt)을 통째로 소스 크로스 빌드 — ARM64 v27, x86_64 cooked-v10 — 해서 GLib 충돌이 발생하지 않습니다. mc는 터미널 폴백으로 남아 있습니다.

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

### Q: 독 / 상태 바를 어떻게 재시작하나요?
**A:**
```bash
killall plank
/usr/bin/plank &   # 상태 바: killall marux-quicksettings; /usr/bin/marux-quicksettings &
```

### Q: 설정 파일 위치는 어디인가요?
**A:**
- 독 런처: `~/.config/plank/dock1/launchers/*.dockitem` (기본값 `/etc/skel`) · 독 설정: GSettings keyfile `~/.config/glib-2.0/settings/keyfile` (기본값 `/usr/share/glib-2.0/schemas/40_maruxos.gschema.override`)
- Openbox: `~/.config/openbox/rc.xml`
- 시스템 전역 xinitrc: `/etc/X11/xinit/xinitrc`

---

## 문제 해결

### Q: startx 후 검은 화면
**A:** xinitrc 파일 확인:
```bash
cat /etc/X11/xinit/xinitrc
```
`openbox`, `plank`, `marux-quicksettings` 명령이 있는지 확인하고 `/tmp/plank.log`, `/tmp/quicksettings.log`, `/tmp/picom.log`를 보세요.

### Q: startx가 자동으로 시작되지 않음
**A:** `.bash_profile`이 존재하고 다음 내용이 포함되어 있는지 확인:
```bash
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    startx   # not exec: if X exits you get the shell back (2.0.0 policy)
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
