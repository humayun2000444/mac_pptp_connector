#!/bin/bash
#===============================================
# PPTP VPN Client GUI for macOS
#===============================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/vpn.conf"

# Check if connected
is_connected() {
    pgrep -f "pppd call pptp-vpn" > /dev/null 2>&1
}

# Load config
load_config() {
    [ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"
}

# Save config
save_config() {
    cat > "$CONFIG_FILE" << EOF
VPN_SERVER="$VPN_SERVER"
VPN_USER="$VPN_USER"
VPN_PASS="$VPN_PASS"
EOF
}

# Edit settings
edit_settings() {
    load_config

    VPN_SERVER=$(osascript -e "display dialog \"VPN Server:\" default answer \"$VPN_SERVER\" buttons {\"Cancel\",\"Next\"}" -e 'text returned of result' 2>/dev/null) || return
    VPN_USER=$(osascript -e "display dialog \"Username:\" default answer \"$VPN_USER\" buttons {\"Cancel\",\"Next\"}" -e 'text returned of result' 2>/dev/null) || return
    VPN_PASS=$(osascript -e "display dialog \"Password:\" default answer \"$VPN_PASS\" with hidden answer buttons {\"Cancel\",\"Save\"}" -e 'text returned of result' 2>/dev/null) || return

    save_config
    osascript -e 'display dialog "Settings saved!" buttons {"OK"}'
}

# Connect VPN - opens Terminal with connect.sh
connect_vpn() {
    load_config

    if [ -z "$VPN_SERVER" ] || [ -z "$VPN_USER" ] || [ -z "$VPN_PASS" ]; then
        osascript -e 'display dialog "Configure settings first!" buttons {"OK"} with icon caution'
        edit_settings
        return
    fi

    # Open Terminal and run connect script
    osascript << EOF
tell application "Terminal"
    activate
    do script "cd '$SCRIPT_DIR' && ./connect.sh"
end tell
EOF

    # Wait for connection
    sleep 5

    if is_connected; then
        VPN_IP=$(ifconfig ppp0 2>/dev/null | grep "inet " | awk '{print $2}')
        osascript -e "display notification \"Connected! IP: $VPN_IP\" with title \"PPTP VPN\""
    fi
}

# Disconnect VPN
disconnect_vpn() {
    osascript << EOF
tell application "Terminal"
    activate
    do script "sudo pkill -f 'pppd call pptp-vpn'; sudo route delete default 2>/dev/null; sudo route add default \$(cat /tmp/vpn_orig_gw 2>/dev/null) 2>/dev/null; echo 'VPN Disconnected'; sleep 2; exit"
end tell
EOF
    sleep 2
    osascript -e 'display notification "Disconnected" with title "PPTP VPN"'
}

# Main menu
show_menu() {
    if is_connected; then
        VPN_IP=$(ifconfig ppp0 2>/dev/null | grep "inet " | awk '{print $2}')
        osascript -e "choose from list {\"Disconnect\", \"Edit Settings\", \"Quit\"} with prompt \"Status: Connected ($VPN_IP)\" with title \"PPTP VPN\"" 2>/dev/null
    else
        load_config
        [ -n "$VPN_SERVER" ] && STATUS="Not Connected - $VPN_SERVER" || STATUS="Not Connected"
        osascript -e "choose from list {\"Connect\", \"Edit Settings\", \"Quit\"} with prompt \"Status: $STATUS\" with title \"PPTP VPN\"" 2>/dev/null
    fi
}

# Main loop
while true; do
    CHOICE=$(show_menu)

    case "$CHOICE" in
        "Connect") connect_vpn ;;
        "Disconnect") disconnect_vpn ;;
        "Edit Settings") edit_settings ;;
        "Quit"|"false"|"")
            if is_connected; then
                ANS=$(osascript -e 'button returned of (display dialog "Disconnect before quit?" buttons {"No","Yes"})' 2>/dev/null)
                [ "$ANS" = "Yes" ] && disconnect_vpn
            fi
            exit 0
            ;;
    esac
done
