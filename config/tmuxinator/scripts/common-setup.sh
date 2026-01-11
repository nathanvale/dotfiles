#!/bin/bash
# common-setup.sh - Minimal shared functions for tmuxinator
# Most functionality moved to templates and tx CLI

# Rename window and disable auto-rename
pane_setup() {
    local name="$1"
    tmux rename-window "$name" 2>/dev/null || true
    tmux set-window-option automatic-rename off 2>/dev/null || true
}
