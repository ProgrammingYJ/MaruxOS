#!/bin/bash
SQROOT=/home/administrator/MaruxOS/v18-restore/squashfs-root
DESIGN_DIR="/mnt/c/Users/Administrator/Desktop/MaruxOS/MaruxOS 디자인"

# Copy launcher icons
mkdir -p $SQROOT/usr/share/maruxos/icons
cp "$DESIGN_DIR/terminal.png" $SQROOT/usr/share/maruxos/icons/marux-terminal.png
cp "$DESIGN_DIR/marux-file-manager.png" $SQROOT/usr/share/maruxos/icons/marux-file-manager.png

# Update xterm.desktop
cat > $SQROOT/usr/share/applications/xterm.desktop << 'EOF'
[Desktop Entry]
Name=Terminal
Comment=Open Terminal
Exec=xterm
Icon=/usr/share/maruxos/icons/marux-terminal.png
Terminal=false
Type=Application
Categories=System;TerminalEmulator;
EOF

# Update mc.desktop
cat > $SQROOT/usr/share/applications/mc.desktop << 'EOF'
[Desktop Entry]
Name=File Manager
Comment=Midnight Commander File Manager
Exec=xterm -e mc ~ /
Icon=/usr/share/maruxos/icons/marux-file-manager.png
Terminal=false
Type=Application
Categories=System;FileManager;
EOF

echo "Icons updated!"
ls -la $SQROOT/usr/share/maruxos/icons/
