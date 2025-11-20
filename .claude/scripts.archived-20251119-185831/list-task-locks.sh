#!/bin/bash
# List Task Locks
#
# Shows all active task locks with details
# Works from anywhere in the repo (main or worktree)
#
# Usage:
#   list-task-locks.sh           # Show all locks with details
#   list-task-locks.sh --simple  # Just show task IDs

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Parse arguments
SIMPLE_MODE=false
WATCH_MODE=false
REFRESH_SECONDS=2

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

Options:
  --simple           Only print task IDs
  --watch [seconds]  Continuously refresh (default 2s)
  -h, --help         Show this help
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --simple)
            SIMPLE_MODE=true
            shift ;;
        --watch)
            WATCH_MODE=true
            REFRESH_SECONDS=${2:-2}
            if [[ "$REFRESH_SECONDS" =~ ^[0-9]+$ ]]; then
                shift 2
            else
                REFRESH_SECONDS=2
                shift
            fi
            ;;
        -h|--help)
            usage
            exit 0 ;;
        --)
            shift
            break ;;
        *)
            echo "Unknown option: $1" >&2
            usage
            exit 1 ;;
    esac
done

run_once() {
    local simple=$1

    source ~/.claude/scripts/lib/get-project-lock-dir.sh
    local lock_dir
    lock_dir=$(get_project_lock_dir)

    if [ ! -d "$lock_dir" ]; then
        $simple || echo -e "${YELLOW}No task locks found (directory doesn't exist)${NC}"
        return
    fi

    # Shell-agnostic array population (works in bash and zsh)
    LOCKS=()
    while IFS= read -r line; do
        [ -n "$line" ] && LOCKS+=("$line")
    done <<< "$(find "$lock_dir" -name "*.lock" -type f 2>/dev/null | sort)"

    if [ ${#LOCKS[@]} -eq 0 ]; then
        if [ "$simple" = false ]; then
            echo -e "${GREEN}✅ No active task locks${NC}"
        fi
        return
    fi

    if [ "$simple" = true ]; then
        for lock_file in "${LOCKS[@]}"; do
            basename "$lock_file" .lock
        done
        return
    fi

    printf "${BLUE}%-12s %-18s %-10s %-10s %-22s %-22s${NC}\n" "Task" "Agent" "Status" "PID" "Locked" "Heartbeat"
    printf "${BLUE}%s${NC}\n" "---------------------------------------------------------------------------------------------------------"

    for lock_file in "${LOCKS[@]}"; do
        [ -f "$lock_file" ] || continue
        local data
        data=$(cat "$lock_file")
        local task_id agent status pid locked_at heartbeat branch
        task_id=$(echo "$data" | jq -r '.taskId // "unknown"')
        agent=$(echo "$data" | jq -r '.agentId // "unknown"')
        status=$(echo "$data" | jq -r '.status // "unknown"')
        pid=$(echo "$data" | jq -r '.pid // "-"')
        locked_at=$(echo "$data" | jq -r '.lockedAt // .timestamp // ""')
        heartbeat=$(echo "$data" | jq -r '.heartbeatAt // ""')
        branch=$(echo "$data" | jq -r '.branch // ""')

        local locked_age heartbeat_age
        locked_age=$(relative_time "$locked_at")
        heartbeat_age=$(relative_time "$heartbeat")

        local color=$YELLOW
        if [ "$heartbeat_age" != "?" ] && [[ $heartbeat_age =~ ^([0-9]+)m ]]; then
            local minutes=${BASH_REMATCH[1]}
            if [ "$minutes" -ge 15 ]; then
                color=$RED
            elif [ "$minutes" -ge 5 ]; then
                color=$YELLOW
            else
                color=$GREEN
            fi
        else
            color=$YELLOW
        fi

        printf "%b%-12s %-18s %-10s %-10s %-22s %-22s%b\n" "$color" "$task_id" "$agent" "$status" "$pid" "$locked_age" "$heartbeat_age" "$NC"
        if [ -n "$branch" ]; then
            echo "    Branch: $branch"
        fi
    done

    echo ""
    echo -e "${BLUE}Lock directory: $lock_dir${NC}"
    echo -e "${BLUE}Total locks: ${#LOCKS[@]}${NC}"
}

relative_time() {
    local ts=$1
    if [ -z "$ts" ] || [ "$ts" = "unknown" ]; then
        echo "?"
        return
    fi
    local ts_epoch
    ts_epoch=$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$ts" +%s 2>/dev/null || date -u +%s)
    local now
    now=$(date -u +%s)
    local diff=$((now - ts_epoch))
    if [ "$diff" -lt 0 ]; then diff=$(( -diff )); fi
    local mins=$((diff / 60))
    local secs=$((diff % 60))
    if [ "$mins" -gt 60 ]; then
        local hours=$((mins / 60))
        mins=$((mins % 60))
        printf "%dh%02dm" "$hours" "$mins"
    elif [ "$mins" -gt 0 ]; then
        printf "%dm%02ds" "$mins" "$secs"
    else
        printf "%ds" "$secs"
    fi
}

if [ "$WATCH_MODE" = true ]; then
    while true; do
        clear
        run_once false
        sleep "$REFRESH_SECONDS"
    done
else
    run_once "$SIMPLE_MODE"
fi
