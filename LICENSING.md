# MaruxOS Licensing (policy & scope)

> **Files:** [`LICENSE`](LICENSE) is the verbatim text of The Unlicense (what GitHub detects). This document explains *what* that dedication covers, what it does not, and how third-party components are handled.

## 1. MaruxOS's own work — The Unlicense (Public Domain Dedication)

To the extent possible under law, the MaruxOS authors have waived all copyright and related or neighboring
rights to **the MaruxOS-specific work in this repository**, which means:

- build, install and configuration scripts (`scripts/`), configuration files (`config/`, `config-arm64/`),
- documentation (`*.md`, `docs/`),
- `src/marux-quicksettings` (the MaruxOS status bar / quick-settings GUI),
- artwork made by MaruxOS itself — everything in `MaruxOS 디자인/` **except** the four tuna27 items listed in §2: the app icons `marux-editor.png`, `marux-image.png`, `marux-calc.png`, `marux-archive.png`, `marux-taskmgr.png`, the 1.x panel/status icons (`bettery*.png`, `InternetLan.png`, `internetNotConnected.png`, `sound_0.png`), boot/splash art (`marux-splash.png`, `marux-login.png`, `progress-bar.png`, `progress-box.png`, `kernel-panic.png`),
- the assembly of the distribution (package selection, layout, integration).

You may use, copy, modify, distribute and sell this work, for any purpose, without asking permission
and without attribution. The full Unlicense text is reproduced in §4 below and in
`config/licenses/UNLICENSE.txt` and, verbatim, in [`LICENSE`](LICENSE) (SPDX: `Unlicense`, OSI-approved).

**Why the Unlicense and not just "public domain":** several jurisdictions (including the Republic of Korea)
have no formal mechanism for an author to place a work in the public domain. The Unlicense achieves the same
intent everywhere: a public-domain dedication where the law allows it, and an unconditional, irrevocable,
OSI-approved license where it does not.

## 2. What the Unlicense does NOT cover

- **Third-party software in the distribution image.** A MaruxOS image is an *aggregate* of hundreds of
  independent projects — the Linux kernel (GPL-2.0), glibc and Qt 5 (LGPL), Firefox (MPL-2.0), Openbox,
  Plank, X.org, ibus-hangul, and many more. Each is redistributed **under its own license, unchanged**.
  The complete list, versions and our compliance notes are in [THIRD-PARTY-LICENSES.md](THIRD-PARTY-LICENSES.md);
  exact source locations are in [SOURCES.md](SOURCES.md); every modification we make is published in
  [`patches/`](patches/). License texts are shipped inside the image under `/usr/share/licenses/`.
- **Proprietary firmware** (Raspberry Pi boot firmware — Broadcom; CYW43455 WiFi firmware — Cypress/Infineon)
  is redistributed unmodified under its own redistribution terms, only for use with Raspberry Pi hardware,
  with the license files shipped alongside the firmware.
- **Artwork by tuna27** — exactly four items: the MaruxOS logo (`marux-logo*.png`, `marux_logo.svg`), the wallpaper (`marux-desktop.png`), the file-manager icon (`marux-file-manager.png`) and the terminal icon (`marux-terminal.png`) — remains © tuna27 and is
  distributed under **Creative Commons Attribution 4.0 (CC BY 4.0)** — tuna27 authorized open-source distribution on 2026-08-28 (via the project author); attribution "tuna27" must be kept. Text: `config/licenses/CC-BY-4.0.txt`, shipped in the image under `/usr/share/licenses/`.
- **Trademarks.** "Firefox" and the Firefox logo are trademarks of the Mozilla Foundation; "Raspberry Pi" is a
  trademark of Raspberry Pi Ltd. MaruxOS uses these names only to describe compatibility and ships the
  unmodified official Firefox build, as those trademark policies allow.

## 3. NOTICE — written offer for source code

MaruxOS binaries are built from upstream release tarballs listed in `SOURCES.md` (name, version, URL, SHA256)
plus the patches in `patches/`. The build is fully reproducible from the scripts in this repository.
If you received a MaruxOS image and need the corresponding source for any GPL/LGPL/MPL component,
it is available from this repository and the MaruxOS release page; you may also request it from the
MaruxOS authors (see README "Support & Contact") and it will be provided at no charge beyond the cost of
physically performing the distribution. This offer is valid for at least three years from the release date.

MaruxOS is built following the Linux From Scratch book (LFS 12.0 toolchain; book instructions MIT-licensed).

---

## 4. The Unlicense — full text

This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <https://unlicense.org/>
