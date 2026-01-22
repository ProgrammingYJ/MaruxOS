#!/bin/bash
# MaruxOS LFS - Master Build Script
# ==================================
# Automated Linux From Scratch Build

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Banner
echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════╗"
echo "║   MaruxOS LFS Build System                    ║"
echo "║   Linux From Scratch - Full Independence      ║"
echo "╚═══════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# Load configuration
source "$PROJECT_ROOT/config/marux-release.conf"

echo -e "${GREEN}Building: $DISTRO_NAME $DISTRO_VERSION ($DISTRO_CODENAME)${NC}"
echo -e "${GREEN}Kernel: Linux $KERNEL_VERSION LTS${NC}"
echo -e "${YELLOW}Build Method: Linux From Scratch (LFS)${NC}"
echo ""

# Warning
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}WARNING: This is a FULL LFS build!${NC}"
echo ""
echo "  • Estimated time: 10-20 hours"
echo "  • Disk space required: ~100GB"
echo "  • Everything built from source"
echo "  • Cannot be interrupted safely"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

read -p "Continue with LFS build? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Build cancelled"
    exit 0
fi

echo ""

# Build phases
PHASES=(
    "lfs/00-prepare-lfs.sh|Preparing LFS environment"
    "lfs/01-download-sources.sh|Downloading all source packages"
    "lfs/02-build-cross-toolchain.sh|Building cross-compilation toolchain"
    "lfs/03-build-temp-tools.sh|Building temporary tools (Phase 6)"
    "lfs/04-prepare-chroot.sh|Preparing chroot environment (Phase 7)"
)

PHASE_NUM=1
TOTAL_PHASES=${#PHASES[@]}

START_TIME=$(date +%s)

for phase_info in "${PHASES[@]}"; do
    SCRIPT="${phase_info%%|*}"
    DESCRIPTION="${phase_info##*|}"

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Phase $PHASE_NUM/$TOTAL_PHASES: $DESCRIPTION${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT"

    if [ -f "$SCRIPT_PATH" ]; then
        # Make executable
        chmod +x "$SCRIPT_PATH"

        # Run phase
        PHASE_START=$(date +%s)

        bash "$SCRIPT_PATH"

        PHASE_END=$(date +%s)
        PHASE_DURATION=$((PHASE_END - PHASE_START))
        PHASE_MINUTES=$((PHASE_DURATION / 60))

        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Phase $PHASE_NUM completed (${PHASE_MINUTES}m)${NC}"
        else
            echo -e "${RED}✗ Phase $PHASE_NUM failed${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}⚠ Script not found: $SCRIPT${NC}"
        echo -e "${YELLOW}  This phase will be implemented later${NC}"
    fi

    echo ""
    PHASE_NUM=$((PHASE_NUM + 1))
done

END_TIME=$(date +%s)
TOTAL_DURATION=$((END_TIME - START_TIME))
TOTAL_HOURS=$((TOTAL_DURATION / 3600))
TOTAL_MINUTES=$(((TOTAL_DURATION % 3600) / 60))

# Build complete
echo -e "${GREEN}"
echo "╔═══════════════════════════════════════════════╗"
echo "║   MaruxOS LFS Build Complete! 🎉               ║"
echo "╚═══════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${GREEN}Total build time: ${TOTAL_HOURS}h ${TOTAL_MINUTES}m${NC}"
echo ""

# Show results
LFS_ROOT="$PROJECT_ROOT/lfs"

if [ -d "$LFS_ROOT" ]; then
    echo "Build artifacts:"
    echo "  Tools: $LFS_ROOT/tools"
    echo "  Rootfs: $PROJECT_ROOT/build/rootfs-lfs"
    echo "  Kernel: $PROJECT_ROOT/build/kernel/vmlinuz-$KERNEL_VERSION"
    echo ""
fi

echo -e "${BLUE}Next steps:${NC}"
echo "  1. Review build logs for any warnings"
echo "  2. Continue with remaining LFS phases"
echo "  3. Build desktop environment"
echo "  4. Create bootable ISO"
echo ""
