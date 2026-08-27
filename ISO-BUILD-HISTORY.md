# MaruxOS ISO 빌드 이력

이 문서는 MaruxOS ISO 빌드 과정에서 각 버전별 변경사항을 기록합니다.

---

## Phoenix 시리즈

### x86_64 (최초 빌드) - 2025-12-16
**파일명:** `MaruxOS-1.0-Phoenix-x86_64.iso`

**내용:**
- LFS 기반 초기 시스템 구축
- 기본 부팅 환경 설정
- 버전 번호 없는 초기 빌드

---

### x86_64 → v2 - 2025-12-16
**변경사항:**
- 버전 관리 시스템 도입
- 파일명 형식 변경: `MaruxOS-1.0-Phoenix-v2.iso`

---

### v2 → v3 - 2025-12-16
**변경사항:**
- 시스템 설정 개선
- 부팅 프로세스 수정

---

### v3 → v4 - 2025-12-16
**변경사항:**
- 커널 설정 조정
- 드라이버 추가

---

### v4 → v5 - 2025-12-16
**변경사항:**
- initrd 구성 개선
- 하드웨어 지원 확대

---

### v5 → v6 - 2025-12-16
**변경사항:**
- Live CD 기반 구조 구축
- squashfs 파일시스템 적용

---

### v6 → v7 - 2025-12-16
**변경사항:**
- GRUB 부트로더 설정
- 부트 메뉴 구성

---

### v7 → v8 - 2025-12-16
**변경사항:**
- 기본 쉘 환경 완성
- 시스템 안정화

---

### v8 → v9 - 2025-12-16
**변경사항:**
- 부팅 안정성 개선
- 기본 유틸리티 추가

---

### v9 → v10 - 2025-12-16
**변경사항:**
- 시스템 테스트 및 버그 수정
- 패키지 구성 최적화

---

### v10 → v11 - 2025-12-17
**변경사항:**
- 추가 패키지 통합
- 시스템 설정 개선

---

### v11 → v12 - 2025-12-17
**변경사항:**
- 버그 수정
- 성능 최적화

---

### v12 → v13 - 2025-12-17
**변경사항:**
- 시스템 안정화
- 설정 파일 정리

---

### v13 → v14 - 2025-12-17
**변경사항:**
- 추가 기능 구현
- 테스트 및 검증

---

### v14 → v15 - 2025-12-17
**변경사항:**
- 안정화 작업
- 최종 테스트

---

### v15 → v16 - 2025-12-17
**변경사항:**
- 시스템 구성 변경
- 패키지 업데이트

---

### v16 → v17 - 2025-12-17
**변경사항:**
- 설정 최적화
- 버그 수정

---

### v17 → v18 - 2025-12-17
**변경사항:**
- 추가 개선사항
- 시스템 테스트

---

### v18 → v19 - 2025-12-17
**변경사항:**
- 기능 개선
- 안정화 작업

---

### v19 → v20 - 2025-12-17
**변경사항:**
- 시스템 최적화
- 설정 변경

---

### v20 → v21 - 2025-12-17
**변경사항:**
- 추가 패키지 통합
- 버그 수정

---

### v21 → v22 - 2025-12-17
**변경사항:**
- 시스템 개선
- 테스트 진행

---

### v22 → v23 - 2025-12-17
**변경사항:**
- 안정화 작업
- 설정 정리

---

### v23 → v24 - 2025-12-17
**변경사항:**
- 데스크톱 환경 준비 작업
- X11 기반 구성 시작

---

### v24 → v25 - 2025-12-18
**변경사항:**
- Openbox 윈도우 매니저 추가
- 기본 데스크톱 환경 구성 시작
- X11 환경 설정

---

### v25 → v26 - 2025-12-18
**변경사항:**
- 데스크톱 환경 패키지 통합 (feh, tint2)
- Openbox 테마 설정

---

### v26 → v27 - 2025-12-18
**변경사항:**
- squashfs 압축 방식 변경: `xz` → `gzip`
- **문제 해결:** 커널이 xz 압축을 지원하지 않아 부팅 실패하던 문제

---

### v27 → v28 - 2025-12-18
**변경사항:**
- xfwm4에서 Openbox로 윈도우 매니저 변경
- **문제 해결:** xfwm4 테마 "Clearlooks" 미설치 에러

---

### v28 → v29 - 2025-12-18
**변경사항:**
- Openbox 테마 복사 (Clearlooks-Phenix 등)
- 기본 테마 적용

---

### v29 → v30 - 2025-12-18
**변경사항:**
- XDG_RUNTIME_DIR 환경변수 설정 추가
- **문제 해결:** "XDG_RUNTIME_DIR not set" 에러

---

### v30 → v31 - 2025-12-18
**변경사항:**
- xinitrc 수정: Openbox autostart 대신 직접 앱 실행
- feh, tint2 실행 코드를 xinitrc로 이동
- **문제 해결:** Openbox autostart가 실행되지 않던 문제

---

### v31 → v32 - 2025-12-19
**변경사항:**
- xterm 터미널 추가
- menu.xml 수정 (Terminal → xterm)
- **문제 해결:** maruxos-terminal 바이너리 미존재 문제

---

### v32 → v33 - 2025-12-19
**변경사항:**
- Imlib2 라이브러리 및 로더 복사
- libpng, libjpeg 의존성 추가
- **문제 해결:** feh "No Imlib2 loader" 에러 (1차 시도)

---

## 67 시리즈 (코드네임 변경: Phoenix → 67)

### v33 → 67-v1 - 2025-12-19
**변경사항:**
- 코드네임 변경: Phoenix → 67
- /etc/maruxos-release 및 /etc/os-release 업데이트
- Imlib2 로더 경로 심볼릭 링크 생성
  - `/usr/lib/x86_64-linux-gnu/imlib2/loaders` → `/usr/lib/imlib2/loaders`
- **문제 해결:** feh가 Imlib2 로더를 찾지 못하던 문제 (완전 해결)
- **결과:** ✅ 배경화면 정상 작동

---

### 67-v1 → 67-v2 - 2025-12-19
**변경사항:**
- GRUB 메뉴 엔트리 코드네임 67로 변경
- grub.cfg 업데이트

---

### 67-v2 → 67-v3 - 2025-12-19
**변경사항:**
- GLib 라이브러리 복사 시도 (libglib, libgio, libgobject 등)
- libfm, libmenu-cache 복사
- **목적:** pcmanfm 파일 관리자의 `g_once_init_leave_pointer` 심볼 에러 해결 시도
- **결과:** ❌ 여전히 pcmanfm 실행 불가

---

### 67-v3 → 67-v4 - 2025-12-20
**변경사항:**
- pcmanfm 및 모든 의존성 라이브러리 완전 복사 (ldd 기반)
- 70개 이상의 라이브러리 복사 (libfm, libgio, libglib, libc 등)
- **결과:** ❌ 커널 패닉 발생
  ```
  Kernel panic - not syncing: Attempted to kill init! exit code=0x00007f00
  ```
- **원인:** libc.so.6 등 핵심 시스템 라이브러리 덮어쓰기로 init 프로세스 사망

---

### 67-v4 → 67-v5 - 2025-12-20
**변경사항:**
- 67-v3 기반으로 롤백
- pcmanfm 완전 제거
- xinitrc에서 `pcmanfm --desktop` 호출 제거
- menu.xml에서 File Manager 항목 제거
- **결과:** ✅ 정상 부팅, 배경화면 + tint2 패널 작동

---

### 67-v5 → 67-v6 - 2025-12-20
**변경사항:**
- xfe (X File Explorer) 파일 관리자 추가
- FOX 툴킷 라이브러리 복사 (libFOX-1.6.so 등)
- menu.xml에 File Manager 항목 추가
- tint2 런처에 xfe 추가
- .desktop 파일 생성 (xterm.desktop, xfe.desktop)
- **결과:** xfe 실행 시 "Running Xfe as root!" 경고 표시 후 OK 클릭 필요

---

### 67-v6 → 67-v7 - 2025-12-20
**변경사항:**
- xfe 래퍼 스크립트 생성 (root 경고 우회 시도)
- Adwaita 아이콘 테마 복사
- GTK 설정 파일 추가
- xfe 설정 파일 생성 (root_warn=0)
- **결과:** ❌ xfe Segmentation fault 발생
  ```
  bash-5.2# xfe
  Segmentation fault
  ```
- **원인:** FOX 라이브러리와 시스템 라이브러리 간 호환성 문제

---

### 67-v7 → 67-v8 - 2025-12-20
**변경사항:**
- xfe 완전 제거 (FOX 라이브러리 호환성 문제)
- mc (Midnight Commander) 파일 관리자로 교체
- mc 의존성 복사:
  - libslang.so.2
  - libgpm.so.2
  - libe2p.so.2
  - libssh2.so.1
  - libext2fs.so.2
  - libgmodule-2.0.so.0
  - libcrypto.so.3
- mc 데이터 파일 복사 (/usr/share/mc/)
- menu.xml 수정: File Manager → `xterm -e mc`
- mc.desktop 파일 생성
- **결과:** ✅ 파일 관리자 정상 작동 (터미널 기반)

---

### 67-v8 → 67-v9 - 2025-12-20
**변경사항:**
- 배경화면 이미지 업데이트
- marux-desktop.png 새 디자인 적용
- **결과:** ✅ 새 배경화면 적용 완료

---

### 67-v9 → 67-v10 - 2025-12-20
**변경사항:**
- Openbox 테마 완전 재설정 (윈도우 버튼 스타일 포함)
- titleLayout 설정: NLIMC (아이콘, 제목, 최소화, 최대화, 닫기)
- 윈도우 버튼 색상 스타일 추가
  - 기본: 파란색 그라데이션
  - 닫기 버튼 hover: 빨간색
- Adwaita 아이콘 테마 전체 복사
- GTK 2.0/3.0 아이콘 설정 파일 생성
- **문제:** 버튼 hover는 작동하나 클릭 이벤트 미작동

---

### 67-v10 → 67-v11 - 2025-12-23
**변경사항:**
- Openbox rc.xml 완전 재작성
- 모든 마우스 바인딩 추가:
  - Close 버튼: Press → Focus/Raise, Click → Close
  - Maximize 버튼: Press → Focus/Raise, Click → ToggleMaximize
  - Iconify 버튼: Press → Focus/Raise, Click → Iconify
- 추가 마우스 바인딩:
  - Titlebar: 드래그로 이동, 더블클릭으로 최대화
  - Frame: Alt+드래그로 이동/크기조절
  - Desktop/Root: 우클릭 메뉴
- 키보드 단축키 추가:
  - Alt+F4: 창 닫기
  - Alt+Tab: 다음 창
  - Alt+Shift+Tab: 이전 창
- **결과:** ✅ 윈도우 버튼 클릭 이벤트 작동

---

### 67-v11 → 67-v12 - 2025-12-24
**변경사항:**
- tint2 패널 완전 개편
- 커스텀 아이콘 적용:
  - marux-terminal.png (터미널 아이콘)
  - marux-file-manager.png (파일 관리자 아이콘)
  - marux-logo.png (Marux 앱 메뉴 버튼)
- 시스템 트레이 추가:
  - nm-applet (WiFi 네트워크 관리)
  - volumeicon (사운드 볼륨 조절)
- Chromium 웹 브라우저 추가
- tint2 런처 구성:
  - 왼쪽: Marux 로고, 터미널, 파일 관리자, Chromium
  - 오른쪽: 시스템 트레이 (WiFi, 사운드), 시계
- xinitrc에 시스템 트레이 앱 자동 실행 추가
- **문제:** Chromium 실행 안됨, Desktop이 태스크바에 표시됨

---

### 67-v12 → 67-v13 - 2025-12-30
**변경사항:**
- Chromium 완전 재설치:
  - /usr/lib/chromium 디렉토리 전체 복사
  - NSS 라이브러리 추가
  - --no-sandbox --disable-gpu 옵션 추가
  - 래퍼 스크립트 생성
- tint2 Desktop 표시 문제 수정:
  - wm_class_filter 추가 (feh, pcmanfm-desktop)
- Openbox 설정 업데이트:
  - feh 창 skip_taskbar 설정
  - Desktop 클래스 skip_taskbar 설정
- **결과:** ✅ Desktop 태스크바 숨김 성공

---

### 67-v13 → 67-v14 - 2025-12-30
**변경사항:**
- mc 파일 관리자 개선:
  - mc.desktop에서 `mc ~ /` 명령으로 실행
  - 좌측 패널: 홈 디렉토리 (~)
  - 우측 패널: 루트 디렉토리 (/)
  - mc 기본 설정 파일 생성 (/etc/skel/.config/mc/)
- Chromium 실행 스크립트 개선:
  - 여러 경로에서 바이너리 자동 탐색
  - --disable-dev-shm-usage 옵션 추가
- **결과:** mc 좌우 패널이 다른 디렉토리 표시

---

### 67-v14 → 67-v15 - 2025-12-30
**변경사항:**
- tint2 패널 Windows 11 스타일로 변경:
  - panel_items = :LT:SC (가운데 정렬)
  - 런처 + 태스크바가 가운데에 배치
  - 시스템 트레이 + 시계는 오른쪽 유지
- 태스크바 스타일 변경:
  - task_text = 0 (텍스트 없음, 아이콘만)
  - task_maximum_size = 44 40 (아이콘 크기)
  - Windows 11처럼 아이콘만 표시
- 패널 높이 증가: 36px → 48px
- 아이콘 크기 증가: 26px → 32px
- **결과:** ✅ Windows 11 스타일 가운데 정렬 태스크바

---

### 67-v15 → 67-v16 - 2026-01-02
**변경사항:**
- Firefox 브라우저 설치:
  - Mozilla에서 직접 tarball 다운로드
  - /opt/firefox에 설치
  - 래퍼 스크립트 생성 (/usr/bin/firefox)
  - 샌드박스 비활성화 옵션 추가
- Chromium 제거 (LFS에서 snap/apt 사용 불가)
- 태스크바 웹 브라우저 아이콘 → Firefox로 변경
- ISO 크기 증가: 1.1GB → 1.2GB
- **결과:** ❌ Firefox 실행 안됨 (라이브러리 의존성 문제)

---

### 67-v16 → 67-v17 - 2026-01-03
**변경사항:**
- Firefox 디버그 모드 추가:
  - 래퍼 스크립트에서 오류 메시지 표시
  - xterm -hold로 실행하여 오류 확인 가능
  - LD_LIBRARY_PATH에 /opt/firefox 추가
- 추가 샌드박스 비활성화 옵션:
  - MOZ_DISABLE_RDD_SANDBOX
  - MOZ_DISABLE_SOCKET_PROCESS_SANDBOX
- 추가 라이브러리 복사:
  - GTK3, Pango, Cairo, GLib 관련 라이브러리
  - X11, XCB, xkbcommon 라이브러리
  - DBus, ATK, ATSPI 라이브러리
  - 폰트, 이미지, 압축 관련 라이브러리
  - GIO, GTK, GDK-pixbuf 모듈
- **결과:** ✅ Firefox 실행 성공 (로케일 경고 표시)

---

### 67-v17 → 67-v18 - 2026-01-03
**변경사항:**
- Firefox 로케일 경고 수정:
  - LANG=C.UTF-8, LC_ALL=C.UTF-8 환경변수 설정
  - xinitrc에도 동일한 로케일 설정 추가
  - 2>/dev/null로 stderr 숨김
- 시스템 트레이 유틸리티 스크립트 추가:
  - /usr/bin/volume-control (pavucontrol 또는 alsamixer)
  - /usr/bin/network-settings (nm-connection-editor 또는 nmtui)
  - /usr/bin/quick-settings (빠른 설정 메뉴)
- tint2 설정 업데이트:
  - 시스템 트레이 아이콘 크기 증가: 20px → 24px
  - 시계 클릭 시 quick-settings 실행
- xinitrc 업데이트:
  - nm-applet, volumeicon 자동 실행 설정
  - GTK 테마 환경변수 설정
- .desktop 파일 수정:
  - Terminal=false로 xterm 없이 Firefox 실행
- **결과:** ✅ Firefox 정상 작동, 시스템 트레이 아이콘 대기 중 (커스텀 이미지 필요)

---

### 67-v18 → 67-v19 - 2026-01-04
**변경사항:**
- MaruxOS 커스텀 아이콘 테마 생성:
  - /usr/share/icons/MaruxOS/ 디렉토리 구조 생성
  - index.theme 파일 생성 (Adwaita 상속)
- 앱 아이콘 적용:
  - terminal.png → utilities-terminal.png
  - marux-file-manager.png → system-file-manager.png
- 시스템 트레이 아이콘 적용:
  - WiFi: wifi_0~4.png → network-wireless-signal-*
  - 사운드: sound_0~3.png → audio-volume-*
  - 네트워크: InternetLan.png, internetNotConnected.png
- tint2 설정 업데이트:
  - launcher_icon_theme = MaruxOS
  - chromium.desktop → firefox.desktop
- .desktop 파일 아이콘 경로 업데이트:
  - xterm.desktop, mc.desktop
- 배경화면 경로 수정:
  - /usr/share/pixmaps/maruxos/marux-desktop.png
- **결과:** ❌ 롤백만 되고 변경사항 미적용 (skel/.xinitrc 오류)

---

### 67-v19 → 67-v20 - 2026-01-10
**변경사항:**
- /etc/skel/.xinitrc 수정:
  - 기존: `exec xterm` (터미널만 실행)
  - 수정: 전체 데스크톱 설정 (feh, openbox, tint2, 시스템 트레이)
  - **문제 해결:** 검은 화면에 터미널만 뜨던 문제
- 배경화면 경로 수정:
  - /usr/share/backgrounds/marux-desktop.png → /usr/share/pixmaps/maruxos/marux-desktop.png 복사
  - **문제 해결:** feh가 배경화면을 찾지 못하던 문제
- root/.xinitrc 생성:
  - /etc/skel/.xinitrc 내용 복사
- GTK 아이콘 테마 설정 추가:
  - /etc/gtk-3.0/settings.ini 생성
  - /root/.config/gtk-3.0/settings.ini 생성
  - gtk-icon-theme-name=MaruxOS 설정
  - **문제 해결:** 시스템 트레이 아이콘이 MaruxOS 테마를 사용하지 않던 문제
- **결과:** ✅ 배경화면, 커스텀 아이콘 테마 정상 적용

---

### 67-v20 → 67-v21 - 2026-01-10
**변경사항:**
- tint2 패널에 시스템 아이콘 버튼 추가:
  - panel_items = :LT:BBBSC (Button 3개 추가)
  - WiFi 버튼: network-wireless-signal-excellent.png
  - 볼륨 버튼: audio-volume-high.png
  - 배터리 버튼: battery-full.png
- 배터리 아이콘 추가:
  - battery-full.png, battery-good.png, battery-low.png
  - battery-caution.png, battery-empty.png, battery-charging.png
- 버튼 클릭 동작 설정:
  - WiFi 클릭 → xterm -e nmtui
  - 볼륨 클릭 → xterm -e alsamixer
- **문제 해결:** nm-applet/volumeicon 미설치로 시스템 트레이가 비어있던 문제
- **결과:** ❌ tint2 버튼 기능 미지원

---

### 67-v21 → 67-v22 - 2026-01-10
**변경사항:**
- tint2 버튼 대신 executor (execp) 사용:
  - panel_items = LTEEESC (Executor 3개 추가)
  - 아이콘 스크립트 생성:
    - /usr/bin/tint2-network-icon
    - /usr/bin/tint2-volume-icon
    - /usr/bin/tint2-battery-icon
- 클릭 동작 설정:
  - 네트워크 클릭 → xterm -e nmtui
  - 볼륨 클릭 → xterm -e alsamixer
- **문제 해결:** tint2 버튼 기능이 LFS 버전에서 미지원
- **결과:** ✅ WiFi, 볼륨, 배터리 아이콘 표시

---

### 67-v22 → 67-v23 - 2026-01-10
**변경사항:**
- 네트워크 아이콘 스크립트 개선:
  - 실제 인터넷 연결 상태 확인 (ping 8.8.8.8)
  - 연결 안됨 → network-offline.png
  - 유선 연결 → network-wired.png
  - WiFi 연결 → 신호 강도별 아이콘 (excellent/good/ok/weak/none)
- **문제 해결:** 인터넷 연결 안됐는데 연결됨으로 표시되던 문제
- **결과:** ✅ 실제 네트워크 상태 반영

---

### 67-v23 → 67-v24 - 2026-01-11
**변경사항:**
- dhcpcd (DHCP 클라이언트) 설치:
  - /usr/sbin/dhcpcd 복사
  - /lib/services/dhcpcd 서비스 스크립트 생성
- **문제 해결:** 네트워크 드라이버(e1000)는 있었지만 DHCP 클라이언트가 없어서 IP 주소를 받지 못하던 문제
- **결과:** ✅ 자동 IP 할당 가능

---

### 67-v24 → 67-v25 - 2026-01-11
**변경사항:**
- /etc/issue 파일 코드네임 수정:
  - "Phoenix" → "67"
- **문제 해결:** 부팅 화면에 코드네임이 여전히 Phoenix로 표시되던 문제
- **결과:** ✅ 부팅 화면 코드네임 67로 표시

---

### 67-v25 → 67-v26 - 2026-01-11
**변경사항:**
- xinitrc에 dhcpcd 자동 시작 추가:
  - `/usr/sbin/dhcpcd 2>/dev/null &`
- /etc/rc.local 파일 생성:
  - 부팅 시 dhcpcd 자동 시작
- **결과:** ❌ 네트워크 인터페이스 eth0 없음 오류

---

### 67-v26 → 67-v27 - 2026-01-11
**변경사항:**
- /etc/rc.d/rc.sysinit 코드네임 수정:
  - "MaruxOS 1.0 Phoenix" → "MaruxOS 1.0 67"
- /etc/lsb-release 코드네임 수정:
  - DISTRIB_CODENAME=Phoenix → DISTRIB_CODENAME=67
  - DISTRIB_DESCRIPTION="MaruxOS 1.0 Phoenix" → "MaruxOS 1.0 67"
- /etc/sysconfig/ifconfig.eth0 삭제:
  - VMware에서 인터페이스 이름이 eno16777736로 변경됨
  - xinitrc의 dhcpcd가 자동으로 모든 인터페이스 감지
- **문제 해결:** 부팅 시 "Interface eth0 doesn't exist" 오류
- **문제 해결:** 부팅 화면에 여전히 "Phoenix" 표시되던 문제
- **결과:** ❌ 네트워크 여전히 작동 안함 (인터페이스 활성화 안됨)

---

### 67-v27 → 67-v28 - 2026-01-20
**변경사항:**
- 커널 네트워크 드라이버 확인:
  - E1000, E1000E가 built-in (=y)으로 커널에 포함됨 확인
- xinitrc 네트워크 초기화 개선:
  - `/sys/class/net/*`에서 모든 네트워크 인터페이스 탐색
  - `ip link set $iface_name up`으로 인터페이스 활성화
  - 각 인터페이스에 대해 dhcpcd 실행
  - loopback(lo) 인터페이스 제외
- **문제 해결:** 네트워크 드라이버는 있지만 인터페이스가 down 상태로 있던 문제
- **결과:** ❌ 네트워크 여전히 작동 안함

---

### 67-v28 → 67-v29 - 2026-01-20
**변경사항:**
- 네트워크 초기화 로그 추가:
  - 로그 파일: `/tmp/Network_log.txt`
  - 네트워크 인터페이스 목록 기록
  - 각 인터페이스 활성화 과정 기록
  - ip link set 명령 출력 기록
  - dhcpcd 실행 결과 및 PID 기록
  - 최종 네트워크 상태 (ip addr, ip route) 기록
- **목적:** 네트워크가 작동하지 않는 원인 진단
- **결과:** ❌ 로그 파일 생성 안됨 (xinitrc 미실행)

---

### 67-v29 → 67-v30 - 2026-01-21
**변경사항:**
- initrd init 스크립트 수정:
  - "MaruxOS 1.0 Phoenix" → "MaruxOS 1.0 67"
- **문제 해결:** 부팅 초기 화면에 "Phoenix" 표시되던 문제
- **결과:** ❌ 로그 파일 여전히 생성 안됨 (squashfs 미갱신)

---

### 67-v30 → 67-v31 - 2026-01-21
**변경사항:**
- squashfs 재빌드:
  - xinitrc 네트워크 로그 코드 포함
  - 수정된 initrd와 함께 빌드
- **결과:** ❌ 로그 파일 여전히 생성 안됨 (xinitrc 미실행 - rc.sysinit 복사 문제)

---

### 67-v31 → 67-v32 - 2026-01-21
**변경사항:**
- /etc/skel/.bash_profile 추가:
  - startx 자동 실행 코드 포함
  - rc.sysinit에서 /root로 복사되도록 설정
- **문제 해결:** rc.sysinit이 tmpfs 마운트 후 /etc/skel/에서 복사하는데 .bash_profile이 없어서 startx 미실행
- **결과:** ✅ startx 자동 실행 성공, ❌ xinitrc 여전히 미실행

---

### 67-v32 → 67-v33 - 2026-01-21
**변경사항:**
- rc.sysinit 파일 복사 명령어 수정:
  - 기존: `cp /etc/skel/.* /root/` (일부 파일만 복사됨)
  - 수정: `cp -a /etc/skel/. /root/` (모든 파일 및 디렉토리 복사)
- **문제 해결:** .xinitrc가 /root에 복사되지 않아 네트워크 로그가 생성되지 않던 문제
- **결과:** ❌ .xinitrc 여전히 복사 안됨

---

### 67-v33 → 67-v34 - 2026-01-21
**변경사항:**
- rc.sysinit에 .xinitrc 명시적 복사 추가:
  ```bash
  if [ -f /etc/skel/.xinitrc ]; then
      cp -a /etc/skel/.xinitrc /root/.xinitrc
      chmod 755 /root/.xinitrc
  fi
  ```
- **문제 해결:** `cp -a /etc/skel/. /root/`로도 .xinitrc가 복사되지 않던 문제
- **결과:** ❌ 여전히 .xinitrc 복사 안됨

---

### 67-v34 → 67-v35 - 2026-01-21
**변경사항:**
- `/etc/X11/xinit/xinitrc` (시스템 전역 xinitrc)에 네트워크 로그 코드 추가
- **문제 발견:** startx가 `~/.xinitrc` 없으면 `/etc/X11/xinit/xinitrc` 사용
- **문제 해결:** 시스템 전역 xinitrc에 네트워크 초기화 로그 코드 직접 추가
- **결과:** ✅ 네트워크 정상 작동! (DHCP IP 획득, 아이콘 상태 반영)

---

### 67-v35 → 67-v36 - 2026-01-22 ~ 01-28
**변경사항:**
- GitHub Release v1.0 배포
- 문서 전면 개편 (README, FAQ, DEVELOPMENT, LFS-BUILD-GUIDE, CONTRIBUTING)
- 라이선스 변경: MIT → Public Domain
- 빌드 히스토리 완전 재작성 (60MB 대화 로그 분석)
- **결과:** ✅ 정식 릴리즈 완료

---

### 67-v36 → 67-v37 - 2026-02-13
**변경사항:**
- Firefox 아이콘 중복 표시 문제 수정
- firefox.desktop 파일 수정:
  - `StartupWMClass=firefox` → `StartupWMClass=Navigator`
  - `StartupNotify=true` 추가
- **문제:** tint2 패널에서 Firefox 런처 아이콘과 실행 중인 창이 별도 아이콘으로 표시
- **원인:** Firefox의 실제 WM_CLASS는 `Navigator`인데 .desktop 파일에는 `firefox`로 설정되어 있었음
- **결과:** ✅ Firefox 실행 시 단일 아이콘으로 표시

---

### 67-v37 → 67-v38 - 2026-02-13
**변경사항:**
- 한국어 로케일 지원 추가
- /etc/locale.gen 파일 생성:
  - en_US.UTF-8 UTF-8
  - ko_KR.UTF-8 UTF-8 (한국어)
  - ja_JP.UTF-8 UTF-8 (일본어)
  - zh_CN.UTF-8 UTF-8 (중국어)
- /etc/locale.conf 파일 생성:
  - LANG=ko_KR.UTF-8
  - LC_CTYPE=ko_KR.UTF-8
  - LC_MESSAGES=en_US.UTF-8 (영문 시스템 메시지)
  - LC_COLLATE=C
- xinitrc 로케일 설정 개선:
  - LANG, LC_CTYPE, LC_MESSAGES, LC_COLLATE, LC_NUMERIC, LC_TIME 환경변수 설정
  - 한국어 로케일 미지원 시 en_US.UTF-8로 자동 폴백
- 한국어/일본어 입력기 설정:
  - GTK_IM_MODULE=ibus
  - QT_IM_MODULE=ibus
  - XMODIFIERS=@im=ibus
  - ibus-daemon 자동 실행 (설치 시)
- 로케일 디렉토리 생성:
  - /usr/share/locale/ko/LC_MESSAGES
  - /usr/share/locale/ja/LC_MESSAGES
  - /usr/share/locale/zh_CN/LC_MESSAGES
  - /usr/lib/locale
- **결과:** ✅ 한국어 UTF-8 인코딩 지원, 한글 입출력 환경 구축

---

### 67-v38 → 67-v44 - 2026-02-13
**변경사항:**
- v38~v43: 한국어 로케일 테스트 및 롤백
- 릴리즈 ISO에서 설정 파일 추출 및 복원
- tint2rc 위치 수정: `/etc/skel/.config/tint2/` → `/etc/xdg/tint2/`
- Desktop 파일 수정:
  - maruxos-menu.desktop → marux-menu.desktop
  - terminal.desktop, filemanager.desktop 제거
  - xterm.desktop, mc.desktop, battery.desktop, network.desktop, volume.desktop 추가
- **결과:** ✅ 릴리즈 버전으로 완전 롤백 성공

---

### 67-v44 → 67-v47 - 2026-02-13
**변경사항:**
- 완벽한 한국어 로케일 지원 추가:
  - 모든 LC_* 환경변수 한국어로 설정 (14개 변수)
  - locale.gen: ko_KR.UTF-8, ko_KR.EUC-KR 추가
  - locale.conf: 모든 LC_* 변수 설정
  - /etc/environment: 시스템 전역 로케일 설정
- xinitrc 한국어 로케일 설정:
  - LC_ALL, LC_CTYPE, LC_NUMERIC, LC_TIME, LC_COLLATE 등
  - GTK_IM_MODULE=ibus, QT_IM_MODULE=ibus, XMODIFIERS=@im=ibus
- localedef로 한국어 로케일 생성 (ko_KR.UTF-8, en_US.UTF-8)
- Nanum 폰트 설치:
  - NanumGothic (Regular, Bold, ExtraBold)
  - NanumMyeongjo (Regular, Bold)
  - 총 5개 폰트 파일 설치
- fc-cache로 폰트 캐시 업데이트
- 한국어 폰트 확인 및 경고 메시지 추가
- **결과:** ✅ 한국어 텍스트 완벽 표시, 로케일 완전 지원

---

### 67-v47 → 67-v49 - 2026-02-13
**변경사항:**
- ibus-hangul 한글 입력기 설치:
  - libhangul 0.2.0 (한글 조합 라이브러리)
  - ibus 1.5.29 (입력 버스 프레임워크)
  - ibus-hangul 1.5.5 (한글 입력 엔진)
- 한영 전환 키 수정: Ctrl+Shift+Tab → **Ctrl+P**
- GRUB 메뉴 한글 깨짐 수정:
  - "MaruxOS 1.0 (67) - 한글 입력 지원" → "MaruxOS 1.0 (67) - Korean Input"
- ibus-hangul 설치 파일:
  - /usr/lib/ibus/ibus-engine-hangul (핵심 입력 엔진)
  - /usr/share/ibus/component/hangul.xml (컴포넌트 정의)
  - /etc/xdg/autostart/ibus.desktop (자동 시작)
  - /etc/skel/.config/ibus/ibus-hangul.conf (설정 파일)
- 자판 배열: 2벌식 (QWERTY)
- 한자 변환 키: F9
- Python 3.12 'imp' 모듈 제거로 인한 GUI 설정 도구 설치 실패 (비중요)
- **결과:** ✅ 한글 타이핑 완전 지원 (Ctrl+P로 한영 전환)
- **문제:** Ctrl+P가 Firefox 인쇄 기능과 충돌

---

### 67-v49 → 67-v50 - 2026-02-13
**변경사항:**
- 한영 전환 키 수정: Ctrl+P → **Ctrl+Y**
- **문제 해결:** Firefox에서 Ctrl+P가 인쇄 기능(print)으로 선점되어 있던 문제
- install-ibus-hangul.sh 수정:
  - HangulKeys=control+p → HangulKeys=control+y
- **결과:** ✅ Firefox와 충돌 없이 한영 전환 가능

---

### 67-v50 → 67-v51 - 2026-02-13
**변경사항:**
- ibus-daemon 디버깅 강화:
  - ldd로 라이브러리 의존성 확인 로그 추가
  - `--verbose` 옵션으로 상세 로그 출력
  - exit code 체크로 ibus-daemon 실행 실패 감지
- xinitrc에 ibus-daemon 상태 진단 코드 추가
- **목적:** ibus-daemon이 실행되지만 한글 입력이 안 되는 원인 파악
- **결과:** ❌ ibus-daemon 실행은 되나 한영 전환 미작동

---

### 67-v51 → 67-v52 - 2026-02-13
**변경사항:**
- ibus-daemon `--daemonize` 옵션 제거
- 포그라운드 실행으로 실제 에러 메시지 확인:
  ```
  Can not execute default config program
  ```
- **문제 발견:** ibus 빌드 시 `--disable-dconf`로 설정 백엔드를 모두 비활성화하여 ibus가 설정을 저장/읽기 불가
- **결과:** ❌ 근본 원인 확인됨 (설정 백엔드 부재)

---

### 67-v52 → 67-v53 - 2026-02-14
**변경사항:**
- ibus 재빌드: `--enable-memconf` (메모리 기반 설정 백엔드 활성화)
- ibus-daemon 실행 옵션에 `--config=memconf` 추가
- /root/.config/ibus/bus 디렉토리 생성 추가
- install-ibus-hangul.sh에 memconf 빌드 옵션 반영
- **근본 원인 해결:**
  - 이전: `--disable-dconf`로 빌드 → 설정 백엔드 없음 → "Can not execute default config program" 크래시
  - 현재: `--enable-memconf`로 빌드 → 메모리 기반 설정 백엔드 사용
- **결과:** ✅ ibus-daemon 5개 프로세스 모두 정상 실행 (ibus-daemon, ibus-memconf, ibus-x11, ibus-portal, ibus-engine-hangul)
- **결과:** ❌ 한영 전환 여전히 미작동 (GTK가 im-ibus.so를 인식 못함)

---

### 67-v53 → 67-v54 - 2026-02-19
**변경사항:**
- **[핵심 수정 1] Wayland 의존성 패치:**
  - WSL2에서 빌드 시 GTK3 헤더에 `GDK_WINDOWING_WAYLAND`이 정의되어 im-ibus.so에 Wayland 심볼 포함
  - MaruxOS의 GTK3는 X11 전용이라 Wayland 심볼 미존재
  - 해결: ibus 소스 코드에서 `GDK_WINDOWING_WAYLAND` → `MARUX_DISABLED_WAYLAND`로 sed 패치
  - `undefined symbol: gdk_wayland_display_get_type` 에러 완전 해결
- **[핵심 수정 2] GTK3 immodules cache 수동 등록:**
  - `gtk-query-immodules-3.0`이 im-ibus.so를 캐시에 등록하지 못하는 문제
  - squashfs는 읽기 전용이므로 `/usr/lib/gtk-3.0/3.0.0/immodules.cache` 직접 수정 불가
  - 해결: `/tmp/gtk-immodules.cache`에 ibus 항목 수동 추가 후 `GTK_IM_MODULE_FILE` 환경변수로 지정
  - 빌드 스크립트에서도 immodules.cache에 ibus 항목 수동 추가
- **[핵심 수정 3] 한영 전환 동작 수정:**
  - `initial-input-mode`를 `'latin'`으로 설정 (영어 기본)
  - hangul 엔진의 `switch-keys`에 `'Hangul,Shift+space,Control+y'` 설정
  - ibus trigger 키 대신 hangul 엔진 내부 전환 메커니즘 사용
- **진단 로그 추가:**
  - xinitrc에 7단계 한글 입력 진단 로그 추가 (`/tmp/hangul-diag.log`)
  - im-ibus.so 존재/심볼 확인, immodules.cache 확인, ibus 프로세스 상태, 환경변수 확인
- **결과:** ✅ **한글 입력 완전 작동!**
  - Ctrl+Y / Shift+Space: 한영 전환
  - 2벌식 QWERTY 자판 배열
  - F9: 한자 변환
  - Firefox 등 GTK3 앱에서 한글 입력 완벽 지원

---

## MaruxOS 1.1 릴리즈 노트

**MaruxOS 1.1** (코드네임 67)은 한글 입력 완전 지원이 추가된 첫 번째 메이저 업데이트입니다.

### 주요 변경사항
- **한글 입력 지원**: ibus-hangul 기반 한글 입력기 완전 작동
- **한국어 로케일**: ko_KR.UTF-8 완벽 지원 (14개 LC_* 변수)
- **한국어 폰트**: Nanum Gothic/Myeongjo 5종 설치
- **한영 전환**: Ctrl+Y 또는 Shift+Space

### 기술 구성
| 컴포넌트 | 버전 | 비고 |
|----------|------|------|
| libhangul | 0.2.0 | 한글 조합 라이브러리 |
| ibus | 1.5.29 | 입력 버스 프레임워크 (memconf 백엔드) |
| ibus-hangul | 1.5.5 | 한글 입력 엔진 |

### 해결한 핵심 문제들
1. **ibus 설정 백엔드 부재** → `--enable-memconf`로 메모리 기반 설정 백엔드 활성화
2. **im-ibus.so Wayland 심볼 에러** → 소스 코드 패치로 Wayland 코드 비활성화
3. **GTK3 immodules cache 미등록** → 수동 캐시 항목 주입 + `GTK_IM_MODULE_FILE` 환경변수
4. **한영 전환 미작동** → hangul 엔진 `switch-keys` 설정으로 내부 전환 메커니즘 활용

---

## 1.2.x 시리즈 (코드네임 67 — 바탕화면 / 아이콘 기능)

### 67-v54 → 1.2.0-67-v1 - 2026-02-27
**변경사항:**
- 버전 1.1 → 1.2.0, 신규 시리즈 명명 (`build-1.2.0-67-vN.sh` 형식 시작)
- **바탕화면 환경 본격 도입**:
  - idesk 설치 (`install-idesk.sh`) — 바탕화면 아이콘 매니저
  - neofetch 설치 (`install-neofetch.sh`)
  - Openbox `menu.xml` + `rc.xml` 완전 작성 (우클릭 메뉴, Win+T/D/E 단축키)
  - `marux-wallpaper`, `marux-desktop-refresh`, `marux-new-desktop-item` 헬퍼 스크립트
  - `/etc/skel/.idesktop/` 기본 아이콘 3개 (Terminal/Files/Firefox)
- **결과:** ✅ 우클릭 메뉴, 단축키, 바탕화면 아이콘 시스템 구축

---

### 1.2.0-67-v1 → 1.2.0-67-v2 - 2026-03-04
**변경사항:**
- 헤더 코멘트 "bugfix: double-fork idesk" 추가 — 실제 수정은 없었음 (라벨만 변경)
- **함정**: v2 빌드 스크립트의 헤더는 fix를 약속했으나 실제 코드는 v1과 동일. 2026-05 시점에 클로드가 발견.
- **결과:** v1과 기능적으로 동일

---

### 1.2.0-67-v2 → 1.2.0-67-v3 - 2026-05-05
**변경사항:**
- **New File / Refresh Desktop 후 모든 바탕화면 아이콘 사라지는 버그 수정**:
  - 원인: `( /usr/bin/idesk & )` 서브셸 패턴이 부모 init reparent는 했지만 **세션 리더는 xterm 그대로** → xterm 종료 시 SIGHUP이 같은 세션 전체로 전파 → 새 idesk도 즉시 사망
  - 수정: `setsid /usr/bin/idesk > /dev/null 2>&1 < /dev/null &`로 새 세션 + 프로세스 그룹 분리
  - 위치: `config/scripts/marux-new-desktop-item`, `config/openbox/menu.xml` (Refresh Desktop 메뉴)
- **결과:** ✅ New File / Refresh Desktop 후에도 아이콘 살아남음

---

### 1.2.0-67-v3 → 1.2.0-67-v4 - 2026-05-05
**변경사항:**
- **PNG prefix 불일치 버그 수정**:
  - 원인: rootfs PNG는 `marux-*` prefix로 설치 (예: `marux-terminal.png`)인데 `.lnk` 파일과 `marux-desktop-refresh`는 prefix 없는 이름 참조 → idesk가 아이콘 못 찾음
  - 수정: 모든 참조를 `marux-*` prefix로 통일
- **터미널 아이콘 불투명 배경 수정**:
  - 원인: rootfs PNG가 2025-12 stale (불투명), `MaruxOS 디자인/`의 2026-01 투명 버전이 동기화 안 됨
  - 수정: 빌드 시 `MaruxOS 디자인/` → rootfs 아이콘 자동 sync 단계 추가 (`marux-terminal.png`, `marux-file-manager.png`, `marux-desktop.png`, `marux-logo-128.png` → `marux-logo.png`)
- **부수**: `MaruxOS 디자인/terminal.png` → `marux-terminal.png`로 이름 통일
- **결과:** ✅ 아이콘 정상 표시 + 투명 배경 적용

---

## MaruxOS 1.2.1 릴리즈 노트 (2026-05-05)

**MaruxOS 1.2.1**은 1.2.0의 바탕화면 아이콘 관련 3종 버그 픽스 패치 릴리즈. GitHub Release [v1.2.1](https://github.com/ProgrammingYJ/MaruxOS/releases/tag/v1.2.1).

- ISO: `MaruxOS-1.2.0-67-v4.iso` (~1.23GB)
- SHA256: `49e8cb6ede42676eeeef22c3ef593ad117ee37dfdfc0b949544410a23f3c366a`
- 1.x 시리즈 마지막 정식 릴리즈
- **이 시점까지 실제 커널은 6.7.4 (Genesis hallucination), 광고는 6.12 LTS — 1년간 미발견**

---

## 2.0.0 "Cooked" 시리즈 (코드네임 67 → Cooked / 진짜 의도-일치 첫 커널)

> 2.0.0의 모든 발견과 함정은 [`Kernel-Update-Log.md`](Kernel-Update-Log.md)에 시간순 상세 기록.

### 1.2.0-67-v4 → 2.0.0-cooked-v1 - 2026-05-05/06
**변경사항:**
- **커널 정공 정정**: 6.7.4 (Genesis hallucination) → **6.18.26 LTS** (실제 빌드)
- 코드명 변경: 67 → **Cooked** (LLM 양면성 메타-자기풍자)
- 빌드 시리즈 명명: `build-2.0.0-cooked-vN.sh` 형식 시작
- **신규 검증 게이트 5종**:
  - SHA256 검증 (다운로드 후 강제)
  - Critical builtin 옵션 grep 검증 (squashfs/iso9660/virtio/ahci/nvme/xhci 등)
  - `make modules_install` + `depmod -a` (1.x에서 누락)
  - vmlinuz 임베드 버전 vs `KERNEL_VERSION` 매칭 검증 (kernel.release 파일 우선)
  - rootfs sync 후 모듈 카운트 핸드오프 검증
- **신규 단계 `[KERNEL]`**: 6.7.4 vmlinuz + `/lib/modules/6.7.4` → `legacy-1.x-kernel/`로 백업 후 6.18.26 sync
- **WSL native fs 강제**: 커널 소스/빌드는 `/home/$USER/MaruxOS-kernel-build/`. `/mnt/c/` (NTFS case-insensitive)에서 빌드 시 `xt_TCPMSS.c` 같은 대문자 파일 손상으로 `No rule to make target xt_TCPMSS.o` 에러
- **GRUB Safe Mode 엔트리**: `nomodeset mitigations=off systemd.unit=multi-user.target`
- **결과:** ✅ MaruxOS 역사상 두 번째 커널 빌드 / 첫 진짜 의도-일치 빌드. QEMU 부팅 통과, `uname -r` → 6.18.26

---

### 2.0.0-cooked-v1 → 2.0.0-cooked-v2 - 2026-05-06
**변경사항:**
- **메타데이터 정공 생성**:
  - 1.x sed 기반 부분 패치는 변형 케이스 (unquoted `VERSION_ID=1.0`, `(67)` 잔재 등) 다수 누락
  - `/etc/{os,maruxos,issue,lsb}-release` 파일을 sed 대신 **canonical 템플릿으로 통째 생성**
  - `VERSION_CODENAME=cooked`, `DISTRIB_CODENAME=Cooked` 필드 명시
- 부팅 splash `67 → Cooked` 정정 (`marux-splash` 등 5개 위치 일괄)
- **결과:** ✅ `/etc/os-release` 깔끔, splash 정상

---

### 2.0.0-cooked-v2 → 2.0.0-cooked-v3 - 2026-05-07 / 06-08
**변경사항:**
- **Plank dock 도입 시도** — Windows 11 스타일 dock
  - `install-plank.sh` 신규: Debian Bookworm `.deb` 5개 추출 (plank, libplank1, libgee-0.8-2, libwnck-3-0, libgnome-menu-3-0)
  - 1.x PCManFM 70개 lib 사고 회피용 시스템 lib 보호 화이트리스트
  - ldd 검증 게이트 (missing libs 0개 확인)
- tint2 → systray-only 변형 (`tint2rc-systray`) 분기
- xinitrc에 plank 자동 시작
- xterm `.desktop` `StartupWMClass` 정정 (XTerm/Navigator)
- **함정**: Debian 패키지 minor revision bump로 `libwnck-3-0_40.0-3` → 실제 `43.0-3`. AI 추측 박았다가 첫 빌드에서 발각
- **추가 함정 (transitive deps)**: ldd가 4개 missing 발견 → bamf, libdbusmenu × 2, libxres1 추가 (총 9 .deb)
- **결과:** Plank 설치는 성공. 부팅 후 `GSettingsSchema 'net.launchpad.plank' not found` → SIGTRAP 자살

---

### 2.0.0-cooked-v3 → 2.0.0-cooked-v4 - 2026-06-08
**변경사항:**
- **install-plank.sh schema strict 처리** (silent fail 패턴 차단):
  - schema XML force-overwrite (copy_safe의 "exists, skip" 우회)
  - chroot `glib-compile-schemas` 출력 노출 + exit code 체크 (이전 `2>/dev/null || true` 제거)
  - `gschemas.compiled` cache 안 `net.launchpad.plank` 등록 검증
  - early-exit 4단 자가치유: binary + schema XML + compiled + cache entry 모두 OK여야 skip
- **xinitrc에 XDG 메타데이터 export**: `XDG_SESSION_TYPE/CLASS/DESKTOP`, `XDG_CURRENT_DESKTOP`, `DESKTOP_SESSION`
- **xterm Xresources 통합**: `/etc/X11/Xresources` 시스템 wide + `xrdb -merge` (launcher 통한 xterm 호출 시 한국어 표시 fix)
- **결과:** Plank 여전히 schema 못 찾고 SIGTRAP. xterm 한국어는 정상화

---

### 2.0.0-cooked-v4 → 2.0.0-cooked-v5 - 2026-06-08
**변경사항:**
- **tint2 풀 패널 복귀** — Plank dock 디버그 동안 UI 반쪽 (우측 systray만) 해소
- xinitrc plank 시작 conditional은 유지 (떠도/안 떠도 무방)
- **결과:** UI 정상화. Plank는 여전히 SIGTRAP

---

### 2.0.0-cooked-v5 → 2.0.0-cooked-v6 - 2026-06-08
**변경사항:**
- **Plank schema의 진짜 위치 발견**:
  - plank.deb, libplank1.deb 안에 schema 없음
  - Debian source package가 binary 4개로 분할되는데 schema는 **`libplank-common` (arch-independent, _all.deb)** 안에 있음
  - install-plank.sh DEBS 배열에 추가 (9 → 10 .deb)
- **결과:** 빌드 자체는 성공했으나 install-plank.sh이 *v6 빌드 시* schema 안 박음 (미스터리, 단독 실행은 정상). v6 ISO 그대로는 SIGTRAP. install-plank.sh 단독 실행 후 v6 재빌드해서 해결

---

### 2.0.0-cooked-v6 → 2.0.0-cooked-v7 - 2026-06-08
**변경사항:**
- **Plank dock 풀세팅**:
  - `config/plank/dock1/settings`: Position=3 (bottom), Alignment=0 (center), IconSize=48, ZoomEnabled=true (150%)
  - `config/plank/dock1/launchers/{xterm,mc,firefox}.dockitem` — 3개 pinned launcher
  - `/etc/skel/.config/plank/` + `/root/.config/plank/` 둘 다 배포 (Live ISO + 설치 사용자 모두 커버)
  - xinitrc에 skel→home restore 로직 추가 (tmpfs 환경 안전)
- **tint2 → systray-only 모드 복귀** (v3 분기 부활)
- **결과:** Plank 바이너리 실행 ✓ + dockitem 파일 위치 OK ✓ / **그러나 dock-items GSettings 키 (memconf) 주입 안 됨 → dock 빈 박스 표시**. 1주 후 (6/19) ARM64 마감 압박 + dock-items 디버그 가치 평가 → v8 롤백 결정.

---

### 2.0.0-cooked-v7 → 2.0.0-cooked-v8 - 2026-06-19 (Plank Rollback)
**변경사항:**
- **Plank 미설치** — install-plank.sh 호출 안 함
- tint2 → 풀 패널 모드 복귀 (1.x 검증된 안정 layout)
- 잔재 청소 ([7.5]에서 rootfs의 기존 plank 흔적 제거: 바이너리, schema, /etc/skel/.config/plank, /root/.config/plank)
- **보존 (deferred 작업)**: `install-plank.sh`, `config/plank/`, `config/tint2/tint2rc-systray` — frozen artifact, 2.0.x 패치에서 부활 가능
- xinitrc plank 조건부 시작 블록은 유지 (`/usr/bin/plank` 없으면 자동 skip)
- **결정 이유**: ARM64 마감 (8/10 OSS Korea 슬라이드) 앞두고 Plank dock-items GSettings 디버그(시간 불확정) 가치 안 맞음. 발표 임팩트는 "schema 정복 + 14종 함정" 챕터에 있고, dock 아이콘 표시 여부는 별개 polish.
- **결과:** ✅ 2.0.0 Cooked = 6.18.26 LTS + 1.x 검증 UI (Openbox + tint2 풀 + idesk + ibus-hangul). Plank는 2.0.x로 deferred.

---

### 2.0.0-cooked-v8 → 2.0.0-cooked-v9 - 2026-08-27 (x86_64 공개 릴리즈 ISO — x86 전용 메뉴 + root/marux) ✅ **= GitHub 릴리즈 자산**
**맥락:** GitHub 릴리즈 v2.0.0 자산용. 공유 `config/openbox/menu.xml`이 ARM64 배치 Q~T로 Qt 앱 기준이 되어 x86에선 메뉴가 깨짐 → **`config/openbox/menu-x86.xml`**(origin/main 1.2.1판) 분리 + 게이트(Qt 앱 참조 금지·xterm/mc/firefox 실존). root 비번 `marux`(v8까지 빈 비번; tty1 자동 로그인 유지). 산출 사본 `MaruxOS-2.0.0-x86_64.iso` + sha256. 그 외 v8 동일(커널 6.18.26, tint2/xterm/mc/Firefox/ibus-hangul).
- 함정: root로 실행 시 `WSL_KERNEL_BUILD_ROOT` 기본값이 `/home/root/…`로 풀려 커널을 못 찾음 → 환경변수로 `/home/administrator/MaruxOS-kernel-build` 명시(1차 발사 실패).
- 산출: `MaruxOS-2.0.0-x86_64.iso` **1.24G** (SHA `6342ac4fd4271a7236025dba248eb0edde8cd28c6fbaeb54cd390f55b8165ccb`, = cooked-v9.iso). 빌드 23:54→23:56(2분).

## ARM64 트랙 이미지 빌드 (별도 명명 `build-2.0.0-cooked-arm64-vN.sh`)

> ⚠️ x86_64 `cooked-vN`과 **완전 별개 트랙**. 산출물 `MaruxOS-2.0.0-arm64.img.xz` (Live ISO 아님 — Pi 4B용 hybrid disk image). v1~v5는 인라인 조립이라 미기록 (상세: `ARM64-Update-Log.md`). **v6가 최초의 스크립트화 빌드.**

### arm64-v6 - 2026-07-06 (최초 빌드 스크립트 + rootfs 4버그 픽스)
**맥락:** 2026-07-06 시리얼 부활로 **우리 커널 6.18.26-maruxos가 실기기 Pi 4B에서 `marux login:`까지 완전 부팅** 확인 (ARM64 트랙 최대 마일스톤). v1~v5의 "부팅 실패"는 죽은 시리얼 어댑터 + 콘솔 라우팅 착시였음이 판명. 부팅 완주 과정에서 드러난 rootfs 설정 버그 4종을 픽스한 첫 정식 빌드.

**`scripts/build-2.0.0-cooked-arm64-v6.sh` (신규):**
- **소스**: `$LFS`(rootfs-clfs-arm64) 직접. `/tools` 제외(x86_64 죽은 크로스툴), **`/sources` 유지**(self-hosting 빌드 — 사용자 결정 "빌드할 거 다 넣어").
- **이미지**: 27G (p1 512M FAT32 boot / p2 26.5G ext4) → 29.7G SD 채움. (v1~v5의 7G 관성 폐기 — SD 용량 여유 활용.)
- **rootfs 4픽스**: ①`/bin/udevadm`→`/usr/sbin/udevadm` 심링크 ②`/etc/fstab`에 `/dev/shm`(tmpfs)+`/sys/fs/cgroup`(cgroup2) ③`S70console` 비활성(헤드리스 setfont 실패) ④`S10sysklogd` 비활성(sysklogd 미설치).
- **부트파일**: kernel8.img(우리 50MB Image, magic 41524d64 게이트) + 우리 mainline dtb + master 펌웨어(start4.elf 2306400/fixup4.dat) + config(`enable_uart=1`) + cmdline(`console=tty1 console=ttyS0,115200` = /dev/console 시리얼 + earlycon).
- **게이트**: OUTPUT_NAME arm64 강제 / 빌드루트 분리 / **커널 arm64 Image 매직바이트** / start4.elf==master 2306400.
- **목표**: 무인 클린부팅 (FAIL 0, 자동 `marux login:`). syslogd 정식설치 + HDMI(vc4-kms-v3d) + X.org는 후속(Stage 5).

### arm64-v7 - 2026-07-11 (그래픽 데스크톱: X.org + openbox/tint2/idesk/xterm)
**맥락:** Stage 5a(커널 VC4/V3D=y → 실기기 HDMI KMS 확인) + 5b(X.org 21.1.11 + mesa 24 vc4/v3d gallium, 44개) + 5c(openbox 3.6.1/tint2 17/idesk/xterm-410 + glib/cairo/pango/harfbuzz 미들웨어, 22개) 완성 후 **첫 그래픽 데스크톱 이미지**. 한글(ibus/gtk3)은 qemu-user의 gdk-pixbuf 로더등록 한계로 보류 → **Pi 네이티브 빌드 후속(결정 A)**.

**`scripts/build-2.0.0-cooked-arm64-v7.sh` (v6 복제 + delta):**
- 커널 = **5a 재빌드**(`CONFIG_DRM_VC4=y`/`DRM_V3D=y` builtin + 의존성 SOUND/SND/RASPBERRYPI_FIRMWARE/MBOX). Image 47.7→**51.1MB**.
- config.txt에 **`max_framebuffers=2`** 추가 (VC4 KMS 프레임버퍼). `dtoverlay` 안 씀(mainline dtb가 hdmi/pixelvalve/gpu 이미 status=okay).
- **sysklogd 정식 설치**됨 → v6의 S10sysklogd 재-disable 라인 삭제(활성 유지). tty1 getty는 inittab에 이미 존재.
- rootfs에 X.org 스택 + 데스크톱(openbox/tint2/idesk/xterm) + **DejaVu 22 TTF** + fc-cache + config(`setup-desktop-config-arm64.sh`: xinitrc/openbox menu→xterm/tint2rc).
- 추가 게이트: Xorg/openbox/tint2/xinitrc/syslogd 존재 + `modules.builtin`에 vc4.ko(5a 커널 확인).
- 산출: **3.0G** (SHA `c426bc93d96ee9e5a1eb1dafb85db22bab8adece27a5ef0b068563306085e22d`).
- **검증법**: HDMI 로그인(`root`/`<ROOT_PW>`) → `startx` → openbox+tint2 데스크톱, 우클릭 메뉴 → xterm. (한글은 Pi 네이티브 gtk3+ibus 후속 = 결정 A)
- **v7.1 (2026-07-17, 스크립트 동일·$LFS 개선분 재빌드)**: v7 실기기 검증서 버그 5종 픽스 반영 — ①xinitrc 4경로 복사(startx가 /usr/etc 봄) ②xauth-1.1.3 빌드(startx 필수) ③tint2 검증샘플(직접작성 config 크래시) ④세션 `exec openbox`(견고화) ⑤**libinput 입력드라이버**(mtdev/libevdev/libinput/xf86-input-libinput → 키보드/마우스). **SHA `29a794cf6243f3418f5e60ccaa19447e4e55fb90cf03ff706eab53ad19b7cd8c`**. 갱신: `install-xorg-arm64.sh`(xauth+libinput+config.guess), `setup-desktop-config-arm64.sh`(robust xinitrc+검증tint2). 상세=ARM64-Update-Log "2026-07-17".

### arm64-v8 - 2026-07-20 (배치 A: 데스크톱 x86_64 패리티 — feh·mc·배경·아이콘·메뉴·키바인드)
**맥락:** v7.1 실기기 검증(입력·한글표시 동작) 후, **1차 목표 = ARM64를 x86_64 최신버전과 동일 완성도로 이식**("VM 돌리듯"). 사용자 결정: 배치 A(qemu-chroot polish) 먼저 → 배치 B(한글 Pi 네이티브). **Firefox는 gtk3 런타임 의존이라 배치 A가 아닌 B로 이동**(prebuilt aarch64도 gtk3 필요).

**신규 스크립트 3종:**
- **`scripts/install-desktop-polish-arm64.sh`**: qemu-chroot로 **feh 3.10.3**(imlib2/X11/Xinerama) + **mc 4.8.31**(ncursesw/glib2) aarch64 빌드. 5c 스캐폴드 재사용(binfmt/mount/resumable `.5A`). 소스 fetch(mc=osuosl 미러, feh=finalrewind). 실행검증: `--version` rc=0, ldd "not found" 0.
- **`scripts/setup-desktop-config-arm64-v2.sh`** (v1 보존): x86 패리티 config 배포 — PNG 8개(x86 rootfs pixmaps 복사)·배경화면(marux-desktop.png)·헬퍼3종(marux-wallpaper/-new-desktop-item/-desktop-refresh)·.Xdefaults(xrdb 없이 xterm 로드)·openbox 풀menu+rc.xml(키바인드 W-t/W-e/W-d, 폰트 NanumGothic→DejaVu sed)·idesk 2아이콘(terminal/files)·full xinitrc(feh배경+network+idesk, ibus/firefox 가드, exec openbox) 4경로.
- **`scripts/build-2.0.0-cooked-arm64-v8.sh`** (v7 클론): 배치A 게이트 6종 추가(feh/mc/배경PNG/아이콘PNG/헬퍼/xinitrc-feh). config.txt·cmdline·커널(5a)·부트체인 v7과 동일.

**빌드 축소 발견:** xrdb 불필요(xterm이 .Xdefaults 자동 로드) + xsetroot 불필요(feh가 배경) → 실제 빌드 feh+mc 2개(의존성 5b/5c에서 이미 충족).
**운영 함정:** ①binfmt 소실(#5) 재현 — 빌드 후 WSL 유휴로 qemu-aarch64 등록 날아감→재등록. ②안전패턴 #8 — WSL은 PowerShell `wsl -u root bash <파일>`로(Git Bash MSYS 경로변환/quoting 파괴).
- 산출: **3.1G** (SHA `a8b733de209288de8fdbe9ec7d71c80d8163b4300d26f1a8807bd16a6508f436`, Windows 복사본 SHA 일치 검증). 게이트 통과.
- **검증법**: HDMI 로그인 → `startx` → 배경화면 + 패널 + 바탕화면 아이콘 2개(더블클릭 실행) + 우클릭 풀메뉴 + 키바인드(Win+T/E/D, 창스냅). (한글입력·Firefox = 배치 B) 상세=ARM64-Update-Log "2026-07-20".

### arm64-v9 - 2026-07-22 (배치 B-1: xterm XIM 한글입력 — ibus-hangul + GTK2 + NanumGothic)
**맥락:** v8 실기기 검증(데스크톱 완전동작) + 폴리시 픽스(지지직=VC4 HW커서→SWcursor xorg.conf / 시계=ko로케일 %A%B tofu→ASCII %Y-%m-%d) 후 배치 B-1. **재규명: ibus XIM 서버(ibus-x11)는 gtk3가 아니라 GTK2 필요** → GTK2는 qemu 빌드 가능(코어 심볼릭SVG 이슈 없음, 데모/테스트만 gdk-pixbuf-csource로 걸림→제거) → **Pi 네이티브 불요.**

**신규 스크립트:**
- **`scripts/install-hangul-arm64-v2.sh`**: qemu-chroot로 **GTK2 2.24.33 + ibus 1.5.29(dist) + ibus-hangul 1.5.5** 빌드. **8겹 블로커 해결**: ①GTK2 데모 gdk-pixbuf-csource(SUBDIRS서 demos/tests/perf 제거) ②libnotify(--disable) ③python바인딩(--disable-python-library) ④iso-codes(ISOCODES env 우회) ⑤automake(ChangeLog+gtk-doc.make 스텁) ⑥valac(git-archive→**릴리즈 dist 타르볼**, vala미리생성C) ⑦ibus-hangul 깨진타르볼(29B)→GitHub소스 ⑧ibus-hangul gtk+-3.0체크+tests(configure.ac/Makefile.am서 제거).
- **`scripts/setup-hangul-config-arm64.sh`**: NanumGothic 3종 TTF + fc-cache. + config-v2 xinitrc ibus 블록 개선(`ibus-daemon --xim --panel disable -r -d` + `ibus engine hangul`).
- **`scripts/build-2.0.0-cooked-arm64-v9.sh`** (v8 클론): 한글 게이트(ibus-x11/engine-hangul/gtk2/libhangul/NanumGothic/xinitrc-ibus). ⚠️ ibus 바이너리는 **/usr/libexec/**(LIBEXECDIR).
- 산출: **3.1G** (SHA `6829830f87acb73d58c88975d5c0d9a83bb89ab990b14be98fd54ef6746569f3`, Windows SHA 일치). 게이트 통과.
- **검증법**: 부팅 → startx → xterm에서 **Shift+Space(한영토글)** → 한글 타이핑(`gksrmf`→`한글`). (Firefox·GTK3앱 입력 = 배치 B-2) 상세=ARM64-Update-Log "2026-07-22".
- **⚠️ v9는 out-of-box 한글 안 됨** — 실기기서 ①ibus 코어 gschema 미설치(엔진 크래시) ②machine-id 없음 발견. 런타임 수동픽스로 **한글 입력 성공 확인**(2026-07-23). → v10에 박제.

### arm64-v10 - 2026-07-23 (한글 out-of-box: ibus 코어 gschema + machine-id 픽스)
**맥락:** v9 실기기서 **한글 안 됨** → 시리얼 디버그로 2근본원인 규명: ①`--disable-dconf`가 ibus 코어 gschema(`data/dconf/org.freedesktop.ibus.gschema.xml`, `.panel` 스키마) 설치 스킵 → 엔진이 GSettings 스키마 못찾아 크래시 → SetGlobalEngine 타임아웃 ②`/etc/machine-id` 없음(from-scratch). **런타임 확증(base64 시리얼 전송)으로 한글 입력 성공** 후 박제.
- **`install-hangul-arm64-v2.sh`** (갱신): 마커무관 필수픽스 2종 — 코어 gschema 추출·설치·`glib-compile-schemas` + `dbus-uuidgen` machine-id(/etc + /var/lib/dbus).
- **`setup-desktop-config-arm64-v2.sh`**: xinitrc ibus `sleep 3→5`.
- **`build-2.0.0-cooked-arm64-v10.sh`** (v9 클론): 게이트 3종(코어 gschema/gschemas.compiled/machine-id) 추가.
- 산출: **3.1G** (SHA `2b73877b24f2d2953509eed36d6fbba4efb2f5314921774ff7ad42846d8a20f2`, Windows SHA 일치 검증). 게이트 통과.
- **검증법**: 재플래시 → startx → 새 xterm → **Shift+Space** → `gksrmf`→`한글` (수동픽스 불요, out-of-box). ⚠️ 토글키=Shift+Space (Ctrl+Y는 dconf 전용). 상세=ARM64-Update-Log "2026-07-23".

### arm64-v11 - 2026-07-25 (배치 B-2: gtk3 + Firefox ESR 140 한국어판 + GTK3앱 한글) ✅
**맥락:** 5d "gtk3 벽" 부검 결과 재규명 — gtk+-3.24.41은 **meson 전용**이고 5d는 meson setup까지 **성공**했었음(빌드디렉 `_b` 잔재의 ninja_log상 코드젠 완료 후 .o 0개 중단 = **binfmt 소실(#5) 중도사 정황**). gtk3 코어 빌드엔 gdk-pixbuf 실행 스텝이 **없음**(심볼릭 PNG 206개 타르볼 pre-encode → gresource 바이트 임베드). 유일 접점 = `ninja install`의 post-install.py → hicolor 선설치+수동 폴백으로 방어. **= Pi 네이티브 수시간 빌드 재회피, qemu-chroot 재도전.**

**신규 스크립트:**
- **`scripts/install-gtk3-arm64.sh`**: ①hicolor-icon-theme 0.17+shared-mime-info 2.4+alsa-lib 1.2.10 ②**gtk+-3.24.41 (meson)** ③ibus 재빌드 `--enable-gtk2 --enable-gtk3` → **im-ibus.so(gtk3)** + `gtk-query-immodules-3.0 --update-cache` + B-1 필수픽스(gschema/machine-id) 멱등 재적용 ④libxkbfile+setxkbmap(startx 경고 제거) ⑤**Firefox ESR 140.13.0esr 공식 aarch64 한국어(ko) prebuilt** → /opt/firefox (**SHA256SUMS raw 검증** — 게이트 원칙) + chroot ldd 의존성 검증(libXss 필요시만 libXScrnSaver). resumable(.b2-markers).
- **`scripts/setup-desktop-config-arm64-v3.sh`** (v2 클론+델타): ①openbox rc.xml **NanumGothic 복원**(v2의 DejaVu 강등 sed 제거 — v9부터 폰트 있음) ②tint2 시계 **한국어 날짜 복원**(`%A %d %B`+NanumGothic — v8 ASCII 강등 원인이던 폰트 부재 해소) ③idesk **firefox.lnk** 추가(x86 skel 패리티, Firefox 번들 default128.png 아이콘) ④root 홈 tint2rc 캐시 제거(우선순위 함정 대응). GTK_IM_MODULE=ibus 등 IM env는 v2부터 선반영돼 있었음.
- **`scripts/build-2.0.0-cooked-arm64-v11.sh`** (v10 클론): B-2 게이트 12종(.b2-COMPLETE/libgtk-3/gtk3 im-ibus.so/immodules.cache-ibus/Firefox 140+심링크/alsa/setxkbmap/mime.cache/FFDEPS부재/firefox.lnk/rc.xml-NanumGothic/GTK_IM_MODULE) + **cmdline `loglevel=4`**(wifi-pwrseq 등 INFO 콘솔 스팸 억제).
- **빌드 중 함정 2종 (스크립트 박제)**: ①**ibus `--enable-gtk3`엔 `--disable-ui` 필수** — ui/gtk3(패널/이모지피커) vala 사전생성 C가 `gdk/gdkwayland.h` 하드 include(--disable-wayland 무시) → wayland 백엔드 없는 우리 gtk3서 컴파일 사망(1차 rc=2). 패널은 `--panel disable`로 미사용이라 통째 스킵. ②**qemu chroot ldd는 RPATH($ORIGIN) 못 풂** — FF 자기 번들 lib(libnspr4/libnss3 등 13종) not found 오탐(2차 FAILED_AT=final) → /opt/firefox 실존 필터. 시스템 의존성은 전부 해결돼 있었음.
- **gtk3 실측**: qemu-chroot ninja 929스텝 **14분 완주**(libgtk-3.so 9.8MB aarch64). = 5d "gtk3 벽"은 binfmt 소실 중도사 **오진 확정**.
- 산출: **3.1G** (SHA `fcb599b3547c33a5496fa0e105aa7efea4edca30c86d0d7aaac5b46911cbbf1a`, Windows SHA 일치 검증). 게이트 12종 통과. (선행: **v10 out-of-box 한글 실기기 검증 성공** — 사용자 확인 2026-07-25.)
- **검증법**: 부팅 → startx → 바탕화면 Firefox 아이콘(3아이콘)/메뉴 → Firefox 한국어 UI 기동 → 주소창·페이지 입력폼에서 **Shift+Space** 한글 입력(= gtk3 immodule 경로, XIM 아님). +시계 한국어 날짜(`%A %d %B`/NanumGothic) + 콘솔 스팸 감소(loglevel=4). 상세=ARM64-Update-Log "2026-07-24".

### arm64-v12 - 2026-07-27 (네트워크: dhcpcd 유선 DHCP + chrony NTP — Firefox 인터넷 + 시계 1970 해결)
**맥락:** v11까지 DHCP 클라이언트 전무(xinitrc 가드 조용히 스킵) + `ifconfig.eth0`이 ipv4-static 192.168.1.50 플레이스홀더 + NTP 전무(Pi RTC 없음 = 시계 1970 버그). WiFi는 커널 CFG80211=m이라 no-modules 원칙상 커널 재빌드 필요 → Plank/네트워크GUI 배치로 보류.
- **`scripts/install-network-arm64.sh`**: dhcpcd 10.0.6(--disable-privsep, 61초) + chrony 4.5(70초, makestep 1 -1) qemu-chroot 빌드 + 부팅통합(x86 `/lib/services/dhcpcd` 이식·ifconfig.eth0=dhcpcd·S25chronyd). resumable(.n-markers).
- **`scripts/build-2.0.0-cooked-arm64-v12.sh`** (v11 클론): 네트워크 게이트 6종 + **[5b] resolv.conf 클린 생성**(v6~v11에 WSL resolv.conf 잔재 실려있었음 — dhcpcd가 런타임 덮어쓰므로 비치명이었으나 정정).
- 산출: **3.2G** (SHA `294cfade858faeb9d9eb31a39bf3676970d93241b3f4b3f926cec29337f77982`, Windows SHA 일치 검증). 게이트 통과.
- **✅ 실기기 검증 성공 (2026-07-27, 시리얼 주도)**: 부팅 자동 DHCP 임대(192.168.45.176)+라우팅+ISP DNS, ping google.com 36ms, chrony 오차 0.7µs(시계 1970 완치), Firefox 실사용 웹서핑(사용자 확인). klogd 첫부팅 정지 flake 1/3(비재현, 모니터링). 상세=ARM64-Update-Log "2026-07-27".

### arm64-v13 - 2026-07-27 (실기기 폴리시: HW커서 복권 + flat 가속 + HDMI 1080p60 강제)
**맥락:** v12 실기기 라이브 픽스 세션 산출물 박제. ①TV "invalid format" → cmdline `video=HDMI-A-1/2:1920x1080@60` 강제로 해결 ②시리얼 진단: glamor 정상 가동 확인 + **TearFree는 xorg 21.1 modesetting 미지원**(죽은 옵션이었음) ③라이브 A/B: **HW커서(SWcursor=false) 복권** — 지지직 재발 없음 + SW커서 깜빡임·딜레이 완치(사용자 "깨끗함") ④libinput flat 가속 프로파일. v8의 "지지직=HW커서" 판정은 모니터+auto EDID 환경 한정 가능성(모니터 재발 시 롤백 옵션 문서화).
- **`scripts/setup-desktop-config-arm64-v4.sh`** (v3 클론): SWcursor false + TearFree 제거 + 50-mouse-flat.conf + xinitrc DRM master 주석.
- **`scripts/build-2.0.0-cooked-arm64-v13.sh`** (v12 클론): cmdline video= 강제 + 커서 게이트 3종.
- **함정 2종**: #11 stale DRM master(X 어중간 종료→startx 검은화면, `drmSetMaster busy` — pkill Xorg/xinit로 해제, 예방=메뉴 Exit 종료) / #12 WSL VM 크래시(nohup도 VM 셧다운은 못 버팀 → 재발사).
- 산출: **3.2G** (SHA `3f3023681d02a2f9bf61603105e7d683301f9c31e02879f295e6610b64c56ce7`, Windows SHA 일치 검증). 게이트 통과. ※커서 픽스는 실기기 라이브 A/B로 이미 검증됨(이미지는 박제본).
- **검증법**: 부팅(HDMI0+이더넷) → startx → 커서 깜빡임/딜레이/지지직 없음 + v12 전체 회귀. 상세=ARM64-Update-Log "2026-07-27".

### arm64-v14 - 2026-07-28 (배치 P: Plank dock — vala 부트스트랩 + GSettings 정공 픽스)
**맥락:** x86 v3~v7 Plank 실패의 4-에이전트 워크플로 부검으로 근본원인 해명 — **memconf=GLib memory 백엔드=프로세스별·비영속**이라 `gsettings set`이 plank 프로세스에 도달 불가("빈 독"의 실체). plank 0.11.89는 사전생성 C 없음(75 .vala)+valac/vapigen+bamf 하드요구 → x86 deb 추출 대신 **소스 체인 11종**: g-i 1.78 → **vala 0.56.17 부트스트랩(자체 valac!)** → libgee → libXres → libwnck 43 → libgtop → gnome-menus → xcb-util → startup-notification → bamf(lxml 하드체크 sed 무력화) → plank(SHA `a662a46e…` 게이트).
- **정공 픽스 (elementary OS 패턴)**: `40_maruxos.gschema.override`로 dock-items 기본값 박제 → **chroot gsettings 실효값 검증**(`['xterm','mc','firefox'].dockitem`) + xinitrc `GSETTINGS_BACKEND=keyfile`(영속·공유).
- **`scripts/install-plank-arm64.sh`**(.p-markers) / **`setup-desktop-config-arm64-v5.sh`**(keyfile+.desktop 3종+dockitem 3종+tint2 systray-only SC+plank 블록) / **`build-2.0.0-cooked-arm64-v14.sh`**(Plank 게이트 15종).
- 함정 4종: libwnck GNOME 40+ URL(디렉토리=메이저) / vala 0.56→g-i girdir 하드요구 / sn→xcb-util(xcb_aux) / bamf→python3-lxml(테스트용) 하드체크.
- 산출: **3.2G** (SHA `7f836cde37e2f480231e9513eeec4a9d5ac73e02827eab1b09b928d4273bf612`, Windows SHA 일치 검증). 게이트 통과.
- **검증법**: startx → 하단 중앙 **Plank 독 3아이콘**(클릭 실행) + tint2 우하단 systray/clock + v13 전체 회귀. 독=불투명(비컴포지트 정상). 상세=ARM64-Update-Log "2026-07-27 배치 P".

### arm64-v15 - 2026-07-29 (배치 P2: Plank 폴리시 — picom 컴포지터 + Marux 유리 테마)
**맥락:** v14 실기기 검증 ✅(독 3아이콘 + keyfile 영속화 실측) 후 사용자 요구 = macOS풍 라운드·긴 바·**반투명 유리**. 라이브 실험으로 테마 스위칭 작동(색톤 즉시 반영) + **라운드=컴포지터 필수**(비컴포지트 사각 폴백) 실측 → picom 도입 확정.
- **`scripts/install-plank-polish-arm64.sh`**(.p2-markers): picom v11.2(xrender+vsync 미니멀, 그림자/페이드 off) + libev/libconfig/uthash/xcb-util-{renderutil,image,wm} + **Marux 테마**(라운드10·alpha130 유리·HorizPadding5) + override theme='Marux'(gsettings 검증).
- **`setup-desktop-config-arm64-v6.sh`**: xinitrc picom 기동(plank 앞) + tint2 panel_size 360→200(시계 치우침 픽스).
- **`build-2.0.0-cooked-arm64-v15.sh`** (v14 클론): P2 게이트 7종.
- 산출: **3.2G** (SHA `5fef190d4922a2a1d8f28ab81ab296095b6121708d719a0a156664f06f2ee4fb`, Windows SHA 일치 검증). 게이트 통과.
- **검증법**: startx → 라운드·반투명 유리 독 + 호버 줌 + 시계 우하단 + 독 실행 점(bamfdaemon) + v14 회귀. 블러는 플래시 후 라이브 실험(v16 후보). 상세=ARM64-Update-Log "2026-07-29".

### arm64-v16 - 2026-07-29 (v15 실기기 라이브픽스 4종 박제 — 클릭포커스·bamf·유리확정·HDMI정리)
**맥락:** v15 실기기 라이브픽스 세션. "회색 독"=버그 아닌 광학(어두운 배경 통과 유리 — 흰 창 뒤에 두면 유리티 확연, 사용자 확인). 진짜 버그 3종 근원 규명: ①클릭 창전환 불가=rc.xml **Client 컨텍스트 부재**(x86 잠복, 레포 원본 수정=양 트랙 동시픽스) ②독 실행 점=bamfdaemon **세그폴트**(exception-trace로 특정: wnck가 SN 미포함 빌드[체인 순서 실수] → `wnck_handle_set_default_icon_size` 사망. 데비안 조합과 유일한 차이) + D-Bus runner 우분투 전용→xinitrc 명시기동 ③RGB 콘솔 스팸=미연결 HDMI-A-2 모드강제(유력)→cmdline 제거+dmesg -n 1.
- **`setup-desktop-config-arm64-v7.sh`** / **`build-2.0.0-cooked-arm64-v16.sh`**(라이브픽스 게이트 6종) / `install-plank-arm64.sh` 갱신(sn→wnck 순서교정+SN게이트+override=Marux).
- **게이트 승리**: 1차 빌드가 override theme 리셋(두 스크립트 한 파일 소유 결함)을 자동 abort로 검거 → 소유권 정리 후 재발사.
- 산출: **3.2G** (SHA `57daa20ad5df363245ae839918b07ff4d2101b61680e5f701626fb7a76fb8e1f`, Windows SHA 일치 검증). 게이트 통과.
- **검증법**: startx → 독 앱 실행 **점 표시**(bamf 부활=마지막 조각) + 클릭 창전환 + 유리(라운드10/알파95) + RGB 스팸 소멸. 상세=ARM64-Update-Log "2026-07-29 (2)".
- → **후일 재규명(2026-08-14)**: 실기기 검증 결과 클릭 창전환·유리·RGB 스팸 소멸 ✅ / **점 표시 ❌** — SN 재빌드는 근원이 아니었음(bamfdaemon 여전히 세그폴트). 실근원 = **libwnck 43.0 업스트림 버그**(`invalidate_icons` screens NULL 가드 부재, 43.2에서 수정) → 43.2 버전업으로 해결, **v17 탑재 예정**. 아래 2026-08-14 항목 참조.

### arm64-v17 - 2026-08-14 (bamf 진짜 픽스: libwnck 43.2 + clock-only 시계) ✅
**맥락:** v16 bamf 픽스(SN 재빌드)=오진 판명 → 진짜 근원 = **libwnck 43.0 업스트림 버그**(invalidate_icons의 screens NULL 가드 누락). 43.2 채택 + **시리얼 무플래시 배포로 실기기 선검증 완료**(bamfdaemon 가동·독 실행 점·실행 중 앱 클릭 창전환 ✅ — 사용자 확인). 함정 #25.
- **`build-2.0.0-cooked-arm64-v17.sh`** (v16 클론): 게이트 갱신 — tint2 `panel_items=C`/`panel_size=100`(config v8) + **libwnck-3.0.pc Version 43.2 강제**(43.0=bamf 즉사).
- config v8: tint2 **clock-only 100px**(윈도우식 우하단 시계, 실기기 확정).
- 🐛 미탑재 알려진 버그: 독 점 위치 테마 무반응(plank 소스 패치 예정).
- 산출: **3.2G** (SHA `767ec40eb7eb5a9a8af14520a25610ce633f92145d6e78175cf9d12965a8de36`, Windows SHA 일치 검증 3,344,571,676 B). 게이트 통과.
- **✅ 실기기 검증 완료 (2026-08-14, 사용자)**: ①독 실행 점(이미지 부팅만으로 bamfdaemon 자동기동) ②실행 중 앱 클릭=창 전환 ③시계 + 회귀 전반 = **배치 P(Plank) 공식 완전 종결.** 시계 밀착 추가 튜닝 확정값(72px/패딩0/배경박스 제거)+플로팅 박스 디자인 요청 = config v9 과제. 상세=ARM64-Update-Log "2026-08-14".

### arm64-v18 - 2026-08-14 (배치 W: WiFi 커널+wpa+퀵설정 GUI + 플로팅 시계)
**맥락:** 배치 P 종결 직후 같은 날 배치 W 개시→완주. WiFi를 no-modules 원칙 그대로 성립시키는 핵심 = **펌웨어 5종 커널 임베드**(EXTRA_FIRMWARE — builtin brcmfmac은 rootfs 마운트 전에 request_firmware하므로 rootfs 배치만으론 타이밍 실패).
- **`rebuild-kernel-wifi-arm64.sh`** (신규): 무선 7종 =y(CFG80211/MAC80211/RFKILL/BRCMFMAC(+SDIO)/BRCMUTIL/VENDOR_BROADCOM) + 43455 bin(Cypress 7.45.234)/Pi4B NVRAM/clm_blob/regulatory.db+p7s 임베드. 새 Image 52,947,456 B (SHA `2d8e6289…`). 함정 #27(linux-firmware 파일명 개편 — bin/clm 실체=cypress/, regdb 정본=wireless-regdb 레포) + 게이트 자기검증 #2(clm 매직="BLOB", "CLM DATA"는 기억 환각 — od 실측 정정).
- **`install-wifi-arm64.sh`** (신규, .w-markers): libnl 3.9.0 + wpa_supplicant 2.11(**internal TLS** — openssl 회피, WPA2-PSK MVP/SAE 제외) + conf 템플릿(**자격증명 無 sanitize 게이트**) + S24wpasupplicant(wlan0 가드).
- **`install-quicksettings-arm64.sh`** (신규, .q-markers): **marux-quicksettings** — GTK3+vala 자체 제작(src/marux-quicksettings/, ~330줄), 자체 valac 0.56로 chroot 컴파일(86,616 B AArch64, 첫 트라이). 우상단 바→드롭다운(WiFi 토글/스캔/연결 + 볼륨).
- **`setup-desktop-config-arm64-v9.sh`** (v8 클론): tint2 = **플로팅 시계**(`config/tint2/tint2rc-floating` 자산 복사 — 우하단 공중 라운드 회색 박스 #c8c8c8 90/rounded 12/margin 10/shrink+패딩30 중앙정렬/NanumGothic Bold, 실기기 라이브 확정값 1:1) + xinitrc **marux-quicksettings 기동**.
- **`build-2.0.0-cooked-arm64-v18.sh`** (v17 클론): 신규 게이트 — 커널 SHA 고정(WiFi 재빌드본 강제) + modules.builtin 무선 4종 실측 + Image 임베드 흔적 + .w/.q-COMPLETE + wpa 3종 + **conf sanitize(psk= 시 abort)** + 퀵설정 readelf + 플로팅 시계 5종.
- 🐛 미탑재 알려진 버그(v19 이월): 독 점 위치/크기(plank 소스 패치 필요).
- 산출: **3.2G** (SHA `4bcd57aedef601b857e4089b3370347a524a518be4c96df151995c795d74a33a`, Windows SHA 일치 검증 3,363,794,180 B). 게이트 전량 통과.
- **실기기 검증 결과 (2026-08-17)**: 플로팅 시계 ✅ / ❌ **wlan0 부재**("WiFi 미지원" 표시) ❌ 패널 투명 ❌ 볼륨 % 고정 → 아래 v19에서 근원 픽스.

### arm64-v19 - 2026-08-17 (v18 실기기 픽스 3종: RESET_GPIO + alsa-utils + GUI cairo 배경)
**맥락:** v18 실기기 문제 3종 전부 근원 특정(시리얼 dmesg + 호스트 대조): ①wlan0 부재 = **CONFIG_RESET_GPIO=m** — 6.18 pwrseq_simple이 reset 컨트롤러 프레임워크 우선인데 DT reset-gpios 브리지가 모듈이라 "reset control not ready" 영구 defer(함정 #28, =m 트랩 신종) ②볼륨 = **amixer 자체가 미설치**(alsa-lib만 있었음) ③투명 패널 = GTK CSS 배경 미발현.
- **`rebuild-kernel-wifi-arm64.sh`** 갱신: `-e RESET_GPIO` + 게이트 → 새 Image SHA `10ff2fe4…` (52,947,456 B 동일).
- **`install-wifi-arm64.sh`** 확장: alsa-utils 1.2.10 (+`/etc/asound.conf` softvol — vc4-hdmi HW볼륨 無라 "Master" 컨트롤 생성, 첫 재생 후 등장).
- **`marux-quicksettings.vala`** 재작업(87,520 B 재컴파일): cairo 직접 페인트 라운드 유리(**플로팅 시계와 동일 #c8c8c8 톤**+다크 텍스트) + 믹서 동적 감지(부재 시 "♪ --") + draw 핸들러 뒤 창 CSS 배경 덧칠 함정 처리.
- **`build-2.0.0-cooked-arm64-v19.sh`** (v18 클론): 커널 SHA `10ff2fe4…` 고정 + modules.builtin reset-gpio.ko + amixer/aplay/asound.conf 게이트.
- 산출: **3.2G** (SHA `7790d375cf2be06e0ee696935cb9e9710af5b5e42bc5d73d4a14457fd1bb9ec6`, Windows SHA 일치 검증 3,361,192,684 B). 게이트 전량 통과.
- **실기기 결과 (2026-08-17)**: ❌ **부팅 정지**(3.07초 이후 무출력) — 단 커널은 정상 생존. loglevel=8 재캡처로 근원 특정 = **mmc 번호 시프트**(RESET_GPIO=y로 WiFi SDIO 호스트가 mmc0 선점 → SD가 mmcblk1로 밀림 → `root=/dev/mmcblk0p2` 무한 대기). **함정 #29**.
- ✅ **부수 성과**: `allocated mmc-pwrseq` + `brcmfmac: Firmware: BCM4345/6 wl0 version 7.45.234` = **RESET_GPIO 픽스 적중 + 임베드 펌웨어 로드 성공** = WiFi 하드웨어 스택 정상 입증.
- 라이브 우회: SD cmdline을 `root=PARTUUID=4898efc0-02`로 교체(이미지 MBR 실측 + SD 실물 시그니처 교차검증 일치) → 재부팅 검증.

### arm64-v20 - 2026-08-17 (root=PARTUUID 정공법 — mmc 번호 시프트 면역) [스크립트 준비 완료]
**맥락:** v19가 드러낸 구조적 취약점(`/dev/mmcblkN` 하드코딩) 영구 해소. WiFi·USB 등 어떤 SDIO/MMC 호스트가 번호를 밀어도 root를 정확히 찾도록.
- **`build-2.0.0-cooked-arm64-v20.sh`** (v19 클론): ①sfdisk **`label-id: 0x4d415258`("MARX") 고정** → PARTUUID 결정적(`4d415258-02`) ②cmdline `root=PARTUUID=4d415258-02` ③게이트 2종 — 이미지 MBR signature 실측(`5852414d` LE) + cmdline `mmcblk` 잔재 금지. `bash -n` 통과.
- 내용물은 v19 유지(RESET_GPIO 커널 + 펌웨어 임베드 + wpa + 퀵설정 + 플로팅 시계).
- ▶ 현 SD(PARTUUID 라이브 픽스)로 기능 검증 통과 후 빌드 예정.

### arm64-v20 - 2026-08-22 (root=PARTUUID + fstab LABEL — mmc 번호 시프트 완전 면역)
**맥락:** v19가 부팅 3초에서 정지 → 근원 = WiFi(SDIO)가 mmc0 선점으로 SD가 mmcblk1로 밀림(**함정 #29**). cmdline·fstab **양 계층**을 번호 비의존으로 전환.
- sfdisk `label-id: 0x4d415258`("MARX") 고정 → PARTUUID 결정적 → cmdline `root=PARTUUID=4d415258-02`.
- `/etc/fstab` → **LABEL=maruxroot / LABEL=MARUXBOOT** (커널은 LABEL 파싱 불가라 cmdline은 PARTUUID, userspace는 LABEL — 계층별 해법 분리).
- 게이트: MBR signature 실측 / cmdline PARTUUID / fstab LABEL 3종 / mmcblk 잔재 금지.
- **커널 오염 검거**: 빌드 1차가 SHA 게이트로 abort — 8/21 23:19 제3 경로 재빌드본에서 `CONFIG_RESET_GPIO` 소실(함정 #28 재발 상태). 복구 재빌드 → **커널 SHA `a690210b…`(#7)**.
- 산출: **3.2G** (SHA `0d04c4ab719454e9e5492d1d786de352375f4cbf167be9ab30d358e7d901c09a`, Win 일치 3,372,549,580 B).
- **실기기 결과**: ✅ 부팅 성공(함정 #29 종결) ✅ wlan0 ✅ 스캔 / ❌ 연결 ASSOCIATED 정지 ❌ 볼륨 ❌ UI 혹평 → v21로.

### arm64-v21 - 2026-08-23 (wpa BRCM 빌드 + 퀵설정 UI v2 + 볼륨 부트스트랩)
**맥락:** v20 실기기 3건 피드백 근원 해소.
- **WiFi 4-way 수수께끼(함정 #30)**: assoc·암호협상 정상인데 `wait for driver port authorized indication` 후 타임아웃, **EAPOL 0건**. = wpa가 펌웨어 offload를 신뢰하고 대기하나 brcmfmac 펌웨어가 완료 이벤트를 안 줌. → **`CONFIG_DRIVER_NL80211_BRCM=y` 재빌드**(Raspberry Pi OS 공식 조합). 검증=바이너리 BRCM 문자열 50건. (부수: 평문 passphrase 시 CONNECT에 PSK 미포함, hex PSK로는 전달 확인)
- **퀵설정 UI v2**: 여백 8→16 + 내부 margin 16, WiFi/볼륨 **카드 계층**, **CSS PRIORITY_USER**(Adwaita가 라운드를 덮던 문제), 목록 라운드+호버, 슬라이더 커스텀, 볼륨 % 라벨. 87,688 B 재컴파일.
- **볼륨**: `amixer scontrols` 빈 출력 = 컨트롤 부재 → xinitrc 무음 1초 재생으로 softvol Master 선생성.
- 게이트 추가: wpa BRCM 문자열 실측 / xinitrc 볼륨 부트스트랩. **🆕 게이트 자체 버그도 검거**: `strings|grep -q`가 SIGPIPE+pipefail로 오탐 → `grep -qa` 직접 검색으로 교체(금지 패턴 박제).
- 산출: **3.2G** (SHA `f3aff23e13b967bd76bafec8eda0a0253b804f73fb50fe852f48e13bedc7b36a`, Win 일치 3,352,151,212 B). ▶ 실기기 검증 대기.

### arm64-v22 - 2026-08-23 (🏆 WiFi 정복 박제 + 우상단 통합 상태 바 + tint2 은퇴)
**맥락:** v21 실기기에서 WiFi가 여전히 실패(ASSOCIATED 정지) → 3단 수사로 진범 특정 = **brcmfmac FWSUP(펌웨어 supplicant)**. 커널 패치 후 **실기기 인터넷 도달 성공**(유선 없이 google.com 42ms). 이 검증분과 UI 통합을 이미지에 박제.
- **커널 FWSUP 패치**(`rebuild-kernel-wifi-arm64.sh` [2.5], 멱등+게이트): `feature.c`의 `sup_wpa` 감지 제거 → host supplicant 강제 → EAPOL 정상 전달. 커널 SHA `13bd3415…`. **함정 #31**.
- **wpa offload 차단**(`install-wifi-arm64.sh`): `driver_nl80211_capa.c`의 4WAY_HANDSHAKE_PSK/8021X 수용부 무력화 + 마커. **함정 #30**(full-mac은 비번 오류를 CONN_FAILED로 위장).
- **우상단 통합 상태 바**: `한/A · WiFi · ♪% │ 오후 h:mm / YYYY-MM-DD`를 단일 유리 바에(시계를 marux-quicksettings로 흡수, 88,192 B). → **config v10에서 tint2 완전 은퇴**(자산은 frozen 보존).
- **GUI IP 버그 수정**(사용자 신고): HashTable 파싱에서 `ip_address` 유실 → 직접 파싱 + `ip addr` 폴백 + 3초×3회 재확인. 스캔 파서도 동일 패턴 선제 교체. **vala 함정 #5**.
- 게이트 개편: tint2 6종 제거 → **FWSUP 소스 마커 / wpa offload 마커 / tint2 은퇴 / 통합바 기동** 4종 신설.
- 산출: **3.2G** (SHA `a94ea5f23ac6a8d2a55934afcd70a7bdfc2f133ca1b7ae7f4bac35829d2b77cf`, Win 일치 3,362,923,812 B). ▶ 실기기 검증 대기.

### arm64-v23 - 2026-08-23 (한/영 정확표시 + WiFi 아이콘 + UX 픽스 4종)
**맥락:** v22 실기기 피드백 — 통합 상태 바는 호평("오 좋다"), 한영 표시 고정 / WiFi 재연결 실패 / 독 유령 창 / 호버·아이콘 요청.
- **한/영 정확 표시**: ibus 패널 D-Bus 구현(반나절+) 대신 **ibus-hangul 엔진 소스 패치** — 모든 전환이 통과하는 `set_input_mode`에서 `/tmp/marux-ime-mode`에 han/eng 기록, GUI는 파일만 읽음. 엔진 재빌드 169,864 B, 바이너리 마커 게이트 상주.
- **WiFi 아이콘**: 폰트 글리프 부재(이모지 금지) → **cairo 직접 드로잉**(호 3개+중심점, RSSI 0~3단계).
- **독 유령 창 제거**: 드롭다운 UTILITY → **POPUP_MENU**(bamf가 창으로 안 잡음).
- **UX**: 바 호버 하이라이트 / **연결 실패 알림**(기존엔 "연결 중…"에서 침묵) / **TEMP-DISABLED 자동 해제** / 부팅 시 `wpa_cli set country KR`(5GHz 개방 시도).
- ※ v22 "WiFi 또 안 됨"의 진상 = 5G 시도 실패로 wpa가 네트워크를 자동 차단, 2.4G까지 여파. 기능 자체는 정상(수동 재연결 시 즉시 COMPLETED).
- 산출: **3.2G** (SHA `8c2321ac5aff79476df830373ca730ae49a65e0af140a7d4e16633c1c6851a36`, Win 일치 3,371,277,460 B). ▶ 실기기 검증 대기.

### arm64-v24 - 2026-08-23 (호버·실패알림·목록아이콘 실제 반영 + 방식 전환)
**맥락:** v23 피드백에서 "적용 안 됨"으로 보고된 항목들 — 실은 GUI 수정이 v23 빌드 *이후*라 $LFS에만 있었음(사용자가 정확히 지적). 재빌드로 반영 + 두 건은 방식 자체를 교체.
- **호버**: CSS→**cairo 직접 밝기 전환**(배경을 cairo가 그리는데 CSS로 덮으려던 설계 오류), 감지도 창 레벨 enter/leave.
- **실패 알림**: v23의 `POPUP_MENU` 전환 부작용(포커스 상실 시 패널이 닫혀 라벨을 볼 수 없음) → **Gtk.MessageDialog**로 별도 표시.
- **드롭다운 목록 WiFi 아이콘**: 각 행 cairo 아이콘(3단계). 재컴파일 89,280 B.
- 산출: **3.2G** (SHA `aad9e0224b40ab992592ec691f5d3e6d788e236bcdab7b4ef2581f370ec43998`, Win 일치 3,365,686,736 B).
- 🐛 조사 중: plank 우클릭 닫기(event_time 가설 유력) / 한영(엔진 lazy 기동 — xterm 타이핑 상태에서 검증 필요).

### arm64-v25 - 2026-08-25 (독 유령창 근절: override-redirect + 경고창 가시화)
**맥락:** v24에서 호버 ✅ / 목록 아이콘 ✅ 확인, 남은 2건 교정. **한/영 전환도 v24에서 실기기 성공**(사용자 "매우매우 잘됨").
- **독 유령창 근절**: DOCK(v22)·POPUP_MENU(v23) 모두 *타입 힌트*일 뿐 WM이 관리하는 창이라 bamf가 인식 → plank에 항목 잔존. **`Gtk.WindowType.POPUP`(override-redirect)**로 전환하여 WM/bamf가 존재 자체를 모르게 함. 바·드롭다운 적용, 키 입력 필요한 비밀번호 창만 일반 창 유지.
- **경고창 가시화**: 부모 없는 모달이 화면 뒤/밖에 뜨던 문제 → CENTER_ALWAYS + keep_above + stick + show_all/present.
- 산출: **3.2G** (SHA `f633b415fde676604dbd8471dd790274523e664869b890c718e31c964366ac21`, Win 일치 3,362,613,856 B).
- 🐛 조사 대기: plank 우클릭 "닫기" 무동작(event_time 가설).

### (스크립트 신규) 2026-08-25 — `install-qt5-arm64.sh` (배치 Q: Qt5 크로스 빌드)
**MaruxOS 최초의 호스트 크로스 컴파일.** qemu 네이티브는 Qt 규모상 불가(qtbase만 10시간+ 추정) → Qt5 공식 크로스 지원 사용(`-sysroot`/`-extprefix`/`-hostprefix`). 소스·빌드 트리는 **rootfs 밖**($B/qt-src)에 두어 이미지 비대화 방지.
- 단계: **[0-pre]** libtool `.la` 절대경로 무력화(114건) → **[0]** Qt xcb 필수 14종 사전 게이트 + 누락분(xcb-util-keysyms) 크로스 보강 → **[1]** qtbase(패치 2종: `<limits>`, xkb keysym 4종) 빌드/설치.
- 게이트: xcb 14종 존재 / **libQt5Core가 AArch64 ELF인지 readelf 확인**(x86 오산출 차단) / xcb 플랫폼 플러그인 / 호스트 moc.
- 결과: **qtbase 5.15.2 크로스 빌드 성공** — Core·Gui·Widgets·DBus·Network·Sql·Xml·Concurrent + xcb 플러그인 + 호스트 moc.
- 6겹 함정 상세 = docs/arm64/02-TRAPS-CATALOG.md **함정 #34**.
- ▶ 잔여: qtx11extras → qttools → qtermwidget → qterminal (⚠️ 후자 2종은 **CMake** — 크로스 툴체인 파일 필요).

### arm64-v26 - 2026-08-25 (🏆 배치 Q: Qt5 + QTerminal — 로드맵 3번 달성)
**맥락:** 2.0.0 로드맵 "③ xterm → QTerminal" 완수. MaruxOS 최초의 **호스트 크로스 컴파일**(qemu 네이티브는 Qt 규모상 불가, qtbase만 10시간+ 추정).
- **Qt5 5.15.2**: Core/Gui/Widgets/DBus/Network/Sql/Xml/Concurrent/X11Extras/XcbQpa + **xcb 플랫폼 플러그인**. `install-qt5-arm64.sh`(소스·빌드는 rootfs 밖 `$B/qt-src`, 설치만 `$LFS/usr`).
- **QTerminal 0.17.0** + qtermwidget 0.17.0 + lxqt-build-tools 0.13.0.
- **config v11**: 독·데스크톱 아이콘·openbox 메뉴 전부 qterminal로 통일(xterm은 **폴백 잔류**), `QT_QPA_PLATFORM_PLUGIN_PATH`/`QT_QPA_PLATFORM=xcb` 명시.
- **게이트 신설**: Qt 라이브러리 5종 + xcb 플러그인 + qtermwidget + **qterminal AArch64 readelf**(크로스 오설정 차단) + xinitrc Qt 경로 + openbox xterm 잔재 금지 + **xterm 폴백 존재 강제**.
- **10겹 함정**(= 함정 #33/#34): `<limits>` 시대차 / sed 3중 이스케이프 / xcb-keysyms 누락 / `.la` 절대경로 114건 / CC·CXX `--sysroot` / libxkbcommon 구버전 / **SVE 블록**(Cortex-A72 미지원) / lxqt-build-tools / **Qt5LinguistTools 호스트-타겟 혼선** / **`.desktop` 번역이 ARM perl 실행(Error 126)**.
- ▶ 실기기 검증 대기: qterminal 기동·한글 입력·독/메뉴 연동.

### arm64-v27 - 2026-08-25 (🏆 PCManFM-Qt — **2.0.0 로드맵 4/4 완주**)
**맥락:** 배치 F 완주. 1.x의 PCManFM(GTK) 사고(GLib 2.68 요구 → glibc 덮어쓰기 참사 → mc 후퇴)를 **Qt 경로로 정공 해소**.
- 사슬: libexif 0.6.24 → **libfm 1.3.2(--with-extra-only)** → menu-cache 1.1.0 → libfm-qt 0.17.0 → pcmanfm-qt 0.17.0. 배치 Q의 크로스 체계 전면 재사용.
- 함정: menu-cache 배포처 이동(SourceForge) / **순환 의존**(libfm↔menu-cache → extra-only) / intltool 누락 / **`-fcommon`**(GCC 10 기본값 변경, 2016년 코드) / **ARM pkg-config 실행**(→ 호스트 명시, perl과 동일 패턴).
- **config v12**: .desktop 5종, 독 = qterminal·pcmanfm-qt·firefox, openbox 메뉴 mc 잔재 0, **mc 폴백 잔류**.
- 게이트: pcmanfm-qt **AArch64 readelf** / libfm-qt·libfm-extra·menu-cache·libexif / .desktop·dockitem / 메뉴 mc 금지 / **mc 폴백 강제**.
- 산출: **3.2G** (SHA `bdf1f50e8735ce5b0df5a43f44b7c1b789269e5de799d03f84e41713b4b20190`, Win 일치 3,370,004,520 B).
- ▶ 실기기 검증 대기: QTerminal·PCManFM-Qt 기동/한글, 기존 회귀.

### arm64-v28 - 2026-08-26 (🚨 Qt 즉사 픽스: FORTIFY 오탐 — 함정 #35 + **기동 게이트** 신설) ✅
**맥락:** v27 실기기 검증에서 **QTerminal이 기동 즉시 `*** buffer overflow detected ***`로 SIGABRT**, PCManFM-Qt는 종료 시 동일 사망. chroot gdb 백트레이스 = `__readlink_chk ← qt_readlink ← QLockFile ← QSettings ← Properties::migrate_settings`. 원인 = **Ubuntu 크로스 gcc의 암묵 `-D_FORTIFY_SOURCE=3`**(우리가 준 적 없는 플래그)이 Qt 5.15.2 QByteArray 인라인 데이터 포인터의 크기를 오판. `--version`은 QSettings 전에 끝나 v26/v27의 존재·아키텍처 게이트를 전부 통과했다.
- **픽스**: Qt 스택 전체(qtbase·x11extras·qtermwidget·qterminal·libfm-qt·pcmanfm-qt·libexif·libfm-extra·menu-cache)를 **`-D_FORTIFY_SOURCE=2`로 재빌드** — `rebuild-qt-fortify-arm64.sh`(mkspec/CMake 툴체인/CFLAGS 3경로 주입 + 단계별 플래그 실존 grep). `install-qt5-arm64.sh`/`install-pcmanfm-qt-arm64.sh`에도 동일 주입(fresh 실행 정합).
- **게이트 승격 — 존재 검사 → 기동 검사**: 신규 `gate-qt-launch-arm64.sh`가 rootfs를 qemu chroot로 **실제 실행**(qterminal offscreen 12초 생존 / pcmanfm-qt 세션버스 기동 + SIGTERM 종료 경로 / 던져버릴 HOME 후 삭제). v28 빌드 게이트 = `.q-FORTIFY2-OK` 기록 SHA와 rootfs 바이너리 대조 + 기동 게이트 호출 + CMake 툴체인 FORTIFY 주입 확인.
- 부수: pcmanfm-qt는 세션 버스 없으면 "다른 인스턴스"로 오판해 조용히 exit 0(xinitrc는 이미 dbus-launch export). 함정 #5 확장 = WSL VM 유휴 종료 시 binfmt 소실 → 멱등 재등록 가드.
- (v27 유지: PCManFM-Qt, QTerminal, WiFi, 통합 상태 바, 한영 표시, PARTUUID/LABEL) 🐛 이월: plank 우클릭 닫기, 독 점 위치.
- 게이트 실전: 첫 판 기동 게이트(offscreen)가 pcmanfm-qt를 SIGSEGV로 오판(플러그인이 raise() 미지원) → **xcb/Xvfb로 교정** = 배포 경로 그대로. 재빌드 12분, `--gate-only` 재판정 PASS(qterminal 12초 생존 / pcmanfm-qt 12초 + aboutToQuit 종료 무사).
- 산출: **3.2G** (SHA `a5b1393d8e8c98f3d21965f5308652b99c49c2ba7b3fee965cb825d501d22996`, WSL·Win 일치 3,366,202,932 B, 사이드카 갱신). 빌드 01:39→02:04. 통과본 SHA: libQt5Core `9ae8296f…` / qterminal `aac9a30f…` / pcmanfm-qt `ca6e384b…`.
- ▶ 실기기 검증 대기: **QTerminal 기동**(즉사 재현 여부가 1번) → PCManFM-Qt 기동·**닫기** → Qt 앱 한글 입력 → 기존 회귀.

### arm64-v29 - 2026-08-26 (독 아이콘 투명 픽스 — 함정 #36: 패키지 재설치가 config `.desktop`을 덮어씀) ✅
**맥락:** v28 실기기 — **QTerminal·PCManFM-Qt 기동 성공(함정 #35 픽스 실증)**, 그러나 독 아이콘 2종 투명. 원인 = FORTIFY 재빌드의 `make install`이 config v12가 배포한 `.desktop`을 업스트림(`Icon=utilities-terminal` 테마 이름)으로 덮어씀 → hicolor뿐이라 빈 아이콘. "config → rootfs" 흐름의 역방향 오염.
- 조치: 라이브 픽스(시리얼 sed + plank 재기동) / rootfs = config v12 재적용(5/5 cmp 일치) / 스크립트 변경 없음.
- **게이트 승격 "존재≠내용"**: 독 5종 `.desktop` = `config/applications/` **바이트 일치** + 절대경로 Icon 실존 + 테마 이름 Icon 금지 + idesk `.lnk` Icon 실존. `rebuild-qt-fortify-arm64.sh` 말미에 config 재적용 경고.
- 산출: **3.2G** (SHA `312e4706576254b76c0a198bf6b8fbbaba80e630979babdd5de0b6e282abe1f6`, WSL·Win 일치 3,370,699,388 B, 사이드카 갱신). 빌드 22:32→22:52. 게이트 로그 3행에 `.desktop 5종 = config 원본 (바이트 일치)` ✓.
- ▶ 실기기 검증: 독 아이콘 3종 → QTerminal/PCManFM-Qt 기동·닫기 → Qt 한글 → 회귀.

### arm64-v30 - 2026-08-26 (자동 로그인 + X 자동 기동 — 출품용 "부팅하면 바로 화면") ✅
**맥락:** 8/27 출품 직전 사용자 요청 "ㄹㅇ 운영체제처럼 부팅하면 바로 화면까지". 디스플레이 매니저 없이 sysvinit 수준에서 구현.
- **config v13**: `inittab` tty1 → `agetty --autologin root --noclear tty1 9600`(util-linux 2.39.3, 실기기 `--help`로 지원 실측) + `/root/.bash_profile`(+skel): 로그인 셸이 tty1이고 DISPLAY 없으면 `startx`. **exec 아님** → X 종료/실패 시 tty1 셸 복귀(respawn 루프 없음), 로그아웃(exit) 시 agetty 재자동로그인 → DM 체감. **ttyS0 시리얼 getty 유지** = 디버깅 통로.
- 게이트: inittab tty1 줄 정확 일치 / agetty autologin 문자열 / .bash_profile(root·skel) tty1 startx 가드 + `exec startx` 금지 + 문법.
- 자기 도구 함정: 첫 발사가 `strings agetty | grep -q autologin`에서 거짓 실패 — **`set -o pipefail` 아래서 grep -q가 먼저 닫아 strings가 SIGPIPE(141)** → 파이프 없는 `grep -a -q`로 교정(config v13·build v30 동일). 게이트가 자기 오류를 잡은 사례.
- 산출: **3.2G** (SHA `29579682072cd1a78c15df4d775e6e1d4840a343619f8b883622a0ad24a8a535`, WSL·Win 일치 3,372,483,208 B, 사이드카 갱신). 빌드 23:09→23:30.
- ▶ 실기기: 전원 인가 → 로그인 없이 데스크톱 → 독 아이콘 3종 → QTerminal/PCManFM-Qt 기동·닫기 → 한글 → 회귀.

### arm64-v31 - 2026-08-27 (배치 E: FeatherPad 텍스트 편집기 + MIME 기본앱 — "txt 여는 notepad") [빌드 중]
**맥락:** 출품 당일 사용자 요청 "txt 같은 텍스트 여는 notepad 같은 거 포함". Qt 크로스 체계 그대로 재사용해 **FeatherPad 0.17.1**(LXQt 계열 Qt5 편집기) 탑재.
- 사슬: **qtsvg**(qmake 모듈, FeatherPad 필수 — rootfs에 없었음) → **hunspell 1.7.2**(0.17.1은 REQUIRED, `WITH_HUNSPELL` 옵션은 후속 버전 — 첫 발사가 확인) → FeatherPad(CMake). 전부 FORTIFY=2(함정 #35). `install-featherpad-arm64.sh`(마커 `.e-markers`, 완료 `.e-COMPLETE`).
- 게이트 오탐 1건: qtsvg 하위 Makefile은 `make` 시점에 생성 → 사전 grep 빈손 → **make 후 검사**로 이동.
- **config v14**: `featherpad.desktop`(config SSOT, Icon=file-text.png) + openbox 메뉴 "Text Editor"(apps/root, "(mc)" 라벨 잔재 정정) + idesk 바탕화면 아이콘 + **MIME 기본앱**: `mimeapps.list`(/usr/share/applications + /etc/xdg) text/plain·x-shellscript·x-c·x-python·css → featherpad, html → firefox; rootfs에 desktop-file-utils가 없어 **mimeinfo.cache를 config가 직접 생성**. → PCManFM-Qt에서 .txt 더블클릭 = FeatherPad.
- 기동 게이트 확장: featherpad가 test.txt를 열고 12초 생존(PASS). 빌드 게이트: featherpad AArch64 + libQt5Svg + `.desktop` **6종** config 바이트 일치 + mimeapps/mimeinfo + 메뉴/lnk + `.e-COMPLETE`.
- 독은 3종 유지(편집기는 메뉴/바탕화면/파일 연결).
- 산출: **3.2G** (SHA `46293e9d49e0b3d9b6d53fbb0a7985bd595a239ec4af541ba7778a7799ca7536`, WSL·Win 일치 3,369,891,836 B). 빌드 02:05→02:32. 편집기 아이콘은 플레이스홀더(file-text.png) — v32에서 교체.

### arm64-v32 - 2026-08-27 (편집기 아이콘 + **배치 T**: LXImage-Qt·SpeedCrunch·LXQt Archiver·qps 1.10.20) ✅
**맥락:** 디자이너(tuna27) 바쁨 → 사용자가 "텍스트 파일 아이콘 이런 거처럼"으로 스타일 지정(줄 있는 종이 + 접힌 모서리). PIL로 128px 생성 → `MaruxOS 디자인/marux-editor.png`(SSOT).
- **config v15**: `$DZN/marux-editor.png` → `/usr/share/pixmaps/maruxos/`, featherpad.desktop(config) + idesk editor.lnk Icon 교체. 나머지 v14 동일.
- **배치 T** (사용자: "LXImage-Qt, SpeedCrunch, LXQt Archiver, qps 넣자 다"): `install-lxtools-arm64.sh` — 전부 Qt5 CMake 크로스(툴체인 FORTIFY=2). LXImage-Qt 0.17.0(뷰어+스크린샷, libfm-qt·libexif·Svg 기존) / SpeedCrunch 0.12.0(Debian orig 소스, 루트 src/) / LXQt Archiver 0.2.0(+**json-glib 1.6.6 meson 크로스**, unzip/zip Info-ZIP 비치명) / qps 2.3.0. 개별 마커·SKIP_* 로 하나가 막혀도 나머지 진행.
- config v15: .desktop 4종(PIL 아이콘 4종 `marux-image/calc/archive/taskmgr.png`) + 메뉴(Image Viewer/Calculator/Archive Manager/Task Manager=qps, top은 터미널 항목으로 잔류) + MIME(image/* → lximage-qt, zip/tar/gz/xz/7z → lxqt-archiver). feh 폴백 잔류. 기동 게이트 ④ 4종 추가.
- 게이트: `.desktop` **10종** 바이트 일치 + 아이콘 5종 실존 + 4종 AArch64·메뉴 + json-glib + MIME + `.t-COMPLETE`.
- 배치 T 벽 6개(ARM64-Log 표): SpeedCrunch가 QtHelp를 헤더까지 요구 → **qttools `src/assistant/help` 모듈만** 크로스(PCH off, HelpConfigExtras 호스트 도구 검사 제거) / qps 2.3.0은 liblxqt 요구 → **1.10.20** + `QT_NO_CAST_FROM_ASCII` remove_definitions / 게이트: lximage-qt는 D-Bus 단일 인스턴스라 세션 버스 붙여 실행. 기동 게이트 7종 PASS.
- 산출: **3.2G** (SHA `8fe60e87e983950819376a6b7b0723a016854b17ea1cd8cf34e225a23bbcc597`, WSL·Win 일치 3,373,784,532 B, 사이드카 갱신). 빌드 02:47→03:07. 게이트: .desktop 10종 바이트 일치 / 기동 게이트 7종 / autologin / FeatherPad / 배치 T.
- ⚠️ 이 이미지까지 **`/sources`(12G tarball)가 이미지에 동봉**되어 있었다(3.2G의 대부분). v33에서 제거 예정(소스는 SOURCES.md·릴리즈로 제공). 라이선스 텍스트·펌웨어 LICENCE 미동봉 — v33에서 반영.

### arm64-v33 - 2026-08-27 (🪶 다이어트 + 📜 라이선스 동봉 — 출품 제출본) ✅
**맥락:** 사용자 "딱 운영체제 구동에 필요한 것만, 슬림하게" + 라이선스 전면 정정(Kernel-Log §32). 실측 rootfs 18G = **/sources 12G가 이미지에 통째로**(v27~v32 3.2G의 정체) + gcc 본체 1.6G + python 297M + .a 187M + doc/man/info 192M + locale 163M + include 86M, unstripped ELF 827.
- **다이어트(이미지 사본만, $LFS 원본 유지)**: rsync exclude(/sources·/usr/include·doc/man/info/gtk-doc·gir/vala·cmake/pkgconfig/mkspecs·.la/.a·python·gcc 컴파일러 본체·binutils 실행파일·i18n) + locale ko/en만 + `strip --strip-unneeded`(/opt/firefox 제외). `SLIM_KEEP_GCC=1`로 컴파일러 유지 가능. IMGSIZE 27G → **8G**.
- **라이선스 동봉**: `/usr/share/licenses/`(공통 13 + pkg 216 + MaruxOS LICENSE·THIRD-PARTY·SOURCES·patches 9종), boot 파티션 `LICENCE.broadcom`, `/lib/firmware/LICENCE.cypress`·`LICENCE.broadcom_bcm43xx`·wireless-regdb, `fonts/nanum/OFL.txt`. 라이선스 = **The Unlicense**(MaruxOS 저작물).
- **게이트(슬림 사본)**: /sources·/usr/include 부재 / libgcc_s·libstdc++ 실존 / **모든 ELF NEEDED 해석 0누락** / python 참조 0(xinitrc·init.d·.desktop·독) / strip 표본 / 라이선스 파일 실존 / **기동 게이트 7종을 슬림 사본에서 재실행**(`QTGATE_ROOT`) / 라이선스 자산 HTML(봇 차단 페이지) 오염 검사.
- 발사 5회(게이트 자기 오류 4건 교정: readelf pipefail 침묵사·`ls a b glob` 전부누락 오판·libperl 깊은 경로·MimeType text/x-python 오탐·사본 경로 가드). 슬림 사본에서 **기동 게이트 7종 PASS**, NEEDED 202종 전부 해석.
- 산출: **361M** (SHA `fc3e038f42758b78c589b8b46029e3a927e1f2f263bac07a0226689e6beabca2`, WSL·Win 일치 377,620,436 B, 사이드카 갱신). rootfs 복사 1.3G → strip 후 **919M** → xz **361M** (v32 3.2G 대비 **-89%**). 빌드 03:45→03:50(5분, 이미지 8G).

### arm64-v34 - 2026-08-27 (🔐 공개 릴리즈용 root 비번 marux + v33 다이어트/라이선스) ✅ **= GitHub 릴리즈 자산**
**맥락:** GitHub 공개 직전 비밀정보 스캔(Kernel-Log §33) — v33까지의 이미지 `/etc/shadow` root 해시가 개발자 개인 비번이었음. 이미지 사본에서 `openssl passwd -6`로 `marux` 해시 주입 + salt 재계산 검증 게이트. 첫 발사는 호스트 절전 복귀 후 snapfuse 마운트가 굳어 `sfdisk`의 `sync()`가 무한 대기 → WSL 재시작 후 재발사.
- 산출: **384M** (SHA `1a6cbcc0a1cf842de7fc2edcd4336d6fed506804ed1be57ffafd4e852b730756`, WSL·Win 일치 401,815,008 B, 사이드카 갱신). 슬림 사본 기동 게이트 7종 PASS, root 해시 검증 ✓. 빌드 18:04→18:09.

### (선행 스크립트 변경) 2026-08-14 — libwnck 43.0→43.2 + config v8
- **`install-plank-arm64.sh`**: libwnck **43.2**로 버전업 — 43.0은 `invalidate_icons`에 screens NULL 가드가 없어 bamfdaemon 즉사(실기기 dmesg 트레이스→디스어셈블→43.0↔43.2 diff로 근원 특정. 업스트림 픽스 채택). $LFS 재빌드 완료(bamf 포함). **43.2 라이브 검증**: gzip+base64 시리얼 무플래시 배포 → bamf 가동 → **점 표시+실행 중 앱 클릭 전환 실기기 확인**.
- **`setup-desktop-config-arm64-v8.sh`** (v7 클론): tint2 **clock-only**(`panel_items = C`, `panel_size = 100 36`) — 윈도우식 우하단 시계(실기기 확정).
- **v17 예정**: v16 클론 + 게이트 수정(panel C/100 + wnck 43.2 확인). 절차=ARM64-Update-Log "2026-08-14" 핸드오프.

---

## 빌드 정보

| 항목 | 값 |
|------|-----|
| 최초 빌드 | 2025-12-16 |
| 정식 릴리즈 | 1.0 (v37), 1.1 (67-v54), **1.2.1 (1.2.0-67-v4)** |
| 진행 중 | **2.0.0 "Cooked"** (ARM64 최신 = **arm64-v34** `1a6cbcc0…` **384M** — v33 + 공개용 root 비번 marux = GitHub 릴리즈 자산 ← v30 `29579682…`: v28에서 Qt 기동 실증(함정 #35 픽스) + 독 아이콘 투명(함정 #36) 픽스 + `.desktop` 내용 게이트. 로드맵 4/4 코드 완주, 실기기 최종 검증 대기 / 8-27 출품) |
| 코드네임 변천 | Phoenix (1.0 초기) → 67 (1.0~1.2.x) → **Cooked** (2.0.0+) |
| 커널 | 1.x: Linux 6.7.4 (Genesis hallucination, 광고는 6.12) / **2.0.0+: Linux 6.18.26 LTS** (정공 정정) |
| 압축 방식 | gzip (squashfs) |
| ISO 크기 | ~1.2GB |
| 총 빌드 횟수 (집계) | 1.x 시리즈 92회 + 1.2.x 시리즈 4회 + 2.0.0 시리즈 7회 = **103회+** |

---

## 파일 구조 (현재 2.0.0-cooked-v7)
```
MaruxOS-2.0.0-cooked-v7.iso
├── boot/
│   ├── grub/
│   │   └── grub.cfg              # Desktop / Safe Mode / Debug 3 엔트리
│   ├── vmlinuz                    # → vmlinuz-6.18.26-maruxos (symlink)
│   └── initrd.img                 # minimal busybox (lib/modules 없음)
└── live/
    └── filesystem.squashfs        # gzip 압축
```

---

## 버전 타임라인

| 날짜 | 버전 | 주요 변경 |
|------|------|----------|
| 2025-12-16 | x86_64 ~ v10 | 초기 시스템 구축 |
| 2025-12-17 | v11 ~ v24 | 시스템 안정화 및 개선 |
| 2025-12-18 | v25 ~ v31 | 데스크톱 환경 구축 |
| 2025-12-19 | v32 ~ 67-v3 | 터미널, 코드네임 변경 |
| 2025-12-20 | 67-v4 ~ 67-v10 | 파일 관리자 시도, 윈도우 버튼 추가 |
| 2025-12-23 | 67-v11 | 윈도우 버튼 클릭 이벤트 수정 |
| 2025-12-24 | 67-v12 | 커스텀 아이콘, 시스템 트레이, Chromium 추가 |
| 2025-12-30 | 67-v13 ~ v15 | Chromium 수정, mc 개선, Windows 11 스타일 태스크바 |
| 2026-01-02 | 67-v16 | Firefox 브라우저 설치 |
| 2026-01-03 | 67-v17 | Firefox 디버그 모드, 라이브러리 추가 |
| 2026-01-03 | 67-v18 | Firefox 로케일 수정, 시스템 트레이 유틸리티 |
| 2026-01-04 | 67-v19 | 커스텀 아이콘 테마 적용 (실패) |
| 2026-01-10 | 67-v20 | xinitrc 수정, 배경화면 경로 수정, GTK 아이콘 테마 설정 |
| 2026-01-10 | 67-v21 | tint2 버튼으로 WiFi/볼륨/배터리 아이콘 추가 (실패) |
| 2026-01-10 | 67-v22 | tint2 executor로 시스템 아이콘 구현 |
| 2026-01-10 | 67-v23 | 네트워크 아이콘 실제 상태 반영 |
| 2026-01-11 | 67-v24 | dhcpcd 설치, 네트워크 DHCP 지원 |
| 2026-01-11 | 67-v25 | /etc/issue 코드네임 Phoenix → 67 수정 |
| 2026-01-11 | 67-v26 | dhcpcd xinitrc 추가, rc.local 생성 |
| 2026-01-11 | 67-v27 | rc.sysinit/lsb-release 코드네임 수정, 네트워크 인터페이스 자동 감지 |
| 2026-01-20 | 67-v28 | 네트워크 인터페이스 자동 활성화 (ip link set up) |
| 2026-01-20 | 67-v29 | 네트워크 초기화 로그 추가 (/tmp/Network_log.txt) |
| 2026-01-21 | 67-v30 | initrd "Phoenix" → "67" 수정 |
| 2026-01-21 | 67-v31 | squashfs 재빌드 (xinitrc 포함) |
| 2026-01-21 | 67-v32 | /etc/skel/.bash_profile 추가 (startx 자동실행) |
| 2026-01-21 | 67-v33 | rc.sysinit 복사 명령어 수정 (cp -a) |
| 2026-01-21 | 67-v34 | rc.sysinit에 .xinitrc 명시적 복사 추가 |
| 2026-01-21 | 67-v35 | 시스템 전역 xinitrc에 네트워크 로그 코드 추가 |
| 2026-01-22 ~ 01-28 | 67-v36 | GitHub Release v1.0, 문서 전면 개편, Public Domain 라이선스 |
| 2026-02-13 | 67-v37 | Firefox 아이콘 중복 표시 수정 (StartupWMClass=Navigator) |
| 2026-02-13 | 67-v38 | 한국어 로케일 지원 추가 (ko_KR.UTF-8, ibus 설정) |
| 2026-02-13 | 67-v44 ~ v47 | 완벽한 한국어 로케일 지원, Nanum 폰트 설치 |
| 2026-02-13 | 67-v49 | ibus-hangul 한글 입력기 설치, Ctrl+P 한영 전환 |
| 2026-02-13 | 67-v50 | 한영 전환 키 Ctrl+P → Ctrl+Y (Firefox 충돌 해결) |
| 2026-02-13 | 67-v51 | ibus-daemon 디버깅 강화 (ldd, verbose, exit code 체크) |
| 2026-02-13 | 67-v52 | --daemonize 제거, 포그라운드 실행으로 실제 에러 확인 |
| 2026-02-14 | 67-v53 | ibus memconf 설정 백엔드 활성화 (근본 원인 해결) |
| 2026-02-19 | **67-v54** | **한글 입력 완전 작동! (v1.1 릴리즈)** |
| 2026-02-27 | 1.2.0-67-v1 | 1.2.0 시리즈 시작 — idesk, neofetch, openbox menu, marux-* 헬퍼 |
| 2026-03-04 | 1.2.0-67-v2 | 헤더 라벨 변경 (실제 코드 변경 없음, 함정) |
| 2026-05-05 | 1.2.0-67-v3 | idesk SIGHUP 함정 픽스 (setsid) |
| 2026-05-05 | **1.2.0-67-v4** | **PNG prefix 통일 + 디자인 아이콘 sync (v1.2.1 정식 릴리즈)** |
| 2026-05-05~06 | 2.0.0-cooked-v1 | **커널 6.7.4 → 6.18.26 LTS 정정** + 검증 게이트 5종 + 코드명 Cooked |
| 2026-05-06 | 2.0.0-cooked-v2 | 메타데이터 canonical 템플릿 + splash 67→Cooked |
| 2026-05-07~06-08 | 2.0.0-cooked-v3 | Plank dock 도입 시도 (ldd 통과, schema 함정 노출) |
| 2026-06-08 | 2.0.0-cooked-v4 | Plank schema strict 처리 + Xresources + XDG 메타 |
| 2026-06-08 | 2.0.0-cooked-v5 | tint2 풀 패널 복귀 (UI 반쪽 해소) |
| 2026-06-08 | 2.0.0-cooked-v6 | libplank-common 발견 (schema 진짜 위치) |
| 2026-06-08 | 2.0.0-cooked-v7 | Plank dockitem 풀세팅 시도 (실행 OK, dock-items GSettings 미주입) |
| 2026-06-19 | **2.0.0-cooked-v8** | **Plank 롤백 — 1.x tint2 풀 패널로 안정화. Plank는 2.0.x로 deferred** |

---

## 기술 노트

### gzip을 사용하는 이유
LFS 커널이 xz/lzma squashfs 지원 없이 빌드됨. gzip 압축으로 전환하여 부팅 실패 해결.

### pcmanfm을 사용하지 않는 이유
pcmanfm은 `g_once_init_leave_pointer` 심볼을 위해 GLib 2.68+ 필요. LFS 시스템의 GLib 버전이 낮아 심볼 조회 에러 발생. GLib 라이브러리를 복사하면 시스템 불안정.

### xfe를 사용하지 않는 이유
xfe는 FOX 툴킷을 사용하며 LFS 시스템 라이브러리와 호환성 문제로 Segmentation fault 발생.

### 현재 파일 관리자
mc (Midnight Commander)를 파일 관리자로 사용. 터미널 기반이지만 LFS 시스템 라이브러리와 안정적으로 작동.

### WSL2 크로스 컴파일 시 Wayland 문제
WSL2의 GTK3에는 Wayland 지원이 포함되어 `GDK_WINDOWING_WAYLAND` 매크로가 정의됨. ibus의 GTK3 IM 모듈(im-ibus.so)이 이 매크로를 참조하여 Wayland 코드를 포함하게 됨. MaruxOS는 X11 전용이므로 Wayland 심볼이 존재하지 않아 `undefined symbol` 에러 발생. ibus `--disable-wayland` 옵션은 GTK3 IM 모듈의 Wayland 코드를 제어하지 못함 (GTK3 헤더의 `#ifdef`로 제어됨). 해결책: 소스 코드에서 `GDK_WINDOWING_WAYLAND`을 `MARUX_DISABLED_WAYLAND`로 직접 치환.

### Live ISO에서 GTK immodules cache 문제
squashfs는 읽기 전용이므로 `/usr/lib/gtk-3.0/3.0.0/immodules.cache`를 런타임에 수정 불가. `gtk-query-immodules-3.0`도 im-ibus.so를 캐시에 자동 등록하지 못함. 해결책: xinitrc에서 `/tmp/gtk-immodules.cache`에 ibus 항목을 수동으로 추가하고 `GTK_IM_MODULE_FILE` 환경변수로 이 파일을 지정.

### ibus memconf 설정 백엔드
LFS에는 dconf/GSettings 데이터베이스가 없으므로 ibus의 기본 설정 백엔드(dconf)를 사용할 수 없음. `--enable-memconf`로 ibus를 빌드하면 메모리 기반 설정 백엔드를 사용. gsettings 명령으로 런타임에 설정을 주입하면 memconf가 메모리에 저장.

### 2.0.0 신규 기술 노트

#### 6.7.4 → 6.18.26 커널 정정 (Genesis hallucination)
1.x 시리즈는 광고로는 "Linux 6.12 LTS"였으나 실제 vmlinuz는 **6.7.4** (2024년 1월 stable). Genesis 단계(2025-12-14)에 AI hallucination으로 박힌 후 92회 빌드 동안 재컴파일 0회. 2026-05-05 발견. 2.0.0 "Cooked"에서 정공 6.18.26 LTS로 정정 + 검증 게이트 5종으로 재발 방지. 자세한 시간순 기록은 `Kernel-Update-Log.md`.

#### Plank dock의 GSettings schema가 별도 패키지에 있는 이유
Debian source `plank`은 4개 binary 패키지로 분할됨 (plank / libplank1 / libplank-dev / **libplank-common**). GSettings schema (`net.launchpad.plank.gschema.xml`)는 **libplank-common** (architecture-independent, `_all.deb`)에 있음. plank.deb나 libplank1.deb엔 없음. install-plank.sh이 5개 .deb만 추출하면 schema 못 찾고 plank 부팅 시 SIGTRAP. 2026-06-08 발견 후 추가.

#### Minimal busybox initrd 제약 (lib/modules 없음)
1.x부터 사용 중인 initrd는 busybox 기반 minimal 구조로 `/lib/modules` 없음. 즉 부팅 시 모듈 로드 불가. 부팅 필수 드라이버(squashfs, iso9660, virtio, ahci, nvme, xhci, ext4, NET 등)는 모두 커널에 **builtin (`=y`)** 으로 빌드 필수. 2.0.0의 `02-build-kernel.sh`에 명시적 `enable_builtin` 호출 + critical 옵션 grep 검증 게이트 있음.

#### WSL 커널 빌드는 native fs 필수
Windows 마운트 드라이브 `/mnt/c/`는 NTFS case-insensitive. 커널 소스의 대문자 파일명(`xt_TCPMSS.c`, `xt_TCPOPTSTRIP.c` 등)이 압축 해제 시 손상돼 빌드 시 `No rule to make target xt_TCPMSS.o` 에러. 해결: 커널 소스는 WSL native ext4 (`/home/$USER/MaruxOS-kernel-build/`)에서 빌드. 2026-05-06 발견.

#### sudo 실행 시 `$USER=root` 함정
`sudo bash script.sh`는 `$USER`/`$HOME` 등을 root로 바꿈. 그러나 작업 결과(커널 빌드 등)는 원래 사용자(`administrator`)의 홈에 있음. 해결: 빌드 스크립트에서 `${SUDO_USER:-$USER}` 패턴 사용.