#!/usr/bin/env bash
# TaskDock Bash Compatibility Checker
# Verify all scripts use bash-compatible syntax

set -euo pipefail

TASKDOCK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}TaskDock Bash Compatibility Audit${NC}"
echo "================================================"
echo ""

# Check bash version
BASH_MAJOR="${BASH_VERSINFO[0]}"
BASH_MINOR="${BASH_VERSINFO[1]}"

echo "Current Bash: $BASH_MAJOR.$BASH_MINOR"
if [[ "$BASH_MAJOR" -ge 4 ]]; then
    echo -e "${GREEN}✓ Bash version is compatible${NC}"
elif [[ "$BASH_MAJOR" -eq 3 ]] && [[ "$BASH_MINOR" -ge 2 ]]; then
    echo -e "${YELLOW}⚠ Bash 3.2 detected - some features may not work${NC}"
    echo -e "${YELLOW}  Upgrade to bash 4.0+ recommended${NC}"
else
    echo -e "${RED}✗ Bash version too old (requires 3.2+)${NC}"
    exit 1
fi
echo ""

# Find all shell scripts
echo "Scanning for shell scripts..."
SCRIPTS=()
while IFS= read -r -d '' file; do
    SCRIPTS+=("$file")
done < <(find "$TASKDOCK_ROOT" \( -name "*.sh" -o -path "*/bin/taskdock" \) -type f -print0)

echo "Found ${#SCRIPTS[@]} scripts"
echo ""

# Compatibility checks
ISSUES=0
CHECKS_RUN=0

echo "Running compatibility checks..."
echo ""

for script in "${SCRIPTS[@]}"; do
    relative_path="${script#$TASKDOCK_ROOT/}"
    script_issues=()

    # Check 1: Shebang should be bash
    if head -n1 "$script" | grep -q '^#!/usr/bin/env bash'; then
        : # Good
    elif head -n1 "$script" | grep -q '^#!/bin/bash'; then
        script_issues+=("Shebang should be '#!/usr/bin/env bash' (found '#!/bin/bash')")
    elif head -n1 "$script" | grep -q '^#!/bin/sh'; then
        script_issues+=("ERROR: Using sh instead of bash")
        ((ISSUES++))
    fi
    ((CHECKS_RUN++))

    # Check 2: Uses set -euo pipefail (for main scripts)
    if [[ "$relative_path" == commands/* ]] || [[ "$relative_path" == bin/* ]]; then
        if ! grep -q 'set -euo pipefail' "$script"; then
            script_issues+=("Missing 'set -euo pipefail'")
        fi
    fi
    ((CHECKS_RUN++))

    # Check 3: No usage of sh-specific syntax
    if grep -n '\[ .*= .*\]' "$script" | grep -v '\[\['; then
        script_issues+=("Uses [ ] instead of [[ ]] (less robust)")
    fi
    ((CHECKS_RUN++))

    # Check 4: No backticks
    if grep -n '`.*`' "$script" | grep -v '#.*`.*`'; then
        script_issues+=("Uses backticks instead of \$()")
    fi
    ((CHECKS_RUN++))

    # Check 5: Variables are quoted
    # This is a heuristic check - look for common unquoted patterns
    if grep -n '\$[A-Z_][A-Z0-9_]*[^"]' "$script" | \
       grep -v '#' | \
       grep -v 'BASH_' | \
       grep -v '\[\[' | \
       head -5 > /dev/null; then
        script_issues+=("Possible unquoted variables (check manually)")
    fi
    ((CHECKS_RUN++))

    # Report issues for this script
    if [[ ${#script_issues[@]} -gt 0 ]]; then
        echo -e "${YELLOW}⚠${NC} $relative_path"
        for issue in "${script_issues[@]}"; do
            echo "    - $issue"
        done
        echo ""
    fi
done

echo ""
echo "================================================"
echo "Compatibility Summary:"
echo "  Scripts checked: ${#SCRIPTS[@]}"
echo "  Checks run: $CHECKS_RUN"
echo ""

if [[ $ISSUES -gt 0 ]]; then
    echo -e "${RED}Found $ISSUES critical issues${NC}"
    exit 1
else
    echo -e "${GREEN}No critical issues found${NC}"
    echo ""
    echo "Recommendations:"
    echo "  1. Run shellcheck for detailed analysis:"
    echo "     ./taskdock/scripts/shellcheck-all.sh"
    echo ""
    echo "  2. Test on target platforms:"
    echo "     - Linux (bash 4.3+)"
    echo "     - macOS with Homebrew bash (5.0+)"
    echo "     - WSL"
    echo ""
    exit 0
fi
