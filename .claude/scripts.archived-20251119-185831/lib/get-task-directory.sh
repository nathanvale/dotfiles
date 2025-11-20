#!/bin/bash
# Get Task Directory
#
# Auto-detects the task directory for the current repository.
# Checks common patterns: docs/tasks, apps/*/docs/tasks
#
# Usage:
#   source ~/.claude/scripts/lib/get-task-directory.sh
#   TASK_DIR=$(get_task_directory)
#
# Returns:
#   Absolute path to task directory, or empty string if not found

get_task_directory() {
    local repo_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
    local task_dir=""

    # Check root-level docs/tasks
    if [ -d "$repo_root/docs/tasks" ]; then
        task_dir="$repo_root/docs/tasks"
    # Check for apps/*/docs/tasks (monorepo pattern)
    elif [ -d "$repo_root/apps" ]; then
        task_dir=$(find "$repo_root/apps" -maxdepth 3 -type d -path "*/docs/tasks" 2>/dev/null | head -1 || echo "")
    fi

    echo "$task_dir"
}
