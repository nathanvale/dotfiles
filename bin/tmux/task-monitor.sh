#!/bin/bash
# Task Monitor Dashboard
#
# Real-time monitoring of parallel Claude agents and their tasks.
# Shows active locks, PIDs, worktrees, and task status.
#
# Usage:
#   task-monitor.sh [REFRESH_INTERVAL]
#
# Arguments:
#   REFRESH_INTERVAL - Seconds between updates (default: 2)
#
# Features:
#   - Shows all active task locks with PID status
#   - Displays git worktrees and their status
#   - Color-coded status indicators (alive/dead PIDs)
#   - Auto-refreshes for real-time updates
#   - Works from any directory (auto-detects git root)
#
# Integration:
#   - Bind to Ctrl-g m in tmux.conf for quick access
#   - Use in split pane while parallel agents run
#   - Press Ctrl-C to exit

set -e

# ============================================================================
# CONFIGURATION
# ============================================================================

REFRESH_INTERVAL="${1:-2}"
LOCK_DIR=".claude/state/task-locks"

# Color codes (ANSI)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Detect git repository root (worktree-safe)
get_git_root() {
    local git_root
    git_root=$(git rev-parse --show-superproject-working-tree 2>/dev/null)
    if [ -z "$git_root" ]; then
        git_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
    fi
    echo "$git_root"
}

# Check if process is running
is_process_running() {
    local pid=$1
    if kill -0 "$pid" 2>/dev/null; then
        return 0  # Running
    else
        return 1  # Not running
    fi
}

# Get task status from lock file
get_lock_info() {
    local lock_file=$1

    if [ ! -f "$lock_file" ]; then
        return 1
    fi

    # Extract fields from JSON lock file
    local task_id
    task_id=$(grep '"taskId"' "$lock_file" | sed 's/.*: "\([^"]*\)".*/\1/' 2>/dev/null || echo "unknown")
    local pid
    pid=$(grep '"pid"' "$lock_file" | sed 's/.*: \([0-9]*\).*/\1/' 2>/dev/null || echo "")
    local agent_id
    agent_id=$(grep '"agentId"' "$lock_file" | sed 's/.*: "\([^"]*\)".*/\1/' 2>/dev/null || echo "unknown")

    echo "$task_id|$pid|$agent_id"
}

# Get worktree status
get_worktree_info() {
    git worktree list --porcelain | awk '
        /^worktree/ { path=$2 }
        /^branch/ { branch=$2; sub(/.*\//, "", branch) }
        /^$/ { if (path && branch) print path "|" branch; path=""; branch="" }
    '
}

# Clear screen and show header
show_header() {
    clear
    cat <<EOF
${BOLD}${CYAN}╔════════════════════════════════════════════════════════════════╗
║         🔍 Claude Agent Task Monitor                          ║
╚════════════════════════════════════════════════════════════════╝${RESET}

${YELLOW}Refresh: ${REFRESH_INTERVAL}s | Press Ctrl-C to exit${RESET}
Updated: $(date '+%Y-%m-%d %H:%M:%S')

EOF
}

# Display active locks section
show_active_locks() {
    echo -e "${BOLD}${BLUE}📋 Active Task Locks:${RESET}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Resolve taskdock binary
    local taskdock_cmd="taskdock"
    local script_dir
    script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
    local repo_root
    repo_root=$(cd "$script_dir/../.." && pwd)

    if [ -x "$repo_root/apps/taskdock/bin/taskdock" ]; then
        taskdock_cmd="$repo_root/apps/taskdock/bin/taskdock"
    fi

    if ! command -v "$taskdock_cmd" &> /dev/null && [ ! -x "$taskdock_cmd" ]; then
        echo -e "${YELLOW}  taskdock CLI not found${RESET}"
        echo
        return
    fi

    local locks_json
    locks_json=$("$taskdock_cmd" locks list --json 2>/dev/null || echo "[]")

    if [ "$locks_json" == "[]" ] || [ -z "$locks_json" ]; then
        echo -e "${YELLOW}  No active locks${RESET}"
        echo
        return
    fi

    printf "  %-15s %-10s %-20s %-10s\n" "TASK" "PID" "AGENT" "STATUS"
    printf "  %-15s %-10s %-20s %-10s\n" "────" "───" "─────" "──────"

    echo "$locks_json" | jq -r '.[] | "\(.taskId)|\(.pid // "")|\(.agentId)"' | while IFS='|' read -r task_id pid agent_id; do
        local status_color=$RED
        local status_text="DEAD"

        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            status_color=$GREEN
            status_text="ALIVE"
        elif [ -z "$pid" ]; then
             status_color=$YELLOW
             status_text="UNKNOWN"
        fi

        printf "  %-15s %-10s %-20s ${status_color}%-10s${RESET}\n" \
            "$task_id" "$pid" "$agent_id" "$status_text"
    done

    echo
}

# Display worktrees section
show_worktrees() {
    echo -e "${BOLD}${BLUE}🌳 Git Worktrees:${RESET}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    local worktrees
    worktrees=$(get_worktree_info)

    if [ -z "$worktrees" ]; then
        echo -e "${YELLOW}  No worktrees found${RESET}"
        echo
        return
    fi

    printf "  %-50s %-15s\n" "PATH" "BRANCH"
    printf "  %-50s %-15s\n" "────" "──────"

    while IFS='|' read -r path branch; do
        # Skip main worktree (usually the repo root)
        if [[ "$path" == *"/worktrees/"* ]] || [[ "$branch" =~ ^T[0-9]{4} ]]; then
            # Highlight task branches
            if [[ "$branch" =~ ^T[0-9]{4} ]]; then
                printf "  ${GREEN}%-50s %-15s${RESET}\n" "$path" "$branch"
            else
                printf "  %-50s %-15s\n" "$path" "$branch"
            fi
        fi
    done <<< "$worktrees"

    echo
}

# Display task directory status
show_task_stats() {
    local git_root=$1

    echo -e "${BOLD}${BLUE}📊 Task Statistics:${RESET}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Auto-detect task directory
    local task_dir=""
    if [ -d "$git_root/apps/migration-cli/docs/tasks" ]; then
        task_dir="$git_root/apps/migration-cli/docs/tasks"
    elif [ -d "$git_root/docs/tasks" ]; then
        task_dir="$git_root/docs/tasks"
    elif [ -d "$git_root/tasks" ]; then
        task_dir="$git_root/tasks"
    elif [ -d "$git_root/.tasks" ]; then
        task_dir="$git_root/.tasks"
    fi

    if [ -z "$task_dir" ] || [ ! -d "$task_dir" ]; then
        echo -e "${YELLOW}  No task directory found${RESET}"
        echo
        return
    fi

    # Count tasks by status
    local ready
    ready=$(find "$task_dir" -name "T[0-9][0-9][0-9][0-9]-*.md" -type f -exec grep -l "^status: READY" {} \; | wc -l | xargs)
    local in_progress
    in_progress=$(find "$task_dir" -name "T[0-9][0-9][0-9][0-9]-*.md" -type f -exec grep -l "^status: IN_PROGRESS" {} \; | wc -l | xargs)
    local completed
    completed=$(find "$task_dir" -name "T[0-9][0-9][0-9][0-9]-*.md" -type f -exec grep -l "^status: COMPLETED" {} \; | wc -l | xargs)
    local blocked
    blocked=$(find "$task_dir" -name "T[0-9][0-9][0-9][0-9]-*.md" -type f -exec grep -l "^status: BLOCKED" {} \; | wc -l | xargs)

    printf "  %-20s ${GREEN}%s${RESET}\n" "Ready:" "$ready"
    printf "  %-20s ${YELLOW}%s${RESET}\n" "In Progress:" "$in_progress"
    printf "  %-20s ${BLUE}%s${RESET}\n" "Completed:" "$completed"
    printf "  %-20s ${RED}%s${RESET}\n" "Blocked:" "$blocked"

    echo
}

# Main monitoring loop
monitor_loop() {
    local git_root
    git_root=$(get_git_root)

    while true; do
        show_header
        show_active_locks
        show_worktrees
        show_task_stats "$git_root"

        echo -e "${YELLOW}Refreshing in ${REFRESH_INTERVAL}s...${RESET}"

        sleep "$REFRESH_INTERVAL"
    done
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

# Validate refresh interval
if ! [[ "$REFRESH_INTERVAL" =~ ^[0-9]+$ ]] || [ "$REFRESH_INTERVAL" -lt 1 ]; then
    echo "Error: REFRESH_INTERVAL must be a positive integer" >&2
    exit 1
fi

# Run monitoring loop
monitor_loop
