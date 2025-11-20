#!/usr/bin/env bash
# Generate next sequential task ID with atomic counter
# Usage: next-task-id.sh [prefix]
# Output: MPCU-001, MPCU-002, etc.

set -euo pipefail

# Parse arguments
PREFIX="${1:-}"

# Load project prefix from config if not provided
if [ -z "$PREFIX" ]; then
  # Try project-level config first
  MAIN_REPO=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
  if [ -n "$MAIN_REPO" ] && [ -f "$MAIN_REPO/.claude/config.json" ] && command -v jq &> /dev/null; then
    PREFIX=$(jq -r '.projectPrefix // empty' "$MAIN_REPO/.claude/config.json" 2>/dev/null || echo "")
  fi

  # Fallback to global config
  if [ -z "$PREFIX" ]; then
    CONFIG_FILE="$HOME/.claude/config.json"
    if [ -f "$CONFIG_FILE" ] && command -v jq &> /dev/null; then
      PREFIX=$(jq -r '.projectPrefix // "MPCU"' "$CONFIG_FILE" 2>/dev/null || echo "MPCU")
    else
      PREFIX="MPCU"
    fi
  fi
fi

# Get project lock directory
source ~/.claude/scripts/lib/get-project-lock-dir.sh
PROJECT_DIR=$(dirname "$(get_project_lock_dir)")

# Create state directory
mkdir -p "$PROJECT_DIR/state"
mkdir -p "$PROJECT_DIR/locks"

# Counter and lock paths
SEQ_FILE="$PROJECT_DIR/state/tasks.seq"
LOCK_DIR="$PROJECT_DIR/locks/task.lock"

# Acquire lock with retry
MAX_RETRIES=10
for i in $(seq 1 $MAX_RETRIES); do
  if mkdir "$LOCK_DIR" 2>/dev/null; then
    # Lock acquired - ensure cleanup on exit
    trap "rmdir '$LOCK_DIR' 2>/dev/null || true" EXIT INT TERM

    # Read current counter (default to 0 if missing)
    if [ -f "$SEQ_FILE" ]; then
      LAST_SEQ=$(cat "$SEQ_FILE" 2>/dev/null || echo "0")
      # Validate it's a number
      if ! [[ "$LAST_SEQ" =~ ^[0-9]+$ ]]; then
        echo "❌ ERROR: Counter file corrupted: $SEQ_FILE" >&2
        echo "   Contains: '$LAST_SEQ'" >&2
        echo "   Fix: rm '$SEQ_FILE' && echo '0' > '$SEQ_FILE'" >&2
        exit 1
      fi
    else
      LAST_SEQ=0
    fi

    # Increment
    NEXT_SEQ=$((LAST_SEQ + 1))
    echo "$NEXT_SEQ" > "$SEQ_FILE"

    # Format ID with 4-digit padding (0001-9999)
    NNN=$(printf "%04d" $NEXT_SEQ)

    TASK_ID="${PREFIX}-${NNN}"

    # Output ID
    echo "$TASK_ID"
    exit 0
  fi

  # Lock contention - retry with jitter
  if [ $i -lt $MAX_RETRIES ]; then
    JITTER=$((RANDOM % 40 + 10))  # 10-50ms
    sleep "0.0${JITTER}" 2>/dev/null || sleep 0.05  # Fallback for systems without sub-second sleep
  fi
done

# Failed to acquire lock
echo "❌ ERROR: Failed to acquire lock after $MAX_RETRIES retries" >&2
echo "   Lock file: $LOCK_DIR" >&2
echo "   If you're sure no other process is running, remove it:" >&2
echo "   rmdir '$LOCK_DIR'" >&2
exit 1
