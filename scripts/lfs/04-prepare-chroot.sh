#!/usr/bin/env bash
# MaruxOS LFS - Prepare and Enter Chroot Environment
# This prepares the chroot environment for Phase 7

set -e
set -o pipefail

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/config/marux-release.conf"
source "$PROJECT_ROOT/config/lfs-config.conf"
source "$PROJECT_ROOT/config/lfs-versions.conf"

# LFS directory (points to target rootfs)
LFS="$LFS_ROOTFS"

echo "========================================"
echo "MaruxOS LFS - Chroot Environment Setup"
echo "========================================"
echo ""
echo "This will:"
echo "  1. Change ownership to root"
echo "  2. Prepare virtual kernel file systems"
echo "  3. Set up essential directories"
echo "  4. Create essential files"
echo ""

#================================================
# Step 1: Change Ownership to Root
#================================================
echo "=== Step 1: Changing ownership to root ==="
echo ""

# Note: In WSL, we might already be running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: This script must be run as root"
    echo "Please run: sudo bash $0"
    exit 1
fi

echo "Changing ownership of $LFS to root..."
# Create missing directories if they don't exist
mkdir -p "$LFS"/{lib,sbin}
# Change ownership of existing directories
for dir in usr lib var etc bin sbin tools; do
    [ -d "$LFS/$dir" ] && chown -R root:root "$LFS/$dir"
done
case $(uname -m) in
  x86_64)
    mkdir -p "$LFS/lib64"
    # Create dynamic linker symlink
    ln -sfv /usr/lib/ld-linux-x86-64.so.2 "$LFS/lib64/ld-linux-x86-64.so.2"
    chown -R root:root "$LFS/lib64" 2>/dev/null || true
  ;;
esac

echo "✓ Ownership changed to root"
echo ""

#================================================
# Step 2: Prepare Virtual Kernel File Systems
#================================================
echo "=== Step 2: Preparing Virtual Kernel File Systems ==="
echo ""

mkdir -pv "$LFS"/{dev,proc,sys,run}

# Create initial device nodes
echo "Creating initial device nodes..."
if [ ! -e "$LFS/dev/console" ]; then
    mknod -m 600 "$LFS/dev/console" c 5 1
fi
if [ ! -e "$LFS/dev/null" ]; then
    mknod -m 666 "$LFS/dev/null" c 1 3
fi

echo "✓ Virtual kernel file systems prepared"
echo ""

#================================================
# Step 3: Create Essential Directories
#================================================
echo "=== Step 3: Creating essential directories ==="
echo ""

mkdir -pv "$LFS"/{boot,home,mnt,opt,srv}
mkdir -pv "$LFS"/etc/{opt,sysconfig}
mkdir -pv "$LFS"/lib/firmware
mkdir -pv "$LFS"/media/{floppy,cdrom}
mkdir -pv "$LFS"/usr/{,local/}{include,src}
mkdir -pv "$LFS"/usr/local/{bin,lib,sbin}
mkdir -pv "$LFS"/usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -pv "$LFS"/usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -pv "$LFS"/usr/{,local/}share/man/man{1..8}
mkdir -pv "$LFS"/var/{cache,local,log,mail,opt,spool}
mkdir -pv "$LFS"/var/lib/{color,misc,locate}

ln -sfv /run "$LFS/var/run"
ln -sfv /run/lock "$LFS/var/lock"

install -dv -m 0750 "$LFS/root"
install -dv -m 1777 "$LFS/tmp" "$LFS/var/tmp"

echo "✓ Essential directories created"
echo ""

#================================================
# Step 4: Create Essential Files and Symlinks
#================================================
echo "=== Step 4: Creating essential files ==="
echo ""

# Create /etc/hosts
cat > "$LFS/etc/hosts" << EOF
127.0.0.1  localhost $(hostname)
::1        localhost
EOF

# Create /etc/passwd
cat > "$LFS/etc/passwd" << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/usr/bin/false
daemon:x:6:6:Daemon User:/dev/null:/usr/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/run/dbus:/usr/bin/false
systemd-journal-gateway:x:73:73:systemd Journal Gateway:/:/usr/bin/false
systemd-journal-remote:x:74:74:systemd Journal Remote:/:/usr/bin/false
systemd-journal-upload:x:75:75:systemd Journal Upload:/:/usr/bin/false
systemd-network:x:76:76:systemd Network Management:/:/usr/bin/false
systemd-resolve:x:77:77:systemd Resolver:/:/usr/bin/false
systemd-timesync:x:78:78:systemd Time Synchronization:/:/usr/bin/false
systemd-coredump:x:79:79:systemd Core Dumper:/:/usr/bin/false
uuidd:x:80:80:UUID Generation Daemon User:/dev/null:/usr/bin/false
systemd-oom:x:81:81:systemd Out Of Memory Daemon:/:/usr/bin/false
nobody:x:65534:65534:Unprivileged User:/dev/null:/usr/bin/false
EOF

# Create /etc/group
cat > "$LFS/etc/group" << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
systemd-journal:x:23:
input:x:24:
mail:x:34:
kvm:x:61:
systemd-journal-gateway:x:73:
systemd-journal-remote:x:74:
systemd-journal-upload:x:75:
systemd-network:x:76:
systemd-resolve:x:77:
systemd-timesync:x:78:
systemd-coredump:x:79:
uuidd:x:80:
systemd-oom:x:81:
wheel:x:97:
users:x:999:
nogroup:x:65534:
EOF

# Initialize log files
touch "$LFS/var/log"/{btmp,lastlog,faillog,wtmp}
chgrp -v utmp "$LFS/var/log/lastlog"
chmod -v 664  "$LFS/var/log/lastlog"
chmod -v 600  "$LFS/var/log/btmp"

echo "✓ Essential files created"
echo ""

#================================================
# Step 5: Display chroot instructions
#================================================
echo "========================================"
echo "Chroot Environment Ready!"
echo "========================================"
echo ""
echo "The chroot environment is now prepared."
echo ""
echo "To enter chroot, run the following commands:"
echo ""
echo "  sudo chroot \"$LFS\" /usr/bin/env -i   \\"
echo "      HOME=/root                         \\"
echo "      TERM=\"\$TERM\"                     \\"
echo "      PS1='(lfs chroot) \u:\w\$ '        \\"
echo "      PATH=/usr/bin:/usr/sbin            \\"
echo "      MAKEFLAGS=\"-j\$(nproc)\"          \\"
echo "      TESTSUITEFLAGS=\"-j\$(nproc)\"     \\"
echo "      /bin/bash --login"
echo ""
echo "Or use the helper script:"
echo "  sudo bash scripts/lfs/05-enter-chroot.sh"
echo ""
