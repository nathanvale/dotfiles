#!/bin/bash
# Wrapper for worktree-ai.sh that handles the display-popup -> switch-client issue

SWITCH_FILE="/tmp/tmux-worktree-switch"
DEBUG_FILE="/tmp/tmux-worktree-debug"

# Debug log function
debug() {
    echo "$(date '+%H:%M:%S') $1" >> "$DEBUG_FILE"
}

debug "=== Wrapper started ==="
debug "SWITCH_FILE: $SWITCH_FILE"

# Clean up any previous switch file
rm -f "$SWITCH_FILE"

# Run the worktree script in a popup
debug "Launching popup..."
tmux display-popup -w 80% -h 70% -E \
    "WORKTREE_SWITCH_FILE='$SWITCH_FILE' bash $HOME/code/dotfiles/bin/tmux/worktree-ai.sh"

debug "Popup closed"
debug "Switch file exists: $(test -f "$SWITCH_FILE" && echo "yes" || echo "no")"
debug "Switch file contents: $(cat "$SWITCH_FILE" 2>/dev/null || echo "empty")"

# After popup closes, check if we need to switch
if [[ -f "$SWITCH_FILE" ]] && [[ -s "$SWITCH_FILE" ]]; then
    session_name=$(cat "$SWITCH_FILE")
    debug "Session to switch to: $session_name"
    rm -f "$SWITCH_FILE"

    if tmux has-session -t "$session_name" 2>/dev/null; then
        debug "Session exists, attempting switch..."
        tmux switch-client -t "$session_name" 2>>"$DEBUG_FILE"
        debug "Switch command exit code: $?"
    else
        debug "Session does NOT exist: $session_name"
    fi
else
    debug "No switch file or empty"
    rm -f "$SWITCH_FILE"
fi

debug "=== Wrapper finished ==="
