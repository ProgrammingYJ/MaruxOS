#!/bin/bash
# Combined script to mount chroot and run Phase 7
set -e

PROJECT_ROOT="/home/administrator/MaruxOS"
source "$PROJECT_ROOT/config/lfs-config.conf"

LFS="$LFS_ROOTFS"

echo "========================================"
echo "Phase 7: Final System Build"
echo "========================================"
echo ""
echo "WARNING: This will build 80+ packages"
echo "Estimated time: 8-15 hours"
echo ""

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: Must be run as root"
    exit 1
fi

# Mount virtual filesystems
echo "=== Mounting virtual filesystems ==="
mountpoint -q "$LFS/dev" || mount -v --bind /dev "$LFS/dev"
mountpoint -q "$LFS/dev/pts" || mount -v --bind /dev/pts "$LFS/dev/pts"
mountpoint -q "$LFS/proc" || mount -vt proc proc "$LFS/proc"
mountpoint -q "$LFS/sys" || mount -vt sysfs sysfs "$LFS/sys"
mountpoint -q "$LFS/run" || mount -vt tmpfs tmpfs "$LFS/run"

if [ -h "$LFS/dev/shm" ]; then
    install -v -d -m 1777 "$LFS$(realpath /dev/shm)"
else
    mountpoint -q "$LFS/dev/shm" || mount -vt tmpfs -o nosuid,nodev tmpfs "$LFS/dev/shm"
fi

echo "✓ Virtual filesystems mounted"
echo ""

# Bind mount sources directory
mkdir -p "$LFS/sources"
mountpoint -q "$LFS/sources" || mount -v --bind "$PROJECT_ROOT/lfs/sources" "$LFS/sources"

# Copy scripts into chroot
mkdir -p "$LFS/scripts/lfs"
cp -v "$PROJECT_ROOT/scripts/lfs/07-build-final-system.sh" "$LFS/scripts/lfs/"
cp -v "$PROJECT_ROOT/config/lfs-versions.conf" "$LFS/tmp/"

echo "=== Entering chroot to build Phase 7 ==="
echo ""

# Run Phase 7 inside chroot
chroot "$LFS" /usr/bin/env -i   \
    HOME=/root                  \
    TERM="$TERM"               \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin:/bin:/sbin     \
    MAKEFLAGS="-j$(nproc)"     \
    /bin/bash --login +h -c "
        set -e
        export LC_ALL=POSIX
        umask 022

        # Source versions
        source /tmp/lfs-versions.conf

        # Run Phase 7 build
        echo 'yes' | bash /scripts/lfs/07-build-final-system.sh

        echo ''
        echo '✓✓✓ Phase 7 Complete! ✓✓✓'
    "

CHROOT_EXIT=$?

# Unmount virtual filesystems
echo ""
echo "=== Unmounting virtual filesystems ==="
mountpoint -q "$LFS/sources" && umount -v "$LFS/sources" || true
mountpoint -q "$LFS/dev/shm" && umount -v "$LFS/dev/shm" || true
mountpoint -q "$LFS/run" && umount -v "$LFS/run" || true
mountpoint -q "$LFS/sys" && umount -v "$LFS/sys" || true
mountpoint -q "$LFS/proc" && umount -v "$LFS/proc" || true
mountpoint -q "$LFS/dev/pts" && umount -v "$LFS/dev/pts" || true
mountpoint -q "$LFS/dev" && umount -v "$LFS/dev" || true

echo "✓ Cleanup complete"
echo ""

exit $CHROOT_EXIT
