#!/bin/bash
# optimize-ubuntu-guest.sh
# Description : Optimize Ubuntu (and flavors/derivatives) for virtual machine performance
# Author      : yourname (or GitHub handle)
# License     : MIT
# Usage       : sudo ./optimize-ubuntu-guest.sh

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
echo -e "${CYAN}🧠 Optimizing Ubuntu for Virtual Machine...${RESET}"
if ! command -v sudo &>/dev/null; then
    echo -e "${RED}❌ sudo is required. Exiting.${RESET}"
    exit 1
fi

sudo -v || { echo -e "${RED}❌ Sudo authentication failed. Exiting.${RESET}"; exit 1; }

if ! command -v systemctl &>/dev/null; then
    echo -e "${RED}❌ systemctl not found. Are you using a non-systemd OS? Exiting.${RESET}"
    exit 1
fi

# ──────────────────────────────────────────────────────────────
# 🧰 Install VM guest tools
echo -e "${YELLOW}🧰 Installing virtual machine guest tools...${RESET}"

# For general virtualization platforms
run_cmd "sudo apt update"
run_cmd "sudo apt install -y spice-vdagent qemu-guest-agent"

# Enable agents if present
sudo systemctl enable --now spice-vdagent qemu-guest-agent || true
echo -e "${GREEN}✅ Guest agents installed and enabled.${RESET}"

# ──────────────────────────────────────────────────────────────
# 🚫 Disable unnecessary services
echo -e "${YELLOW}🚫 Disabling unneeded services...${RESET}"
disable_service() {
    local svc="$1"
    if systemctl list-unit-files | grep -q "^${svc}.service"; then
        run_cmd "sudo systemctl disable --now $svc"
    else
        echo -e "${YELLOW}⚠️  $svc not installed. Skipping.${RESET}"
    fi
}

disable_service "cups"
disable_service "avahi-daemon"
disable_service "ModemManager"
echo -e "${GREEN}✅ Unnecessary services disabled.${RESET}"

# ──────────────────────────────────────────────────────────────
# 🧹 Clean up
echo -e "${YELLOW}🧹 Cleaning up...${RESET}"
run_cmd "sudo apt autoremove --purge -y"
run_cmd "sudo apt clean"
echo -e "${GREEN}✅ Cleanup done.${RESET}"

# ──────────────────────────────────────────────────────────────
# ✅ Done
echo -e "${GREEN}🎉 Ubuntu is now optimized for VM usage!${RESET}"
