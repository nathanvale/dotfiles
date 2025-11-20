#!/usr/bin/env bash
# Legacy Claude Scripts Cleanup
# Archives old scripts and creates stub redirects

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LEGACY_DIR="${DOTFILES_ROOT}/.claude/scripts"
ARCHIVE_DIR="${DOTFILES_ROOT}/.claude/scripts.archived-$(date +%Y%m%d-%H%M%S)"
TASKDOCK_DIR="${DOTFILES_ROOT}/taskdock"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}TaskDock Legacy Cleanup${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ ! -d "$LEGACY_DIR" ]; then
    echo -e "${YELLOW}No legacy scripts found at ${LEGACY_DIR}${NC}"
    exit 0
fi

echo -e "${BLUE}This will:${NC}"
echo "  1. Archive legacy scripts to: ${ARCHIVE_DIR}"
echo "  2. Create stub redirects for common scripts"
echo "  3. Update documentation references"
echo ""
echo -e "${YELLOW}Press Ctrl+C to cancel, or Enter to continue...${NC}"
read -r

# Create archive directory
echo ""
echo -e "${BLUE}Archiving legacy scripts...${NC}"
mkdir -p "$ARCHIVE_DIR"

# Copy everything to archive
cp -R "${LEGACY_DIR}"/* "$ARCHIVE_DIR/"
echo -e "${GREEN}✓${NC} Archived to: ${ARCHIVE_DIR}"

# Remove old scripts but keep the directory structure
echo ""
echo -e "${BLUE}Removing legacy scripts...${NC}"

# List of scripts that have been ported to TaskDock
PORTED_SCRIPTS=(
    "parse-next-task.sh"
    "select-and-lock-task.sh"
    "next-task-id.sh"
    "find-next-task.sh"
    "create-worktree.sh"
    "setup-task-context.sh"
    "update-lock-heartbeat.sh"
    "worktree-status.sh"
    "validate-worktree.sh"
    "merge-pr.sh"
    "manual-merge.sh"
    "cleanup-merged-worktrees.sh"
    "cleanup-task-lock.sh"
    "cleanup-stale-locks.sh"
    "clean-stale-locks.sh"
    "list-task-locks.sh"
    "unlock-task.sh"
    "vscode-next.sh"
)

for script in "${PORTED_SCRIPTS[@]}"; do
    if [ -f "${LEGACY_DIR}/${script}" ]; then
        rm -f "${LEGACY_DIR}/${script}"
        echo -e "${GREEN}✓${NC} Removed: ${script}"
    fi
done

# Remove lib directory (all functions ported to taskdock/lib)
if [ -d "${LEGACY_DIR}/lib" ]; then
    rm -rf "${LEGACY_DIR}/lib"
    echo -e "${GREEN}✓${NC} Removed: lib/"
fi

# Create stub redirects for commonly used scripts
echo ""
echo -e "${BLUE}Creating stub redirects...${NC}"

# Stub for vscode-next.sh
cat > "${LEGACY_DIR}/vscode-next.sh" << 'EOF'
#!/usr/bin/env bash
# DEPRECATED: This script has moved to TaskDock
# Use: taskdock-vscode

echo "⚠️  This script is deprecated and has moved to TaskDock"
echo ""
echo "Use instead: taskdock-vscode"
echo ""
echo "For more information:"
echo "  taskdock --help"
echo "  taskdock worktree --help"
echo ""
exit 1
EOF
chmod +x "${LEGACY_DIR}/vscode-next.sh"
echo -e "${GREEN}✓${NC} Created stub: vscode-next.sh"

# Stub for next task workflow
cat > "${LEGACY_DIR}/next-task.sh" << 'EOF'
#!/usr/bin/env bash
# DEPRECATED: This script has moved to TaskDock
# Use: taskdock next

echo "⚠️  This script is deprecated and has moved to TaskDock"
echo ""
echo "Complete workflow:"
echo "  taskdock next                  # Select next task"
echo "  taskdock worktree create T0001 # Create worktree"
echo "  taskdock validate              # Validate changes"
echo "  taskdock merge pr --current    # Merge and cleanup"
echo ""
echo "For more information:"
echo "  taskdock --help"
echo ""
exit 1
EOF
chmod +x "${LEGACY_DIR}/next-task.sh"
echo -e "${GREEN}✓${NC} Created stub: next-task.sh"

# Create README in legacy directory
cat > "${LEGACY_DIR}/README.md" << 'EOF'
# DEPRECATED: Claude Scripts

**This directory is deprecated.** All scripts have been migrated to TaskDock.

## Migration Notice

The Claude scripts automation system has been reorganized into **TaskDock**, a more robust and maintainable system located at `taskdock/`.

### What Changed

- **Old location**: `.claude/scripts/`
- **New location**: `taskdock/`
- **New entry point**: `taskdock` command (in PATH)

### Migration Path

All functionality has been preserved and improved:

| Old Script | New Command |
|------------|-------------|
| `parse-next-task.sh` | `taskdock next` |
| `select-and-lock-task.sh` | `taskdock next` |
| `create-worktree.sh` | `taskdock worktree create` |
| `worktree-status.sh` | `taskdock worktree list` |
| `validate-worktree.sh` | `taskdock validate` |
| `merge-pr.sh` | `taskdock merge pr` |
| `manual-merge.sh` | `taskdock merge manual` |
| `cleanup-merged-worktrees.sh` | `taskdock worktree cleanup` |
| `list-task-locks.sh` | `taskdock locks list` |
| `unlock-task.sh` | `taskdock locks unlock` |
| `cleanup-stale-locks.sh` | `taskdock locks cleanup` |
| `vscode-next.sh` | `taskdock-vscode` |

### Getting Started with TaskDock

```bash
# View all commands
taskdock --help

# Initialize a repository
taskdock init

# Complete workflow
taskdock next                  # Select task
taskdock worktree create T0001 # Create worktree
taskdock validate              # Validate changes
taskdock merge pr --current    # Merge and cleanup
```

### Documentation

- **Main docs**: `taskdock/docs/README.md`
- **Quick start**: `taskdock/README.md`
- **Configuration**: `taskdock config --help`

### Archived Scripts

Old scripts archived at: `.claude/scripts.archived-[timestamp]/`

### Keep Files

The following files remain for compatibility:
- `detect-git-provider.sh` - Still used by some external tools
- Helper scripts in specific project directories

---

**Migration Date**: 2025-11-19
**TaskDock Version**: 0.1.0
EOF
echo -e "${GREEN}✓${NC} Created: README.md"

# Keep detect-git-provider.sh as it might be used elsewhere
if [ -f "${LEGACY_DIR}/detect-git-provider.sh" ]; then
    echo -e "${YELLOW}⚠${NC}  Kept: detect-git-provider.sh (still in use)"
fi

# Update main .claude docs if they exist
echo ""
echo -e "${BLUE}Updating documentation references...${NC}"

if [ -f "${DOTFILES_ROOT}/.claude/docs/scripts.md" ]; then
    cat > "${DOTFILES_ROOT}/.claude/docs/scripts.md" << 'EOF'
# Scripts Documentation

**Note**: The `.claude/scripts/` directory has been deprecated.

All task orchestration functionality has moved to **TaskDock**.

See: `taskdock/docs/README.md` for complete documentation.

## Quick Reference

```bash
taskdock --help              # Show all commands
taskdock init                # Initialize repository
taskdock next                # Get next task
taskdock worktree create     # Create worktree
taskdock validate            # Run validation
taskdock merge pr            # Merge and cleanup
```

For legacy scripts archive, see: `.claude/scripts.archived-[timestamp]/`
EOF
    echo -e "${GREEN}✓${NC} Updated: .claude/docs/scripts.md"
fi

# Summary
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ Legacy Cleanup Complete${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}Archived:${NC}"
echo "  ${ARCHIVE_DIR}"
echo ""
echo -e "${GREEN}Removed Scripts:${NC}"
echo "  ${#PORTED_SCRIPTS[@]} scripts ported to TaskDock"
echo ""
echo -e "${GREEN}Stub Redirects Created:${NC}"
echo "  vscode-next.sh → taskdock-vscode"
echo "  next-task.sh → taskdock next"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "  1. Test TaskDock commands in your workflows"
echo "  2. Update any external scripts that reference old paths"
echo "  3. Delete archive after confirming everything works"
echo ""
echo -e "${YELLOW}To rollback if needed:${NC}"
echo "  cp -R ${ARCHIVE_DIR}/* ${LEGACY_DIR}/"
echo ""
