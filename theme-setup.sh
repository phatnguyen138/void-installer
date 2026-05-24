#!/usr/bin/env bash
set -euo pipefail

# ============================================
# Theme Setup Script
# Ensures dark mode and Catppuccin theming is
# correctly applied for GTK, portals, and apps.
# ============================================

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[THEME]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ============================================
# Helpers
# ============================================
require_file() {
    if [ ! -f "$1" ]; then
        log_error "Missing file: $1"
        return 1
    fi
}

# Restart portal if running so it picks up new GTK settings
restart_portal() {
    local portal_bin=""
    for path in /usr/libexec/xdg-desktop-portal /usr/lib/xdg-desktop-portal; do
        [ -x "$path" ] && portal_bin="$path" && break
    done

    if [ -z "$portal_bin" ]; then
        log_error "xdg-desktop-portal binary not found."
        log_error "Install it with: sudo xbps-install -Sy xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-wlr"
        return 1
    fi

    if pgrep -x "xdg-desktop-portal" &>/dev/null; then
        log_info "Restarting xdg-desktop-portal to pick up theme changes..."
        pkill -x "xdg-desktop-portal" || true
        sleep 0.5
    fi

    log_info "Starting xdg-desktop-portal..."
    nohup "$portal_bin" &>/dev/null &
    sleep 1

    if pgrep -x "xdg-desktop-portal" &>/dev/null; then
        log_info "Portal is running."
    else
        log_warn "Portal failed to start. It may auto-start via D-Bus when an app requests it."
    fi
}

# ============================================
# GTK Theme Verification
# ============================================
setup_gtk() {
    log_info "Configuring GTK dark mode..."

    local gtk3_settings="$HOME/.config/gtk-3.0/settings.ini"
    local gtk4_settings="$HOME/.config/gtk-4.0/settings.ini"

    if [ ! -f "$gtk3_settings" ]; then
        log_warn "GTK3 settings not found. Ensure 'gtk' package is stowed."
    else
        log_info "GTK3 settings OK."
    fi

    if [ ! -f "$gtk4_settings" ]; then
        log_warn "GTK4 settings not found. Ensure 'gtk' package is stowed."
    else
        log_info "GTK4 settings OK."
    fi

    # Verify dark mode preference is set
    if [ -f "$gtk3_settings" ] && grep -q "gtk-application-prefer-dark-theme=1" "$gtk3_settings"; then
        log_info "GTK3 dark mode preference: ENABLED"
    else
        log_warn "GTK3 dark mode preference not set."
    fi

    if [ -f "$gtk4_settings" ] && grep -q "gtk-application-prefer-dark-theme=1" "$gtk4_settings"; then
        log_info "GTK4 dark mode preference: ENABLED"
    else
        log_warn "GTK4 dark mode preference not set."
    fi
}

# ============================================
# GSettings Color Scheme (for Portal Exposure)
# ============================================
setup_gsettings() {
    log_info "Configuring gsettings color scheme for portal exposure..."

    if ! command -v gsettings &>/dev/null; then
        log_warn "gsettings not found. Install glib or gsettings-desktop-schemas."
        log_warn "Portal-based dark mode detection may not work for Chromium apps."
        return 1
    fi

    local schema="org.gnome.desktop.interface"
    local key="color-scheme"

    if ! gsettings list-schemas 2>/dev/null | grep -q "^${schema}$"; then
        log_warn "gsettings schema '${schema}' not found."
        log_warn "Install: sudo xbps-install -Sy gsettings-desktop-schemas"
        return 1
    fi

    if ! command -v dconf &>/dev/null; then
        log_warn "dconf not found. gsettings values won't persist."
        log_warn "Install: sudo xbps-install -Sy dconf"
        return 1
    fi

    log_info "Setting ${schema} ${key} to 'prefer-dark'..."
    gsettings set "${schema}" "${key}" "prefer-dark"

    local current_value
    current_value=$(gsettings get "${schema}" "${key}")
    if [ "$current_value" = "'prefer-dark'" ]; then
        log_info "gsettings color-scheme: ${current_value}"
    else
        log_warn "gsettings color-scheme returned: ${current_value}"
    fi
}

# ============================================
# Portal Configuration
# ============================================
setup_portal() {
    log_info "Configuring xdg-desktop-portal..."

    local portal_conf="$HOME/.config/xdg-desktop-portal/portals.conf"

    if [ ! -f "$portal_conf" ]; then
        log_warn "Portal config not found. Ensure 'xdg-desktop-portal' package is stowed."
        return 1
    fi

    if grep -q "org.freedesktop.impl.portal.Settings=gtk" "$portal_conf"; then
        log_info "Portal Settings backend: gtk (dark mode will be exposed to apps)"
    else
        log_warn "Portal Settings backend not configured to gtk."
    fi
}

# ============================================
# Portal Debug: query what the portal actually returns
# ============================================
debug_portal() {
    log_info "Querying xdg-desktop-portal for color-scheme..."

    local portal_reply
    portal_reply=$(dbus-send --print-reply \
        --dest=org.freedesktop.portal.Desktop \
        /org/freedesktop/portal/desktop \
        org.freedesktop.portal.Settings.Read \
        string:'org.freedesktop.appearance' \
        string:'color-scheme' 2>/dev/null)

    if [ -z "$portal_reply" ]; then
        log_warn "Portal did not respond. Is xdg-desktop-portal running?"
        log_info "Check: ps aux | grep xdg-desktop-portal"
        return 1
    fi

    local color_value
    color_value=$(echo "$portal_reply" | grep -oP 'uint32 \K[0-9]+' | tail -1)

    case "$color_value" in
        0)
            log_warn "Portal color-scheme = 0 (NO PREFERENCE)"
            log_warn "Chromium will use LIGHT mode."
            log_info "Fix: ensure gsettings org.gnome.desktop.interface color-scheme = 'prefer-dark'"
            ;;
        1)
            log_info "Portal color-scheme = 1 (PREFER DARK)"
            log_info "Chromium should detect dark mode."
            ;;
        2)
            log_warn "Portal color-scheme = 2 (PREFER LIGHT)"
            log_warn "Chromium will use LIGHT mode."
            ;;
        *)
            log_warn "Portal returned unexpected value: ${color_value:-<empty>}"
            log_info "Raw reply: ${portal_reply}"
            ;;
    esac
}

# ============================================
# nwg-look Export (if available)
# ============================================
setup_nwglook() {
    if command -v nwg-look &>/dev/null; then
        log_info "Running nwg-look export to sync GTK settings..."
        nwg-look -x || log_warn "nwg-look export failed."
    else
        log_warn "nwg-look not installed. GTK settings rely on static config files."
    fi
}

# ============================================
# Brave Browser Dark Mode
# ============================================
setup_brave() {
    log_info "Checking Brave browser configuration..."

    local brave_prefs="$HOME/.config/BraveSoftware/Brave-Browser/Default/Preferences"

    if [ ! -f "$brave_prefs" ]; then
        log_warn "Brave preferences not found. Launch Brave at least once first."
        log_info "After launching Brave, run: brave://settings/appearance"
        log_info "Or add this flag to the launch command: --force-dark-mode"
        return 0
    fi

    # Check if force-dark-mode is in the prefs (jq is not always available, use grep)
    if grep -q '"force_dark_mode"' "$brave_prefs" 2>/dev/null; then
        log_info "Brave force-dark-mode already set in preferences."
    else
        log_warn "Brave dark mode preference not found in config."
        log_info "Tip: Launch Brave with: brave --force-dark-mode"
        log_info "Or enable 'Dark mode' in brave://settings/appearance"
    fi
}

# ============================================
# Environment Check
# ============================================
check_env() {
    log_info "Checking session environment..."

    if [ -z "${WAYLAND_DISPLAY:-}" ]; then
        log_warn "WAYLAND_DISPLAY not set. Portal may not work correctly outside a Wayland session."
    else
        log_info "WAYLAND_DISPLAY=$WAYLAND_DISPLAY"
    fi

    if [ -z "${XDG_CURRENT_DESKTOP:-}" ]; then
        log_warn "XDG_CURRENT_DESKTOP not set. Some apps may not detect the desktop environment."
    else
        log_info "XDG_CURRENT_DESKTOP=$XDG_CURRENT_DESKTOP"
    fi
}

# ============================================
# Main
# ============================================
main() {
    echo "============================================"
    echo "  Theme / Dark Mode Setup"
    echo "============================================"
    echo

    cd "$DOTFILES_DIR" 2>/dev/null || true

    check_env
    setup_gtk
    setup_gsettings
    setup_portal
    setup_nwglook
    setup_brave

    echo
    log_info "Restarting portal to ensure apps pick up theme changes..."
    restart_portal

    echo
    debug_portal

    echo
    echo "============================================"
    log_info "Theme setup complete!"
    echo "============================================"
    echo
    echo "Next steps:"
    echo "  1. Log out and back in (or reload Sway: Mod+Shift+c)"
    echo "  2. Launch Brave and verify dark mode in brave://settings/appearance"
    echo "  3. If still light, try:  brave --force-dark-mode"
}

main "$@"
