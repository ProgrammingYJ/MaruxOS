# patches/ — MaruxOS modifications to upstream sources

Every change MaruxOS makes to third-party source is listed here and published as a unified diff, so that the
**corresponding source** of every shipped binary is available (GPL §2(a)/§3, LGPL §2, MPL §3).
The diffs are generated from the actual patched build trees; the build scripts apply the same change with an
idempotent `sed` (search for `MaruxOS:` in `scripts/`).

| Patch file | Upstream | File | Purpose | License of upstream |
|---|---|---|---|---|
| `linux-6.18.26-brcmfmac-disable-fwsup.patch` | Linux 6.18.26 | `drivers/net/wireless/broadcom/brcm80211/brcmfmac/feature.c` | Disable firmware supplicant (FWSUP) so wpa_supplicant performs the 4-way handshake on the host. Fixes `ASSOCIATED` loop on Pi 4B. | GPL-2.0-only |
| `wpa_supplicant-2.11-no-4way-offload.patch` | wpa_supplicant 2.11 | `src/drivers/driver_nl80211_capa.c` | Do not advertise `WPA_DRIVER_FLAGS_4WAY_HANDSHAKE_PSK` (pair with the kernel patch). | BSD-3-Clause |
| `ibus-hangul-1.5.5-export-input-mode.patch` | ibus-hangul 1.5.5 | `src/engine.c` | Write `han`/`eng` to `/tmp/marux-ime-mode` whenever the input mode changes (drives the 한/A indicator in marux-quicksettings). | GPL-2.0+ |
| `glibc-2.38-math-vector-no-sve.patch` | glibc 2.38 (sysroot header) | `bits/math-vector.h` | Disable SVE vector-math declarations (Cortex-A72 has no SVE; broke CMake compiler checks in cross builds). Header only. | LGPL-2.1+ |
| `qtbase-5.15.2-gcc13-limits.patch` | Qt 5.15.2 | several headers | `#include <limits>` for GCC 11+. Build fix only. | LGPL-3.0 |
| `qtbase-5.15.2-xkb-keysyms.patch` | Qt 5.15.2 | `src/platformsupport/input/xkbcommon/qxkbcommon.cpp` | Define 4 dead-key keysyms missing from the sysroot's libxkbcommon. Build fix only. | LGPL-3.0 |
| `qtbase-5.15.2-mkspec-fortify2.patch` | Qt 5.15.2 | `mkspecs/linux-aarch64-gnu-g++/qmake.conf` | `-D_FORTIFY_SOURCE=2` (Ubuntu cross gcc defaults to 3, which false-positives on `qt_readlink`). | LGPL-3.0 |
| `qttools-5.15.2-help-config-no-hosttool-check.patch` | Qt 5.15.2 (qttools) | `Qt5HelpConfigExtras.cmake` (installed file) | Skip existence check of host tools `qhelpgenerator`/`qcollectiongenerator` (not built). | LGPL-3.0 |
| `qps-1.10.20-allow-ascii-cast.patch` | qps 1.10.20 | `CMakeLists.txt` | `remove_definitions(-DQT_NO_CAST_FROM_ASCII …)` — newer lxqt-build-tools enforces flags the 2018 code predates. | GPL-2.0+ |

Generation: `scripts/gen-sources-and-patches-arm64.sh` (diffs the patched build trees under `~/MaruxOS-arm64/` against the pristine tarballs; for packages whose build tree was already removed — wpa_supplicant, ibus-hangul — the same `sed` used by the install script is re-applied to the pristine file and diffed). qtermwidget needs no patch (the LinguistTools change turned out to be a no-op there).
