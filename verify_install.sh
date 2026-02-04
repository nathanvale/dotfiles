#!/usr/bin/env bash
# verify_install.sh - Post-installation verification
#
# Validates that all bootstrap phases completed successfully.
# Run after setup.sh to verify.
#
# Usage:
#   ./verify_install.sh         # Run all verifications
#   ./verify_install.sh --quiet # Only show failures

# Note: Not using set -e because we want to continue on verification failures
set -uo pipefail

# Auto-detect dotfiles directory
DOTFILES="$(cd "$(dirname "$0")" && pwd)"
STATE_DIR="$HOME/.dotfiles_state"

# Ensure Homebrew is in PATH for this script (Apple Silicon)
if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Counters
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

# Quiet mode
QUIET=false

# Get profile
get_profile() {
    if [[ -n "${DOTFILES_PROFILE:-}" ]]; then
        echo "$DOTFILES_PROFILE"
    elif [[ -f "$STATE_DIR/profile" ]]; then
        cat "$STATE_DIR/profile"
    else
        echo "desktop"
    fi
}

# Verification helper
verify() {
    local name="$1"
    local cmd="$2"

    if eval "$cmd" &>/dev/null; then
        PASS_COUNT=$((PASS_COUNT + 1))
        if ! $QUIET; then
            echo -e "${GREEN}✓${RESET} $name"
        fi
        return 0
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
        echo -e "${RED}✗${RESET} $name ${RED}FAILED${RESET}"
        return 0  # Don't fail the script, just record the failure
    fi
}

# Warning helper (non-fatal)
verify_warn() {
    local name="$1"
    local cmd="$2"

    if eval "$cmd" &>/dev/null; then
        PASS_COUNT=$((PASS_COUNT + 1))
        if ! $QUIET; then
            echo -e "${GREEN}✓${RESET} $name"
        fi
        return 0
    else
        WARN_COUNT=$((WARN_COUNT + 1))
        echo -e "${YELLOW}⚠${RESET} $name ${YELLOW}(optional)${RESET}"
        return 0
    fi
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --quiet|-q)
            QUIET=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--quiet]"
            echo ""
            echo "Options:"
            echo "  --quiet, -q  Only show failures"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

PROFILE=$(get_profile)

echo ""
echo -e "${CYAN}=== Installation Verification ===${RESET}"
echo -e "Profile: $PROFILE"
echo ""

# ============================================================================
# Phase 1: Foundation
# ============================================================================
echo -e "${CYAN}--- Phase 1: Foundation ---${RESET}"
verify "Homebrew" "command -v brew"
verify "Dotfiles repo" "[[ -d '$DOTFILES' ]]"
verify "Xcode CLT" "xcode-select -p"

# ============================================================================
# Phase 2: AI Rescue
# ============================================================================
echo ""
echo -e "${CYAN}--- Phase 2: AI Rescue ---${RESET}"
verify_warn "Claude Code" "command -v claude"
verify_warn "AI rescue marker" "[[ -f '$STATE_DIR/ai_rescue_ready' ]]"

# ============================================================================
# Phase 3: Core Tools
# ============================================================================
echo ""
echo -e "${CYAN}--- Phase 3: Core Tools ---${RESET}"
verify "Git" "command -v git"
verify "Zsh" "command -v zsh"
verify "Tmux" "command -v tmux"
verify "Zoxide" "command -v zoxide"
verify "Fzf" "command -v fzf"
verify "Ripgrep" "command -v rg"
verify "Fd" "command -v fd"
verify "Bat" "command -v bat"
verify "Eza" "command -v eza"
verify "GitHub CLI" "command -v gh"
verify "jq" "command -v jq"
verify "yq" "command -v yq"

# ============================================================================
# Phase 4: Development
# ============================================================================
echo ""
echo -e "${CYAN}--- Phase 4: Development ---${RESET}"
verify "Bun" "command -v bun"
verify "Python" "command -v python3"
verify "UV" "command -v uv"
verify "fnm (Node)" "command -v fnm"
verify "pnpm" "command -v pnpm"
verify "shellcheck" "command -v shellcheck"

# ============================================================================
# Phase 5: Applications (Profile-specific)
# ============================================================================
echo ""
echo -e "${CYAN}--- Phase 5: Applications ---${RESET}"

# Common apps
verify "Ghostty" "[[ -d /Applications/Ghostty.app ]]"
verify "Raycast" "[[ -d /Applications/Raycast.app ]]"
verify "1Password" "[[ -d '/Applications/1Password.app' ]]"
verify "Obsidian" "[[ -d /Applications/Obsidian.app ]]"

if [[ "$PROFILE" == "server" ]]; then
    # Server-specific
    verify_warn "OrbStack" "[[ -d /Applications/OrbStack.app ]]"
    verify_warn "Ollama" "command -v ollama"
else
    # Desktop-specific
    verify_warn "VS Code" "[[ -d '/Applications/Visual Studio Code.app' ]]"
    verify_warn "Slack" "[[ -d /Applications/Slack.app ]]"
    verify_warn "Discord" "[[ -d /Applications/Discord.app ]]"
fi

# ============================================================================
# Phase 6: Configuration
# ============================================================================
echo ""
echo -e "${CYAN}--- Phase 6: Configuration ---${RESET}"

# Symlinks
verify "Zsh config symlink" "[[ -L ~/.zshrc ]]"
verify "Git config symlink" "[[ -L ~/.gitconfig ]]"
verify_warn "Tmux config symlink" "[[ -L ~/.tmux.conf ]] || [[ -L ~/.config/tmux/tmux.conf ]]"

# Profile marker
verify "Profile saved" "[[ -f '$STATE_DIR/profile' ]]"

# ============================================================================
# Server-specific verification
# ============================================================================
if [[ "$PROFILE" == "server" ]]; then
    echo ""
    echo -e "${CYAN}--- Server Settings ---${RESET}"

    # Check pmset sleep settings
    verify "Sleep disabled" "[[ \$(pmset -g | grep ' sleep' | awk '{print \$2}') == '0' ]]"
    verify "Display sleep disabled" "[[ \$(pmset -g | grep 'displaysleep' | awk '{print \$2}') == '0' ]]"

    # Check SSH
    verify_warn "SSH enabled" "systemsetup -getremotelogin 2>/dev/null | grep -q On"

    # Check screen saver
    verify_warn "Screen saver disabled" "[[ \$(defaults read com.apple.screensaver idleTime 2>/dev/null) == '0' ]]"
fi

# ============================================================================
# Summary
# ============================================================================
echo ""
echo -e "${CYAN}=== Verification Summary ===${RESET}"
echo -e "${GREEN}Passed:${RESET}  $PASS_COUNT"
echo -e "${RED}Failed:${RESET}  $FAIL_COUNT"
echo -e "${YELLOW}Warnings:${RESET} $WARN_COUNT"
echo ""

if [[ $FAIL_COUNT -eq 0 ]]; then
    echo -e "${GREEN}All critical checks passed!${RESET}"
    if [[ $WARN_COUNT -gt 0 ]]; then
        echo -e "${YELLOW}Some optional items may need attention.${RESET}"
    fi
    exit 0
else
    echo -e "${RED}Some checks failed. Review the output above.${RESET}"
    echo ""
    echo "To debug with Claude Code:"
    echo "  claude 'Help me fix the verification failures in my dotfiles setup'"
    exit 1
fi
