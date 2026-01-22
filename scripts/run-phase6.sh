#!/usr/bin/env bash
# MaruxOS LFS - Run Phase 6 in Chroot
# This script sets up scripts in chroot and executes Phase 6

set -e

cd ~/MaruxOS

# Source configuration
source config/lfs-config.conf
LFS="$LFS_ROOTFS"

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: This script must be run as root"
    echo "Please run: sudo bash $0"
    exit 1
fi

echo "=========================================="
echo "MaruxOS LFS - Phase 6 Setup and Execution"
echo "=========================================="
echo ""

# Step 1: Copy scripts into chroot
echo "=== Step 1: Copying build scripts to chroot ==="
mkdir -p "$LFS/root/scripts"
cp scripts/lfs/06-build-additional-tools.sh "$LFS/root/scripts/"
cp scripts/lfs/07-build-final-system.sh "$LFS/root/scripts/"
cp scripts/lfs/08-system-configuration.sh "$LFS/root/scripts/"
chmod +x "$LFS/root/scripts/"*.sh

echo "✓ Scripts copied:"
ls -lh "$LFS/root/scripts/"
echo ""

# Step 2: Mount virtual filesystems and sources
echo "=== Step 2: Mounting virtual filesystems and sources ==="

# Mount sources directory
mkdir -p "$LFS/sources"
SOURCES_PATH="$PROJECT_ROOT/lfs/sources"
if [ -d "$SOURCES_PATH" ]; then
    mountpoint -q "$LFS/sources" || mount -v --bind "$SOURCES_PATH" "$LFS/sources"
    echo "✓ Sources mounted from $SOURCES_PATH"
else
    echo "WARNING: Sources directory not found at $SOURCES_PATH"
fi

# Mount virtual kernel filesystems
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

echo "✓ All filesystems mounted"
echo ""

# Step 3: Execute Phase 6 in chroot
echo "=== Step 3: Starting Phase 6 build ===""
echo ""
echo "Building additional tools (Gettext, Bison, Perl, Python, Texinfo, Util-linux)..."
echo "This will take approximately 1-2 hours."
echo ""
echo "Log file: /root/phase6-build.log (inside chroot)"
echo ""

# Create chroot environment and run Phase 6
chroot "$LFS" /usr/bin/bash --login << 'CHROOT_EOF'
# Set environment
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

# Change to root directory
cd /root

# Run Phase 6
echo "=========================================="
echo "Executing Phase 6: Build Additional Tools"
echo "=========================================="
echo ""

bash /root/scripts/06-build-additional-tools.sh 2>&1 | tee /root/phase6-build.log

echo ""
echo "=========================================="
echo "Phase 6 Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Review the log: /root/phase6-build.log"
echo "  2. Run Phase 7: bash /root/scripts/07-build-final-system.sh"
echo ""
CHROOT_EOF

# Step 4: Cleanup
echo ""
echo "=== Cleanup: Unmounting filesystems ==="
mountpoint -q "$LFS/dev/shm" && umount -v "$LFS/dev/shm" || true
mountpoint -q "$LFS/run" && umount -v "$LFS/run" || true
mountpoint -q "$LFS/sys" && umount -v "$LFS/sys" || true
mountpoint -q "$LFS/proc" && umount -v "$LFS/proc" || true
mountpoint -q "$LFS/dev/pts" && umount -v "$LFS/dev/pts" || true
mountpoint -q "$LFS/dev" && umount -v "$LFS/dev" || true
mountpoint -q "$LFS/sources" && umount -v "$LFS/sources" || true

echo ""
echo "✓ Phase 6 execution complete!"
echo ""
echo "To continue with Phase 7, run:"
echo "  sudo bash scripts/run-phase7.sh"
echo ""
