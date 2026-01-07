#!/bin/bash
# setup.sh - One-liner dotfiles installer
#
# Usage (run this on a fresh Mac):
#   curl -fsSL https://raw.githubusercontent.com/nathanvale/dotfiles/main/setup.sh | bash
#
# Or download and inspect first:
#   curl -fsSL https://raw.githubusercontent.com/nathanvale/dotfiles/main/setup.sh -o setup.sh
#   less setup.sh
#   bash setup.sh

set -e

# Configuration
DOTFILES_REPO="git@github.com:nathanvale/dotfiles.git"
DOTFILES_REPO_HTTPS="https://github.com/nathanvale/dotfiles.git"
DOTFILES_DIR="$HOME/code/dotfiles"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${RESET} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${RESET} $1"; }
log_error() { echo -e "${RED}[ERROR]${RESET} $1"; }
log_section() { echo -e "\n${BLUE}==> $1${RESET}\n"; }

echo ""
echo "╔═══════════════════════════════════════════════════╗"
echo "║     nathanvale/dotfiles setup                     ║"
echo "╚═══════════════════════════════════════════════════╝"
echo ""

# Check if dotfiles already exist
if [[ -d "$DOTFILES_DIR" ]]; then
	log_warn "Dotfiles directory already exists: $DOTFILES_DIR"
	read -p "Pull latest changes and continue? [y/N] " -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		cd "$DOTFILES_DIR"
		git pull
	else
		log_info "Exiting. Run ./bootstrap.sh and ./install.sh manually."
		exit 0
	fi
else
	log_section "Cloning dotfiles repository"

	# Create parent directory
	mkdir -p "$(dirname "$DOTFILES_DIR")"

	# Try SSH first, fall back to HTTPS
	if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
		log_info "Using SSH to clone"
		git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
	else
		log_warn "SSH not configured, using HTTPS"
		git clone "$DOTFILES_REPO_HTTPS" "$DOTFILES_DIR"
	fi

	cd "$DOTFILES_DIR"
fi

# Prompt for bootstrap
log_section "Ready to install"
echo ""
echo "This will:"
echo "  1. Install Xcode Command Line Tools (if needed)"
echo "  2. Install Homebrew (if needed)"
echo "  3. Install all packages from Brewfile"
echo "  4. Create symlinks for dotfiles"
echo "  5. Apply macOS preferences"
echo ""
read -p "Continue with full installation? [y/N] " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
	log_section "Running bootstrap (Homebrew + packages)"
	./bootstrap.sh

	log_section "Running install (symlinks + preferences)"
	./install.sh

	log_section "Setup complete!"
	echo ""
	log_info "Your dotfiles are installed at: $DOTFILES_DIR"
	echo ""
	echo "Next steps:"
	echo "  1. Restart your terminal"
	echo "  2. Copy .env.example to .env and add your secrets"
	echo "  3. Run 'tmux' to start a session"
	echo ""
else
	log_info "Skipped. Run these manually when ready:"
	echo ""
	echo "  cd $DOTFILES_DIR"
	echo "  ./bootstrap.sh    # Homebrew + packages"
	echo "  ./install.sh      # Symlinks + preferences"
	echo ""
fi
