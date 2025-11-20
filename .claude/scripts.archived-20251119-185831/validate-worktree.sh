#!/bin/bash
# Validate Worktree - Deterministic validation for all projects
# Location: ~/.claude/scripts/validate-worktree.sh
# Usage: validate-worktree.sh <worktree-path> [package-name]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

WORKTREE_PATH="$1"
PACKAGE_NAME="$2"  # Optional: for monorepo filtering

if [ -z "$WORKTREE_PATH" ]; then
    echo -e "${RED}Usage: validate-worktree.sh <worktree-path> [package-name]${NC}"
    exit 1
fi

if [ ! -d "$WORKTREE_PATH" ]; then
    echo -e "${RED}❌ ERROR: Worktree not found at $WORKTREE_PATH${NC}"
    exit 1
fi

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔍 Validating worktree: $WORKTREE_PATH${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Detect project structure
IS_MONOREPO=false
if [ -f "$WORKTREE_PATH/pnpm-workspace.yaml" ] || \
   [ -f "$WORKTREE_PATH/lerna.json" ] || \
   [ -d "$WORKTREE_PATH/packages" ]; then
    IS_MONOREPO=true
    echo -e "${BLUE}📦 Detected: Monorepo${NC}"
else
    echo -e "${BLUE}📦 Detected: Single repo${NC}"
fi

# Detect package manager
PACKAGE_MANAGER=""
if [ -f "$WORKTREE_PATH/pnpm-lock.yaml" ]; then
    PACKAGE_MANAGER="pnpm"
elif [ -f "$WORKTREE_PATH/package-lock.json" ]; then
    PACKAGE_MANAGER="npm"
elif [ -f "$WORKTREE_PATH/yarn.lock" ]; then
    PACKAGE_MANAGER="yarn"
else
    echo -e "${RED}❌ ERROR: No lock file found (pnpm-lock.yaml, package-lock.json, yarn.lock)${NC}"
    exit 1
fi

echo -e "${BLUE}📦 Package manager: $PACKAGE_MANAGER${NC}"

# Auto-detect package name if not provided and is monorepo
if [ "$IS_MONOREPO" = true ] && [ -z "$PACKAGE_NAME" ]; then
    # Try to extract from task file in worktree
    TASK_FILE=$(find "$WORKTREE_PATH/docs/tasks" "$WORKTREE_PATH/apps/*/docs/tasks" "$WORKTREE_PATH/packages/*/docs/tasks" -name "T*.md" 2>/dev/null | head -1)
    if [ -n "$TASK_FILE" ]; then
        # Extract package dir from task file path
        PACKAGE_DIR=$(dirname "$(dirname "$(dirname "$TASK_FILE")")")
        PACKAGE_NAME=$(basename "$PACKAGE_DIR")
        echo -e "${BLUE}📦 Auto-detected package: $PACKAGE_NAME${NC}"
    fi
fi

echo ""

# Build command prefix based on project type
if [ "$IS_MONOREPO" = true ] && [ -n "$PACKAGE_NAME" ]; then
    # For monorepo with pnpm, use --filter from repo root (not --prefix)
    # cd to worktree first, then use --filter
    cd "$WORKTREE_PATH"
    CMD_PREFIX="$PACKAGE_MANAGER --filter $PACKAGE_NAME"
    echo -e "${BLUE}Running validation for package: $PACKAGE_NAME${NC}"
else
    # For single repo, use --prefix (don't cd)
    if [ "$PACKAGE_MANAGER" = "pnpm" ]; then
        CMD_PREFIX="$PACKAGE_MANAGER --prefix $WORKTREE_PATH"
    elif [ "$PACKAGE_MANAGER" = "npm" ]; then
        CMD_PREFIX="$PACKAGE_MANAGER --prefix $WORKTREE_PATH run"
    elif [ "$PACKAGE_MANAGER" = "yarn" ]; then
        CMD_PREFIX="$PACKAGE_MANAGER --cwd $WORKTREE_PATH"
    fi
fi

echo ""

# Helper function to check if npm script exists
script_exists() {
    local script_name="$1"
    local package_json

    if [ "$IS_MONOREPO" = true ] && [ -n "$PACKAGE_NAME" ]; then
        # Find package.json for specific package
        package_json=$(find "$WORKTREE_PATH/apps" "$WORKTREE_PATH/packages" -type f -name "package.json" -path "*/$PACKAGE_NAME/package.json" 2>/dev/null | head -1)
    else
        # Use root package.json
        package_json="$WORKTREE_PATH/package.json"
    fi

    if [ -f "$package_json" ]; then
        grep -q "\"$script_name\"" "$package_json"
        return $?
    else
        return 1
    fi
}

# Track failures
FAILED_CHECKS=0
SKIPPED_CHECKS=0

# Run validation checks in order
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}1️⃣  Running format check...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if ! script_exists "format"; then
    echo -e "${YELLOW}⏭️  Format script not found - skipping${NC}"
    SKIPPED_CHECKS=$((SKIPPED_CHECKS + 1))
elif $CMD_PREFIX format 2>&1; then
    echo -e "${GREEN}✅ Format check passed${NC}"
else
    echo -e "${RED}❌ Format check failed${NC}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}2️⃣  Running typecheck...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if ! script_exists "typecheck"; then
    echo -e "${RED}❌ Typecheck script not found (REQUIRED)${NC}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
elif $CMD_PREFIX typecheck 2>&1 | head -100; then
    echo -e "${GREEN}✅ Typecheck passed${NC}"
else
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 137 ]; then
        echo -e "${YELLOW}⚠️  Typecheck killed (OOM - exit 137)${NC}"
        echo -e "${YELLOW}Try checking specific files instead${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    else
        echo -e "${RED}❌ Typecheck failed${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}3️⃣  Running lint...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if ! script_exists "lint"; then
    echo -e "${YELLOW}⏭️  Lint script not found - skipping${NC}"
    SKIPPED_CHECKS=$((SKIPPED_CHECKS + 1))
elif $CMD_PREFIX lint 2>&1; then
    echo -e "${GREEN}✅ Lint passed${NC}"
else
    echo -e "${RED}❌ Lint failed${NC}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}4️⃣  Running tests...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if ! script_exists "test"; then
    echo -e "${RED}❌ Test script not found (REQUIRED)${NC}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
elif $CMD_PREFIX test 2>&1; then
    echo -e "${GREEN}✅ Tests passed${NC}"
else
    echo -e "${RED}❌ Tests failed${NC}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📊 Validation Summary${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

TOTAL_CHECKS=4
PASSED_CHECKS=$((TOTAL_CHECKS - FAILED_CHECKS - SKIPPED_CHECKS))

echo -e "Passed:  ${GREEN}${PASSED_CHECKS}${NC}"
echo -e "Failed:  ${RED}${FAILED_CHECKS}${NC}"
if [ $SKIPPED_CHECKS -gt 0 ]; then
    echo -e "Skipped: ${YELLOW}${SKIPPED_CHECKS}${NC} (optional scripts not found)"
fi
echo ""

if [ $FAILED_CHECKS -eq 0 ]; then
    echo -e "${GREEN}✅ All validation checks passed${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}❌ Validation failed: $FAILED_CHECKS check(s) failed${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo -e "  1. Fix the issues using Edit tool"
    echo -e "  2. Re-run validation: ~/.claude/scripts/validate-worktree.sh \"$WORKTREE_PATH\""
    echo -e "  3. Repeat until all checks pass"
    echo ""
    echo -e "${RED}⚠️  DO NOT mark task as COMPLETED until all checks pass${NC}"
    echo ""
    exit 1
fi
