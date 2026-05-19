# Void Linux Sway Desktop Dotfiles

> A comprehensive dotfiles setup for Void Linux with Sway window manager, themed with Catppuccin Macchiato.

## Overview

This repository contains configuration files and setup scripts to bootstrap a fresh Void Linux installation into a fully configured desktop environment with:

- **Window Manager**: Sway (Wayland)
- **Terminal**: Alacritty + Kitty
- **Shell**: Zsh + Oh My Zsh + Powerlevel10k
- **Editor**: Neovim + LazyVim
- **Multiplexer**: Tmux + TPM
- **Bar**: Waybar (with theme switching)
- **Launcher**: Rofi
- **Input**: Fcitx5 with Unikey (Vietnamese)
- **Theme**: Catppuccin Macchiato across all apps

## Prerequisites

- Fresh Void Linux installation
- Network connection
- `git` and `curl` installed (or use the live ISO)

## Quick Start

```bash
# Clone this repo
git clone https://github.com/phatnguyen138/my-dot-files.git ~/dotfiles
cd ~/dotfiles

# Run the bootstrap script
./setup.sh
```

For a dry run (see what would happen without making changes):

```bash
./setup.sh --dry-run
```

To run only a specific phase:

```bash
./setup.sh --phase 1  # System packages + services
./setup.sh --phase 2  # Frameworks (oh-my-zsh, TPM, asdf)
./setup.sh --phase 3  # Dotfiles stow
./setup.sh --phase 4  # Post-install
```

## What's Installed

### System Packages (~95 packages)

See [`packages.txt`](packages.txt) for the full list. Key categories:

- **Wayland/Sway**: sway, swayidle, swaylock, waybar, wl-clipboard
- **Terminal**: alacritty, kitty, tmux, zsh
- **Input**: fcitx5, fcitx5-unikey
- **Audio**: pipewire, wireplumber, pulseaudio-utils
- **Networking**: NetworkManager, openssh
- **Fonts**: nerd-fonts, font-awesome
- **Development**: neovim, git, fzf, ripgrep, fd, lazygit
- **Session**: greetd, tuigreet, elogind, seatd

### Frameworks

- **Oh My Zsh** with plugins: autosuggestions, syntax-highlighting, fast-syntax-highlighting
- **Powerlevel10k** theme
- **TPM** (Tmux Plugin Manager) with catppuccin theme
- **asdf** version manager (installed, languages not included)

### Services Enabled

The following runit services are enabled:

- NetworkManager
- dbus
- elogind
- seatd
- greetd
- docker
- polkitd

## Stow Usage

After pulling updates, re-stow all packages:

```bash
./stow.sh
```

To stow individual packages:

```bash
cd ~/dotfiles
stow -R -t "$HOME" zsh
stow -R -t "$HOME" sway
```

To unstow a package:

```bash
cd ~/dotfiles
stow -D -t "$HOME" zsh
```

## Adding New Configs

1. Create the directory structure: `dotfiles/<app>/.config/<app>/`
2. Add your config files
3. Run: `stow -v -t "$HOME" <app>`

Example:

```bash
mkdir -p ~/dotfiles/myapp/.config/myapp
cp ~/.config/myapp/config.toml ~/dotfiles/myapp/.config/myapp/
cd ~/dotfiles && stow -v -t "$HOME" myapp
```

## Manual Steps

The setup script cannot handle these automatically (requires user interaction or root review):

1. **Set zsh as default shell**:
   ```bash
   chsh -s $(which zsh)
   ```

2. **Copy greetd config** (review before applying):
   ```bash
   sudo mkdir -p /etc/greetd
   sudo cp ~/dotfiles/greetd/config.toml /etc/greetd/config.toml
   ```

3. **Reboot** to start the Sway session via greetd.

## Restricted Packages

Some packages (like `brave-bin`) are not available in the default Void repos. Use the separate builder script:

```bash
./setup-void-packages.sh
```

This clones `void-packages`, enables restricted builds, and builds the packages listed in [`restricted-packages.txt`](restricted-packages.txt).

**Warning**: This requires significant disk space (~10GB+) and build time.

## Troubleshooting

### Symlink conflicts
If stow reports conflicts, back up the existing file and remove it:
```bash
mv ~/.config/sway ~/.config/sway.bak
cd ~/dotfiles && stow -v -t "$HOME" sway
```

### Missing packages
If `setup.sh` fails to install packages, ensure the nonfree repo is enabled:
```bash
sudo xbps-install -Sy void-repo-nonfree
```

### Waybar theme switching
The waybar config includes a theme swap script:
```bash
~/.config/waybar/scripts/swap.sh
```

### Neovim plugins not loading
Run Lazy sync manually:
```bash
nvim --headless '+Lazy! sync' +qa
```

## Structure

```
dotfiles/
├── setup.sh                 # Main bootstrap script
├── stow.sh                  # Re-stow helper
├── setup-void-packages.sh   # Restricted package builder
├── packages.txt             # Curated package list
├── restricted-packages.txt  # Restricted packages to build
├── README.md                # This file
├── alacritty/
├── bash/
├── fcitx5/
├── gtk/
├── greetd/
├── kitty/
├── lazygit/
├── neovim/
├── nwg-look/
├── rofi/
├── sway/
├── tmux/
├── waybar/
├── xsettingsd/
└── zsh/
```

## License

MIT
