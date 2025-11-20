#!/bin/bash
# Helper function to get centralized project lock directory
# Location: ~/.claude/scripts/lib/get-project-lock-dir.sh
#
# Returns the centralized lock directory for the current project
# All worktrees for the same project share this directory
#
# Uses .git/task-locks/ to keep locks with the repository
# (same pattern as .git/task-counter)
#
# Usage:
#   LOCK_DIR=$(source ~/.claude/scripts/lib/get-project-lock-dir.sh && get_project_lock_dir)

get_project_lock_dir() {
    # Get the COMMON .git directory (shared across all worktrees)
    local git_dir=$(git rev-parse --git-common-dir 2>/dev/null)

    if [ -z "$git_dir" ]; then
        # Not in a git repo - fall back to temp directory
        echo "/tmp/task-locks"
        return
    fi

    # Return lock directory inside .git (shared by all worktrees)
    echo "$git_dir/task-locks"
}

# If script is sourced and function called directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    get_project_lock_dir
fi
