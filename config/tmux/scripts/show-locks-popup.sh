#!/bin/bash
# Wrapper script to show locks in a popup that stays open

set +e  # Don't exit on errors

clear
echo "════════════════════════════════════════════════════════════════"
echo "  🔒 Task Lock Status"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Resolve taskdock binary
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../../.." && pwd)
TASKDOCK_BIN="$REPO_ROOT/apps/taskdock/bin/taskdock"

if [ ! -x "$TASKDOCK_BIN" ]; then
    TASKDOCK_BIN="taskdock"
fi

# Run the list-task-locks script explicitly with bash
if "$TASKDOCK_BIN" locks list 2>&1; then
    echo ""
else
    echo ""
    echo "⚠️  Error running taskdock locks list"
    echo ""
fi

echo "════════════════════════════════════════════════════════════════"
echo ""
read -n 1 -s -r -p "Press any key to close..."
echo ""
