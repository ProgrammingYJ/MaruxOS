#!/bin/bash
set -e
echo "=========================================="
echo "MaruxOS 1.0 Phoenix - ISO Creation"
echo "=========================================="

ROOTFS="build/rootfs-lfs"
ISO_DIR="iso_work"
OUTPUT_DIR="output"
ISO_NAME="MaruxOS-1.0-Phoenix-v16.iso"

rm -rf $ISO_DIR $OUTPUT_DIR
mkdir -p $ISO_DIR/boot/grub/i386-pc $ISO_DIR/live $OUTPUT_DIR

echo "[1/5] Copying kernel..."
cp $ROOTFS/boot/vmlinuz-* $ISO_DIR/boot/vmlinuz 2>/dev/null || cp $ROOTFS/boot/vmlinuz $ISO_DIR/boot/vmlinuz

echo "[2/5] Creating initramfs..."
rm -rf /tmp/initrd
mkdir -p /tmp/initrd/{bin,sbin,dev,proc,sys,mnt,newroot,run,lib,lib64}

# Copy static busybox from rootfs
cp $ROOTFS/bin/busybox /tmp/initrd/bin/busybox
chmod 755 /tmp/initrd/bin/busybox

# Create busybox applet symlinks
for applet in sh ash mount umount mkdir cat echo sleep mknod ls ln cp mv rm losetup blkid findfs modprobe insmod; do
    ln -sf busybox /tmp/initrd/bin/$applet
done
ln -sf ../bin/busybox /tmp/initrd/sbin/init
ln -sf ../bin/busybox /tmp/initrd/sbin/switch_root
ln -sf ../bin/busybox /tmp/initrd/sbin/mount

# Create device nodes
mknod -m 600 /tmp/initrd/dev/console c 5 1
mknod -m 666 /tmp/initrd/dev/null c 1 3
mknod -m 666 /tmp/initrd/dev/zero c 1 5
mknod -m 666 /tmp/initrd/dev/tty c 5 0

# Create init script
cat > /tmp/initrd/init << 'INITEOF'
#!/bin/busybox sh

echo ""
echo "=========================================="
echo " MaruxOS 1.0 Phoenix - Live Boot"
echo "=========================================="
echo ""

# Install busybox symlinks
/bin/busybox --install -s /bin 2>/dev/null
/bin/busybox --install -s /sbin 2>/dev/null

# Mount essential filesystems
echo "Mounting virtual filesystems..."
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs devtmpfs /dev 2>/dev/null || {
    echo "devtmpfs failed, creating devices manually..."
    mknod /dev/console c 5 1
    mknod /dev/null c 1 3
}

# Create device nodes
echo "Creating device nodes..."
mknod /dev/sr0 b 11 0 2>/dev/null
mknod /dev/sr1 b 11 1 2>/dev/null
mknod /dev/loop0 b 7 0 2>/dev/null
mknod /dev/loop1 b 7 1 2>/dev/null

mkdir -p /mnt/cdrom /newroot

echo "Waiting for devices..."
sleep 5

echo ""
echo "Available block devices:"
ls -la /dev/sr* /dev/sd* /dev/hd* /dev/loop* 2>/dev/null || echo "  Checking /sys..."
ls /sys/block/ 2>/dev/null

echo ""
echo "Searching for boot media..."

# Try multiple device paths
FOUND=0
for dev in /dev/sr0 /dev/sr1 /dev/cdrom /dev/hdc /dev/scd0 /dev/sda /dev/sdb; do
    if [ -e "$dev" ]; then
        echo "  Trying $dev..."
        if mount -t iso9660 -o ro "$dev" /mnt/cdrom 2>/dev/null; then
            if [ -f /mnt/cdrom/live/filesystem.squashfs ]; then
                echo "  SUCCESS: Found live filesystem on $dev!"
                FOUND=1
                break
            else
                echo "    No squashfs found, unmounting..."
                ls /mnt/cdrom/ 2>/dev/null
            fi
            umount /mnt/cdrom 2>/dev/null
        else
            echo "    Mount failed"
        fi
    fi
done

if [ "$FOUND" = "1" ]; then
    echo ""
    echo "========== INITRAMFS DEBUG LOG =========="
    echo "Mounting squashfs root filesystem..."

    if mount -t squashfs -o ro /mnt/cdrom/live/filesystem.squashfs /newroot; then
        echo "[OK] Squashfs mounted"

        echo ""
        echo "=== Setting up tmpfs mounts ==="

        echo -n "Mounting /newroot/tmp... "
        if mount -t tmpfs -o mode=1777 tmpfs /newroot/tmp; then
            echo "[OK]"
        else
            echo "[FAILED]"
        fi

        # Start logging to file (now that /newroot/tmp is tmpfs)
        LOGFILE="/newroot/tmp/initramfs-boot.log"
        echo "=== Initramfs Boot Log ===" > $LOGFILE
        echo "Date: $(date 2>/dev/null || echo 'unknown')" >> $LOGFILE
        echo "" >> $LOGFILE

        echo -n "Mounting /newroot/var... "
        if mount -t tmpfs tmpfs /newroot/var; then
            echo "[OK]"
            echo "tmpfs /newroot/var: OK" >> $LOGFILE
        else
            echo "[FAILED]"
            echo "tmpfs /newroot/var: FAILED" >> $LOGFILE
        fi

        echo -n "Mounting /newroot/run... "
        if mount -t tmpfs tmpfs /newroot/run; then
            echo "[OK]"
            echo "tmpfs /newroot/run: OK" >> $LOGFILE
        else
            echo "[FAILED]"
            echo "tmpfs /newroot/run: FAILED" >> $LOGFILE
        fi

        echo -n "Mounting /newroot/root... "
        if mount -t tmpfs tmpfs /newroot/root; then
            echo "[OK]"
            echo "tmpfs /newroot/root: OK" >> $LOGFILE
        else
            echo "[FAILED]"
            echo "tmpfs /newroot/root: FAILED" >> $LOGFILE
        fi

        echo "" >> $LOGFILE
        echo "=== Mounts after tmpfs setup ===" >> $LOGFILE
        mount >> $LOGFILE

        echo ""
        echo "=== Current mounts ==="
        mount | grep newroot

        echo ""
        echo "=== Creating directories ==="
        mkdir -p /newroot/tmp/.X11-unix && echo "[OK] /tmp/.X11-unix"
        chmod 1777 /newroot/tmp/.X11-unix
        mkdir -p /newroot/var/run /newroot/var/log /newroot/var/tmp && echo "[OK] /var subdirs"
        mkdir -p /newroot/var/cache /newroot/var/lib
        mkdir -p /newroot/var/run/dbus /newroot/var/lib/dbus && echo "[OK] dbus dirs"
        chmod 1777 /newroot/var/tmp
        mkdir -p /newroot/run/lock /newroot/run/dbus && echo "[OK] /run subdirs"
        touch /newroot/root/.Xauthority && echo "[OK] .Xauthority created"
        chmod 600 /newroot/root/.Xauthority

        # Copy debug script to accessible location
        cp /debug-boot.sh /newroot/tmp/debug-boot.sh 2>/dev/null || true
        chmod 755 /newroot/tmp/debug-boot.sh 2>/dev/null || true

        echo "" >> $LOGFILE
        echo "=== Directories created ===" >> $LOGFILE
        ls -la /newroot/tmp/ >> $LOGFILE 2>&1
        ls -la /newroot/var/ >> $LOGFILE 2>&1
        ls -la /newroot/run/ >> $LOGFILE 2>&1

        echo ""
        echo "=== Testing write to /newroot/tmp ==="
        if echo "test" > /newroot/tmp/test.txt; then
            echo "[OK] /newroot/tmp is writable"
            echo "Write test: /newroot/tmp is WRITABLE" >> $LOGFILE
            rm /newroot/tmp/test.txt
        else
            echo "[FAILED] /newroot/tmp is NOT writable!"
            echo "Write test: /newroot/tmp is READ-ONLY" >> $LOGFILE
        fi

        # Keep cdrom accessible
        mkdir -p /newroot/mnt/cdrom
        mount --move /mnt/cdrom /newroot/mnt/cdrom 2>/dev/null || mount -o bind /mnt/cdrom /newroot/mnt/cdrom

        echo ""
        echo "=== Switching to new root ==="

        echo "" >> $LOGFILE
        echo "=== Final mount table before switch_root ===" >> $LOGFILE
        mount >> $LOGFILE

        # Move virtual filesystems
        mount --move /proc /newroot/proc 2>/dev/null || true
        mount --move /sys /newroot/sys 2>/dev/null || true
        mount --move /dev /newroot/dev 2>/dev/null || true

        echo ""
        echo "=== Final mount table ==="
        mount

        echo ""
        echo "Log saved to /tmp/initramfs-boot.log"
        echo "After boot, run: /tmp/debug-boot.sh"
        sleep 3

        # Use switch_root (simpler than pivot_root)
        exec switch_root /newroot /sbin/init
    else
        echo "[FAILED] Could not mount squashfs!"
    fi
else
    echo ""
    echo "ERROR: Could not find live filesystem!"
    echo ""
    echo "Debug info:"
    echo "  /proc/partitions:"
    cat /proc/partitions 2>/dev/null
    echo ""
    echo "  dmesg (last 20 lines):"
    dmesg 2>/dev/null | tail -20
fi

echo ""
echo "Dropping to emergency shell..."
echo "Commands: ls, cat, mount, dmesg"
exec sh
INITEOF

# Create post-boot debug script
cat > /tmp/initrd/debug-boot.sh << 'DEBUGEOF'
#!/bin/busybox sh
LOG="/tmp/post-boot-debug.txt"
echo "=== MaruxOS Post-Boot Debug ===" > $LOG
echo "Date: $(date)" >> $LOG
echo "" >> $LOG
echo "=== Current mounts ===" >> $LOG
mount >> $LOG
echo "" >> $LOG
echo "=== /tmp status ===" >> $LOG
ls -la /tmp >> $LOG 2>&1
echo "" >> $LOG
echo "=== Write test ===" >> $LOG
if echo "test" > /tmp/write-test-123.txt 2>&1; then
    echo "/tmp is WRITABLE" >> $LOG
    rm /tmp/write-test-123.txt
else
    echo "/tmp is READ-ONLY" >> $LOG
fi
echo "" >> $LOG
echo "=== /var status ===" >> $LOG
ls -la /var >> $LOG 2>&1
echo "" >> $LOG
echo "=== /run status ===" >> $LOG
ls -la /run >> $LOG 2>&1
echo "" >> $LOG
echo "=== /proc/mounts ===" >> $LOG
cat /proc/mounts >> $LOG 2>&1
echo "" >> $LOG
echo "Debug saved to $LOG"
cat $LOG
DEBUGEOF
chmod 755 /tmp/initrd/debug-boot.sh

chmod 755 /tmp/initrd/init

# Verify init
echo "Init script created:"
ls -la /tmp/initrd/init

# Create initramfs cpio archive
echo "Creating initramfs cpio archive..."
cd /tmp/initrd
find . | cpio -o -H newc 2>/dev/null | gzip -9 > /home/administrator/MaruxOS/$ISO_DIR/boot/initrd.img
cd /home/administrator/MaruxOS

ls -lh $ISO_DIR/boot/initrd.img

echo "[3/5] Creating squashfs..."
# Clear /tmp contents but keep directory (needed as mount point)
rm -rf $ROOTFS/tmp/* 2>/dev/null || true
# Ensure mount point directories exist and are empty
mkdir -p $ROOTFS/tmp $ROOTFS/proc $ROOTFS/sys $ROOTFS/run $ROOTFS/dev/pts $ROOTFS/dev/shm
chmod 1777 $ROOTFS/tmp
# Create squashfs - keep mount point directories, exclude only sources and caches
mksquashfs $ROOTFS $ISO_DIR/live/filesystem.squashfs -comp gzip -e sources -e var/cache -e usr/share/doc -progress
ls -lh $ISO_DIR/live/filesystem.squashfs

echo "[4/5] Creating GRUB config..."
cat > $ISO_DIR/boot/grub/grub.cfg << 'GRUBCFG'
set timeout=10
set default=0

menuentry "MaruxOS 1.0 Phoenix" {
    linux /boot/vmlinuz
    initrd /boot/initrd.img
}

menuentry "MaruxOS 1.0 Phoenix (Debug)" {
    linux /boot/vmlinuz debug
    initrd /boot/initrd.img
}
GRUBCFG

echo "[5/5] Creating ISO..."
cp -r $ROOTFS/usr/lib/grub/i386-pc/* $ISO_DIR/boot/grub/i386-pc/ 2>/dev/null || cp -r /usr/lib/grub/i386-pc/* $ISO_DIR/boot/grub/i386-pc/
grub-mkimage -O i386-pc -o $ISO_DIR/boot/grub/i386-pc/core.img -p /boot/grub biosdisk iso9660 normal search configfile linux echo
cat $ROOTFS/usr/lib/grub/i386-pc/cdboot.img $ISO_DIR/boot/grub/i386-pc/core.img > $ISO_DIR/boot/grub/bios.img 2>/dev/null || cat /usr/lib/grub/i386-pc/cdboot.img $ISO_DIR/boot/grub/i386-pc/core.img > $ISO_DIR/boot/grub/bios.img
xorriso -as mkisofs -o $OUTPUT_DIR/$ISO_NAME -b boot/grub/bios.img -no-emul-boot -boot-load-size 4 -boot-info-table -V "MARUXOS" -R -J $ISO_DIR

echo ""
echo "=========================================="
echo "ISO Created: $OUTPUT_DIR/$ISO_NAME"
ls -lh $OUTPUT_DIR/$ISO_NAME
echo "=========================================="
