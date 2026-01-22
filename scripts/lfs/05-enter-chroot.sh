#!/usr/bin/env bash
# MaruxOS LFS - Enter Chroot Environment
# Helper script to mount virtual filesystems and enter chroot

set -e

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/config/lfs-config.conf"

# LFS directory
LFS="$LFS_ROOTFS"

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: This script must be run as root"
    echo "Please run: sudo bash $0"
    exit 1
fi

echo "========================================"
echo "MaruxOS LFS - Entering Chroot"
echo "========================================"
echo ""

#================================================
# Mount Virtual Kernel File Systems
#================================================
echo "Mounting virtual kernel file systems..."

# Mount /dev
mountpoint -q "$LFS/dev" || mount -v --bind /dev "$LFS/dev"

# Mount virtual kernel file systems
mountpoint -q "$LFS/dev/pts" || mount -v --bind /dev/pts "$LFS/dev/pts"
mountpoint -q "$LFS/proc" || mount -vt proc proc "$LFS/proc"
mountpoint -q "$LFS/sys" || mount -vt sysfs sysfs "$LFS/sys"
mountpoint -q "$LFS/run" || mount -vt tmpfs tmpfs "$LFS/run"

# Some host systems have /dev/shm as symlink to /run/shm
if [ -h "$LFS/dev/shm" ]; then
  install -v -d -m 1777 "$LFS$(realpath /dev/shm)"
else
  mountpoint -q "$LFS/dev/shm" || mount -vt tmpfs -o nosuid,nodev tmpfs "$LFS/dev/shm"
fi

echo "✓ Virtual filesystems mounted"
echo ""

#================================================
# Enter Chroot
#================================================
echo "Entering chroot environment..."
echo ""
echo "You are now in the LFS chroot environment."
echo "To build additional tools, run:"
echo "  bash /sources/../scripts/lfs/06-build-additional-tools.sh"
echo ""
echo "To exit chroot, type: exit"
echo ""

# Create environment setup script
cat > "$LFS/tmp/chroot-env.sh" << EOF
export HOME=/root
export TERM="$TERM"
export PS1='(lfs chroot) \u:\w\$ '
export PATH=/usr/bin:/usr/sbin
export MAKEFLAGS="-j$(nproc)"
export TESTSUITEFLAGS="-j$(nproc)"
export LC_ALL=POSIX
export LFS_TGT=x86_64-maruxos-linux-gnu
set +h
umask 022
cd /
EOF

chroot "$LFS" /usr/bin/bash --login -c "source /tmp/chroot-env.sh && exec bash"

#================================================
# Cleanup on exit
#================================================
echo ""
echo "Exited chroot. Unmounting virtual filesystems..."

# Unmount in reverse order
mountpoint -q "$LFS/dev/shm" && umount -v "$LFS/dev/shm" || true
mountpoint -q "$LFS/run" && umount -v "$LFS/run" || true
mountpoint -q "$LFS/sys" && umount -v "$LFS/sys" || true
mountpoint -q "$LFS/proc" && umount -v "$LFS/proc" || true
mountpoint -q "$LFS/dev/pts" && umount -v "$LFS/dev/pts" || true
mountpoint -q "$LFS/dev" && umount -v "$LFS/dev" || true

echo "✓ Cleanup complete"
