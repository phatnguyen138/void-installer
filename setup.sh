#!/usr/bin/env bash
set -euo pipefail

# ============================================
# Void Linux Desktop Bootstrap
# ============================================

DOTFILES_REPO="https://github.com/phatnguyen138/my-dot-files.git"
DOTFILES_DIR="$HOME/dotfiles"
DRY_RUN=false
PHASE="all"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

dry_run_echo() {
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY-RUN] Would execute: $1"
    else
        eval "$1"
    fi
}

# ============================================
# Phase 1: System Setup
# ============================================
phase1_system() {
    log_info "=== Phase 1: System Setup ==="

    # Enable nonfree repo
    if ! xbps-query -l | grep -q "void-repo-nonfree"; then
        dry_run_echo "sudo xbps-install -Sy void-repo-nonfree"
    fi

    # Install packages from packages.txt
    if [ -f "$DOTFILES_DIR/packages.txt" ]; then
        local pkgs
        pkgs=$(grep -v '^#' "$DOTFILES_DIR/packages.txt" | grep -v '^$' | grep -v '^# SERVICES' | sed '/^# /,$d' | tr '\n' ' ')
        dry_run_echo "sudo xbps-install -Sy $pkgs"
    fi

    # Enable services
    local services=("NetworkManager" "dbus" "elogind" "seatd" "greetd" "docker" "polkitd")
    for svc in "${services[@]}"; do
        if [ ! -e "/var/service/$svc" ]; then
            dry_run_echo "sudo ln -sf /etc/sv/$svc /var/service/"
        fi
    done

    log_info "Phase 1 complete"
}

# ============================================
# Phase 2: Frameworks
# ============================================
phase2_frameworks() {
    log_info "=== Phase 2: Frameworks ==="

    # oh-my-zsh
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        # shellcheck disable=SC2016
        dry_run_echo 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'
    fi

    # Custom plugins
    local plugins=(
        "zsh-users/zsh-autosuggestions"
        "zsh-users/zsh-syntax-highlighting"
        "zdharma-continuum/fast-syntax-highlighting"
    )
    for plugin in "${plugins[@]}"; do
        local name
        name=$(basename "$plugin")
        if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/$name" ]; then
            dry_run_echo "git clone https://github.com/$plugin.git $HOME/.oh-my-zsh/custom/plugins/$name"
        fi
    done

    # powerlevel10k
    if [ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
        dry_run_echo "git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $HOME/.oh-my-zsh/custom/themes/powerlevel10k"
    fi

    # TPM
    if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
        dry_run_echo "git clone https://github.com/tmux-plugins/tpm.git $HOME/.tmux/plugins/tpm"
    fi

    # Install TPM plugins
    if [ -f "$HOME/.tmux/plugins/tpm/bin/install_plugins" ]; then
        dry_run_echo "$HOME/.tmux/plugins/tpm/bin/install_plugins"
    fi

    # asdf
    if [ ! -d "$HOME/.asdf" ]; then
        dry_run_echo "git clone https://github.com/asdf-vm/asdf.git $HOME/.asdf --branch v0.16.7"
    fi

    log_info "Phase 2 complete"
}

# ============================================
# Phase 3: Dotfiles
# ============================================
phase3_dotfiles() {
    log_info "=== Phase 3: Dotfiles ==="

    # Clone dotfiles if not present
    if [ ! -d "$DOTFILES_DIR/.git" ]; then
        dry_run_echo "git clone $DOTFILES_REPO $DOTFILES_DIR"
    fi

    # Stow packages
    cd "$DOTFILES_DIR"
    local packages=(
        "zsh" "bash" "sway" "tmux" "alacritty" "kitty"
        "waybar" "rofi" "fcitx5" "neovim" "gtk"
        "nwg-look" "greetd" "lazygit" "xsettingsd"
    )

    for pkg in "${packages[@]}"; do
        if [ -d "$DOTFILES_DIR/$pkg" ]; then
            if [ "$DRY_RUN" = true ]; then
                echo "[DRY-RUN] Would stow: $pkg"
                stow -n -v -t "$HOME" "$pkg" 2>&1 || true
            else
                log_info "Stowing $pkg..."
                stow -v -t "$HOME" "$pkg" 2>&1 || log_warn "Failed to stow $pkg (may already exist)"
            fi
        fi
    done

    log_info "Phase 3 complete"
}

# ============================================
# Phase 4: Post-Install
# ============================================
phase4_postinstall() {
    log_info "=== Phase 4: Post-Install ==="

    # Create directories
    dry_run_echo "mkdir -p $HOME/screenshorts $HOME/Projects $HOME/Downloads"

    # Install neovim plugins
    if command -v nvim &> /dev/null; then
        dry_run_echo "nvim --headless '+Lazy! sync' +qa"
    fi

    # Set zsh as default (with confirmation)
    if [ "$SHELL" != "$(which zsh)" ]; then
        log_warn "To set zsh as default shell, run: chsh -s $(which zsh)"
    fi

    # Note about greetd
    log_warn "Manual step required: copy greetd config"
    log_warn "  sudo mkdir -p /etc/greetd"
    log_warn "  sudo cp $DOTFILES_DIR/greetd/config.toml /etc/greetd/config.toml"

    log_info "Phase 4 complete"
    log_info "Setup complete! Please reboot to start Sway."
}

# ============================================
# Main
# ============================================
main() {
    # Parse args
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --phase)
                PHASE="$2"
                shift 2
                ;;
            --help|-h)
                echo "Usage: $0 [--dry-run] [--phase <1-4|all>]"
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    if [ "$DRY_RUN" = true ]; then
        log_warn "DRY-RUN MODE: Commands will be printed, not executed"
    fi

    case $PHASE in
        1) phase1_system ;;
        2) phase2_frameworks ;;
        3) phase3_dotfiles ;;
        4) phase4_postinstall ;;
        all)
            phase1_system
            phase2_frameworks
            phase3_dotfiles
            phase4_postinstall
            ;;
        *)
            log_error "Unknown phase: $PHASE"
            exit 1
            ;;
    esac
}

main "$@"
