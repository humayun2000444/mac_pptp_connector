#!/bin/bash
#===============================================
# PPTP VPN Disconnect Script
#===============================================

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    exec sudo "$0" "$@"
fi

echo "Disconnecting VPN..."

# Kill pppd process
if [ -f /var/run/ppp0.pid ]; then
    PID=$(cat /var/run/ppp0.pid)
    kill "$PID" 2>/dev/null
    sleep 1
    kill -9 "$PID" 2>/dev/null
else
    pkill -f "pppd call pptp-vpn" 2>/dev/null
fi

# Restore routes
VPN_SERVER=$(cat /tmp/vpn_server 2>/dev/null)
ORIG_GW=$(cat /tmp/vpn_orig_gw 2>/dev/null)

if [ -n "$ORIG_GW" ]; then
    /sbin/route delete -host "$VPN_SERVER" 2>/dev/null
    /sbin/route delete default 2>/dev/null
    /sbin/route add default "$ORIG_GW" 2>/dev/null
fi

# Cleanup
rm -f /tmp/vpn_orig_gw /tmp/vpn_server

echo "VPN disconnected and routes restored."
