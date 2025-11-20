#!/usr/bin/env bash
# TaskDock worktree context setup
# Sets up environment variables for working in a task worktree
# Must be sourced to export variables to parent shell

set -euo pipefail

TASK_ID="${1:-}"

if [ -z "$TASK_ID" ]; then
    echo "❌ ERROR: Task ID required"
    echo "Usage: source taskdock-worktree-env.sh <task-id>"
    return 1 2>/dev/null || exit 1
fi

# Find taskdock installation
TASKDOCK_ROOT=""
if [ -f "$HOME/code/dotfiles/apps/taskdock/lib/common.sh" ]; then
    TASKDOCK_ROOT="$HOME/code/dotfiles/apps/taskdock"
elif [ -f "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh" ]; then
    TASKDOCK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/..)" && pwd)"
else
    echo "❌ ERROR: Cannot find TaskDock installation"
    return 1 2>/dev/null || exit 1
fi

# Source libraries
source "${TASKDOCK_ROOT}/lib/common.sh"
source "${TASKDOCK_ROOT}/lib/config.sh"

# Get repo root
MAIN_REPO=$(get_repo_root 2>/dev/null || pwd)

# Get worktree root from config
WORKTREE_BASE=$(taskdock_config worktree_root 2>/dev/null || echo ".worktrees")
WORKTREE_ROOT="${MAIN_REPO}/${WORKTREE_BASE}/${TASK_ID}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 TaskDock: Setting up task context"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Repo:     ${MAIN_REPO}"
echo "Worktree: ${WORKTREE_ROOT}"
echo "Task ID:  ${TASK_ID}"
echo ""

if [ ! -d "$WORKTREE_ROOT" ]; then
    echo "❌ ERROR: Worktree not found at ${WORKTREE_ROOT}"
    echo "➡️  Run: taskdock worktree create ${TASK_ID}"
    return 1 2>/dev/null || exit 1
fi

# Check dependencies
if [ -f "${WORKTREE_ROOT}/package.json" ] && [ ! -d "${WORKTREE_ROOT}/node_modules" ]; then
    echo "❌ ERROR: Dependencies not installed in worktree"
    echo "➡️  Run: cd ${WORKTREE_ROOT} && pnpm install"
    return 1 2>/dev/null || exit 1
fi

# Find task file
TASK_FILE=""

# Priority 1: docs/tasks root
for match in "${WORKTREE_ROOT}/docs/tasks/${TASK_ID}-"*.md; do
    if [ -f "$match" ]; then
        TASK_FILE="$match"
        break
    fi
done

# Priority 2: apps/*/docs/tasks
if [ -z "$TASK_FILE" ] && [ -d "${WORKTREE_ROOT}/apps" ]; then
    while IFS= read -r -d '' candidate; do
        TASK_FILE="$candidate"
        break
    done < <(find "${WORKTREE_ROOT}/apps" -maxdepth 4 -type f -name "${TASK_ID}-*.md" -path "*/docs/tasks/*" -print0 2>/dev/null || true)
fi

# Priority 3: packages/*/docs/tasks
if [ -z "$TASK_FILE" ] && [ -d "${WORKTREE_ROOT}/packages" ]; then
    while IFS= read -r -d '' candidate; do
        TASK_FILE="$candidate"
        break
    done < <(find "${WORKTREE_ROOT}/packages" -maxdepth 4 -type f -name "${TASK_ID}-*.md" -path "*/docs/tasks/*" -print0 2>/dev/null || true)
fi

if [ -z "$TASK_FILE" ]; then
    echo "❌ ERROR: Task file for ${TASK_ID} not found"
    return 1 2>/dev/null || exit 1
fi

# Detect package name for monorepos (pnpm workspace)
PACKAGE_NAME=""
if [ -f "${WORKTREE_ROOT}/pnpm-workspace.yaml" ]; then
    rel_path="${TASK_FILE#${WORKTREE_ROOT}/}"
    IFS='/' read -r first second _rest <<< "$rel_path"
    if [ "$first" = "apps" ] || [ "$first" = "packages" ]; then
        PACKAGE_NAME="$second"
    fi
fi

echo "📄 Task file: ${TASK_FILE}"
if [ -n "$PACKAGE_NAME" ]; then
    echo "📦 Package:   ${PACKAGE_NAME}"
else
    echo "📦 Package:   (single-repo / none)"
fi
echo ""
echo "✅ Context initialized"

# Export variables
export MAIN_REPO
export WORKTREE_ROOT
export TASK_FILE
export PACKAGE_NAME
export TASK_ID

# Machine-readable summary
echo "::setup:: MAIN_REPO='${MAIN_REPO}' WORKTREE_ROOT='${WORKTREE_ROOT}' TASK_FILE='${TASK_FILE}' PACKAGE_NAME='${PACKAGE_NAME}' TASK_ID='${TASK_ID}'"

# Reminder about sourcing
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    echo ""
    echo "ℹ️  Note: Script executed, not sourced — exported vars won't persist"
    echo "➡️  Use: source taskdock-worktree-env.sh ${TASK_ID}"
fi
