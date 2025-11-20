#!/usr/bin/env bash
# TaskDock VS Code Integration
# Opens next task in VS Code worktree

set -euo pipefail

# Source required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/ui.sh"
source "${SCRIPT_DIR}/lib/logging.sh"

main() {
    info "VS Code Next Task Orchestrator"
    echo ""

    # Step 1: Get next task
    info "Finding next available task..."

    local next_result
    next_result=$(TASKDOCK_OUTPUT=json "${SCRIPT_DIR}/bin/taskdock" next 2>/dev/null)

    if [ $? -ne 0 ]; then
        error "Failed to get next task"
        echo "$next_result"
        return 1
    fi

    local task_id
    task_id=$(echo "$next_result" | jq -r '.data.taskId')

    if [ -z "$task_id" ] || [ "$task_id" = "null" ]; then
        warn "No tasks available"
        return 0
    fi

    success "Selected task: ${task_id}"

    # Step 2: Create worktree
    info "Creating worktree..."

    local worktree_result
    worktree_result=$(TASKDOCK_OUTPUT=json "${SCRIPT_DIR}/bin/taskdock" worktree create "$task_id" 2>/dev/null)

    if [ $? -ne 0 ]; then
        error "Failed to create worktree"
        echo "$worktree_result"
        return 1
    fi

    local worktree_path
    worktree_path=$(echo "$worktree_result" | jq -r '.data.path')

    success "Worktree created: ${worktree_path}"

    # Step 3: Open in VS Code
    info "Opening in VS Code..."

    if command -v code >/dev/null 2>&1; then
        code "$worktree_path"
        success "VS Code opened"
        echo ""
        tip "Worktree is ready at: ${worktree_path}"
        tip "Run 'taskdock validate' when ready to validate your changes"
    else
        warn "VS Code CLI not found"
        tip "Install with: code command from VS Code: Cmd+Shift+P → 'Shell Command: Install code command'"
        tip "Or open manually: ${worktree_path}"
    fi

    log_task_event "vscode" "$task_id" "Opened in VS Code" \
        "$(jq -n --arg path "$worktree_path" '{path: $path}')"
}

main "$@"
