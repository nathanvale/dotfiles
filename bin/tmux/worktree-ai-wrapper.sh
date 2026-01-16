#!/bin/bash
# Wrapper for worktree-ai.sh that handles the display-popup -> switch-client issue
#
# Problem: display-popup creates its own tmux client, so switch-client inside
# the popup switches the popup's client, not the parent. When popup closes,
# the switch is lost.
#
# Solution: Run popup, have script write session name to file, switch after popup closes.

# Use a fixed file path (not $$) since run-shell may have different PID context
SWITCH_FILE="/tmp/tmux-worktree-switch"

# Clean up any previous switch file
rm -f "$SWITCH_FILE"

# Run the worktree script in a popup
# The script will write the session name to SWITCH_FILE
tmux display-popup -w 80% -h 70% -E \
    "WORKTREE_SWITCH_FILE='$SWITCH_FILE' bash $HOME/code/dotfiles/bin/tmux/worktree-ai.sh"

# After popup closes, check if we need to switch
# Use tmux run-shell to ensure switch happens in proper client context
if [[ -f "$SWITCH_FILE" ]] && [[ -s "$SWITCH_FILE" ]]; then
    session_name=$(cat "$SWITCH_FILE")
    rm -f "$SWITCH_FILE"
    if tmux has-session -t "$session_name" 2>/dev/null; then
        # Use run-shell -b to run in background after this script exits
        exec tmux switch-client -t "$session_name"
    fi
else
    rm -f "$SWITCH_FILE"
fi
