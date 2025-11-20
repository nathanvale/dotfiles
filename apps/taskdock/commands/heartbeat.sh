#!/usr/bin/env bash
# TaskDock heartbeat - Update task lock heartbeat timestamp
# Used to keep locks alive during long-running operations

set -euo pipefail

# Source required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/ui.sh"
source "${SCRIPT_DIR}/lib/logging.sh"
source "${SCRIPT_DIR}/lib/locks.sh"

main() {
    local task_id="${1:-}"
    local quiet=false

    # Parse flags
    shift || true
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --quiet)
                quiet=true
                shift
                ;;
            *)
                error "Unknown option: $1"
                return "$EXIT_INVALID_ARGS"
                ;;
        esac
    done

    if [ -z "$task_id" ]; then
        error "Task ID required"
        tip "Usage: taskdock heartbeat <task-id> [--quiet]"
        return "$EXIT_INVALID_ARGS"
    fi

    if ! is_task_locked "$task_id"; then
        error "Task ${task_id} is not locked"
        return "$EXIT_LOCK_BUSY"
    fi

    # Update heartbeat
    update_lock_heartbeat "$task_id"

    [ "$quiet" = false ] && success "Heartbeat updated for task ${task_id}"

    if [ "${TASKDOCK_OUTPUT:-human}" = "json" ]; then
        json_success "Heartbeat updated" \
            "$(jq -n --arg taskId "$task_id" '{taskId: $taskId}')"
    fi

    return 0
}

main "$@"
