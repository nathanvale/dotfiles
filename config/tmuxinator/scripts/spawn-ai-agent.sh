#!/bin/bash
# ~/.config/tmuxinator/scripts/spawn-ai-agent.sh
# Dynamically spawn AI agent panes in the current tmux session

set -e

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output (using tput for better terminal compatibility)
if command -v tput &> /dev/null && [ -n "$TERM" ]; then
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    CYAN=$(tput setaf 6)
    BOLD=$(tput bold)
    NC=$(tput sgr0) # No Color
else
    # Fallback to ANSI codes
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    NC='\033[0m'
fi

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

print_usage() {
    cat <<EOF
${BLUE}Tmux AI Agent Spawner${NC}

${GREEN}Usage:${NC}
    $0 <agent_type> [window_name] [split_direction]

${GREEN}Arguments:${NC}
    agent_type       Type of AI agent to spawn
                     Options: claude, gemini, openai, codex
    window_name      Name of window to spawn in (default: current window)
                     Use "new" to create a new window
    split_direction  How to split the pane (default: horizontal)
                     Options: horizontal, vertical

${GREEN}Examples:${NC}
    # Spawn Gemini in current window (horizontal split)
    $0 gemini

    # Spawn OpenAI in current window (vertical split)
    $0 openai current vertical

    # Spawn Claude in a new window
    $0 claude new

    # Spawn Codex in the 'ai-agents' window
    $0 codex ai-agents horizontal

${GREEN}Tmux Key Bindings (add to ~/.tmux.conf):${NC}
    # Ctrl-g + a + c = Spawn Claude
    bind-key -n C-g a c run-shell "~/.config/tmuxinator/scripts/spawn-ai-agent.sh claude"

    # Ctrl-g + a + g = Spawn Gemini
    bind-key -n C-g a g run-shell "~/.config/tmuxinator/scripts/spawn-ai-agent.sh gemini"

    # Ctrl-g + a + o = Spawn OpenAI
    bind-key -n C-g a o run-shell "~/.config/tmuxinator/scripts/spawn-ai-agent.sh openai"

EOF
}

error() {
    printf "%s%s%s\n" "${RED}" "Error: $1" "${NC}" >&2
    exit 1
}

success() {
    printf "%s%s%s\n" "${GREEN}" "$1" "${NC}"
}

info() {
    printf "%s%s%s\n" "${BLUE}" "$1" "${NC}"
}

warning() {
    printf "%s%s%s\n" "${YELLOW}" "$1" "${NC}"
}

# ============================================================================
# AI AGENT COMMANDS
# ============================================================================

get_agent_command() {
    local agent_type="$1"
    local pane_name="$2"

    case "$agent_type" in
        claude)
            cat <<'CLAUDE_EOF'
source ~/.config/tmuxinator/scripts/common-setup.sh
pane_setup "claude"
clear
echo "🤖 Claude AI Agent"
echo "Repository: $(pwd)"
echo ""
claude
CLAUDE_EOF
            ;;
        gemini)
            cat <<'GEMINI_EOF'
source ~/.config/tmuxinator/scripts/common-setup.sh
pane_setup "gemini"
clear
echo "🔷 Gemini AI Agent"
echo "Repository: $(pwd)"
echo ""
# Check if Google Gemini CLI is available
if command -v gemini &> /dev/null; then
    gemini
else
    echo "⚠️  Gemini CLI not installed"
    echo ""
    echo "Install with npm:"
    echo "  npm i -g @google/gemini-cli"
    echo ""
    echo "Or run without installing:"
    echo "  npx @google/gemini-cli"
    echo ""
    $SHELL
fi
GEMINI_EOF
            ;;
        openai)
            cat <<'OPENAI_EOF'
source ~/.config/tmuxinator/scripts/common-setup.sh
pane_setup "openai"
clear
echo "🔶 OpenAI Agent"
echo "Repository: $(pwd)"
echo ""
# Check if OpenAI CLI is available
if command -v openai &> /dev/null; then
    openai
elif [ -n "$OPENAI_API_KEY" ]; then
    echo "💡 OpenAI API Key detected"
    echo ""
    echo "Available options:"
    echo "  1. Install OpenAI CLI: pip install openai"
    echo "  2. Use ChatGPT API directly"
    echo "  3. Use shell-gpt: brew install shell-gpt"
    echo ""
    $SHELL
else
    echo "⚠️  OpenAI not configured"
    echo ""
    echo "Setup options:"
    echo "  1. export OPENAI_API_KEY='your-key'"
    echo "  2. Install shell-gpt: brew install shell-gpt"
    echo "  3. Install OpenAI CLI: pip install openai"
    echo ""
    $SHELL
fi
OPENAI_EOF
            ;;
        codex)
            cat <<'CODEX_EOF'
source ~/.config/tmuxinator/scripts/common-setup.sh
pane_setup "codex"
clear
echo "🔶 OpenAI Codex Agent"
echo "Repository: $(pwd)"
echo ""
# Check if OpenAI Codex CLI is available
if command -v codex &> /dev/null; then
    codex
else
    echo "⚠️  Codex CLI not installed"
    echo ""
    echo "Install with npm:"
    echo "  npm i -g @openai/codex"
    echo ""
    echo "Requires ChatGPT Plus, Pro, Business, Edu, or Enterprise plan."
    echo ""
    $SHELL
fi
CODEX_EOF
            ;;
        *)
            error "Unknown agent type: $agent_type"
            ;;
    esac
}

# ============================================================================
# PANE SPAWNING LOGIC
# ============================================================================

spawn_agent() {
    local agent_type="$1"
    local window_name="${2:-current}"
    local split_direction="${3:-horizontal}"

    # Check if we're in a tmux session
    if [ -z "$TMUX" ]; then
        echo "❌ Not in a tmux session. Start tmux first." >&2
        exit 1
    fi

    # Get current session name
    local session_name=$(tmux display-message -p '#S')

    # Determine target window
    if [ "$window_name" = "new" ]; then
        # Create new window for AI agents
        tmux new-window -t "$session_name" -n "ai-agents"
        local target_window="${session_name}:ai-agents"
    elif [ "$window_name" = "current" ]; then
        local target_window=$(tmux display-message -p '#S:#I')
    else
        local target_window="${session_name}:${window_name}"
    fi

    # Get the agent command
    local agent_command=$(get_agent_command "$agent_type")

    # Split pane based on direction
    if [ "$split_direction" = "vertical" ]; then
        tmux split-window -t "$target_window" -v
    else
        tmux split-window -t "$target_window" -h
    fi

    # Send the command to the new pane
    tmux send-keys -t "$target_window" "$agent_command" C-m

    # Apply tiled layout to distribute space evenly
    tmux select-layout -t "$target_window" tiled

    # Use tmux display-message for clean output (no color codes in terminal)
    tmux display-message "✅ Spawned $agent_type agent in $target_window"
}

# ============================================================================
# MAIN SCRIPT
# ============================================================================

main() {
    # Parse arguments
    if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        print_usage
        exit 0
    fi

    local agent_type="$1"
    local window_name="${2:-current}"
    local split_direction="${3:-horizontal}"

    # Validate agent type
    case "$agent_type" in
        claude|gemini|openai|codex)
            spawn_agent "$agent_type" "$window_name" "$split_direction"
            ;;
        *)
            # Use tmux display-message for errors too when run from tmux
            if [ -n "$TMUX" ]; then
                tmux display-message "❌ Invalid agent: $agent_type (use: claude, gemini, openai, codex)"
                exit 1
            else
                error "Invalid agent type: $agent_type\nValid options: claude, gemini, openai, codex"
            fi
            ;;
    esac
}

main "$@"
