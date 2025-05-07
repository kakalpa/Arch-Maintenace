#!/bin/bash

# Arch Linux System Maintenance Script with -v, --help, and -a <AUR helper>
# Author: Kalpa Kuruwita

set -euo pipefail

LOG_DIR="/var/log/arch-maintenance"
LOG_FILE="$LOG_DIR/maintenance.log"
VERBOSE=false
AUR_HELPER="yay"  # default

# Help message
show_help() {
  cat << EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  -v              Verbose mode (prints output to terminal and log file)
  -a <helper>     Specify AUR helper (e.g. paru, yay, or 'none' to skip)
  --help          Display this help message

This script performs routine Arch Linux system maintenance tasks:
  - System + AUR updates
  - Package and journal cleanup
  - Orphaned package removal
  - Mirrorlist update (requires 'reflector')
  - Flatpak cleanup (if installed)
EOF
  exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -v)
      VERBOSE=true
      shift
      ;;
    -a)
      AUR_HELPER="$2"
      shift 2
      ;;
    --help)
      show_help
      ;;
    *)
      echo "❌ Unknown option: $1. Use --help for usage."
      exit 1
      ;;
  esac
done

# Ensure log directory exists
sudo mkdir -p "$LOG_DIR"
sudo chown "$USER":"$USER" "$LOG_DIR"

# Logging function
log() {
  if $VERBOSE; then
    echo -e "$1" | tee -a "$LOG_FILE"
  else
    echo -e "$1" >> "$LOG_FILE"
  fi
}

log "\n🕒 $(date): Starting Arch Linux system maintenance..."

log "📦 Updating system packages..."
sudo pacman -Syu --noconfirm &>> "$LOG_FILE"

log "🧹 Cleaning package cache..."
sudo paccache -r &>> "$LOG_FILE"

log "🗑️ Removing orphaned packages..."
orphans=$(pacman -Qtdq || true)
if [[ -n "$orphans" ]]; then
  sudo pacman -Rns --noconfirm $orphans &>> "$LOG_FILE"
else
  log "✅ No orphaned packages found."
fi

# AUR update logic
if [[ "$AUR_HELPER" == "none" ]]; then
  log "🚫 Skipping AUR package updates."
elif command -v "$AUR_HELPER" &> /dev/null; then
  log "📦 Updating AUR packages with '$AUR_HELPER'..."
  "$AUR_HELPER" -Syu --noconfirm &>> "$LOG_FILE"
else
  log "⚠️ AUR helper '$AUR_HELPER' not found. Skipping AUR updates."
fi

log "🧾 Cleaning journal logs..."
sudo journalctl --vacuum-time=2weeks &>> "$LOG_FILE"
sudo journalctl --vacuum-size=100M &>> "$LOG_FILE"

log "🩺 Checking system health..."
systemctl --failed &>> "$LOG_FILE"
sudo pacman -Qk &>> "$LOG_FILE"

if command -v reflector &> /dev/null; then
  log "🌐 Updating mirrorlist..."
  sudo reflector --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist &>> "$LOG_FILE"
else
  log "⚠️ 'reflector' not found. Skipping mirrorlist update."
fi

if command -v flatpak &> /dev/null; then
  log "🧹 Removing unused Flatpak packages..."
  flatpak uninstall --unused -y &>> "$LOG_FILE"
else
  log "ℹ️ Flatpak not installed. Skipping Flatpak cleanup."
fi

log "✅ Done: Maintenance completed at $(date)."
