#!/bin/bash
# tmux helper: watch lock status with list-task-locks --watch

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)
# Go up 4 levels: tmux -> ux -> taskdock -> apps -> dotfiles
REPO_ROOT=$(cd "$SCRIPT_DIR/../../../.." >/dev/null && pwd)
TASKDOCK_BIN="$REPO_ROOT/apps/taskdock/bin/taskdock"

if [ ! -x "$TASKDOCK_BIN" ]; then
    TASKDOCK_BIN="taskdock"
fi

cd "$REPO_ROOT"

if [ -z "${TMUX:-}" ]; then
    echo "⚠️  Not inside tmux; running once"
    "$TASKDOCK_BIN" locks list
    exit 0
fi

# Watch loop
while true; do
    clear
    echo "════════════════════════════════════════════════════════════════"
    echo "  🔒 Task Lock Status (Updated: $(date +%H:%M:%S))"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    "$TASKDOCK_BIN" locks list
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    sleep 2
done
