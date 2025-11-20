#!/usr/bin/env bash
# TaskDock File Locking Library
# Provides flock-based concurrency safety for critical sections

# Source common library
# shellcheck source=./common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Global lock directory
# Deprecated: Use repo-local locks instead
# TASKDOCK_LOCK_DIR="${TASKDOCK_LOCK_DIR:-$HOME/.taskdock/locks}"

# Ensure lock directory exists
ensure_flock_dir() {
  local lock_dir
  lock_dir="$(get_flock_base_dir)"
  if [[ ! -d "$lock_dir" ]]; then
    mkdir -p "$lock_dir"
  fi
}

# Get base lock directory (repo-local)
get_flock_base_dir() {
  local git_common_dir
  git_common_dir="$(git rev-parse --git-common-dir 2>/dev/null)"

  if [[ -z "$git_common_dir" ]]; then
    # Fallback to temp dir if not in a git repo (though this should be rare)
    echo "${TMPDIR:-/tmp}/taskdock-locks"
  else
    echo "$git_common_dir/taskdock-locks"
  fi
}

# Get lock file path for a resource
get_flock_path() {
  local resource="$1"
  ensure_flock_dir
  echo "$(get_flock_base_dir)/${resource}.flock"
}

# Acquire exclusive lock on a resource
# Usage: with_flock "resource-name" command [args...]
# Example: with_flock "task-selection" ./select-task.sh
with_flock() {
  # Default to 30s timeout
  with_flock_timeout 30 "$@"
}

# Acquire exclusive lock with custom timeout
# Usage: with_flock_timeout timeout "resource-name" command [args...]
with_flock_timeout() {
  local timeout="$1"
  local resource="$2"
  shift 2

  local lock_dir
  lock_dir="$(get_flock_path "$resource").lock"

  # Try to acquire lock with mkdir (atomic operation)
  local elapsed=0

  while ! mkdir "$lock_dir" 2>/dev/null; do
    if [[ $elapsed -ge $((timeout * 10)) ]]; then
      return "$EXIT_LOCK_TIMEOUT"
    fi
    sleep 0.1
    elapsed=$((elapsed + 1))
  done

  # Store PID in lock directory for debugging
  echo $$ > "$lock_dir/pid"

  # Execute command with lock held
  local exit_code=0
  "$@" || exit_code=$?

  # Release lock
  rm -rf "$lock_dir"

  return $exit_code
}

# Try to acquire lock without blocking
# Usage: try_flock "resource-name" command [args...]
# Returns EXIT_LOCK_BUSY if lock cannot be acquired immediately
try_flock() {
  local resource="$1"
  shift

  local lock_dir
  lock_dir="$(get_flock_path "$resource").lock"

  # Try to acquire lock (non-blocking)
  if ! mkdir "$lock_dir" 2>/dev/null; then
    return "$EXIT_LOCK_BUSY"
  fi

  # Store PID in lock directory for debugging
  echo $$ > "$lock_dir/pid"

  # Execute command with lock held
  local exit_code=0
  "$@" || exit_code=$?

  # Release lock
  rm -rf "$lock_dir"

  return $exit_code
}

# Clean up stale lock files (older than 1 hour)
cleanup_stale_flocks() {
  ensure_flock_dir
  local lock_dir
  lock_dir="$(get_flock_base_dir)"

  find "$lock_dir" -name "*.lock" -type d -mmin +60 -exec rm -rf {} + 2>/dev/null || true
}

# Get repo-specific flock path for shared git resources
# Alias for get_flock_path since all locks are now repo-local
get_repo_flock_path() {
  get_flock_path "$@"
}

# Acquire lock on repo-specific resource
# Alias for with_flock since all locks are now repo-local
with_repo_flock() {
  with_flock "$@"
}

# Function to run critical section with lock
# Usage: critical_section "lock-name" <<'EOF'
#   # your critical code here
# EOF
critical_section() {
  local lock_name="$1"
  local code

  # Read code from stdin
  code=$(cat)

  with_flock "$lock_name" bash -c "$code"
}
