#!/usr/bin/env bash
# MaruxOS LFS - System Configuration and Boot Setup (Chapter 9-10)
# This script runs INSIDE the chroot environment

set -e
set -o pipefail

echo "========================================"
echo "MaruxOS - System Configuration"
echo "========================================"
echo ""
echo "This will configure:"
echo "  - Network configuration"
echo "  - System initialization scripts"
echo "  - Bootloader (GRUB)"
echo "  - Kernel configuration"
echo ""

# Source version information
if [ -f "/sources/../config/marux-release.conf" ]; then
    source "/sources/../config/marux-release.conf"
else
    # Default values
    DISTRO_NAME="MaruxOS"
    DISTRO_VERSION="1.0"
    DISTRO_CODENAME="Phoenix"
    KERNEL_VERSION="6.7.4"
fi

#================================================
# LFS-Bootscripts
#================================================

echo ""
echo "=== Installing LFS-Bootscripts ==="
echo ""

cd /sources
tar -xf lfs-bootscripts-20230728.tar.xz
cd lfs-bootscripts-20230728
make install
cd /sources
rm -rf lfs-bootscripts-20230728

echo "✓ LFS-Bootscripts installed"

#================================================
# Network Configuration
#================================================

echo ""
echo "=== Configuring Network ==="
echo ""

# Create network interface configuration
cat > /etc/sysconfig/ifconfig.eth0 << "EOF"
ONBOOT=yes
IFACE=eth0
SERVICE=ipv4-static

IP=192.168.1.100
GATEWAY=192.168.1.1
PREFIX=24
BROADCAST=192.168.1.255
EOF

# Create resolv.conf
cat > /etc/resolv.conf << "EOF"
# DNS Configuration
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF

# Set hostname
echo "maruxos" > /etc/hostname

# Create hosts file
cat > /etc/hosts << "EOF"
# Begin /etc/hosts

127.0.0.1 localhost.localdomain localhost
127.0.1.1 maruxos.localdomain maruxos
::1       localhost ip6-localhost ip6-loopback
ff02::1   ip6-allnodes
ff02::2   ip6-allrouters

# End /etc/hosts
EOF

echo "✓ Network configured"

#================================================
# System Configuration Files
#================================================

echo ""
echo "=== Creating system configuration files ==="
echo ""

# /etc/inittab (for SysVinit or systemd)
if [ "$INIT_SYSTEM" = "sysvinit" ]; then
    cat > /etc/inittab << "EOF"
# Begin /etc/inittab

id:3:initdefault:

si::sysinit:/etc/rc.d/init.d/rc S

l0:0:wait:/etc/rc.d/init.d/rc 0
l1:S1:wait:/etc/rc.d/init.d/rc 1
l2:2:wait:/etc/rc.d/init.d/rc 2
l3:3:wait:/etc/rc.d/init.d/rc 3
l4:4:wait:/etc/rc.d/init.d/rc 4
l5:5:wait:/etc/rc.d/init.d/rc 5
l6:6:wait:/etc/rc.d/init.d/rc 6

ca:12345:ctrlaltdel:/sbin/shutdown -t1 -a -r now

su:S06:once:/sbin/sulogin
s1:1:respawn:/sbin/sulogin

1:2345:respawn:/sbin/agetty --noclear tty1 9600
2:2345:respawn:/sbin/agetty tty2 9600
3:2345:respawn:/sbin/agetty tty3 9600
4:2345:respawn:/sbin/agetty tty4 9600
5:2345:respawn:/sbin/agetty tty5 9600
6:2345:respawn:/sbin/agetty tty6 9600

# End /etc/inittab
EOF
fi

# /etc/sysconfig/clock
cat > /etc/sysconfig/clock << "EOF"
# Begin /etc/sysconfig/clock

UTC=1

# Set this to any options you might need to give to hwclock,
# such as machine hardware clock type for Alphas.
CLOCKPARAMS=

# End /etc/sysconfig/clock
EOF

# /etc/sysconfig/console
cat > /etc/sysconfig/console << "EOF"
# Begin /etc/sysconfig/console

UNICODE="1"
KEYMAP="us"
FONT="Lat2-Terminus16"

# End /etc/sysconfig/console
EOF

# /etc/profile
cat > /etc/profile << "EOF"
# Begin /etc/profile

export LANG=en_US.UTF-8
export PATH=/usr/bin:/usr/sbin
export PS1='\u@\h:\w\$ '

if [ -d /etc/profile.d ]; then
  for i in /etc/profile.d/*.sh; do
    if [ -r $i ]; then
      . $i
    fi
  done
  unset i
fi

# End /etc/profile
EOF

# /etc/inputrc
cat > /etc/inputrc << "EOF"
# Begin /etc/inputrc

set horizontal-scroll-mode Off
set meta-flag On
set input-meta On
set convert-meta Off
set output-meta On
set bell-style none

"\eOd": backward-word
"\eOc": forward-word
"\e[1~": beginning-of-line
"\e[4~": end-of-line
"\e[5~": beginning-of-history
"\e[6~": end-of-history
"\e[3~": delete-char
"\e[2~": quoted-insert

# End /etc/inputrc
EOF

# /etc/shells
cat > /etc/shells << "EOF"
# Begin /etc/shells

/bin/sh
/bin/bash

# End /etc/shells
EOF

echo "✓ System configuration files created"

#================================================
# Create /etc/fstab
#================================================

echo ""
echo "=== Creating /etc/fstab ==="
echo ""

cat > /etc/fstab << "EOF"
# Begin /etc/fstab

# file system  mount-point    type     options             dump  fsck
#                                                                order

/dev/sda2      /              ext4     defaults            1     1
/dev/sda1      /boot          ext4     defaults            0     2
proc           /proc          proc     nosuid,noexec,nodev 0     0
sysfs          /sys           sysfs    nosuid,noexec,nodev 0     0
devpts         /dev/pts       devpts   gid=5,mode=620      0     0
tmpfs          /run           tmpfs    defaults            0     0
devtmpfs       /dev           devtmpfs mode=0755,nosuid    0     0
tmpfs          /dev/shm       tmpfs    nosuid,nodev        0     0
cgroup2        /sys/fs/cgroup cgroup2  nosuid,noexec,nodev 0     0

# End /etc/fstab
EOF

echo "⚠  IMPORTANT: Edit /etc/fstab to match your actual disk partitions!"
echo ""

#================================================
# Build and Install Linux Kernel
#================================================

echo ""
echo "================================================================"
echo "Building Linux Kernel $KERNEL_VERSION"
echo "================================================================"
echo ""

cd /sources
tar -xf linux-$KERNEL_VERSION.tar.xz
cd linux-$KERNEL_VERSION

make mrproper

# Use a default config or load custom config
if [ -f "/sources/../config/kernel-config-$KERNEL_VERSION" ]; then
    echo "Loading custom kernel configuration..."
    cp /sources/../config/kernel-config-$KERNEL_VERSION .config
else
    echo "Generating default kernel configuration..."
    make defconfig

    # Enable commonly needed options
    scripts/config --enable CONFIG_EXT4_FS
    scripts/config --enable CONFIG_MSDOS_FS
    scripts/config --enable CONFIG_VFAT_FS
    scripts/config --enable CONFIG_PROC_FS
    scripts/config --enable CONFIG_SYSFS
    scripts/config --enable CONFIG_TMPFS
    scripts/config --enable CONFIG_DEVTMPFS
    scripts/config --enable CONFIG_DEVTMPFS_MOUNT
    scripts/config --enable CONFIG_BLK_DEV_SD
    scripts/config --enable CONFIG_SCSI
    scripts/config --enable CONFIG_ATA
    scripts/config --enable CONFIG_SATA_AHCI
    scripts/config --enable CONFIG_USB_SUPPORT
    scripts/config --enable CONFIG_USB_XHCI_HCD
    scripts/config --enable CONFIG_USB_EHCI_HCD
    scripts/config --enable CONFIG_USB_OHCI_HCD
    scripts/config --enable CONFIG_USB_STORAGE
    scripts/config --enable CONFIG_INPUT_KEYBOARD
    scripts/config --enable CONFIG_INPUT_MOUSE
    scripts/config --enable CONFIG_FB
    scripts/config --enable CONFIG_FRAMEBUFFER_CONSOLE
    scripts/config --enable CONFIG_DRM
    scripts/config --enable CONFIG_NETWORK_FILESYSTEMS

    echo "Running make olddefconfig to resolve dependencies..."
    make olddefconfig
fi

echo ""
echo "Building kernel... (this will take 30-60 minutes)"
make -j$(nproc)

echo ""
echo "Installing kernel modules..."
make modules_install

echo ""
echo "Installing kernel..."
cp -iv arch/x86/boot/bzImage /boot/vmlinuz-$KERNEL_VERSION-maruxos
cp -iv System.map /boot/System.map-$KERNEL_VERSION
cp -iv .config /boot/config-$KERNEL_VERSION

install -d /usr/share/doc/linux-$KERNEL_VERSION
cp -r Documentation/* /usr/share/doc/linux-$KERNEL_VERSION

cd /sources
rm -rf linux-$KERNEL_VERSION

echo "✓ Linux kernel $KERNEL_VERSION installed"

#================================================
# Install and Configure GRUB
#================================================

echo ""
echo "================================================================"
echo "Installing GRUB Bootloader"
echo "================================================================"
echo ""

echo "Installing GRUB to /boot/grub..."
grub-install --target=i386-pc /dev/sda

# Generate GRUB configuration
cat > /boot/grub/grub.cfg << EOF
# Begin /boot/grub/grub.cfg
set default=0
set timeout=5

insmod part_gpt
insmod ext2
set root=(hd0,2)

menuentry "$DISTRO_NAME $DISTRO_VERSION - $DISTRO_CODENAME" {
    linux   /boot/vmlinuz-$KERNEL_VERSION-maruxos root=/dev/sda2 ro
}

menuentry "$DISTRO_NAME $DISTRO_VERSION (Recovery Mode)" {
    linux   /boot/vmlinuz-$KERNEL_VERSION-maruxos root=/dev/sda2 ro single
}
EOF

echo "✓ GRUB installed"
echo ""
echo "⚠  IMPORTANT: Verify GRUB configuration in /boot/grub/grub.cfg"
echo "⚠  Adjust root device (/dev/sda2) to match your system!"
echo ""

#================================================
# Create MaruxOS Release Information
#================================================

echo ""
echo "=== Creating MaruxOS release information ==="
echo ""

cat > /etc/maruxos-release << EOF
$DISTRO_NAME $DISTRO_VERSION "$DISTRO_CODENAME"
Kernel: Linux $KERNEL_VERSION
Built: $(date '+%Y-%m-%d %H:%M:%S')
Architecture: $(uname -m)
Build Method: Linux From Scratch (LFS)
EOF

cat > /etc/os-release << EOF
NAME="$DISTRO_NAME"
VERSION="$DISTRO_VERSION ($DISTRO_CODENAME)"
ID=maruxos
ID_LIKE=lfs
VERSION_ID="$DISTRO_VERSION"
PRETTY_NAME="$DISTRO_NAME $DISTRO_VERSION ($DISTRO_CODENAME)"
HOME_URL="https://github.com/marux/maruxos"
SUPPORT_URL="https://github.com/marux/maruxos/issues"
BUG_REPORT_URL="https://github.com/marux/maruxos/issues"
EOF

cat > /etc/lsb-release << EOF
DISTRIB_ID="$DISTRO_NAME"
DISTRIB_RELEASE="$DISTRO_VERSION"
DISTRIB_CODENAME="$DISTRO_CODENAME"
DISTRIB_DESCRIPTION="$DISTRO_NAME $DISTRO_VERSION"
EOF

echo "✓ Release information created"

#================================================
# Set Root Password
#================================================

echo ""
echo "================================================================"
echo "IMPORTANT: Set Root Password"
echo "================================================================"
echo ""
echo "Please set the root password for your MaruxOS system:"
passwd root

#================================================
# Final Summary
#================================================

echo ""
echo "================================================================"
echo "System Configuration Complete!"
echo "================================================================"
echo ""
echo "$DISTRO_NAME $DISTRO_VERSION \"$DISTRO_CODENAME\" is ready!"
echo ""
echo "Kernel: Linux $KERNEL_VERSION"
echo "Bootloader: GRUB"
echo "Architecture: $(uname -m)"
echo ""
echo "Next steps:"
echo "  1. Exit the chroot environment: exit"
echo "  2. Unmount all filesystems"
echo "  3. Reboot into your new $DISTRO_NAME system!"
echo ""
echo "Post-installation tasks:"
echo "  - Create user accounts"
echo "  - Install desktop environment (XFCE)"
echo "  - Configure network for your setup"
echo "  - Install additional software"
echo ""
echo "To create a bootable ISO, run:"
echo "  bash scripts/create-iso.sh"
echo ""
