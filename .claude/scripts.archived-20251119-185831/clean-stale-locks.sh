#!/bin/bash
# Clean Stale Locks - Remove lock files for dead processes
# Location: ~/.claude/scripts/clean-stale-locks.sh
# Works in ANY git repository

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get centralized lock directory (worktree-safe)
source ~/.claude/scripts/lib/get-project-lock-dir.sh
LOCK_DIR=$(get_project_lock_dir)

echo -e "${BLUE}🧹 Cleaning stale locks...${NC}"
echo -e "${BLUE}Lock directory: $LOCK_DIR${NC}"
echo ""

if [ ! -d "$LOCK_DIR" ]; then
    echo -e "${YELLOW}No lock directory found${NC}"
    exit 0
fi

# Function to check if process is running
is_process_running() {
    local pid=$1
    if ps -p "$pid" > /dev/null 2>&1; then
        return 0  # Running
    else
        return 1  # Not running
    fi
}

CLEANED=0
ACTIVE=0
FAILED=0

# Check each lock file
for lock_file in "$LOCK_DIR"/*.lock; do
    # Skip if no lock files
    if [ ! -f "$lock_file" ]; then
        continue
    fi

    TASK_ID=$(basename "$lock_file" .lock)

    # Extract PID from lock file
    PID=$(grep '"pid"' "$lock_file" | sed 's/.*: \([0-9]*\).*/\1/' 2>/dev/null)
    AGENT=$(grep '"agentId"' "$lock_file" | sed 's/.*: "\(.*\)".*/\1/' 2>/dev/null)

    if [ -z "$PID" ]; then
        echo -e "${RED}⚠️  ${TASK_ID}: Invalid lock file (no PID)${NC}"
        FAILED=$((FAILED + 1))
        continue
    fi

    # Check if process is running
    if is_process_running "$PID"; then
        echo -e "${GREEN}✓ ${TASK_ID}: Active${NC} (${AGENT}, PID: ${PID})"
        ACTIVE=$((ACTIVE + 1))
    else
        echo -e "${YELLOW}🧹 ${TASK_ID}: Cleaning stale lock${NC} (dead PID: ${PID})"
        rm -f "$lock_file"
        CLEANED=$((CLEANED + 1))
    fi
done

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Cleanup complete${NC}"
echo ""
echo -e "📊 Summary:"
echo -e "  ${GREEN}Active locks:${NC} ${ACTIVE}"
echo -e "  ${YELLOW}Cleaned:${NC} ${CLEANED}"
if [ $FAILED -gt 0 ]; then
    echo -e "  ${RED}Failed:${NC} ${FAILED}"
fi
echo ""

if [ $CLEANED -eq 0 ] && [ $ACTIVE -eq 0 ] && [ $FAILED -eq 0 ]; then
    echo -e "${BLUE}No locks found${NC}"
    echo ""
fi
