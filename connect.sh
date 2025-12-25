#!/bin/bash
#===============================================
# PPTP VPN Client for macOS (Apple Silicon/Intel)
# Works on macOS Big Sur, Monterey, Ventura, Sonoma, Sequoia
#===============================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/vpn.conf"
PPTP_BIN="$SCRIPT_DIR/bin/pptp"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo ""
echo "=========================================="
echo "   PPTP VPN Client for macOS"
echo "=========================================="
echo ""

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Error: Config file not found at $CONFIG_FILE${NC}"
    echo "Please create vpn.conf with your VPN credentials."
    exit 1
fi

# Load config
source "$CONFIG_FILE"

# Validate config
if [ -z "$VPN_SERVER" ] || [ -z "$VPN_USER" ] || [ -z "$VPN_PASS" ]; then
    echo -e "${RED}Error: Missing configuration.${NC}"
    echo "Please edit vpn.conf and set VPN_SERVER, VPN_USER, and VPN_PASS"
    exit 1
fi

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script requires root privileges."
    echo "Running with sudo..."
    exec sudo "$0" "$@"
fi

# Check if pptp binary exists
if [ ! -f "$PPTP_BIN" ]; then
    echo -e "${RED}Error: pptp binary not found at $PPTP_BIN${NC}"
    echo "Make sure the 'bin' folder contains the pptp executable."
    exit 1
fi

# Make pptp executable
chmod +x "$PPTP_BIN"

# Create /etc/ppp directories
mkdir -p /etc/ppp/peers

# Create chap-secrets file
cat > /etc/ppp/chap-secrets << EOF
# PPTP VPN credentials
$VPN_USER * "$VPN_PASS" *
* $VPN_USER "$VPN_PASS" *
EOF
chmod 600 /etc/ppp/chap-secrets

# Create peer configuration
cat > /etc/ppp/peers/pptp-vpn << EOF
# PPTP VPN Configuration
pty "$PPTP_BIN $VPN_SERVER --nolaunchpppd"
lock
noauth
refuse-pap
refuse-eap
refuse-chap
nobsdcomp
nodeflate
user $VPN_USER
password "$VPN_PASS"
mtu 1400
mru 1400
defaultroute
usepeerdns
noipdefault
lcp-echo-interval 30
lcp-echo-failure 4
EOF
chmod 600 /etc/ppp/peers/pptp-vpn

# Get current default gateway
ORIG_GW=$(netstat -rn | grep "^default" | head -1 | awk '{print $2}')
echo -e "${YELLOW}Original gateway: $ORIG_GW${NC}"

# Save original gateway
echo "$ORIG_GW" > /tmp/vpn_orig_gw
echo "$VPN_SERVER" > /tmp/vpn_server

# Create ip-up script for routing
cat > /etc/ppp/ip-up << 'IPUP'
#!/bin/bash
IFACE=$1
VPN_SERVER=$(cat /tmp/vpn_server 2>/dev/null)
ORIG_GW=$(cat /tmp/vpn_orig_gw 2>/dev/null)

if [ -n "$ORIG_GW" ] && [ -n "$VPN_SERVER" ]; then
    /sbin/route add -host $VPN_SERVER $ORIG_GW 2>/dev/null
    /sbin/route delete default 2>/dev/null
    /sbin/route add default -interface $IFACE 2>/dev/null
    echo "Routes configured: all traffic via $IFACE"
fi
IPUP
chmod 755 /etc/ppp/ip-up

# Create ip-down script to restore routes
cat > /etc/ppp/ip-down << 'IPDOWN'
#!/bin/bash
VPN_SERVER=$(cat /tmp/vpn_server 2>/dev/null)
ORIG_GW=$(cat /tmp/vpn_orig_gw 2>/dev/null)

if [ -n "$ORIG_GW" ]; then
    /sbin/route delete -host $VPN_SERVER 2>/dev/null
    /sbin/route delete default 2>/dev/null
    /sbin/route add default $ORIG_GW 2>/dev/null
    echo "Original routes restored"
fi
IPDOWN
chmod 755 /etc/ppp/ip-down

echo ""
echo -e "${GREEN}Connecting to VPN: $VPN_SERVER${NC}"
echo -e "${GREEN}Username: $VPN_USER${NC}"
echo ""
echo "Press Ctrl+C to disconnect"
echo "=========================================="
echo ""

# Start pppd
pppd call pptp-vpn debug nodetach

# Cleanup on exit
/etc/ppp/ip-down 2>/dev/null
rm -f /tmp/vpn_orig_gw /tmp/vpn_server

echo ""
echo -e "${YELLOW}VPN disconnected.${NC}"
