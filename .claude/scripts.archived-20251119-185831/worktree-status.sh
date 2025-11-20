#!/bin/bash
# Worktree Status - Show all worktrees with lock information
# Location: ~/.claude/scripts/worktree-status.sh
# Works in ANY git repository

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

LOCK_DIR=".claude/state/task-locks"

echo -e "${BLUE}📊 Worktree Status${NC}"
echo ""

# Get main repo path (works from worktrees too)
MAIN_REPO=$(git rev-parse --show-superproject-working-tree 2>/dev/null)
if [ -z "$MAIN_REPO" ]; then
  MAIN_REPO=$(git rev-parse --show-toplevel)
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

# Function to get lock info
get_lock_info() {
    local task_id=$1
    local lock_file="${LOCK_DIR}/${task_id}.lock"

    if [ -f "$lock_file" ]; then
        local pid=$(grep '"pid"' "$lock_file" | sed 's/.*: \([0-9]*\).*/\1/')
        local agent=$(grep '"agentId"' "$lock_file" | sed 's/.*: "\(.*\)".*/\1/')
        local started=$(grep '"startedAt"' "$lock_file" | sed 's/.*: "\(.*\)".*/\1/')

        if is_process_running "$pid"; then
            echo -e "    ${GREEN}🔒 Locked${NC} by ${agent} (PID: ${pid})"
            echo -e "    ${CYAN}   Started: ${started}${NC}"
            return 0
        else
            echo -e "    ${YELLOW}🔓 Stale lock${NC} (dead PID: ${pid})"
            return 1
        fi
    else
        echo -e "    ${YELLOW}⚠️  No lock file${NC}"
        return 2
    fi
}

# Count worktrees
TOTAL_COUNT=0
LOCKED_COUNT=0
STALE_COUNT=0
UNLOCKED_COUNT=0

# List all worktrees
git worktree list --porcelain | while IFS= read -r line; do
    if [[ "$line" == worktree* ]]; then
        WORKTREE_PATH=$(echo "$line" | cut -d' ' -f2-)

        # Skip main repo
        if [ "$WORKTREE_PATH" = "$MAIN_REPO" ]; then
            continue
        fi

        TOTAL_COUNT=$((TOTAL_COUNT + 1))

        # Get branch
        read -r branch_line
        BRANCH=$(echo "$branch_line" | sed 's/branch refs\/heads\///')

        # Extract task ID from path (assumes ./worktrees/T0001/ structure)
        TASK_ID=$(basename "$WORKTREE_PATH")

        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${CYAN}Task:${NC} ${TASK_ID}"
        echo -e "${CYAN}Path:${NC} ${WORKTREE_PATH}"
        echo -e "${CYAN}Branch:${NC} ${BRANCH}"

        # Get lock status
        if get_lock_info "$TASK_ID"; then
            LOCKED_COUNT=$((LOCKED_COUNT + 1))
        elif [ $? -eq 1 ]; then
            STALE_COUNT=$((STALE_COUNT + 1))
        else
            UNLOCKED_COUNT=$((UNLOCKED_COUNT + 1))
        fi

        # Check if worktree directory exists
        if [ ! -d "$WORKTREE_PATH" ]; then
            echo -e "    ${RED}⚠️  Worktree directory missing${NC}"
        fi

        # Get commit count
        if [ -d "$WORKTREE_PATH" ]; then
            cd "$WORKTREE_PATH" || continue
            COMMIT_COUNT=$(git rev-list --count main..HEAD 2>/dev/null || echo "0")
            if [ "$COMMIT_COUNT" -gt 0 ]; then
                echo -e "    ${GREEN}📝 ${COMMIT_COUNT} commits${NC} on branch"

                # Show recent commits
                echo -e "    ${CYAN}Recent commits:${NC}"
                git log --oneline main..HEAD | head -n 3 | while IFS= read -r commit; do
                    echo -e "      ${commit}"
                done
            else
                echo -e "    ${YELLOW}📝 No commits yet${NC}"
            fi

            # Check for uncommitted changes
            if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
                echo -e "    ${YELLOW}⚠️  Uncommitted changes${NC}"
                git status --short | head -n 5 | while IFS= read -r status_line; do
                    echo -e "      ${status_line}"
                done
            fi

            cd - > /dev/null
        fi

        echo ""
    fi
done

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${CYAN}📊 Summary${NC}"
echo -e "  Total worktrees: ${TOTAL_COUNT}"
echo -e "  ${GREEN}Locked (active):${NC} ${LOCKED_COUNT}"
echo -e "  ${YELLOW}Stale locks:${NC} ${STALE_COUNT}"
echo -e "  ${YELLOW}Unlocked:${NC} ${UNLOCKED_COUNT}"
echo ""

# Show cleanup suggestions
if [ $STALE_COUNT -gt 0 ]; then
    echo -e "${YELLOW}💡 Cleanup suggestions:${NC}"
    echo -e "  Run: ~/.claude/scripts/clean-stale-locks.sh"
    echo ""
fi

# Show available commands
echo -e "${BLUE}📋 Available commands:${NC}"
echo -e "  ${CYAN}~/.claude/scripts/worktree-status.sh${NC}          - Show this status"
echo -e "  ${CYAN}~/.claude/scripts/clean-stale-locks.sh${NC}        - Clean stale locks"
echo -e "  ${CYAN}~/.claude/scripts/cleanup-merged-worktrees.sh${NC} - Clean merged worktrees"
echo -e "  ${CYAN}git worktree list${NC}                              - Git native list"
echo ""
