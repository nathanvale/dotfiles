#!/usr/bin/env bash
# TaskDock Setup Script
# Makes all scripts executable

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Making TaskDock scripts executable..."

# Make bin scripts executable
chmod +x "$REPO_ROOT/bin/taskdock"
chmod +x "$REPO_ROOT/apps/taskdock/bin/taskdock"

# Make lib scripts sourceable (readable)
chmod +r "$REPO_ROOT/apps/taskdock/lib"/*.sh

# Make command scripts executable
find "$REPO_ROOT/apps/taskdock/commands" -name "*.sh" -exec chmod +x {} \;

# Make worktree scripts executable/sourceable
find "$REPO_ROOT/apps/taskdock/worktrees" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

# Make task scripts executable
find "$REPO_ROOT/apps/taskdock/tasks" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

# Make UX scripts executable
find "$REPO_ROOT/apps/taskdock/ux" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

# Make UX shims executable
[ -f "$REPO_ROOT/bin/taskdock-vscode" ] && chmod +x "$REPO_ROOT/bin/taskdock-vscode"

# Make test scripts executable
[ -f "$REPO_ROOT/apps/taskdock/tests/integration-test.sh" ] && chmod +x "$REPO_ROOT/apps/taskdock/tests/integration-test.sh"

echo "✅ TaskDock setup complete!"
echo ""
echo "Next steps:"
echo "  1. Add $REPO_ROOT/bin to your PATH if not already there"
echo "  2. Run 'taskdock doctor' to check dependencies"
echo "  3. Run 'taskdock init' in a git repo to get started"
