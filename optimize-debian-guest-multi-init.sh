#!/bin/bash
# optimize-debian-guest-multi-init.sh
# Description : Optimize Debian and derivatives for virtual machine performance with multi-init support
# Author      : yourname (or GitHub handle)
# License     : MIT
# Usage       : sudo ./optimize-debian-guest-multi-init.sh

set -euo pipefail

# ──────────────────────────────────────────────────────────────
# 🎨 Colors
CYAN="\033[0;36m"
YELLOW="\033[0;33m"
GREEN="\033[0;32m"
RED="\033[0;31m"
RESET="\033[0m"

run_cmd() {
    echo -e "${CYAN}🔧 Running: $1${RESET}"
    eval "$1"
}

# ──────────────────────────────────────────────────────────────
# 🧠 Info
echo -e "${CYAN}🧠 Optimizing Debian for Virtual Machine...${RESET}"
if ! command -v sudo &>/dev/null; then
    echo -e "${RED}❌ sudo is required. Exiting.${RESET}"
    exit 1
fi

sudo -v || { echo -e "${RED}❌ Sudo authentication failed. Exiting.${RESET}"; exit 1; }

# Detect the init system
if command -v systemctl &>/dev/null; then
    INIT="systemd"
elif command -v sv &>/dev/null; then
    INIT="runit"
elif command -v service &>/dev/null; then
    INIT="sysvinit"
else
    echo -e "${RED}❌ Unsupported init system. Exiting.${RESET}"
    exit 1
fi

echo -e "${CYAN}📡 Detected init system: $INIT${RESET}"

# ──────────────────────────────────────────────────────────────
# 🧰 Install virtual machine guest tools
echo -e "${YELLOW}🧰 Installing virtual machine guest tools...${RESET}"

run_cmd "sudo apt update"
run_cmd "sudo apt install -y spice-vdagent qemu-guest-agent"

# Enable and start agents based on the init system
case "$INIT" in
    systemd)
        sudo systemctl enable --now spice-vdagent qemu-guest-agent || true
        ;;
    runit)
        sudo ln -s /etc/sv/spice-vdagent /var/service/
        sudo ln -s /etc/sv/qemu-guest-agent /var/service/
        ;;
    sysvinit)
        sudo service spice-vdagent start
        sudo service qemu-guest-agent start
        ;;
esac

echo -e "${GREEN}✅ Guest agents installed and enabled.${RESET}"

# ──────────────────────────────────────────────────────────────
# 🚫 Disable unnecessary services (only if present)
echo -e "${YELLOW}🚫 Disabling unneeded services...${RESET}"
disable_service() {
    local svc="$1"
    case "$INIT" in
        systemd)
            if systemctl list-unit-files | grep -q "^${svc}.service"; then
                run_cmd "sudo systemctl disable --now $svc"
            else
                echo -e "${YELLOW}⚠️  $svc not found. Skipping.${RESET}"
            fi
            ;;
        runit)
            if [ -d "/etc/service/$svc" ]; then
                run_cmd "sudo rm -f /etc/service/$svc"
            else
                echo -e "${YELLOW}⚠️  $svc not found. Skipping.${RESET}"
            fi
            ;;
        sysvinit)
            if service --status-all | grep -q "$svc"; then
                run_cmd "sudo service $svc stop"
                run_cmd "sudo update-rc.d $svc disable"
            else
                echo -e "${YELLOW}⚠️  $svc not found. Skipping.${RESET}"
            fi
            ;;
    esac
}

disable_service "cups"
disable_service "avahi-daemon"
disable_service "ModemManager"
echo -e "${GREEN}✅ Unnecessary services disabled.${RESET}"

# ──────────────────────────────────────────────────────────────
# 🧹 Clean up
echo -e "${YELLOW}🧹 Cleaning up system...${RESET}"
run_cmd "sudo apt autoremove --purge -y"
run_cmd "sudo apt clean"
echo -e "${GREEN}✅ Cleanup complete.${RESET}"

# ──────────────────────────────────────────────────────────────
# ✅ Done
echo -e "${GREEN}🎉 Debian system is now VM-optimized!${RESET}"
