# MaruxOS ARM64 트랙 — 자산·값 레퍼런스 시트

> **문서 성격**: ARM64 트랙(2.0.0 "Cooked", Raspberry Pi 4B 8GB 포팅)의 **자산 경로·해시·크기·버전·명령을 한 곳에 모은 참조 시트.** 새로 발생한 사실을 기록하는 로그가 아니라, 이미 기록된 값을 verbatim으로 색인한 것.
>
> **주 소스**: [`ARM64-Update-Log.md`](../../ARM64-Update-Log.md) (전체). **보조**: [`Kernel-Update-Log.md`](../../Kernel-Update-Log.md), [`CLAUDE.md`](../../CLAUDE.md), [`config-arm64/`](../../config-arm64/), [`config/lfs-versions.conf`](../../config/lfs-versions.conf), git log.
>
> **작성 규칙 (환각 방지)**:
> - **verbatim**: SHA·크기·경로·버전은 원문/실제 파일 그대로. 지어내지 않음.
> - **(재구성)**: 요약에서 명령을 재조립한 경우 표기.
> - **(미기록)**: 소스에 정확한 값이 없는 항목은 이렇게 명시. 추정으로 채우지 않음.
> - **실측 표기**: `ls`/파일 읽기로 이 시트 작성 시점에 직접 확인한 값은 "실측"으로 표기.
> - 이 파일은 기존 로그를 덮어쓰지 않음. 신규 참조 문서.

---

## 1. 산출물 이미지 (output/)

> **⚠️ 갱신(2026-08-25, v27 실측)**: 아래 표는 v27 기준으로 재측정했다. (이전 갱신 주석 보존) **⚠️ 갱신(2026-07-30)**: 이 시트는 원래 v2(2026-07-05) 기준이었다. 부팅 해결(2026-07-08) 이후 이미지는 v6→v7.1→v8→v9→v10→v11→v12→v13→v14→v15→**v16**으로 진화했다. **현재 `output/`에 물리적으로 존재하는 이미지 = v16**(Plank dock+picom 데스크톱 완성 + 라이브픽스 4종, 사이드카 SHA 일치 실측). 직전 버전들을 동일 파일명으로 순차 덮어썼다.

| 항목 | 값 |
|------|-----|
| 파일명 | `MaruxOS-2.0.0-arm64.img.xz` (버전마다 동일 파일명 덮어씀) |
| Windows 경로 | `c:\Users\Administrator\Desktop\MaruxOS\output\MaruxOS-2.0.0-arm64.img.xz` |
| **실측 크기 (현재 디스크상 = v33)** | **377,620,436 B** (≈361M — 다이어트본), mtime 2026-08-27 03:50 (실측) |
| *(구) v30 크기* | 3,372,483,208 B |
| *(구) v29 크기* | 3,370,699,388 B, mtime 2026-08-26 22:52 |
| *(구) v28 크기* | 3,366,202,932 B, mtime 2026-08-26 02:04 |
| *(구) v27 크기* | 3,370,004,520 B, mtime 2026-08-25 09:14 |
| *(구) v16 크기* | 3,362,609,608 B, mtime 2026-07-29 16:13 |
| **v33 SHA256 (현재 디스크상, WSL·Win·사이드카 3자 일치 실측 2026-08-27)** | `fc3e038f42758b78c589b8b46029e3a927e1f2f263bac07a0226689e6beabca2` |
| *(구) v30 SHA256* | `29579682072cd1a78c15df4d775e6e1d4840a343619f8b883622a0ad24a8a535` |
| *(구) v29 SHA256* | `312e4706576254b76c0a198bf6b8fbbaba80e630979babdd5de0b6e282abe1f6` |
| *(구) v28 SHA256 — 기동 ✅, 독 아이콘 투명(함정 #36)* | `a5b1393d8e8c98f3d21965f5308652b99c49c2ba7b3fee965cb825d501d22996` |
| *(구) v27 SHA256 — QTerminal 즉사(함정 #35) 판명* | `bdf1f50e8735ce5b0df5a43f44b7c1b789269e5de799d03f84e41713b4b20190` |
| *(구) v16 SHA256* | `57daa20ad5df363245ae839918b07ff4d2101b61680e5f701626fb7a76fb8e1f` |
| **직전 계보** | v24 `aad9e022…` → v25 `f633b415…` → v26 `29d75dea…`(Qt5+QTerminal) → v27 `bdf1f50e…`(+PCManFM-Qt) → v28 `a5b1393d…`(Qt FORTIFY=2 재빌드 + 기동 게이트) → v29 `312e4706…`(독 아이콘 픽스 + .desktop 내용 게이트) → v30 `29579682…`(자동 로그인) → v31 `46293e9d…`(FeatherPad) → v32 `8fe60e87…`(툴 4종) → **v33 `fc3e038f…`**(다이어트 361M + 라이선스 동봉) |
| **v15 (직전 빌드 — picom+유리 테마, v16에 덮어써짐)** | 3,351,321,332 B / SHA `5fef190d4922a2a1d8f28ab81ab296095b6121708d719a0a156664f06f2ee4fb` (2026-07-29 00:59) |
| SHA256 사이드카 | `output/MaruxOS-2.0.0-arm64.img.xz.sha256` — ✅ **갱신됨(v30 SHA `29579682…`, 2026-08-26 `sha256sum -c` OK)**. ⚠️ 빌드 스크립트는 사이드카를 쓰지 않는다(수동 갱신 항목). *(구: v27 `bdf1f50e…`)* *(구 주석: v16 SHA `57daa20a…`)*: 현재 디스크상 이미지 v16과 일치 (실측, 2026-07-30). |
| 압축 전 이미지 레이아웃 | **8 GiB sparse (v33~; v20~v32는 27 GiB)**(v27 빌드 로그 실측, 28,991,029,248 B): p1 = FAT32 512 MB(bootable, type `c`), p2 = ext4 root 26.5 GiB (type `L`). MBR disk-id **`0x4d415258`** 고정 → PARTUUID `4d415258-02` 결정론적. *(구 기재: 7 GB raw — v20 이전)* |

**버전 이력 (전 마일스톤 — SHA verbatim/실측)**: 전부 동일 파일명으로 순차 덮어씀. 상세 표 = [`00-BUILD-REPRODUCIBILITY.md`](00-BUILD-REPRODUCIBILITY.md) §10.5.
- **v1** (1.1G, `605ec90a…`) → 첫 SD 직부팅 이미지 (2026-06-23). 펌웨어 master 계열, config.txt 한글 주석(mojibake 버그).
- **v2** (1.02GB, `eab7dc2b…`) → 부팅 디버깅 재조립 (2026-07-05). 펌웨어 RPi OS 검증본, config.txt 순수 ASCII, 시리얼 ttyAMA0 헤지. *(당시 "부팅 미해결"은 실제로는 시리얼 관측 불능이었음 — §12 참조.)*
- **v6** (2.9G, `894c75e4…`) → **🎉 무인 클린부팅 → `marux login:` + self-hosting (2026-07-08)**.
- **v7.1** (3.0G, `29a794cf…`) → 실물 HDMI 그래픽 데스크톱 + 입력(libinput) + 한글 표시 (2026-07-17/18).
- **v8** (3.1G, `a8b733de…`) → 데스크톱 x86 패리티 (feh·mc·아이콘·메뉴, 2026-07-20).
- **v9** (3.1G, `6829830f…`) → ibus-hangul XIM 한글 입력 빌드 (2026-07-22, 실기기 런타임 픽스로 검증). 동일 파일명으로 v10에 덮어써짐.
- **v10** (3.03GB, `2b73877b…`) → **out-of-box 한글**(ibus 코어 gschema+machine-id baked-in, 2026-07-23).
- **v11** (3.1G, 3,328,213,080 B, `fcb599b3…`) → gtk+-3.24.41(qemu-chroot) + **Firefox ESR 140.13.0esr 공식 aarch64 한국어**(`/opt/firefox`) + gtk3 ibus immodule(GTK3 앱 한글 입력) + alsa-lib + setxkbmap (2026-07-25).
- **v12** (3.2G, 3,332,335,020 B, `294cfade…`) → **유선 네트워크 out-of-box** — dhcpcd 10.0.6 + chrony 4.5(NTP, "1970 시계" 완치). **실기기 웹서핑 검증 ✅** (2026-07-27).
- **v13** (3.2G, 3,329,485,712 B, `3f302368…`) → HW커서 복권 + HDMI 1080p60 강제 + libinput flat 가속 (2026-07-27).
- **v14** (3.2G, 3,340,464,724 B, `7f836cde…`) → **Plank dock 소스빌드**(vala 0.56.17 부트스트랩 = 자체 valac + 11종 체인) + gschema.override/keyfile 정공픽스. **실기기 검증 ✅** (2026-07-28).
- **v15** (3.2G, 3,351,321,332 B, `5fef190d…`) → picom v11.2(xrender+vsync) + Marux 반투명 유리 테마 (2026-07-29).
- **v16** (3.2G, 3,362,609,608 B, `57daa20a…`, → 현행=**v17** `767ec40e…`(2026-08-14)) → **라이브픽스 4종**(클릭 창전환 rc.xml·wnck SN 재빌드·유리 확정값 10/95·HDMI RGB 스팸 제거) (2026-07-29, mtime 16:13). *(→ 2026-08-14 재규명: 4종 중 wnck SN 재빌드는 오진 — bamfdaemon 세그폴트 실근원 = libwnck 43.0 업스트림 버그, 43.2 버전업으로 v17에서 완결(✅ 2026-08-14 빌드·실기기 검증). 함정 #25)*

**이미지 조립 방법** (ARM64-Update-Log 핸드오프 절 기록 — 명령 요약):
`truncate -s 7G` → `sfdisk`(p1 512M type c bootable, p2 L) → `losetup -fP`(loop0) → `mkfs.vfat -F32`(p1) / `mkfs.ext4`(p2) → `lfs-rootfs-complete.tar` 전개(p2) → boot 파티션 populate(펌웨어+kernel8.img+dtb+config/cmdline) → `xz -T0`. 실행 = WSL root.

---

## 2. rootfs / 스냅샷 백업 (WSL native)

| 백업 파일 | 크기 | 내용 | 경로 |
|-----------|------|------|------|
| `lfs-rootfs-complete.tar` | **4.6 G** | 완성된 aarch64 rootfs (Stage 2 완료 스냅샷, 이미지 p2에 전개되는 원본) | `~/MaruxOS-arm64/lfs-rootfs-complete.tar` |
| `lfs-ch7-snapshot.tar` | **3.2 G** | Ch7 완료 시점 스냅샷 (가상FS·sources 제외, Ch8 장기빌드 사고 대비). 함정 #5 외과 복원 시 gcc 드라이버 추출원으로 사용됨 | `~/MaruxOS-arm64/lfs-ch7-snapshot.tar` |

`~` = `/home/administrator` (WSL Ubuntu). 두 백업 모두 WSL native ext4(`/dev/sdc`)상. Windows 측 복사 여부는 (미기록).

---

## 3. 커널 산출물

| 항목 | 값 |
|------|-----|
| 커널 버전 | **Linux 6.18.26 LTS mainline** (RPi 포크 아님) |
| baked kernelrelease | `6.18.26-maruxos` (`LOCALVERSION="-maruxos"`, `LOCALVERSION_AUTO=n`) |
| defconfig | 통합 `arch/arm64/configs/defconfig` (⚠️ `bcm2711_defconfig`은 mainline에 **없음** = 함정 #1) + Pi4 critical builtin 강제 |
| 소스 트리 | `~/MaruxOS-arm64/kernel/linux-6.18.26/` |
| `Image` (비압축 arm64) | `~/MaruxOS-arm64/kernel/linux-6.18.26/arch/arm64/boot/Image` — **50,022,912 B** (≈47.7 MB) |
| DTB | `.../arch/arm64/boot/dts/broadcom/bcm2711-rpi-4-b.dtb` — **39,650 B** |
| Pi 배치 시 파일명 | `Image` → boot 파티션에 `kernel8.img`로 배치 (magic `ARMd@`, "Linux kernel ARM64 boot executable") |
| 빌드 명령 (기록) | `make -j32 Image dtbs` (`ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu-`), 빌드 시간 ≈9분(32스레드) |
| 강제 builtin 요점 | `PCIE_BRCMSTB=y`(Pi4 USB), `BCMGENET=y`(이더넷), `DRM=y`, `OVERLAY_FS=y`, `SQUASHFS_ZSTD/XZ=y`, `NLS_UTF8=y`. `DRM_VC4`는 의존성으로 `m` 유지(강제 실패, 안 싸움) |
| 커널 소스 타르볼 | `linux-6.18.26.tar.xz`, **154,432,584 B**, SHA256 `53772f5d3776e043767c8d81a32240d1f3eb64e822a5d7a510b55ca40707b0ec` (canonical과 완전 일치 — SHA 게이트 PASS) |

**크기 주의**: 47.7 MB는 통합 defconfig가 전 arm64 SoC 드라이버를 builtin으로 박아서 큼. 부팅 무해. Broadcom-only 슬림화(→~10-15 MB)는 폴리시 패스로 보류. 실기기 부팅 디버깅의 "50MB 커널 로드 실패" 가설(B)은 **✅ 반증됨(2026-07-08)** — 펌웨어가 50MB 커널을 정상 로드해 핸드오프했고 커널은 완전 부팅(4-CPU SMP·PCIe·USB·eth0·ext4·`/sbin/init`). 진짜 원인은 죽은 시리얼 어댑터 + `console=ttyS0` 순서였다. **풀 커널 유지가 정답.**

---

## 4. 검증 펌웨어 파일 (config-arm64/firmware/) — 실측

> 출처: RPi OS Lite SD에서 추출한 **Broadcom 공식 펌웨어 (mtime 2026-06-18)**. GPU 펌웨어(start4.elf) = BIOS급, **OS 아님 = 정체성 무관**. v2 이미지가 사용하는 검증 버전.

| 파일 | 크기 (B) | mtime | 역할 |
|------|----------|-------|------|
| `start4.elf` | **2,305,632** | 2026-06-18 00:20 | GPU/부트 펌웨어 (Broadcom blob) |
| `start4x.elf` | **3,053,352** | 2026-06-18 00:20 | 확장(x) 펌웨어 |
| `fixup4.dat` | **5,499** | 2026-06-18 00:20 | start4.elf 페어 링커 |
| `fixup4x.dat` | **8,494** | 2026-06-18 00:20 | start4x.elf 페어 링커 |
| `overlays/disable-bt.dtbo` | **1,073** | 2026-06-09 13:55 | BT 비활성 → PL011(ttyAMA0)을 GPIO14/15로 (v2 시리얼) |
| `overlays/miniuart-bt.dtbo` | **1,566** | 2026-06-09 13:55 | (대안) BT를 mini-UART로 |
| `overlays/vc4-kms-v3d.dtbo` | **2,760** | 2026-06-09 13:55 | VC4 KMS/V3D 디스플레이 |

**버전 대조 (start4.elf)**:
- **v2 검증 펌웨어 = 2,305,632 B** (RPi OS SD, 위 실측값).
- **v1 master 펌웨어 = 2,306,400 B** (raspberrypi/firmware master, 다른 버전 — ARM64-Update-Log 부팅 분석 표). → v1/v2 펌웨어 교체로도 "짧2" LED 증상 안 고쳐짐(펌웨어는 범인 아님으로 확정).

**주의**:
- 로그 Stage 3(v1) 서술의 `fixup4.dat(8K)`는 v1 시점 근사 표기. **현재 디렉토리의 fixup4.dat 실측은 5,499 B** (v2 검증본). fixup4x.dat가 8,494 B(≈8K).
- `bootcode.bin`은 부팅 체인 문서엔 언급되나 **config-arm64/firmware/ 에는 미존재** (Pi 4는 EEPROM 내장이라 생략 가능).

---

## 5. config.txt / cmdline.txt (config-arm64/) — 실제 내용 verbatim

> **⚠️ 갱신(2026-07-23, 실측)**: 아래 verbatim은 **2026-07-05(v2) 스냅샷**이다. 부팅 해결 이후 `config-arm64/` 템플릿이 바뀌었다. **현재 디스크상 실측**:
> - `config-arm64/config.txt` = **3줄**: `arm_64bit=1` / `kernel=kernel8.img` / `enable_uart=1` (`dtoverlay=disable-bt`·`disable_overscan=1` 제거됨).
> - `config-arm64/cmdline.txt` = `console=ttyS0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 rootwait fsck.repair=yes net.ifnames=0` (**`ttyAMA0` 제거** — 부팅 해결이 mini-UART `ttyS0` 경로로 확정됐기 때문. HDMI/시리얼 콘솔 라우팅은 부팅 디버깅에서 `console=` 순서로 해결).
> - HDMI용 `max_framebuffers=2`는 실제 부팅 SD의 config.txt에서 적용됨(Stage 5a); 이 템플릿 파일 반영 여부는 config-arm64 소유 트랙 관할.
>
> 아래 원문(v2 verbatim)은 역사 보존.

**`config-arm64/config.txt`** (85 B 실측, 순수 ASCII, BOM 없음 — v1의 한글 주석 mojibake 버그 수정본):
```
arm_64bit=1
kernel=kernel8.img
enable_uart=1
dtoverlay=disable-bt
disable_overscan=1
```

**`config-arm64/cmdline.txt`** (132 B 실측, 1줄):
```
console=ttyAMA0,115200 console=ttyS0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 rootwait fsck.repair=yes net.ifnames=0
```

**v1 → v2 차이 (기록)**: v1 config.txt는 `gpu_mem=128` 포함 + 한글 주석(mojibake로 Pi 파서 위험). v1 cmdline은 `console=ttyS0`(mini-UART) 중심. v2에서 PL011(ttyAMA0) 우선 + ttyS0/tty1 헤지, ASCII 정화, gpu_mem 제거, `dtoverlay=disable-bt` 추가.

---

## 6. inittab 시리얼 설정

| 항목 | 값 |
|------|-----|
| 콘솔 getty | `tty1`~`tty6` (가상 콘솔) + **`ttyS0`**(mini-UART) + **`ttyAMA0`**(PL011, v2에서 이미지 조립 시 sed로 추가) |
| 목적 | TTL-USB 시리얼 디버그 콘솔 (GPIO14/15, 115200) |
| baud | 115200 |
| 시리얼 어댑터 | FT232RL, COM9, 배선 GND→핀6 / TX→핀8 / RX→핀10 / 3.3V, VCC(빨강) 미연결 |
| init 시스템 | **sysvinit 3.08** (systemd 아님) + eudev(udevd 251) + lfs-bootscripts |

**exact agetty/respawn 라인 문구는 (미기록)** — 로그는 "ttyS0 + ttyAMA0 getty 둘 다", "이미지 조립 시 sed로 추가"라고만 서술. 정확한 inittab 엔트리 문자열(`S0:2345:respawn:...` 형태)은 소스에 verbatim으로 남아있지 않음(rootfs 내부 파일, 이 시트 작성 범위 밖).

---

## 7. 툴체인 / 쉬핑 버전 (ground truth = 설치된 바이너리)

> 함정 #3: x86_64 소스 dir의 glibc-2.39/binutils-2.42는 **빌드 안 된 staging 미끼**. 설치된 `libc.so.6`(=2.38)이 진실. arm64도 아래 베이스라인으로 매치. SSOT = `config/lfs-versions.conf`.

| 구성요소 | 버전 | 출처 |
|----------|------|------|
| Linux 커널 | **6.18.26** (kernelrelease `6.18.26-maruxos`) | lfs-versions.conf `KERNEL_VERSION` |
| glibc | **2.38** | lfs-versions.conf `GLIBC_VERSION`, 설치 `libc.so.6` 확인 |
| binutils | **2.41** | lfs-versions.conf `BINUTILS_VERSION`, 설치 `ld` 확인 |
| gcc | **13.2.0** | lfs-versions.conf `GCC_VERSION`, 설치 `gcc --version` |
| gmp / mpfr / mpc | 6.3.0 / 4.2.1 / 1.3.1 | lfs-versions.conf |
| 스캐폴드 cross gcc | Ubuntu **13.3.0** (`aarch64-linux-gnu-gcc`, apt) | 발판 전용, 쉬핑 아님 |
| qemu | `qemu-aarch64-static` + `qemu-system-aarch64` **8.2.2** | Stage 0 |
| bash | 5.2.21 | lfs-versions.conf / 스모크 |
| Python | 3.12.2 | Ch8 스모크 |
| perl / util-linux / bison / texinfo / gettext | 5.38.2 / 2.39.3 / 3.8.2 / 7.1 / 0.22.4 | Ch7·Ch8 (12.1-era 유저랜드) |
| init / udev | sysvinit 3.08 / eudev(udevd 251) | Ch8-6 |
| 로케일 / TZ | `ko_KR.utf8` (+ `C.UTF-8`) / `Asia/Seoul` (KST) | Ch8-1 |
| pip 부트스트랩 | 24.0 | Ch8-5 |

**라벨 정합성 (해소됨)**: 과거 라이브 문서들이 "LFS 12.1 기반"으로 표기했으나 실제 툴체인(glibc 2.38/binutils 2.41)은 **LFS 12.0-era** → **2026-07-08 "LFS 12.0 툴체인 + 12.1-era 유저랜드"로 정정 완료** (CLAUDE.md/FAQ/CONTRIBUTING/docs 전부 반영). 함정 #3 참조.

**데스크톱/네트워크 스택 추가분 (v11~v16, qemu-chroot 소스 빌드)**: gtk+ **3.24.41** · **vala 0.56.17**(부트스트랩 — **MaruxOS 자체 valac 보유**) · plank **0.11.89** · picom **v11.2** · libwnck 43.0(v16에서 startup-notification 포함 재빌드 — *2026-08-14 재규명: 43.0 자체가 업스트림 버그[함정 #25]로 bamfdaemon 세그폴트. $LFS는 **43.2**로 재빌드 완료 → **v17(✅ 2026-08-14 완성·실기기 검증) 탑재**; v16 이미지는 43.0인 채*) · bamf 0.5.6 · dhcpcd **10.0.6** · chrony **4.5** · GSettings = **keyfile 백엔드**(gschema.override + `GSETTINGS_BACKEND=keyfile`). 예외: Firefox ESR **140.13.0esr**은 공식 aarch64 한국어 **바이너리 빌드**(`/opt/firefox`) — 소스빌드 원칙의 유일한 의도적 예외.

### 7-1. 코어 툴체인 소스 SHA256 매니페스트 (Stage 2b 게이트 expected 값)

| 패키지 | 크기 | SHA256 |
|--------|------|--------|
| binutils-2.41.tar.xz | 26M | `ae9a5789e23459e59606e6714723f2d3ffc31c03174191ef0d015bdf06007450` |
| gcc-13.2.0.tar.xz | 84M | `e275e76442a6067341a27f04c5c6b83d8613144004c0413528863dc6b5c743da` |
| gmp-6.3.0.tar.xz | 2.0M | `a3c2b80201b89e68616f4ad30bc66aee4927c3ce50e33929ca819d5c43538898` |
| mpfr-4.2.1.tar.xz | 1.5M | `277807353a6726978996945af13e52829e3abd7a9a5b7fb2793894e18f1fcbb2` |
| mpc-1.3.1.tar.gz | 756K | `ab642492f5cf882b74aa0cb730cd410a81edcdbec895183ce930e706c1c759b8` |
| glibc-2.38.tar.xz | 19M | `fb82998998b2b29965467bc1b69d152e9c307d2cf301c9eafb4555b770ef3fd2` |

---

## 8. WSL 빌드 경로

| 변수 / 항목 | 값 |
|-------------|-----|
| 빌드 호스트 | x86_64 WSL2 (Ubuntu 24.04), 유저 `administrator`, HOME `/home/administrator` (ext4 `/dev/sdc`) |
| **빌드 루트** | `/home/administrator/MaruxOS-arm64/` ⭐ (x86_64 `/home/administrator/MaruxOS/build/` 와 **완전 분리**) |
| 하위 디렉토리 | `toolchain/`, `kernel/`, `firmware/`, `rootfs-clfs-arm64/`, `iso-build/`, `output/` |
| **`$LFS`** | `/home/administrator/MaruxOS-arm64/rootfs-clfs-arm64` |
| **`$LFS_TGT`** | `aarch64-lfs-linux-gnu` |
| `--build` (host triplet) | `x86_64-pc-linux-gnu` (고정, config.guess 편차 회피) |
| glibc 슬립디렉토리 강제 | `libc_cv_slibdir=/usr/lib` (lib64 회피, 함정 #4) |
| aarch64 osdir sed (함정 #4) | `sed -e '/mabi.lp64=/s/lib64/lib/' -i.orig gcc/config/aarch64/t-aarch64-linux` — gcc pass1/pass2/final **매번 필수** |
| resumable 마커 | `$LFS/sources/.done/<pkg>` (실패 시 해당 패키지부터 재개) |
| chroot 진입 | `qemu-aarch64-static` binfmt(F 플래그) + dev/pts/proc/sys/run bind 마운트 |
| 소스 스테이징 | `$LFS/sources` = 186 타르볼 + 7 패치 (x86_64에서 복사, staging binutils-2.42/glibc-2.39 **제외**) |

---

## 9. 호스트 변경 (Windows powercfg) — 가역, 사용자 검토 대기

> 함정 #5(WSL 슬립이 binfmt를 죽여 긴 chroot 빌드 연쇄장애)의 근본 완화. 빌드 마라톤 생존용 가역 조치.

**적용 명령** (로그 기록 그대로 — 일부 축약 표기):

| 목적 | 적용 명령 | 복구 명령 |
|------|-----------|-----------|
| AC 유휴 슬립 끔 | `powercfg /change standby-timeout-ac 0` | `powercfg /change standby-timeout-ac 30` |
| AC 최대절전 끔 | `powercfg /change hibernate-timeout-ac 0` | (미기록 — 복구 명시 없음. 대칭이라면 `hibernate-timeout-ac <원래값>`) |
| lid-close 슬립 끔 | `powercfg SUB_BUTTONS LIDACTION 0` *(로그 축약 표기)* | `LIDACTION 1` *(로그 축약 표기)* |

**주의**: `SUB_BUTTONS LIDACTION 0` / `LIDACTION 1`은 로그에 축약형으로만 기록됨. 완전한 powercfg 구문(`/setacvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION 0` + `/setactive SCHEME_CURRENT`)은 **(미기록)** — 로그 문구를 verbatim 인용하되 완전 재구성은 하지 않음. 전원 AC 연결 상태에서 적용됨.

---

## 10. 브랜치 / 디렉토리 분리 규칙 (Hallucination 격리)

| 축 | ARM64 트랙 | x86_64 트랙 |
|----|-----------|-------------|
| 브랜치 | `2.0.0-cooked-arm64` (parent `2.0.0-cooked-kernel`) | `2.0.0-cooked-kernel` |
| WSL 빌드 디렉토리 | `/home/$USER/MaruxOS-arm64/` ⭐ | `/home/$USER/MaruxOS/build/` — **건드림 ❌** |
| 빌드 스크립트 | `scripts/build-2.0.0-cooked-arm64-vN.sh` | `scripts/build-2.0.0-cooked-vN.sh` |
| 산출물 | `MaruxOS-2.0.0-arm64.img.xz` (hybrid disk image) | `MaruxOS-2.0.0-x86_64.iso` (`MaruxOS-2.0.0-cooked-vN.iso`) |
| 전용 config | `config-arm64/` (Pi boot용) | `config/` |
| 작업 로그 | `ARM64-Update-Log.md` | `Kernel-Update-Log.md` (Section 1~29) |
| 부트로더 | start4.elf 직접 kernel8.img (U-Boot/GRUB 없음) | GRUB2 |
| Windows 프로젝트 루트 (공통) | `c:\Users\Administrator\Desktop\MaruxOS\` | 동일 |

**빌드 스크립트 의무 게이트 4종** (모든 `build-*-arm64-*.sh` 헤더): ① 빌드 루트 PWD == `$EXPECTED_BUILD_ROOT`(`/home/$USER/MaruxOS-arm64`) 확인 + `/MaruxOS/build` 아님 확인 ② `${CC}-dumpmachine`에 `aarch64` 강제 ③ `OUTPUT_NAME`에 `arm64` 강제 ④ `ARCH==arm64` 강제.

**git 상태 주의(실측)**: ARM64 트랙 자산(`ARM64-Update-Log.md`, `config-arm64/`, `output/*arm64*`, `scripts/build-2.0.0-cooked-v*.sh` 등)은 현재 **커밋되지 않은 working tree 상태** (`git status` untracked/modified). 브랜치 HEAD는 `4be4520` (2.0.0 Phase B 메타데이터). ARM64 전용 커밋은 아직 없음.

---

## 11. 격리 테스트 자산 (config-arm64/isolation-test/) — 실측 · ⏭️ 미실행(불요)

> ⏭️ **미실행**: 이 격리 테스트는 "범인 = 우리 이미지(커널 vs FAT)"라는 전제였는데 그 전제가 틀렸다. 실제 원인은 죽은 시리얼 어댑터 + `console=ttyS0` 순서였고, 시리얼 부활로 곧장 부팅에 도달(2026-07-08)해 **실행 전 무의미해짐**. 자산은 디스크에 그대로 남아 있음(방법론 예시).

| 파일 | 크기 (B) | mtime |
|------|----------|-------|
| `kernel8.img` | **50,022,912** | 2026-07-05 12:29 (실측) |
| `bcm2711-rpi-4-b.dtb` | **39,650** | 2026-07-05 12:29 (실측) |

두 파일 모두 커널 산출물(§3)의 복사본 — 크기 일치 확인됨.

---

## 12. 부팅 상태 요약 — ✅ RESOLVED (2026-07-08, 재확인 2026-07-23)

> **아래 표의 "범인 = 우리 이미지" 프레이밍은 2026-07-05 오진이었다.** 확정 사실 자체(RPi OS 부팅·부트 파일 무결·펌웨어 무죄)는 다 옳았으나, 놓친 변수 = **관측 계측기(시리얼 어댑터)의 사망**. 실제 결말:

| 항목 | 상태 (2026-08-25 갱신) |
|-----------|------|
| aarch64 rootfs + 이미지 조립 | ✅ 완료 |
| 실기기 부팅 | ✅ **무인 클린부팅(FAIL 0) → `marux login:` (v6, 2026-07-08)** + 실물 gcc self-hosting 증명 |
| 진짜 원인 | ① 죽은 FT232RL 시리얼 어댑터(관측 불능) + 흰↔초 배선 → 교체·스왑 ② cmdline `console=ttyS0,115200` 맨 뒤 → `/dev/console`=시리얼 ③ rootfs 설정 4종(udevadm 심링크/fstab shm·cgroup/S70console/S10sysklogd) |
| 옛 가설 (A) FAT 구조 / (B) 50MB 커널 | ❌ **둘 다 반증** — 펌웨어가 FAT 읽고 50MB 커널로 핸드오프, 커널 완전 부팅 |
| "짧2 LED" | 부팅 실패 아님(오독). 커널은 처음부터 완전 부팅 중이었음 |
| HDMI | ✅ VC4/V3D `=y` + `max_framebuffers=2` → 1080p 콘솔(Stage 5a) → X.org/데스크톱(v7.1) → v13 HDMI 1080p60 강제(TV 호환) + HW커서 |
| 그래픽 데스크톱 / 한글 입력 | ✅ v8 x86 패리티 → v10 out-of-box 한글(XIM, Shift+Space) → **v11 GTK3 앱/Firefox 한글 입력(gtk3 immodule) + Firefox ESR 한국어 빌드** |
| 네트워크 / 시계 | ✅ **v12 유선 out-of-box**(dhcpcd 10.0.6 DHCP + chrony 4.5 NTP — "1970 시계" 완치, 실기기 웹서핑 검증). WiFi = 다음 배치(커널 재빌드 + 퀵설정 GUI) |
| Plank dock / 컴포지터 | ✅ **v14 소스빌드**(자체 valac 부트스트랩, gschema.override+keyfile 정공픽스) 실기기 검증 → v15 picom v11.2 + Marux 유리 테마 → **v16 라이브픽스 4종 (현재 이미지, SHA `57daa20a…`)**. *단 v16 실기기(2026-08-14): 독 실행 점/실행 앱 클릭 창전환은 여전히 ❌(bamfdaemon 세그폴트 — 실근원 = libwnck 43.0 업스트림 버그, 함정 #25) → 43.2 버전업으로 무플래시 실기기 검증 완료, **v17(✅ 2026-08-14 완성) 탑재 예정*** |
| WiFi 무선 | ✅ **v18~v24 정복, 실기기 검증**(유선 뽑고 DHCP·인터넷) — 진범은 brcmfmac **FWSUP**(함정 #31), host 4-way 강제로 해결 |
| 퀵설정 GUI / 상태 바 | ✅ **자체 제작 `marux-quicksettings`**(vala/GTK3) — v22에서 tint2 은퇴, 한/A·WiFi·볼륨·시계 통합. 실기기 검증(v24) |
| 한/영 상태 표시 | ✅ **v23~v24** — ibus-hangul 엔진 소스 상태 export 패치(정공 우회). 실기기 검증 |
| 부팅 안정성 | ✅ **v20** — cmdline `root=PARTUUID` + fstab `LABEL`(계층별 해법). mmc 번호 시프트(함정 #29) 면역 |
| 터미널 | ✅ **v26 QTerminal 0.17.0**(Qt5 호스트 크로스 빌드) — ⏳ 실기기 검증 대기 |
| 파일 매니저 | ✅ **v27 PCManFM-Qt 0.17.0** — ⏳ 실기기 검증 대기. 1.x GTK판 사고를 Qt 경로로 정공 해소 |
| ⚠️ 검증 대기 (v25~v27) | 독 유령창 소멸 · 경고 다이얼로그 가시성 · QTerminal 기동/한글 · PCManFM-Qt 기동/한글 파일명 |
| 🐛 미해결 (2026-08-14, 사용자 판정) | 독 인디케이터 점 **위치가 테마 BottomPadding으로 안 움직임**(2.5→4→6 라이브 실험 시각 변화 없음) — 가설 2개 미검증: (a) plank 테마 핫리로드가 패딩/레이아웃 미적용(→ plank 재시작 후 재판정이 1차 확인) (b) 인디케이터 y가 DockRenderer에 하드앵커(→ plank 소스 패치 필요). + 점 크기 증대(IndicatorSize 4.5→7 후보)도 함께 보류 중 |

---

## 13. 배치 W / Q / F 자산 (2026-08-14~25 추가) — 실측 크기

> 배치 W = WiFi + 퀵설정 GUI(v18~v25) · 배치 Q = Qt5 + QTerminal(v26) · 배치 F = PCManFM-Qt(v27).
> 아래 크기는 Windows 프로젝트 루트 기준 `ls -l` 실측(2026-08-25).

| 자산 | 경로 (프로젝트 루트 기준) | 크기 (B) | 역할 |
|------|--------------------------|---------|------|
| WiFi 커널 재빌드 | `scripts/rebuild-kernel-wifi-arm64.sh` | 9,794 | wireless 7종 `=y` + `RESET_GPIO=y`(함정 #28) + brcmfmac FWSUP 비활성 패치(함정 #31) + `CONFIG_EXTRA_FIRMWARE` 임베드 |
| WiFi 유저스페이스 | `scripts/install-wifi-arm64.sh` | 10,977 | wpa_supplicant 2.11(`CONFIG_DRIVER_NL80211_BRCM`, 4-way offload 차단) + alsa-utils 1.2.10 + `/etc/asound.conf` softvol |
| 퀵설정 GUI 소스 | `src/marux-quicksettings/marux-quicksettings.vala` | 30,053 | vala/GTK3 자체 제작. 우상단 통합 상태 바(한/A·WiFi·볼륨·시계) + 드롭다운. cairo 직접 페인팅, override-redirect 창 |
| Qt5 크로스 빌드 | `scripts/install-qt5-arm64.sh` | 21,125 | Qt5 5.15.2 12종 + xcb 플러그인 + lxqt-build-tools + qtermwidget + QTerminal 0.17.0 |
| PCManFM-Qt 크로스 빌드 | `scripts/install-pcmanfm-qt-arm64.sh` | 6,253 | libexif 0.6.24 → libfm 1.3.2(`--with-extra-only`) → menu-cache 1.1.0 → libfm-qt → pcmanfm-qt 0.17.0 |
| CMake 크로스 툴체인 | `$B/qt-cross-toolchain.cmake` (WSL, rootfs 밖) | — | `FIND_ROOT_PATH_MODE` 분리. 배치 Q에서 만들어 배치 F가 그대로 재사용 |
| config 세대 | `scripts/setup-desktop-config-arm64-v10.sh` / `-v11.sh` / `-v12.sh` / `-v13.sh` | 13,023 / 13,782 / 14,105 / — | v10 = tint2 은퇴+통합 바 · v11 = xterm→qterminal · v12 = mc→pcmanfm-qt · **v13 = tty1 자동 로그인 + startx 프로필** |
| **Qt FORTIFY 재빌드** | `scripts/rebuild-qt-fortify-arm64.sh` | — | 함정 #35 픽스: mkspec/CMake 툴체인/CFLAGS 3경로 `-D_FORTIFY_SOURCE=2` + 단계별 플래그 grep + `--gate-only` |
| **Qt 기동 게이트** | `scripts/gate-qt-launch-arm64.sh` | — | "존재≠기동": qemu chroot + Xvfb(xcb) 실제 실행 12초 생존 + pcmanfm-qt SIGTERM 종료 경로. 재빌드·install 모듈·build v28에서 호출 |
| 빌드 스크립트 | `scripts/build-2.0.0-cooked-arm64-v24~v33.sh` | 18,888 / 18,671 / 20,145 / 20,968 | v24 = 배치 W 확정 · v25 = 유령창/경고창 · v26 = Qt5+QTerminal · v27 = +PCManFM-Qt |

**빌드 산출물 배치 원칙**: Qt/fm 소스·빌드 트리는 **rootfs 밖**(`$B/qt-src`, `$B/fm-src`)에 두고 **설치만** `$LFS/usr`로. 완료 마커 = `$B/.q-*`(Qt), `$B/.f-*`(fm).

**커널 SHA (FWSUP 패치본, 배치 W 이후 전 이미지 공통)**: `13bd3415cad00b66ae75b756ddf19591f8c25fbc011992476ef023201c48c10c`

---

### 출처 각주
- 이미지/rootfs/커널/펌웨어/config/inittab/호스트변경 값: `ARM64-Update-Log.md` (전체, 특히 "핸드오프" 및 "Stage 2 완료"·"Stage 3+4a" 절)
- 툴체인 SSOT: `config/lfs-versions.conf`
- 함정 #1 교차 기록: `Kernel-Update-Log.md` §1, §29
- 디렉토리/게이트/분리 규칙: `CLAUDE.md` "ARM64 트랙" 섹션
- 실측(파일 크기·SHA 사이드카·config 내용·git 상태): 이 시트 작성 시점 직접 확인
