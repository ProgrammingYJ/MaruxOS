# MaruxOS ISO Build History

This document records the changes made in each version during the MaruxOS ISO build process.

---

## Phoenix Series

### x86_64 (Initial Build) - 2025-12-16
**Filename:** `MaruxOS-1.0-Phoenix-x86_64.iso`

**Contents:**
- Initial LFS-based system construction
- Basic boot environment setup
- Initial build without version number

---

### x86_64 → v2 - 2025-12-16
**Changes:**
- Introduced version management system
- Changed filename format: `MaruxOS-1.0-Phoenix-v2.iso`

---

### v2 → v3 - 2025-12-16
**Changes:**
- System configuration improvements
- Boot process modifications

---

### v3 → v4 - 2025-12-16
**Changes:**
- Kernel configuration adjustments
- Driver additions

---

### v4 → v5 - 2025-12-16
**Changes:**
- initrd configuration improvements
- Extended hardware support

---

### v5 → v6 - 2025-12-16
**Changes:**
- Live CD base structure implementation
- squashfs filesystem applied

---

### v6 → v7 - 2025-12-16
**Changes:**
- GRUB bootloader configuration
- Boot menu setup

---

### v7 → v8 - 2025-12-16
**Changes:**
- Basic shell environment completion
- System stabilization

---

### v8 → v9 - 2025-12-16
**Changes:**
- Boot stability improvements
- Basic utilities added

---

### v9 → v10 - 2025-12-16
**Changes:**
- System testing and bug fixes
- Package configuration optimization

---

### v10 → v11 - 2025-12-17
**Changes:**
- Additional package integration
- System configuration improvements

---

### v11 → v12 - 2025-12-17
**Changes:**
- Bug fixes
- Performance optimization

---

### v12 → v13 - 2025-12-17
**Changes:**
- System stabilization
- Configuration file cleanup

---

### v13 → v14 - 2025-12-17
**Changes:**
- Additional feature implementation
- Testing and verification

---

### v14 → v15 - 2025-12-17
**Changes:**
- Stabilization work
- Final testing

---

### v15 → v16 - 2025-12-17
**Changes:**
- System configuration changes
- Package updates

---

### v16 → v17 - 2025-12-17
**Changes:**
- Configuration optimization
- Bug fixes

---

### v17 → v18 - 2025-12-17
**Changes:**
- Additional improvements
- System testing

---

### v18 → v19 - 2025-12-17
**Changes:**
- Feature improvements
- Stabilization work

---

### v19 → v20 - 2025-12-17
**Changes:**
- System optimization
- Configuration changes

---

### v20 → v21 - 2025-12-17
**Changes:**
- Additional package integration
- Bug fixes

---

### v21 → v22 - 2025-12-17
**Changes:**
- System improvements
- Testing progress

---

### v22 → v23 - 2025-12-17
**Changes:**
- Stabilization work
- Configuration cleanup

---

### v23 → v24 - 2025-12-17
**Changes:**
- Desktop environment preparation
- X11 base configuration started

---

### v24 → v25 - 2025-12-18
**Changes:**
- Added Openbox window manager
- Started basic desktop environment configuration
- X11 environment setup

---

### v25 → v26 - 2025-12-18
**Changes:**
- Desktop environment package integration (feh, tint2)
- Openbox theme configuration

---

### v26 → v27 - 2025-12-18
**Changes:**
- Changed squashfs compression: `xz` → `gzip`
- **Fixed:** Boot failure due to kernel not supporting xz compression

---

### v27 → v28 - 2025-12-18
**Changes:**
- Switched window manager from xfwm4 to Openbox
- **Fixed:** xfwm4 theme "Clearlooks" not installed error

---

### v28 → v29 - 2025-12-18
**Changes:**
- Copied Openbox themes (Clearlooks-Phenix, etc.)
- Applied default theme

---

### v29 → v30 - 2025-12-18
**Changes:**
- Added XDG_RUNTIME_DIR environment variable setting
- **Fixed:** "XDG_RUNTIME_DIR not set" error

---

### v30 → v31 - 2025-12-18
**Changes:**
- Modified xinitrc: Direct app execution instead of Openbox autostart
- Moved feh, tint2 execution code to xinitrc
- **Fixed:** Openbox autostart not executing issue

---

### v31 → v32 - 2025-12-19
**Changes:**
- Added xterm terminal
- Modified menu.xml (Terminal → xterm)
- **Fixed:** maruxos-terminal binary not found issue

---

### v32 → v33 - 2025-12-19
**Changes:**
- Copied Imlib2 library and loaders
- Added libpng, libjpeg dependencies
- **Fixed:** feh "No Imlib2 loader" error (first attempt)

---

## 67 Series (Codename Change: Phoenix → 67)

### v33 → 67-v1 - 2025-12-19
**Changes:**
- Codename change: Phoenix → 67
- Updated /etc/maruxos-release and /etc/os-release
- Created Imlib2 loader path symlink
  - `/usr/lib/x86_64-linux-gnu/imlib2/loaders` → `/usr/lib/imlib2/loaders`
- **Fixed:** feh unable to find Imlib2 loaders (completely resolved)
- **Result:** ✅ Wallpaper working properly

---

### 67-v1 → 67-v2 - 2025-12-19
**Changes:**
- Changed GRUB menu entry codename to 67
- Updated grub.cfg

---

### 67-v2 → 67-v3 - 2025-12-19
**Changes:**
- Attempted GLib library copy (libglib, libgio, libgobject, etc.)
- Copied libfm, libmenu-cache
- **Purpose:** Attempted to fix pcmanfm file manager `g_once_init_leave_pointer` symbol error
- **Result:** ❌ pcmanfm still not working

---

### 67-v3 → 67-v4 - 2025-12-20
**Changes:**
- Complete copy of pcmanfm and all dependency libraries (ldd-based)
- Copied 70+ libraries (libfm, libgio, libglib, libc, etc.)
- **Result:** ❌ Kernel panic occurred
  ```
  Kernel panic - not syncing: Attempted to kill init! exit code=0x00007f00
  ```
- **Cause:** Overwriting core system libraries like libc.so.6 killed the init process

---

### 67-v4 → 67-v5 - 2025-12-20
**Changes:**
- Rolled back to 67-v3 base
- Completely removed pcmanfm
- Removed `pcmanfm --desktop` call from xinitrc
- Removed File Manager entry from menu.xml
- **Result:** ✅ Normal boot, wallpaper + tint2 panel working

---

### 67-v5 → 67-v6 - 2025-12-20
**Changes:**
- Added xfe (X File Explorer) file manager
- Copied FOX toolkit libraries (libFOX-1.6.so, etc.)
- Added File Manager entry to menu.xml
- Added xfe to tint2 launcher
- Created .desktop files (xterm.desktop, xfe.desktop)
- **Result:** xfe shows "Running Xfe as root!" warning, requires OK click

---

### 67-v6 → 67-v7 - 2025-12-20
**Changes:**
- Created xfe wrapper script (attempted to bypass root warning)
- Copied Adwaita icon theme
- Added GTK configuration files
- Created xfe config file (root_warn=0)
- **Result:** ❌ xfe Segmentation fault occurred
  ```
  bash-5.2# xfe
  Segmentation fault
  ```
- **Cause:** Compatibility issues between FOX library and system libraries

---

### 67-v7 → 67-v8 - 2025-12-20
**Changes:**
- Completely removed xfe (FOX library compatibility issues)
- Replaced with mc (Midnight Commander) file manager
- Copied mc dependencies:
  - libslang.so.2
  - libgpm.so.2
  - libe2p.so.2
  - libssh2.so.1
  - libext2fs.so.2
  - libgmodule-2.0.so.0
  - libcrypto.so.3
- Copied mc data files (/usr/share/mc/)
- Modified menu.xml: File Manager → `xterm -e mc`
- Created mc.desktop file
- **Result:** ✅ File manager working properly (terminal-based)

---

### 67-v8 → 67-v9 - 2025-12-20
**Changes:**
- Updated wallpaper image
- Applied new marux-desktop.png design
- **Result:** ✅ New wallpaper applied successfully

---

### 67-v9 → 67-v10 - 2025-12-20
**Changes:**
- Complete Openbox theme reset (including window button styles)
- titleLayout configuration: NLIMC (icon, label, iconify, maximize, close)
- Added window button color styling
  - Default: Blue gradient
  - Close button hover: Red
- Complete Adwaita icon theme copy
- Created GTK 2.0/3.0 icon configuration files
- **Issue:** Button hover works but click events don't work

---

### 67-v10 → 67-v11 - 2025-12-23
**Changes:**
- Complete Openbox rc.xml rewrite
- Added all mouse bindings:
  - Close button: Press → Focus/Raise, Click → Close
  - Maximize button: Press → Focus/Raise, Click → ToggleMaximize
  - Iconify button: Press → Focus/Raise, Click → Iconify
- Additional mouse bindings:
  - Titlebar: Drag to move, double-click to maximize
  - Frame: Alt+drag to move/resize
  - Desktop/Root: Right-click menu
- Added keyboard shortcuts:
  - Alt+F4: Close window
  - Alt+Tab: Next window
  - Alt+Shift+Tab: Previous window
- **Result:** ✅ Window button click events working

---

### 67-v11 → 67-v12 - 2025-12-24
**Changes:**
- Complete tint2 panel redesign
- Applied custom icons:
  - marux-terminal.png (terminal icon)
  - marux-file-manager.png (file manager icon)
  - marux-logo.png (Marux app menu button)
- Added system tray:
  - nm-applet (WiFi network management)
  - volumeicon (sound volume control)
- Added Chromium web browser
- tint2 launcher configuration:
  - Left: Marux logo, terminal, file manager, Chromium
  - Right: System tray (WiFi, sound), clock
- Added auto-launch for system tray apps in xinitrc
- **Issue:** Chromium not working, Desktop showing in taskbar

---

### 67-v12 → 67-v13 - 2025-12-30
**Changes:**
- Complete Chromium reinstallation:
  - Copied entire /usr/lib/chromium directory
  - Added NSS libraries
  - Added --no-sandbox --disable-gpu options
  - Created wrapper script
- Fixed tint2 Desktop display issue:
  - Added wm_class_filter (feh, pcmanfm-desktop)
- Updated Openbox settings:
  - feh window skip_taskbar setting
  - Desktop class skip_taskbar setting
- **Result:** ✅ Desktop hidden from taskbar

---

### 67-v13 → 67-v14 - 2025-12-30
**Changes:**
- Improved mc file manager:
  - mc.desktop runs with `mc ~ /` command
  - Left panel: Home directory (~)
  - Right panel: Root directory (/)
  - Created mc config files (/etc/skel/.config/mc/)
- Improved Chromium launch script:
  - Auto-detect binary from multiple paths
  - Added --disable-dev-shm-usage option
- **Result:** mc panels show different directories

---

### 67-v14 → 67-v15 - 2025-12-30
**Changes:**
- Changed tint2 panel to Windows 11 style:
  - panel_items = :LT:SC (center alignment)
  - Launcher + Taskbar centered
  - System tray + Clock on right
- Changed taskbar style:
  - task_text = 0 (no text, icon only)
  - task_maximum_size = 44 40 (icon size)
  - Shows only icons like Windows 11
- Increased panel height: 36px → 48px
- Increased icon size: 26px → 32px
- **Result:** ✅ Windows 11 style centered taskbar

---

### 67-v15 → 67-v16 - 2026-01-02
**Changes:**
- Firefox browser installation:
  - Downloaded tarball directly from Mozilla
  - Installed to /opt/firefox
  - Created wrapper script (/usr/bin/firefox)
  - Added sandbox disable options
- Removed Chromium (snap/apt unavailable in LFS)
- Changed taskbar web browser icon → Firefox
- ISO size increased: 1.1GB → 1.2GB
- **Result:** ❌ Firefox not working (library dependency issues)

---

### 67-v16 → 67-v17 - 2026-01-03
**Changes:**
- Added Firefox debug mode:
  - Wrapper script shows error messages
  - Run with xterm -hold to see errors
  - Added /opt/firefox to LD_LIBRARY_PATH
- Additional sandbox disable options:
  - MOZ_DISABLE_RDD_SANDBOX
  - MOZ_DISABLE_SOCKET_PROCESS_SANDBOX
- Additional library copies:
  - GTK3, Pango, Cairo, GLib related libraries
  - X11, XCB, xkbcommon libraries
  - DBus, ATK, ATSPI libraries
  - Font, image, compression libraries
  - GIO, GTK, GDK-pixbuf modules
- **Result:** ✅ Firefox runs successfully (with locale warnings)

---

### 67-v17 → 67-v18 - 2026-01-03
**Changes:**
- Fixed Firefox locale warnings:
  - Set LANG=C.UTF-8, LC_ALL=C.UTF-8 environment variables
  - Added same locale settings to xinitrc
  - Redirect stderr to /dev/null (2>/dev/null)
- Added system tray utility scripts:
  - /usr/bin/volume-control (pavucontrol or alsamixer)
  - /usr/bin/network-settings (nm-connection-editor or nmtui)
  - /usr/bin/quick-settings (quick settings menu)
- Updated tint2 configuration:
  - Increased system tray icon size: 20px → 24px
  - Clock click opens quick-settings
- Updated xinitrc:
  - nm-applet, volumeicon auto-start configuration
  - GTK theme environment variables
- Fixed .desktop file:
  - Terminal=false to run Firefox without xterm
- **Result:** ✅ Firefox working properly, system tray icons pending (custom images needed)

---

### 67-v18 → 67-v19 - 2026-01-04
**Changes:**
- Created MaruxOS custom icon theme:
  - /usr/share/icons/MaruxOS/ directory structure
  - index.theme file (inherits Adwaita)
- Applied app icons:
  - terminal.png → utilities-terminal.png
  - marux-file-manager.png → system-file-manager.png
- Applied system tray icons:
  - WiFi: wifi_0~4.png → network-wireless-signal-*
  - Sound: sound_0~3.png → audio-volume-*
  - Network: InternetLan.png, internetNotConnected.png
- Updated tint2 configuration:
  - launcher_icon_theme = MaruxOS
  - chromium.desktop → firefox.desktop
- Updated .desktop file icon paths:
  - xterm.desktop, mc.desktop
- Fixed wallpaper path:
  - /usr/share/pixmaps/maruxos/marux-desktop.png
- **Result:** ❌ Only rollback applied, changes not working (skel/.xinitrc error)

---

### 67-v19 → 67-v20 - 2026-01-10
**Changes:**
- Fixed /etc/skel/.xinitrc:
  - Before: `exec xterm` (only runs terminal)
  - After: Full desktop settings (feh, openbox, tint2, system tray)
  - **Issue Fixed:** Black screen with only terminal showing
- Fixed wallpaper path:
  - Copied /usr/share/backgrounds/marux-desktop.png → /usr/share/pixmaps/maruxos/marux-desktop.png
  - **Issue Fixed:** feh could not find wallpaper
- Created root/.xinitrc:
  - Copied contents from /etc/skel/.xinitrc
- Added GTK icon theme settings:
  - Created /etc/gtk-3.0/settings.ini
  - Created /root/.config/gtk-3.0/settings.ini
  - Set gtk-icon-theme-name=MaruxOS
  - **Issue Fixed:** System tray icons not using MaruxOS theme
- **Result:** ✅ Wallpaper and custom icon theme working properly

---

### 67-v20 → 67-v21 - 2026-01-10
**Changes:**
- Added system icon buttons to tint2 panel:
  - panel_items = :LT:BBBSC (added 3 Buttons)
  - WiFi button: network-wireless-signal-excellent.png
  - Volume button: audio-volume-high.png
  - Battery button: battery-full.png
- Added battery icons:
  - battery-full.png, battery-good.png, battery-low.png
  - battery-caution.png, battery-empty.png, battery-charging.png
- Set button click actions:
  - WiFi click → xterm -e nmtui
  - Volume click → xterm -e alsamixer
- **Issue Fixed:** System tray was empty due to nm-applet/volumeicon not installed
- **Result:** ❌ tint2 button feature not supported

---

### 67-v21 → 67-v22 - 2026-01-10
**Changes:**
- Used tint2 executor (execp) instead of buttons:
  - panel_items = LTEEESC (added 3 Executors)
  - Created icon scripts:
    - /usr/bin/tint2-network-icon
    - /usr/bin/tint2-volume-icon
    - /usr/bin/tint2-battery-icon
- Set click actions:
  - Network click → xterm -e nmtui
  - Volume click → xterm -e alsamixer
- **Issue Fixed:** tint2 button feature not supported in LFS version
- **Result:** ✅ WiFi, Volume, Battery icons displayed

---

### 67-v22 → 67-v23 - 2026-01-10
**Changes:**
- Improved network icon script:
  - Check actual internet connection (ping 8.8.8.8)
  - Disconnected → network-offline.png
  - Wired connection → network-wired.png
  - WiFi connection → signal strength icons (excellent/good/ok/weak/none)
- **Issue Fixed:** Network icon showed connected when not actually connected
- **Result:** ✅ Network status reflects actual connection state

---

### 67-v23 → 67-v24 - 2026-01-11
**Changes:**
- Installed dhcpcd (DHCP client):
  - Copied /usr/sbin/dhcpcd
  - Created /lib/services/dhcpcd service script
- **Issue Fixed:** Network driver (e1000) was present but dhcpcd was missing, couldn't obtain IP address
- **Result:** ✅ Automatic IP assignment available

---

### 67-v24 → 67-v25 - 2026-01-11
**Changes:**
- Updated /etc/issue file codename:
  - "Phoenix" → "67"
- **Issue Fixed:** Boot screen still showing Phoenix codename
- **Result:** ✅ Boot screen displays codename 67

---

### 67-v25 → 67-v26 - 2026-01-11
**Changes:**
- Added dhcpcd auto-start to xinitrc:
  - `/usr/sbin/dhcpcd 2>/dev/null &`
- Created /etc/rc.local file:
  - Auto-start dhcpcd on boot
- **Result:** ❌ Network interface eth0 not found error

---

### 67-v26 → 67-v27 - 2026-01-11
**Changes:**
- Fixed /etc/rc.d/rc.sysinit codename:
  - "MaruxOS 1.0 Phoenix" → "MaruxOS 1.0 67"
- Fixed /etc/lsb-release codename:
  - DISTRIB_CODENAME=Phoenix → DISTRIB_CODENAME=67
  - DISTRIB_DESCRIPTION="MaruxOS 1.0 Phoenix" → "MaruxOS 1.0 67"
- Removed /etc/sysconfig/ifconfig.eth0:
  - VMware interface renamed to eno16777736
  - xinitrc dhcpcd auto-detects all interfaces
- **Issue Fixed:** Boot error "Interface eth0 doesn't exist"
- **Issue Fixed:** Boot screen still showing "Phoenix"
- **Result:** ❌ Network still not working (interface not activated)

---

### 67-v27 → 67-v28 - 2026-01-20
**Changes:**
- Verified kernel network drivers:
  - E1000, E1000E built-in (=y) to kernel confirmed
- Improved xinitrc network initialization:
  - Scan all network interfaces from `/sys/class/net/*`
  - Activate interface with `ip link set $iface_name up`
  - Run dhcpcd for each interface
  - Exclude loopback(lo) interface
- **Issue Fixed:** Network driver present but interface was in down state
- **Result:** ❌ Network still not working

---

### 67-v28 → 67-v29 - 2026-01-20
**Changes:**
- Added network initialization logging:
  - Log file: `/tmp/Network_log.txt`
  - Records network interface list
  - Records each interface activation process
  - Records ip link set command output
  - Records dhcpcd execution result and PID
  - Records final network state (ip addr, ip route)
- **Purpose:** Diagnose why network is not working
- **Result:** ❌ Log file not created (xinitrc not executed)

---

### 67-v29 → 67-v30 - 2026-01-21
**Changes:**
- Fixed initrd init script:
  - "MaruxOS 1.0 Phoenix" → "MaruxOS 1.0 67"
- **Issue Fixed:** Boot splash showing "Phoenix" instead of "67"
- **Result:** ❌ Log file still not created (squashfs not updated)

---

### 67-v30 → 67-v31 - 2026-01-21
**Changes:**
- Rebuilt squashfs:
  - Included xinitrc with network logging code
  - Built with updated initrd
- **Result:** ❌ Log file still not created (xinitrc not executed - rc.sysinit copy issue)

---

### 67-v31 → 67-v32 - 2026-01-21
**Changes:**
- Added /etc/skel/.bash_profile:
  - Includes startx auto-execution code
  - Configured to be copied to /root by rc.sysinit
- **Issue Fixed:** rc.sysinit mounts tmpfs on /root and copies from /etc/skel/, but .bash_profile was missing so startx didn't run
- **Result:** ✅ startx auto-execution successful, ❌ xinitrc still not executed

---

### 67-v32 → 67-v33 - 2026-01-21
**Changes:**
- Fixed rc.sysinit file copy command:
  - Before: `cp /etc/skel/.* /root/` (only some files copied)
  - After: `cp -a /etc/skel/. /root/` (all files and directories copied)
- **Issue Fixed:** .xinitrc was not being copied to /root, causing network log not to be generated
- **Result:** ❌ .xinitrc still not copied

---

### 67-v33 → 67-v34 - 2026-01-21
**Changes:**
- Added explicit .xinitrc copy to rc.sysinit:
  ```bash
  if [ -f /etc/skel/.xinitrc ]; then
      cp -a /etc/skel/.xinitrc /root/.xinitrc
      chmod 755 /root/.xinitrc
  fi
  ```
- **Issue Fixed:** .xinitrc was not being copied even with `cp -a /etc/skel/. /root/`
- **Result:** ❌ .xinitrc still not copied

---

### 67-v34 → 67-v35 - 2026-01-21
**Changes:**
- Added network logging code to `/etc/X11/xinit/xinitrc` (system-wide xinitrc)
- **Issue Found:** startx uses `/etc/X11/xinit/xinitrc` when `~/.xinitrc` doesn't exist
- **Issue Fixed:** Added network initialization logging code directly to system-wide xinitrc
- **Result:** ✅ Network working! (DHCP IP obtained, icon status reflected)

---

### 67-v35 → 67-v36 - 2026-01-22 ~ 01-28
**Changes:**
- GitHub Release v1.0 published
- Complete documentation overhaul (README, FAQ, DEVELOPMENT, LFS-BUILD-GUIDE, CONTRIBUTING)
- License change: MIT → Public Domain
- Build history completely rewritten (analyzed 60MB conversation log)
- **Result:** ✅ Official release completed

---

### 67-v36 → 67-v37 - 2026-02-13
**Changes:**
- Fixed Firefox icon duplication in tint2 panel
- Modified firefox.desktop file:
  - `StartupWMClass=firefox` → `StartupWMClass=Navigator`
  - Added `StartupNotify=true`
- **Issue:** Firefox launcher icon and running window appeared as separate icons in tint2 panel
- **Root Cause:** Firefox's actual WM_CLASS is `Navigator`, but .desktop file had it set to `firefox`
- **Result:** ✅ Firefox now displays as single icon when running (expected)

---


## Technical Notes

### Why gzip instead of xz?
The LFS kernel was built without xz/lzma squashfs support. Switching to gzip compression resolved boot failures.

### Why not pcmanfm?
pcmanfm requires GLib 2.68+ for the `g_once_init_leave_pointer` symbol. The LFS system has an older GLib version, causing symbol lookup errors. Attempts to copy newer GLib libraries resulted in system instability.

### Why not xfe?
xfe uses the FOX toolkit, which has compatibility issues with the LFS system libraries, resulting in segmentation faults on startup.

### Current Solution
mc (Midnight Commander) is used as the file manager. While terminal-based, it's stable and fully functional with the LFS system libraries.
