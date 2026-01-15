#!/bin/bash
# bin/tmux/upgrade-ai-tools.sh
# Close AI agent panes, upgrade tools via brew bundle, and respawn agents

set -e

# ============================================================================
# CONFIGURATION
# ============================================================================

DOTFILES_DIR="$HOME/code/dotfiles"
BREWFILE="$DOTFILES_DIR/config/brew/Brewfile"
AI_TOOLS=("claude" "codex" "gemini")

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

info() { printf "${BLUE}%s${NC}\n" "$1"; }
success() { printf "${GREEN}%s${NC}\n" "$1"; }
warning() { printf "${YELLOW}%s${NC}\n" "$1"; }
error() { printf "${RED}%s${NC}\n" "$1" >&2; }

# ============================================================================
# MAIN LOGIC
# ============================================================================

main() {
    echo ""
    echo "${BOLD}${CYAN}========================================${NC}"
    echo "${BOLD}${CYAN}  AI Tools Upgrade${NC}"
    echo "${BOLD}${CYAN}========================================${NC}"
    echo ""

    # Check if we're in tmux
    if [ -z "$TMUX" ]; then
        error "Not in a tmux session"
        exit 1
    fi

    local session_name=$(tmux display-message -p '#S')
    local current_window=$(tmux display-message -p '#I')

    # Step 1: Find and kill AI agent panes
    info "Step 1: Closing AI agent panes..."
    local killed_count=0

    # Get all panes in session with their commands
    while IFS=: read -r window pane cmd; do
        for tool in "${AI_TOOLS[@]}"; do
            if [[ "$cmd" == *"$tool"* ]]; then
                # Don't kill current pane if it's running this script
                local current_pane=$(tmux display-message -p '#P')
                if [[ "$window" == "$current_window" && "$pane" == "$current_pane" ]]; then
                    continue
                fi
                tmux kill-pane -t "${session_name}:${window}.${pane}" 2>/dev/null || true
                ((killed_count++)) || true
                echo "  Closed ${tool} in window ${window}, pane ${pane}"
            fi
        done
    done < <(tmux list-panes -s -F '#{window_index}:#{pane_index}:#{pane_current_command}' 2>/dev/null)

    if [ $killed_count -eq 0 ]; then
        echo "  No AI agent panes found"
    else
        success "  Closed $killed_count AI agent pane(s)"
    fi
    echo ""

    # Step 2: Upgrade via brew bundle
    info "Step 2: Upgrading AI tools via brew..."
    echo ""

    # Show current versions
    echo "  ${BOLD}Current versions:${NC}"
    claude --version 2>/dev/null | head -1 | sed 's/^/    claude: /' || echo "    claude: not installed"
    codex --version 2>/dev/null | head -1 | sed 's/^/    codex: /' || echo "    codex: not installed"
    gemini --version 2>/dev/null | head -1 | sed 's/^/    gemini: /' || echo "    gemini: not installed"
    echo ""

    # Run brew bundle (uses Brewfile as source of truth)
    echo "  Running brew bundle..."
    brew bundle --file="$BREWFILE" 2>&1 | sed 's/^/    /' || true
    echo ""

    # Show new versions
    echo "  ${BOLD}Updated versions:${NC}"
    claude --version 2>/dev/null | head -1 | sed 's/^/    claude: /' || echo "    claude: not installed"
    codex --version 2>/dev/null | head -1 | sed 's/^/    codex: /' || echo "    codex: not installed"
    gemini --version 2>/dev/null | head -1 | sed 's/^/    gemini: /' || echo "    gemini: not installed"
    echo ""

    success "========================================="
    success "  Upgrade complete!"
    success "========================================="
    echo ""
    echo "  Use ${BOLD}Ctrl-g A c/g/x${NC} to spawn AI agents"
    echo "  Or ${BOLD}Ctrl-g t${NC} to start a new session with AI window"
    echo ""

    # Wait for user to dismiss
    echo "Press Enter to close..."
    read -r
}

main "$@"
