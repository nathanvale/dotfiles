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
    
    # Only show git branch on the first tab (claude)
    if [ "$window_name" = "claude" ]; then
        branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main") 2>/dev/null
        tmux rename-window -t "${session_name}:${window_name}" "${window_name}:$branch" 2>/dev/null
    else
        tmux rename-window -t "${session_name}:${window_name}" "${window_name}" 2>/dev/null
    fi
    
    tmux set-window-option -t "${session_name}:${window_name}" automatic-rename off 2>/dev/null
    
    if [ -n "$service" ]; then
        cleanup_logs "$service"
    fi
}
