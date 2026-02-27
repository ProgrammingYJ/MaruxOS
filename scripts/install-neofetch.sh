#!/bin/bash
# MaruxOS - neofetch Installation Script
# neofetch는 bash 스크립트 하나라 다운로드+설치만 하면 됨

set -e

SQUASHFS_ROOT="${1:-/home/administrator/MaruxOS/build/rootfs-lfs}"

NEOFETCH_VERSION="7.1.0"
NEOFETCH_URL="https://github.com/dylanaraps/neofetch/archive/refs/tags/${NEOFETCH_VERSION}.tar.gz"

echo "==========================================="
echo "  neofetch $NEOFETCH_VERSION Installation"
echo "==========================================="
echo ""

# 이미 설치되어 있는지 확인
if [ -f "$SQUASHFS_ROOT/usr/bin/neofetch" ]; then
    echo "neofetch is already installed at $SQUASHFS_ROOT/usr/bin/neofetch"
    echo "Skipping installation."
    exit 0
fi

SOURCES_DIR="$SQUASHFS_ROOT/sources"
mkdir -p "$SOURCES_DIR"

# 다운로드
echo "[1/3] Downloading neofetch $NEOFETCH_VERSION..."
cd "$SOURCES_DIR"

if [ ! -f "neofetch-${NEOFETCH_VERSION}.tar.gz" ]; then
    wget -O "neofetch-${NEOFETCH_VERSION}.tar.gz" "$NEOFETCH_URL" 2>&1 || {
        echo "ERROR: Failed to download neofetch"
        exit 1
    }
    echo "  Downloaded"
else
    echo "  Source already exists"
fi

# 압축 해제 + 설치
echo "[2/3] Installing neofetch..."
cd "$SOURCES_DIR"
rm -rf "neofetch-${NEOFETCH_VERSION}"
tar -xf "neofetch-${NEOFETCH_VERSION}.tar.gz"

# neofetch 스크립트 + man page 복사
install -m 755 "neofetch-${NEOFETCH_VERSION}/neofetch" "$SQUASHFS_ROOT/usr/bin/neofetch"

mkdir -p "$SQUASHFS_ROOT/usr/share/man/man1"
install -m 644 "neofetch-${NEOFETCH_VERSION}/neofetch.1" "$SQUASHFS_ROOT/usr/share/man/man1/neofetch.1" 2>/dev/null || true

# MaruxOS ASCII 아트 설정 (기본 config)
mkdir -p "$SQUASHFS_ROOT/etc/skel/.config/neofetch"
cat > "$SQUASHFS_ROOT/etc/skel/.config/neofetch/config.conf" << 'NEOCONF'
# neofetch config for MaruxOS

print_info() {
    info title
    info underline

    info "OS" distro
    info "Host" model
    info "Kernel" kernel
    info "Uptime" uptime
    info "Shell" shell
    info "WM" wm
    info "Terminal" term
    info "CPU" cpu
    info "Memory" memory
    info "Disk" disk
    info "Resolution" resolution
    info "Locale" locale

    info cols
}

# ASCII art
ascii_distro="auto"
ascii_bold="on"
NEOCONF

# /etc/os-release 생성 (neofetch가 OS 정보를 읽는 파일)
if [ ! -f "$SQUASHFS_ROOT/etc/os-release" ]; then
    cat > "$SQUASHFS_ROOT/etc/os-release" << 'OSREL'
NAME="MaruxOS"
VERSION="1.2.0"
ID=maruxos
ID_LIKE=lfs
VERSION_ID=1.2.0
PRETTY_NAME="MaruxOS 1.2.0"
HOME_URL="https://github.com/MaruxOS"
OSREL
    echo "  Created /etc/os-release"
fi

# 클린업
cd "$SOURCES_DIR"
rm -rf "neofetch-${NEOFETCH_VERSION}"

# 검증
echo "[3/3] Verifying installation..."
if [ -f "$SQUASHFS_ROOT/usr/bin/neofetch" ]; then
    echo "  neofetch installed successfully at /usr/bin/neofetch"
    ls -la "$SQUASHFS_ROOT/usr/bin/neofetch"
else
    echo "  ERROR: neofetch not found after installation!"
    exit 1
fi

echo ""
echo "==========================================="
echo "  neofetch installation complete!"
echo "==========================================="
