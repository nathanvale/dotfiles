#!/bin/bash
# tmux-auto-register-hook.sh - Auto-register repositories when tmux sessions start
set -e

# Get the current working directory of the new session
session_name="$1"
session_path="$2"

# If no path provided, try to get it from tmux
if [ -z "$session_path" ]; then
    session_path=$(tmux display-message -t "$session_name" -p "#{pane_current_path}" 2>/dev/null || echo "")
fi

# If still no path, skip
if [ -z "$session_path" ] || [ ! -d "$session_path" ]; then
    exit 0
fi

# Auto-register if the directory has vaultable content
if [ -d "$session_path/.agent-os" ] || [ -d "$session_path/docs" ]; then
    # Use the unified vault script to register
    "$HOME/code/dotfiles/bin/vault" register "$session_path" >/dev/null 2>&1 || true
fi