#!/usr/bin/env bash
# TaskDock Common Library
# Shared shell safety flags, utilities, and constants

# Prevent double sourcing
if [[ -n "${TASKDOCK_COMMON_LOADED:-}" ]]; then
  return 0
fi
readonly TASKDOCK_COMMON_LOADED=1

set -euo pipefail

# TaskDock root directory
TASKDOCK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null && pwd)"

# Version
TASKDOCK_VERSION="$(cat "$TASKDOCK_ROOT/VERSION" 2>/dev/null || echo "unknown")"

# Exit codes
[[ -z "${EXIT_SUCCESS:-}" ]] && readonly EXIT_SUCCESS=0
readonly EXIT_CONFIG_MISSING=10
readonly EXIT_LOCK_BUSY=20
readonly EXIT_VALIDATION_FAILED=30
readonly EXIT_GIT_ERROR=40
readonly EXIT_DEPENDENCY_MISSING=50
readonly EXIT_INVALID_ARGS=60
readonly EXIT_LOCK_TIMEOUT=70
readonly EXIT_NOT_IN_REPO=80

# Constants
readonly TASKDOCK_USER_DIR="$HOME/.taskdock"
readonly TASKDOCK_USER_CONFIG="$TASKDOCK_USER_DIR/config.yaml"
readonly TASKDOCK_USER_LOGS="$TASKDOCK_USER_DIR/logs"

readonly TASKDOCK_REPO_DIR_NAME=".taskdock"
readonly TASKDOCK_REPO_CONFIG_NAME="config.yaml"
readonly TASKDOCK_REPO_LOGS_NAME="logs"

# Colors for terminal output
readonly COLOR_RESET='\033[0m'
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_CYAN='\033[0;36m'

# Emoji/symbols
readonly SYMBOL_SUCCESS="✅"
readonly SYMBOL_ERROR="⚠️"
readonly SYMBOL_INFO="ℹ️"
readonly SYMBOL_TIP="💡"

# Check if running in CI or non-interactive mode
is_ci() {
  [[ "${CI:-false}" == "true" ]] || [[ ! -t 1 ]]
}

# Get current repo root (if in a git repo)
get_repo_root() {
  git rev-parse --show-toplevel 2>/dev/null || echo ""
}

# Get main worktree root (works from any worktree)
get_main_worktree() {
  git worktree list 2>/dev/null | head -1 | awk '{print $1}' || get_repo_root
}

# Get repo name from git remote
get_repo_name() {
  local repo_root="${1:-$(get_repo_root)}"
  if [[ -n "$repo_root" ]]; then
    basename "$repo_root"
  else
    echo "unknown"
  fi
}

# Check if command exists
command_exists() {
  command -v "$1" &> /dev/null
}

# Generate correlation ID for tracking
generate_correlation_id() {
  local timestamp
  timestamp=$(date +%Y%m%d-%H%M%S)
  local random
  random=$(head -c 4 /dev/urandom | xxd -p)
  echo "TD-${timestamp}-${random}"
}

# Export correlation ID if not already set
ensure_correlation_id() {
  if [[ -z "${TASKDOCK_CORRELATION_ID:-}" ]]; then
    export TASKDOCK_CORRELATION_ID="$(generate_correlation_id)"
  fi
}

# Print version information
print_version() {
  echo "TaskDock v${TASKDOCK_VERSION}"
}
