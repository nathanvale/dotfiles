#!/usr/bin/env bash
# TaskDock Task Selector
# Find and lock the highest priority READY task

# This file is meant to be sourced, not executed directly

# Source flock library for concurrency safety
TASKDOCK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$TASKDOCK_ROOT/lib/flock.sh"

# Get timestamp in UTC
timestamp_utc() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Get agent ID
get_agent_id() {
  echo "${TASKDOCK_AGENT_ID:-${USER}-$$}"
}

# Parse priority from task frontmatter
get_task_priority() {
  local file="$1"
  grep '^priority:' "$file" 2>/dev/null | sed 's/priority: *//' | tr -d '[:space:]' || echo "P3"
}

# Convert priority to numeric for sorting (P0=0, P1=1, P2=2, P3=3)
priority_to_num() {
  local p="$1"
  echo "$p" | sed 's/P//'
}

# Check if status is completed
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
check_task_dependencies() {
  local file="$1"
  local task_dir="$2"

  local deps_raw
  deps_raw=$(grep '^depends_on:' "$file" 2>/dev/null | sed 's/depends_on: *//' || echo "")
  local deps
  deps=$(echo "$deps_raw" | tr -d '[]"' | tr ',' ' ' | xargs)

  if [[ -z "$deps" ]]; then
    return 0  # No dependencies
  fi

  # Check each dependency
  for dep_id in $deps; do
    dep_id=$(echo "$dep_id" | tr -d '[:space:]')

    # Find dependency task file
    local dep_file
    dep_file=$(find "$task_dir" -maxdepth 1 -type f -name "${dep_id}-*.md" 2>/dev/null | head -1)

    if [[ -z "$dep_file" ]]; then
      return 1  # Dependency not found
    fi

    # Check if dependency is completed
    local dep_status
    dep_status=$(grep '^status:' "$dep_file" 2>/dev/null | sed 's/status: *//' | tr -d '[:space:]' || echo "")

    if ! is_completed_status "$dep_status"; then
      return 1  # Dependency not completed
    fi
  done

  return 0  # All dependencies met
}

# Try to create lock atomically
# Protected by flock to prevent race conditions
try_create_task_lock() {
  local task_id="$1"

  ensure_lock_dir
  local lock_path
  lock_path="$(get_lock_path "$task_id")"

  # Use flock to protect this critical section
  # This ensures only one agent can check/create the lock at a time
  with_repo_flock "task-lock-${task_id}" _try_create_task_lock_impl "$task_id" "$lock_path"
}

# Implementation of lock creation (called under flock protection)
_try_create_task_lock_impl() {
  local task_id="$1"
  local lock_path="$2"

  # Quick gate - check if already locked
  if [[ -f "$lock_path" ]]; then
    return 1
  fi

  local tmp_file
  tmp_file=$(mktemp "$(dirname "$lock_path")/.${task_id}.lock.XXXXXX")

  local now
  now=$(timestamp_utc)

  local agent_id
  agent_id=$(get_agent_id)

  jq -n \
    --arg taskId "$task_id" \
    --argjson pid "$$" \
    --arg agentId "$agent_id" \
    --arg hostname "$(hostname)" \
    --arg lockedAt "$now" \
    --arg lastHeartbeat "$now" \
    --arg correlationId "${TASKDOCK_CORRELATION_ID:-}" \
    '{
      taskId: $taskId,
      pid: $pid,
      agentId: $agentId,
      hostname: $hostname,
      lockedAt: $lockedAt,
      lastHeartbeat: $lastHeartbeat,
      correlationId: $correlationId,
      status: "LOCKED"
    }' > "$tmp_file"

  # Move temp file to final location (atomic within flock)
  mv "$tmp_file" "$lock_path" 2>/dev/null || {
    rm -f "$tmp_file"
    return 1
  }

  return 0
}

# Select and lock next task
# Returns JSON with task info or empty object
select_and_lock_task() {
  local task_dir="$1"
  local ticket_prefix="$2"

  # Build list of READY tasks with priorities
  local task_list=()

  while IFS= read -r task_file; do
    [[ -f "$task_file" ]] || continue

    # Extract task ID
    local task_id
    task_id=$(basename "$task_file" .md | sed 's/^\([A-Z][A-Z0-9-]*[0-9]\)-.*/\1/')

    # Check status
    local status
    status=$(grep '^status:' "$task_file" 2>/dev/null | sed 's/status: *//' | tr -d '[:space:]' || echo "")

    if [[ "$status" != "READY" ]]; then
      continue
    fi

    # Check dependencies
    if ! check_task_dependencies "$task_file" "$task_dir"; then
      continue
    fi

    # Get priority
    local priority
    priority=$(get_task_priority "$task_file")
    local priority_num
    priority_num=$(priority_to_num "$priority")

    # Add to list: "priority_num|task_id|task_file|priority"
    task_list+=("${priority_num}|${task_id}|${task_file}|${priority}")

  done < <(find "$task_dir" -maxdepth 1 -type f -name "*.md" ! -name "README.md" 2>/dev/null)

  # Check if any tasks found
  if [[ ${#task_list[@]} -eq 0 ]]; then
    echo "{}"
    return 1
  fi

  # Sort by priority (numeric), then by task ID
  local sorted_tasks
  IFS=$'\n' sorted_tasks=($(printf '%s\n' "${task_list[@]}" | sort -t'|' -k1,1n -k2,2))

  # Try each task in priority order until we successfully lock one
  for task_entry in "${sorted_tasks[@]}"; do
    IFS='|' read -r _ task_id task_file priority <<< "$task_entry"

    # Try to lock this task atomically
    if try_create_task_lock "$task_id"; then
      # Successfully locked! Return this task
      local task_title
      task_title=$(grep '^title:' "$task_file" 2>/dev/null | sed 's/title: *//' || echo "")

      local repo_root
      repo_root="$(get_repo_root)"

      local lock_path
      lock_path="$(get_lock_path "$task_id")"

      jq -n \
        --arg taskId "$task_id" \
        --arg filePath "$task_file" \
        --arg priority "$priority" \
        --arg status "READY" \
        --arg lockFile "$lock_path" \
        --arg title "$task_title" \
        --arg taskDir "$task_dir" \
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

      return 0
    fi

    # Lock failed - task is locked by another agent, try next task
  done

  # All tasks are locked
  echo "{}"
  return 1
}
