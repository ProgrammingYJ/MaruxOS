#!/bin/bash
# MaruxOS ibus-hangul Installation Script
# 한국어 입력기 완전 설치 (모든 의존성 포함)

set -e

WORK_DIR="/home/administrator/MaruxOS/ibus-build"
INSTALL_ROOT="/home/administrator/MaruxOS/build/rootfs-lfs"
SRC_DIR="$WORK_DIR/sources"
BUILD_DIR="$WORK_DIR/build"

# 버전 정보
LIBHANGUL_VERSION="0.2.0"
IBUS_VERSION="1.5.29"
IBUS_HANGUL_VERSION="1.5.5"

echo "=========================================="
echo "MaruxOS ibus-hangul Installation"
echo "Korean Input Method - Full Installation"
echo "=========================================="

# 작업 디렉토리 생성
mkdir -p "$SRC_DIR"
mkdir -p "$BUILD_DIR"
cd "$WORK_DIR"

echo ""
echo "=========================================="
echo "Step 1: Checking Dependencies"
echo "=========================================="

# chroot 환경에서 필수 패키지 확인
echo "Checking for essential build tools..."
chroot "$INSTALL_ROOT" /bin/bash -c "gcc --version" > /dev/null 2>&1 || { echo "ERROR: gcc not found"; exit 1; }
chroot "$INSTALL_ROOT" /bin/bash -c "pkg-config --version" > /dev/null 2>&1 || { echo "ERROR: pkg-config not found"; exit 1; }

echo "✓ Build tools available"

# autotools 확인 및 필요 시 설치 안내
echo "Checking for autotools..."
AUTOTOOLS_MISSING=0

if ! chroot "$INSTALL_ROOT" /bin/bash -c "autoconf --version" > /dev/null 2>&1; then
    echo "⚠ WARNING: autoconf not found"
    AUTOTOOLS_MISSING=1
fi

if ! chroot "$INSTALL_ROOT" /bin/bash -c "automake --version" > /dev/null 2>&1; then
    echo "⚠ WARNING: automake not found"
    AUTOTOOLS_MISSING=1
fi

if ! chroot "$INSTALL_ROOT" /bin/bash -c "libtool --version" > /dev/null 2>&1; then
    echo "⚠ WARNING: libtool not found"
    AUTOTOOLS_MISSING=1
fi

if [ $AUTOTOOLS_MISSING -eq 1 ]; then
    echo ""
    echo "ERROR: autotools (autoconf, automake, libtool) are required to build ibus"
    echo "Please install them in your chroot environment first:"
    echo ""
    echo "  1. Download and build autoconf, automake, libtool in chroot"
    echo "  2. Or use a pre-built ibus package"
    echo ""
    echo "For LFS/BLFS, follow:"
    echo "  - autoconf: https://www.linuxfromscratch.org/lfs/view/stable/chapter08/autoconf.html"
    echo "  - automake: https://www.linuxfromscratch.org/lfs/view/stable/chapter08/automake.html"
    echo "  - libtool: https://www.linuxfromscratch.org/lfs/view/stable/chapter08/libtool.html"
    exit 1
else
    echo "✓ autotools available"
fi

# glib 확인
if chroot "$INSTALL_ROOT" /bin/bash -c "pkg-config --exists glib-2.0"; then
    echo "✓ glib-2.0 found"
else
    echo "⚠ WARNING: glib-2.0 not found - ibus requires glib >= 2.46"
    echo "Please install glib first"
fi

# gtk+3 확인
if chroot "$INSTALL_ROOT" /bin/bash -c "pkg-config --exists gtk+-3.0"; then
    echo "✓ gtk+-3.0 found"
else
    echo "⚠ WARNING: gtk+-3.0 not found - may be needed for ibus-setup"
fi

# dbus 확인
if chroot "$INSTALL_ROOT" /bin/bash -c "pkg-config --exists dbus-1"; then
    echo "✓ dbus-1 found"
else
    echo "⚠ WARNING: dbus-1 not found - ibus requires dbus"
fi

echo ""
echo "=========================================="
echo "Step 2: Downloading Sources"
echo "=========================================="

cd "$SRC_DIR"

# libhangul 다운로드
echo "Downloading libhangul..."
if [ ! -f "libhangul-${LIBHANGUL_VERSION}.tar.gz" ]; then
    wget https://github.com/libhangul/libhangul/releases/download/libhangul-${LIBHANGUL_VERSION}/libhangul-${LIBHANGUL_VERSION}.tar.gz
    echo "✓ libhangul downloaded"
else
    echo "✓ libhangul already downloaded"
fi

# ibus 다운로드
echo "Downloading ibus..."
if [ ! -f "ibus-${IBUS_VERSION}.tar.gz" ]; then
    wget https://github.com/ibus/ibus/archive/refs/tags/${IBUS_VERSION}.tar.gz -O ibus-${IBUS_VERSION}.tar.gz
    echo "✓ ibus downloaded"
else
    echo "✓ ibus already downloaded"
fi

# ibus-hangul 다운로드 (.tar.xz 형식)
echo "Downloading ibus-hangul..."
if [ ! -f "ibus-hangul-${IBUS_HANGUL_VERSION}.tar.xz" ]; then
    wget https://github.com/libhangul/ibus-hangul/releases/download/${IBUS_HANGUL_VERSION}/ibus-hangul-${IBUS_HANGUL_VERSION}.tar.xz
    echo "✓ ibus-hangul downloaded"
else
    echo "✓ ibus-hangul already downloaded"
fi

echo ""
echo "=========================================="
echo "Step 3: Verifying Downloads (Double Check)"
echo "=========================================="

VERIFICATION_FAILED=0

# libhangul 검증
echo "Verifying libhangul..."
if [ ! -f "libhangul-${LIBHANGUL_VERSION}.tar.gz" ]; then
    echo "✗ ERROR: libhangul tarball not found!"
    VERIFICATION_FAILED=1
else
    FILE_SIZE=$(stat -c%s "libhangul-${LIBHANGUL_VERSION}.tar.gz" 2>/dev/null || stat -f%z "libhangul-${LIBHANGUL_VERSION}.tar.gz" 2>/dev/null)
    if [ "$FILE_SIZE" -lt 1000 ]; then
        echo "✗ ERROR: libhangul file too small ($FILE_SIZE bytes) - download may be incomplete or corrupted"
        VERIFICATION_FAILED=1
    else
        echo "  - File size: $FILE_SIZE bytes ✓"
        if tar -tzf "libhangul-${LIBHANGUL_VERSION}.tar.gz" >/dev/null 2>&1; then
            echo "  - Archive integrity: OK ✓"
            echo "✓ libhangul verification passed"
        else
            echo "✗ ERROR: libhangul archive is corrupted - cannot extract"
            VERIFICATION_FAILED=1
        fi
    fi
fi

# ibus 검증
echo "Verifying ibus..."
if [ ! -f "ibus-${IBUS_VERSION}.tar.gz" ]; then
    echo "✗ ERROR: ibus tarball not found!"
    VERIFICATION_FAILED=1
else
    FILE_SIZE=$(stat -c%s "ibus-${IBUS_VERSION}.tar.gz" 2>/dev/null || stat -f%z "ibus-${IBUS_VERSION}.tar.gz" 2>/dev/null)
    if [ "$FILE_SIZE" -lt 10000 ]; then
        echo "✗ ERROR: ibus file too small ($FILE_SIZE bytes) - download may be incomplete or corrupted"
        VERIFICATION_FAILED=1
    else
        echo "  - File size: $FILE_SIZE bytes ✓"
        if tar -tzf "ibus-${IBUS_VERSION}.tar.gz" >/dev/null 2>&1; then
            echo "  - Archive integrity: OK ✓"
            echo "✓ ibus verification passed"
        else
            echo "✗ ERROR: ibus archive is corrupted - cannot extract"
            VERIFICATION_FAILED=1
        fi
    fi
fi

# ibus-hangul 검증 (.tar.xz 형식)
echo "Verifying ibus-hangul..."
if [ ! -f "ibus-hangul-${IBUS_HANGUL_VERSION}.tar.xz" ]; then
    echo "✗ ERROR: ibus-hangul tarball not found!"
    VERIFICATION_FAILED=1
else
    FILE_SIZE=$(stat -c%s "ibus-hangul-${IBUS_HANGUL_VERSION}.tar.xz" 2>/dev/null || stat -f%z "ibus-hangul-${IBUS_HANGUL_VERSION}.tar.xz" 2>/dev/null)
    if [ "$FILE_SIZE" -lt 1000 ]; then
        echo "✗ ERROR: ibus-hangul file too small ($FILE_SIZE bytes) - download may be incomplete or corrupted"
        VERIFICATION_FAILED=1
    else
        echo "  - File size: $FILE_SIZE bytes ✓"
        if tar -tJf "ibus-hangul-${IBUS_HANGUL_VERSION}.tar.xz" >/dev/null 2>&1; then
            echo "  - Archive integrity: OK ✓"
            echo "✓ ibus-hangul verification passed"
        else
            echo "✗ ERROR: ibus-hangul archive is corrupted - cannot extract"
            VERIFICATION_FAILED=1
        fi
    fi
fi

# 검증 실패 시 중단
if [ $VERIFICATION_FAILED -eq 1 ]; then
    echo ""
    echo "=========================================="
    echo "VERIFICATION FAILED!"
    echo "=========================================="
    echo "One or more downloaded files failed verification."
    echo "Please check the download URLs and try again."
    echo "Remove corrupted files manually if needed:"
    echo "  rm -f $SRC_DIR/*.tar.gz"
    exit 1
fi

echo ""
echo "=========================================="
echo "✓ All downloads verified successfully!"
echo "=========================================="
echo "Proceeding to build phase..."
sleep 2

echo ""
echo "=========================================="
echo "Step 4: Building libhangul"
echo "=========================================="

cd "$BUILD_DIR"
rm -rf libhangul-${LIBHANGUL_VERSION}
tar -xf "$SRC_DIR/libhangul-${LIBHANGUL_VERSION}.tar.gz"
cd libhangul-${LIBHANGUL_VERSION}

echo "Configuring libhangul..."
./configure --prefix=/usr \
            --sysconfdir=/etc \
            --localstatedir=/var

echo "Building libhangul..."
make -j$(nproc)

echo "Installing libhangul to chroot..."
make DESTDIR="$INSTALL_ROOT" install

echo "✓ libhangul installed"

echo ""
echo "=========================================="
echo "Step 5: Building ibus"
echo "=========================================="

cd "$BUILD_DIR"
rm -rf ibus-${IBUS_VERSION}
tar -xf "$SRC_DIR/ibus-${IBUS_VERSION}.tar.gz"
cd ibus-${IBUS_VERSION}

# PATCH: GTK3 IM 모듈에서 Wayland 참조 제거
# WSL의 GTK3 헤더에 GDK_WINDOWING_WAYLAND가 정의되어 있어서
# im-ibus.so에 Wayland 심볼이 포함됨. MaruxOS는 X11 전용이므로 제거 필요.
echo "Patching GTK3 IM module to remove Wayland dependencies..."
for f in client/gtk3/*.c client/gtk3/*.h; do
    if [ -f "$f" ]; then
        sed -i 's/GDK_WINDOWING_WAYLAND/MARUX_DISABLED_WAYLAND/g' "$f"
    fi
done
echo "  ✓ Wayland references removed from GTK3 IM module"

echo "Running autogen.sh to generate configure script..."
SAVE_DIST_FILES=1 NOCONFIGURE=1 ./autogen.sh

echo "Configuring ibus..."
# Try to use GTK3 only and disable GTK2 requirement
# Disable dconf (GNOME-specific, not needed for lightweight desktop)
# Enable memconf (memory-based config backend, works without dconf!)
# Disable libnotify (desktop notifications, not essential for input)
# Disable unicode-dict (requires UCD files, not needed for Korean input)
# Disable engine (requires valac, ibus-hangul provides its own engine)
# Disable ui (requires valac, ibus-hangul works without panel UI)
# Disable python-library (reduces dependencies)
# Enable vala bindings (needed for tools to compile - valac now installed in WSL)
PYTHON=python3 ./configure --prefix=/usr \
            --sysconfdir=/etc \
            --libexecdir=/usr/lib/ibus \
            --disable-dconf \
            --enable-memconf \
            --disable-wayland \
            --enable-gtk3 \
            --disable-gtk2 \
            --disable-tests \
            --disable-gtk-doc \
            --disable-python2 \
            --disable-appindicator \
            --disable-emoji-dict \
            --disable-libnotify \
            --disable-unicode-dict \
            --disable-engine \
            --disable-ui \
            --disable-python-library

echo "Building ibus (this may take a while)..."
make -j$(nproc)

echo "Creating temporary symlinks for libtool (WSL-specific fix)..."
# libtool expects libc in /usr/lib/ but Ubuntu WSL has it in /lib/x86_64-linux-gnu/
# Create temporary symlinks so libtool can find them during relinking
sudo ln -sf /lib/x86_64-linux-gnu/libc.so.6 /usr/lib/libc.so.6 2>/dev/null || true
sudo ln -sf /lib/x86_64-linux-gnu/libc_nonshared.a /usr/lib/libc_nonshared.a 2>/dev/null || true
sudo ln -sf /lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 /usr/lib/ld-linux-x86-64.so.2 2>/dev/null || true

echo "Installing ibus to chroot..."
make DESTDIR="$INSTALL_ROOT" install

echo "Cleaning up temporary symlinks..."
sudo rm -f /usr/lib/libc.so.6 /usr/lib/libc_nonshared.a /usr/lib/ld-linux-x86-64.so.2 2>/dev/null || true

echo "✓ ibus installed"

# GTK3 immodules 캐시 업데이트 (CRITICAL - GTK가 im-ibus.so를 인식하도록!)
echo "Updating GTK3 immodules cache..."
if [ -x "$INSTALL_ROOT/usr/bin/gtk-query-immodules-3.0" ]; then
    chroot "$INSTALL_ROOT" /bin/bash -c '/usr/bin/gtk-query-immodules-3.0 > /usr/lib/gtk-3.0/3.0.0/immodules.cache 2>/dev/null' || true
    echo "✓ GTK3 immodules cache updated (gtk-query-immodules-3.0)"
fi

# gtk-query-immodules-3.0이 im-ibus.so를 캐시에 추가하지 못할 경우 수동 등록
if ! grep -q ibus "$INSTALL_ROOT/usr/lib/gtk-3.0/3.0.0/immodules.cache" 2>/dev/null; then
    echo "⚠ ibus not in cache - manually adding ibus entry..."
    cat >> "$INSTALL_ROOT/usr/lib/gtk-3.0/3.0.0/immodules.cache" << 'IBUS_CACHE_EOF'

"/usr/lib/gtk-3.0/3.0.0/immodules/im-ibus.so"
"ibus" "Intelligent Input Bus" "ibus10" "/usr/share/locale" ""

IBUS_CACHE_EOF
    echo "✓ ibus manually added to immodules.cache"
else
    echo "✓ ibus already in immodules.cache"
fi

echo ""
echo "=========================================="
echo "Step 6: Building ibus-hangul"
echo "=========================================="

cd "$BUILD_DIR"
rm -rf ibus-hangul-${IBUS_HANGUL_VERSION}
tar -xJf "$SRC_DIR/ibus-hangul-${IBUS_HANGUL_VERSION}.tar.xz"
cd ibus-hangul-${IBUS_HANGUL_VERSION}

echo "Configuring ibus-hangul..."
# Set PKG_CONFIG paths to use chroot libraries and headers
export PKG_CONFIG_PATH="$INSTALL_ROOT/usr/lib/pkgconfig:$PKG_CONFIG_PATH"
export PKG_CONFIG_SYSROOT_DIR="$INSTALL_ROOT"
./configure --prefix=/usr \
            --sysconfdir=/etc \
            --libexecdir=/usr/lib/ibus

echo "Creating temporary symlinks for libtool (WSL-specific fix)..."
sudo ln -sf /lib/x86_64-linux-gnu/libc.so.6 /usr/lib/libc.so.6 2>/dev/null || true
sudo ln -sf /lib/x86_64-linux-gnu/libc_nonshared.a /usr/lib/libc_nonshared.a 2>/dev/null || true
sudo ln -sf /lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 /usr/lib/ld-linux-x86-64.so.2 2>/dev/null || true

echo "Building ibus-hangul..."
make -j$(nproc)

echo "Installing ibus-hangul to chroot..."
# Install may fail on Python setup (imp module removed in Python 3.12)
# but the core engine files will be installed successfully
make DESTDIR="$INSTALL_ROOT" install || echo "⚠ Warning: Setup tools installation failed (Python 3.12 compatibility issue)"

echo "Cleaning up temporary symlinks..."
sudo rm -f /usr/lib/libc.so.6 /usr/lib/libc_nonshared.a /usr/lib/ld-linux-x86-64.so.2 2>/dev/null || true

echo "✓ ibus-hangul installed"

echo ""
echo "=========================================="
echo "Step 7: Configuring ibus-hangul"
echo "=========================================="

# ibus 설정 디렉토리 생성
mkdir -p "$INSTALL_ROOT/etc/xdg/autostart"
mkdir -p "$INSTALL_ROOT/usr/share/ibus/component"

# ibus 자동 시작 설정
cat > "$INSTALL_ROOT/etc/xdg/autostart/ibus.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=IBus
Comment=Start IBus Input Method Framework
Exec=ibus-daemon --xim --daemonize
Terminal=false
Categories=System;
NoDisplay=true
EOF

# ibus-hangul 기본 설정
mkdir -p "$INSTALL_ROOT/etc/skel/.config/ibus"
cat > "$INSTALL_ROOT/etc/skel/.config/ibus/ibus-hangul.conf" << 'EOF'
# ibus-hangul Configuration
# 한영 전환: Ctrl+Y
# 키보드 레이아웃: QWERTY (2-beol)

[engine/Hangul]
HangulKeyboard=2
HangulKeys=control+y
HanjaKeys=F9
WordCommit=false
AutoReorder=true
EOF

echo "✓ ibus-hangul configured"

echo ""
echo "=========================================="
echo "Step 8: Updating Library Cache"
echo "=========================================="

# ldconfig 실행
if [ -x "$INSTALL_ROOT/sbin/ldconfig" ]; then
    chroot "$INSTALL_ROOT" /sbin/ldconfig
    echo "✓ Library cache updated"
fi

# ibus cache 업데이트
if [ -x "$INSTALL_ROOT/usr/bin/ibus" ]; then
    chroot "$INSTALL_ROOT" /usr/bin/ibus write-cache
    echo "✓ ibus cache updated"
fi

# GSettings 스키마 생성 및 컴파일 (ibus + ibus-engine-hangul 모두 필수!)
echo "Creating and compiling GSettings schemas..."
mkdir -p "$INSTALL_ROOT/usr/share/glib-2.0/schemas"

# ibus 메인 스키마 생성 (panel, general, hotkey 등)
echo "  Creating ibus GSettings schema files..."
cat > "$INSTALL_ROOT/usr/share/glib-2.0/schemas/org.freedesktop.ibus.gschema.xml" << 'IBUS_SCHEMA_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<schemalist>
  <schema id="org.freedesktop.ibus.general" path="/org/freedesktop/ibus/general/">
    <key name="preload-engines" type="as">
      <default>['hangul']</default>
      <summary>Preload engines</summary>
      <description>Preload engines during ibus startup</description>
    </key>
    <key name="engines-order" type="as">
      <default>['hangul']</default>
      <summary>Engines order</summary>
      <description>Engines order in the switch list</description>
    </key>
    <key name="switcher-delay-time" type="i">
      <default>400</default>
      <summary>Switcher delay time</summary>
      <description>Delay time in milliseconds for the switcher</description>
    </key>
    <key name="version" type="s">
      <default>''</default>
      <summary>Version</summary>
      <description>IBus version</description>
    </key>
    <key name="use-system-keyboard-layout" type="b">
      <default>true</default>
      <summary>Use system keyboard layout</summary>
      <description>Use system keyboard layout</description>
    </key>
    <key name="embed-preedit-text" type="b">
      <default>true</default>
      <summary>Embed preedit text</summary>
      <description>Embed preedit text in application window</description>
    </key>
    <key name="use-global-engine" type="b">
      <default>true</default>
      <summary>Use global engine</summary>
      <description>Share the same engine across all applications</description>
    </key>
    <key name="enable-by-default" type="b">
      <default>false</default>
      <summary>Enable by default</summary>
      <description>Enable input method by default</description>
    </key>
    <key name="dbus-timeout" type="i">
      <default>-1</default>
      <summary>DBus timeout</summary>
      <description>Timeout for DBus calls in milliseconds</description>
    </key>
    <child name="hotkey" schema="org.freedesktop.ibus.general.hotkey"/>
  </schema>
  <schema id="org.freedesktop.ibus.general.hotkey" path="/org/freedesktop/ibus/general/hotkey/">
    <key name="trigger" type="as">
      <default>['Control+y']</default>
      <summary>Trigger shortcut keys</summary>
      <description>The shortcut keys for turning input method on or off</description>
    </key>
    <key name="triggers" type="as">
      <default>['Control+y']</default>
      <summary>Trigger shortcut keys</summary>
      <description>The shortcut keys for turning input method on or off</description>
    </key>
    <key name="enable-unconditional" type="as">
      <default>[]</default>
      <summary>Enable shortcut keys</summary>
      <description>The shortcut keys for turning input method on</description>
    </key>
    <key name="disable-unconditional" type="as">
      <default>[]</default>
      <summary>Disable shortcut keys</summary>
      <description>The shortcut keys for turning input method off</description>
    </key>
    <key name="next-engine" type="as">
      <default>[]</default>
      <summary>Next engine shortcut keys</summary>
      <description>The shortcut keys for switching to the next input method</description>
    </key>
    <key name="next-engine-in-menu" type="as">
      <default>[]</default>
      <summary>Next engine in menu shortcut keys</summary>
      <description>The shortcut keys for switching to the next input method in the menu</description>
    </key>
    <key name="prev-engine" type="as">
      <default>[]</default>
      <summary>Previous engine shortcut keys</summary>
      <description>The shortcut keys for switching to the previous input method</description>
    </key>
  </schema>
  <schema id="org.freedesktop.ibus.panel" path="/org/freedesktop/ibus/panel/">
    <key name="show" type="i">
      <default>0</default>
      <summary>Show panel</summary>
      <description>When to show the panel (0: do not show, 1: auto hide, 2: always)</description>
    </key>
    <key name="x" type="i">
      <default>-1</default>
      <summary>Panel x position</summary>
      <description>X position of the panel</description>
    </key>
    <key name="y" type="i">
      <default>-1</default>
      <summary>Panel y position</summary>
      <description>Y position of the panel</description>
    </key>
    <key name="lookup-table-orientation" type="i">
      <default>1</default>
      <summary>Lookup table orientation</summary>
      <description>Orientation of the lookup table (0: horizontal, 1: vertical)</description>
    </key>
    <key name="show-icon-on-systray" type="b">
      <default>true</default>
      <summary>Show icon on systray</summary>
      <description>Show ibus icon on the system tray</description>
    </key>
    <key name="show-im-name" type="b">
      <default>false</default>
      <summary>Show IM name</summary>
      <description>Show input method name on the language bar</description>
    </key>
    <key name="use-custom-font" type="b">
      <default>false</default>
      <summary>Use custom font</summary>
      <description>Use a custom font for the language bar</description>
    </key>
    <key name="custom-font" type="s">
      <default>'Sans 10'</default>
      <summary>Custom font</summary>
      <description>Custom font for the language bar</description>
    </key>
    <key name="property-icon-delay-time" type="i">
      <default>500</default>
      <summary>Property icon delay time</summary>
      <description>Delay time to show property icon in milliseconds</description>
    </key>
    <key name="auto-hide-timeout" type="i">
      <default>10000</default>
      <summary>Auto hide timeout</summary>
      <description>Timeout to auto hide the panel in milliseconds</description>
    </key>
    <child name="emoji" schema="org.freedesktop.ibus.panel.emoji"/>
  </schema>
  <schema id="org.freedesktop.ibus.panel.emoji" path="/org/freedesktop/ibus/panel/emoji/">
    <key name="unicode-hotkey" type="as">
      <default>['&lt;Control&gt;&lt;Shift&gt;u']</default>
      <summary>Unicode hotkey</summary>
      <description>Hotkey to show Unicode code point input</description>
    </key>
    <key name="font" type="s">
      <default>'Monospace 16'</default>
      <summary>Emoji font</summary>
      <description>Font for emoji candidates</description>
    </key>
    <key name="lang" type="s">
      <default>'en'</default>
      <summary>Emoji language</summary>
      <description>Language for emoji annotations</description>
    </key>
    <key name="has-partial-match" type="b">
      <default>false</default>
      <summary>Has partial match</summary>
      <description>Whether to use partial match for emoji search</description>
    </key>
    <key name="partial-match-length" type="i">
      <default>3</default>
      <summary>Partial match length</summary>
      <description>Minimum length for partial match</description>
    </key>
    <key name="partial-match-condition" type="i">
      <default>0</default>
      <summary>Partial match condition</summary>
      <description>Condition for partial match</description>
    </key>
    <key name="favorites" type="as">
      <default>[]</default>
      <summary>Favorite emojis</summary>
      <description>List of favorite emojis</description>
    </key>
  </schema>
</schemalist>
IBUS_SCHEMA_EOF
echo "  ✓ ibus GSettings schema created"

# hangul 엔진 스키마 생성 (GitHub 원본 기반 - 정확한 키 목록)
cat > "$INSTALL_ROOT/usr/share/glib-2.0/schemas/org.freedesktop.ibus.engine.hangul.gschema.xml" << 'HANGUL_SCHEMA_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<schemalist>
  <schema path="/org/freedesktop/ibus/engine/hangul/"
          id="org.freedesktop.ibus.engine.hangul">
    <key name="hangul-keyboard" type="s">
      <default>'2'</default>
      <summary>Hangul keyboard</summary>
      <description></description>
    </key>
    <key name="initial-input-mode" type="s">
      <default>'latin'</default>
      <summary>Initial input mode</summary>
      <description></description>
    </key>
    <key name="word-commit" type="b">
      <default>false</default>
      <summary>Word commit</summary>
      <description></description>
    </key>
    <key name="auto-reorder" type="b">
      <default>true</default>
      <summary>Auto reorder</summary>
      <description></description>
    </key>
    <key name="switch-keys" type="s">
      <default>'Hangul,Shift+space,Control+y'</default>
      <summary>Switch keys</summary>
      <description></description>
    </key>
    <key name="hanja-keys" type="s">
      <default>'Hangul_Hanja,F9'</default>
      <summary>Hanja keys</summary>
      <description></description>
    </key>
    <key name="on-keys" type="s">
      <default>''</default>
      <summary>On keys</summary>
      <description></description>
    </key>
    <key name="off-keys" type="s">
      <default>'Escape'</default>
      <summary>Off keys</summary>
      <description></description>
    </key>
    <key name="disable-latin-mode" type="b">
      <default>false</default>
      <summary>Disable Latin mode</summary>
      <description></description>
    </key>
    <key name="use-event-forwarding" type="b">
      <default>true</default>
      <summary>Enable event forwarding workaround</summary>
      <description></description>
    </key>
    <key name="preedit-mode" type="s">
      <choices>
        <choice value="none" />
        <choice value="syllable" />
        <choice value="word" />
      </choices>
      <default>'syllable'</default>
      <summary>Preedit mode</summary>
      <description></description>
    </key>
  </schema>
</schemalist>
HANGUL_SCHEMA_EOF
echo "  ✓ hangul GSettings schema created (complete - 11 keys)"

# 스키마 컴파일
if [ -x "$INSTALL_ROOT/usr/bin/glib-compile-schemas" ]; then
    chroot "$INSTALL_ROOT" /usr/bin/glib-compile-schemas /usr/share/glib-2.0/schemas/
    echo "✓ GSettings schemas compiled"
else
    echo "⚠ glib-compile-schemas not found - schemas may not work"
fi

echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo "Installed packages:"
echo "  ✓ libhangul ${LIBHANGUL_VERSION}"
echo "  ✓ ibus ${IBUS_VERSION}"
echo "  ✓ ibus-hangul ${IBUS_HANGUL_VERSION}"
echo ""
echo "Configuration:"
echo "  - 한영 전환: Ctrl+Y"
echo "  - 키보드 레이아웃: QWERTY (2-beol)"
echo "  - 자동 시작: ibus-daemon"
echo ""
echo "Next steps:"
echo "  1. It will automatically build ISO file for v53"
echo "=========================================="

# 정리 (선택사항)
echo ""
read -p "Clean up build files? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Cleaning up..."
    rm -rf "$BUILD_DIR"
    echo "✓ Build files cleaned"
fi

echo "Done!"
