#!/bin/bash
# Dynamic Parallel Claude Agent Launcher
#
# Launches N Claude Code agents in parallel tmux panes, each running /next command.
# Integrates with existing lock coordination system to prevent task conflicts.
#
# Usage:
#   parallel-claude.sh [NUM_AGENTS] [MODE]
#
# Arguments:
#   NUM_AGENTS  - Number of agents to launch (default: 4)
#   MODE        - Where to create agents:
#                 'current' - Add window to current session (default)
#                 'new'     - Create dedicated parallel-claude session
#
# Examples:
#   parallel-claude.sh           # Launch 4 agents in current session
#   parallel-claude.sh 10        # Launch 10 agents in current session
#   parallel-claude.sh 2 new     # Launch 2 agents in new session
#
# Integration:
#   - Works with existing find-next-task.sh lock coordination
#   - Respects user's tmux prefix (Ctrl-g)
#   - Creates tiled layout for clean grid display
#   - Staggers execution to prevent race conditions

set -e

# ============================================================================
# CONFIGURATION
# ============================================================================

# Get git root for config reading (worktree-safe)
GIT_ROOT=$(git rev-parse --show-superproject-working-tree 2>/dev/null)
if [ -z "$GIT_ROOT" ]; then
  GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
fi
cd "$GIT_ROOT"

# Read git config options (gtr-compatible)
DEFAULT_AGENTS=$(git config --get gtr.parallel.default 2>/dev/null || echo "4")
MAX_AGENTS=$(git config --get gtr.parallel.max 2>/dev/null || echo "50")
STAGGER_DELAY=$(git config --get gtr.parallel.stagger 2>/dev/null || echo "2")
AUTO_LAUNCH=$(git config --bool --get gtr.parallel.auto 2>/dev/null || echo "true")

NUM_AGENTS="${1:-$DEFAULT_AGENTS}"
MODE="${2:-current}"
WINDOW_NAME="claude-parallel"

# Validate num_agents is a positive integer
if ! [[ "$NUM_AGENTS" =~ ^[0-9]+$ ]] || [ "$NUM_AGENTS" -lt 1 ]; then
    echo "Error: NUM_AGENTS must be a positive integer" >&2
    exit 1
fi

# Enforce max agents limit
if [ "$NUM_AGENTS" -gt "$MAX_AGENTS" ]; then
    echo "Warning: Requested $NUM_AGENTS agents exceeds max ($MAX_AGENTS). Using $MAX_AGENTS." >&2
    NUM_AGENTS=$MAX_AGENTS
fi

# Validate mode
if [[ "$MODE" != "current" && "$MODE" != "new" ]]; then
    echo "Error: MODE must be 'current' or 'new'" >&2
    exit 1
fi

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Source color logging utilities if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Resolve git root to find utils
GIT_ROOT=$(git rev-parse --show-superproject-working-tree 2>/dev/null)
if [ -z "$GIT_ROOT" ]; then
  GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || cd "$SCRIPT_DIR/../../../.." && pwd)
fi

COLOUR_LOG_PATH="$GIT_ROOT/bin/utils/colour_log.sh"
if [ -f "$COLOUR_LOG_PATH" ]; then
    source "$COLOUR_LOG_PATH"
else
    # Fallback logging functions
    log_info() { echo "[INFO] $*"; }
    log_success() { echo "[SUCCESS] $*"; }
    log_error() { echo "[ERROR] $*" >&2; }
fi

# Get current session name or create new one
get_session_name() {
    if [ "$MODE" = "new" ]; then
        echo "parallel-claude"
    else
        tmux display-message -p '#S'
    fi
}

# Check if we're inside tmux
check_tmux() {
    if [ -z "$TMUX" ] && [ "$MODE" = "current" ]; then
        log_error "Not inside a tmux session. Use MODE=new or run from within tmux."
        exit 1
    fi
}

# Create or attach to session
setup_session() {
    local session_name="$1"

    if [ "$MODE" = "new" ]; then
        # Create new session if it doesn't exist
        if ! tmux has-session -t "$session_name" 2>/dev/null; then
            tmux new-session -d -s "$session_name" -n "$WINDOW_NAME"
            log_info "Created new session: $session_name"
        else
            log_info "Attaching to existing session: $session_name"
        fi
    else
        # Create new window in current session
        tmux new-window -n "$WINDOW_NAME"
        log_info "Created window '$WINDOW_NAME' in current session"
    fi
}

# Create pane layout for N agents
create_pane_layout() {
    local session_name="$1"
    local window_name="$2"
    local num_agents="$3"

    local target="${session_name}:${window_name}"

    # First pane already exists from window creation
    # Create N-1 additional panes
    for ((i=2; i<=num_agents; i++)); do
        if [ $((i % 2)) -eq 0 ]; then
            # Even panes: split horizontally
            tmux split-window -t "$target" -h
        else
            # Odd panes: split vertically
            tmux split-window -t "$target" -v
        fi
    done

    # Apply tiled layout for clean grid
    tmux select-layout -t "$target" tiled

    log_info "Created $num_agents panes in tiled layout"
}

# Launch claude code in each pane with staggered delays
launch_agents() {
    local session_name="$1"
    local window_name="$2"
    local num_agents="$3"

    local target="${session_name}:${window_name}"

    # Check if auto-launch is enabled
    if [ "$AUTO_LAUNCH" != "true" ]; then
        log_info "Auto-launch disabled (gtr.parallel.auto=false)"
        log_info "Manually run 'claude' in each pane when ready"
        return
    fi

    for ((i=0; i<num_agents; i++)); do
        local pane_index=$i

        # Calculate stagger delay (first agent starts immediately)
        local delay=$((i * STAGGER_DELAY))

        # Send command to specific pane
        if [ $delay -eq 0 ]; then
            tmux send-keys -t "${target}.${pane_index}" "claude" C-m
            log_info "Launched agent $((i+1))/$num_agents immediately"
        else
            # Use sleep to stagger subsequent launches
            tmux send-keys -t "${target}.${pane_index}" "sleep $delay && claude" C-m
            log_info "Scheduled agent $((i+1))/$num_agents to launch in ${delay}s"
        fi
    done

    log_success "All $num_agents agents scheduled for launch"
}

# Display instructions to user
show_instructions() {
    local session_name="$1"
    local num_agents="$2"

    cat <<EOF

╔════════════════════════════════════════════════════════════════╗
║  🚀 Parallel Claude Agent Launcher                            ║
╠════════════════════════════════════════════════════════════════╣
║  Session:        $session_name
║  Agents:         $num_agents
║  Stagger Delay:  ${STAGGER_DELAY}s between launches
╠════════════════════════════════════════════════════════════════╣
║  📋 Next Steps:                                               ║
║                                                                ║
║  1. Wait for all agents to launch (staggered start)           ║
║  2. In each Claude pane, run: /next                           ║
║  3. Monitor progress with: Ctrl-g M (task monitor)            ║
║                                                                ║
║  💡 Tips:                                                      ║
║  - Use Ctrl-g o to cycle through panes                        ║
║  - Use Ctrl-g z to zoom into a single pane                    ║
║  - Locks prevent duplicate task selection                     ║
║  - Each agent works in isolated worktree                      ║
╚════════════════════════════════════════════════════════════════╝

EOF
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    log_info "Starting parallel Claude agent launcher..."
    log_info "Agents: $NUM_AGENTS | Mode: $MODE"

    # Validate environment
    check_tmux

    # Get or create session
    SESSION_NAME=$(get_session_name)

    # Setup session/window
    setup_session "$SESSION_NAME"

    # Create pane layout
    create_pane_layout "$SESSION_NAME" "$WINDOW_NAME" "$NUM_AGENTS"

    # Launch agents with staggered delays
    launch_agents "$SESSION_NAME" "$WINDOW_NAME" "$NUM_AGENTS"

    # Show instructions
    show_instructions "$SESSION_NAME" "$NUM_AGENTS"

    # Attach to session if in 'new' mode
    if [ "$MODE" = "new" ] && [ -z "$TMUX" ]; then
        log_info "Attaching to session..."
        tmux attach-session -t "$SESSION_NAME"
    fi
}

# Run main function
main
