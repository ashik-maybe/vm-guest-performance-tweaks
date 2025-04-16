#!/bin/bash
# optimize-fedora-guest.sh
# Description : Optimize Fedora for virtual machine performance (QEMU/KVM/VMware)
# Author      : yourname (or GitHub handle)
# License     : MIT
# Usage       : sudo ./optimize-fedora-guest.sh

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
echo -e "${CYAN}🧠 Optimizing Fedora for Virtual Machine...${RESET}"
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
# ⚙️ Improve DNF Speed (with backup)
echo -e "${YELLOW}⚙️ Tweaking DNF configuration...${RESET}"
if [[ -f /etc/dnf/dnf.conf ]]; then
    sudo cp /etc/dnf/dnf.conf /etc/dnf/dnf.conf.bak
    echo -e "${CYAN}🗂️  Backed up existing dnf.conf to dnf.conf.bak${RESET}"
fi

sudo tee /etc/dnf/dnf.conf > /dev/null <<EOF
[main]
gpgcheck=True
installonly_limit=3
clean_requirements_on_remove=True
best=False
skip_if_unavailable=True
max_parallel_downloads=10
fastestmirror=True
color=auto
EOF
echo -e "${GREEN}✅ DNF optimized.${RESET}"

# ──────────────────────────────────────────────────────────────
# 🧰 Install virtual guest tools
echo -e "${YELLOW}🧰 Installing virtual machine guest tools...${RESET}"
run_cmd "sudo dnf install -y spice-vdagent qemu-guest-agent open-vm-tools"

sudo systemctl enable --now spice-vdagent qemu-guest-agent || true
echo -e "${GREEN}✅ Guest tools installed and enabled.${RESET}"

# ──────────────────────────────────────────────────────────────
# 🚫 Disable unnecessary services (only if present)
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
run_cmd "sudo dnf autoremove -y"
# run_cmd "sudo dnf clean all"
echo -e "${GREEN}✅ Cleanup done.${RESET}"

# ──────────────────────────────────────────────────────────────
# 🎉 Done
echo -e "${GREEN}🎉 Fedora is now optimized for VM usage!${RESET}"
