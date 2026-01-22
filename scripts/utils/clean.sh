#!/bin/bash
# MaruxOS Clean Script
# ====================
# Removes build artifacts and temporary files

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "======================================"
echo "MaruxOS Build Cleanup"
echo "======================================"
echo ""

echo "This will remove all build artifacts:"
echo "  - $PROJECT_ROOT/build/"
echo ""

read -p "Continue? (y/N): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo "Removing build directory..."
rm -rf "$PROJECT_ROOT/build"

echo "Removing downloaded kernel (optional)..."
read -p "Remove kernel source? (y/N): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf "$PROJECT_ROOT/kernel/source"/*
    echo "✓ Kernel source removed"
fi

echo ""
echo "✓ Cleanup complete!"
echo ""
