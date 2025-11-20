#!/usr/bin/env bash
# TaskDock Shellcheck Runner
# Run shellcheck on all TaskDock scripts

set -euo pipefail

TASKDOCK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}TaskDock Shellcheck Audit${NC}"
echo "================================================"
echo ""

# Check if shellcheck is installed
if ! command -v shellcheck &> /dev/null; then
    echo -e "${RED}✗ shellcheck not found${NC}"
    echo "Install with: brew install shellcheck"
    exit 1
fi

echo -e "${GREEN}✓ shellcheck found:${NC} $(shellcheck --version | head -1)"
echo ""

# Find all shell scripts
SCRIPT_FILES=(
    # Main dispatcher
    "$TASKDOCK_ROOT/bin/taskdock"

    # Commands
    "$TASKDOCK_ROOT"/commands/*.sh

    # Libraries
    "$TASKDOCK_ROOT"/lib/*.sh

    # Tasks
    "$TASKDOCK_ROOT"/tasks/*.sh

    # Worktrees
    "$TASKDOCK_ROOT"/worktrees/*.sh

    # UX
    "$TASKDOCK_ROOT"/ux/*.sh

    # Scripts
    "$TASKDOCK_ROOT"/scripts/*.sh
)

# Expand wildcards and filter existing files
SCRIPTS=()
for pattern in "${SCRIPT_FILES[@]}"; do
    if [[ -f "$pattern" ]]; then
        SCRIPTS+=("$pattern")
    elif [[ "$pattern" == *"*"* ]]; then
        # Expand glob
        for file in $pattern; do
            [[ -f "$file" ]] && SCRIPTS+=("$file")
        done
    fi
done

if [[ ${#SCRIPTS[@]} -eq 0 ]]; then
    echo -e "${YELLOW}No scripts found${NC}"
    exit 0
fi

echo "Found ${#SCRIPTS[@]} scripts to check"
echo ""

# Shellcheck configuration
SHELLCHECK_OPTS=(
    --shell=bash
    --severity=style
    --exclude=SC1090  # Can't follow non-constant source
    --exclude=SC1091  # Not following sourced files
    --exclude=SC2034  # Variable appears unused (many are exported)
)

TOTAL=0
PASSED=0
FAILED=0
WARNINGS=0

# Run shellcheck on each script
for script in "${SCRIPTS[@]}"; do
    TOTAL=$((TOTAL + 1))

    relative_path="${script#$TASKDOCK_ROOT/}"

    # Run shellcheck
    if output=$(shellcheck "${SHELLCHECK_OPTS[@]}" "$script" 2>&1); then
        echo -e "${GREEN}✓${NC} $relative_path"
        PASSED=$((PASSED + 1))
    else
        # Check if there are warnings vs errors
        if echo "$output" | grep -q "^.*: error:"; then
            echo -e "${RED}✗${NC} $relative_path"
            FAILED=$((FAILED + 1))
        else
            echo -e "${YELLOW}⚠${NC} $relative_path"
            WARNINGS=$((WARNINGS + 1))
        fi

        # Show the output indented
        echo "$output" | sed 's/^/  /'
        echo ""
    fi
done

echo ""
echo "================================================"
echo "Summary:"
echo -e "  Total:    $TOTAL"
echo -e "  ${GREEN}Passed:   $PASSED${NC}"
echo -e "  ${YELLOW}Warnings: $WARNINGS${NC}"
echo -e "  ${RED}Failed:   $FAILED${NC}"
echo ""

if [[ $FAILED -gt 0 ]]; then
    echo -e "${RED}Shellcheck found errors!${NC}"
    exit 1
elif [[ $WARNINGS -gt 0 ]]; then
    echo -e "${YELLOW}Shellcheck found warnings (non-blocking)${NC}"
    exit 0
else
    echo -e "${GREEN}All checks passed!${NC}"
    exit 0
fi
