# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## MaruxOS

LFS 12.1 기반 커스텀 Linux 배포판. WSL2에서 빌드 → squashfs Live ISO. 한글 입력기 ibus-hangul 내장.

## 협업 원칙

- **한국어로 소통한다.**
- **항상 결정을 다시 의심하라** — 사용자가 동의했어도, 코드 작성 직전 한 번 더 자문: "이게 진짜 최선인가? 더 단순한 길은? 잘못된 가정은 없나?" 의심이 남으면 코드 치기 전에 사용자에게 다시 묻는다. 침묵하고 진행하지 말 것.
- **안정성 최우선.** 의존성/버전은 이중 체크. 커널·빌드·부트 영역 변경은 가설 → 검증 → 실행 순서로.
- **빌드 스크립트는 `set -e` 사용 중** — 한 줄 실패 = 전체 중단. 에러 핸들링/`|| true` 신중히.
- **이 프로젝트는 "AI의 한계를 도전"하는 실험.** 이 파일은 컴파스이지 족쇄가 아님. 정책이 길을 막으면 사용자에게 알리고 협의.

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
- `config/xinitrc` — X 세션 시작점 (locale, ibus-daemon, dhcpcd, openbox, idesk, tint2 모두 여기서 기동).
- `config/openbox/{rc.xml,menu.xml}` — 우클릭 메뉴 + 키바인드 (Win+T/D/E 등).
- `config/scripts/marux-*` — 게스트 시스템에서 동작하는 헬퍼 (wallpaper, desktop-refresh, new-desktop-item).
- `scripts/build-X.Y.Z-67-vN.sh` — 릴리즈별 빌드 스크립트. 버전별로 새 파일 생성 (이전 버전 보존). 헤더에 변경/버그픽스 코멘트 명시.
- `scripts/install-*.sh` — 빌드 스크립트가 호출하는 패키지별 설치 모듈 (ibus-hangul, idesk, neofetch).
- `iso/boot/grub/grub.cfg` — GRUB 부트로더 (정적 경로 `/boot/vmlinuz` 사용 — 커널 버전 무관).
- `/usr/bin/marux-splash` — 부팅 스플래시 (게스트 측 경로).

## 알아둘 제약

- **버전은 사용자가 지정한다.** 자동 bump 금지. 현재 진행: 1.2.0 (idesk 데스크톱) → 2.0.0 (커널 6.18 LTS + ARM64 후속).
- **PCManFM 사용 불가** — GLib 2.68+ 필요, v2~v5 빌드 실패 이력. 파일 매니저는 `mc` (Midnight Commander).
- **한글 입력**: ibus-hangul + memconf 백엔드. Wayland는 별도 패치 필요. 현재 X.org 환경.
- **바탕화면 아이콘**: idesk. `setsid`로 세션 분리 안 하면 SIGHUP에 죽음 (v3에서 수정).

## 진행 중 작업

상세한 진행 상황은 `C:\Users\Administrator\.claude\plans\` 의 plan 파일과 git log를 참조한다. 이 파일은 변하지 않는 것만 적는다.
