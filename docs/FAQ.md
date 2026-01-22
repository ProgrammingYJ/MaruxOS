# MaruxOS Frequently Asked Questions

## General Questions

### What is MaruxOS?

MaruxOS is a custom Linux distribution based on Debian, using Linux Kernel 6.12 LTS. It's designed for stability, modern aesthetics, and ease of use.

### Why create another Linux distribution?

MaruxOS focuses on:
- **Stability**: Using LTS kernel for long-term reliability
- **Modern Design**: Custom branding and polished user interface
- **Simplicity**: Easy installation and user-friendly experience

### Is MaruxOS free?

Yes, MaruxOS is completely free and open source.

### What is the relationship with Debian?

MaruxOS is based on Debian stable (Bookworm), using Debian's package repositories and build tools. It adds custom branding, configuration, and optimizations.

## System Requirements

### Minimum Requirements

- **CPU**: 64-bit x86 processor (Intel/AMD)
- **RAM**: 2GB (4GB recommended)
- **Storage**: 20GB
- **Graphics**: VGA compatible display
- **Boot**: UEFI or Legacy BIOS

### Recommended Requirements

- **CPU**: Dual-core 2GHz or faster
- **RAM**: 4GB or more
- **Storage**: 40GB SSD
- **Graphics**: Modern GPU with 512MB+ VRAM
- **Network**: Ethernet or WiFi adapter

### Will MaruxOS run on older computers?

Yes, especially with lighter desktop environments like XFCE. However, very old systems (10+ years) may struggle.

## Installation

### How do I install MaruxOS?

1. Download the ISO image
2. Create bootable USB using Rufus (Windows) or dd (Linux)
3. Boot from USB
4. Choose "Install MaruxOS" from the boot menu
5. Follow the Calamares installer

### Can I try MaruxOS without installing?

Yes! Select "Try MaruxOS" from the boot menu to run a live session without making any changes to your system.

### Can I dual-boot with Windows?

Yes, the Calamares installer supports dual-boot configurations. Make sure to:
- Disable Fast Startup in Windows
- Disable Secure Boot (or configure MOK)
- Have free unallocated space on your drive

### Will installation erase my data?

Only if you choose to erase the disk. The installer offers options:
- Install alongside (dual-boot)
- Replace a partition
- Manual partitioning

Always backup important data before installing any OS.

### What filesystems are supported?

- ext4 (recommended for Linux)
- Btrfs
- XFS
- FAT32 (for boot/EFI partitions)
- NTFS (read/write support)

## Desktop Environment

### Which desktop environment does MaruxOS use?

During installation, you can choose from:
- **GNOME**: Modern, feature-rich
- **KDE Plasma**: Highly customizable
- **XFCE**: Lightweight, traditional
- **Cinnamon**: Elegant, user-friendly

### Can I change desktop environments later?

Yes, you can install additional desktop environments:

```bash
sudo apt install kde-plasma-desktop  # For KDE
sudo apt install xfce4              # For XFCE
```

Then select your preferred DE at login.

### What default applications are included?

- **Browser**: Firefox ESR
- **Office**: LibreOffice
- **Email**: Thunderbird
- **Media**: VLC
- **Graphics**: GIMP
- **Terminal**: GNOME Terminal
- And more utilities

## Software Management

### How do I install software?

Using APT package manager:

```bash
sudo apt update
sudo apt install package-name
```

Or use graphical tools like Synaptic or GNOME Software.

### Are Flatpak/Snap supported?

Not installed by default, but you can add them:

```bash
# Flatpak
sudo apt install flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Snap
sudo apt install snapd
```

### Can I use Debian packages?

Yes! MaruxOS is fully compatible with Debian packages (.deb files).

### How do I update the system?

```bash
sudo apt update
sudo apt upgrade
```

Or use the graphical update manager.

## Kernel and Boot

### Why Linux 6.12 LTS?

- Long-term support (6+ years of updates)
- Excellent hardware compatibility
- Latest security features
- Proven stability

### Can I update to a newer kernel?

Yes, but proceed with caution:

```bash
# Check available kernels
apt search linux-image

# Install newer kernel
sudo apt install linux-image-x.y.z-amd64
```

### How do I access GRUB menu?

Hold `Shift` during boot (or `Esc` on some systems) to show the GRUB menu.

### Boot is slow, how can I speed it up?

```bash
# Analyze boot time
systemd-analyze
systemd-analyze blame

# Disable unnecessary services
sudo systemctl disable service-name
```

## Troubleshooting

### System won't boot after installation

1. Check BIOS boot order
2. Disable Secure Boot
3. Try "Safe Graphics" mode from GRUB menu
4. Check if GRUB is installed on correct drive

### No WiFi connection

```bash
# Check if adapter is detected
lspci | grep -i network
ip link

# Install firmware if needed
sudo apt install firmware-iwlwifi  # For Intel
sudo apt install firmware-realtek  # For Realtek
```

### Graphics issues / Screen flickering

Boot with `nomodeset`:
1. At GRUB, press 'e' to edit
2. Add `nomodeset` to linux line
3. Press F10 to boot

Then install proper graphics drivers.

### No sound

```bash
# Check ALSA
alsamixer

# Restart PulseAudio
pulseaudio -k
pulseaudio --start
```

### System freezes

Common causes:
- Graphics driver issues → Try `nomodeset`
- Overheating → Clean fans, check temperatures
- Bad RAM → Run memtest86+ from GRUB
- Disk errors → Check with `smartctl`

## Building and Customization

### How do I build MaruxOS from source?

See [BUILD.md](BUILD.md) for detailed instructions.

### Can I customize the theme?

Yes! Replace images in `MaruxOS 디자인/` directory before building.

### Build fails with "not enough space"

You need at least 50GB free space. Clean up:

```bash
./scripts/utils/clean.sh
```

### Build takes too long

Normal build time is 1-3 hours. To speed up:
- Use more CPU cores (edit kernel build script)
- Use SSD instead of HDD
- Skip kernel build if not modified

### Can I create a custom ISO?

Well... Do it if you can.
This project didn't do Obfuscation.

## Support and Community

### Where can I get help?

- Check this FAQ
- Read the documentation in `docs/`
- Check build logs for errors
- Search for similar issues online
- DM me in Discord! (ID : pizzamaru_.)

### How can I contribute?

See [DEVELOPMENT.md](DEVELOPMENT.md) for contribution guidelines.

### I found a bug, where do I report it?

Create a detailed bug report including:
- MaruxOS version
- Hardware specifications
- Steps to reproduce
- Error messages
- System logs

### Is there a forum or community?

Community resources (to be established):
- Forum: TBD
- Discord: No server Yet, Just DM Me! (ID : pizzamaru_.)
- IRC: TBD

## Technical Details

### What kernel parameters does MaruxOS use?

Live boot:
```
boot=live quiet splash
```

### What init system is used?

**systemd** - Modern, full-featured init system.

### What package manager?

**APT** (Advanced Package Tool) - Debian's robust package manager.

### What bootloader?

**GRUB2** - Supports both BIOS and UEFI boot modes.

### Is Secure Boot supported?

Not by default. To enable:
1. Sign kernel with MOK (Machine Owner Key)
2. Enroll MOK in firmware
3. Enable Secure Boot

## Comparison

### MaruxOS vs Ubuntu?

| Feature | MaruxOS | Ubuntu |
|---------|---------|--------|
| Base | 100% Linux Kernel | Debian |
| Release Cycle | When Maru wants | 6 months |
| Kernel | 6.12 LTS | Latest |
| Focus | Stability | Features |
| Branding | Custom | Canonical |

### MaruxOS vs Arch Linux?

| Feature | MaruxOS | Arch |
|---------|---------|------|
| Difficulty | Easy | Advanced |
| Package Manager | APT | Pacman |
| Release | Stable | Rolling |
| Target User | People who is crazy on Vibe-Coding | Experienced |


## Performance

### How much RAM does MaruxOS use?

Depends on desktop environment:
- **GNOME**: ~1.5GB
- **KDE**: ~1.2GB
- **XFCE**: ~600MB

### Is MaruxOS fast?

Nah, IDK. How about testing and reporting?

### Can I run MaruxOS on a Raspberry Pi?

Not currently. MaruxOS is built for x86_64 architecture. ARM support may come in future versions.

## Licensing

### What license is MaruxOS under?

Components use various open source licenses:
- Linux Kernel: GPLv2
- Debian packages: Various (GPL, MIT, BSD, etc.)
- Custom scripts: (NO LICENSE)

### Can I redistribute MaruxOS?

Yes This is 100% Open Source!

### Can I use MaruxOS commercially?

Yes, there are no restrictions on commercial use.

---

**Still have questions?** Check the detailed documentation or contribute to improving this FAQ! or Feel free to DM ME!
