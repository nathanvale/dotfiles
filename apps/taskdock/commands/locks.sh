#!/usr/bin/env bash
# TaskDock Locks Command
# Manage task locks

set -euo pipefail

TASKDOCK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null && pwd)"
source "$TASKDOCK_ROOT/lib/common.sh"
source "$TASKDOCK_ROOT/lib/ui.sh"
source "$TASKDOCK_ROOT/lib/config.sh"
source "$TASKDOCK_ROOT/lib/git.sh"
source "$TASKDOCK_ROOT/lib/locks.sh"
source "$TASKDOCK_ROOT/lib/logging.sh"

show_help() {
  print_help_header "taskdock locks" "Manage task locks"

  print_usage "taskdock locks <subcommand> [options]"

  cat << EOF
Subcommands:
  list              List all active locks
  unlock <task-id>  Unlock a specific task
  cleanup           Remove stale locks

Options:
  --json            Output in JSON format
  --help, -h        Show this help

Examples:
  taskdock locks list
  taskdock locks unlock MPCU-0017
  taskdock locks cleanup --max-age 30
EOF
}

# Subcommand: list
cmd_list() {
  if [[ "${1:-}" == "--json" ]]; then
    TASKDOCK_OUTPUT="json"
  fi

  local locks_json
  locks_json="$(list_locks)"

  if [[ "${TASKDOCK_OUTPUT:-human}" == "json" ]]; then
    echo "$locks_json" | jq '.'
  else
    local lock_count
    lock_count=$(echo "$locks_json" | jq 'length')

    if [[ "$lock_count" -eq 0 ]]; then
      info "No active locks"
      exit 0
    fi

    echo ""
    info "Active Locks ($lock_count)"
    echo ""

    echo "$locks_json" | jq -r '.[] | "  \(.taskId) | \(.agentId) | \(.lockedAt)"' | while read -r line; do
      echo "$line"
    done
    echo ""
  fi
}

# Subcommand: unlock
cmd_unlock() {
  local task_id="$1"

  if ! is_task_locked "$task_id"; then
    warn "Task $task_id is not locked"
    exit 0
  fi

  if delete_lock "$task_id"; then
    success "Unlocked task: $task_id"
    log_task_event "locks" "$task_id" "Task unlocked manually" "{}"

    if [[ "${TASKDOCK_OUTPUT:-human}" == "json" ]]; then
      jq -n --arg taskId "$task_id" '{taskId: $taskId, unlocked: true}'
    fi
  else
    error "Failed to unlock task: $task_id"
    exit 1
  fi
}

# Subcommand: cleanup
cmd_cleanup() {
  local max_age="${1:-30}"
  local quiet="${2:-false}"

  local lock_dir
  lock_dir="$(get_lock_dir)"

  if [[ -z "$lock_dir" ]] || [[ ! -d "$lock_dir" ]]; then
    [[ "$quiet" != "true" ]] && info "No lock directory found"
    exit 0
  fi

  local removed=0

  for lock_file in "$lock_dir"/*.lock; do
    [[ -f "$lock_file" ]] || continue

    local task_id
    task_id=$(basename "$lock_file" .lock)

    local minutes_since
    minutes_since=$(minutes_since_heartbeat "$task_id")

    if [[ "$minutes_since" -ge "$max_age" ]]; then
      if delete_lock "$task_id"; then
        ((removed++)) || true
        [[ "$quiet" != "true" ]] && info "Removed stale lock: $task_id (${minutes_since}m old)"
        log_task_event "locks" "$task_id" "Stale lock removed" "$(jq -n --argjson age "$minutes_since" '{ageMinutes: $age}')"
      fi
    fi
  done

  if [[ "$quiet" != "true" ]]; then
    if [[ "$removed" -eq 0 ]]; then
      success "No stale locks found"
    else
      success "Removed $removed stale lock(s)"
    fi
  fi

  if [[ "${TASKDOCK_OUTPUT:-human}" == "json" ]]; then
    jq -n --argjson removed "$removed" '{removed: $removed}'
  fi
}

# Parse arguments
SUBCOMMAND="${1:-}"

if [[ -z "$SUBCOMMAND" ]] || [[ "$SUBCOMMAND" == "--help" ]] || [[ "$SUBCOMMAND" == "-h" ]]; then
  show_help
  exit 0
fi

shift || true

case "$SUBCOMMAND" in
  list)
    cmd_list "$@"
    ;;
  unlock)
    if [[ $# -lt 1 ]]; then
      error "Missing task ID"
      tip "Usage: taskdock locks unlock <task-id>"
      exit "$EXIT_INVALID_ARGS"
    fi
    cmd_unlock "$@"
    ;;
  cleanup)
    # Parse cleanup options
    MAX_AGE=30
    QUIET=false
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --max-age)
          MAX_AGE="$2"
          shift 2
          ;;
        --quiet)
          QUIET=true
          shift
          ;;
        *)
          shift
          ;;
      esac
    done
    cmd_cleanup "$MAX_AGE" "$QUIET"
    ;;
  *)
    error "Unknown subcommand: $SUBCOMMAND"
    tip "Run 'taskdock locks --help' to see available subcommands"
    exit "$EXIT_INVALID_ARGS"
    ;;
esac
