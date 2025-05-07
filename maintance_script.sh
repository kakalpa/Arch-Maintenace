#!/bin/bash

# Arch Linux System Maintenance Script
# Inspired by Fernando Cejas' blog post

set -euo pipefail

echo "🔧 Starting Arch Linux system maintenance..."

# 1. Update system packages
echo "📦 Updating system packages..."
sudo pacman -Syu --noconfirm

# 2. Clean package cache
echo "🧹 Cleaning package cache..."
sudo paccache -r

# 3. Remove orphaned packages
echo "🗑️ Removing orphaned packages..."
orphans=$(pacman -Qtdq || true)
if [[ -n "$orphans" ]]; then
  sudo pacman -Rns --noconfirm $orphans
else
  echo "✅ No orphaned packages found."
fi

# 4. Update AUR packages (requires 'paru' AUR helper)
if command -v paru &> /dev/null; then
  echo "📦 Updating AUR packages..."
  paru -Syu --noconfirm
else
  echo "⚠️ 'yay' not found. Skipping AUR package updates."
fi

# 5. Clean journal logs older than 2 weeks
echo "🧾 Cleaning journal logs older than 2 weeks..."
sudo journalctl --vacuum-time=2weeks

# 6. Check system health
echo "🩺 Checking system health..."
systemctl --failed

# 7. Verify package integrity
echo "🔍 Verifying package integrity..."
sudo pacman -Qk

# 8. Update mirrorlist (requires 'reflector')
if command -v reflector &> /dev/null; then
  echo "🌐 Updating mirrorlist..."
  sudo reflector --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
else
  echo "⚠️ 'reflector' not found. Skipping mirrorlist update."
fi

# 9. Remove unused Flatpak packages (if Flatpak is installed)
if command -v flatpak &> /dev/null; then
  echo "🧹 Removing unused Flatpak packages..."
  flatpak uninstall --unused -y
else
  echo "ℹ️ Flatpak not installed. Skipping Flatpak cleanup."
fi

# 10. Clean systemd journal logs
echo "🧾 Cleaning systemd journal logs..."
sudo journalctl --vacuum-size=100M

echo "✅ Arch Linux system maintenance completed successfully!"
