#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
cd "$DOTFILES_DIR"

PACKAGES=(
    zsh bash sway tmux alacritty kitty
    waybar rofi fcitx5 neovim gtk
    nwg-look greetd lazygit xsettingsd
)

echo "Restowing dotfiles packages..."
for pkg in "${PACKAGES[@]}"; do
    if [ -d "$pkg" ]; then
        echo "  -> $pkg"
        stow -R -t "$HOME" "$pkg"
    else
        echo "  -> $pkg (skipped, not found)"
    fi
done

echo "Done!"
