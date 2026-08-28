# MaruxOS — Third-Party Licenses / 서드파티 라이선스

> **Scope.** MaruxOS's *own* work (build scripts, configuration, documentation, `src/marux-quicksettings`, MaruxOS-drawn icons) is dedicated to the public domain under **The Unlicense** (see [LICENSING.md](LICENSING.md)).
> A MaruxOS **image** is an *aggregate* of many independent projects. Each component is redistributed **under its own license**, listed below. Nothing in MaruxOS changes those licenses.
>
> **범위.** MaruxOS *고유 저작물*(빌드 스크립트·설정·문서·`src/marux-quicksettings`·자체 제작 아이콘)은 **The Unlicense**로 퍼블릭 도메인에 헌정합니다([LICENSING.md](LICENSING.md)).
> MaruxOS **이미지**는 수많은 독립 프로젝트의 *집합체*입니다. 각 구성 요소는 **각자의 라이선스** 하에 재배포되며, MaruxOS는 그 라이선스를 바꾸지 않습니다.

## How we comply / 준수 방식

| Obligation | How MaruxOS meets it |
|---|---|
| **Corresponding source** (GPL/LGPL) | Every package is built from an upstream release tarball. Exact package/version/URL/SHA256 list: [SOURCES.md](SOURCES.md). All MaruxOS modifications are published as unified diffs in [`patches/`](patches/) and applied by the scripts in [`scripts/`](scripts/). The image itself does **not** carry source tarballs (kept slim); sources are provided via this repository and the release page (GPLv3 §6(d) / GPLv2 §3 written offer: see LICENSING.md §3). |
| **License texts / notices** (all) | Shipped in the image under `/usr/share/licenses/` (ARM64 v33+, x86_64 cooked-v10+) and in this repository under [`config/licenses/`](config/licenses/). |
| **Firmware redistribution conditions** | `LICENCE.broadcom` is shipped on the boot partition next to `start4.elf`; `LICENCE.cypress` / `LICENCE.broadcom_bcm43xx` are shipped with the WiFi firmware. Firmware is redistributed **unmodified** and only for use with Raspberry Pi hardware, as those licenses require. |
| **LGPL relinking** | LGPL libraries (glibc, Qt5, GTK, ibus, …) are **dynamically linked** shared objects; users can replace them. |
| **Mozilla trademarks** | Firefox is the **unmodified official Mozilla build** (aarch64 ESR ko / x86_64 release), redistributed as-is with its branding, per the Mozilla Trademark Policy. |
| **x86_64 image provenance** | The x86_64 ISO (cooked-v10) is the 1.x LFS rootfs plus the same from-source Qt/desktop stack as ARM64 (cross-built on the host against the rootfs sysroot). A few runtime libraries inherited from the 1.x Plank experiment came from Debian/Ubuntu binary packages (GLib 2.80.0 family — noted below); they are unmodified upstream builds and their source is the upstream tarball of the same version. Modules whose dependencies were never shipped (cups print backend, some imlib2 loaders, gio proxy/gvfs modules, libpulse) are removed at image build time. |
| **Modified packages** | Marked below (⚙️). Each change is a small patch (see `patches/`) and is announced in the file header/comment as required by GPL §2(a). |

## Components / 구성 요소

⚙️ = MaruxOS applies a patch (published in `patches/`).

### Kernel · toolchain · base system
| Component | Version | License | Notes |
|---|---|---|---|
| Linux kernel | 6.18.26 LTS | GPL-2.0-only (with syscall exception) | ⚙️ brcmfmac `feature.c`: disable FWSUP (host 4-way handshake). Pi 4B firmware blobs embedded via `CONFIG_EXTRA_FIRMWARE` (see Firmware). |
| glibc | 2.38 | LGPL-2.1+ (parts GPL-2.0+, BSD, ISC) | ⚙️ `bits/math-vector.h`: SVE declarations disabled for cross builds (header only, no runtime change). |
| GNU Binutils | 2.41 | GPL-3.0+ | build-time |
| GCC (libgcc, libstdc++) | 13.2.0 | GPL-3.0+ **with GCC Runtime Library Exception 3.1** | runtime libraries shipped |
| Busybox (initrd) | LFS-era | GPL-2.0-only | x86_64 initrd |
| GRUB 2 | LFS-era | GPL-3.0+ | x86_64 bootloader |
| sysvinit | LFS 12.0 | GPL-2.0+ | |
| eudev | LFS 12.0 | GPL-2.0+ / LGPL-2.1+ | |
| D-Bus | LFS 12.0 | AFL-2.1 or GPL-2.0+ | |
| util-linux (agetty …) | 2.39.3 | GPL-2.0+ / LGPL-2.1+ / BSD | |
| coreutils, bash, tar, xz, gzip, bzip2, findutils, grep, sed, gawk … | LFS 12.0 | GPL-3.0+ | |
| zlib, libpng, libjpeg-turbo, freetype, fontconfig, harfbuzz, expat, pcre2 … | LFS/BLFS | zlib / libpng / IJG+BSD / FTL(BSD) / MIT / MIT / MIT / BSD | |
| Midnight Commander (mc) | BLFS | GPL-3.0+ | fallback file manager |
| chrony | 4.5 | GPL-2.0 | NTP |
| dhcpcd | 10.0.6 | BSD-2-Clause | |
| wpa_supplicant | 2.11 | BSD-3-Clause | ⚙️ `driver_nl80211_capa.c`: 4-way offload disabled |
| alsa-lib / alsa-utils | 1.2.10 | LGPL-2.1+ / GPL-2.0+ | |
| shared-mime-info, wireless-regdb | — | GPL-2.0+ / ISC | |

### Graphics stack
| Component | Version | License | Notes |
|---|---|---|---|
| X.org server, libX11, xcb, mesa, libinput … | BLFS | MIT/X11 (mesa: MIT) | |
| libxkbcommon | BLFS | MIT | |
| GTK 2 / GTK 3 | 2.24.33 / 3.24.41 | LGPL-2.1+ | |
| GLib | 2.78.4 (ARM64; x86_64 headers/pc) · **2.80.0 runtime on x86_64** | LGPL-2.1+ | x86_64 image: the `/usr/lib/libglib-2.0.so.0.8000.0` family was inherited from a Debian/Ubuntu `libglib2.0-0` binary package during the 1.x Plank experiment and is shipped **unmodified**; corresponding source = upstream GLib 2.80.0 tarball (https://download.gnome.org/sources/glib/2.80/). LFS-built 2.78.4 headers/`.pc` remain in `/usr/lib64`; see Kernel-Update-Log §34. |
| cairo, pango, gdk-pixbuf, ATK | BLFS | LGPL-2.1+ (cairo: LGPL-2.1/MPL-1.1) | |
| Openbox | BLFS | GPL-2.0+ | window manager |
| Plank | 0.11.89 | GPL-3.0+ | dock (built from source with Vala) |
| Vala compiler (build-time) | 0.56.17 | LGPL-2.1+ | |
| bamf, libwnck | 0.5.x / 43.2 | LGPL-3.0 / LGPL-2.0+ | |
| picom | v11.2 | MIT + MPL-2.0 | compositor |
| idesk | 0.7.5 | BSD-3-Clause | desktop icons |
| feh | BLFS | MIT-style (feh license) | fallback image viewer / wallpaper |
| tint2 | BLFS | GPL-2.0 | retired (ARM64 v22, x86_64 cooked-v10) — binary still present, not started |
| xterm | BLFS | MIT/X11 | fallback terminal |

### Korean input
| Component | Version | License | Notes |
|---|---|---|---|
| ibus | 1.5.29 | LGPL-2.1+ | |
| ibus-hangul | 1.5.5 | GPL-2.0+ | ⚙️ `engine.c`: export input mode to `/tmp/marux-ime-mode` (status bar 한/A indicator) |
| libhangul | 0.2.0 | LGPL-2.1+ | |
| Nanum Gothic / Nanum Myeongjo | — | **SIL Open Font License 1.1** | © NAVER Corporation. OFL text shipped with the fonts. |

### Qt desktop
| Component | Version | License | Notes |
|---|---|---|---|
| Qt 5 (Core, Gui, Widgets, DBus, Network, PrintSupport, Sql, Svg, X11Extras, XcbQpa, Help, …) | 5.15.2 | **LGPL-3.0** (or GPL-2.0/3.0 at user's option) | ⚙️ build-only fixes: `#include <limits>` for GCC 13, 4 xkb keysym defines, `-D_FORTIFY_SOURCE=2` build flag. Dynamically linked. |
| qtermwidget / QTerminal | 0.17.0 | GPL-2.0+ | terminal |
| libfm-qt / PCManFM-Qt | 0.17.0 | LGPL-2.1+ / GPL-2.0+ | file manager |
| libfm (extra), menu-cache | 1.3.2 / 1.1.0 | GPL-2.0+ / LGPL-2.1+ | |
| libexif | 0.6.24 | LGPL-2.1+ | |
| FeatherPad | 0.17.1 | GPL-3.0+ | text editor |
| hunspell | 1.7.2 | LGPL-2.1 / GPL-2.0 / MPL-1.1 (tri-license) | |
| LXImage-Qt | 0.17.0 | GPL-2.0+ | image viewer / screenshot |
| SpeedCrunch | 0.12.0 | GPL-2.0+ | calculator |
| LXQt Archiver | 0.2.0 | GPL-2.0+ (backend derived from File Roller) | ⚙️ none (build flags only) |
| json-glib | 1.6.6 | LGPL-2.1+ | |
| qps | 1.10.20 | GPL-2.0+ | ⚙️ CMake only: `remove_definitions(QT_NO_CAST_FROM_ASCII…)` |
| lxqt-build-tools | 0.13.0 | BSD-3-Clause | build-time CMake macros |
| Info-ZIP unzip / zip | 6.0 / 3.0 | Info-ZIP license | unmodified |

### Applications
| Component | Version | License | Notes |
|---|---|---|---|
| Firefox | ARM64: ESR 140.13.0esr (official aarch64 ko build) · x86_64: 146.0.1 (official x86_64 release build, inherited from 1.x) | **MPL-2.0** | Unmodified official Mozilla binaries; Mozilla trademarks retained per Mozilla Trademark Policy. |

### Firmware (proprietary, redistributable)
| Component | License | Conditions we follow |
|---|---|---|
| Raspberry Pi boot firmware (`bootcode.bin`, `start4.elf`, `fixup4.dat`) | Broadcom — `LICENCE.broadcom` | Redistributed unmodified, only for use with Raspberry Pi devices; license file shipped on the boot partition. |
| Cypress/Infineon CYW43455 WiFi firmware (`brcmfmac43455-sdio.bin`, `.clm_blob`) | `LICENCE.cypress` | Redistributed unmodified; license file shipped in `/lib/firmware/`. Embedded into the kernel image via `CONFIG_EXTRA_FIRMWARE` (a kernel-provided mechanism; the blob is data, not derived from kernel code). |
| Broadcom NVRAM (`brcmfmac43455-sdio.*.txt`) | `LICENCE.broadcom_bcm43xx` | Same as above. |
| `regulatory.db` | wireless-regdb (ISC) | |

### MaruxOS-specific
| Item | License |
|---|---|
| Build/install/config scripts, `config/`, docs, `src/marux-quicksettings` (Vala), icons generated by MaruxOS (`marux-editor/image/calc/archive/taskmgr.png`) | **The Unlicense** |
| Artwork by **tuna27** — **only** these four: logo (`marux-logo*.png`, `marux_logo.svg`), wallpaper (`marux-desktop.png`), terminal icon (`marux-terminal.png`), file-manager icon (`marux-file-manager.png`). Every other file in `MaruxOS 디자인/` is MaruxOS's own work (Unlicense, row above). | © tuna27 — **CC BY 4.0** (designer authorized open-source distribution 2026-08-28; attribution "tuna27" required). Not part of the Unlicense dedication; text in `config/licenses/CC-BY-4.0.txt` and `/usr/share/licenses/`. |
| Linux From Scratch (methodology only) | **No LFS book content is included in MaruxOS.** The build scripts are MaruxOS's own work (Unlicense) that follow the book's package order and configure flags; the LFS *instructions* are MIT-licensed. (The book's prose is CC BY-NC-SA and is deliberately not reproduced anywhere in this repository or the images.) |

*Versions marked "LFS 12.0 / BLFS" follow the LFS 12.0 toolchain (glibc 2.38 / binutils 2.41 / gcc 13.2.0) and 12.1-era userland as recorded in `config/lfs-versions.conf`. If a component is missing from this list, its license is the upstream one in its source tarball listed in `SOURCES.md`.*
