#!/bin/bash
# bootstrap.sh - One-time setup for a fresh Mac
#
# This script installs Homebrew and all packages from Brewfile.
# Run this ONCE on a fresh Mac, then use install.sh for config.
#
# Usage:
#   ./bootstrap.sh          Install Homebrew + all packages
#   ./bootstrap.sh --help   Show help
#
# On a fresh Mac:
#   1. git clone git@github.com:nathanvale/dotfiles.git ~/code/dotfiles
#   2. cd ~/code/dotfiles
#   3. ./bootstrap.sh       # One-time: Homebrew + packages
#   4. ./install.sh         # Symlinks + preferences

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
	echo "Usage: $0"
	echo ""
	echo "One-time bootstrap for a fresh Mac."
	echo "Installs Homebrew and all packages from Brewfile."
	echo ""
	echo "Options:"
	echo "  --help      Show this help message"
	echo ""
	echo "After running this, use ./install.sh for symlinks + preferences."
	exit 0
}

# Check for Xcode Command Line Tools
check_xcode_clt() {
	if ! xcode-select -p &>/dev/null; then
		log_warn "Xcode Command Line Tools not installed"
		log_info "Installing Xcode Command Line Tools..."
		xcode-select --install
		echo "Press any key after installation completes..."
		read -n 1 -s
	else
		log_info "Xcode Command Line Tools already installed"
	fi
}

# Install Homebrew if not present
install_homebrew() {
	if ! command -v brew &>/dev/null; then
		log_info "Installing Homebrew..."
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

		# Add Homebrew to PATH for this session
		if [[ -f /opt/homebrew/bin/brew ]]; then
			eval "$(/opt/homebrew/bin/brew shellenv)"
		fi
	else
		log_info "Homebrew already installed"
	fi
}

# Install packages from Brewfile
install_brew_packages() {
	if [[ ! -f "$DOTFILES/config/brew/Brewfile" ]]; then
		log_error "Brewfile not found: $DOTFILES/config/brew/Brewfile"
		return 1
	fi

	brew bundle --file="$DOTFILES/config/brew/Brewfile"
	log_info "Homebrew packages installed"
}

# Main
case "${1:-}" in
--help | -h)
	usage
	;;
"")
	echo ""
	echo "╔═══════════════════════════════════════════════════╗"
	echo "║     nathanvale/dotfiles bootstrap                 ║"
	echo "╚═══════════════════════════════════════════════════╝"
	echo ""
	log_info "Dotfiles location: $DOTFILES"

	log_section "Checking prerequisites"
	check_xcode_clt

	log_section "Installing Homebrew"
	install_homebrew

	log_section "Installing packages from Brewfile"
	install_brew_packages

	log_section "Bootstrap complete!"
	echo ""
	log_info "Next step: ./install.sh"
	echo ""
	;;
*)
	log_error "Unknown option: $1"
	usage
	;;
esac
