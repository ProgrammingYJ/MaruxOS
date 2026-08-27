# MaruxOS ARM64 — Stage 4b 실기기 부팅 디버깅 기록 (Raspberry Pi 4B)

> # ✅ RESOLVED (2026-07-08, 재확인 2026-07-23)
>
> **이 문서의 본문은 "미해결" 스냅샷(2026-07-05)이다. 실물 Pi 4B 부팅은 2026-07-08에 해결됐다. 아래는 실제 결말 — 본문의 디버깅 서사는 방법론 기록으로 보존한다.**
>
> **부팅은 애초에 실패한 적이 없었다 — 관측이 불능이었을 뿐이다.** 실제 원인 3종:
> 1. **죽어가던 FT232RL 시리얼 어댑터** → v1~v4 전부 "장님 디버깅"(LED만 보고 추측)이었다. 새 FT232RL + **흰↔초록 배선 스왑**(핀8=초록=어댑터TX, 핀10=흰=어댑터RX) + `enable_uart=1`로 시리얼 부활 → RPi OS가 `raspberrypi login:`까지 완전 부팅, 30,378바이트 캡처로 파이프라인 100% 검증.
> 2. **`console=ttyS0,115200`를 cmdline 맨 뒤로** 이동 → `/dev/console`이 시리얼(mini-UART)에 물림. 그전엔 유저스페이스가 **안 보이는 tty1 더미 콘솔**로 새고 있어서 init/rc 출력이 시리얼에 안 떴다.
> 3. **경미한 rootfs 설정 4종**(`/bin/udevadm` 심링크 누락 / fstab `/dev/shm`+`/sys/fs/cgroup` 누락 / S70console `setfont` / S10sysklogd)이 rc마다 "Press Enter" 정지 유발 → v6에서 픽스 → **무인 클린부팅(FAIL 0) → `marux login:`** + 실물 Pi에서 gcc self-hosting 컴파일 증명.
>
> **본문의 두 가설은 둘 다 틀렸다**: **(A) FAT 파티션 구조 ❌** — 펌웨어는 우리 FAT 부트 파티션을 완벽히 읽었다. **(B) 50MB 커널 로드 실패 ❌** — 50MB 커널은 정상 로드·완전 부팅됐다(4-CPU SMP·PCIe·USB·eth0·ext4 마운트·`/sbin/init` 실행 확인). **"짧2 LED"는 부팅 실패가 아니었다.** §7의 격리 테스트는 전제 오류(범인=이미지)로 실행 전 무의미해졌다.
>
> **HDMI 블랙아웃**도 부팅 실패가 아니라 최소 config에 디스플레이 드라이버 부재(dummy console)였을 뿐 → 커널 **VC4/V3D `=y`** + config.txt `max_framebuffers=2`(mainline dtb라 dtoverlay 불요)로 실물 1080p 콘솔 부활(Stage 5a). 이후 X.org+데스크톱(v7.1) → x86 패리티(v8) → **ibus-hangul 한글 입력(v10, 2026-07-23)** → GTK3/Firefox 한국어(v11) → 유선 네트워크+실기기 웹서핑(v12) → **Plank dock+picom 유리 데스크톱(v14~v16, 2026-07-29)** 까지 완성. 현황 = [`03-ASSET-REFERENCE.md`](03-ASSET-REFERENCE.md).
>
> ---
>
> **(아래는 2026-07-05 당시 원문 — 역사적 디버깅 방법론 보존. "미해결"은 그 시점 기준.)**
>
> **상태: 미해결 · 진행 중.** aarch64 rootfs·부팅 이미지는 완성됐으나, 실기기 Pi 4B 부팅만 안 됨.
> 초록 LED **짧은 깜빡 2번 반복(짧2)** = 펌웨어가 우리 SD 부트를 못 읽음. **하드웨어·SD는 정상**(공식 RPi OS는 같은 SD/Pi에서 부팅됨), **우리 이미지가 문제.** 범인을 **커널(50MB) vs FAT 구조** 둘로 좁혔고, 격리 테스트 직전 단계.

---

## 문서 규약 (환각 방지)

이 프로젝트는 환각을 극도로 경계한다(1.x의 "6.12 광고 → 6.7.4 실체" 5개월 생존 전과). 본 문서는 다음 규칙을 지킨다.

- **원문에 실제로 있는 값만 기록.** 버전·명령·크기·SHA·경로는 소스 원문 그대로(verbatim).
- **소스에 명령이 없고 요약에서 재구성한 것은 `(재구성)` 표기.** 소스에 기록되지 않은 것은 `미기록`이라 명시.
- 본 문서는 새 파일이며 기존 로그를 대체하지 않는다.

**1차 소스**: [`ARM64-Update-Log.md`](../../ARM64-Update-Log.md) (특히 "Stage 3+4a 완료" 절, "2026-07-02 Stage 4b 실기기 부팅 디버깅" 절, "🚨 다음 세션 핸드오프 — Stage 4b 부팅 디버깅 (2026-07-05)" 절).
**보조 소스**: `Kernel-Update-Log.md`(ARM64 boot 디버깅 항목 없음 — §29 genesis 참조만), `CLAUDE.md`, `config-arm64/`(config.txt·cmdline.txt·firmware/·isolation-test/), `config/lfs-versions.conf`, git log.
**리포지토리 실측**: 본 문서 작성 시 `config-arm64/` 하위 파일 크기를 디스크에서 직접 확인한 값은 "(실측)"으로 병기.

---

## 0. 부팅 체인 (참조 — 절대 건드리지 말 것)

Pi 4B는 U-Boot/GRUB 단계가 **없다**. EEPROM이 GPU 펌웨어를 직접 로드한다.

```
EEPROM → start4.elf → config.txt → kernel8.img + dtb → 커널 → sysvinit → `marux login:` (root/root)
```

- **start4.elf 는 GPU 펌웨어(=BIOS급, OS 아님)**. 이게 로드되면 화면에 무지개(레인보우) 테스트 패턴이 잠깐 뜬다. 무지개 = "start4.elf까지는 살아있다"의 신호.
- 그 다음 단계(kernel8.img + config.txt 읽기)가 실패하면 커널로 넘어가지 못하고 LED 에러 코드를 깜빡인다.

---

## 1. 증상 타임라인

| 단계 | 화면 | LED | 시리얼 | 해석 |
|------|------|-----|--------|------|
| ① 첫 부팅 | **무지개 정지**(멈춤) | — | 무출력 | start4.elf 로드됨, 그 뒤 진행 안 됨 |
| ② 재삽입 후 (v1) | **무지개 0.1초 → 블랙** | **초록 깜빡** (2026-07-02 로그: "긴2 깜빡") | 무출력 | start4.elf 로드 → 부트 파일 읽기 실패 |
| ③ v2 이미지 | 동일 (무지개 0.1초 → 블랙) | **동일 (짧2)** | 무출력(▒▒ 깨짐) | 펌웨어 교체·config ASCII화·시리얼 변경에도 **증상 불변** |

> **⚠️ LED 기술 표기 내부 변화(정직 기록)**: 2026-07-02 로그 원문은 "초록 LED **긴2 깜빡**"·"긴2 계열"로 적었고, 2026-07-05 핸드오프 원문은 "초록 LED **짧은 깜빡 2번 반복**(짧2)"으로 적음. **최신·확정 표기는 짧2**("공식 표 + 사용자 확인", 원문 표현). 초기 긴2 표기는 재판독 전 기록으로 남긴다.

핵심: **v1 → v2로 펌웨어·시리얼·config를 바꿨는데도 증상이 그대로**라는 점이, 아래 "펌웨어 무관" 확정과 "범인은 커널 or FAT" 가설 축소의 근거.

---

## 2. Pi 4B 초록 LED 에러 코드 (공식 표 기반)

- **판독 출처**: WebSearch로 공식 표 확인(원문: "기억으로 안 박음"). 사용자 실기기 관찰과 교차 확인.
- **코드 구조**: **긴 깜빡 N번 + 짧은 깜빡 M번** (`긴N + 짧M`).
- **우리 케이스 = 짧2** → **부트 파티션 / 부트 파일을 못 찾음**. 원문 표현: *"SD 구조가 꼬여서 부팅파일 위치 못 찾겠다 = 완전 거부."*
- **추정 위치**: start4.elf는 로드됨(무지개 0.1초) → 그 **다음 단계인 kernel8.img/config.txt 읽기에서 실패**로 추정.

> **미기록 주의**: 소스 로그에는 위 두 값(구조 `긴N+짧M`, 짧2=부트파티션/파일 못읽음)만 기록돼 있다. Pi 부팅 에러의 **전체 공식 수치 매핑표**(각 N/M 조합별 의미)는 원문에 옮겨져 있지 않음 → `미기록`. 지어내지 않는다.

---

## 3. 확정된 사실 (재검증 완료 — 추측 아님)

원문 "✅ 확정된 사실" 절(2026-07-05) 기준.

1. **하드웨어·SD 정상.** 공식 **Raspberry Pi OS Lite**를 **같은 SD·같은 Pi**에 구워 부팅 → **정상 부팅됨.** → SD카드·리더·Pi 하드웨어·EEPROM 전부 정상. **범인은 우리 이미지로 확정.**
2. **우리 부트 파일 PC 검증 완벽.** PowerShell로 부트 파티션(F:) 검증 → 6개 파일 전부 정확한 크기, FAT32 읽힘, 파티션 레이아웃 OK. "잘못 구운 것" 아님. 검증 파일:
   - `start4.elf`, `fixup4.dat`, `kernel8.img`(**50022912**), `bcm2711-rpi-4-b.dtb`(**39650**), `config.txt`, `cmdline.txt`.
3. **파티션 레이아웃 정상.** p1 = 512MB FAT32(부트), p2 = 6.5GB ext4(root). (Windows가 ext4를 못 읽어 부트 파티션 510MB만 보이는 것은 정상 동작.)
4. **커널·dtb 산출물 유효 (파일 안 깨짐).**
   - `kernel8.img` = 유효한 arm64 Image. magic **`ARMd@`**, offset 56, `"Linux kernel ARM64 boot executable"`.
   - `bcm2711-rpi-4-b.dtb` = 유효한 FDT. magic **`d00dfeed`**.
5. **펌웨어는 범인 아님.**
   - v1: master 펌웨어 `start4.elf` = **2306400** → 짧2.
   - v2: RPi OS 검증 펌웨어 `start4.elf` = **2305632** → **똑같이 짧2**.
   - → 펌웨어 교체로 안 고쳐짐 = **펌웨어 무관.**
6. **LED 짧2 의미** = 펌웨어가 부트 파티션/파일을 못 찾음(§2). start4.elf 로드는 성공(무지개 0.1초), 그 다음 읽기에서 실패 추정.

---

## 4. config.txt 한글 mojibake 버그 → ASCII 수정 (해결됨)

- **증상**: v1 `config.txt`에 **한글 주석**이 들어가 mojibake(깨진 문자)로 저장됨.
- **위험**: Pi 부트로더의 원시(raw) config 파서는 비ASCII에 취약 → 파서가 죽을 수 있음. *"비ASCII가 Pi 부트로더 죽인다"* 함정.
- **조치**: `config.txt`를 **순수 ASCII로 교체**, **BOM 없음 확인**. (v2에서 `hdmi_safe`도 제거.)
- **주의**: 이 버그는 수정됐으나, **짧2 증상은 그대로**였다 → mojibake 단독으로는 부팅 실패의 유일 원인 아님(펌웨어 무관 결과와 함께 범인 후보에서 제외됨). 재발 방지 목적의 확정 수정으로 유지.

### 현재 리포지토리의 v2 config.txt (실측, 순수 ASCII)

```
arm_64bit=1
kernel=kernel8.img
enable_uart=1
dtoverlay=disable-bt
disable_overscan=1
```

### 현재 리포지토리의 v2 cmdline.txt (실측)

```
console=ttyAMA0,115200 console=ttyS0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 rootwait fsck.repair=yes net.ifnames=0
```

---

## 5. v1 → v2 이미지 변경 요약

### v1 vs 공식 RPi OS 비교 (원문 표, 참조 목적 — RPi OS 알맹이는 안 가져옴)

| | 공식 RPi OS | 우리 v1 |
|--|-------------|---------|
| 펌웨어 | `start4.elf` 2305632 + start4x/cd/db + fixup 다수 + **overlays 371개** | `start4.elf` **2306400**(master, 다른 버전) + 2개뿐, overlays 없음 |
| kernel8.img | 10MB (RPi 포크) | 50MB (우리 mainline) |
| 시리얼 | `console=serial0` (dtb alias) | `console=ttyS0` (mini-UART, baud 흔들려 ▒▒) |

### v2에서 적용한 조치 (원문 기준)

1. **펌웨어 교체** → RPi OS의 검증된 Broadcom 버전(`start4.elf` 2305632 / `start4x.elf` / `fixup4.dat` / `fixup4x.dat`)으로 교체 + `config-arm64/firmware/`에 박제.
2. **시리얼 = PL011(ttyAMA0)** via `dtoverlay=disable-bt` (mini-UART baud 흔들림 해결 목적). overlay ↔ mainline dtb 호환 불확실 → **cmdline에 `ttyAMA0` + `ttyS0` 양쪽 console 헤지** + inittab에 ttyAMA0 getty 추가.
3. **config.txt 순수 ASCII** + `hdmi_safe` 제거 (§4).
4. **커널·dtb·rootfs는 그대로.** 산출: 동일 파일명 덮어쓰기(v2).

**결과**: v2도 **짧2 동일** → 위 조치들(펌웨어/시리얼/config)로는 안 고쳐짐.

### 현재 리포지토리 firmware 파일 (실측)

`config-arm64/firmware/` (RPi OS SD에서 채취한 Broadcom 공식 blob, 2026-06-18 날짜, BIOS급 = 정체성 무관):

| 파일 | 크기 (실측) |
|------|-------------|
| `start4.elf` | 2305632 |
| `start4x.elf` | 3053352 |
| `fixup4.dat` | 5499 |
| `fixup4x.dat` | 8494 |
| `overlays/disable-bt.dtbo` | 1073 |
| `overlays/miniuart-bt.dtbo` | 1566 |
| `overlays/vc4-kms-v3d.dtbo` | 2760 |

---

## 6. 남은 가설 (둘 중 하나 — 아직 미확정) · ❌ 둘 다 반증됨 (2026-07-08)

> ❌ **반증**: 시리얼이 부활하자 두 가설 모두 틀린 것으로 드러났다(상단 RESOLVED 배너 참조). 범인은 이미지가 아니라 **죽은 시리얼 어댑터 + `console=ttyS0` 순서 + 경미 rootfs 설정**이었다. 아래는 그 시점의 추론으로 보존.

- **(A) 우리 FAT 파티션 구조**를 Pi 펌웨어가 못 읽음. `mkfs.vfat`가 만든 FAT를 Pi의 **원시 부트 파서가 싫어함**(Windows는 관대해서 읽힘). RPi OS의 FAT는 Pi 파서가 읽음. — ❌ **반증**: 펌웨어는 우리 FAT를 완벽히 읽고 커널로 핸드오프했다.
- **(B) 우리 50MB 커널.** 통합 defconfig(전 SoC builtin)로 인해 `kernel8.img`가 50MB → 로드 실패 가능(RPi 포크 커널은 10MB). 크기/로드 주소 문제 가능성. — ❌ **반증**: 50MB 커널은 정상 로드·완전 부팅됐다.

두 가설을 **하나로 못 박기 위한 격리 테스트**가 다음 액션(§7). *(→ 실제로는 전제가 틀려 실행 전 무의미해짐.)*

---

## 7. 격리 테스트 절차 (커널 vs FAT 못박기) · ⏭️ 실행 전 무의미해짐 (2026-07-08)

> ⏭️ **미실행**: 이 격리 테스트는 "범인 = 우리 이미지"라는 전제였는데 그 전제가 틀렸다. 시리얼 부활 + `console=ttyS0` 맨 뒤 배치로 곧장 부팅에 도달해 실행 불요가 됐다. 좋은 이분법 격리 방법론의 예시로 보존한다.

**아이디어**: **우리 `kernel8.img` + `dtb`를, RPi OS의 "작동하는 부트 체인"(펌웨어 + FAT 구조) 위에 얹어** 부팅한다. 변수를 하나(우리 커널)로 좁힌다.

**준비물 (이미 확보)**: `config-arm64/isolation-test/{kernel8.img, bcm2711-rpi-4-b.dtb}` — 우리 산출물 복사본.
- 실측: `kernel8.img` = 50022912, `bcm2711-rpi-4-b.dtb` = 39650 (§3 값과 일치 확인).

**절차 (원문 기준)**:
1. 사용자가 **RPi OS Lite를 SD에 재플래시** (작동하는 펌웨어 + FAT 구조 확보).
2. SD를 PC에 꽂아 부트 파티션(F:)을 연다.
3. **F:에 우리 `kernel8.img` + `dtb`를 덮어쓰고, `config.txt`를 "우리 커널 부팅용 최소 세팅"으로 수정** (RPi 펌웨어와 FAT 구조는 유지).
   - *구체 PowerShell 명령·최소 config.txt 내용은 소스 원문에 `미기록`. 실행 시 확정.*
4. 사용자 부팅.

**판정 기준**:
- **시리얼에 `Booting Linux...` 가 뜨면 → 커널은 정상 = FAT가 범인.** (→ 가설 A) → 이미지의 FAT 재조립으로 픽스.
- **여전히 짧2 → 커널이 범인.** (→ 가설 B) → 커널 슬림화로 픽스.

---

## 8. 범인별 픽스 계획 (준비됨) · ⏭️ 불요 (2026-07-08, FAT·커널 둘 다 무죄)

> ⏭️ 아래 두 픽스는 준비됐으나 실행 불요가 됐다 — FAT도 커널도 범인이 아니었기 때문(상단 RESOLVED 배너). 방법론 예시로 보존.

### 8-A. FAT가 범인일 때

이미지 빌드에서 `mkfs.vfat` 대신 **Pi-friendly FAT**로 재조립:
- RPi OS FAT 파라미터 복제, **또는** `mkfs.fat -F32 -s <cluster>`로 클러스터 크기 명시, **또는** Pi Imager식 부트 파티션 위에 우리 파일을 얹는 방식.

### 8-B. 커널이 범인일 때

커널 재빌드로 슬림화 (50MB → ~10–15MB):
- 통합 `arch/arm64/configs/defconfig`에서 **Broadcom/Pi 외 SoC(MediaTek/Rockchip/Qualcomm/Tegra …) 비활성화**.
- `arch/arm64/configs/defconfig` 트림 + `scripts/config`.
- *(주의: CLAUDE.md/함정 카탈로그상 mainline엔 `bcm2711_defconfig`가 없다(함정 #1). 슬림화는 통합 defconfig 트림으로 수행.)*

---

## 9. 시리얼 콘솔 현황 · ✅ 진짜 범인이 여기 있었다 (2026-07-08)

> ✅ **아래 "▒▒ 깨진 글자 / 무출력"의 진짜 원인은 baud도 접점도 아니라 어댑터 단선(사망)이었다.** 새 FT232RL + **흰↔초 배선 스왑**(핀8=초록=어댑터TX, 핀10=흰=어댑터RX)으로 부활 → 이것이 부팅 해결의 열쇠. mini-UART `ttyS0`가 최종 확정(ttyAMA0 헤지 철회). 아래 표는 그 시점의 (오)진단 기록.

| 항목 | 값 |
|------|-----|
| 어댑터 | FT232RL (구형 = **단선 사망** → 신품 교체) |
| 포트 | **COM9** |
| Baud | **115200** (8N1) |
| 증상 (당시 오진) | **▒▒ 깨진 글자 / 무출력** = "baud 흔들림/접점"으로 추정 → 실제는 **죽은 어댑터 + 배선 반대** |
| v2 시도 (철회) | ~~PL011(ttyAMA0) via `dtoverlay=disable-bt`~~ → 부팅 해결 후 mini-UART `ttyS0`로 확정 |

**배선 (원문 verbatim)**: `GND → 핀6, TX → 핀8, RX → 핀10, 3.3V, 빨강(VCC) 연결 안 함.`
- (핀8 = GPIO14/TXD, 핀10 = GPIO15/RXD. Stage 4a 원문은 "GPIO14/15, 115200"으로도 기록.)
- 어댑터 TX/RX는 Pi 기준 크로스 연결. VCC(빨강)는 미연결 — Pi는 별도 USB-C 5V3A로 급전.

~~**아직 시리얼 무출력** 상태라, 부팅 실패 지점을 시리얼 로그로 못 잡고 있다.~~ → ✅ **해결**: 어댑터 교체 + 흰↔초 스왑으로 시리얼 부활 후, cmdline `console=ttyS0`를 **맨 뒤로** 옮기자 init/rc 출력이 드러났다(그전엔 유저스페이스가 안 보이는 tty1 더미 콘솔로 샜음). 커널은 처음부터 완전 부팅 중이었다 — "부팅 실패 지점"은 애초에 없었다(관측 불능이었을 뿐). 격리 테스트(§7)는 그래서 불요가 됐다.

---

## 10. 이미지 자산 · SHA · 경로 (핸드오프용)

### 이미지 (Windows 쪽 `output/`)

> **⚠️ 갱신(2026-07-30)**: 아래 v1/v2는 **부팅 디버깅 시점(2026-07-05)의 이미지**다. 부팅 해결 후 v6(무인 클린부팅)→v7.1(그래픽 데스크톱)→v8(x86 패리티)→v9/v10(한글 입력)→v11(GTK3/Firefox 한국어)→v12(유선 네트워크)→v13(HW커서·HDMI)→v14(Plank 소스빌드)→v15(picom+유리 테마)→**v16**으로 진화했다. **현재 `output/`에 물리적으로 존재하는 이미지 = v16**(3,362,609,608 B, SHA `57daa20a…b8e1f`, 사이드카 일치 실측, mtime 2026-07-29 16:13). 전체 이력 표 = [`00-BUILD-REPRODUCIBILITY.md`](00-BUILD-REPRODUCIBILITY.md) §10.5.

| 버전 | 파일 | 크기 | SHA256 |
|------|------|------|--------|
| **v1** | `output/MaruxOS-2.0.0-arm64.img.xz` | 1.1G | `605ec90af39ccd262ecd8a9f66b1b279482818c7acf2233078a7b5425173bd59` |
| **v2** (07-05 디버깅 시점) | `output/MaruxOS-2.0.0-arm64.img.xz` (동일 파일명 덮어쓰기) | 1.02GB | `eab7dc2bf9553ee1d5f9931e1856c67c5b18acc6cdf697db6e2b35cf40d15131` |
| **v9** (07-22 한글 입력) | `output/MaruxOS-2.0.0-arm64.img.xz` (동일 파일명, 후속 버전에 덮어써짐) | 3.1G (3,251,016,632 B, 실측) | `6829830f87acb73d58c88975d5c0d9a83bb89ab990b14be98fd54ef6746569f3` |
| **v10** (07-23 out-of-box 한글) | `output/MaruxOS-2.0.0-arm64.img.xz` (동일 파일명, v11~v16에 순차 덮어써짐) | 3.03GB (3,249,853,780 B) | `2b73877b24f2d2953509eed36d6fbba4efb2f5314921774ff7ad42846d8a20f2` — out-of-box 한글 |
| **v16** (현재 디스크상) | `output/MaruxOS-2.0.0-arm64.img.xz` | 3.2G (3,362,609,608 B, 실측, mtime 2026-07-29 16:13) | `57daa20ad5df363245ae839918b07ff4d2101b61680e5f701626fb7a76fb8e1f` — Plank dock+picom 데스크톱 완성 + 라이브픽스 4종 *(4종 중 bamf 픽스는 2026-08-14 오진 판명 — 실근원 = libwnck 43.0 업스트림 버그[함정 #25], v17에서 완결 예정)* |

### 산출물 · 백업 (WSL `~/MaruxOS-arm64/`)

- **커널 산출물**: `~/MaruxOS-arm64/kernel/linux-6.18.26/arch/arm64/boot/{Image, dts/broadcom/bcm2711-rpi-4-b.dtb}`
  - `Image` = 50,022,912 B (= `kernel8.img`), kernelrelease `6.18.26-maruxos`.
  - `bcm2711-rpi-4-b.dtb` = 39,650 B.
- **rootfs 백업**: `~/MaruxOS-arm64/lfs-rootfs-complete.tar` (4.6G, 완성 rootfs), `lfs-ch7-snapshot.tar` (3.2G).

### 커널 메타 (SSOT — `config/lfs-versions.conf`)

- `KERNEL_VERSION="6.18.26"`
- `KERNEL_SHA256="53772f5d3776e043767c8d81a32240d1f3eb64e822a5d7a510b55ca40707b0ec"` (Stage 1a에서 kernel.org 타르볼과 byte 일치 검증됨)

### 이미지 빌드 방법 (원문 기록 — 명령 스케치)

```
truncate -s 7G  →  sfdisk (p1 512M type c bootable, p2 L)  →  losetup -fP
  →  mkfs.vfat -F32 (p1) / mkfs.ext4 (p2)
  →  rootfs tar 전개 (lfs-rootfs-complete.tar)
  →  boot 파티션 populate (firmware + kernel8.img + dtb + config.txt + cmdline.txt)
  →  xz -T0
```
- 환경: WSL root, `loop0` (`WSL2 losetup -P` 동작 확인됨).
- inittab: `ttyS0` + `ttyAMA0` getty 둘 다 (이미지 조립 시 sed로 추가).
- *위 파이프라인은 원문에 단계 스케치로 기록됨. 각 단계의 정확한 인자 전체는 스크립트화되지 않았을 가능성 — 세부 인자는 부분 `미기록`.*

---

## 11. 호스트 변경 (검토 대기 · 가역)

빌드 마라톤 중 WSL 슬립이 chroot 빌드를 끊는 문제(함정 #2/#5) 대응으로 선적용. **가역 조치이며 사용자 검토 대기 항목.**

| 조치 | 명령 (verbatim) | 복구 |
|------|------------------|------|
| AC 슬립 끔 | `powercfg /change standby-timeout-ac 0` | `powercfg /change standby-timeout-ac 30` |
| AC 최대절전 끔 | `powercfg /change hibernate-timeout-ac 0` | (원문 복구 명령 `미기록`) |
| lid-close 동작 끔 | `powercfg ... SUB_BUTTONS LIDACTION 0` | `... LIDACTION 1` |

---

## 12. 사용자 절대 원칙 (재확인 2026-07-02)

> *"다른 OS 참고한답시고 이 프젝을 라파 그 자체로 만들면 안 된다."*

- **참조/사용 허용**: Broadcom 펌웨어(`start4.elf` = GPU 펌웨어 = BIOS급, OS 아님)·overlays·config 파일 형식.
- **100% 우리 것 (절대 대체 금지)**: 커널(우리 mainline **6.18.26-maruxos**)·rootfs(우리 from-scratch CLFS)·dtb(우리 mainline).

---

## 13. 다음 액션 요약 · ✅ 전부 완료·초월됨 (2026-07-08~23)

> ✅ 아래는 2026-07-05 시점의 계획이다. 실제 진행은 상단 RESOLVED 배너대로 흘렀다 — 아래 1·2는 전제 오류로 불요가 됐고, 3(시리얼 확보)이 실제 돌파구였다.

1. ~~격리 테스트 실행 (§7)~~ — ⏭️ 불요(전제 오류). 실제 돌파구는 아래 3.
2. ~~§8-A(FAT 재조립) 또는 §8-B(커널 슬림화)~~ — ⏭️ 불요(FAT·커널 둘 다 무죄).
3. **시리얼 출력 확보** — ✅ **이것이 진짜 열쇠였다.** 죽은 어댑터 교체 + 흰↔초 배선 스왑으로 시리얼 부활 → `console=ttyS0` 맨 뒤 라우팅 → init/rc 관측 → rootfs 4종 픽스 → **무인 클린부팅(v6) → `marux login:`.**
4. (이후) HDMI VC4=y(Stage 5a) → X.org+데스크톱(v7.1) → x86 패리티(v8) → **ibus-hangul 한글 입력(v10)** → GTK3/Firefox 한국어(v11) → 유선 네트워크(v12) → **Plank dock+picom 데스크톱(v14~v16)**.

---

### 부록: ARM64 함정 카탈로그 중 부팅 관련 (전체는 `ARM64-Update-Log.md`)

- **#1** mainline엔 `bcm2711_defconfig` 없음 (RPi 포크 전용) → 통합 defconfig + Pi4 builtin 강제.
- **부팅 함정 A (해결)**: config.txt 비ASCII(한글 mojibake)가 Pi 원시 파서를 죽일 수 있음 → 순수 ASCII·BOM 없음으로 교체.
- **부팅 함정 B (✅ 해결 2026-07-08)**: "짧2 = 펌웨어가 부트 못 읽음"은 오진이었다. FAT 구조(A)·50MB 커널(B) 가설 둘 다 반증. 진짜 원인 = 죽은 시리얼 어댑터(관측 불능) + `console=ttyS0` 순서 + 경미 rootfs 설정. 격리 테스트는 전제 오류로 미실행. (상단 RESOLVED 배너 참조.)
