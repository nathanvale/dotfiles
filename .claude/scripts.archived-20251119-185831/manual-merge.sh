#!/bin/bash
# Manual Merge Script
#
# Merges current branch directly into main without creating a PR.
# Cleans up worktree, branches, and lock files.
#
# Usage:
#   manual-merge.sh [branch-name]
#   manual-merge.sh                    # Use current branch
#   manual-merge.sh feat/my-feature    # Merge specific branch

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔀 Manual Merge (No PR)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Get repository root
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

# Determine branch to merge
if [ -n "${1:-}" ]; then
    BRANCH_NAME="$1"
    echo -e "${BLUE}Branch: $BRANCH_NAME (provided)${NC}"
else
    BRANCH_NAME=$(git branch --show-current)
    echo -e "${BLUE}Branch: $BRANCH_NAME (current)${NC}"
fi

# Safety check: don't merge main into main
if [ "$BRANCH_NAME" = "main" ] || [ "$BRANCH_NAME" = "master" ]; then
    echo -e "${RED}❌ Cannot merge main/master into itself${NC}"
    exit 1
fi

# Detect worktree if exists by checking which worktree has this branch checked out
# Parse git worktree list --porcelain output line by line
WORKTREE_PATH=""
while IFS= read -r line; do
    if [[ "$line" == worktree\ * ]]; then
        current_wt="${line#worktree }"
    elif [[ "$line" == "branch refs/heads/$BRANCH_NAME" ]]; then
        WORKTREE_PATH="$current_wt"
        break
    fi
done < <(git worktree list --porcelain)

if [ -n "$WORKTREE_PATH" ]; then
    echo -e "${BLUE}Worktree: $WORKTREE_PATH${NC}"
else
    echo -e "${YELLOW}⚠️  No worktree detected${NC}"
fi

echo ""

# Extract task ID from branch name
TASK_ID=$(echo "$BRANCH_NAME" | grep -oE 'MPCU-[0-9]+|T-[0-9]+|T[0-9]+|[A-Z]+-[0-9]+' | head -1 || echo "")

if [ -n "$TASK_ID" ]; then
    echo -e "${BLUE}Task ID: $TASK_ID${NC}"
fi

echo ""
echo -e "${YELLOW}⚠️  This will:${NC}"
echo -e "${YELLOW}  1. Merge $BRANCH_NAME → main (no PR)${NC}"
echo -e "${YELLOW}  2. Push to origin/main${NC}"
echo -e "${YELLOW}  3. Delete remote branch${NC}"
echo -e "${YELLOW}  4. Remove worktree (if exists)${NC}"
echo -e "${YELLOW}  5. Delete local branch${NC}"
echo -e "${YELLOW}  6. Clean up lock file${NC}"
echo ""

# Confirm
read -p "Continue? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}❌ Merge cancelled${NC}"
    exit 0
fi

echo ""

# Step 1: Switch to main and update
echo -e "${BLUE}📥 Updating main branch...${NC}"
git checkout main
git pull origin main
echo -e "${GREEN}✅ Main branch updated${NC}"
echo ""

# Step 2: Merge with no-fast-forward
echo -e "${BLUE}🔀 Merging $BRANCH_NAME into main...${NC}"
if git merge --no-ff "$BRANCH_NAME" -m "Merge $BRANCH_NAME"; then
    echo -e "${GREEN}✅ Merge successful${NC}"
else
    echo -e "${RED}❌ Merge failed - conflicts may need resolution${NC}"
    echo -e "${YELLOW}Run 'git merge --abort' to cancel or resolve conflicts manually${NC}"
    exit 1
fi
echo ""

# Step 3: Push to remote
echo -e "${BLUE}📤 Pushing to origin/main...${NC}"
if git push origin main; then
    echo -e "${GREEN}✅ Pushed to origin/main${NC}"
else
    echo -e "${RED}❌ Push failed${NC}"
    exit 1
fi
echo ""

# Step 4: Delete remote branch
echo -e "${BLUE}🗑️  Deleting remote branch...${NC}"
if git push origin --delete "$BRANCH_NAME" 2>/dev/null; then
    echo -e "${GREEN}✅ Remote branch deleted${NC}"
else
    echo -e "${YELLOW}⚠️  Remote branch already deleted or doesn't exist${NC}"
fi
echo ""

# Step 5: Remove worktree if exists
if [ -n "$WORKTREE_PATH" ]; then
    echo -e "${BLUE}🗑️  Removing worktree...${NC}"
    if git worktree remove "$WORKTREE_PATH" 2>/dev/null; then
        echo -e "${GREEN}✅ Worktree removed: $WORKTREE_PATH${NC}"
    else
        echo -e "${YELLOW}⚠️  Forcing worktree removal...${NC}"
        if git worktree remove --force "$WORKTREE_PATH"; then
            echo -e "${GREEN}✅ Worktree force-removed${NC}"
        else
            echo -e "${RED}❌ Failed to remove worktree${NC}"
        fi
    fi
    echo ""
fi

# Step 6: Delete local branch
echo -e "${BLUE}🗑️  Deleting local branch...${NC}"
if git branch -D "$BRANCH_NAME" 2>/dev/null; then
    echo -e "${GREEN}✅ Local branch deleted${NC}"
else
    echo -e "${YELLOW}⚠️  Local branch already deleted${NC}"
fi
echo ""

# Step 7: Clean up lock file
if [ -n "$TASK_ID" ]; then
    echo -e "${BLUE}🔓 Cleaning up lock file...${NC}"
    if ~/.claude/scripts/cleanup-task-lock.sh "$TASK_ID" "$REPO_ROOT" 2>/dev/null; then
        echo -e "${GREEN}✅ Lock file cleaned up${NC}"
    else
        echo -e "${YELLOW}⚠️  No lock file to clean up${NC}"
    fi
    echo ""
fi

# Summary
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Manual Merge Complete${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}Merged: $BRANCH_NAME → main${NC}"
if [ -n "$TASK_ID" ]; then
    echo -e "${GREEN}Task: $TASK_ID${NC}"
fi
echo -e "${GREEN}Branch deleted: $BRANCH_NAME${NC}"
if [ -n "$WORKTREE_PATH" ]; then
    echo -e "${GREEN}Worktree removed: $WORKTREE_PATH${NC}"
fi
echo ""
echo -e "${BLUE}You are now on: $(git branch --show-current)${NC}"
echo ""

exit 0
