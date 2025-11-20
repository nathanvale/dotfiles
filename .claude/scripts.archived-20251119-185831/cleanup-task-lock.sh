#!/usr/bin/env bash
# Cleanup lock file for a task
# Usage: cleanup-task-lock.sh T0041 [project-path]
#
# If project-path not provided, uses current directory's git repo

TASK_ID=$1
PROJECT_PATH=$2

if [ -z "$TASK_ID" ]; then
    echo "Usage: cleanup-task-lock.sh TASK_ID [project-path]"
    exit 1
fi

# If project path provided, cd there first
if [ -n "$PROJECT_PATH" ]; then
    if [ ! -d "$PROJECT_PATH" ]; then
        echo "❌ ERROR: Project path not found: $PROJECT_PATH"
        exit 1
    fi
    cd "$PROJECT_PATH" || exit 1
fi

# Get centralized lock directory
if ! source ~/.claude/scripts/lib/get-project-lock-dir.sh 2>/dev/null; then
    echo "❌ ERROR: Failed to source get-project-lock-dir.sh"
    exit 1
fi

LOCK_DIR=$(get_project_lock_dir 2>/dev/null)

if [ -z "$LOCK_DIR" ]; then
    echo "❌ ERROR: Could not determine lock directory (not in a git repo?)"
    exit 1
fi

LOCK_FILE="${LOCK_DIR}/${TASK_ID}.lock"

if [ -f "$LOCK_FILE" ]; then
    rm "$LOCK_FILE"
    echo "✅ Lock removed: ${TASK_ID}"
    echo "   From: $LOCK_FILE"
else
    echo "⚠️  No lock found for ${TASK_ID}"
    echo "   Expected at: $LOCK_FILE"
    echo "   (This is OK if lock was already cleaned or process died)"
fi
