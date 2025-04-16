#!/bin/bash
# optimize-fedora-vm.sh — Optimize Fedora for Virtual Machine usage

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
sudo -v || { echo -e "${RED}❌ Sudo required. Exiting.${RESET}"; exit 1; }

# ──────────────────────────────────────────────────────────────
# ⚙️ Improve DNF Speed
echo -e "${YELLOW}⚙️ Tweaking DNF...${RESET}"
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
# 🧰 Install useful VM tools
echo -e "${YELLOW}🧰 Installing virtual machine tools...${RESET}"
run_cmd "sudo dnf install -y spice-vdagent qemu-guest-agent open-vm-tools"
sudo systemctl enable --now spice-vdagent qemu-guest-agent
echo -e "${GREEN}✅ Guest tools installed and enabled.${RESET}"

# ──────────────────────────────────────────────────────────────
# 🚫 Disable unneeded services
echo -e "${YELLOW}🚫 Disabling unused services...${RESET}"
run_cmd "sudo systemctl disable --now cups"
run_cmd "sudo systemctl disable --now avahi-daemon"
run_cmd "sudo systemctl disable --now ModemManager"
echo -e "${GREEN}✅ Unnecessary services disabled.${RESET}"

# ──────────────────────────────────────────────────────────────
# 🧹 Clean up
echo -e "${YELLOW}🧹 Cleaning up system...${RESET}"
run_cmd "sudo dnf autoremove -y"
# run_cmd "sudo dnf clean all"
echo -e "${GREEN}✅ Cleanup done.${RESET}"

# ──────────────────────────────────────────────────────────────
# ✅ Done
echo -e "${GREEN}🎉 Fedora is now VM-optimized!${RESET}"
