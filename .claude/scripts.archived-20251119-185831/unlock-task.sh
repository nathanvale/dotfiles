#!/bin/bash
# Unlock Task
#
# Removes lock file for a task ID.
# Use when abandoning work on a task without merging.
#
# Usage:
#   unlock-task.sh TASK_ID
#   unlock-task.sh MPCU-0008
#
# Returns:
#   Exit 0 on success, 1 on failure

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check argument
if [ -z "${1:-}" ]; then
    echo -e "${RED}❌ Usage: unlock-task.sh TASK_ID${NC}"
    echo "Example: unlock-task.sh MPCU-0008"
    exit 1
fi

TASK_ID="$1"

# Import lock directory helper
source ~/.claude/scripts/lib/get-project-lock-dir.sh
LOCK_DIR=$(get_project_lock_dir)

LOCK_FILE="${LOCK_DIR}/${TASK_ID}.lock"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔓 Unlocking Task: $TASK_ID${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ ! -f "$LOCK_FILE" ]; then
    echo -e "${YELLOW}ℹ️  Task $TASK_ID is not locked${NC}"
    exit 0
fi

# Show lock info before removing
echo -e "Lock file: ${YELLOW}$LOCK_FILE${NC}"
cat "$LOCK_FILE" 2>/dev/null || true
echo ""

# Remove lock
rm "$LOCK_FILE"
echo -e "${GREEN}✅ Task $TASK_ID unlocked${NC}"
echo ""
echo -e "${YELLOW}Note: This only removes the lock. You may still need to:${NC}"
echo -e "  - Remove worktree: git worktree remove <path>"
echo -e "  - Delete branch: git branch -D <branch-name>"
echo -e "  - Close PR (if created)"
echo ""

exit 0
