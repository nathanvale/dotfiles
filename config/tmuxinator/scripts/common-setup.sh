#!/bin/bash
# ~/.config/tmuxinator/scripts/common-setup.sh
# Shared setup functions for tmuxinator projects

setup_logs() {
    local project_name="$1"
    # Create logs directory structure if it doesn't exist
    mkdir -p .logs/nextjs
    mkdir -p .logs/dev
    mkdir -p .logs/prisma
    mkdir -p .logs/storybook
    # Clean up logs older than 7 days
    find .logs -name "*.log" -mtime +7 -delete 2>/dev/null || true
    # Keep only last 10 log files per service
    for dir in .logs/*/; do
        ls -t "$dir"*.log 2>/dev/null | tail -n +11 | xargs rm -f 2>/dev/null || true
    done
}

setup_vscode_marker() {
    local project_name="$1"
    # Clean up old VS Code marker
    rm -f /tmp/tmux_${project_name}_vscode_opened
}

cleanup_vscode_marker() {
    local project_name="$1"
    # Clean up VS Code marker
    rm -f /tmp/tmux_${project_name}_vscode_opened
}

open_vscode_once() {
    local project_name="$1"
    # Open VS Code (only once per session)
    if [ ! -f /tmp/tmux_${project_name}_vscode_opened ]; then
        code . &
        touch /tmp/tmux_${project_name}_vscode_opened
    fi
}

get_branch_name() {
    git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main"
}

cleanup_logs() {
    local service="$1"
    ls -t .logs/${service}/*.log 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null || true
}

pane_setup() {
    local window_name="$1"
    local service="$2"
    
    # Wait a moment to ensure window is properly created
    sleep 0.1
    
    # Use window name to target the specific window instead of current index
    session_name=$(tmux display-message -p '#S')
    
    # Set window name based on what's running
    case "$window_name" in
        claude)
            tmux rename-window -t "${session_name}:${window_name}" "claude" 2>/dev/null
            ;;
        code)
            tmux rename-window -t "${session_name}:${window_name}" "code" 2>/dev/null
            ;;
        git)
            tmux rename-window -t "${session_name}:${window_name}" "lazygit" 2>/dev/null
            ;;
        shell)
            tmux rename-window -t "${session_name}:${window_name}" "shell" 2>/dev/null
            ;;
        nextjs)
            tmux rename-window -t "${session_name}:${window_name}" "nextjs" 2>/dev/null
            ;;
        storybook)
            tmux rename-window -t "${session_name}:${window_name}" "storybook" 2>/dev/null
            ;;
        vault)
            tmux rename-window -t "${session_name}:${window_name}" "vault" 2>/dev/null
            ;;
        *)
            tmux rename-window -t "${session_name}:${window_name}" "${window_name}" 2>/dev/null
            ;;
    esac
    
    # Disable automatic rename for all windows to keep our custom names
    tmux set-window-option -t "${session_name}:${window_name}" automatic-rename off 2>/dev/null
    
    if [ -n "$service" ]; then
        cleanup_logs "$service"
    fi
}

# Vault management functions
vault_check() {
    local project="${1:-$(basename $PWD)}"

    # Check if vault manager is available
    if ! command -v "$HOME/code/dotfiles/bin/vault/vault" >/dev/null 2>&1; then
        return 0
    fi

    # Check if current project is registered
    local registry=$("$HOME/code/dotfiles/bin/vault/vault" status 2>/dev/null)
    if echo "$registry" | grep -q "$(pwd)"; then
        echo "📚 Vault registered for $project"
    else
        # Check for unregistered vaultable content
        if [ -d ".agent-os" ] || [ -d "docs" ] || [ -d "documentation" ] || [ -d "wiki" ] || [ -d "notes" ]; then
            echo "📝 Unregistered vault content found."
            echo "   Run: vault register"
            echo "   Or use: Ctrl-g V (manage vaults) | Ctrl-g v (open current)"
        fi
    fi
}

open_project_vault() {
    local project="${1:-$(tmux display-message -p '#S' 2>/dev/null || basename $PWD)}"

    if command -v "$HOME/code/dotfiles/bin/vault/vault" >/dev/null 2>&1; then
        "$HOME/code/dotfiles/bin/vault/vault" open
    else
        echo "Vault manager not available"
    fi
}

# Auto-register vaults for current directory
auto_register_vaults() {
    local project_name="$(basename $PWD)"

    if ! command -v "$HOME/code/dotfiles/bin/vault/vault" >/dev/null 2>&1; then
        return 0
    fi

    # Register if has vaultable content and not already registered
    if [ -d ".agent-os" ] || [ -d "docs" ]; then
        local registry=$("$HOME/code/dotfiles/bin/vault/vault" status 2>/dev/null)
        if ! echo "$registry" | grep -q "$(pwd)"; then
            "$HOME/code/dotfiles/bin/vault/vault" register "$(pwd)" >/dev/null 2>&1 && {
                echo "✅ Auto-registered vault for $project_name"
            }
        fi
    fi

    return 0
}

# ============================================================================
# PARALLEL CLAUDE AGENT FUNCTIONS
# ============================================================================

# Setup a parallel task pane with optional auto-launch
# Usage: setup_parallel_task_pane <window_name> <pane_index> <auto_launch>
#
# Arguments:
#   window_name  - Name of the window (e.g., "tasks")
#   pane_index   - Index of the pane (0-based)
#   auto_launch  - If "true", automatically launch /next command
#
# Example in tmuxinator.yml:
#   - tasks:
#       layout: tiled
#       panes:
#         - setup_parallel_task_pane tasks 0 true
#         - setup_parallel_task_pane tasks 1 true
#         - setup_parallel_task_pane tasks 2 true
#         - setup_parallel_task_pane tasks 3 true
setup_parallel_task_pane() {
    local window_name="$1"
    local pane_index="${2:-0}"
    local auto_launch="${3:-false}"
    local stagger_delay=$((pane_index * 2))  # 2 seconds per pane

    # Get session name
    local session_name=$(tmux display-message -p '#S')

    # Set pane title
    tmux select-pane -t "${session_name}:${window_name}.${pane_index}" -T "Agent $((pane_index + 1))"

    # Auto-launch /next if configured
    if [ "$auto_launch" = "true" ]; then
        if [ $stagger_delay -eq 0 ]; then
            echo "🤖 Launching agent $((pane_index + 1)) immediately..."
            tmux send-keys -t "${session_name}:${window_name}.${pane_index}" "claude" C-m
        else
            echo "🤖 Scheduling agent $((pane_index + 1)) to launch in ${stagger_delay}s..."
            tmux send-keys -t "${session_name}:${window_name}.${pane_index}" "sleep $stagger_delay && claude" C-m
        fi
    else
        # Just provide helpful message
        echo "💡 Pane $((pane_index + 1)) ready. Run 'claude' to start agent."
    fi
}

# Create a parallel task window with N panes
# Usage: create_parallel_task_window <num_agents> <auto_launch>
#
# Arguments:
#   num_agents   - Number of agent panes to create (default: 4)
#   auto_launch  - If "true", automatically launch /next in each pane
#
# Example:
#   create_parallel_task_window 4 true
create_parallel_task_window() {
    local num_agents="${1:-4}"
    local auto_launch="${2:-false}"
    local window_name="tasks"

    local session_name=$(tmux display-message -p '#S')

    # Create window if it doesn't exist
    if ! tmux list-windows -t "$session_name" | grep -q "^[0-9]*: ${window_name}"; then
        tmux new-window -t "$session_name" -n "$window_name"
    fi

    # Create panes (first pane already exists from window creation)
    for ((i=1; i<num_agents; i++)); do
        if [ $((i % 2)) -eq 1 ]; then
            tmux split-window -t "${session_name}:${window_name}" -h
        else
            tmux split-window -t "${session_name}:${window_name}" -v
        fi
    done

    # Apply tiled layout
    tmux select-layout -t "${session_name}:${window_name}" tiled

    # Setup each pane
    for ((i=0; i<num_agents; i++)); do
        setup_parallel_task_pane "$window_name" "$i" "$auto_launch"
    done

    echo "✅ Created $num_agents parallel task panes"
}
