#!/bin/bash
# tmux-smart-detach.sh - Switch to another session (simple approach)

# Get current session
current_session=$(tmux display-message -p '#S')

# Get list of other sessions (excluding current)
other_sessions=$(tmux list-sessions -F "#{session_name}" | grep -v "^${current_session}$")

# If there are other sessions, just switch to one
if [ -n "$other_sessions" ]; then
    next_session=$(echo "$other_sessions" | head -1)
    tmux switch-client -t "$next_session"
else
    # No other sessions, use regular detach
    tmux detach-client
fi