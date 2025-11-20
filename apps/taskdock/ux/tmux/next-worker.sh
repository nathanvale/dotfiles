#!/bin/bash
# Enhanced tmux worker loop with heartbeat monitoring

set -euo pipefail

# Color codes
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'
CYAN=$'\033[0;36m'
RED=$'\033[0;31m'
NC=$'\033[0m'

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)
# Go up 4 levels: tmux -> ux -> taskdock -> apps -> dotfiles
REPO_ROOT=$(cd "$SCRIPT_DIR/../../../.." >/dev/null && pwd)
cd "$REPO_ROOT"

# Resolve taskdock binary
TASKDOCK_BIN="$REPO_ROOT/apps/taskdock/bin/taskdock"
if [ ! -x "$TASKDOCK_BIN" ]; then
    if command -v taskdock &> /dev/null; then
        TASKDOCK_BIN="taskdock"
    else
        echo -e "${RED}❌ Error: taskdock binary not found at $TASKDOCK_BIN and not in PATH${NC}"
        read -p "Press Enter to close..."
        exit 1
    fi
fi

# Heartbeat interval (in seconds)
HEARTBEAT_INTERVAL=120  # 2 minutes

# Worker identification
WORKER_ID="tmux-pane-$(tmux display-message -p '#{pane_id}' 2>/dev/null || echo $$)"
export WORKER_ID

echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  🤖 Multi-Agent Worker Loop                                   ║${NC}"
echo -e "${CYAN}╠════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${CYAN}║  Worker ID: ${WORKER_ID}${NC}"
echo -e "${CYAN}║  Heartbeat: Every ${HEARTBEAT_INTERVAL}s${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Background heartbeat function
start_heartbeat() {
    local task_id="$1"

    (
        while kill -0 $$ 2>/dev/null; do
            sleep "$HEARTBEAT_INTERVAL"
            if "$TASKDOCK_BIN" heartbeat "$task_id" >/dev/null 2>&1; then
                tmux display-message "💓 Heartbeat updated for $task_id" 2>/dev/null || true
            fi
        done
    ) &

    HEARTBEAT_PID=$!
    echo -e "${GREEN}✅ Started heartbeat monitor (PID: $HEARTBEAT_PID)${NC}"
}

# Stop heartbeat
stop_heartbeat() {
    if [ -n "${HEARTBEAT_PID:-}" ]; then
        kill "$HEARTBEAT_PID" 2>/dev/null || true
        echo -e "${YELLOW}⏸️  Stopped heartbeat monitor${NC}"
    fi
}

# Cleanup on exit
cleanup() {
    stop_heartbeat
    echo -e "${BLUE}👋 Worker shutting down${NC}"
    # Keep window open on error if we didn't exit cleanly
    if [ $? -ne 0 ]; then
        echo -e "${RED}⚠️  Worker exited with error. Press Enter to close...${NC}"
        read -r
    fi
}
trap cleanup EXIT

# Main worker loop
while true; do
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}🚀 Requesting next available task...${NC}"
    echo ""

    # Run cleanup before attempting to grab a new task
    "$TASKDOCK_BIN" locks cleanup --quiet >/dev/null 2>&1 || true

    # Get next task
    NEXT_TASK_JSON=$("$TASKDOCK_BIN" next --json 2>/dev/null || echo "{}")
    TASK_ID=$(echo "$NEXT_TASK_JSON" | jq -r '.taskId // empty')

    if [ -n "$TASK_ID" ]; then
        echo ""
        echo -e "${GREEN}✅ Assigned task: $TASK_ID${NC}"
        echo ""

        # Start heartbeat monitoring
        start_heartbeat "$TASK_ID"

        # Create worktree
        if "$TASKDOCK_BIN" worktree create "$TASK_ID"; then
                echo ""
                echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
                echo -e "${CYAN}║  📝 Task Ready for Implementation                             ║${NC}"
                echo -e "${CYAN}╠════════════════════════════════════════════════════════════════╣${NC}"
                echo -e "${CYAN}║  Task ID:     $TASK_ID${NC}"
                echo -e "${CYAN}║  Worktree:    .worktrees/$TASK_ID${NC}"
                echo -e "${CYAN}║  Heartbeat:   Active (${HEARTBEAT_INTERVAL}s pulses)${NC}"
                echo -e "${CYAN}╠════════════════════════════════════════════════════════════════╣${NC}"
                echo -e "${CYAN}║  Next Steps:${NC}"
                echo -e "${CYAN}║  1. Implement the task${NC}"
                echo -e "${CYAN}║  2. Run validation${NC}"
                echo -e "${CYAN}║  3. Run /merge when complete${NC}"
                echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
                echo ""

                # Exit loop - manual implementation phase
                break
            else
                echo -e "${RED}❌ Worktree creation failed${NC}"
                stop_heartbeat
            fi
        else
            echo -e "${YELLOW}⏳ No task assigned (all tasks locked or none available)${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  No tasks available; will retry in 30s${NC}"
    fi

    # Wait before retry
    sleep 30
done

# Keep shell open for manual work
echo ""
echo -e "${GREEN}🎯 Worker loop finished - shell remains open for manual work${NC}"
echo -e "${BLUE}💡 Tip: Heartbeat will continue updating every ${HEARTBEAT_INTERVAL}s${NC}"
echo ""
