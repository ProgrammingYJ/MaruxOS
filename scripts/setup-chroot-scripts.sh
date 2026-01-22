#!/usr/bin/env bash
# Helper script to copy build scripts into chroot and start Phase 6

set -e

cd ~/MaruxOS

echo "=========================================="
echo "Setting up chroot scripts"
echo "=========================================="
echo ""

# Create scripts directory in chroot
echo "Creating /root/scripts directory in chroot..."
sudo mkdir -p build/rootfs-lfs/root/scripts

# Copy Phase 6-8 scripts
echo "Copying build scripts..."
sudo cp scripts/lfs/06-build-additional-tools.sh build/rootfs-lfs/root/scripts/
sudo cp scripts/lfs/07-build-final-system.sh build/rootfs-lfs/root/scripts/
sudo cp scripts/lfs/08-system-configuration.sh build/rootfs-lfs/root/scripts/

# Set execute permissions
echo "Setting permissions..."
sudo chmod +x build/rootfs-lfs/root/scripts/*.sh

# Verify
echo ""
echo "✓ Scripts copied successfully:"
sudo ls -lh build/rootfs-lfs/root/scripts/

echo ""
echo "=========================================="
echo "Scripts are ready!"
echo "=========================================="
echo ""
echo "Now you can enter chroot and run Phase 6:"
echo ""
echo "  sudo bash scripts/lfs/05-enter-chroot.sh"
echo ""
echo "Inside chroot, run:"
echo "  bash /root/scripts/06-build-additional-tools.sh"
echo ""
