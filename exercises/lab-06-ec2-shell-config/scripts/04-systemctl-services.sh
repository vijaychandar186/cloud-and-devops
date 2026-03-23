#!/usr/bin/env bash
# Lab 06 — Script 4: systemctl service management demo
# Demonstrates how to check, enable, disable, and manage services with systemctl.
# Based on Ex-6: "Configure Networking Services to Start or Stop Automatically"

echo "=========================================="
echo " Lab 06 — systemctl Service Management"
echo "=========================================="
echo ""
echo "systemctl is the service manager for systemd-based Linux (Ubuntu, Debian, RHEL, etc.)"
echo "It controls which services run now and which start automatically at boot."
echo ""

# Detect whether systemd is available (check for the systemd runtime directory)
HAVE_SYSTEMD=false
if [ -d /run/systemd/system ]; then
    HAVE_SYSTEMD=true
fi

# -----------------------------------------------------------
echo "--- Common networking services ---"
echo ""
for SVC in ssh sshd NetworkManager systemd-networkd; do
    if $HAVE_SYSTEMD; then
        STATUS=$(systemctl is-active "$SVC" 2>&1 | grep -v systemd | head -1 || true)
        [ -z "$STATUS" ] && STATUS="not-found"
        ENABLED=$(systemctl is-enabled "$SVC" 2>&1 | grep -v systemd | head -1 || true)
        [ -z "$ENABLED" ] && ENABLED="not-found"
    else
        STATUS=$(service "$SVC" status > /dev/null 2>&1 && echo "active" || echo "inactive")
        ENABLED="(systemd not available)"
    fi
    printf "  %-24s  active=%-12s  enabled=%s\n" "$SVC" "$STATUS" "$ENABLED"
done

# -----------------------------------------------------------
echo ""
echo "--- Active services ---"
echo ""
if $HAVE_SYSTEMD; then
    systemctl list-units --type=service --state=active --no-pager --no-legend 2>/dev/null \
        | head -15 \
        | awk '{printf "  %s\n", $0}'
else
    echo "  NOTE: systemd is not running in this devcontainer."
    echo "  In a real Ubuntu/EC2 instance, this command would list all active services:"
    echo "  \$ systemctl list-units --type=service --state=active"
    echo ""
    echo "  Using 'service --status-all' as the devcontainer equivalent:"
    service --status-all 2>&1 | head -20 | awk '{printf "  %s\n", $0}' || true
fi

# -----------------------------------------------------------
echo ""
echo "--- Reference: systemctl command cheatsheet ---"
echo ""
printf "  %-45s  %s\n" "Command" "What it does"
printf "  %-45s  %s\n" "-------" "------------"
printf "  %-45s  %s\n" "systemctl status <service>"     "Show current state and recent logs"
printf "  %-45s  %s\n" "systemctl start <service>"      "Start service now (not persistent)"
printf "  %-45s  %s\n" "systemctl stop <service>"       "Stop service now (not persistent)"
printf "  %-45s  %s\n" "systemctl restart <service>"    "Stop then start"
printf "  %-45s  %s\n" "systemctl reload <service>"     "Reload config without full restart"
printf "  %-45s  %s\n" "systemctl enable <service>"     "Auto-start at boot"
printf "  %-45s  %s\n" "systemctl disable <service>"    "Do not auto-start at boot"
printf "  %-45s  %s\n" "systemctl is-active <service>"  "Print 'active' or 'inactive'"
printf "  %-45s  %s\n" "systemctl is-enabled <service>" "Print 'enabled' or 'disabled'"

# -----------------------------------------------------------
echo ""
echo "--- SSH service (used for remote shell access) ---"
echo ""
if $HAVE_SYSTEMD; then
    systemctl status ssh --no-pager 2>&1 | grep -v "^$" || \
        systemctl status sshd --no-pager 2>&1 | grep -v "^$" || \
        echo "  ssh/sshd service not found."
else
    echo "  Checking with 'service' (systemd unavailable in devcontainer):"
    service ssh status 2>/dev/null || service sshd status 2>/dev/null || \
        echo "  ssh/sshd not found — it would be present on a real EC2 Ubuntu instance."
fi

# -----------------------------------------------------------
echo ""
echo "--- macOS equivalent (networksetup) ---"
echo ""
echo "  On macOS, use networksetup instead of systemctl:"
echo ""
printf "  %-50s  %s\n" "Command" "What it does"
printf "  %-50s  %s\n" "-------" "------------"
printf "  %-50s  %s\n" "networksetup -listallnetworkservices"             "List all network interfaces"
printf "  %-50s  %s\n" "networksetup -setnetworkserviceenabled Wi-Fi off" "Disable Wi-Fi"
printf "  %-50s  %s\n" "networksetup -setnetworkserviceenabled Wi-Fi on"  "Enable Wi-Fi"
printf "  %-50s  %s\n" "sudo networksetup -setairportpower en0 on"        "Power on airport adapter"

echo ""
echo "Done."
