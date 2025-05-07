#!/bin/bash

# Arch Linux System Maintenance Script (Single Log File)
# Author: Kalpa Kuruwita

set -euo pipefail

LOG_DIR="/var/log/arch-maintenance"
LOG_FILE="$LOG_DIR/maintenance.log"

# Ensure log directory exists
sudo mkdir -p "$LOG_DIR"
sudo chown "$USER":"$USER" "$LOG_DIR"

echo "🕒 $(date): Starting Arch Linux system maintenance..." | tee -a "$LOG_FILE"

# 1. Update system packages
echo "📦 Updating system packages..." | tee -a "$LOG_FILE"
sudo pacman -Syu --noconfirm &>> "$LOG_FILE"

# 2. Clean package cache
echo "🧹 Cleaning package cache..." | tee -a "$LOG_FILE"
sudo paccache -r &>> "$LOG_FILE"

# 3. Remove orphaned packages
echo "🗑️ Removing orphaned packages..." | tee -a "$LOG_FILE"
orphans=$(pacman -Qtdq || true)
if [[ -n "$orphans" ]]; then
  sudo pacman -Rns --noconfirm $orphans &>> "$LOG_FILE"
else
  echo "✅ No orphaned packages found." | tee -a "$LOG_FILE"
fi

# 4. Update AUR packages (if paru exists)
if command -v paru &> /dev/null; then
  echo "📦 Updating AUR packages..." | tee -a "$LOG_FILE"
  yay -Syu --noconfirm &>> "$LOG_FILE"
else
  echo "⚠️ 'yay' not found. Skipping AUR updates." | tee -a "$LOG_FILE"
fi

# 5. Clean journal logs
echo "🧾 Cleaning journal logs..." | tee -a "$LOG_FILE"
sudo journalctl --vacuum-time=2weeks &>> "$LOG_FILE"
sudo journalctl --vacuum-size=100M &>> "$LOG_FILE"

# 6. Check system health
echo "🩺 Checking system health..." | tee -a "$LOG_FILE"
systemctl --failed &>> "$LOG_FILE"
sudo pacman -Qk &>> "$LOG_FILE"

# 7. Update mirrorlist
if command -v reflector &> /dev/null; then
  echo "🌐 Updating mirrorlist..." | tee -a "$LOG_FILE"
  sudo reflector --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist &>> "$LOG_FILE"
else
  echo "⚠️ 'reflector' not found. Skipping mirrorlist update." | tee -a "$LOG_FILE"
fi

# 8. Clean Flatpak packages
if command -v flatpak &> /dev/null; then
  echo "🧹 Removing unused Flatpak packages..." | tee -a "$LOG_FILE"
  flatpak uninstall --unused -y &>> "$LOG_FILE"
else
  echo "ℹ️ Flatpak not installed. Skipping Flatpak cleanup." | tee -a "$LOG_FILE"
fi

echo "✅ Done: Arch Linux system maintenance completed at $(date)." | tee -a "$LOG_FILE"
