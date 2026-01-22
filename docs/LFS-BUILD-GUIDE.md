# MaruxOS - Linux From Scratch Build Guide

**[English](#english) | [한국어](#한국어)**

---

# 한국어

이 가이드는 MaruxOS를 **완전히 처음부터** 빌드하는 방법을 설명합니다. Debian이나 다른 배포판에 의존하지 않는 **순수 LFS(Linux From Scratch)** 방식입니다.

---

## 📋 목차

1. [개요](#개요)
2. [시스템 요구사항](#시스템-요구사항)
3. [빌드 단계 개요](#빌드-단계-개요)
4. [상세 빌드 프로세스](#상세-빌드-프로세스)
5. [문제 해결](#문제-해결)
6. [예상 시간](#예상-시간)

---

## 개요

### MaruxOS란?

MaruxOS는 **Linux From Scratch (LFS) 12.1**을 기반으로 하는 완전히 독립적인 Linux 배포판입니다.

**핵심 특징:**
- 100% 소스코드부터 빌드
- 외부 배포판 의존성 제로
- 완전한 커스터마이징 가능
- Linux 6.12 LTS 커널
- GCC 13.2.0 도구체인
- SysVinit 초기화 시스템
- Openbox + tint2 데스크톱 환경

### 빌드 방식

```
Host System (Ubuntu WSL)
    ↓
Cross-Compilation Toolchain (Pass 1)
    ↓
Temporary Tools (Pass 2)
    ↓
Chroot Environment
    ↓
Final System Build
    ↓
Kernel + Bootloader
    ↓
MaruxOS 완성!
```

---

## 시스템 요구사항

### 하드웨어

| 구성 요소 | 최소 | 권장 |
|---------|------|------|
| CPU | 4 코어 | 8+ 코어 |
| RAM | 8GB | 16GB+ |
| 디스크 공간 | 100GB | 200GB+ |
| 빌드 시간 | 15-25시간 | 10-15시간 |

### 소프트웨어

- **OS**: Windows 10/11 with WSL2 (Ubuntu)
- **필수 패키지**:
  ```bash
  sudo apt update
  sudo apt install -y build-essential bison gawk texinfo \
                      wget curl git vim python3 m4 libgmp-dev \
                      libmpfr-dev libmpc-dev
  ```

### 호스트 시스템 검증

빌드 시작 전 호스트 시스템을 검증하세요:

```bash
cd ~/MaruxOS
bash scripts/version-check.sh
```

모든 요구사항이 충족되어야 합니다.

---

## 빌드 단계 개요

### 전체 단계

| Phase | 스크립트 | 설명 | 예상 시간 |
|-------|---------|------|----------|
| 0 | `00-prepare-lfs.sh` | LFS 환경 준비 | 5분 |
| 1 | `01-download-sources.sh` | 소스 패키지 다운로드 (3.8GB) | 30-60분 |
| 2 | `02-build-cross-toolchain.sh` | 크로스 컴파일 도구체인 빌드 | 2-3시간 |
| 3 | `03-build-temp-tools.sh` | 임시 도구 17개 빌드 | 3-6시간 |
| 4 | `04-prepare-chroot.sh` | Chroot 환경 준비 | 5분 |
| 5 | `05-enter-chroot.sh` | Chroot 진입 (수동) | - |
| 6 | `06-build-additional-tools.sh` | 추가 임시 도구 (Chroot 내부) | 1-2시간 |
| 7 | `07-build-final-system.sh` | 최종 시스템 빌드 (80+ 패키지) | 8-15시간 |
| 8 | `08-system-configuration.sh` | 시스템 설정 + 커널 + GRUB | 1-2시간 |

**총 예상 시간: 15-30시간** (하드웨어에 따라 다름)

---

## 상세 빌드 프로세스

### Phase 0-3: 호스트 환경에서 실행

#### 1단계: 저장소 클론 및 준비

```bash
cd ~
git clone https://github.com/marux/MaruxOS.git
cd MaruxOS
```

#### 2단계: LFS 환경 준비

```bash
sudo bash scripts/lfs/00-prepare-lfs.sh
```

**이 단계에서 수행되는 작업:**
- LFS 디렉토리 구조 생성 (`~/MaruxOS/lfs`, `~/MaruxOS/build/rootfs-lfs`)
- 빌드 사용자 및 권한 설정
- 환경 변수 구성

#### 3단계: 소스 패키지 다운로드

```bash
bash scripts/lfs/01-download-sources.sh
```

**다운로드되는 패키지:**
- 총 80+ 패키지, 약 3.8GB
- 모든 패키지의 체크섬 검증
- 실패 시 자동 재시도

#### 4단계: 크로스 컴파일 도구체인 빌드

```bash
bash scripts/lfs/02-build-cross-toolchain.sh
```

**빌드되는 도구:**
- Binutils Pass 1
- GCC Pass 1 (C 컴파일러 only)
- Linux API Headers
- Glibc (C 표준 라이브러리)
- Libstdc++ (C++ 표준 라이브러리)

**중요:** 이 단계는 매우 오래 걸립니다 (2-3시간). 중단하지 마세요!

#### 5단계: 임시 도구 빌드 (Phase 6)

```bash
bash scripts/lfs/03-build-temp-tools.sh
```

**빌드되는 17개 패키지:**
1. M4
2. Ncurses
3. Bash
4. Coreutils
5. Diffutils
6. File
7. Findutils
8. Gawk
9. Grep
10. Gzip
11. Make
12. Patch
13. Sed
14. Tar
15. Xz
16. Binutils Pass 2
17. **GCC Pass 2** (중요: 특별한 CXXFLAGS 필요)

**알려진 이슈와 해결방법:**

GCC Pass 2 빌드 시 C++ 헤더 오류가 발생할 수 있습니다:
```
fatal error: new: No such file or directory
```

**해결방법:** 스크립트에 이미 적용되어 있음
```bash
make MAKEINFO=true \
    CXXFLAGS="-I$LFS/tools/x86_64-maruxos-linux-gnu/include/c++/13.2.0 \
              -I$LFS/tools/x86_64-maruxos-linux-gnu/include/c++/13.2.0/x86_64-maruxos-linux-gnu"
```

#### 6단계: Chroot 환경 준비

```bash
sudo bash scripts/lfs/04-prepare-chroot.sh
```

**이 단계에서 수행되는 작업:**
- 소유권을 root로 변경
- 가상 커널 파일시스템 준비 (`/dev`, `/proc`, `/sys`)
- 필수 디렉토리 생성
- 필수 파일 생성 (`/etc/passwd`, `/etc/group`, etc.)

---

### Phase 4-8: Chroot 환경 내부에서 실행

#### 7단계: Chroot 진입

```bash
sudo bash scripts/lfs/05-enter-chroot.sh
```

**이 스크립트는:**
1. 가상 파일시스템 마운트
2. Chroot 환경으로 진입
3. 작업 완료 후 자동으로 언마운트

**Chroot 내부에서는 다음과 같은 프롬프트가 표시됩니다:**
```
(lfs chroot) root:/#
```

#### 8단계: 추가 임시 도구 빌드 (Chroot 내부)

Chroot 내부에서 실행:
```bash
bash /sources/../scripts/lfs/06-build-additional-tools.sh
```

**빌드되는 패키지:**
1. Gettext
2. Bison
3. Perl
4. Python
5. Texinfo
6. Util-linux

**중요:** 이 단계 후에는 반드시 디버그 심볼 스트리핑이 수행됩니다.

#### 9단계: 최종 시스템 빌드 (Chroot 내부)

**⚠️ 경고: 이것은 가장 긴 단계입니다 (8-15시간)!**

Chroot 내부에서 실행:
```bash
bash /sources/../scripts/lfs/07-build-final-system.sh
```

**빌드되는 80+ 패키지 (주요 항목):**

**시스템 라이브러리:**
- Glibc (최종 버전)
- Zlib, Bzip2, Xz, Zstd
- Readline, Ncurses
- Attr, Acl, Libcap, Libxcrypt

**개발 도구:**
- **Binutils (최종)** - 링커, 어셈블러
- **GCC 13.2.0 (최종)** - 완전한 C/C++ 지원
- GMP, MPFR, MPC (수학 라이브러리)
- Autoconf, Automake, Libtool
- Make, Patch, Flex, Bison

**핵심 유틸리티:**
- Coreutils (ls, cp, mv, etc.)
- Bash (셸)
- Grep, Sed, Gawk (텍스트 처리)
- Findutils, Diffutils
- Tar, Gzip

**시스템 도구:**
- Shadow (사용자 관리)
- Util-linux (시스템 유틸리티)
- E2fsprogs (파일시스템)
- Procps-ng (프로세스 도구)
- Kbd (키보드 설정)

**네트워크 & 기타:**
- OpenSSL (암호화)
- Perl, Python (스크립팅)
- Vim (에디터)
- GRUB (부트로더)

**빌드 진행 상황 모니터링:**
```bash
# 다른 터미널에서:
tail -f /tmp/lfs-build-final/*.log
```

#### 10단계: 시스템 설정 및 부팅 (Chroot 내부)

Chroot 내부에서 실행:
```bash
bash /sources/../scripts/lfs/08-system-configuration.sh
```

**이 단계에서 수행되는 작업:**

1. **부팅 스크립트 설치** (LFS-Bootscripts)
2. **네트워크 설정**
   - 호스트명: `maruxos`
   - 네트워크 인터페이스 구성
   - DNS 설정
3. **시스템 구성 파일**
   - `/etc/fstab` (파일시스템 테이블)
   - `/etc/inittab` (초기화 설정)
   - `/etc/profile` (환경 변수)
   - `/etc/hosts` (호스트 이름)
4. **Linux 커널 빌드**
   - Kernel 6.12 LTS
   - 모듈 설치
   - `/boot/vmlinuz` 설치
5. **GRUB 부트로더 설치**
   - `/boot/grub/grub.cfg` 생성
   - GRUB을 `/dev/sda`에 설치
6. **MaruxOS 릴리스 정보**
   - `/etc/maruxos-release`
   - `/etc/os-release`
   - `/etc/lsb-release`
7. **Root 비밀번호 설정**

#### 11단계: Chroot 종료 및 재부팅

```bash
# Chroot 내부에서:
exit

# 호스트 시스템에서:
sudo umount -R /path/to/lfs
sudo reboot
```

---

## 문제 해결

### 일반적인 문제

#### 1. GCC Pass 2 libcpp 오류

**증상:**
```
fatal error: new: No such file or directory
```

**원인:** Cross-compiler가 C++ 표준 라이브러리 헤더를 찾을 수 없음

**해결:** 이미 `03-build-temp-tools.sh`에 적용됨 (CXXFLAGS 사용)

#### 2. Binutils makeinfo 오류

**증상:**
```
WARNING: 'makeinfo' is missing on your system
```

**해결:** `make MAKEINFO=true` 사용 (이미 스크립트에 적용됨)

#### 3. Ncurses iostream.h 오류

**증상:**
```
fatal error: iostream.h: No such file or directory
```

**해결:** `--without-cxx` configure 옵션 사용 (이미 적용됨)

#### 4. 디스크 공간 부족

**증상:** 빌드 중 "No space left on device"

**해결방법:**
```bash
# 사용 중인 공간 확인
df -h

# 빌드 디렉토리 정리
rm -rf ~/MaruxOS/lfs/build/temp-tools/*
rm -rf ~/MaruxOS/lfs/build/cross-tools/*
```

#### 5. 빌드 중단 후 재시작

각 스크립트는 이미 빌드된 패키지를 건너뛰도록 설계되어 있습니다:

```bash
# 예: Phase 3 재시작
bash scripts/lfs/03-build-temp-tools.sh
# → 이미 설치된 패키지는 자동으로 건너뜀
```

### 로그 파일 위치

모든 빌드 로그는 다음 위치에 저장됩니다:

```
~/MaruxOS/lfs-*.log
~/MaruxOS/build/logs/
```

### 도움 요청

문제가 해결되지 않으면:

1. **로그 확인**: 마지막 100줄 확인
   ```bash
   tail -100 ~/MaruxOS/lfs-build-*.log
   ```

2. **Discord**: `pizzamaru_`

3. **GitHub Issues**: 버그 리포트 및 기능 요청

4. **LFS 공식 문서**: https://www.linuxfromscratch.org/lfs/

---

## 예상 시간

### 하드웨어별 예상 빌드 시간

| 단계 | 2 코어 / 4GB | 4 코어 / 8GB | 8 코어 / 16GB |
|------|--------------|--------------|----------------|
| Phase 0-1 | 1시간 | 45분 | 30분 |
| Phase 2 | 4시간 | 3시간 | 2시간 |
| Phase 3 | 8시간 | 5시간 | 3시간 |
| Phase 4-6 | 3시간 | 2시간 | 1시간 |
| Phase 7 | 20시간 | 12시간 | 8시간 |
| Phase 8 | 3시간 | 2시간 | 1시간 |
| **총합** | **39시간** | **24.75시간** | **15.5시간** |

### 최적화 팁

1. **병렬 빌드 사용**
   ```bash
   export MAKEFLAGS="-j$(nproc)"
   ```

2. **ccache 사용** (재빌드 시 유용)
   ```bash
   sudo apt install ccache
   export CC="ccache gcc"
   export CXX="ccache g++"
   ```

3. **tmpfs 사용** (RAM 디스크 - 빠르지만 재부팅 시 소실)
   ```bash
   sudo mount -t tmpfs -o size=20G tmpfs ~/MaruxOS/lfs/build
   ```

---

## 다음 단계

빌드가 완료되면:

1. **사용자 계정 생성**
   ```bash
   useradd -m -G wheel,audio,video myuser
   passwd myuser
   ```

2. **데스크톱 환경 설치** (Openbox + tint2)
   - Openbox 윈도우 매니저
   - tint2 패널
   - feh 배경화면

3. **추가 소프트웨어 설치**
   ```bash
   bash scripts/install-packages.sh
   ```

4. **부팅 가능한 ISO 생성**
   ```bash
   bash scripts/create-iso.sh
   ```

---

## 참고 자료

- **Linux From Scratch**: https://www.linuxfromscratch.org/lfs/view/stable/
- **Beyond Linux From Scratch**: https://www.linuxfromscratch.org/blfs/
- **LFS 커뮤니티**: https://www.linuxquestions.org/questions/linux-from-scratch-13/

---

## 라이선스

MaruxOS는 MIT 라이선스 하에 배포됩니다.

개별 패키지는 각자의 라이선스를 따릅니다 (GPL, LGPL, BSD 등).

---

## 기여

Pull Request 환영합니다!

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

---

## 크레딧

| 역할 | 크레딧 |
|------|--------|
| **UI/UX 디자인** | **tuna27** |
| **AI 개발** | **Claude Code (Anthropic)** |
| 베이스 시스템 | Linux From Scratch |
| 커널 | kernel.org |

**감사의 말**: Sigterm Co., Ltd. (시그텀 주식회사) - Claude Code MAX 플랜 지원

---

## 연락처

- **Discord**: `pizzamaru_`
- **Email**: marudev@outlook.kr
- **Portfolio**: https://marulee.dev
- **GitHub Issues**: 버그 리포트 및 기능 요청
