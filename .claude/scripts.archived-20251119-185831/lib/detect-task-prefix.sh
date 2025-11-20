#!/bin/bash
# Detect Task Prefix
#
# Auto-detects the task ID prefix from existing tasks in the directory.
# Analyzes existing task files and returns the most common prefix.
#
# Usage:
#   source ~/.claude/scripts/lib/detect-task-prefix.sh
#   PREFIX=$(detect_task_prefix "/path/to/tasks")
#
# Arguments:
#   $1 - Task directory path
#
# Returns:
#   Detected prefix (e.g., "MPCU-", "T-", "TASK-"), or "TASK-" as default

detect_task_prefix() {
    local task_dir="$1"

    if [ -z "$task_dir" ] || [ ! -d "$task_dir" ]; then
        echo "TASK-"
        return
    fi

    # Strategy 1: Check READY tasks first (active work)
    # Pattern: Extract uppercase letters and dash before first number
    # Examples: MPCU-0001-foo.md → MPCU-, T0044-bar.md → T, SEC-001-baz.md → SEC-
    local ready_prefix=$(find "$task_dir" -maxdepth 1 -type f -name "*.md" ! -name "README.md" -exec grep -l "^status: READY" {} \; 2>/dev/null \
        | xargs -I {} basename {} .md \
        | sed -n 's/^\([A-Z][A-Z]*-*\)[0-9].*/\1/p' \
        | sort | uniq -c | sort -rn | head -1 | awk '{print $2}')

    if [ -n "$ready_prefix" ]; then
        # Ensure it ends with dash
        if [[ "$ready_prefix" != *- ]]; then
            ready_prefix="${ready_prefix}-"
        fi
        echo "$ready_prefix"
        return
    fi

    # Strategy 2: Fallback to all tasks if no READY tasks
    local all_prefix=$(find "$task_dir" -maxdepth 1 -type f -name "*.md" ! -name "README.md" 2>/dev/null \
        | xargs -I {} basename {} .md \
        | sed -n 's/^\([A-Z][A-Z]*-*\)[0-9].*/\1/p' \
        | sort | uniq -c | sort -rn | head -1 | awk '{print $2}')

    if [ -n "$all_prefix" ]; then
        # Ensure it ends with dash
        if [[ "$all_prefix" != *- ]]; then
            all_prefix="${all_prefix}-"
        fi
        echo "$all_prefix"
    else
        # Default fallback
        echo "TASK-"
    fi
}
