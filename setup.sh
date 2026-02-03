#!/usr/bin/env bash
# setup.sh - One-liner dotfiles installer with machine profiles
#
# Usage (run this on a fresh Mac):
#   curl -fsSL https://raw.githubusercontent.com/nathanvale/dotfiles/main/setup.sh | bash
#   curl -fsSL ... | bash -s -- --server   # Server profile (Mac Mini)
#   curl -fsSL ... | bash -s -- --desktop  # Desktop profile (MacBook Pro)
#
# Or download and inspect first:
#   curl -fsSL https://raw.githubusercontent.com/nathanvale/dotfiles/main/setup.sh -o setup.sh
#   less setup.sh
#   bash setup.sh --desktop
#
# Profiles:
#   --desktop  MacBook Pro with GUI apps, development tools, AI desktop apps
#   --server   Mac Mini headless server with OrbStack, Ollama, server settings

# Wrapper function pattern ensures entire script is parsed before execution
# This is critical for curl | bash safety
main() {
    set -euo pipefail

    # Configuration
    DOTFILES_REPO="git@github.com:nathanvale/dotfiles.git"
    DOTFILES_REPO_HTTPS="https://github.com/nathanvale/dotfiles.git"
    DOTFILES_DIR="$HOME/code/dotfiles"
    STATE_DIR="$HOME/.dotfiles_state"

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

    # Parse command line arguments
    PROFILE=""
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --server|-s)
                PROFILE="server"
                shift
                ;;
            --desktop|-d)
                PROFILE="desktop"
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [--desktop | --server]"
                echo ""
                echo "Options:"
                echo "  --desktop, -d   Desktop profile (MacBook Pro) - default"
                echo "  --server, -s    Server profile (Mac Mini headless)"
                echo "  --help, -h      Show this help message"
                echo ""
                echo "One-liner installation:"
                echo "  curl -fsSL https://raw.githubusercontent.com/nathanvale/dotfiles/main/setup.sh | bash"
                echo "  curl ... | bash -s -- --server"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done

    echo ""
    echo "===================================================="
    echo "     nathanvale/dotfiles setup                      "
    echo "===================================================="
    echo ""

    # Profile selection
    if [[ -z "$PROFILE" ]]; then
        # Check if stdin is a terminal (interactive) or pipe (curl | bash)
        if [[ -t 0 ]]; then
            # Interactive mode - prompt for profile
            echo "Select machine profile:"
            echo "  1) Desktop (MacBook Pro) - GUI apps, development tools"
            echo "  2) Server (Mac Mini) - headless, containers, AI workloads"
            echo ""
            read -p "Choice [1/2] (default: 1): " -n 1 -r
            echo
            case $REPLY in
                2) PROFILE="server" ;;
                *) PROFILE="desktop" ;;
            esac
        else
            # Piped input (curl | bash) - require explicit flag
            log_error "Profile not specified. When using curl | bash, you must specify a profile."
            echo ""
            echo "Usage:"
            echo "  curl ... | bash -s -- --desktop   # Desktop profile"
            echo "  curl ... | bash -s -- --server    # Server profile"
            exit 1
        fi
    fi

    log_info "Selected profile: $PROFILE"

    # Save profile to state directory for child scripts
    mkdir -p "$STATE_DIR"
    echo "$PROFILE" > "$STATE_DIR/profile"

    # Export for child scripts (belt and suspenders)
    export DOTFILES_PROFILE="$PROFILE"

    # Check if dotfiles already exist
    if [[ -d "$DOTFILES_DIR" ]]; then
        log_warn "Dotfiles directory already exists: $DOTFILES_DIR"

        if [[ -t 0 ]]; then
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
            # Non-interactive: just pull
            log_info "Pulling latest changes..."
            cd "$DOTFILES_DIR"
            git pull
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
    log_section "Ready to install ($PROFILE profile)"
    echo ""
    echo "This will:"
    echo "  1. Install Xcode Command Line Tools (if needed)"
    echo "  2. Install Homebrew (if needed)"
    echo "  3. Install Claude Code (Phase 2 - AI rescue)"
    echo "  4. Install all packages from Brewfile.$PROFILE"
    echo "  5. Create symlinks for dotfiles"
    echo "  6. Apply macOS preferences"
    if [[ "$PROFILE" == "server" ]]; then
        echo "  7. Apply server-specific settings (pmset, SSH, firewall)"
    fi
    echo ""

    if [[ -t 0 ]]; then
        read -p "Continue with full installation? [y/N] " -n 1 -r
        echo
        PROCEED=$([[ $REPLY =~ ^[Yy]$ ]] && echo "yes" || echo "no")
    else
        # Non-interactive: proceed automatically
        PROCEED="yes"
    fi

    if [[ "$PROCEED" == "yes" ]]; then
        log_section "Running bootstrap (Homebrew + packages)"
        ./bootstrap.sh

        log_section "Running install (symlinks + preferences)"
        ./install.sh

        log_section "Setup complete!"
        echo ""
        log_info "Profile: $PROFILE"
        log_info "Dotfiles location: $DOTFILES_DIR"
        echo ""
        echo "Next steps:"
        echo "  1. Restart your terminal (or run: source ~/.zshrc)"
        echo "  2. Copy .env.example to .env and add your secrets"
        echo "  3. Run 'tmux' to start a session"
        if [[ "$PROFILE" == "server" ]]; then
            echo "  4. Verify server settings: pmset -g"
            echo "  5. Test SSH access from another machine"
        fi
        echo ""

        # Run verification if available
        if [[ -f "$DOTFILES_DIR/verify_install.sh" ]]; then
            log_section "Running installation verification"
            "$DOTFILES_DIR/verify_install.sh"
        fi
    else
        log_info "Skipped. Run these manually when ready:"
        echo ""
        echo "  cd $DOTFILES_DIR"
        echo "  export DOTFILES_PROFILE=$PROFILE"
        echo "  ./bootstrap.sh    # Homebrew + packages"
        echo "  ./install.sh      # Symlinks + preferences"
        echo ""
    fi
}

# Execute main function with all arguments
main "$@"
