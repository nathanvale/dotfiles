#!/usr/bin/env bash
# setup.sh - Unified dotfiles installer with machine profiles
#
# 7-Phase Architecture:
#   Phase 0: Preflight     (~5s)   - Validate environment, check requirements
#   Phase 1: Foundation    (~2m)   - Xcode CLT + Homebrew + repo clone
#   Phase 2: AI Rescue     (~30s)  - Claude Code ONLY (enables AI debugging)
#   Phase 3: Core Tools    (~3m)   - Essential CLI (git, zsh, tmux, etc.)
#   Phase 4: Development   (~5m)   - Language runtimes (bun, python, node)
#   Phase 5: Applications  (~10m)  - GUI apps from Brewfile
#   Phase 6: Configuration (~2m)   - Symlinks + macOS preferences
#
# Usage (fresh Mac - one-liner):
#   curl -fsSL https://raw.githubusercontent.com/nathanvale/dotfiles/main/setup.sh | bash
#   curl -fsSL ... | bash -s -- --server   # Server profile (Mac Mini)
#   curl -fsSL ... | bash -s -- --desktop  # Desktop profile (MacBook Pro)
#
# Usage (from repo):
#   ./setup.sh [--desktop|--server]        # Full install (phases 0-6)
#   ./setup.sh --resume                    # Resume from checkpoint
#   ./setup.sh --start-phase N             # Start from phase N
#   ./setup.sh symlinks                    # Just create symlinks
#   ./setup.sh prefs                       # Just apply macOS preferences
#   ./setup.sh status                      # Show symlink status
#   ./setup.sh verify                      # Run verify_install.sh
#   ./setup.sh --help                      # Show help
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
    LOG_FILE="$STATE_DIR/setup.log"

    # Colors
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    RESET='\033[0m'

    # Ensure state directory exists
    mkdir -p "$STATE_DIR"

    # ========================================================================
    # Logging functions
    # ========================================================================
    log() {
        local msg="[$(date +%H:%M:%S)] $1"
        echo -e "${GREEN}$msg${RESET}"
        echo "$msg" >> "$LOG_FILE"
    }

    log_warn() {
        local msg="[$(date +%H:%M:%S)] WARNING: $1"
        echo -e "${YELLOW}$msg${RESET}"
        echo "$msg" >> "$LOG_FILE"
    }

    log_error() {
        local msg="[$(date +%H:%M:%S)] ERROR: $1"
        echo -e "${RED}$msg${RESET}"
        echo "$msg" >> "$LOG_FILE"
    }

    log_phase() {
        local msg="=== PHASE $1: $2 ==="
        echo -e "\n${CYAN}$msg${RESET}\n"
        echo "" >> "$LOG_FILE"
        echo "$msg" >> "$LOG_FILE"
    }

    log_section() {
        echo -e "\n${BLUE}==> $1${RESET}\n"
    }

    # ========================================================================
    # Sudo management
    # ========================================================================
    acquire_sudo() {
        log "Requesting administrator access (you may be prompted for your password)..."

        # Use /dev/tty for password prompt - required for curl | bash flow
        # where stdin is the pipe, not the terminal
        if ! sudo -v < /dev/tty 2>&1; then
            log_error "Failed to acquire sudo access. Some phases require administrator privileges."
            exit 1
        fi
        log "Administrator access: OK"

        # Keep sudo alive in background (refresh every 50s, timeout is 5min)
        while true; do
            sudo -n true 2>/dev/null
            sleep 50
        done &
        SUDO_KEEPALIVE_PID=$!
    }

    release_sudo() {
        if [[ -n "${SUDO_KEEPALIVE_PID:-}" ]]; then
            kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
            wait "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
            unset SUDO_KEEPALIVE_PID
        fi
    }

    # ========================================================================
    # Profile helpers
    # ========================================================================
    get_profile() {
        if [[ -n "${DOTFILES_PROFILE:-}" ]]; then
            echo "$DOTFILES_PROFILE"
        elif [[ -f "$STATE_DIR/profile" ]]; then
            cat "$STATE_DIR/profile"
        else
            echo "desktop"  # Default
        fi
    }

    # ========================================================================
    # Checkpoint system
    # ========================================================================
    save_checkpoint() {
        local phase="$1"
        echo "$phase" > "$STATE_DIR/checkpoint"
        echo "$(date -Iseconds) - Phase $phase completed" >> "$STATE_DIR/history"
    }

    get_checkpoint() {
        if [[ -f "$STATE_DIR/checkpoint" ]]; then
            cat "$STATE_DIR/checkpoint"
        else
            echo "0"
        fi
    }

    clear_checkpoint() {
        rm -f "$STATE_DIR/checkpoint"
    }

    # ========================================================================
    # Usage
    # ========================================================================
    usage() {
        echo "Usage: $0 [OPTIONS] [COMMAND]"
        echo ""
        echo "Unified dotfiles installer for macOS."
        echo ""
        echo "Commands (run from repo):"
        echo "  symlinks         Just create symlinks"
        echo "  prefs            Just apply macOS preferences"
        echo "  status           Show current symlink status"
        echo "  verify           Run installation verification"
        echo ""
        echo "Options:"
        echo "  --desktop, -d    Desktop profile (MacBook Pro) - default"
        echo "  --server, -s     Server profile (Mac Mini headless)"
        echo "  --resume         Resume from last checkpoint"
        echo "  --start-phase N  Start from phase N (0-6)"
        echo "  --help, -h       Show this help message"
        echo ""
        echo "Phases:"
        echo "  0: Preflight     - Validate environment"
        echo "  1: Foundation    - Xcode CLT + Homebrew + repo clone"
        echo "  2: AI Rescue     - Claude Code (enables AI debugging)"
        echo "  3: Core Tools    - Essential CLI tools"
        echo "  4: Development   - Language runtimes"
        echo "  5: Applications  - GUI apps from Brewfile"
        echo "  6: Configuration - Symlinks + macOS preferences"
        echo ""
        echo "Full install (fresh Mac):"
        echo "  curl -fsSL https://raw.githubusercontent.com/nathanvale/dotfiles/main/setup.sh | bash"
        echo "  curl ... | bash -s -- --server"
        echo ""
        echo "Update existing installation:"
        echo "  ./setup.sh symlinks    # Recreate symlinks"
        echo "  ./setup.sh prefs       # Reapply macOS preferences"
        echo ""
        echo "Profile: $(get_profile)"
        exit 0
    }

    # ========================================================================
    # Subcommands
    # ========================================================================

    # Auto-detect dotfiles directory (for subcommands run from repo)
    detect_dotfiles_dir() {
        if [[ -d "$DOTFILES_DIR" ]]; then
            echo "$DOTFILES_DIR"
        else
            # Fall back to script location
            cd "$(dirname "$0")" && pwd
        fi
    }

    install_symlinks() {
        local dotfiles
        dotfiles=$(detect_dotfiles_dir)
        log_section "Creating symlinks"

        local symlinks_script="$dotfiles/bin/dotfiles/symlinks/symlinks_manage.sh"
        if [[ -f "$symlinks_script" ]]; then
            # Use --force in non-interactive mode (e.g., curl | bash)
            if [[ -t 0 ]]; then
                "$symlinks_script" --link
            else
                "$symlinks_script" --link --force
            fi
        else
            log_warn "Symlinks script not found: $symlinks_script"
        fi
    }

    install_prefs() {
        local dotfiles
        dotfiles=$(detect_dotfiles_dir)
        local profile
        profile=$(get_profile)

        log_section "Applying macOS preferences"
        log "Profile: $profile"

        # Common preferences (works for both desktop and server)
        local prefs_script="$dotfiles/config/macos/defaults.common.sh"
        if [[ -f "$prefs_script" ]]; then
            log "Applying common macOS preferences..."
            "$prefs_script" --set
        else
            log_warn "Preferences script not found: $prefs_script"
        fi

        # Server-specific preferences
        if [[ "$profile" == "server" ]]; then
            log_section "Applying server-specific settings"

            local server_prefs="$dotfiles/config/macos/defaults.server.sh"
            if [[ -f "$server_prefs" ]]; then
                log "Running server-specific configuration..."
                log "This will configure:"
                log "  - Energy settings (prevent sleep, wake on network)"
                log "  - Screen saver (disabled for headless)"
                log "  - Bluetooth (disabled for headless)"
                log "  - SSH and Screen Sharing (enabled)"
                log "  - Firewall (enabled with stealth mode)"
                log "  - Performance optimizations"
                echo ""

                # Run server preferences (may require sudo)
                "$server_prefs"
            else
                log_warn "Server preferences script not found: $server_prefs"
            fi
        fi
    }

    show_status() {
        local dotfiles
        dotfiles=$(detect_dotfiles_dir)
        local symlinks_script="$dotfiles/bin/dotfiles/symlinks/symlinks_manage.sh"
        if [[ -f "$symlinks_script" ]]; then
            "$symlinks_script" --status
        else
            log_error "Symlinks script not found: $symlinks_script"
            exit 1
        fi
    }

    run_verify() {
        local dotfiles
        dotfiles=$(detect_dotfiles_dir)
        if [[ -f "$dotfiles/verify_install.sh" ]]; then
            "$dotfiles/verify_install.sh" "$@"
        else
            log_error "verify_install.sh not found: $dotfiles/verify_install.sh"
            exit 1
        fi
    }

    # Handle subcommand routing
    run_subcommand() {
        local cmd="$1"
        shift
        case "$cmd" in
            symlinks)
                install_symlinks
                ;;
            prefs)
                install_prefs
                ;;
            status)
                show_status
                ;;
            verify)
                run_verify "$@"
                ;;
        esac
    }

    # ========================================================================
    # Phase 0: Preflight Checks
    # ========================================================================
    phase_0_preflight() {
        log_phase 0 "Preflight checks"

        # Check macOS version (require Sequoia 15+ or Tahoe 26+)
        local os_version
        os_version=$(sw_vers -productVersion)
        local major_version
        major_version=$(echo "$os_version" | cut -d. -f1)

        if [[ "$major_version" -lt 15 ]]; then
            log_error "Requires macOS 15+ (Sequoia/Tahoe). Found: $os_version"
            exit 1
        fi
        log "macOS version: $os_version"

        # Check architecture (Apple Silicon only)
        local arch
        arch=$(uname -m)
        if [[ "$arch" != "arm64" ]]; then
            log_error "Requires Apple Silicon (arm64). Found: $arch"
            exit 1
        fi
        log "Architecture: $arch (Apple Silicon)"

        # Check network connectivity
        if ! curl -fsS --max-time 5 https://github.com > /dev/null 2>&1; then
            log_error "No network connectivity to github.com"
            exit 1
        fi
        log "Network connectivity: OK"

        # Check disk space (need ~10GB free)
        local free_gb
        free_gb=$(df -g "$HOME" | tail -1 | awk '{print $4}')
        if [[ "$free_gb" -lt 10 ]]; then
            log_error "Need 10GB free disk space, have ${free_gb}GB"
            exit 1
        fi
        log "Disk space: ${free_gb}GB free"

        # Display profile
        log "Profile: $(get_profile)"

        # Store macOS version for later phases (Tahoe compatibility)
        echo "$major_version" > "$STATE_DIR/macos_version"

        # Acquire sudo for subsequent phases (Homebrew install, server prefs)
        acquire_sudo

        log "Preflight: PASSED"
    }

    # ========================================================================
    # Phase 1: Foundation (Xcode CLT + Homebrew + Repo Clone)
    # ========================================================================
    phase_1_foundation() {
        log_phase 1 "Foundation (Xcode CLT + Homebrew)"

        # Xcode Command Line Tools
        if ! xcode-select -p &>/dev/null; then
            log "Installing Xcode Command Line Tools..."

            # Use softwareupdate for non-interactive install (works over SSH)
            # xcode-select --install requires a GUI dialog click
            touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
            local clt_pkg
            clt_pkg=$(softwareupdate -l 2>/dev/null | grep -o '.*Command Line Tools.*' | head -1 | sed 's/^[* ]*//' | sed 's/^Label: //' | sed 's/ *$//')

            if [[ -n "$clt_pkg" ]]; then
                log "Found package: $clt_pkg"
                softwareupdate -i "$clt_pkg" --verbose 2>&1 | tee -a "$LOG_FILE"
            fi
            rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress

            # Verify installation succeeded, fall back to xcode-select --install
            if ! xcode-select -p &>/dev/null; then
                log_warn "softwareupdate didn't install CLT, falling back to xcode-select --install"
                log_warn "You may need to click 'Install' in the dialog if running with a display"
                xcode-select --install 2>/dev/null || true

                # Wait for installation
                log "Waiting for Xcode CLT installation..."
                until xcode-select -p &>/dev/null; do
                    sleep 5
                done
            fi

            log "Xcode CLT installed"
        else
            log "Xcode CLT already installed: $(xcode-select -p)"
        fi

        # Homebrew
        if ! command -v brew &>/dev/null; then
            log "Installing Homebrew..."
            NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

            # Add Homebrew to PATH for this session (Apple Silicon)
            eval "$(/opt/homebrew/bin/brew shellenv)"
            log "Homebrew installed"
        else
            log "Homebrew already installed: $(brew --version | head -1)"
        fi

        # macOS Tahoe (26+) compatibility fix
        # Older Homebrew versions don't recognize macOS 26, causing version detection errors
        # See: https://github.com/orgs/Homebrew/discussions/6206
        local macos_version
        macos_version=$(cat "$STATE_DIR/macos_version" 2>/dev/null || echo "0")
        if [[ "$macos_version" -ge 26 ]]; then
            log "Applying Homebrew fix for macOS Tahoe..."
            brew update-reset || log_warn "brew update-reset failed, continuing anyway"
        fi

        # Clone dotfiles if not already done (for curl | bash flow)
        if [[ ! -d "$DOTFILES_DIR" ]]; then
            log "Cloning dotfiles repository..."
            mkdir -p "$(dirname "$DOTFILES_DIR")"

            # Try SSH first, fall back to HTTPS
            if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
                log "Using SSH to clone"
                git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
            else
                log_warn "SSH not configured, using HTTPS"
                git clone "$DOTFILES_REPO_HTTPS" "$DOTFILES_DIR"
            fi
        fi

        log "Foundation: COMPLETE"
    }

    # ========================================================================
    # Phase 2: AI Rescue (Claude Code)
    # ========================================================================
    # CRITICAL: This phase installs Claude Code ASAP so AI can help debug
    # any issues in subsequent phases. This is the "AI rescue" pattern.
    # ========================================================================
    phase_2_ai_rescue() {
        log_phase 2 "AI Rescue (Claude Code)"

        log "Installing Claude Code (enables AI debugging for remaining phases)..."

        if brew list --cask claude-code &>/dev/null; then
            log "Claude Code already installed"
        else
            if brew install --cask claude-code; then
                log "Claude Code installed successfully"
            else
                log_warn "Claude Code install failed - continuing without AI rescue"
                log_warn "You can install it later: brew install --cask claude-code"
                return 0  # Non-fatal
            fi
        fi

        # Verify Claude Code is available
        if command -v claude &>/dev/null; then
            log "SUCCESS: Claude Code ready - AI debugging available"
            echo "ai_rescue_ready" > "$STATE_DIR/ai_rescue_ready"
            log ""
            log "TIP: If later phases fail, run:"
            log "  claude 'Help me debug this setup failure. Check ~/.dotfiles_state/setup.log'"
        else
            log_warn "Claude Code installed but 'claude' command not in PATH yet"
            log_warn "After restart, you can use: claude 'Help me debug...'"
        fi

        log "AI Rescue: COMPLETE"
    }

    # ========================================================================
    # Phase 3: Core Tools
    # ========================================================================
    phase_3_core_tools() {
        log_phase 3 "Core Tools"

        # Essential CLI tools that should be installed early
        local essentials=(
            git
            zsh
            tmux
            zoxide
            fzf
            ripgrep
            fd
            bat
            eza
            gh
            jq
            yq
            lazygit
            wget
            coreutils
            tree
            htop
        )

        log "Installing ${#essentials[@]} essential tools..."

        for tool in "${essentials[@]}"; do
            if brew list "$tool" &>/dev/null; then
                log "  $tool: already installed"
            else
                log "  $tool: installing..."
                brew install "$tool" || log_warn "Failed to install $tool"
            fi
        done

        log "Core Tools: COMPLETE"
    }

    # ========================================================================
    # Phase 4: Development Tools
    # ========================================================================
    phase_4_development() {
        log_phase 4 "Development Tools"

        # Tap for Bun
        log "Adding Bun tap..."
        brew tap oven-sh/bun 2>/dev/null || true

        local dev_tools=(
            "oven-sh/bun/bun"
            python
            uv
            pipx
            pyenv
            fnm
            pnpm
            shfmt
            shellcheck
            git-delta
        )

        log "Installing ${#dev_tools[@]} development tools..."

        for tool in "${dev_tools[@]}"; do
            local tool_name
            tool_name=$(basename "$tool")
            if brew list "$tool_name" &>/dev/null; then
                log "  $tool_name: already installed"
            else
                log "  $tool_name: installing..."
                brew install "$tool" || log_warn "Failed to install $tool"
            fi
        done

        log "Development Tools: COMPLETE"
    }

    # ========================================================================
    # Phase 5: Applications (Profile-aware Brewfile)
    # ========================================================================
    phase_5_applications() {
        log_phase 5 "Applications"

        local profile
        profile=$(get_profile)
        local brewfile="$DOTFILES_DIR/config/brew/Brewfile"

        # Check Brewfile exists
        if [[ ! -f "$brewfile" ]]; then
            log_error "Brewfile not found: $brewfile"
            return 1
        fi

        log "Installing packages for profile: $profile"
        log "This may take 10-15 minutes for a full install..."

        # Run brew bundle with profile environment variable
        # NOTE: Must use HOMEBREW_ prefix for env vars to pass through to Brewfile Ruby context
        # Regular env vars are filtered out by Homebrew for security/isolation
        if HOMEBREW_DOTFILES_PROFILE="$profile" brew bundle --file="$brewfile"; then
            log "All packages installed successfully"
        else
            log_warn "Some packages may have failed - check output above"
            log_warn "You can retry failed packages manually or run:"
            log_warn "  HOMEBREW_DOTFILES_PROFILE=$profile brew bundle --file=$brewfile"
        fi

        log "Applications: COMPLETE"
    }

    # ========================================================================
    # Phase 6: Configuration (symlinks + macOS preferences)
    # ========================================================================
    phase_6_configuration() {
        log_phase 6 "Configuration (symlinks + preferences)"

        install_symlinks
        install_prefs

        log "Configuration: COMPLETE"
    }

    # ========================================================================
    # Full install flow
    # ========================================================================
    run_full_install() {
        local start_phase="$1"

        # Ensure sudo keep-alive is cleaned up on exit (success or failure)
        trap 'release_sudo' EXIT

        local profile
        profile=$(get_profile)

        # Banner
        echo ""
        echo "===================================================="
        echo "     nathanvale/dotfiles setup                      "
        echo "===================================================="
        echo ""
        log "Dotfiles location: $DOTFILES_DIR"
        log "Profile: $profile"
        log "Log file: $LOG_FILE"

        # Run phases
        local phases=(
            phase_0_preflight
            phase_1_foundation
            phase_2_ai_rescue
            phase_3_core_tools
            phase_4_development
            phase_5_applications
            phase_6_configuration
        )

        for i in "${!phases[@]}"; do
            if [[ "$i" -ge "$start_phase" ]]; then
                ${phases[$i]}
                save_checkpoint "$((i + 1))"
            else
                log "Skipping phase $i (already completed)"
            fi
        done

        # Clear checkpoint on success
        clear_checkpoint

        echo ""
        log "===================================================="
        log "SETUP COMPLETE"
        log "===================================================="
        log "Profile: $profile"
        echo ""

        echo "Next steps:"
        echo "  1. Restart your terminal (or run: source ~/.zshrc)"
        echo "  2. Copy .env.example to .env and add your secrets"
        echo "  3. Run 'tmux' to start a session"
        if [[ "$profile" == "server" ]]; then
            echo "  4. Verify server settings: pmset -g"
            echo "  5. Test SSH access from another machine"
        fi
        echo ""

        # Run verification (informational only, don't fail setup)
        if [[ -f "$DOTFILES_DIR/verify_install.sh" ]]; then
            log_section "Running installation verification"
            "$DOTFILES_DIR/verify_install.sh" || true
        fi

        # Release sudo keep-alive before final banner
        release_sudo

        echo ""
        echo -e "${GREEN}════════════════════════════════════════════════════${RESET}"
        echo -e "${GREEN}  ✓ Setup complete!${RESET}"
        echo -e "${GREEN}════════════════════════════════════════════════════${RESET}"
        echo ""
    }

    # ========================================================================
    # Parse arguments and route
    # ========================================================================
    local profile_arg=""
    local start_phase=0
    local resume=false
    local subcommand=""
    local subcommand_args=()

    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --help|-h)
                usage
                ;;
            --server|-s)
                profile_arg="server"
                shift
                ;;
            --desktop|-d)
                profile_arg="desktop"
                shift
                ;;
            --resume)
                resume=true
                shift
                ;;
            --start-phase)
                start_phase="$2"
                shift 2
                ;;
            symlinks|prefs|status|verify)
                subcommand="$1"
                shift
                subcommand_args=("$@")
                break
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done

    # Handle subcommands (no profile selection needed)
    if [[ -n "$subcommand" ]]; then
        run_subcommand "$subcommand" "${subcommand_args[@]}"
        return 0
    fi

    # Full install flow: profile selection
    if [[ -n "$profile_arg" ]]; then
        DOTFILES_PROFILE="$profile_arg"
    elif [[ -t 0 ]]; then
        # Interactive mode - prompt for profile
        echo ""
        echo "===================================================="
        echo "     nathanvale/dotfiles setup                      "
        echo "===================================================="
        echo ""
        echo "Select machine profile:"
        echo "  1) Desktop (MacBook Pro) - GUI apps, development tools"
        echo "  2) Server (Mac Mini) - headless, containers, AI workloads"
        echo ""
        read -p "Choice [1/2] (default: 1): " -n 1 -r
        echo
        case $REPLY in
            2) DOTFILES_PROFILE="server" ;;
            *) DOTFILES_PROFILE="desktop" ;;
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

    # Save profile to state directory for child scripts
    echo "$DOTFILES_PROFILE" > "$STATE_DIR/profile"
    export DOTFILES_PROFILE

    log "Selected profile: $DOTFILES_PROFILE"

    # Handle resume
    if $resume; then
        start_phase=$(get_checkpoint)
        if [[ "$start_phase" == "0" ]]; then
            log "No checkpoint found, starting from beginning"
        else
            log "Resuming from phase $start_phase"
        fi
    fi

    # Check if dotfiles already exist (curl | bash flow)
    if [[ -d "$DOTFILES_DIR" ]] && [[ ! -f "$DOTFILES_DIR/setup.sh" || "$0" != "$DOTFILES_DIR/setup.sh" ]]; then
        log_warn "Dotfiles directory already exists: $DOTFILES_DIR"

        if [[ -t 0 ]]; then
            read -p "Pull latest changes and continue? [y/N] " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log "Exiting. Run ./setup.sh manually when ready."
                exit 0
            fi
        fi

        # Pull latest
        log "Pulling latest changes..."
        cd "$DOTFILES_DIR"
        git pull
    fi

    # Prompt before full install (interactive only)
    if [[ -t 0 ]] && [[ "$start_phase" -eq 0 ]] && ! $resume; then
        echo ""
        echo "This will:"
        echo "  Phase 0: Validate environment (macOS, arch, network, disk)"
        echo "  Phase 1: Install Xcode CLT + Homebrew + clone repo"
        echo "  Phase 2: Install Claude Code (AI rescue)"
        echo "  Phase 3: Install 16+ essential CLI tools"
        echo "  Phase 4: Install development runtimes (Bun, Python, Node)"
        echo "  Phase 5: Install all GUI apps from Brewfile"
        echo "  Phase 6: Create symlinks + apply macOS preferences"
        if [[ "$DOTFILES_PROFILE" == "server" ]]; then
            echo "         + Apply server-specific settings (pmset, SSH, firewall)"
        fi
        echo ""

        read -p "Continue with full installation? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "Skipped. Run ./setup.sh when ready."
            exit 0
        fi
    fi

    run_full_install "$start_phase"
}

# Execute main function with all arguments
main "$@"
