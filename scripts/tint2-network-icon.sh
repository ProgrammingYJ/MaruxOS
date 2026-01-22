#!/bin/sh
ICON_PATH="/usr/share/icons/MaruxOS/24x24/status"

# Check internet connection
check_connection() {
    if ping -c 1 -W 1 8.8.8.8 >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

# Get WiFi interface name
get_wifi_interface() {
    for iface in /sys/class/net/wl*; do
        if [ -d "$iface" ]; then
            basename "$iface"
            return
        fi
    done
}

# Get wired interface name
get_wired_interface() {
    for iface in /sys/class/net/eth* /sys/class/net/en*; do
        if [ -d "$iface" ]; then
            basename "$iface"
            return
        fi
    done
}

# Get WiFi signal strength
get_wifi_strength() {
    WIFI_IF=$(get_wifi_interface)
    if [ -n "$WIFI_IF" ] && [ -f "/proc/net/wireless" ]; then
        STRENGTH=$(grep "$WIFI_IF" /proc/net/wireless 2>/dev/null | awk '{print int($3)}')
        if [ -n "$STRENGTH" ]; then
            echo "$STRENGTH"
            return
        fi
    fi
    echo "0"
}

# Main logic
if ! check_connection; then
    echo "$ICON_PATH/network-offline.png"
    exit 0
fi

# Check wired connection
WIRED_IF=$(get_wired_interface)
if [ -n "$WIRED_IF" ]; then
    STATE=$(cat /sys/class/net/$WIRED_IF/operstate 2>/dev/null)
    if [ "$STATE" = "up" ]; then
        echo "$ICON_PATH/network-wired.png"
        exit 0
    fi
fi

# WiFi signal strength
STRENGTH=$(get_wifi_strength)
if [ "$STRENGTH" -ge 80 ]; then
    echo "$ICON_PATH/network-wireless-signal-excellent.png"
elif [ "$STRENGTH" -ge 60 ]; then
    echo "$ICON_PATH/network-wireless-signal-good.png"
elif [ "$STRENGTH" -ge 40 ]; then
    echo "$ICON_PATH/network-wireless-signal-ok.png"
elif [ "$STRENGTH" -ge 20 ]; then
    echo "$ICON_PATH/network-wireless-signal-weak.png"
else
    echo "$ICON_PATH/network-wireless-signal-none.png"
fi
