# MaruxOS Build Status

> ⚠️ **HISTORICAL SNAPSHOT — Genesis 시기 (2025-11) 박제본**
>
> 본 문서는 MaruxOS 최초 LFS Phase 0-3 완료 시점의 스냅샷입니다 (Phase 3/8, 37.5%).
> 이후 1.0 Phoenix → 1.1/1.2.x "67" → 2.0.0 "Cooked"로 진화. 본 문서의 "마지막 업데이트: 2024-11-28"은 timestamp hallucination (실제는 **2025-11-28**).
>
> 현재 상태는 [CHANGELOG.md](CHANGELOG.md) + [Kernel-Update-Log.md](Kernel-Update-Log.md) 참조.
> 본 문서는 의도적으로 박제되어 있음 — Genesis 시점의 결정과 함정을 그대로 보존해야 발표 자료(OSS Korea 2026)의 archaeology가 됨.

---


## 🎯 현재 진행 상황

### ✅ 완료된 단계

| Phase | 상태 | 스크립트 | 완료일 | 비고 |
|-------|------|---------|--------|------|
| **Phase 0** | ✅ 완료 | `00-prepare-lfs.sh` | - | LFS 환경 준비 |
| **Phase 1** | ✅ 완료 | `01-download-sources.sh` | - | 소스 다운로드 |
| **Phase 2** | ✅ 완료 | `02-build-cross-toolchain.sh` | - | 크로스 컴파일러 |
| **Phase 3** | ✅ 완료 | `03-build-temp-tools.sh` | 2024-11-27 | 임시 도구 17개 |
| **Phase 4-6** | ✅ 완료 | 스크립트 작성 완료 | 2024-11-28 | Chroot 관련 스크립트 |
| **Phase 7-8** | ✅ 완료 | 스크립트 작성 완료 | 2024-11-28 | 최종 시스템 스크립트 |

### 📦 빌드된 주요 패키지

#### Phase 3: 임시 도구 (17개)
1. ✅ M4 1.4.19
2. ✅ Ncurses 6.4
3. ✅ Bash 5.2.21
4. ✅ Coreutils 9.4
5. ✅ Diffutils 3.10
6. ✅ File 5.45
7. ✅ Findutils 4.9.0
8. ✅ Gawk 5.3.0
9. ✅ Grep 3.11
10. ✅ Gzip 1.13
11. ✅ Make 4.4.1
12. ✅ Patch 2.7.6
13. ✅ Sed 4.9
14. ✅ Tar 1.35
15. ✅ Xz 5.4.6
16. ✅ Binutils 2.41 (Pass 2)
17. ✅ **GCC 13.2.0 (Pass 2)** ⭐

#### 해결된 주요 이슈

1. **GCC Pass 2 libcpp 컴파일 오류**
   - **문제**: C++ 헤더 `<new>` 찾을 수 없음
   - **원인**: Cross-compiler에 C++ stdlib 헤더 경로 미설정
   - **해결**: CXXFLAGS에 명시적 헤더 경로 추가
   ```bash
   CXXFLAGS="-I$LFS/tools/x86_64-maruxos-linux-gnu/include/c++/13.2.0 ..."
   ```

2. **Binutils makeinfo 오류**
   - **문제**: Documentation 빌드 실패
   - **해결**: `make MAKEINFO=true` 사용

3. **Ncurses C++ 바인딩 오류**
   - **문제**: `iostream.h` 찾을 수 없음
   - **해결**: `--without-cxx` 옵션 사용

---

## 🚀 다음 단계

### 즉시 실행 가능한 작업

#### Option A: 모든 단계 자동 실행 (권장하지 않음)

```bash
# 전체 자동 빌드 (Phase 4-8)
# 경고: 이것은 15-20시간이 걸립니다!
sudo bash scripts/build-lfs.sh
```

#### Option B: 단계별 수동 실행 (권장)

```bash
# 1. Chroot 환경 준비 (5분)
sudo bash scripts/lfs/04-prepare-chroot.sh

# 2. Chroot 진입
sudo bash scripts/lfs/05-enter-chroot.sh

# 3. Chroot 내부에서 추가 도구 빌드 (1-2시간)
bash /sources/../scripts/lfs/06-build-additional-tools.sh

# 4. Chroot 내부에서 최종 시스템 빌드 (8-15시간)
bash /sources/../scripts/lfs/07-build-final-system.sh

# 5. Chroot 내부에서 시스템 설정 (1-2시간)
bash /sources/../scripts/lfs/08-system-configuration.sh

# 6. Chroot 종료
exit

# 7. 재부팅
sudo reboot
```

---

## 📊 빌드 통계

### 시간 투자

| 항목 | 시간 |
|------|------|
| Phase 0-1 (준비 + 다운로드) | ~1시간 |
| Phase 2 (크로스 컴파일러) | ~2-3시간 |
| Phase 3 (임시 도구) | ~3-6시간 |
| **현재까지 총 시간** | **~6-10시간** |
| **남은 예상 시간** | **~10-20시간** |
| **총 예상 시간** | **~16-30시간** |

### 디스크 사용량

```bash
# 현재 사용량 확인
du -sh ~/MaruxOS/lfs
du -sh ~/MaruxOS/build

# 예상:
# - Sources: ~4GB
# - Build: ~20GB
# - Tools: ~5GB
# - Rootfs: ~5GB
# 총: ~34GB (최종 시스템까지)
```

---

## 🎯 빌드 전략 결정

### ✅ 선택한 방식: 순수 LFS (Option 1)

**특징:**
- 100% 소스코드부터 빌드
- 외부 배포판 의존성 제로
- 완전한 학습 및 커스터마이징
- 시간: 15-30시간

**이유:**
> "남자는 다른걸 빌려쓰지 않는다. 오로지 자체적인것만 만드는것이 남자의 방식이다."

### ❌ 거부한 방식: Debian 기반 (Option 2)

**특징:**
- Debootstrap 사용
- 빠른 개발 (2-3시간)
- 하지만 Debian 파생 OS가 됨

**거부 이유:**
- MaruxOS는 진정한 독립 OS를 목표로 함
- 외부 의존성을 원하지 않음

---

## 📝 주요 파일 위치

### 설정 파일
```
config/
├── marux-release.conf      # 릴리스 정보
├── lfs-config.conf         # LFS 빌드 설정
└── lfs-versions.conf       # 패키지 버전

```

### 빌드 스크립트
```
scripts/lfs/
├── 00-prepare-lfs.sh                 # ✅ Phase 0
├── 01-download-sources.sh            # ✅ Phase 1
├── 02-build-cross-toolchain.sh       # ✅ Phase 2
├── 03-build-temp-tools.sh            # ✅ Phase 3
├── 04-prepare-chroot.sh              # ✅ Phase 4
├── 05-enter-chroot.sh                # ✅ Phase 5
├── 06-build-additional-tools.sh      # ✅ Phase 6
├── 07-build-final-system.sh          # ✅ Phase 7
└── 08-system-configuration.sh        # ✅ Phase 8
```

### 빌드 출력
```
build/
├── rootfs-lfs/             # 최종 루트 파일시스템
├── kernel/                 # 커널 빌드
└── logs/                   # 빌드 로그

lfs/
├── sources/                # 다운로드된 소스 (3.8GB)
├── tools/                  # 크로스 컴파일 도구체인
└── build/                  # 임시 빌드 디렉토리
```

---

## 🔧 유용한 명령어

### 빌드 상태 확인

```bash
# Phase 3 패키지 설치 확인
ls -lh ~/MaruxOS/build/rootfs-lfs/usr/bin/ | grep -E '(gcc|bash|make)'

# GCC 버전 확인 (chroot 내부)
~/MaruxOS/build/rootfs-lfs/usr/bin/gcc --version

# 디스크 사용량
df -h ~/MaruxOS
```

### 로그 모니터링

```bash
# 실시간 빌드 로그
tail -f ~/MaruxOS/*.log

# 에러 검색
grep -i error ~/MaruxOS/*.log | tail -50

# 경고 검색
grep -i warning ~/MaruxOS/*.log | tail -50
```

### 정리 작업

```bash
# 임시 빌드 파일 삭제 (공간 확보)
rm -rf ~/MaruxOS/lfs/build/temp-tools/*
rm -rf ~/MaruxOS/lfs/build/cross-tools/*

# 로그 압축
gzip ~/MaruxOS/*.log
```

---

## 📚 문서

- **[LFS Build Guide](docs/LFS-BUILD-GUIDE.md)** - 완전한 빌드 가이드
- **[README.md](README.md)** - 프로젝트 개요
- **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** - 시스템 아키텍처

---

## 🐛 알려진 이슈

### 해결됨
- ✅ GCC Pass 2 libcpp 오류
- ✅ Binutils makeinfo 오류
- ✅ Ncurses C++ 바인딩 오류

### 진행 중
- 없음

### 미해결
- 없음

---

## 📞 지원

- **GitHub Issues**: https://github.com/marux/maruxos/issues
- **Documentation**: [docs/](docs/)
- **LFS Book**: https://www.linuxfromscratch.org/lfs/

---

## 🎉 완료 시

빌드가 완료되면:

1. ✅ Phase 3까지 완료됨
2. 📋 Phase 4-8 스크립트 준비 완료
3. 🚀 다음: Chroot 환경 진입 및 추가 도구 빌드

**다음 명령어로 계속:**
```bash
sudo bash scripts/lfs/04-prepare-chroot.sh
```

---

**마지막 업데이트**: 2024-11-28
**빌드 진행률**: Phase 3/8 완료 (약 37.5%)
**예상 남은 시간**: 10-20시간
