#!/usr/bin/env bash
# install.sh - Install/update dotfiles configuration
#
# Creates symlinks and applies macOS preferences.
# Run this after bootstrap.sh, or anytime to update config.
#
# Usage:
#   ./install.sh            Create symlinks + apply preferences
#   ./install.sh symlinks   Just create symlinks
#   ./install.sh prefs      Just apply macOS preferences
#   ./install.sh status     Show current symlink status
#   ./install.sh --help     Show help
#
# On a fresh Mac, run ./bootstrap.sh first to install Homebrew.

set -euo pipefail

# Auto-detect dotfiles directory
DOTFILES="$(cd "$(dirname "$0")" && pwd)"
STATE_DIR="$HOME/.dotfiles_state"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${RESET} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${RESET} $1"; }
log_error() { echo -e "${RED}[ERROR]${RESET} $1"; }
log_section() { echo -e "\n${BLUE}==> $1${RESET}\n"; }

# Get profile from state file or environment
get_profile() {
    if [[ -n "${DOTFILES_PROFILE:-}" ]]; then
        echo "$DOTFILES_PROFILE"
    elif [[ -f "$STATE_DIR/profile" ]]; then
        cat "$STATE_DIR/profile"
    else
        echo "desktop"  # Default
    fi
}

usage() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Install/update dotfiles configuration."
    echo ""
    echo "Commands:"
    echo "  (none)      Create symlinks + apply macOS preferences"
    echo "  symlinks    Just create symlinks"
    echo "  prefs       Just apply macOS preferences"
    echo "  status      Show current symlink status"
    echo ""
    echo "Options:"
    echo "  --help      Show this help message"
    echo ""
    echo "Profile: $(get_profile)"
    echo "Dotfiles location: $DOTFILES"
    echo ""
    echo "On a fresh Mac, run ./bootstrap.sh first."
    exit 0
}

# Create symlinks
install_symlinks() {
    log_section "Creating symlinks"

    local symlinks_script="$DOTFILES/bin/dotfiles/symlinks/symlinks_manage.sh"
    if [[ -f "$symlinks_script" ]]; then
        "$symlinks_script" --link
    else
        log_warn "Symlinks script not found: $symlinks_script"
        log_info "Skipping symlinks"
    fi
}

# Apply macOS preferences
install_prefs() {
    log_section "Applying macOS preferences"

    local profile
    profile=$(get_profile)
    log_info "Profile: $profile"

    # Common preferences (works for both desktop and server)
    local prefs_script="$DOTFILES/bin/system/macos/macos_preferences_manage.sh"
    if [[ -f "$prefs_script" ]]; then
        log_info "Applying common macOS preferences..."
        "$prefs_script" --set
    else
        log_warn "Preferences script not found: $prefs_script"
        log_info "Skipping common macOS preferences"
    fi

    # Server-specific preferences
    if [[ "$profile" == "server" ]]; then
        log_section "Applying server-specific settings"

        local server_prefs="$DOTFILES/config/macos/defaults.server.sh"
        if [[ -f "$server_prefs" ]]; then
            log_info "Running server-specific configuration..."
            log_info "This will configure:"
            log_info "  - Energy settings (prevent sleep, wake on network)"
            log_info "  - Screen saver (disabled for headless)"
            log_info "  - Bluetooth (disabled for headless)"
            log_info "  - SSH and Screen Sharing (enabled)"
            log_info "  - Firewall (enabled with stealth mode)"
            log_info "  - Performance optimizations"
            echo ""

            # Run server preferences (may require sudo)
            "$server_prefs"
        else
            log_warn "Server preferences script not found: $server_prefs"
            log_info "Skipping server-specific settings"
        fi
    fi
}

# Show symlink status
show_status() {
    local symlinks_script="$DOTFILES/bin/dotfiles/symlinks/symlinks_manage.sh"
    if [[ -f "$symlinks_script" ]]; then
        "$symlinks_script" --status
    else
        log_error "Symlinks script not found: $symlinks_script"
        exit 1
    fi
}

# Default installation (symlinks + prefs)
do_install() {
    local profile
    profile=$(get_profile)

    echo ""
    echo "===================================================="
    echo "     nathanvale/dotfiles install                    "
    echo "===================================================="
    echo ""
    log_info "Dotfiles location: $DOTFILES"
    log_info "Profile: $profile"

    install_symlinks
    install_prefs

    log_section "Installation complete!"
    echo ""
    log_info "Profile: $profile"
    echo ""
    log_info "Next steps:"
    echo "  1. Restart your terminal (or run: source ~/.zshrc)"
    echo "  2. Copy .env.example to .env and fill in secrets"
    echo "  3. Run 'tmux' to start a tmux session"

    if [[ "$profile" == "server" ]]; then
        echo ""
        log_info "Server-specific verification:"
        echo "  4. Check energy settings: pmset -g"
        echo "  5. Check SSH status: systemsetup -getremotelogin"
        echo "  6. Test SSH from another machine"
    fi
    echo ""
}

# Parse arguments
case "${1:-}" in
    --help|-h)
        usage
        ;;
    symlinks)
        install_symlinks
        ;;
    prefs)
        install_prefs
        ;;
    status)
        show_status
        ;;
    "")
        do_install
        ;;
    *)
        log_error "Unknown command: $1"
        usage
        ;;
esac
