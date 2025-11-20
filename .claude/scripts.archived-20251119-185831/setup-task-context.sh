#!/usr/bin/env bash
set -euo pipefail

# setup-task-context.sh
# Deterministic mandatory task setup for /next Step 5.0
# Usage (must be sourced to persist exports):
#   source ~/.claude/scripts/setup-task-context.sh T0044
#   source ~/.claude/scripts/setup-task-context.sh T0044 /path/to/main/repo  # Optional: explicit repo path
# Exports: MAIN_REPO, WORKTREE_ROOT, TASK_FILE, PACKAGE_NAME

TASK_ID="${1:-}"
MAIN_REPO_ARG="${2:-}"

if [ -z "${TASK_ID}" ]; then
  echo "❌ ERROR: TASK_ID argument required (e.g. T0044)"
  return 1 2>/dev/null || exit 1
fi

# Determine main repo root
# Option 1: Use provided argument
if [ -n "${MAIN_REPO_ARG}" ]; then
  MAIN_REPO="${MAIN_REPO_ARG}"
# Option 2: Auto-detect via git (handles worktree context)
elif MAIN_REPO=$(git rev-parse --show-superproject-working-tree 2>/dev/null); then
  :
elif MAIN_REPO=$(git rev-parse --show-toplevel 2>/dev/null); then
  :
# Option 3: Check if pwd looks like a repo root
elif [ -d "$(pwd)/.git" ] || [ -f "$(pwd)/.git" ]; then
  MAIN_REPO=$(pwd)
else
  MAIN_REPO=""
fi

if [ -z "${MAIN_REPO}" ] || [ ! -d "${MAIN_REPO}" ]; then
  echo "❌ ERROR: Could not determine repository root via git"
  echo "Current directory: $(pwd)"
  echo "Usage: source ~/.claude/scripts/setup-task-context.sh TASK_ID [MAIN_REPO_PATH]"
  echo "Example: source ~/.claude/scripts/setup-task-context.sh T0044 /Users/nathanvale/code/my-project"
  return 1 2>/dev/null || exit 1
fi

WORKTREE_ROOT="${MAIN_REPO}/.worktrees/${TASK_ID}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 SETUP: Task Context Initialization"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Repo:        ${MAIN_REPO}"
echo "Worktree:    ${WORKTREE_ROOT}"
echo "Task ID:     ${TASK_ID}"
echo ""

if [ ! -d "${WORKTREE_ROOT}" ]; then
  echo "❌ ERROR: Worktree not found at ${WORKTREE_ROOT}"
  echo "➡️  Run: ~/.claude/scripts/create-worktree.sh ${TASK_ID} [optional-package]"
  return 1 2>/dev/null || exit 1
fi

# Dependency presence check (node projects)
if [ -f "${WORKTREE_ROOT}/package.json" ] && [ ! -d "${WORKTREE_ROOT}/node_modules" ]; then
  echo "❌ ERROR: Dependencies not installed in worktree"
  echo "➡️  Re-run create-worktree script; it handles install deterministically"
  return 1 2>/dev/null || exit 1
fi

# Resolve task file with priority order
TASK_FILE=""

# 1. Direct docs/tasks root
for match in "${WORKTREE_ROOT}/docs/tasks/${TASK_ID}-"*.md; do
  if [ -f "${match}" ]; then
    TASK_FILE="${match}"
    break
  fi
done

# 2. apps/*/docs/tasks
if [ -z "${TASK_FILE}" ]; then
  if [ -d "${WORKTREE_ROOT}/apps" ]; then
    while IFS= read -r -d '' candidate; do
      TASK_FILE="${candidate}"; break
    done < <(find "${WORKTREE_ROOT}/apps" -maxdepth 4 -type f -name "${TASK_ID}-*.md" -path "*/docs/tasks/*" -print0 2>/dev/null || true)
  fi
fi

# 3. packages/*/docs/tasks
if [ -z "${TASK_FILE}" ]; then
  if [ -d "${WORKTREE_ROOT}/packages" ]; then
    while IFS= read -r -d '' candidate; do
      TASK_FILE="${candidate}"; break
    done < <(find "${WORKTREE_ROOT}/packages" -maxdepth 4 -type f -name "${TASK_ID}-*.md" -path "*/docs/tasks/*" -print0 2>/dev/null || true)
  fi
fi

if [ -z "${TASK_FILE}" ]; then
  echo "❌ ERROR: Task file for ${TASK_ID} not found inside worktree"
  return 1 2>/dev/null || exit 1
fi

# Monorepo package name detection (pnpm workspace heuristic)
PACKAGE_NAME=""
if [ -f "${WORKTREE_ROOT}/pnpm-workspace.yaml" ]; then
  rel_path="${TASK_FILE#${WORKTREE_ROOT}/}"
  IFS='/' read -r first second _rest <<< "${rel_path}"
  if [ "${first}" = "apps" ] || [ "${first}" = "packages" ]; then
    PACKAGE_NAME="${second}"
  fi
fi

echo "📄 Task file: ${TASK_FILE}"
if [ -n "${PACKAGE_NAME}" ]; then
  echo "📦 Package:   ${PACKAGE_NAME}"
else
  echo "📦 Package:   (single-repo / none)"
fi
echo ""
echo "✅ Context initialized"

export MAIN_REPO
export WORKTREE_ROOT
export TASK_FILE
export PACKAGE_NAME

# Machine-readable summary line
echo "::setup:: MAIN_REPO='${MAIN_REPO}' WORKTREE_ROOT='${WORKTREE_ROOT}' TASK_FILE='${TASK_FILE}' PACKAGE_NAME='${PACKAGE_NAME}'"

# Warn if not sourced
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  echo "ℹ️  Note: Script executed, not sourced — exported vars won't persist in parent shell."
  echo "➡️  Use: source ~/.claude/scripts/setup-task-context.sh ${TASK_ID}"
fi
