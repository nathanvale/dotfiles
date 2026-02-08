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

# Track warning and failure names for recap
WARN_ITEMS=()
FAIL_ITEMS=()

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
        FAIL_ITEMS+=("$name")
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
        WARN_ITEMS+=("$name")
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

# Full Disk Access (needed for Safari prefs)
verify_warn "Full Disk Access" "plutil -lint /Library/Preferences/com.apple.TimeMachine.plist"

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

    # Check SSH (nc doesn't need sudo, unlike systemsetup -getremotelogin)
    verify_warn "SSH enabled" "nc -z localhost 22"

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
else
    echo -e "${RED}Some checks failed.${RESET}"
fi

# ============================================================================
# Actionable recap for warnings and failures
# ============================================================================
# Note: Guard array iteration with length check for bash 3.2 compatibility.
# On bash <4.4, "${arr[@]}" on an empty array triggers "unbound variable"
# under set -u. Checking ${#arr[@]} first avoids this.
# ============================================================================
if [[ $FAIL_COUNT -gt 0 || $WARN_COUNT -gt 0 ]]; then
    echo ""
    echo -e "${YELLOW}--- Action needed ---${RESET}"

    # Recap failed items with fix instructions
    if [[ ${#FAIL_ITEMS[@]} -gt 0 ]]; then
        echo ""
        for item in "${FAIL_ITEMS[@]}"; do
            case "$item" in
                "Homebrew")
                    echo -e "${RED}Homebrew:${RESET} Not installed"
                    echo "  Fix: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
                    echo ""
                    ;;
                "Dotfiles repo")
                    echo -e "${RED}Dotfiles repo:${RESET} Missing"
                    echo "  Fix: git clone https://github.com/nathanvale/dotfiles.git ~/code/dotfiles"
                    echo ""
                    ;;
                "Xcode CLT")
                    echo -e "${RED}Xcode CLT:${RESET} Not installed"
                    echo "  Fix: xcode-select --install"
                    echo ""
                    ;;
                "Zsh config symlink"|"Git config symlink")
                    echo -e "${RED}${item}:${RESET} Broken or missing"
                    echo "  Fix: cd ~/code/dotfiles && bin/dotfiles/symlinks/symlinks_manage.sh --link"
                    echo ""
                    ;;
                "Profile saved")
                    echo -e "${RED}Profile saved:${RESET} State file missing"
                    echo "  Fix: echo 'server' > ~/.dotfiles_state/profile  (or 'desktop')"
                    echo ""
                    ;;
                "Sleep disabled"|"Display sleep disabled")
                    echo -e "${RED}${item}:${RESET} pmset not configured"
                    echo "  Fix: sudo pmset -a sleep 0 && sudo pmset -a displaysleep 0"
                    echo ""
                    ;;
                *)
                    echo -e "${RED}${item}:${RESET} Failed"
                    echo "  Fix: Re-run setup or install manually"
                    echo ""
                    ;;
            esac
        done
    fi

    # Recap warned items with fix instructions
    if [[ ${#WARN_ITEMS[@]} -gt 0 ]]; then
        for item in "${WARN_ITEMS[@]}"; do
            case "$item" in
                "OrbStack")
                    echo -e "${YELLOW}OrbStack:${RESET} Homebrew xattr error on macOS Tahoe"
                    echo "  Fix: brew install --cask orbstack --no-quarantine"
                    echo "  Or download directly from https://orbstack.dev"
                    echo ""
                    ;;
                "SSH enabled")
                    echo -e "${YELLOW}SSH:${RESET} Could not verify (needs sudo)"
                    echo "  Fix:   sudo systemsetup -setremotelogin on"
                    echo "  Check: sudo systemsetup -getremotelogin"
                    echo ""
                    ;;
                "Screen saver disabled")
                    echo -e "${YELLOW}Screen saver:${RESET} Could not verify setting"
                    echo "  Fix:   defaults write com.apple.screensaver idleTime 0"
                    echo "  Check: defaults read com.apple.screensaver idleTime"
                    echo ""
                    ;;
                "Full Disk Access")
                    echo -e "${YELLOW}Full Disk Access:${RESET} Not granted (Safari prefs skipped)"
                    echo "  5 Safari settings not applied: search privacy, suggestions,"
                    echo "  auto-correct, homepage, safe downloads"
                    echo "  Fix:"
                    echo "    1. System Settings > Privacy & Security > Full Disk Access"
                    echo "    2. Add your terminal app (Ghostty, Terminal, etc.)"
                    echo "    3. Relaunch terminal"
                    echo "    4. Run: ~/code/dotfiles/config/macos/defaults.common.sh --set"
                    echo ""
                    ;;
                "Claude Code")
                    echo -e "${YELLOW}Claude Code:${RESET} Not installed"
                    echo "  Fix: brew install --cask claude-code"
                    echo ""
                    ;;
                "Tmux config symlink")
                    echo -e "${YELLOW}Tmux config:${RESET} Symlink not found"
                    echo "  Fix: cd ~/code/dotfiles && bin/dotfiles/symlinks/symlinks_manage.sh --link"
                    echo ""
                    ;;
                "VS Code")
                    echo -e "${YELLOW}VS Code:${RESET} Not installed"
                    echo "  Fix: brew install --cask visual-studio-code"
                    echo ""
                    ;;
                "Slack")
                    echo -e "${YELLOW}Slack:${RESET} Not installed"
                    echo "  Fix: brew install --cask slack"
                    echo ""
                    ;;
                "Discord")
                    echo -e "${YELLOW}Discord:${RESET} Not installed"
                    echo "  Fix: brew install --cask discord"
                    echo ""
                    ;;
                "AI rescue marker")
                    # Harmless -- suppress from action items if Claude Code is installed
                    if command -v claude &>/dev/null; then
                        continue
                    fi
                    echo -e "${YELLOW}AI rescue:${RESET} Claude Code not available"
                    echo "  Fix: brew install --cask claude-code"
                    echo ""
                    ;;
                "Ollama")
                    echo -e "${YELLOW}Ollama:${RESET} Not installed"
                    echo "  Fix: brew install ollama"
                    echo ""
                    ;;
                *)
                    echo -e "${YELLOW}${item}:${RESET} Not available"
                    echo ""
                    ;;
            esac
        done
    fi

    echo "To debug with Claude Code:"
    echo "  claude 'Help me fix these failures. Log: ~/.dotfiles_state/setup.log'"
fi

if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
fi
exit 0
