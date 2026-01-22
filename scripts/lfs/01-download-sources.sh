#!/bin/bash
# MaruxOS LFS Build - Download Source Packages
# =============================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/config/marux-release.conf"
source "$PROJECT_ROOT/config/lfs-config.conf"
source "$PROJECT_ROOT/config/lfs-versions.conf"

echo "========================================"
echo "MaruxOS LFS - Downloading Sources"
echo "========================================"
echo ""

cd "$LFS_SOURCES"

# Download function
download_package() {
    local NAME=$1
    local VERSION=$2
    local URL=$3
    local FILENAME="${NAME}-${VERSION}.tar.xz"

    if [ -f "$FILENAME" ] || [ -f "${FILENAME%.xz}.gz" ] || [ -f "${FILENAME%.xz}.bz2" ]; then
        echo "  ✓ $NAME $VERSION (already downloaded)"
        return 0
    fi

    echo "  ⬇  Downloading $NAME $VERSION..."
    wget -q --show-progress -c "$URL" -O "$FILENAME" || {
        # Try .tar.gz
        FILENAME="${NAME}-${VERSION}.tar.gz"
        wget -q --show-progress -c "${URL%.xz}.gz" -O "$FILENAME" || {
            # Try .tar.bz2
            FILENAME="${NAME}-${VERSION}.tar.bz2"
            wget -q --show-progress -c "${URL%.xz}.bz2" -O "$FILENAME" || {
                echo "  ✗ Failed to download $NAME"
                return 1
            }
        }
    }

    echo "  ✓ $NAME $VERSION downloaded"
}

echo "Downloading core toolchain..."
echo ""

# Core Toolchain
download_package "binutils" "$BINUTILS_VERSION" "$GNU_URL/binutils/binutils-$BINUTILS_VERSION.tar.xz"
download_package "gcc" "$GCC_VERSION" "$GNU_URL/gcc/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.xz"
download_package "glibc" "$GLIBC_VERSION" "$GNU_URL/glibc/glibc-$GLIBC_VERSION.tar.xz"
download_package "gmp" "$GMP_VERSION" "$GNU_URL/gmp/gmp-$GMP_VERSION.tar.xz"
download_package "mpfr" "$MPFR_VERSION" "$GNU_URL/mpfr/mpfr-$MPFR_VERSION.tar.xz"
download_package "mpc" "$MPC_VERSION" "$GNU_URL/mpc/mpc-$MPC_VERSION.tar.gz"

echo ""
echo "Downloading build tools..."
echo ""

download_package "make" "$MAKE_VERSION" "$GNU_URL/make/make-$MAKE_VERSION.tar.gz"
download_package "m4" "$M4_VERSION" "$GNU_URL/m4/m4-$M4_VERSION.tar.xz"

echo ""
echo "Downloading core utilities..."
echo ""

download_package "bash" "$BASH_VERSION" "$GNU_URL/bash/bash-$BASH_VERSION.tar.gz"
download_package "coreutils" "$COREUTILS_VERSION" "$GNU_URL/coreutils/coreutils-$COREUTILS_VERSION.tar.xz"
download_package "diffutils" "$DIFFUTILS_VERSION" "$GNU_URL/diffutils/diffutils-$DIFFUTILS_VERSION.tar.xz"
download_package "findutils" "$FINDUTILS_VERSION" "$GNU_URL/findutils/findutils-$FINDUTILS_VERSION.tar.xz"
download_package "gawk" "$GAWK_VERSION" "$GNU_URL/gawk/gawk-$GAWK_VERSION.tar.xz"
download_package "grep" "$GREP_VERSION" "$GNU_URL/grep/grep-$GREP_VERSION.tar.xz"
download_package "sed" "$SED_VERSION" "$GNU_URL/sed/sed-$SED_VERSION.tar.xz"
download_package "tar" "$TAR_VERSION" "$GNU_URL/tar/tar-$TAR_VERSION.tar.xz"

echo ""
echo "Downloading compression tools..."
echo ""

download_package "gzip" "$GZIP_VERSION" "$GNU_URL/gzip/gzip-$GZIP_VERSION.tar.xz"
download_package "bzip2" "$BZIP2_VERSION" "https://sourceware.org/pub/bzip2/bzip2-$BZIP2_VERSION.tar.gz"
download_package "xz" "$XZ_VERSION" "https://tukaani.org/xz/xz-$XZ_VERSION.tar.gz"
download_package "zstd" "$ZSTD_VERSION" "https://github.com/facebook/zstd/releases/download/v$ZSTD_VERSION/zstd-$ZSTD_VERSION.tar.gz"

echo ""
echo "✓ All source packages downloaded!"
echo ""

# Calculate total size
TOTAL_SIZE=$(du -sh . | cut -f1)
echo "Total download size: $TOTAL_SIZE"
echo ""

# Create MD5SUMS file for verification
echo "Creating checksums..."
md5sum *.tar.* > MD5SUMS 2>/dev/null || true
echo "✓ Checksums created"
echo ""

echo "Next step: Run ./02-build-cross-toolchain.sh"
echo ""
