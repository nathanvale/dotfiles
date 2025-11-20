#!/usr/bin/env bash
# TaskDock Next Command
# Select and lock the next available task

set -euo pipefail

TASKDOCK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null && pwd)"
source "$TASKDOCK_ROOT/lib/common.sh"
source "$TASKDOCK_ROOT/lib/ui.sh"
source "$TASKDOCK_ROOT/lib/config.sh"
source "$TASKDOCK_ROOT/lib/git.sh"
source "$TASKDOCK_ROOT/lib/locks.sh"
source "$TASKDOCK_ROOT/lib/logging.sh"

show_help() {
  print_help_header "taskdock next" "Select and lock the next available task"

  print_usage "taskdock next [options]"

  print_options "$(cat <<'EOF'
--json|Output in JSON format
--cleanup-stale|Clean stale locks first (default: true)
--max-age <minutes>|Max lock age before stale (default: 30)
--help, -h|Show this help
EOF
)"

  print_examples "$(cat <<'EOF'
  taskdock next
  taskdock next --json
  taskdock next --cleanup-stale --max-age 45
EOF
)"
}

# Parse arguments
CLEANUP_STALE=true
MAX_AGE_MINUTES=30

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-cleanup-stale)
      CLEANUP_STALE=false
      shift
      ;;
    --max-age)
      MAX_AGE_MINUTES="$2"
      shift 2
      ;;
    --help|-h)
      show_help
      exit 0
      ;;
    *)
      shift
      ;;
  esac
done

# Cleanup stale locks first
if [[ "$CLEANUP_STALE" == "true" ]]; then
  "$TASKDOCK_ROOT/commands/locks.sh" cleanup --max-age "$MAX_AGE_MINUTES" --quiet >/dev/null 2>&1 || true
fi

# Get task directory from config
REPO_ROOT="$(get_repo_root)"
TASK_DIR_CONFIG="$(taskdock_config "task_directory" "docs/tasks")"
TASK_DIR="$REPO_ROOT/$TASK_DIR_CONFIG"

if [[ ! -d "$TASK_DIR" ]]; then
  error "Task directory not found: $TASK_DIR"
  tip "Check your config: taskdock config get task_directory"

  if [[ "${TASKDOCK_OUTPUT:-human}" == "json" ]]; then
    json_response "$(json_error "Task directory not found" "$EXIT_CONFIG_MISSING" '["taskdock config set task_directory docs/tasks"]')"
  fi

  exit "$EXIT_CONFIG_MISSING"
fi

# Get ticket prefix
TICKET_PREFIX="$(taskdock_config "ticket_prefix")"

# Source task selection logic
source "$TASKDOCK_ROOT/tasks/selector.sh"

# Find next available task
SELECTED_TASK=$(select_and_lock_task "$TASK_DIR" "$TICKET_PREFIX")

if [[ -z "$SELECTED_TASK" ]] || [[ "$SELECTED_TASK" == "{}" ]]; then
  if [[ "${TASKDOCK_OUTPUT:-human}" == "json" ]]; then
    echo "{}"
  else
    warn "No READY tasks available"
    tip "Check task status: ls -l $TASK_DIR"
  fi

  log_info "next" "No tasks available" "" "{}"
  exit 0
fi

# Parse selected task
TASK_ID=$(echo "$SELECTED_TASK" | jq -r '.taskId')
TASK_FILE=$(echo "$SELECTED_TASK" | jq -r '.filePath')
PRIORITY=$(echo "$SELECTED_TASK" | jq -r '.priority')
TITLE=$(echo "$SELECTED_TASK" | jq -r '.title')

# Log event
log_task_event "next" "$TASK_ID" "Task selected and locked" "$(echo "$SELECTED_TASK" | jq -c '{priority, title}')"

# Output
if [[ "${TASKDOCK_OUTPUT:-human}" == "json" ]]; then
  echo "$SELECTED_TASK" | jq '.'
else
  echo ""
  success "Task selected and locked!"
  echo ""
  info "Task ID: $TASK_ID"
  info "Priority: $PRIORITY"
  info "Title: $TITLE"
  info "File: $TASK_FILE"
  echo ""
  tip "Next steps:"
  echo "  1. taskdock worktree create $TASK_ID"
  echo "  2. cd .worktrees/$TASK_ID"
  echo "  3. Start working on the task"
  echo ""
fi

exit 0
