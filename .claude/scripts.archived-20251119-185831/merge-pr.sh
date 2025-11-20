#!/bin/bash
# Merge PR and Clean Up Worktree
#
# Merges a completed PR and performs complete cleanup (worktree, branches, locks).
# Optimized to minimize GitHub/Azure API calls for faster execution.
#
# Usage:
#   merge-pr.sh [--pr-number NUM | --task-id ID | --current]
#   merge-pr.sh 123              # PR number (auto-detected)
#   merge-pr.sh T0030            # Task ID (auto-detected)
#   merge-pr.sh --current        # Use current worktree branch
#
# Returns:
#   Exit 0 on success, 1 on failure

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get git repo root
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

# Import lock directory helper
source ~/.claude/scripts/lib/get-project-lock-dir.sh
LOCK_DIR=$(get_project_lock_dir)

# Track if merge succeeded (for cleanup)
MERGE_SUCCEEDED=false

# Cleanup function for traps
cleanup_on_exit() {
    local exit_code=$?

    # Only unlock if merge succeeded
    # This prevents unlocking if merge failed but allows cleanup even if later steps fail
    if [ "$MERGE_SUCCEEDED" = true ] && [ -n "${TASK_ID:-}" ]; then
        LOCK_FILE="${LOCK_DIR}/${TASK_ID}.lock"
        if [ -f "$LOCK_FILE" ]; then
            rm -f "$LOCK_FILE" 2>/dev/null || true
            echo -e "${YELLOW}🔓 Lock removed (cleanup trap)${NC}" >&2
        fi
    fi

    exit $exit_code
}

# Set trap to cleanup on exit/error (only if merge succeeded)
trap cleanup_on_exit EXIT INT TERM

# Parse arguments
PR_INPUT=""
FORCE_CURRENT=false

if [ "${1:-}" = "--current" ]; then
    FORCE_CURRENT=true
elif [ -n "${1:-}" ]; then
    PR_INPUT="$1"
fi

# ============================================================================
# Step 1: Detect Git Remote Type
# ============================================================================

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔍 Detecting Git Remote Provider${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

REMOTE_TYPE=$(~/.claude/scripts/detect-git-provider.sh)
echo -e "${GREEN}✓ Detected: $REMOTE_TYPE${NC}"
echo ""

# ============================================================================
# Step 2: Identify PR and Branch
# ============================================================================

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔍 Identifying PR and Branch${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

PR_NUMBER=""
PR_ID=""
BRANCH_NAME=""
CURRENT_BRANCH=""

if [ "$REMOTE_TYPE" = "github" ]; then
    # GitHub workflow

    if [ "$FORCE_CURRENT" = true ] || [ -z "$PR_INPUT" ]; then
        # Option B: Detect from current worktree
        CURRENT_BRANCH=$(git branch --show-current)
        echo -e "Current branch: ${YELLOW}$CURRENT_BRANCH${NC}"

        # Get PR number for this branch (single API call)
        PR_JSON=$(gh pr list --head "$CURRENT_BRANCH" --json number,headRefName --limit 1)
        PR_NUMBER=$(echo "$PR_JSON" | jq -r '.[0].number // empty')
        BRANCH_NAME="$CURRENT_BRANCH"

        if [ -z "$PR_NUMBER" ]; then
            echo -e "${RED}❌ No PR found for branch: $CURRENT_BRANCH${NC}"
            exit 1
        fi

    elif [[ "$PR_INPUT" =~ ^[0-9]+$ ]]; then
        # Option A: User provides PR number
        PR_NUMBER="$PR_INPUT"
        echo -e "Using PR number: ${YELLOW}#$PR_NUMBER${NC}"

        # Get branch name from PR (single API call)
        BRANCH_NAME=$(gh pr view "$PR_NUMBER" --json headRefName -q .headRefName)

    elif [[ "$PR_INPUT" =~ ^[A-Z][A-Z0-9-]*[0-9]+$ ]]; then
        # Option C: User provides task ID (e.g., T0030, MPCU-0005)
        TASK_ID="$PR_INPUT"
        echo -e "Looking for task: ${YELLOW}$TASK_ID${NC}"

        # Find branch matching task ID
        BRANCH_NAME=$(git branch --list "feat/${TASK_ID}-*" --format='%(refname:short)' | head -1)

        if [ -z "$BRANCH_NAME" ]; then
            echo -e "${RED}❌ No branch found for task: $TASK_ID${NC}"
            exit 1
        fi

        echo -e "Found branch: ${YELLOW}$BRANCH_NAME${NC}"

        # Get PR number for this branch
        PR_NUMBER=$(gh pr list --head "$BRANCH_NAME" --json number -q '.[0].number')

        if [ -z "$PR_NUMBER" ]; then
            echo -e "${RED}❌ No PR found for branch: $BRANCH_NAME${NC}"
            exit 1
        fi

    else
        echo -e "${RED}❌ Invalid input: $PR_INPUT${NC}"
        echo "Usage: merge-pr.sh [PR_NUMBER | TASK_ID | --current]"
        exit 1
    fi

    echo -e "${GREEN}✓ PR #$PR_NUMBER${NC}"
    echo -e "${GREEN}✓ Branch: $BRANCH_NAME${NC}"

elif [ "$REMOTE_TYPE" = "azure" ]; then
    # Azure DevOps workflow

    if [ "$FORCE_CURRENT" = true ] || [ -z "$PR_INPUT" ]; then
        # Option B: Detect from current worktree
        CURRENT_BRANCH=$(git branch --show-current)
        echo -e "Current branch: ${YELLOW}$CURRENT_BRANCH${NC}"

        # Get PR ID for this branch
        PR_ID=$(az repos pr list --source-branch "$CURRENT_BRANCH" --status active --query '[0].pullRequestId' -o tsv)
        BRANCH_NAME="$CURRENT_BRANCH"

        if [ -z "$PR_ID" ] || [ "$PR_ID" = "null" ]; then
            echo -e "${RED}❌ No PR found for branch: $CURRENT_BRANCH${NC}"
            exit 1
        fi

    elif [[ "$PR_INPUT" =~ ^[0-9]+$ ]]; then
        # Option A: User provides PR ID
        PR_ID="$PR_INPUT"
        echo -e "Using PR ID: ${YELLOW}#$PR_ID${NC}"

        # Get branch name from PR
        BRANCH_NAME=$(az repos pr show --id "$PR_ID" --query sourceRefName -o tsv | sed 's|refs/heads/||')

    elif [[ "$PR_INPUT" =~ ^[A-Z][A-Z0-9-]*[0-9]+$ ]]; then
        # Option C: User provides task ID
        TASK_ID="$PR_INPUT"
        echo -e "Looking for task: ${YELLOW}$TASK_ID${NC}"

        # Find branch matching task ID
        BRANCH_NAME=$(git branch --list "feat/${TASK_ID}-*" --format='%(refname:short)' | head -1)

        if [ -z "$BRANCH_NAME" ]; then
            echo -e "${RED}❌ No branch found for task: $TASK_ID${NC}"
            exit 1
        fi

        echo -e "Found branch: ${YELLOW}$BRANCH_NAME${NC}"

        # Get PR ID for this branch
        PR_ID=$(az repos pr list --source-branch "$BRANCH_NAME" --status active --query '[0].pullRequestId' -o tsv)

        if [ -z "$PR_ID" ] || [ "$PR_ID" = "null" ]; then
            echo -e "${RED}❌ No PR found for branch: $BRANCH_NAME${NC}"
            exit 1
        fi

    else
        echo -e "${RED}❌ Invalid input: $PR_INPUT${NC}"
        echo "Usage: merge-pr.sh [PR_ID | TASK_ID | --current]"
        exit 1
    fi

    echo -e "${GREEN}✓ PR #$PR_ID${NC}"
    echo -e "${GREEN}✓ Branch: $BRANCH_NAME${NC}"
fi

echo ""

# ============================================================================
# Step 3: Verify PR Status (Optimized - Batch API Call)
# ============================================================================

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}✓ Verifying PR Status${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

PR_TITLE=""

if [ "$REMOTE_TYPE" = "github" ]; then
    # Single batched API call to get all PR info
    PR_DATA=$(gh pr view "$PR_NUMBER" --json state,mergeable,reviewDecision,title,headRefName)

    # Parse with single jq invocation (batch processing)
    read -r STATE MERGEABLE REVIEW PR_TITLE < <(echo "$PR_DATA" | jq -r '[.state, .mergeable, .reviewDecision, .title] | @tsv')

    echo -e "State: ${YELLOW}$STATE${NC}"
    echo -e "Mergeable: ${YELLOW}$MERGEABLE${NC}"
    echo -e "Review: ${YELLOW}$REVIEW${NC}"
    echo -e "Title: ${YELLOW}$PR_TITLE${NC}"

    if [ "$STATE" != "OPEN" ]; then
        echo -e "${RED}❌ PR #$PR_NUMBER is not open (state: $STATE)${NC}"
        exit 1
    fi

    if [ "$MERGEABLE" != "MERGEABLE" ]; then
        echo -e "${RED}❌ PR #$PR_NUMBER has merge conflicts${NC}"
        echo -e "${YELLOW}Please resolve conflicts and try again${NC}"
        exit 1
    fi

    echo -e "${GREEN}✅ PR #$PR_NUMBER is ready to merge${NC}"

elif [ "$REMOTE_TYPE" = "azure" ]; then
    # Single batched API call for Azure
    PR_DATA=$(az repos pr show --id "$PR_ID" --query '{status: status, mergeStatus: mergeStatus, title: title}' -o json)

    # Parse with single jq invocation
    read -r STATUS MERGE_STATUS PR_TITLE < <(echo "$PR_DATA" | jq -r '[.status, .mergeStatus, .title] | @tsv')

    echo -e "Status: ${YELLOW}$STATUS${NC}"
    echo -e "Merge Status: ${YELLOW}$MERGE_STATUS${NC}"
    echo -e "Title: ${YELLOW}$PR_TITLE${NC}"

    if [ "$STATUS" != "active" ]; then
        echo -e "${RED}❌ PR #$PR_ID is not active (status: $STATUS)${NC}"
        exit 1
    fi

    if [ "$MERGE_STATUS" != "succeeded" ]; then
        echo -e "${RED}❌ PR #$PR_ID cannot be merged (merge status: $MERGE_STATUS)${NC}"
        exit 1
    fi

    echo -e "${GREEN}✅ PR #$PR_ID is ready to merge${NC}"
fi

echo ""

# ============================================================================
# Step 4: Merge PR to Main
# ============================================================================

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔀 Merging PR to Main${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ "$REMOTE_TYPE" = "github" ]; then
    if gh pr merge "$PR_NUMBER" --merge --delete-branch --subject "Merge PR #$PR_NUMBER: $PR_TITLE"; then
        echo -e "${GREEN}✅ PR #$PR_NUMBER merged successfully${NC}"
        MERGE_SUCCEEDED=true
    else
        echo -e "${RED}❌ Merge failed - stopping cleanup${NC}"
        exit 1
    fi

elif [ "$REMOTE_TYPE" = "azure" ]; then
    # Manual merge process for Azure DevOps
    echo -e "${YELLOW}Performing manual merge (not using Azure PR merge)${NC}"

    # Fetch latest changes
    git fetch origin

    # Checkout and update main branch
    git checkout main
    git pull origin main

    # Merge the feature branch
    if git merge --no-ff "origin/$BRANCH_NAME" -m "Merge PR #$PR_ID: $PR_TITLE"; then
        # Push merged changes to main
        git push origin main

        # Delete remote branch manually
        git push origin --delete "$BRANCH_NAME" || echo -e "${YELLOW}⚠️  Could not delete remote branch${NC}"

        echo -e "${GREEN}✅ PR #$PR_ID merged successfully (manual merge)${NC}"
        MERGE_SUCCEEDED=true
    else
        echo -e "${RED}❌ Merge failed - stopping cleanup${NC}"
        exit 1
    fi
fi

echo ""

# ============================================================================
# Step 5: Update Main Branch Locally
# ============================================================================

# For Azure, we already updated main during the manual merge
if [ "$REMOTE_TYPE" = "github" ]; then
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}🔄 Updating Local Main Branch${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Switch to main branch
    git checkout main > /dev/null 2>&1

    # Pull latest (includes the merge)
    git pull origin main

    echo -e "${GREEN}✅ Local main branch updated${NC}"
    echo ""
else
    echo -e "${YELLOW}ℹ️  Main branch already updated during manual merge${NC}"
    echo ""
fi

# ============================================================================
# Step 6: Delete Local Branch
# ============================================================================

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🗑️  Deleting Local Branch${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
    git branch -D "$BRANCH_NAME" > /dev/null 2>&1
    echo -e "${GREEN}✅ Local branch deleted: $BRANCH_NAME${NC}"
else
    echo -e "${YELLOW}ℹ️  Local branch not found (may have been created in worktree only)${NC}"
fi

echo ""

# ============================================================================
# Step 7: Remove Worktree
# ============================================================================

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🗑️  Removing Worktree${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Find worktree path for this branch
WORKTREE_PATH=$(git worktree list | grep "$BRANCH_NAME" | awk '{print $1}')

if [ -n "$WORKTREE_PATH" ]; then
    # Remove worktree
    git worktree remove "$WORKTREE_PATH" --force > /dev/null 2>&1
    echo -e "${GREEN}✅ Worktree removed: $WORKTREE_PATH${NC}"
else
    echo -e "${YELLOW}ℹ️  No worktree found for branch $BRANCH_NAME${NC}"
fi

echo ""

# ============================================================================
# Step 8: Clean Up Lock File
# ============================================================================

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔓 Cleaning Up Lock File${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Extract task ID from branch name (handles T0044, MPCU-0005, etc.)
TASK_ID=$(echo "$BRANCH_NAME" | grep -oE '[A-Z][A-Z0-9-]*[0-9]+' | head -1)

if [ -n "$TASK_ID" ]; then
    LOCK_FILE="${LOCK_DIR}/${TASK_ID}.lock"

    if [ -f "$LOCK_FILE" ]; then
        rm "$LOCK_FILE"
        echo -e "${GREEN}✅ Lock file removed: $TASK_ID${NC}"
    else
        echo -e "${YELLOW}ℹ️  No lock file found for task $TASK_ID${NC}"
    fi
else
    echo -e "${YELLOW}ℹ️  No task ID found in branch name${NC}"
fi

echo ""

# ============================================================================
# Step 9: Summary
# ============================================================================

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ PR Merge Complete${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ "$REMOTE_TYPE" = "github" ]; then
    echo -e "PR: ${YELLOW}#$PR_NUMBER${NC}"
else
    echo -e "PR: ${YELLOW}#$PR_ID${NC}"
fi

echo -e "Branch: ${YELLOW}$BRANCH_NAME${NC}"
echo -e "Title: ${YELLOW}$PR_TITLE${NC}"
echo ""
echo -e "${GREEN}✅ PR merged to main${NC}"
echo -e "${GREEN}✅ Remote branch deleted${NC}"
echo -e "${GREEN}✅ Local branch deleted${NC}"
echo -e "${GREEN}✅ Worktree removed${NC}"
echo -e "${GREEN}✅ Lock file removed${NC}"
echo ""
echo -e "${BLUE}Main branch updated - ready for next task${NC}"
echo -e "${YELLOW}Run '/next' to start the next highest-priority task${NC}"
echo ""

exit 0
