#!/usr/bin/env bash
# TaskDock Locks Library
# Lock file management and utilities

# Source common library
# shellcheck source=./common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Source flock library for concurrency safety
# shellcheck source=./flock.sh
source "$(dirname "${BASH_SOURCE[0]}")/flock.sh"

# Get lock directory path
get_lock_dir() {
  local git_common_dir
  git_common_dir="$(git rev-parse --git-common-dir 2>/dev/null)"

  if [[ -n "$git_common_dir" ]]; then
    echo "$git_common_dir/taskdock-locks"
  else
    echo ""
  fi
}

# Ensure lock directory exists
ensure_lock_dir() {
  local lock_dir
  lock_dir="$(get_lock_dir)"

  if [[ -n "$lock_dir" ]] && [[ ! -d "$lock_dir" ]]; then
    mkdir -p "$lock_dir"
  fi
}

# Get lock file path for a task
get_lock_path() {
  local task_id="$1"
  local lock_dir
  lock_dir="$(get_lock_dir)"

  if [[ -n "$lock_dir" ]]; then
    echo "$lock_dir/${task_id}.lock"
  else
    echo ""
  fi
}

# Check if task is locked
is_task_locked() {
  local task_id="$1"
  local lock_path
  lock_path="$(get_lock_path "$task_id")"

  [[ -f "$lock_path" ]]
}

# Read lock file as JSON
read_lock() {
  local task_id="$1"
  local lock_path
  lock_path="$(get_lock_path "$task_id")"

  if [[ -f "$lock_path" ]]; then
    cat "$lock_path"
  else
    echo "{}"
  fi
}

# Get lock metadata field
get_lock_field() {
  local task_id="$1"
  local field="$2"
  local default="${3:-}"

  local lock_json
  lock_json="$(read_lock "$task_id")"

  echo "$lock_json" | jq -r ".${field} // \"${default}\""
}

# Update lock heartbeat
# Protected by flock to prevent concurrent updates
update_lock_heartbeat() {
  local task_id="$1"

  with_repo_flock "task-lock-${task_id}" _update_lock_heartbeat_impl "$task_id"
}

# Implementation of heartbeat update (called under flock protection)
_update_lock_heartbeat_impl() {
  local task_id="$1"
  local lock_path
  lock_path="$(get_lock_path "$task_id")"

  if [[ ! -f "$lock_path" ]]; then
    return 1
  fi

  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  local lock_json
  lock_json=$(cat "$lock_path")

  local updated
  updated=$(echo "$lock_json" | jq --arg ts "$timestamp" '.lastHeartbeat = $ts')

  echo "$updated" > "$lock_path"
}

# Get minutes since last heartbeat
minutes_since_heartbeat() {
  local task_id="$1"
  local last_heartbeat
  last_heartbeat="$(get_lock_field "$task_id" "lastHeartbeat")"

  if [[ -z "$last_heartbeat" ]] || [[ "$last_heartbeat" == "null" ]]; then
    echo "999999"
    return
  fi

  local now
  now=$(date -u +%s)

  local heartbeat_ts
  heartbeat_ts=$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_heartbeat" +%s 2>/dev/null || echo "0")

  local diff_seconds=$((now - heartbeat_ts))
  local diff_minutes=$((diff_seconds / 60))

  echo "$diff_minutes"
}

# List all locks as JSON array
list_locks() {
  local lock_dir
  lock_dir="$(get_lock_dir)"

  if [[ -z "$lock_dir" ]] || [[ ! -d "$lock_dir" ]]; then
    echo "[]"
    return
  fi

  local locks=()

  for lock_file in "$lock_dir"/*.lock; do
    if [[ -f "$lock_file" ]]; then
      locks+=("$(cat "$lock_file")")
    fi
  done

  if [[ ${#locks[@]} -eq 0 ]]; then
    echo "[]"
  else
    printf '%s\n' "${locks[@]}" | jq -s '.'
  fi
}

# Delete lock file
# Protected by flock to prevent race conditions
delete_lock() {
  local task_id="$1"

  with_repo_flock "task-lock-${task_id}" _delete_lock_impl "$task_id"
}

# Implementation of lock deletion (called under flock protection)
_delete_lock_impl() {
  local task_id="$1"
  local lock_path
  lock_path="$(get_lock_path "$task_id")"

  if [[ -f "$lock_path" ]]; then
    rm -f "$lock_path"
    return 0
  fi
  return 1
}
