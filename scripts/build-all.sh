#!/bin/bash
# MaruxOS Master Build Script
# ============================
# This script automates the entire MaruxOS build process
#
# Usage: ./build-all.sh [options]
#   -s, --skip-kernel    Skip kernel build (use existing)
#   -c, --clean          Clean all previous builds
#   -h, --help           Show this help message

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_SCRIPTS="$SCRIPT_DIR/build"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Options
SKIP_KERNEL=false
CLEAN_BUILD=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--skip-kernel)
            SKIP_KERNEL=true
            shift
            ;;
        -c|--clean)
            CLEAN_BUILD=true
            shift
            ;;
        -h|--help)
            echo "MaruxOS Build System"
            echo ""
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  -s, --skip-kernel    Skip kernel build (use existing)"
            echo "  -c, --clean          Clean all previous builds"
            echo "  -h, --help           Show this help message"
            echo ""
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Banner
echo -e "${BLUE}"
echo "╔════════════════════════════════════════╗"
echo "║     MaruxOS Build System v1.0          ║"
echo "║  Automated ISO Builder for MaruxOS     ║"
echo "╚════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# Load configuration
source "$PROJECT_ROOT/config/marux-release.conf"

echo -e "${GREEN}Building: $DISTRO_NAME $DISTRO_VERSION ($DISTRO_CODENAME)${NC}"
echo -e "${GREEN}Kernel: Linux $KERNEL_VERSION $KERNEL_TYPE${NC}"
echo ""

# Clean if requested
if [ "$CLEAN_BUILD" = true ]; then
    echo -e "${YELLOW}Cleaning previous build...${NC}"
    rm -rf "$PROJECT_ROOT/build"
    echo -e "${GREEN}✓ Clean complete${NC}"
    echo ""
fi

# Build steps
STEPS=(
    "00-prepare-environment.sh|Preparing build environment"
    "01-download-kernel.sh|Downloading Linux kernel"
    "02-build-kernel.sh|Building Linux kernel"
    "03-build-rootfs.sh|Building root filesystem"
    "04-install-desktop.sh|Installing desktop environment"
    "05-configure-grub.sh|Configuring GRUB bootloader"
    "06-setup-plymouth.sh|Setting up Plymouth splash"
    "07-setup-installer.sh|Setting up Calamares installer"
    "08-create-live-system.sh|Creating live system"
    "09-build-iso.sh|Building ISO image"
)

CURRENT_STEP=1
TOTAL_STEPS=${#STEPS[@]}

# Skip kernel steps if requested
if [ "$SKIP_KERNEL" = true ]; then
    echo -e "${YELLOW}Skipping kernel download and build${NC}"
    echo ""
    CURRENT_STEP=4
fi

for step_info in "${STEPS[@]}"; do
    SCRIPT="${step_info%%|*}"
    DESCRIPTION="${step_info##*|}"

    # Skip kernel steps if requested
    if [ "$SKIP_KERNEL" = true ]; then
        if [[ "$SCRIPT" == "01-download-kernel.sh" ]] || [[ "$SCRIPT" == "02-build-kernel.sh" ]]; then
            continue
        fi
    fi

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Step $CURRENT_STEP/$TOTAL_STEPS: $DESCRIPTION${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    if [ -f "$BUILD_SCRIPTS/$SCRIPT" ]; then
        bash "$BUILD_SCRIPTS/$SCRIPT"

        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Step $CURRENT_STEP completed successfully${NC}"
        else
            echo -e "${RED}✗ Step $CURRENT_STEP failed${NC}"
            exit 1
        fi
    else
        echo -e "${RED}✗ Script not found: $SCRIPT${NC}"
        exit 1
    fi

    echo ""
    CURRENT_STEP=$((CURRENT_STEP + 1))
done

# Build complete
echo -e "${GREEN}"
echo "╔════════════════════════════════════════╗"
echo "║   MaruxOS Build Complete! 🎉           ║"
echo "╚════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# Show ISO location
ISO_PATH="$PROJECT_ROOT/build/$ISO_NAME"
if [ -f "$ISO_PATH" ]; then
    ISO_SIZE=$(du -h "$ISO_PATH" | cut -f1)
    echo -e "${GREEN}ISO Image: $ISO_PATH${NC}"
    echo -e "${GREEN}Size: $ISO_SIZE${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Test the ISO in a virtual machine (VirtualBox, VMware, etc.)"
    echo "  2. Write to USB: sudo dd if=$ISO_PATH of=/dev/sdX bs=4M status=progress"
    echo "  3. Boot from USB and test installation"
    echo ""
else
    echo -e "${RED}Warning: ISO file not found at expected location${NC}"
fi

echo -e "${BLUE}Thank you for building MaruxOS!${NC}"
echo ""
