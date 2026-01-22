#!/bin/bash
# MaruxOS Project Verification Script
# ====================================
# Verifies project structure and file integrity

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "======================================"
echo "MaruxOS Project Verification"
echo "======================================"
echo ""

cd "$PROJECT_ROOT"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

# Check function
check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} $1"
    else
        echo -e "${RED}✗${NC} $1 (missing)"
        ((ERRORS++))
    fi
}

check_dir() {
    if [ -d "$1" ]; then
        echo -e "${GREEN}✓${NC} $1/"
    else
        echo -e "${RED}✗${NC} $1/ (missing)"
        ((ERRORS++))
    fi
}

check_executable() {
    if [ -f "$1" ] && [ -x "$1" ]; then
        echo -e "${GREEN}✓${NC} $1 (executable)"
    elif [ -f "$1" ]; then
        echo -e "${YELLOW}⚠${NC} $1 (not executable)"
        ((WARNINGS++))
    else
        echo -e "${RED}✗${NC} $1 (missing)"
        ((ERRORS++))
    fi
}

echo "Checking project structure..."
echo ""

echo "Core directories:"
check_dir "config"
check_dir "kernel"
check_dir "rootfs"
check_dir "bootloader"
check_dir "installer"
check_dir "packages"
check_dir "scripts"
check_dir "docs"
check_dir "MaruxOS 디자인"
echo ""

echo "Configuration files:"
check_file "config/marux-release.conf"
check_file "config/system-defaults.conf"
echo ""

echo "Documentation files:"
check_file "README.md"
check_file "LICENSE"
check_file "CHANGELOG.md"
check_file "CONTRIBUTING.md"
check_file ".gitignore"
check_file "docs/BUILD.md"
check_file "docs/DEVELOPMENT.md"
check_file "docs/FAQ.md"
echo ""

echo "Build scripts:"
check_executable "scripts/build-all.sh"
check_executable "scripts/build/00-prepare-environment.sh"
check_executable "scripts/build/01-download-kernel.sh"
check_executable "scripts/build/02-build-kernel.sh"
check_executable "scripts/build/03-build-rootfs.sh"
check_executable "scripts/build/04-install-desktop.sh"
check_executable "scripts/build/05-configure-grub.sh"
check_executable "scripts/build/06-setup-plymouth.sh"
check_executable "scripts/build/07-setup-installer.sh"
check_executable "scripts/build/08-create-live-system.sh"
check_executable "scripts/build/09-build-iso.sh"
echo ""

echo "Utility scripts:"
check_executable "scripts/utils/clean.sh"
check_executable "scripts/utils/test-vm.sh"
check_executable "scripts/utils/verify-project.sh"
echo ""

echo "Design files:"
check_file "MaruxOS 디자인/marux-logo-64.png"
check_file "MaruxOS 디자인/marux-logo-128.png"
check_file "MaruxOS 디자인/marux-logo-256.png"
check_file "MaruxOS 디자인/marux-logo-512.png"
check_file "MaruxOS 디자인/marux_logo.svg"
check_file "MaruxOS 디자인/marux-desktop.png"
check_file "MaruxOS 디자인/marux-splash.png"
check_file "MaruxOS 디자인/marux-login.png"
check_file "MaruxOS 디자인/kernel-panic.png"
check_file "MaruxOS 디자인/progress-bar.png"
check_file "MaruxOS 디자인/progress-box.png"
echo ""

echo "GRUB configuration:"
check_file "bootloader/grub/grub.cfg"
echo ""

# Summary
echo "======================================"
echo "Verification Summary"
echo "======================================"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ Project structure is complete!${NC}"
    echo ""
    echo "All required files and directories are present."
    echo "You're ready to build MaruxOS!"
    echo ""
    echo "Next steps:"
    echo "  1. Make scripts executable: chmod +x scripts/**/*.sh"
    echo "  2. Read BUILD.md for build instructions"
    echo "  3. Run: ./scripts/build-all.sh"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ Project structure is mostly complete${NC}"
    echo ""
    echo "Warnings: $WARNINGS"
    echo ""
    echo "Some scripts are not executable. Fix with:"
    echo "  chmod +x scripts/**/*.sh"
    exit 0
else
    echo -e "${RED}✗ Project structure has issues${NC}"
    echo ""
    echo "Errors: $ERRORS"
    echo "Warnings: $WARNINGS"
    echo ""
    echo "Please fix the missing files/directories before building."
    exit 1
fi
