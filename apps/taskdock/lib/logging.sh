#!/usr/bin/env bash
# TaskDock Logging Library
# Structured telemetry with correlation IDs

# Source common library
# shellcheck source=./common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Source flock library for concurrency safety
# shellcheck source=./flock.sh
source "$(dirname "${BASH_SOURCE[0]}")/flock.sh"

# Logging configuration
TASKDOCK_LOG_DIR="${TASKDOCK_LOG_DIR:-$TASKDOCK_USER_LOGS}"
TASKDOCK_TELEMETRY_ENABLED="${TASKDOCK_TELEMETRY_ENABLED:-true}"

# Ensure log directory exists
ensure_log_dir() {
  local log_dir="$1"
  if [[ ! -d "$log_dir" ]]; then
    mkdir -p "$log_dir"
  fi
}

# Get repo-specific log directory
get_repo_log_dir() {
  local repo_root
  repo_root="$(get_repo_root)"
  if [[ -n "$repo_root" ]]; then
    echo "$repo_root/$TASKDOCK_REPO_DIR_NAME/$TASKDOCK_REPO_LOGS_NAME"
  else
    echo ""
  fi
}

# Write log entry (newline-delimited JSON)
log_entry() {
  [[ "$TASKDOCK_TELEMETRY_ENABLED" != "true" ]] && return 0

  local level="$1"
  local command="$2"
  local message="$3"
  local task_id="${4:-}"
  local extra="${5:-\{\}}"

  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  local repo_root
  repo_root="$(get_repo_root)"

  # Validate that extra is valid JSON
  if ! echo "$extra" | jq empty 2>/dev/null; then
    extra="{}"
  fi

  local log_entry
  log_entry=$(jq -cn \
    --arg ts "$timestamp" \
    --arg lvl "$level" \
    --arg corr "${TASKDOCK_CORRELATION_ID:-}" \
    --arg cmd "$command" \
    --arg msg "$message" \
    --arg task "$task_id" \
    --arg repo "$repo_root" \
    --argjson extra "$extra" \
    '{
      ts: $ts,
      level: $lvl,
      correlationId: $corr,
      command: $cmd,
      message: $msg,
      taskId: $task,
      repo: $repo,
      extra: $extra
    }')

  # Write to user log dir (protected by flock)
  ensure_log_dir "$TASKDOCK_LOG_DIR"
  with_flock "log-write" bash -c "echo '$log_entry' >> '$TASKDOCK_LOG_DIR/taskdock.log'"

  # Also write to repo-specific log if in a repo
  local repo_log_dir
  repo_log_dir="$(get_repo_log_dir)"
  if [[ -n "$repo_log_dir" ]]; then
    ensure_log_dir "$repo_log_dir"
    with_repo_flock "log-write" bash -c "echo '$log_entry' >> '$repo_log_dir/taskdock.log'"
  fi
}

# Log info level
log_info() {
  log_entry "info" "$@"
}

# Log warning level
log_warn() {
  log_entry "warn" "$@"
}

# Log error level
log_error() {
  log_entry "error" "$@"
}

# Log command start
log_command_start() {
  local command="$1"
  local task_id="${2:-}"
  log_info "$command" "Command started" "$task_id" '{}'
}

# Log command end
log_command_end() {
  local command="$1"
  local exit_code="$2"
  local task_id="${3:-}"
  local duration="${4:-0}"

  local extra
  extra=$(jq -n --argjson code "$exit_code" --argjson dur "$duration" '{exitCode: $code, durationMs: $dur}')

  if [[ "$exit_code" -eq 0 ]]; then
    log_info "$command" "Command completed successfully" "$task_id" "$extra"
  else
    log_error "$command" "Command failed" "$task_id" "$extra"
  fi
}

# Log task event
log_task_event() {
  local command="$1"
  local task_id="$2"
  local event="$3"
  local details="${4:-{}}"

  log_info "$command" "$event" "$task_id" "$details"
}
