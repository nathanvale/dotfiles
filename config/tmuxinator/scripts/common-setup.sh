#!/bin/bash
# common-setup.sh - Minimal shared functions for tmuxinator
# Most functionality moved to templates and tx CLI

# Rename window and disable auto-rename
# Args: $1=name, $2=optional (ignored for backwards compatibility)
pane_setup() {
    local name="$1"
    # $2 is optional and ignored (for backwards compatibility)
    tmux rename-window "$name" 2>/dev/null || true
    tmux set-window-option automatic-rename off 2>/dev/null || true
}

# Stub for backwards compatibility with existing callers
# Args: $1=session_name (ignored)
setup_logs() {
    # No-op: Functionality moved to tx CLI and templates
    :
}
