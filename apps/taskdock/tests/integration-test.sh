#!/usr/bin/env bash
# TaskDock Integration Test
# Tests core functionality with fixture data

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

FIXTURES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="/tmp/taskdock-integration-test-$$"
PASSED=0
FAILED=0

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}TaskDock Integration Test${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Cleanup function
cleanup() {
    if [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi
}

trap cleanup EXIT

# Test assertion helper
assert_equals() {
    local expected="$1"
    local actual="$2"
    local description="$3"

    if [ "$expected" = "$actual" ]; then
        echo -e "${GREEN}✓${NC} $description"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}✗${NC} $description"
        echo -e "  Expected: ${expected}"
        echo -e "  Actual: ${actual}"
        FAILED=$((FAILED + 1))
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local description="$3"

    if echo "$haystack" | grep -q "$needle"; then
        echo -e "${GREEN}✓${NC} $description"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}✗${NC} $description"
        echo -e "  Expected to contain: ${needle}"
        echo -e "  Actual: ${haystack}"
        FAILED=$((FAILED + 1))
    fi
}

# Setup test environment
echo -e "${BLUE}Setting up test environment...${NC}"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

git init -q
git config user.email "test@example.com"
git config user.name "Test User"

# Create initial commit
echo "# Test Repo" > README.md
git add README.md
git commit -q -m "Initial commit"

echo -e "${GREEN}✓${NC} Test environment created: $TEST_DIR"
echo ""

# Test 1: Repository initialization
echo -e "${BLUE}Test 1: Repository initialization${NC}"
INIT_OUTPUT=$(taskdock init --ticket-prefix TEST 2>&1 || echo "FAILED")
assert_contains "$INIT_OUTPUT" "initialized" "taskdock init succeeds"
assert_equals "true" "$([ -f .taskdock/config.yaml ] && echo true || echo false)" "Creates .taskdock/config.yaml"
echo ""

# Test 2: Copy fixtures
echo -e "${BLUE}Test 2: Fixture setup${NC}"
mkdir -p docs/tasks
cp "$FIXTURES_DIR"/T*.md docs/tasks/
TASK_COUNT=$(find docs/tasks -name "T*.md" | wc -l | tr -d ' ')
assert_equals "5" "$TASK_COUNT" "All fixture tasks copied"
echo ""

# Test 3: Next task selection (should select T0001 - highest priority READY)
echo -e "${BLUE}Test 3: Task selection - highest priority${NC}"
NEXT_OUTPUT=$(taskdock next --json 2>&1 || echo '{"error": true}')
SELECTED_TASK=$(echo "$NEXT_OUTPUT" | jq -r '.data.taskId // "NONE"')
assert_equals "T0001" "$SELECTED_TASK" "Selects highest priority READY task (T0001)"
echo ""

# Test 4: Lock file creation
echo -e "${BLUE}Test 4: Lock file creation${NC}"
LOCK_EXISTS=$([ -f .git/task-locks/T0001.lock ] && echo "true" || echo "false")
assert_equals "true" "$LOCK_EXISTS" "Creates lock file for selected task"
echo ""

# Test 5: Lock prevents duplicate selection
echo -e "${BLUE}Test 5: Lock prevents duplicate selection${NC}"
NEXT_AGAIN=$(taskdock next --json 2>&1 || echo '{"error": true}')
SECOND_SELECT=$(echo "$NEXT_AGAIN" | jq -r '.data.taskId // "NONE"')
assert_equals "T0002" "$SECOND_SELECT" "Skips locked task, selects next available (T0002)"
echo ""

# Test 6: Locks list
echo -e "${BLUE}Test 6: Lock listing${NC}"
LOCKS_OUTPUT=$(taskdock locks list --json 2>&1)
LOCK_COUNT=$(echo "$LOCKS_OUTPUT" | jq -r '.data | length')
assert_equals "2" "$LOCK_COUNT" "Lists correct number of locks"
echo ""

# Test 7: Config get
echo -e "${BLUE}Test 7: Configuration retrieval${NC}"
TICKET_PREFIX=$(taskdock config get ticket_prefix 2>&1)
assert_contains "$TICKET_PREFIX" "TEST" "Retrieves ticket_prefix from config"
echo ""

# Test 8: Doctor command
echo -e "${BLUE}Test 8: Doctor health check${NC}"
DOCTOR_OUTPUT=$(taskdock doctor --json 2>&1 || echo '{"error": true}')
HEALTH_STATUS=$(echo "$DOCTOR_OUTPUT" | jq -r '.data.status // "unknown"')
assert_contains "$HEALTH_STATUS" "healthy\|degraded" "Doctor reports health status"
echo ""

# Test 9: Worktree creation
echo -e "${BLUE}Test 9: Worktree creation${NC}"
WORKTREE_OUTPUT=$(taskdock worktree create T0001 --no-install 2>&1 || echo "FAILED")
WORKTREE_EXISTS=$([ -d .worktrees/T0001 ] && echo "true" || echo "false")
assert_equals "true" "$WORKTREE_EXISTS" "Creates worktree directory"
echo ""

# Test 10: Lock cleanup
echo -e "${BLUE}Test 10: Lock cleanup${NC}"
taskdock locks unlock T0001 2>&1 >/dev/null || true
taskdock locks unlock T0002 2>&1 >/dev/null || true
LOCKS_AFTER=$(taskdock locks list --json 2>&1 | jq -r '.data | length')
assert_equals "0" "$LOCKS_AFTER" "Unlocks all locks"
echo ""

# Summary
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Test Results${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}Passed:${NC} $PASSED"
echo -e "${RED}Failed:${NC} $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    exit 1
fi
