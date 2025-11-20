#!/bin/bash
# Atomic Task Selector with Locking
#
# Finds the highest priority READY task and IMMEDIATELY locks it in a single atomic operation.
# If lock fails (another agent got it), automatically tries the next task.
# This prevents race conditions where multiple agents select the same task.
#
# Usage:
#   ./select-and-lock-task.sh [--json]
#
# Returns:
#   - JSON with selected task info (if --json flag)
#   - Empty JSON {} if no unlocked tasks available
#   - Exit code 0 on success, 1 if no tasks available

set -euo pipefail

# Ensure jq is available for JSON rendering
if ! command -v jq >/dev/null 2>&1; then
    echo "❌ jq is required for select-and-lock-task.sh" >&2
    exit 1
fi

timestamp_utc() {
    date -u +%Y-%m-%dT%H:%M:%SZ
}

AGENT_ID="${CLAUDE_AGENT_ID:-${USER}-agent-$$}"

# Parse arguments
OUTPUT_JSON=false
if [ "${1:-}" = "--json" ]; then
    OUTPUT_JSON=true
fi

# Get git repo root
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

# Import lock directory helper
source ~/.claude/scripts/lib/get-project-lock-dir.sh
LOCK_DIR=$(get_project_lock_dir)
mkdir -p "$LOCK_DIR"

# Atomic lock creation function
# Returns 0 if lock created successfully, 1 if already locked
try_create_lock() {
    local task_id=$1
    local lock_file="${LOCK_DIR}/${task_id}.lock"

    # Quick gate
    if [ -f "$lock_file" ]; then
        return 1
    fi

    local tmp_file
    tmp_file=$(mktemp "${LOCK_DIR}/.${task_id}.lock.XXXXXX")

    local now
    now=$(timestamp_utc)

    jq -n \
        --arg taskId "$task_id" \
        --argjson pid "$$" \
        --arg agentId "$AGENT_ID" \
        --arg hostname "$(hostname)" \
        --arg lockedAt "$now" \
        --arg heartbeatAt "$now" \
        '{
          taskId: $taskId,
          pid: $pid,
          agentId: $agentId,
          hostname: $hostname,
          lockedAt: $lockedAt,
          heartbeatAt: $heartbeatAt,
          status: "LOCKED"
        }' > "$tmp_file"

    # Attempt atomic link (fails if lock already exists)
    if ln "$tmp_file" "$lock_file" 2>/dev/null; then
        rm -f "$tmp_file"
        return 0
    fi

    rm -f "$tmp_file"
    return 1
}

# Find task directory
TASK_DIR=""
if [ -d "$REPO_ROOT/docs/tasks" ]; then
    TASK_DIR="$REPO_ROOT/docs/tasks"
elif [ -d "$REPO_ROOT/apps" ]; then
    # Search for first docs/tasks in apps/*/docs/tasks
    TASK_DIR=$(find "$REPO_ROOT/apps" -maxdepth 3 -type d -path "*/docs/tasks" 2>/dev/null | head -1 || echo "")
fi

if [ -z "$TASK_DIR" ] || [ ! -d "$TASK_DIR" ]; then
    if [ "$OUTPUT_JSON" = true ]; then
        echo "{}"
    else
        echo "❌ No task directory found"
    fi
    exit 1
fi

# Parse priority from task frontmatter
get_priority() {
    local file=$1
    grep '^priority:' "$file" 2>/dev/null | sed 's/priority: *//' | tr -d '[:space:]' || echo "P3"
}

# Convert priority to numeric for sorting (P0=0, P1=1, P2=2, P3=3)
priority_to_num() {
    local p=$1
    echo "$p" | sed 's/P//'
}

# Determine if a dependency status counts as completed
is_completed_status() {
    case "$1" in
        COMPLETED|DONE)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Check if all dependencies are met
check_dependencies() {
    local file=$1
    local deps_raw=$(grep '^depends_on:' "$file" 2>/dev/null | sed 's/depends_on: *//' || echo "")
    local deps=$(echo "$deps_raw" | tr -d '[]"' | tr ',' ' ' | xargs)

    if [ -z "$deps" ]; then
        return 0  # No dependencies
    fi

    # Check each dependency
    for dep_id in $deps; do
        dep_id=$(echo "$dep_id" | tr -d '[:space:]')

        # Find dependency task file
        local dep_file=$(find "$TASK_DIR" -maxdepth 1 -type f -name "${dep_id}-*.md" 2>/dev/null | head -1)

        if [ -z "$dep_file" ]; then
            return 1  # Dependency not found
        fi

        # Check if dependency is completed
        local dep_status=$(grep '^status:' "$dep_file" 2>/dev/null | sed 's/status: *//' | tr -d '[:space:]' || echo "")

        if ! is_completed_status "$dep_status"; then
            return 1  # Dependency not completed
        fi
    done

    return 0  # All dependencies met
}

# Build list of READY tasks with priorities
TASK_LIST=()

while IFS= read -r task_file; do
    [ -f "$task_file" ] || continue

    # Extract task ID (handles formats like "T0044-description.md" or "MPCU-0005-description.md")
    # Pattern: starts with uppercase letters, optional dash, then numbers, then dash
    TASK_ID=$(basename "$task_file" .md | sed 's/^\([A-Z][A-Z0-9-]*[0-9]\)-.*/\1/')

    # Check status
    STATUS=$(grep '^status:' "$task_file" 2>/dev/null | sed 's/status: *//' | tr -d '[:space:]' || echo "")

    if [ "$STATUS" != "READY" ]; then
        continue
    fi

    # Check dependencies
    if ! check_dependencies "$task_file"; then
        continue
    fi

    # Get priority
    PRIORITY=$(get_priority "$task_file")
    PRIORITY_NUM=$(priority_to_num "$PRIORITY")

    # Add to list: "priority_num|task_id|task_file|priority"
    TASK_LIST+=("${PRIORITY_NUM}|${TASK_ID}|${task_file}|${PRIORITY}")

done < <(find "$TASK_DIR" -maxdepth 1 -type f -name "*.md" ! -name "README.md" 2>/dev/null)

# Check if any tasks found
if [ ${#TASK_LIST[@]} -eq 0 ]; then
    if [ "$OUTPUT_JSON" = true ]; then
        echo "{}"
    else
        echo "✅ No READY tasks available"
    fi
    exit 1
fi

# Sort by priority (numeric), then by task ID
IFS=$'\n' SORTED_TASKS=($(printf '%s\n' "${TASK_LIST[@]}" | sort -t'|' -k1,1n -k2,2))

# Try each task in priority order until we successfully lock one
for task_entry in "${SORTED_TASKS[@]}"; do
    IFS='|' read -r _ TASK_ID TASK_FILE PRIORITY <<< "$task_entry"

    # Try to lock this task atomically
    if try_create_lock "$TASK_ID"; then
        # Successfully locked! Return this task
        TASK_TITLE=$(grep '^title:' "$TASK_FILE" 2>/dev/null | sed 's/title: *//' || echo "")

        # Make task file path relative to repo root
        REL_PATH="${TASK_FILE#$REPO_ROOT/}"

                if [ "$OUTPUT_JSON" = true ]; then
                        jq -n \
                                --arg taskId "$TASK_ID" \
                                --arg filePath "$TASK_FILE" \
                                --arg priority "$PRIORITY" \
                                --arg status "READY" \
                                --arg lockFile "${LOCK_DIR}/${TASK_ID}.lock" \
                                --arg title "$TASK_TITLE" \
                                --arg taskDir "$TASK_DIR" \
                                '{
                                    taskId: $taskId,
                                    filePath: $filePath,
                                    priority: $priority,
                                    status: $status,
                                    hasLock: true,
                                    lockFile: $lockFile,
                                    title: $title,
                                    taskDir: $taskDir
                                }'
        else
            # Human-readable output
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "🔒 Task Locked: $TASK_ID ($PRIORITY)"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "📄 Title: $TASK_TITLE"
            echo "📁 File: $REL_PATH"
            echo "🔐 Lock: ${LOCK_DIR}/${TASK_ID}.lock"
            echo ""
        fi

        # Send tmux notification
        ~/code/dotfiles/config/tmux/scripts/notify-lock-event.sh locked "$TASK_ID" 2>/dev/null || true

        exit 0
    fi

    # Lock failed - task is locked by another agent, try next task
done

# All tasks are locked
if [ "$OUTPUT_JSON" = true ]; then
    echo "{}"
else
    echo "⚠️  All READY tasks are currently locked by other agents"
    echo "Try again in a few moments or check lock status:"
    echo "  ls -la $LOCK_DIR"
fi

exit 1
