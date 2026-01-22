#!/bin/bash
# MaruxOS LFS Build - Prepare Environment
# ========================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/config/marux-release.conf"
source "$PROJECT_ROOT/config/lfs-config.conf"
source "$PROJECT_ROOT/config/lfs-versions.conf"

echo "========================================"
echo "MaruxOS LFS - Environment Preparation"
echo "========================================"
echo ""

# Create LFS directory structure
echo "Creating LFS directory structure..."
mkdir -p "$LFS_ROOT"
mkdir -p "$LFS_SOURCES"
mkdir -p "$LFS_TOOLS"
mkdir -p "$LFS_BUILD"
mkdir -p "$LFS_ROOTFS"

# Create build user (if not exists)
echo "Setting up build environment..."

# Set up environment variables
cat > "$LFS_ROOT/lfs-env.sh" <<'EOF'
# LFS Environment Variables
set +h
umask 022

export LFS_TGT="x86_64-maruxos-linux-gnu"
export LC_ALL=POSIX
export PATH=/tools/bin:/bin:/usr/bin

export MAKEFLAGS="-j$(nproc)"
EOF

echo "✓ LFS directory structure created"
echo ""

# Check required host tools
echo "Checking required host tools..."

REQUIRED_TOOLS=(
    "bash"
    "gcc"
    "g++"
    "make"
    "bison"
    "gawk"
    "m4"
    "patch"
    "perl"
    "python3"
    "tar"
    "gzip"
    "bzip2"
    "xz"
    "wget"
    "curl"
)

MISSING_TOOLS=()

for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        MISSING_TOOLS+=("$tool")
        echo "  ✗ $tool - NOT FOUND"
    else
        echo "  ✓ $tool"
    fi
done

echo ""

if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    echo "Missing required tools: ${MISSING_TOOLS[*]}"
    echo "Please install them first:"
    echo "  sudo apt install build-essential bison gawk m4 texinfo python3 wget curl"
    exit 1
fi

echo "✓ All required host tools are present"
echo ""

# Display configuration
echo "LFS Configuration:"
echo "  Target: $LFS_TGT"
echo "  Root: $LFS_ROOT"
echo "  Sources: $LFS_SOURCES"
echo "  Tools: $LFS_TOOLS"
echo "  Rootfs: $LFS_ROOTFS"
echo "  Init: $INIT_SYSTEM"
echo "  Desktop: $DESKTOP_ENV"
echo "  CPU Cores: $(nproc)"
echo ""

# Disk space check
AVAILABLE_SPACE=$(df -BG "$PROJECT_ROOT" | tail -1 | awk '{print $4}' | sed 's/G//')
echo "Available disk space: ${AVAILABLE_SPACE}GB"

if [ "$AVAILABLE_SPACE" -lt 100 ]; then
    echo "⚠️  Warning: Less than 100GB available. LFS build may fail."
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""
echo "✓ LFS environment preparation complete!"
echo ""
echo "Next step: Run ./01-download-sources.sh"
echo ""
