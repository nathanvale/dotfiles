#!/bin/bash
# VS Code Next Task Orchestrator
# Equivalent to Claude Code's /next command for VS Code users
#
# This script:
# 1. Finds the highest priority READY task
# 2. Creates a worktree + lock
# 3. Opens the worktree in a new VS Code window
#
# Usage:
#   ~/.claude/scripts/vscode-next.sh
#
# Or from VS Code:
#   Tasks: Run Task → "Next Task (Auto)"

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 VS Code Next Task Orchestrator${NC}"
echo ""

# ============================================================================
# STEP 1: Find highest priority READY task
# ============================================================================

echo -e "${BLUE}📋 Finding READY tasks...${NC}"

# Auto-detect task directory
TASK_DIR=""
if [ -d "apps/migration-cli/docs/tasks" ]; then
    TASK_DIR="apps/migration-cli/docs/tasks"
elif [ -d "docs/tasks" ]; then
    TASK_DIR="docs/tasks"
elif [ -d "tasks" ]; then
    TASK_DIR="tasks"
elif [ -d ".tasks" ]; then
    TASK_DIR=".tasks"
else
    echo -e "${RED}❌ ERROR: No task directory found${NC}"
    echo "Searched for:"
    echo "  - apps/*/docs/tasks/"
    echo "  - docs/tasks/"
    echo "  - tasks/"
    echo "  - .tasks/"
    exit 1
fi

echo -e "${CYAN}Task directory: ${TASK_DIR}${NC}"

# Find READY tasks and check dependencies
TASK_ID=""
HIGHEST_PRIORITY=""

find "$TASK_DIR" -name "T[0-9][0-9][0-9][0-9]-*.md" -type f | while IFS= read -r task_file; do
    # Extract status
    STATUS=$(grep "^status:" "$task_file" | sed 's/status: *//' || echo "")

    if [ "$STATUS" != "READY" ]; then
        continue
    fi

    # Extract priority
    PRIORITY=$(grep "^priority:" "$task_file" | sed 's/priority: *//' || echo "P3")

    # Extract task ID from filename
    CURRENT_TASK_ID=$(basename "$task_file" | grep -oE 'T[0-9]{4}')

    # Extract dependencies
    DEPENDS_ON=$(grep "^depends_on:" "$task_file" | sed 's/depends_on: *\[\(.*\)\]/\1/' || echo "")

    # Check if dependencies are met
    if [ -n "$DEPENDS_ON" ]; then
        ALL_MET=true
        for dep in $(echo "$DEPENDS_ON" | tr ',' ' '); do
            # Clean up whitespace
            dep=$(echo "$dep" | xargs)

            # Find dependency task file
            DEP_FILE=$(find "$TASK_DIR" -name "${dep}-*.md" -type f | head -1)

            if [ -z "$DEP_FILE" ]; then
                echo -e "${YELLOW}⚠️  ${CURRENT_TASK_ID}: Dependency ${dep} not found${NC}"
                ALL_MET=false
                break
            fi

            # Check if dependency is COMPLETED
            DEP_STATUS=$(grep "^status:" "$DEP_FILE" | sed 's/status: *//' || echo "")

            if [ "$DEP_STATUS" != "COMPLETED" ]; then
                echo -e "${YELLOW}⏳ ${CURRENT_TASK_ID}: Blocked by ${dep} (${DEP_STATUS})${NC}"
                ALL_MET=false
                break
            fi
        done

        if [ "$ALL_MET" = false ]; then
            continue
        fi
    fi

    # Priority comparison (P0 > P1 > P2 > P3)
    if [ -z "$HIGHEST_PRIORITY" ] || [ "$PRIORITY" \< "$HIGHEST_PRIORITY" ]; then
        HIGHEST_PRIORITY="$PRIORITY"
        TASK_ID="$CURRENT_TASK_ID"
        echo -e "${GREEN}✓ ${TASK_ID} (${PRIORITY}, dependencies met)${NC}"
    fi
done

# Check if we found a task
if [ -z "$TASK_ID" ]; then
    echo -e "${YELLOW}No READY tasks found${NC}"
    echo ""
    echo "All tasks may be:"
    echo "  - Already IN_PROGRESS or COMPLETED"
    echo "  - Blocked by dependencies"
    echo "  - Not in READY status"
    exit 0
fi

echo ""
echo -e "${GREEN}✅ Selected task: ${TASK_ID} (${HIGHEST_PRIORITY})${NC}"
echo ""

# ============================================================================
# STEP 2: Create worktree + lock
# ============================================================================

echo -e "${BLUE}🚀 Creating worktree for ${TASK_ID}...${NC}"
echo ""

if ! ~/.claude/scripts/create-worktree.sh "$TASK_ID"; then
    echo -e "${RED}❌ Failed to create worktree${NC}"
    exit 1
fi

echo ""

# ============================================================================
# STEP 3: Open in new VS Code window
# ============================================================================

WORKTREE_PATH="./worktrees/${TASK_ID}"

if [ ! -d "$WORKTREE_PATH" ]; then
    echo -e "${RED}❌ ERROR: Worktree not found at ${WORKTREE_PATH}${NC}"
    exit 1
fi

echo -e "${BLUE}📂 Opening worktree in new VS Code window...${NC}"
echo ""

# Open new VS Code window
code -n "$WORKTREE_PATH"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ VS Code Next Task Complete${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${CYAN}Task: ${TASK_ID}${NC}"
echo -e "${CYAN}Priority: ${HIGHEST_PRIORITY}${NC}"
echo -e "${CYAN}Worktree: ${WORKTREE_PATH}${NC}"
echo ""
echo -e "${BLUE}📋 Next steps:${NC}"
echo -e "  1. Work on task in new VS Code window"
echo -e "  2. Run validation: ${CYAN}pnpm typecheck && pnpm lint && pnpm test${NC}"
echo -e "  3. Commit changes to feature branch"
echo -e "  4. Create PR: ${CYAN}gh pr create${NC} or ${CYAN}az repos pr create${NC}"
echo -e "  5. Run: ${CYAN}Tasks: Run Task → Worktree: Cleanup Merged${NC} (after PR merged)"
echo ""
