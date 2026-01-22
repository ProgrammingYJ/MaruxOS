# Changelog

All notable changes to MaruxOS will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- ARM architecture support
- Additional desktop environments
- Custom package repository
- Automatic update system
- Backup and restore utility
- System monitoring dashboard

## [1.0.0] - 2024-11-23

### Added
- Initial release of MaruxOS
- Linux Kernel 6.12 LTS support
- Debian Bookworm base system
- GRUB2 bootloader with custom theme
- Plymouth boot splash
- Calamares graphical installer
- Desktop environment options:
  - GNOME
  - KDE Plasma
  - XFCE
  - Cinnamon
- Live USB/CD support (Try Marux mode)
- Custom MaruxOS branding and themes
- Automated build system
- Comprehensive build scripts:
  - Environment preparation
  - Kernel download and compilation
  - Root filesystem creation
  - Desktop installation
  - GRUB configuration
  - Plymouth setup
  - Installer configuration
  - Live system creation
  - ISO generation
- Documentation:
  - README.md
  - BUILD.md - Build instructions
  - DEVELOPMENT.md - Development guide
  - FAQ.md - Frequently asked questions
  - CONTRIBUTING.md - Contribution guidelines
- Utility scripts:
  - Master build script (build-all.sh)
  - Clean script
  - VM test script
- Default applications:
  - Firefox ESR web browser
  - Thunderbird email client
  - LibreOffice suite
  - GIMP image editor
  - VLC media player
  - File manager
  - Text editor
  - Terminal
  - Calculator
  - Document viewer
- System tools:
  - Network Manager
  - PulseAudio
  - GParted
  - Synaptic
  - htop
  - neofetch
- Configuration files:
  - Release configuration
  - System defaults
  - Korean locale support (ko_KR.UTF-8)
  - English fallback (en_US.UTF-8)
  - Asia/Seoul timezone default

### Features
- BIOS and UEFI boot support
- Dual-boot capable
- Live session with persistence option
- Graphical installer with slideshow
- Multiple partition schemes support
- ext4, Btrfs, XFS filesystem support
- Automatic hardware detection
- Network configuration during install
- User account creation
- Root password configuration
- Hostname customization
- Timezone selection
- Keyboard layout selection
- Modern blue and black color scheme
- Custom plymouth theme with animation
- Branded boot menu
- Welcome screen in live mode
- Desktop wallpaper
- Login screen background
- System logos (64px, 128px, 256px, 512px)

### Technical Details
- Architecture: x86_64 (AMD64)
- Kernel: Linux 6.12 LTS
- Init System: systemd
- Package Manager: APT (Debian)
- Bootloader: GRUB2
- Installer: Calamares
- Boot Splash: Plymouth
- Base: Debian Bookworm
- Compression: squashfs with xz

### Build System
- Modular build scripts
- Parallel build support
- Incremental build capability
- Clean build option
- Skip kernel build option
- Automated dependency checking
- Error handling and validation
- Progress indication
- Build time optimization
- Checksum generation (MD5, SHA256)

### Security
- LTS kernel for long-term security updates
- Debian security repository enabled
- sudo for privilege escalation
- AppArmor profiles (from Debian)
- Firewall ready (ufw available)
- SSH server included

### Known Issues
- Initial boot may be slow on HDD
- Some WiFi adapters may need additional firmware
- Nvidia proprietary drivers not included (install post-install)
- Secure Boot not configured by default

### Notes
- First stable release
- Ready for testing and feedback
- Not recommended for production use yet
- Please report bugs and issues

---

## Release Types

- **Major** (X.0.0): Significant changes, new features, breaking changes
- **Minor** (1.X.0): New features, improvements, backwards compatible
- **Patch** (1.0.X): Bug fixes, security updates, minor improvements

## Versioning

MaruxOS follows semantic versioning:
- Version format: MAJOR.MINOR.PATCH
- Codenames: Each major version has a codename
  - 1.0 "Genesis" - The beginning

---

[Unreleased]: https://github.com/maruxos/maruxos/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/maruxos/maruxos/releases/tag/v1.0.0
