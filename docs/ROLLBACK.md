# MaruxOS — Rollback Guide

**대상 독자**: 2.0.0 "Cooked" 부팅이 안정적이지 않거나 회귀가 의심될 때 1.2.1로 안전하게 돌아가야 하는 사용자/개발자.

**핵심 원칙**: 1.2.1 시리즈 자산은 **세 곳에 보존되어 있어 어느 하나라도 살아있으면 복구 가능**.

---

## 보존 위치 (Triple Safety Net)

| Layer | 위치 | 무엇 | 비고 |
|-------|------|------|------|
| **GitHub Release** | [v1.2.1](https://github.com/ProgrammingYJ/MaruxOS/releases/tag/v1.2.1) | `MaruxOS-1.2.0-67-v4.iso` (1.23GB) + SHA256 | 영구. 인터넷 있으면 항상 다운로드 가능. |
| **Local 출력 디렉토리** | `output/MaruxOS-1.2.0-67-v4.iso` | 동일 ISO (Windows side) | 빌드 호스트에 보존. `output/`는 git ignore라 push되지 않지만 로컬 디스크에 잔류. |
| **WSL 빌드 트리** | `/home/administrator/MaruxOS/build/legacy-1.x-kernel/` | 1.x의 vmlinuz-6.7.4-maruxos + `/lib/modules/6.7.4` | `build-2.0.0-cooked-vN.sh`가 첫 실행 시 자동 백업 (이미 존재하면 skip) |
| **Git main branch** | commit `cd6141d` | 1.2.1 시점 코드/문서/설정 전체 | 2026-08-27 이후 main은 2.0.0(fast-forward). 1.2.1 시점은 태그 `v1.2.1` / 커밋 `cd6141d`로 항상 복원 가능. |

---

## 시나리오별 복구 절차

### 시나리오 A — 단순히 1.2.1 부팅하고 싶음 (사용자)

가장 단순. GitHub Release에서 ISO 다운로드 후 USB/CD 부팅.

```bash
# Linux/macOS:
wget https://github.com/ProgrammingYJ/MaruxOS/releases/download/v1.2.1/MaruxOS-1.2.0-67-v4.iso
echo "<expected SHA256>" MaruxOS-1.2.0-67-v4.iso | sha256sum -c -

# Windows (PowerShell):
Invoke-WebRequest -Uri https://github.com/ProgrammingYJ/MaruxOS/releases/download/v1.2.1/MaruxOS-1.2.0-67-v4.iso -OutFile MaruxOS-1.2.1.iso
```

QEMU로 즉시 부팅 테스트:
```bash
qemu-system-x86_64 -m 4G -enable-kvm -cdrom MaruxOS-1.2.0-67-v4.iso
```

### 시나리오 B — 빌드 호스트(WSL)에서 2.0.0 빌드 산출물을 폐기하고 1.2.1 빌드 환경으로 돌아가고 싶음 (개발자)

**조건**: `legacy-1.x-kernel/` 백업이 살아있는 경우.

```bash
cd /home/administrator/MaruxOS/build

# 1. 현재 2.0.0 잔재 정리
rm -rf rootfs-lfs/lib/modules/6.18.26 2>/dev/null || true
rm -f rootfs-lfs/boot/vmlinuz-6.18.26-maruxos rootfs-lfs/boot/vmlinuz 2>/dev/null

# 2. legacy 복원
cp -a legacy-1.x-kernel/lib/modules/6.7.4 rootfs-lfs/lib/modules/
for f in legacy-1.x-kernel/boot/vmlinuz*; do
    cp -a "$f" rootfs-lfs/boot/
done
ln -sf vmlinuz-6.7.4-maruxos rootfs-lfs/boot/vmlinuz

# 3. 1.2.1 ISO 재빌드
bash /mnt/c/Users/Administrator/Desktop/MaruxOS/scripts/build-1.2.0-67-v4.sh
```

생성된 `output/MaruxOS-1.2.0-67-v4.iso`가 **1.2.1과 비트 단위로 동일한 산출물** (재빌드 결정성 한계는 있음 — squashfs 타임스탬프 등).

### 시나리오 C — Git 코드/문서를 1.2.1 시점으로 되돌리기 (개발자)

```bash
cd /mnt/c/Users/Administrator/Desktop/MaruxOS

# 옵션 1: 작업 브랜치 폐기 (가장 단순)
git checkout main
git branch -D 2.0.0-cooked-kernel    # 위험: 미커밋 변경사항 손실

# 옵션 2: 작업 브랜치 보존 + main으로 이동
git checkout main                     # 자동으로 2.0.0 변경사항 stash됨

# main이 v1.2.1 = commit cd6141d (2026-05-05)
git log --oneline -3
```

### 시나리오 D — `legacy-1.x-kernel/` 백업이 없는 상황 (재해)

WSL 청소나 디스크 사고로 `build/legacy-1.x-kernel/`이 사라진 경우.

**복구 방법**: GitHub Release v1.2.1 ISO에서 vmlinuz와 모듈 추출.

```bash
# 1. ISO 다운로드 + 마운트
mkdir -p /tmp/maruxos-restore
cd /tmp/maruxos-restore
wget https://github.com/ProgrammingYJ/MaruxOS/releases/download/v1.2.1/MaruxOS-1.2.0-67-v4.iso
sudo mount -o loop MaruxOS-1.2.0-67-v4.iso /mnt/maruxos-iso

# 2. squashfs 마운트 → 모듈 추출
sudo mkdir /mnt/maruxos-squashfs
sudo mount -o loop /mnt/maruxos-iso/live/filesystem.squashfs /mnt/maruxos-squashfs

# 3. rootfs로 복원
cp -a /mnt/maruxos-squashfs/lib/modules/6.7.4 /home/administrator/MaruxOS/build/rootfs-lfs/lib/modules/
cp /mnt/maruxos-iso/boot/vmlinuz /home/administrator/MaruxOS/build/rootfs-lfs/boot/vmlinuz-6.7.4-maruxos

# 4. cleanup
sudo umount /mnt/maruxos-squashfs /mnt/maruxos-iso
```

---

## 이 가이드가 필요해질 만한 상황 (사전 정찰)

### 2.0.0 신규 위험 영역 (정찰 결과 기반)
- **Nouveau GSP 펌웨어 변경** — Nvidia Ampere/Turing 사용자 X 시작 실패 → Safe Mode 부팅 후 nm-applet 로그 확인
- **CPU mitigations** — 구형 CPU 부팅 실패 → GRUB Safe Mode 엔트리 (`mitigations=off nomodeset`) 사용
- **베어메탈 Wi-Fi** — `brcmfmac` 등 펌웨어 누락 시 무선 안 됨 → 유선/USB 어댑터 폴백, 또는 1.2.1로 임시 롤백

### 1.x 시리즈에서 알려진 한계 (롤백해도 그대로)
- 디스크 설치 미지원 — Live Boot only
- ARM64 미지원 — 2.0.x 후속 작업
- 베어메탈 Wi-Fi 일부 칩 미지원 (펌웨어 누락)

---

## 마지막 보루

만약 위 모든 백업이 동시에 사라진 시나리오라면 (확률 ≈ 0):
- LFS 12.0 툴체인 + 12.1-era 유저랜드 + 본 저장소 `scripts/lfs/` 단계 처음부터 재실행 → genesis kernel 재빌드 가능
- 다만 6.7.4가 아니라 **현재 KERNEL_VERSION 값**(2.0.0 시점은 6.18.26)으로 빌드됨 → 비트 단위 1.2.1 복원은 불가, 새 빌드만 가능

이게 1.x → 2.0.0이 단방향인 이유. 그래서 이 ROLLBACK.md가 마무리되기 전엔 main에 2.0.0을 머지하지 말 것.
