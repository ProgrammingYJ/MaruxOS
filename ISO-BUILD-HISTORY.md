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


## 빌드 정보

| 항목 | 값 |
|------|-----|
| 최초 빌드 | 2025-12-16 |
| 현재 버전 | 67-v35 |
| 코드네임 | 67 (구 Phoenix) |
| 버전 | 1.0 |
| 압축 방식 | gzip (squashfs) |
| ISO 크기 | ~1.2GB |
| 총 빌드 횟수 | 69회 (x86_64 + v2~v33 + 67-v1~v35) |

---

## 파일 구조
```
MaruxOS-1.0-67-v35.iso
├── boot/
│   ├── grub/
│   │   ├── grub.cfg
│   │   └── bios.img
│   ├── vmlinuz
│   └── initrd.img
└── live/
    └── filesystem.squashfs (gzip 압축)
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