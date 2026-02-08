#!/usr/bin/env bash
# verify_install.sh - Post-installation verification
#
# Validates that all bootstrap phases completed successfully.
# Run after setup.sh to verify.
#
# Usage:
#   ./verify_install.sh           # Run all verifications
#   ./verify_install.sh --quiet   # Only show failures
#   ./verify_install.sh --verbose # Show every check individually

# Note: Not using set -e because we want to continue on verification failures
set -uo pipefail

# Auto-detect dotfiles directory
DOTFILES="$(cd "$(dirname "$0")" && pwd)"
STATE_DIR="$HOME/.dotfiles_state"

# Ensure Homebrew is in PATH for this script (Apple Silicon)
if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Colors (self-contained -- don't source colour_log.sh, this runs when things may be broken)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
DIM='\033[0;90m'
RESET='\033[0m'

# Counters
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

# Track warning and failure names for recap
# Note: Guard array iteration with length check for bash 3.2 compatibility.
# On bash <4.4, "${arr[@]}" on an empty array triggers "unbound variable"
# under set -u. Always check ${#arr[@]} before iterating.
WARN_ITEMS=()
FAIL_ITEMS=()

# Per-phase counters for collapsed output
PHASE_PASS=0
PHASE_FAIL=0
PHASE_WARN=0
PHASE_ISSUES=()

# Display mode
MODE="normal"  # normal, quiet, verbose

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

# Start a new phase (resets per-phase counters)
phase_start() {
    PHASE_PASS=0
    PHASE_FAIL=0
    PHASE_WARN=0
    PHASE_ISSUES=()
}

# End a phase (prints collapsed summary)
phase_end() {
    local name="$1"
    local total=$((PHASE_PASS + PHASE_FAIL + PHASE_WARN))

    if [[ $PHASE_FAIL -eq 0 && $PHASE_WARN -eq 0 ]]; then
        # All passed -- single line
        if [[ "$MODE" != "quiet" ]]; then
            echo -e "${GREEN}${name}:${RESET} ${PHASE_PASS}/${total} passed"
        fi
    else
        # Has issues -- show summary + expand failures/warnings
        echo -e "${CYAN}${name}:${RESET} ${PHASE_PASS}/${total} passed"
        if [[ ${#PHASE_ISSUES[@]} -gt 0 ]]; then
            for issue in "${PHASE_ISSUES[@]}"; do
                echo -e "  $issue"
            done
        fi
    fi
}

# Verification helper
verify() {
    local name="$1"
    local cmd="$2"

    if eval "$cmd" &>/dev/null; then
        PASS_COUNT=$((PASS_COUNT + 1))
        PHASE_PASS=$((PHASE_PASS + 1))
        if [[ "$MODE" == "verbose" ]]; then
            PHASE_ISSUES+=("${GREEN}✓${RESET} $name")
        fi
        return 0
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
        FAIL_ITEMS+=("$name")
        PHASE_FAIL=$((PHASE_FAIL + 1))
        PHASE_ISSUES+=("${RED}✗ $name${RESET}")
        return 0  # Don't fail the script, just record the failure
    fi
}

# Warning helper (non-fatal)
verify_warn() {
    local name="$1"
    local cmd="$2"

    if eval "$cmd" &>/dev/null; then
        PASS_COUNT=$((PASS_COUNT + 1))
        PHASE_PASS=$((PHASE_PASS + 1))
        if [[ "$MODE" == "verbose" ]]; then
            PHASE_ISSUES+=("${GREEN}✓${RESET} $name")
        fi
        return 0
    else
        WARN_COUNT=$((WARN_COUNT + 1))
        WARN_ITEMS+=("$name")
        PHASE_WARN=$((PHASE_WARN + 1))
        PHASE_ISSUES+=("${YELLOW}⚠ $name${RESET}")
        return 0
    fi
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --quiet|-q)
            MODE="quiet"
            shift
            ;;
        --verbose|-v)
            MODE="verbose"
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--quiet] [--verbose]"
            echo ""
            echo "Options:"
            echo "  --quiet, -q    Only show phases with failures"
            echo "  --verbose, -v  Show every individual check"
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
phase_start
verify "Homebrew" "command -v brew"
verify "Dotfiles repo" "[[ -d '$DOTFILES' ]]"
verify "Xcode CLT" "xcode-select -p"
phase_end "Phase 1: Foundation"

# ============================================================================
# Phase 2: AI Rescue
# ============================================================================
phase_start
verify_warn "Claude Code" "command -v claude"
# Only check AI rescue marker if Claude Code itself is missing (otherwise it's noise)
if ! command -v claude &>/dev/null; then
    verify_warn "AI rescue marker" "[[ -f '$STATE_DIR/ai_rescue_ready' ]]"
else
    # Count it as passed silently
    PASS_COUNT=$((PASS_COUNT + 1))
    PHASE_PASS=$((PHASE_PASS + 1))
fi
phase_end "Phase 2: AI Rescue"

# ============================================================================
# Phase 3: Core Tools
# ============================================================================
phase_start
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
phase_end "Phase 3: Core Tools"

# ============================================================================
# Phase 4: Development
# ============================================================================
phase_start
verify "Bun" "command -v bun"
verify "Python" "command -v python3"
verify "UV" "command -v uv"
verify "fnm (Node)" "command -v fnm"
verify "pnpm" "command -v pnpm"
verify "shellcheck" "command -v shellcheck"
phase_end "Phase 4: Development"

# ============================================================================
# Phase 5: Applications (Profile-specific)
# ============================================================================
phase_start
verify "Ghostty" "[[ -d /Applications/Ghostty.app ]]"
verify "Raycast" "[[ -d /Applications/Raycast.app ]]"
verify "1Password" "[[ -d '/Applications/1Password.app' ]]"
verify "Obsidian" "[[ -d /Applications/Obsidian.app ]]"

if [[ "$PROFILE" == "server" ]]; then
    verify_warn "OrbStack" "[[ -d /Applications/OrbStack.app ]]"
    verify_warn "Ollama" "command -v ollama"
else
    verify_warn "VS Code" "[[ -d '/Applications/Visual Studio Code.app' ]]"
    verify_warn "Slack" "[[ -d /Applications/Slack.app ]]"
    verify_warn "Discord" "[[ -d /Applications/Discord.app ]]"
fi
phase_end "Phase 5: Applications"

# ============================================================================
# Phase 6: Configuration
# ============================================================================
phase_start
verify "Zsh config symlink" "[[ -L ~/.zshrc ]]"
verify "Git config symlink" "[[ -L ~/.gitconfig ]]"
verify_warn "Tmux config symlink" "[[ -L ~/.tmux.conf ]] || [[ -L ~/.config/tmux/tmux.conf ]]"
verify_warn "Full Disk Access" "plutil -lint /Library/Preferences/com.apple.TimeMachine.plist"
verify "Profile saved" "[[ -f '$STATE_DIR/profile' ]]"
phase_end "Phase 6: Configuration"

# ============================================================================
# Server-specific verification
# ============================================================================
if [[ "$PROFILE" == "server" ]]; then
    phase_start
    verify "Sleep disabled" "[[ \$(pmset -g | grep ' sleep' | awk '{print \$2}') == '0' ]]"
    verify "Display sleep disabled" "[[ \$(pmset -g | grep 'displaysleep' | awk '{print \$2}') == '0' ]]"
    verify_warn "SSH enabled" "nc -z localhost 22"
    verify_warn "Screen saver disabled" "[[ \$(defaults read com.apple.screensaver idleTime 2>/dev/null) == '0' ]]"
    phase_end "Server Settings"
fi

# ============================================================================
# Summary
# ============================================================================
TOTAL=$((PASS_COUNT + FAIL_COUNT + WARN_COUNT))
echo ""
if [[ $FAIL_COUNT -eq 0 && $WARN_COUNT -eq 0 ]]; then
    echo -e "${GREEN}=== ${TOTAL}/${TOTAL} checks passed ===${RESET}"
else
    echo -e "${CYAN}=== Verification Summary ===${RESET}"
    echo -e "  ${GREEN}Passed:${RESET}   $PASS_COUNT"
    if [[ $FAIL_COUNT -gt 0 ]]; then
        echo -e "  ${RED}Failed:${RESET}   $FAIL_COUNT"
    fi
    if [[ $WARN_COUNT -gt 0 ]]; then
        echo -e "  ${YELLOW}Warnings:${RESET} $WARN_COUNT"
    fi
fi

# ============================================================================
# Actionable recap for warnings and failures
# ============================================================================
if [[ $FAIL_COUNT -gt 0 || $WARN_COUNT -gt 0 ]]; then
    local_action_count=0

    echo ""
    echo -e "${YELLOW}╔══════════════════════════════════════════╗${RESET}"
    echo -e "${YELLOW}  Action needed${RESET}"
    echo -e "${YELLOW}╚══════════════════════════════════════════╝${RESET}"

    # Helper to print a numbered action item
    action() {
        local_action_count=$((local_action_count + 1))
        local color="$1"
        local title="$2"
        local desc="$3"
        shift 3
        echo ""
        echo -e "  ${color}${local_action_count}. ${title}${RESET} -- ${desc}"
        for line in "$@"; do
            echo "     $line"
        done
    }

    # Recap failed items
    if [[ ${#FAIL_ITEMS[@]} -gt 0 ]]; then
        for item in "${FAIL_ITEMS[@]}"; do
            case "$item" in
                "Homebrew")
                    action "$RED" "Homebrew" "not installed" \
                        "Fix: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
                    ;;
                "Dotfiles repo")
                    action "$RED" "Dotfiles repo" "missing" \
                        "Fix: git clone https://github.com/nathanvale/dotfiles.git ~/code/dotfiles"
                    ;;
                "Xcode CLT")
                    action "$RED" "Xcode CLT" "not installed" \
                        "Fix: xcode-select --install"
                    ;;
                "Zsh config symlink"|"Git config symlink")
                    action "$RED" "$item" "broken or missing" \
                        "Fix: cd ~/code/dotfiles && bin/dotfiles/symlinks/symlinks_manage.sh --link"
                    ;;
                "Profile saved")
                    action "$RED" "Profile saved" "state file missing" \
                        "Fix: echo 'server' > ~/.dotfiles_state/profile  (or 'desktop')"
                    ;;
                "Sleep disabled"|"Display sleep disabled")
                    action "$RED" "$item" "pmset not configured" \
                        "Fix: sudo pmset -a sleep 0 && sudo pmset -a displaysleep 0"
                    ;;
                *)
                    action "$RED" "$item" "failed" \
                        "Fix: re-run setup or install manually"
                    ;;
            esac
        done
    fi

    # Recap warned items
    if [[ ${#WARN_ITEMS[@]} -gt 0 ]]; then
        for item in "${WARN_ITEMS[@]}"; do
            case "$item" in
                "OrbStack")
                    action "$YELLOW" "OrbStack" "not installed (may be an orphaned app issue)" \
                        "Fix: rm -rf /Applications/OrbStack.app && brew install --cask orbstack" \
                        "Or re-run: setup.sh --server (pre-cleanup handles this automatically)"
                    ;;
                "SSH enabled")
                    action "$YELLOW" "SSH" "could not verify (needs sudo)" \
                        "Fix:   sudo systemsetup -setremotelogin on" \
                        "Check: sudo systemsetup -getremotelogin"
                    ;;
                "Screen saver disabled")
                    action "$YELLOW" "Screen saver" "could not verify setting" \
                        "Fix:   defaults write com.apple.screensaver idleTime 0" \
                        "Check: defaults read com.apple.screensaver idleTime"
                    ;;
                "Full Disk Access")
                    action "$YELLOW" "Full Disk Access" "not granted (5 Safari prefs skipped)" \
                        "Fix:" \
                        "  1. System Settings > Privacy & Security > Full Disk Access" \
                        "  2. Add your terminal app (Ghostty, Terminal, etc.)" \
                        "  3. Relaunch terminal" \
                        "  4. Run: ~/code/dotfiles/config/macos/defaults.common.sh --set"
                    ;;
                "Claude Code")
                    action "$YELLOW" "Claude Code" "not installed" \
                        "Fix: brew install --cask claude-code"
                    ;;
                "Tmux config symlink")
                    action "$YELLOW" "Tmux config" "symlink not found" \
                        "Fix: cd ~/code/dotfiles && bin/dotfiles/symlinks/symlinks_manage.sh --link"
                    ;;
                "VS Code")
                    action "$YELLOW" "VS Code" "not installed" \
                        "Fix: brew install --cask visual-studio-code"
                    ;;
                "Slack")
                    action "$YELLOW" "Slack" "not installed" \
                        "Fix: brew install --cask slack"
                    ;;
                "Discord")
                    action "$YELLOW" "Discord" "not installed" \
                        "Fix: brew install --cask discord"
                    ;;
                "AI rescue marker")
                    # Suppress entirely -- Claude Code handles this
                    if command -v claude &>/dev/null; then
                        continue
                    fi
                    action "$YELLOW" "AI rescue" "Claude Code not available" \
                        "Fix: brew install --cask claude-code"
                    ;;
                "Ollama")
                    action "$YELLOW" "Ollama" "not installed" \
                        "Fix: brew install ollama"
                    ;;
                *)
                    action "$YELLOW" "$item" "not available" \
                        "Fix: check brew bundle output above"
                    ;;
            esac
        done
    fi

    echo ""
    echo -e "  ${DIM}Tip: claude 'Help me fix these. Log: ~/.dotfiles_state/setup.log'${RESET}"
fi

echo ""

if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
fi
exit 0
