# scripts/ — 어디서부터 읽을까

| 목적 | 현재 진입점 |
|---|---|
| **x86_64 Live ISO 빌드** (cooked-v10, 2026-08-28) | [`build-2.0.0-cooked-v10.sh`](build-2.0.0-cooked-v10.sh) — 패리티 rootfs → 스테이징 슬림 → 게이트 → squashfs xz → ISO |
| **ARM64 / Raspberry Pi 4B 이미지 빌드** (arm64-v34) | [`build-2.0.0-cooked-arm64-v34.sh`](build-2.0.0-cooked-arm64-v34.sh) |
| 커널 다운로드·빌드 (양 트랙) | [`build/01-download-kernel.sh`](build/01-download-kernel.sh), [`build/02-build-kernel.sh`](build/02-build-kernel.sh) |
| 데스크톱 config 배포 (xinitrc·독·MIME·자동 로그인) | [`setup-desktop-config-arm64-v15.sh`](setup-desktop-config-arm64-v15.sh) / [`setup-desktop-config-x86-v1.sh`](setup-desktop-config-x86-v1.sh) |
| 패키지 설치 모듈 | `install-*-arm64.sh` (qemu-chroot 네이티브 또는 호스트 크로스) / `install-*-x86.sh` (같은 스크립트의 x86 sysroot 변환본) |
| 검증 게이트 | `gate-qt-launch-*.sh` (Xvfb에서 Qt 앱 7종 실제 기동), `gate-qt-fortify-x86.sh`, `rebuild-qt-fortify-arm64.sh` |
| 소스·패치 목록 생성 (SOURCES.md, patches/) | [`gen-sources-and-patches-arm64.sh`](gen-sources-and-patches-arm64.sh) |

## 규칙
- 빌드 스크립트는 **버전별로 새 파일**을 만들고 이전 버전은 수정하지 않는다(재현성). 대체된 버전은 [`archive/`](archive/)로 옮긴다 — 내용은 그대로이며 `ISO-BUILD-HISTORY.md`가 버전별 변경을 서술한다.
- 모든 단일 진실값(커널 버전·SHA256·코드명·config 파일 내용)은 빌드 산출물과 대조하는 **게이트**를 갖는다. 게이트의 기대값도 실측으로 채운다.
- 패키지를 (재)설치한 뒤에는 반드시 `setup-desktop-config-*`를 재적용한다(함정 #36: `make install`이 config가 배포한 `.desktop`을 덮어쓴다).
- 실행 환경: WSL2 root. 긴 빌드는 `nohup setsid`. 커널 소스는 WSL 네이티브 fs(`/mnt/c` 금지).

## archive/
- `1.x/` — 1.0 "Phoenix" ~ 1.2.1 "67" 빌드·픽스 스크립트(build-67-v19~v54, fix-67-v3~v36 …)
- `2.0.0-x86_64/` — cooked-v1 ~ v9 (v10이 현재)
- `2.0.0-arm64/` — arm64-v6 ~ v33, config v1 ~ v14, 초기 한글 설치 모듈 (v34 / config v15가 현재)
