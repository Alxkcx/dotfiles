#!/bin/bash
# Restore packages from dotfiles package lists
# Usage: bash restore-packages.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
PKG_DIR="$DOTFILES_DIR/packages"

echo "==> Restoring packages..."

# Native packages
if [ -f "$PKG_DIR/official.txt" ]; then
    echo "==> Installing official packages ($(wc -l < "$PKG_DIR/official.txt") packages)..."
    sudo pacman -S --needed - < "$PKG_DIR/official.txt"
else
    echo "!! official.txt not found, skipping"
fi

# AUR packages
if [ -f "$PKG_DIR/aur.txt" ]; then
    echo "==> Installing AUR packages ($(wc -l < "$PKG_DIR/aur.txt") packages)..."
    if command -v paru &>/dev/null; then
        paru -S --needed - < "$PKG_DIR/aur.txt"
    elif command -v yay &>/dev/null; then
        yay -S --needed - < "$PKG_DIR/aur.txt"
    else
        echo "!! No AUR helper found. Install paru or yay first, then run:"
        echo "   paru -S --needed - < $PKG_DIR/aur.txt"
    fi
else
    echo "!! aur.txt not found, skipping"
fi

# Flatpak apps (system 安装为常态；列表格式: app_id<TAB>origin)
if [ -f "$PKG_DIR/flatpak.txt" ]; then
    echo "==> Installing Flatpak apps ($(grep -c . "$PKG_DIR/flatpak.txt") apps)..."
    if command -v flatpak &>/dev/null; then
        flatpak remote-add --if-not-exists flathub \
            https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
        while IFS=$'\t' read -r app origin; do
            [ -z "$app" ] && continue
            origin="${origin:-flathub}"
            if flatpak info "$app" &>/dev/null; then
                echo "  = $app (already installed)"
            else
                echo "  + $app  (from $origin)"
                flatpak install -y --noninteractive "$origin" "$app" \
                    || sudo flatpak install -y --noninteractive "$origin" "$app" \
                    || echo "  !! failed: $app"
            fi
        done < "$PKG_DIR/flatpak.txt"
    else
        echo "!! flatpak not found. Install it first, then run:"
        echo "   flatpak install -y \$(cut -f1 "$PKG_DIR/flatpak.txt")"
    fi
else
    echo "!! flatpak.txt not found, skipping"
fi

echo "==> Done! Packages restored."
