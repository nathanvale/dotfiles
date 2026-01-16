#!/bin/bash
# Wrapper for worktree-delete.sh - runs in popup, handles session switching after

SWITCH_FILE="/tmp/tmux-worktree-delete-$$"
rm -f "$SWITCH_FILE"

# Run the delete script in a popup
tmux display-popup -w 80% -h 70% -E \
    "bash $HOME/code/dotfiles/bin/tmux/worktree-delete.sh"

rm -f "$SWITCH_FILE"
