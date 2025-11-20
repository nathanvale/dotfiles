#!/bin/bash
# Cleanup stale lock files using heartbeat timestamps and git status

set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
    echo "❌ jq is required for cleanup-stale-locks.sh" >&2
    exit 1
fi

source ~/.claude/scripts/lib/get-project-lock-dir.sh

# Default configuration
MAX_HEARTBEAT_MINUTES=${MAX_HEARTBEAT_MINUTES:-20}
HISTORY_FILE=${HISTORY_FILE:-".git/task-locks/history.log"}
QUIET=false
DRY_RUN=false
SIMPLE=false

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

Options:
  --max-age MINUTES    Consider locks stale after MINUTES (default: $MAX_HEARTBEAT_MINUTES)
  --quiet              Suppress non-essential output
  --dry-run            Show actions without deleting
  --simple             Minimal output (for automation)
  -h, --help           Show this help
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --max-age)
            if [ -z "${2:-}" ]; then
                echo "--max-age requires a value" >&2
                exit 1
            fi
            MAX_HEARTBEAT_MINUTES="$2"
            shift 2 ;;
        --quiet)
            QUIET=true
            shift ;;
        --dry-run)
            DRY_RUN=true
            shift ;;
        --simple)
            SIMPLE=true
            shift ;;
        -h|--help)
            usage
            exit 0 ;;
        --)
            shift
            break ;;
        -*)
            echo "Unknown option: $1" >&2
            usage
            exit 1 ;;
        *)
            echo "Unexpected argument: $1" >&2
            usage
            exit 1 ;;
    esac
done

LOCK_DIR=$(get_project_lock_dir)
if [ -z "$LOCK_DIR" ] || [ ! -d "$LOCK_DIR" ]; then
    $SIMPLE || echo "No lock directory found"
    exit 0
fi

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
HISTORY_PATH="$REPO_ROOT/$HISTORY_FILE"
mkdir -p "$(dirname "$HISTORY_PATH")"

timestamp_utc() { date -u +%Y-%m-%dT%H:%M:%SZ; }

minutes_since() {
    local ts=$1
    if [ -z "$ts" ]; then
        echo 999999
        return
    fi
    local since=$(( ( $(date -u +%s) - $(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$ts" +%s 2>/dev/null || date -u +%s ) ) / 60 ))
    echo "${since#-}"
}

log_event() {
    local msg=$1
    printf "%s %s\n" "$(timestamp_utc)" "$msg" >> "$HISTORY_PATH"
}

is_branch_merged() {
    local branch=$1
    if [ -z "$branch" ]; then
        return 1
    fi
    if git show-ref --verify --quiet "refs/heads/$branch" 2>/dev/null; then
        if git merge-base --is-ancestor "$branch" main 2>/dev/null; then
            return 0
        fi
    else
        # If branch doesn't exist locally, assume merged if lock is old
        return 0
    fi
    return 1
}

should_remove_lock() {
    local task_id=$1
    local heartbeat=$2
    local branch=$3
    local status=$4

    # Completed tasks or merged branches are safe to remove
    if [ "$status" = "COMPLETED" ]; then
        return 0
    fi

    if is_branch_merged "$branch"; then
        return 0
    fi

    # Heartbeat timeout
    local minutes
    minutes=$(minutes_since "$heartbeat")
    if [ "$minutes" -ge "$MAX_HEARTBEAT_MINUTES" ]; then
        return 0
    fi

    return 1
}

removed=0
skipped=0
errors=0

declare -a REPORT_LINES=()

for lock_file in "$LOCK_DIR"/*.lock; do
    [ -f "$lock_file" ] || continue

    data=$(cat "$lock_file")
    task_id=$(echo "$data" | jq -r '.taskId // empty')
    heartbeat=$(echo "$data" | jq -r '.heartbeatAt // .lockedAt // empty')
    branch=$(echo "$data" | jq -r '.branch // empty')
    status=$(echo "$data" | jq -r '.status // empty')
    agent=$(echo "$data" | jq -r '.agentId // empty')

    if [ -z "$task_id" ]; then
        $SIMPLE || echo "⚠️  Skipping invalid lock: $lock_file"
        errors=$((errors + 1))
        continue
    fi

    if should_remove_lock "$task_id" "$heartbeat" "$branch" "$status"; then
        if [ "$DRY_RUN" = true ]; then
            $SIMPLE || echo "🧹 (dry-run) Would remove $task_id (agent: $agent)"
        else
            rm -f "$lock_file"
            log_event "Removed lock $task_id (agent: $agent, heartbeat: $heartbeat, branch: $branch)"
            $SIMPLE || echo "🧹 Removed stale lock: $task_id (agent: $agent)"
            # Send tmux notification
            ~/code/dotfiles/config/tmux/scripts/notify-lock-event.sh stale "$task_id" "agent: $agent" 2>/dev/null || true
        fi
        removed=$((removed + 1))
    else
        skipped=$((skipped + 1))
        if [ "$SIMPLE" != true ]; then
            REPORT_LINES+=("$task_id|$agent|$heartbeat|$branch|$status")
        fi
    fi

done

if [ "$SIMPLE" != true ]; then
    echo ""
    echo "Active locks:"
    printf "%-12s %-20s %-20s %-20s %-12s\n" "Task" "Agent" "Heartbeat" "Branch" "Status"
    for line in "${REPORT_LINES[@]}"; do
        IFS='|' read -r t a h b s <<< "$line"
        printf "%-12s %-20s %-20s %-20s %-12s\n" "$t" "$a" "$h" "$b" "$s"
    done
fi

if [ "$SIMPLE" != true ]; then
    echo ""
    echo "Summary:"
    echo "  Removed: $removed"
    echo "  Active:  $skipped"
    echo "  Errors:  $errors"
fi
*** End File Creation
