#!/bin/bash
# Cleanup worktrees for merged PRs
#
# This script:
# 1. Finds all worktrees with branches merged into main
# 2. Removes lock files for merged tasks
# 3. Removes the worktree directories
# 4. Deletes the merged branches
# 5. Prunes stale worktree metadata
#
# Usage:
#   ./scripts/cleanup-merged-worktrees.sh
#
# Or as a git alias:
#   git config alias.cleanup-worktrees '!bash scripts/cleanup-merged-worktrees.sh'
#   git cleanup-worktrees

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧹 Cleaning up merged worktrees...${NC}"
echo ""

# Update refs from remote
echo -e "${BLUE}📡 Fetching latest changes from remote...${NC}"
git fetch --all --prune

# Track cleanup statistics
CLEANED_COUNT=0
KEPT_COUNT=0
FAILED_COUNT=0

# Get the main repo path to skip it (works from worktrees too)
MAIN_REPO=$(git rev-parse --show-superproject-working-tree 2>/dev/null)
if [ -z "$MAIN_REPO" ]; then
  MAIN_REPO=$(git rev-parse --show-toplevel)
fi

# Find all worktrees
git worktree list --porcelain | grep "^worktree" | cut -d' ' -f2- | while IFS= read -r WORKTREE_PATH; do
    # Skip main repo
    if [ "$WORKTREE_PATH" = "$MAIN_REPO" ]; then
        continue
    fi

    # Check if path still exists (might have been manually removed)
    if [ ! -d "$WORKTREE_PATH" ]; then
        echo -e "${YELLOW}⚠️  Orphaned worktree metadata: $WORKTREE_PATH${NC}"
        echo "   Will be pruned at the end"
        continue
    fi

    # Get branch for this worktree
    BRANCH=$(git -C "$WORKTREE_PATH" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

    if [ -z "$BRANCH" ]; then
        echo -e "${RED}⚠️  Cannot determine branch for $WORKTREE_PATH${NC}"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        continue
    fi

    echo -e "${BLUE}Checking: ${BRANCH}${NC}"

    # Check if branch is merged into main
    if git branch --merged main | grep -q "^[* ]*$BRANCH\$"; then
        echo -e "${GREEN}  ✅ Branch is merged - cleaning up...${NC}"

        # Extract task ID from path (assumes ./worktrees/T0001/ structure)
        TASK_ID=$(basename "$WORKTREE_PATH")

        # Remove lock file
        LOCK_FILE=".claude/state/task-locks/${TASK_ID}.lock"
        if [ -f "$LOCK_FILE" ]; then
            rm -f "$LOCK_FILE"
            echo -e "  ${GREEN}🔓 Removed lock file${NC}"
        fi

        # Check for uncommitted changes (safety check)
        if [ -n "$(git -C "$WORKTREE_PATH" status --porcelain 2>/dev/null)" ]; then
            echo -e "  ${YELLOW}⚠️  Worktree has uncommitted changes${NC}"
            echo -e "  ${YELLOW}   Skipping automatic cleanup for safety${NC}"
            echo -e "  ${YELLOW}   To force remove: git worktree remove --force $WORKTREE_PATH${NC}"
            FAILED_COUNT=$((FAILED_COUNT + 1))
            continue
        fi

        # Remove worktree
        if git worktree remove "$WORKTREE_PATH" 2>/dev/null; then
            echo -e "  ${GREEN}📂 Removed worktree${NC}"
        else
            echo -e "  ${YELLOW}⚠️  Failed to remove worktree${NC}"
            echo -e "  ${YELLOW}   Manual cleanup: git worktree remove --force $WORKTREE_PATH${NC}"
            FAILED_COUNT=$((FAILED_COUNT + 1))
            continue
        fi

        # Delete branch (local only)
        if git branch -d "$BRANCH" 2>/dev/null; then
            echo -e "  ${GREEN}🌿 Deleted branch${NC}"
        else
            echo -e "  ${YELLOW}⚠️  Could not delete branch (may be in use elsewhere)${NC}"
            # This is not fatal - branch might be needed elsewhere
        fi

        echo -e "  ${GREEN}✅ Cleaned up ${TASK_ID}${NC}"
        CLEANED_COUNT=$((CLEANED_COUNT + 1))
    else
        echo -e "${YELLOW}  ⏳ Branch not merged yet - keeping worktree${NC}"
        KEPT_COUNT=$((KEPT_COUNT + 1))
    fi

    echo ""
done

# Prune stale worktree metadata
echo ""
echo -e "${BLUE}🧹 Pruning stale worktree metadata...${NC}"
git worktree prune --verbose

# Summary
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ Cleanup complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "📊 Summary:"
echo -e "  ${GREEN}Cleaned:${NC} $CLEANED_COUNT worktree(s)"
echo -e "  ${YELLOW}Kept (not merged):${NC} $KEPT_COUNT worktree(s)"
if [ $FAILED_COUNT -gt 0 ]; then
    echo -e "  ${RED}Failed/Skipped:${NC} $FAILED_COUNT worktree(s)"
fi
echo ""
echo -e "${BLUE}📋 Remaining worktrees:${NC}"
git worktree list

echo ""
echo -e "${BLUE}💡 Tip: To manually remove a worktree:${NC}"
echo -e "   git worktree remove <path>"
echo -e "   git worktree remove --force <path>  (if it has uncommitted changes)"
echo ""
