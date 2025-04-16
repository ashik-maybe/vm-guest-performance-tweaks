#!/bin/bash
# optimize-arch-guest.sh
# Description : Optimize Arch Linux and derivatives for virtual machine performance
# Author      : yourname (or GitHub handle)
# License     : MIT
# Usage       : sudo ./optimize-arch-guest.sh

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
echo -e "${CYAN}🧠 Optimizing Arch Linux for Virtual Machine...${RESET}"
if ! command -v sudo &>/dev/null; then
    echo -e "${RED}❌ sudo is required. Exiting.${RESET}"
    exit 1
fi

sudo -v || { echo -e "${RED}❌ Sudo authentication failed. Exiting.${RESET}"; exit 1; }

# Detect the init system (assuming systemd for most Arch-based distros)
if command -v systemctl &>/dev/null; then
    INIT="systemd"
elif command -v sv &>/dev/null; then
    INIT="runit"
else
    echo -e "${RED}❌ Unsupported init system. Exiting.${RESET}"
    exit 1
fi

echo -e "${CYAN}📡 Detected init system: $INIT${RESET}"

# ──────────────────────────────────────────────────────────────
# 🧰 Install virtual machine guest tools
echo -e "${YELLOW}🧰 Installing virtual machine guest tools...${RESET}"

run_cmd "sudo pacman -Syu --noconfirm"
run_cmd "sudo pacman -S --noconfirm spice-vdagent qemu-guest-agent"

# Enable and start agents based on the init system
case "$INIT" in
    systemd)
        sudo systemctl enable --now spice-vdagent qemu-guest-agent || true
        ;;
    runit)
        sudo ln -s /etc/sv/spice-vdagent /var/service/
        sudo ln -s /etc/sv/qemu-guest-agent /var/service/
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
    esac
}

disable_service "cups"
disable_service "avahi-daemon"
disable_service "ModemManager"
echo -e "${GREEN}✅ Unnecessary services disabled.${RESET}"

# ──────────────────────────────────────────────────────────────
# 🧹 Clean up
echo -e "${YELLOW}🧹 Cleaning up system...${RESET}"
run_cmd "sudo pacman -Rns $(sudo pacman -Qdtq) --noconfirm"
run_cmd "sudo pacman -Scc --noconfirm"
echo -e "${GREEN}✅ Cleanup complete.${RESET}"

# ──────────────────────────────────────────────────────────────
# ✅ Done
echo -e "${GREEN}🎉 Arch system is now VM-optimized!${RESET}"
