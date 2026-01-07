#!/bin/bash
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

set -e

# Auto-detect dotfiles directory
DOTFILES="$(cd "$(dirname "$0")" && pwd)"

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
	echo "Dotfiles location: $DOTFILES"
	echo ""
	echo "On a fresh Mac, run ./bootstrap.sh first."
	exit 0
}

# Create symlinks
install_symlinks() {
	log_section "Creating symlinks"
	"$DOTFILES/bin/dotfiles/symlinks/symlinks_manage.sh" --link
}

# Apply macOS preferences
install_prefs() {
	log_section "Applying macOS preferences"

	local prefs_script="$DOTFILES/bin/dotfiles/preferences/preferences_install.sh"
	if [[ -f "$prefs_script" ]]; then
		"$prefs_script"
	else
		log_warn "Preferences script not found: $prefs_script"
		log_info "Skipping macOS preferences"
	fi
}

# Show symlink status
show_status() {
	"$DOTFILES/bin/dotfiles/symlinks/symlinks_manage.sh" --status
}

# Default installation (symlinks + prefs)
do_install() {
	echo ""
	echo "╔═══════════════════════════════════════════════════╗"
	echo "║     nathanvale/dotfiles install                   ║"
	echo "╚═══════════════════════════════════════════════════╝"
	echo ""
	log_info "Dotfiles location: $DOTFILES"

	install_symlinks
	install_prefs

	log_section "Installation complete!"
	echo ""
	log_info "Next steps:"
	echo "  1. Restart your terminal (or run: source ~/.zshrc)"
	echo "  2. Copy .env.example to .env and fill in secrets"
	echo "  3. Run 'tmux' to start a tmux session"
	echo ""
}

# Parse arguments
case "${1:-}" in
--help | -h)
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
