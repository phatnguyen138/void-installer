#!/usr/bin/env bash
set -euo pipefail

VOID_PKGS_DIR="$HOME/void_tools/void-packages"
RESTRICTED_FILE="${RESTRICTED_FILE:-$HOME/dotfiles/restricted-packages.txt}"
DRY_RUN=false

log_info() { echo -e "\033[0;32m[INFO]\033[0m $1"; }
log_warn() { echo -e "\033[1;33m[WARN]\033[0m $1"; }

# Parse args
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--dry-run]"
            echo ""
            echo "Builds restricted packages from void-packages."
            echo "Requires significant disk space and build time."
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Clone void-packages if not present
if [ ! -d "$VOID_PKGS_DIR/.git" ]; then
    log_info "Cloning void-packages..."
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY-RUN] Would clone: git clone https://github.com/void-linux/void-packages.git $VOID_PKGS_DIR"
    else
        mkdir -p "$(dirname "$VOID_PKGS_DIR")"
        git clone https://github.com/void-linux/void-packages.git "$VOID_PKGS_DIR"
    fi
else
    log_info "void-packages already cloned"
fi

# Bootstrap build environment
if [ ! -f "$VOID_PKGS_DIR/xbps-src" ]; then
    log_info "Bootstrapping void-packages..."
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY-RUN] Would run: $VOID_PKGS_DIR/xbps-src binary-bootstrap"
    else
        "$VOID_PKGS_DIR/xbps-src" binary-bootstrap
    fi
else
    log_info "Build environment already bootstrapped"
fi

# Enable restricted packages
if [ "$DRY_RUN" = false ]; then
    if ! grep -q "XBPS_ALLOW_RESTRICTED=yes" "$VOID_PKGS_DIR/etc/conf" 2>/dev/null; then
        log_info "Enabling restricted packages..."
        echo "XBPS_ALLOW_RESTRICTED=yes" >> "$VOID_PKGS_DIR/etc/conf"
    fi
fi

# Build restricted packages
if [ -f "$RESTRICTED_FILE" ]; then
    while IFS= read -r pkg; do
        # Skip comments and empty lines
        [[ "$pkg" =~ ^#.*$ ]] && continue
        [[ -z "$pkg" ]] && continue

        log_info "Building $pkg..."
        if [ "$DRY_RUN" = true ]; then
            echo "[DRY-RUN] Would build: $VOID_PKGS_DIR/xbps-src pkg $pkg"
        else
            "$VOID_PKGS_DIR/xbps-src" pkg "$pkg"
        fi

        log_info "Installing $pkg..."
        if [ "$DRY_RUN" = true ]; then
            echo "[DRY-RUN] Would install: xi $pkg"
        else
            # xi is installed by xtools
            xi "$pkg" || sudo xbps-install --repository="$VOID_PKGS_DIR/hostdir/binpkgs" "$pkg"
        fi
    done < "$RESTRICTED_FILE"
else
    log_warn "No restricted-packages.txt found at $RESTRICTED_FILE"
fi

log_info "Done!"
