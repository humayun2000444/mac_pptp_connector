# Mac PPTP Connector

> Connect to PPTP VPN on modern macOS - Apple Silicon (M1/M2/M3/M4) & Intel supported!

![macOS](https://img.shields.io/badge/macOS-Big%20Sur%20%7C%20Monterey%20%7C%20Ventura%20%7C%20Sonoma%20%7C%20Sequoia-blue)
![Apple Silicon](https://img.shields.io/badge/Apple%20Silicon-M1%20%7C%20M2%20%7C%20M3%20%7C%20M4-green)
![License](https://img.shields.io/badge/License-GPL-yellow)

---

## The Problem

Apple removed native PPTP VPN support in **macOS Sierra (2016)**. If you need to connect to a PPTP VPN on a modern Mac, you're stuck with:
- Paid apps ($50+)
- Apps that don't work on Apple Silicon
- No solution at all

## The Solution

**Mac PPTP Connector** - A free, open-source PPTP VPN client that actually works!

---

## How to Use

### Step 1: Download

```bash
git clone https://github.com/humayun2000444/mac_pptp_connector.git
cd mac_pptp_connector
```

### Step 2: Make Executable

```bash
chmod +x connect.sh disconnect.sh vpn-gui.sh bin/pptp
```

### Step 3: Add Your VPN Credentials

Edit `vpn.conf` file:

```bash
VPN_SERVER="your.vpn.server.com"
VPN_USER="your_username"
VPN_PASS="your_password"
```

### Step 4: Connect

**Option A - GUI (Recommended)**
```bash
./vpn-gui.sh
```
- Select **Connect** from menu
- Enter your Mac password when prompted
- Done! You're connected

**Option B - Command Line**
```bash
./connect.sh
```

### Step 5: Disconnect

- **GUI:** Select **Disconnect** from menu
- **Command Line:** Press `Ctrl+C` or run `./disconnect.sh`

---

## Add to Dock (Optional)

Create a clickable app:

```bash
osacompile -o "PPTP VPN.app" -e 'tell application "Terminal" to do script "cd ~/path/to/mac_pptp_connector && ./vpn-gui.sh"'
```

Drag the created **PPTP VPN.app** to your Dock!

---

## What's Included

| File | Description |
|------|-------------|
| `bin/pptp` | PPTP client compiled for Apple Silicon |
| `vpn.conf` | Your VPN settings (edit this!) |
| `connect.sh` | Command-line connect script |
| `disconnect.sh` | Command-line disconnect script |
| `vpn-gui.sh` | GUI launcher with menu |

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Connection drops after 30-40 sec | Enable "PPTP/GRE Passthrough" in your router |
| Internet not working when connected | Run: `sudo route add default -interface ppp0` |
| Permission denied | Run: `chmod +x *.sh bin/pptp` |

---

## Security Note

⚠️ PPTP is an older protocol with known vulnerabilities. Use only when no other option is available. Consider asking your VPN provider for L2TP/IPSec, IKEv2, or OpenVPN.

---

## Tested On

- MacBook Air M4 - macOS Sequoia 15.x ✅
- Apple Silicon (M1/M2/M3/M4) ✅
- Intel Macs ✅

---

## Contributing

Found a bug? Have a suggestion? Open an issue or submit a PR!

If this helped you, please ⭐ the repo!

---

## Author

**Humayun Ahmed**

Made with ❤️ to solve a real problem for Mac users.

## License

GPL - Based on [pptpclient](http://pptpclient.sourceforge.net/)
