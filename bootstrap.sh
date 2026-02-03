#!/usr/bin/env bash
# bootstrap.sh - Phased installation with checkpoints and AI rescue
#
# 7-Phase Architecture:
#   Phase 0: Preflight     (~5s)   - Validate environment, check requirements
#   Phase 1: Foundation    (~2m)   - Xcode CLT + Homebrew
#   Phase 2: AI Rescue     (~30s)  - Claude Code ONLY (enables AI debugging)
#   Phase 3: Core Tools    (~3m)   - Essential CLI (git, zsh, tmux, etc.)
#   Phase 4: Development   (~5m)   - Language runtimes (bun, python, node)
#   Phase 5: Applications  (~10m)  - GUI apps from Brewfile
#   Phase 6: Configuration (~2m)   - Symlinks + macOS preferences
#
# Usage:
#   ./bootstrap.sh              # Run all phases
#   ./bootstrap.sh --resume     # Resume from last checkpoint
#   ./bootstrap.sh --start-phase 3  # Start from specific phase
#   ./bootstrap.sh --help       # Show help
#
# On a fresh Mac:
#   1. git clone https://github.com/nathanvale/dotfiles.git ~/code/dotfiles
#   2. cd ~/code/dotfiles
#   3. ./bootstrap.sh       # One-time: Homebrew + packages
#   4. ./install.sh         # Symlinks + preferences

set -euo pipefail

# Auto-detect dotfiles directory
DOTFILES="$(cd "$(dirname "$0")" && pwd)"
STATE_DIR="$HOME/.dotfiles_state"
LOG_FILE="$STATE_DIR/bootstrap.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Ensure state directory exists
mkdir -p "$STATE_DIR"

# Logging functions
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

# Checkpoint functions
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

# Usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Phased bootstrap for a fresh Mac with checkpoint/resume support."
    echo ""
    echo "Options:"
    echo "  --resume          Resume from last checkpoint"
    echo "  --start-phase N   Start from phase N (0-6)"
    echo "  --help            Show this help message"
    echo ""
    echo "Phases:"
    echo "  0: Preflight     - Validate environment"
    echo "  1: Foundation    - Xcode CLT + Homebrew"
    echo "  2: AI Rescue     - Claude Code (enables AI debugging)"
    echo "  3: Core Tools    - Essential CLI tools"
    echo "  4: Development   - Language runtimes"
    echo "  5: Applications  - GUI apps from Brewfile"
    echo "  6: Configuration - Final setup (handled by install.sh)"
    echo ""
    echo "Profile: $(get_profile)"
    exit 0
}

# ============================================================================
# PHASE 0: Preflight Checks
# ============================================================================
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

    log "Preflight: PASSED"
}

# ============================================================================
# PHASE 1: Foundation (Xcode CLT + Homebrew)
# ============================================================================
phase_1_foundation() {
    log_phase 1 "Foundation (Xcode CLT + Homebrew)"

    # Xcode Command Line Tools
    if ! xcode-select -p &>/dev/null; then
        log "Installing Xcode Command Line Tools..."
        xcode-select --install

        # Wait for installation
        log "Waiting for Xcode CLT installation..."
        until xcode-select -p &>/dev/null; do
            sleep 5
        done
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

    # Clone dotfiles if not already done (for standalone bootstrap runs)
    if [[ ! -d "$DOTFILES" ]]; then
        log "Cloning dotfiles repository..."
        mkdir -p "$(dirname "$DOTFILES")"
        git clone https://github.com/nathanvale/dotfiles.git "$DOTFILES"
    fi

    log "Foundation: COMPLETE"
}

# ============================================================================
# PHASE 2: AI Rescue (Claude Code)
# ============================================================================
# CRITICAL: This phase installs Claude Code ASAP so AI can help debug
# any issues in subsequent phases. This is the "AI rescue" pattern.
# ============================================================================
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
        log "  claude 'Help me debug this bootstrap failure. Check ~/.dotfiles_state/bootstrap.log'"
    else
        log_warn "Claude Code installed but 'claude' command not in PATH yet"
        log_warn "After restart, you can use: claude 'Help me debug...'"
    fi

    log "AI Rescue: COMPLETE"
}

# ============================================================================
# PHASE 3: Core Tools
# ============================================================================
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

# ============================================================================
# PHASE 4: Development Tools
# ============================================================================
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

# ============================================================================
# PHASE 5: Applications (Profile-aware Brewfile)
# ============================================================================
phase_5_applications() {
    log_phase 5 "Applications"

    local profile
    profile=$(get_profile)
    local brewfile="$DOTFILES/config/brew/Brewfile"

    # Check Brewfile exists
    if [[ ! -f "$brewfile" ]]; then
        log_error "Brewfile not found: $brewfile"
        return 1
    fi

    log "Installing packages for profile: $profile"
    log "This may take 10-15 minutes for a full install..."

    # Run brew bundle with profile environment variable
    # Brewfile uses Ruby conditionals to filter by profile
    if DOTFILES_PROFILE="$profile" brew bundle --file="$brewfile"; then
        log "All packages installed successfully"
    else
        log_warn "Some packages may have failed - check output above"
        log_warn "You can retry failed packages manually or run:"
        log_warn "  DOTFILES_PROFILE=$profile brew bundle --file=$brewfile"
    fi

    log "Applications: COMPLETE"
}

# ============================================================================
# Main Execution
# ============================================================================
main() {
    local start_phase=0
    local resume=false

    # Parse arguments
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --help|-h)
                usage
                ;;
            --resume)
                resume=true
                shift
                ;;
            --start-phase)
                start_phase="$2"
                shift 2
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                ;;
        esac
    done

    # Banner
    echo ""
    echo "===================================================="
    echo "     nathanvale/dotfiles bootstrap                  "
    echo "===================================================="
    echo ""
    log "Dotfiles location: $DOTFILES"
    log "Profile: $(get_profile)"
    log "Log file: $LOG_FILE"

    # Handle resume
    if $resume; then
        start_phase=$(get_checkpoint)
        if [[ "$start_phase" == "0" ]]; then
            log "No checkpoint found, starting from beginning"
        else
            log "Resuming from phase $start_phase"
        fi
    fi

    # Run phases
    local phases=(
        phase_0_preflight
        phase_1_foundation
        phase_2_ai_rescue
        phase_3_core_tools
        phase_4_development
        phase_5_applications
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
    log "BOOTSTRAP COMPLETE"
    log "===================================================="
    log "Profile: $(get_profile)"
    log ""
    log "Next step: ./install.sh"
    echo ""
}

main "$@"
