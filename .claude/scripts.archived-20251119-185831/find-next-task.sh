#!/bin/bash
# Universal Task Selector
#
# Finds the highest priority READY task with all dependencies met and no active locks.
# Works in ANY project with a task directory structure.
#
# Usage:
#   find-next-task.sh           # Plain text output (TASK_ID)
#   find-next-task.sh --json    # JSON output (rich metadata)
#
# Returns:
#   Plain mode: TASK_ID (e.g., T0033) or empty if no tasks available
#   JSON mode:  {"taskId":"T0033","filePath":"...","priority":"P1",...} or {}
#
# Exit Codes:
#   0 - Task found or not found (check output)
#   1 - Error (task directory not found)

set -e

# Parse arguments
JSON_MODE=false
if [ "$1" = "--json" ]; then
    JSON_MODE=true
fi

# ============================================================================
# DETECT GIT REPOSITORY ROOT
# ============================================================================

# Get the absolute path to the git repository root (worktree-safe)
GIT_ROOT=$(git rev-parse --show-superproject-working-tree 2>/dev/null)

if [ -z "$GIT_ROOT" ]; then
    # Not in a worktree, try main repo
    GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
fi

if [ -z "$GIT_ROOT" ]; then
    # Not in a git repository - use current directory
    GIT_ROOT=$(pwd)
fi

# Change to git root to ensure consistent path resolution
cd "$GIT_ROOT"

# ============================================================================
# AUTO-DETECT TASK DIRECTORY
# ============================================================================

TASK_DIR=""
if [ -d "apps/migration-cli/docs/tasks" ]; then
    TASK_DIR="apps/migration-cli/docs/tasks"
elif [ -d "docs/tasks" ]; then
    TASK_DIR="docs/tasks"
elif [ -d "tasks" ]; then
    TASK_DIR="tasks"
elif [ -d ".tasks" ]; then
    TASK_DIR=".tasks"
else
    # Try to find any monorepo package with tasks
    TASK_DIR=$(find . -path "*/apps/*/docs/tasks" -o -path "*/packages/*/docs/tasks" 2>/dev/null | head -1)
    if [ -z "$TASK_DIR" ]; then
        # No task directory found - silent exit
        exit 1
    fi
fi

# ============================================================================
# RESOURCE LIMITING: Check max parallel agents (simple lock count)
# ============================================================================

# Read git config for max parallel agents (gtr-compatible)
MAX_PARALLEL=$(git config --get gtr.parallel.max 2>/dev/null || echo "")

if [ -n "$MAX_PARALLEL" ]; then
    # Get centralized lock directory
    source ~/.claude/scripts/lib/get-project-lock-dir.sh
    TEMP_LOCK_DIR=$(get_project_lock_dir)

    # Count ALL locks (no PID checking)
    # Lock exists = task is being worked on
    ACTIVE_COUNT=0
    if [ -d "$TEMP_LOCK_DIR" ]; then
        ACTIVE_COUNT=$(find "$TEMP_LOCK_DIR" -name "*.lock" -type f 2>/dev/null | wc -l | tr -d ' ')
    fi

    # Check if we've hit the limit
    if [ "$ACTIVE_COUNT" -ge "$MAX_PARALLEL" ]; then
        if [ "$JSON_MODE" = true ]; then
            echo "{}"
        else
            echo "Max parallel agents reached ($ACTIVE_COUNT/$MAX_PARALLEL)" >&2
        fi
        exit 0
    fi
fi

# ============================================================================
# FIND READY TASKS WITH DEPENDENCIES MET AND NO LOCKS
# ============================================================================

# Variables to store selected task (persist outside loop)
SELECTED_TASK_ID=""
SELECTED_TASK_FILE=""
SELECTED_PRIORITY=""
SELECTED_TITLE=""
HIGHEST_PRIORITY=""

# Get centralized project lock directory (shared across all worktrees)
source ~/.claude/scripts/lib/get-project-lock-dir.sh
LOCK_DIR=$(get_project_lock_dir)

# Use process substitution to avoid subshell issue
while IFS= read -r task_file; do
    # Extract status
    STATUS=$(grep "^status:" "$task_file" | sed 's/status: *//' || echo "")

    if [ "$STATUS" != "READY" ]; then
        continue
    fi

    # Extract priority
    PRIORITY=$(grep "^priority:" "$task_file" | sed 's/priority: *//' || echo "P3")

    # Extract task ID from filename (supports both T#### and MPCU-NNN formats)
    # Pattern: Extract everything before the last descriptive part (e.g., "MPCU-003" from "MPCU-003-fix-auth.md")
    FILENAME=$(basename "$task_file" .md)
    # Get first component if it matches WORD-DIGITS pattern, otherwise try T#### pattern
    if [[ "$FILENAME" =~ ^([A-Z]+-[0-9]+)- ]]; then
        CURRENT_TASK_ID="${BASH_REMATCH[1]}"
    elif [[ "$FILENAME" =~ ^(T[0-9]{4})- ]]; then
        CURRENT_TASK_ID="${BASH_REMATCH[1]}"
    else
        # Fallback: take everything up to first dash
        CURRENT_TASK_ID=$(echo "$FILENAME" | cut -d'-' -f1-2)
    fi

    # ========================================================================
    # CHECK FOR LOCK (simple gate: exists = locked, skip it)
    # ========================================================================
    LOCK_FILE="${LOCK_DIR}/${CURRENT_TASK_ID}.lock"

    if [ -f "$LOCK_FILE" ]; then
        # Task is locked - skip it. Period.
        # No PID checking, no "stale" detection.
        # Use unlock-task.sh to manually remove locks if needed.
        continue
    fi

    # ========================================================================
    # CHECK GITHUB ASSIGNMENT (optional, distributed lock)
    # ========================================================================
    GITHUB_URL=$(grep '^github:' "$task_file" 2>/dev/null | sed 's/github: *//' | tr -d '[:space:]' || echo "")

    if [ -n "$GITHUB_URL" ] && command -v gh &> /dev/null; then
        # Extract issue number from URL
        GITHUB_ISSUE_NUM=$(echo "$GITHUB_URL" | grep -oE '[0-9]+$' || echo "")

        if [ -n "$GITHUB_ISSUE_NUM" ]; then
            # Check current assignee
            CURRENT_ASSIGNEE=$(gh issue view "$GITHUB_ISSUE_NUM" --json assignees -q '.assignees[0].login' 2>/dev/null || echo "")

            if [ -n "$CURRENT_ASSIGNEE" ] && [ "$CURRENT_ASSIGNEE" != "$USER" ]; then
                # Task is assigned to someone else on GitHub - skip it
                continue
            fi
        fi
    fi

    # ========================================================================
    # CHECK DEPENDENCIES
    # ========================================================================
    DEPENDS_ON=$(grep "^depends_on:" "$task_file" | sed 's/depends_on: *\[\(.*\)\]/\1/' || echo "")

    # Filter out empty or malformed dependency strings
    if [ -n "$DEPENDS_ON" ] && [ "$DEPENDS_ON" != "depends_on:" ]; then
        ALL_MET=true
        for dep in $(echo "$DEPENDS_ON" | tr ',' ' '); do
            # Clean up whitespace
            dep=$(echo "$dep" | xargs)

            # Find dependency task file
            DEP_FILE=$(find "$TASK_DIR" -name "${dep}-*.md" -type f | head -1)

            if [ -z "$DEP_FILE" ]; then
                ALL_MET=false
                break
            fi

            # Check if dependency is COMPLETED
            DEP_STATUS=$(grep "^status:" "$DEP_FILE" | sed 's/status: *//' || echo "")

            if [ "$DEP_STATUS" != "COMPLETED" ]; then
                ALL_MET=false
                break
            fi
        done

        if [ "$ALL_MET" = false ]; then
            continue
        fi
    fi

    # ========================================================================
    # SELECT HIGHEST PRIORITY TASK
    # ========================================================================
    # Priority comparison (P0 > P1 > P2 > P3)
    # Lower string value = higher priority (P0 < P1 < P2 < P3)
    if [ -z "$HIGHEST_PRIORITY" ] || [ "$PRIORITY" \< "$HIGHEST_PRIORITY" ]; then
        HIGHEST_PRIORITY="$PRIORITY"
        SELECTED_TASK_ID="$CURRENT_TASK_ID"
        SELECTED_TASK_FILE="$task_file"
        SELECTED_PRIORITY="$PRIORITY"
        # Extract title from first heading
        SELECTED_TITLE=$(grep "^# " "$task_file" | head -n 1 | sed 's/^# *//' | sed 's/^P[0-3]: *//' || echo "")
    fi
done < <(find "$TASK_DIR" -name "*-*.md" -type f)

# ============================================================================
# OUTPUT RESULTS
# ============================================================================

if [ "$JSON_MODE" = true ]; then
    # JSON output mode
    if [ -n "$SELECTED_TASK_ID" ]; then
        # Escape quotes in title for JSON
        SAFE_TITLE=$(echo "$SELECTED_TITLE" | sed 's/"/\\"/g')

        cat <<EOF
{
  "taskId": "$SELECTED_TASK_ID",
  "filePath": "$SELECTED_TASK_FILE",
  "priority": "$SELECTED_PRIORITY",
  "status": "READY",
  "hasLock": false,
  "title": "$SAFE_TITLE",
  "taskDir": "$TASK_DIR"
}
EOF
    else
        # No tasks available
        echo "{}"
    fi
else
    # Plain text output mode (backwards compatible)
    if [ -n "$SELECTED_TASK_ID" ]; then
        echo "$SELECTED_TASK_ID"
    fi
fi
