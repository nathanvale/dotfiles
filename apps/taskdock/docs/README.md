# TaskDock

**Agentic task orchestration and worktree management system**

TaskDock is a CLI tool for managing multi-agent development workflows using git worktrees, task locking, and structured validation. It provides a unified interface for task selection, worktree lifecycle, validation pipelines, and merge operations.

## Quick Start

### Installation

TaskDock is installed in your dotfiles at `$HOME/code/dotfiles/apps/taskdock/`.

1. **Run setup script:**
   ```bash
   cd ~/code/dotfiles
   ./apps/taskdock/setup.sh
   ```

2. **Verify installation:**
   ```bash
   taskdock version
   taskdock doctor
   ```

3. **Initialize a repository:**
   ```bash
   cd /path/to/your/repo
   taskdock init
   ```

### Basic Workflow

```bash
# 1. Get next available task
taskdock next

# 2. Create worktree for the task
taskdock worktree create T0001

# 3. Work on the task...
cd .worktrees/T0001

# 4. Keep lock alive during long operations
taskdock heartbeat T0001

# 5. Validate your changes
taskdock validate

# 6. Merge and cleanup
taskdock merge pr --current

# 7. Repeat
taskdock next
```

## Commands

### Core Commands

#### `taskdock init`
Initialize TaskDock in current repository. Creates `.taskdock/config.yaml` with required settings.

```bash
taskdock init
taskdock init --ticket-prefix PROJ
```

**Required on first use in each repository.**

---

#### `taskdock next`
Select and lock the next highest-priority READY task.

```bash
taskdock next
taskdock next --json
```

**Returns:**
- Task ID, title, priority, file path
- Automatically creates lock file
- Checks dependencies before selection

---

#### `taskdock worktree create <task-id>`
Create git worktree for a task.

```bash
taskdock worktree create T0001
taskdock worktree create T0001 apps/api
taskdock worktree create T0001 --no-install
```

**Features:**
- Auto-detects monorepo vs single-repo
- Finds task file automatically
- Creates feature branch (`feat/T0001-...`)
- Installs dependencies (unless `--no-install`)
- Updates lock metadata

---

#### `taskdock validate`
Run validation checks on worktree.

```bash
taskdock validate
taskdock validate /path/to/worktree
taskdock validate /path/to/worktree my-package
```

**Runs:**
- Format check (`format` script)
- Type checking (`typecheck` script) - **REQUIRED**
- Linting (`lint` script)
- Tests (`test` script) - **REQUIRED**

**Configurable via `.taskdock/config.yaml`:**
```yaml
validation:
  run_format: true
  run_typecheck: true
  run_lint: true
  run_tests: true
```

---

#### `taskdock merge pr [PR_NUM|TASK_ID|--current]`
Merge PR and perform complete cleanup.

```bash
taskdock merge pr --current        # Merge current branch's PR
taskdock merge pr 123              # Merge PR #123
taskdock merge pr T0001            # Merge task T0001's PR
```

**Supports:**
- GitHub (via `gh` CLI)
- Azure DevOps (via `az` CLI)
- Auto-detection of git provider

**Performs:**
- PR status verification
- Merge to main
- Remote branch deletion
- Local branch deletion
- Worktree removal
- Lock cleanup

---

#### `taskdock merge manual [branch]`
Manual merge without PR (for quick fixes).

```bash
taskdock merge manual              # Merge current branch
taskdock merge manual feat/my-fix  # Merge specific branch
```

**Includes confirmation prompt before proceeding.**

---

### Worktree Management

#### `taskdock worktree list`
List all active worktrees with status.

```bash
taskdock worktree list
taskdock worktree list --json
```

**Shows:**
- Task ID and path
- Branch name
- Lock status
- Commit count
- Uncommitted changes

---

#### `taskdock worktree status [task-id]`
Show detailed status for a worktree.

```bash
taskdock worktree status           # All worktrees
taskdock worktree status T0001     # Specific task
```

---

#### `taskdock worktree cleanup`
Clean up merged worktrees.

```bash
taskdock worktree cleanup
taskdock worktree cleanup --force   # Force remove with changes
taskdock worktree cleanup --quiet   # Minimal output
```

**Automatically:**
- Detects merged branches
- Removes worktrees
- Deletes branches
- Cleans lock files

---

### Lock Management

#### `taskdock locks list`
List all active task locks.

```bash
taskdock locks list
taskdock locks list --json
```

---

#### `taskdock locks unlock <task-id>`
Remove lock for a specific task.

```bash
taskdock locks unlock T0001
```

---

#### `taskdock locks cleanup`
Remove stale locks based on heartbeat age.

```bash
taskdock locks cleanup
taskdock locks cleanup --quiet
```

**Default max age: 30 minutes (configurable)**

---

#### `taskdock heartbeat <task-id>`
Update task lock heartbeat timestamp.

```bash
taskdock heartbeat T0001
taskdock heartbeat T0001 --quiet
```

**Use during long-running operations to prevent lock from becoming stale.**

---

### Configuration

#### `taskdock config show`
Display merged configuration (all sources).

```bash
taskdock config show
taskdock config show --json
```

---

#### `taskdock config get <key>`
Get specific config value.

```bash
taskdock config get ticket_prefix
taskdock config get worktree_root
taskdock config get validation.run_tests
```

---

#### `taskdock config set <key> <value>`
Update repo configuration.

```bash
taskdock config set ticket_prefix PROJ
taskdock config set lock_max_age_minutes 45
```

---

#### `taskdock config check`
Validate required configuration.

```bash
taskdock config check
```

---

### Observability

#### `taskdock logs`
View TaskDock telemetry logs.

```bash
taskdock logs
taskdock logs --tail 50
taskdock logs --follow
taskdock logs --command next
taskdock logs --correlation-id abc123
taskdock logs --repo
taskdock logs --all
```

**Features:**
- Structured newline-delimited JSON
- Correlation IDs for request tracing
- Command filtering
- Follow mode (tail -f)

---

#### `taskdock doctor`
Check system dependencies and health.

```bash
taskdock doctor
taskdock doctor --json
```

**Checks:**
- Git installation
- jq, yq, pnpm availability
- Repository initialization status
- Active locks count
- Working tree status

---

#### `taskdock version`
Show TaskDock version.

```bash
taskdock version
```

---

## Configuration

TaskDock uses a 5-level configuration hierarchy:

1. **Defaults** - `taskdock/config/defaults.yaml`
2. **User** - `$HOME/.taskdock/config.yaml` (not yet implemented)
3. **Repo** - `.taskdock/config.yaml` (created by `taskdock init`)
4. **Environment** - `TASKDOCK_*` variables
5. **Flags** - Command-line arguments

Later sources override earlier ones.

### Required Configuration

```yaml
ticket_prefix: "PROJ"  # Required: Task ID prefix
```

### Optional Configuration

```yaml
# Task management
task_directory: "docs/tasks"      # Where task files live
lock_max_age_minutes: 30          # Stale lock threshold

# Worktree settings
worktree_root: ".worktrees"       # Worktree location
branch_prefix: "feat"             # Branch prefix

# Git settings
default_branch: "main"            # Main branch name
git_provider: "auto"              # "auto", "github", or "azure"

# Validation
validation:
  run_format: true                # Run formatters
  run_typecheck: true             # Run type checking
  run_lint: true                  # Run linting
  run_tests: true                 # Run tests

# Telemetry
telemetry_enabled: true           # Enable logging
log_retention_days: 7             # Log retention

# Output
default_output_format: "human"    # "human" or "json"
```

---

## Agent-Friendly Features

TaskDock is designed for AI agent interactions:

### JSON Output Mode

All commands support `--json` flag for machine-readable output:

```bash
taskdock next --json
taskdock worktree list --json
taskdock validate --json
```

**Or set globally:**
```bash
export TASKDOCK_OUTPUT=json
```

### Structured Telemetry

All operations logged with correlation IDs:

```json
{
  "timestamp": "2025-11-19T10:30:00Z",
  "correlationId": "550e8400-e29b-41d4-a716-446655440000",
  "command": "next",
  "event": "task_selected",
  "taskId": "T0001",
  "data": {"priority": "P0", "title": "Fix login bug"}
}
```

### Exit Codes

Standardized exit codes for scripting:

- `0` - Success
- `10` - Configuration missing
- `20` - Lock busy
- `30` - Validation failed
- `40` - Git error
- `50` - Dependency missing
- `60` - Invalid arguments

### Error Messages

Actionable error messages with suggestions:

```
❌ ERROR: Repository not initialized
💡 TIP: Run 'taskdock init' to set up this repository
```

---

## VS Code Integration

TaskDock provides a VS Code wrapper for seamless integration:

```bash
taskdock-vscode
```

**This command:**
1. Finds next available task
2. Creates worktree
3. Opens worktree in new VS Code window

**Or add as VS Code task** (`.vscode/tasks.json`):

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "TaskDock: Next Task",
      "type": "shell",
      "command": "taskdock-vscode",
      "problemMatcher": []
    }
  ]
}
```

---

## Task File Format

TaskDock expects task files in markdown with YAML frontmatter:

```markdown
---
id: T0001
title: Fix login bug
status: READY
priority: P0
depends_on: []
assigned_to: ""
github: https://github.com/org/repo/issues/123
---

# P0: Fix login bug

## Description
Users cannot log in with email addresses...

## Acceptance Criteria
- [ ] Login with email works
- [ ] Error messages are clear
- [ ] Tests pass

## Technical Notes
Check the authentication middleware...
```

### Task Statuses

- `READY` - Available for selection
- `IN_PROGRESS` - Currently being worked on
- `COMPLETED` - Finished and merged
- `BLOCKED` - Waiting on dependencies

### Priority Levels

- `P0` - Critical (highest priority)
- `P1` - High
- `P2` - Medium
- `P3` - Low (default)

---

## Architecture

### Directory Structure

```
taskdock/
├── bin/
│   └── taskdock              # Main CLI dispatcher
├── commands/                 # Command implementations
│   ├── init.sh
│   ├── next.sh
│   ├── worktree.sh
│   ├── validate.sh
│   ├── merge.sh
│   ├── locks.sh
│   ├── config.sh
│   ├── logs.sh
│   ├── doctor.sh
│   ├── heartbeat.sh
│   └── version.sh
├── lib/                      # Shared libraries
│   ├── common.sh             # Core utilities
│   ├── ui.sh                 # Output formatting
│   ├── logging.sh            # Telemetry
│   ├── config.sh             # Configuration
│   ├── git.sh                # Git operations
│   ├── locks.sh              # Lock management
│   └── guards.sh             # Execution guards
├── tasks/                    # Task selection logic
│   └── selector.sh
├── worktrees/                # Worktree utilities
│   └── setup-env.sh
├── ux/                       # User experience wrappers
│   └── vscode-next.sh
├── config/
│   └── defaults.yaml         # Default configuration
├── docs/
│   └── README.md             # This file
└── setup.sh                  # Installation script
```

### Key Concepts

**Front-Door Pattern:**
All commands route through `taskdock` CLI for consistency.

**Guard System:**
Commands verify repository initialization before execution.

**Correlation IDs:**
All operations tagged with unique ID for tracing.

**Dual Output:**
Human-friendly and JSON modes for all commands.

**Lock Heartbeats:**
Prevent stale locks during long-running operations.

---

## Troubleshooting

### Repository Not Initialized

```
❌ ERROR: Repository not initialized
```

**Solution:**
```bash
taskdock init
```

---

### No Tasks Available

```
⚠️  No READY tasks found
```

**Check:**
1. Task files exist in `docs/tasks/`
2. Tasks have `status: READY`
3. Dependencies are met

---

### Lock Already Exists

```
❌ ERROR: Task T0001 is already locked
```

**Check:**
```bash
taskdock locks list
```

**Unlock if stale:**
```bash
taskdock locks unlock T0001
# or
taskdock locks cleanup
```

---

### Validation Failures

```
❌ Typecheck failed
```

**Fix issues and re-run:**
```bash
taskdock validate
```

**Never mark task as COMPLETED with failing validation.**

---

### Merge Conflicts

```
❌ PR has merge conflicts
```

**Resolution:**
1. Pull latest main
2. Resolve conflicts
3. Push to branch
4. Re-run merge

---

## Contributing

TaskDock follows strict error handling patterns:

- All scripts use `set -euo pipefail`
- All functions return proper exit codes
- All errors have actionable messages
- All operations are logged

---

## License

Part of nathanvale's dotfiles configuration.

---

## Concurrency Safety

TaskDock implements comprehensive concurrency protection for multi-agent workflows:

- **flock-based locking**: Prevents race conditions during task selection, config updates, and log writes
- **Repo-level locks**: Shared across all worktrees via `.git/taskdock-locks/`
- **Automatic cleanup**: Stale locks removed after timeout
- **Zero data corruption**: All critical sections properly protected

For detailed information, see [CONCURRENCY.md](CONCURRENCY.md).

---

## Future Plans

- [ ] User-level configuration (`$HOME/.taskdock/config.yaml`)
- [ ] Telemetry privacy controls
- [x] Concurrency safety with flock
- [x] Cross-shell compatibility audit (bash 4.0+ documented)
- [ ] Test fixtures and harness
- [ ] GitHub Actions integration
- [ ] Task templates
- [ ] Dependency graph visualization
- [ ] Multi-repo coordination
- [ ] Auto-merge on validation success

---

**Version:** 0.1.0
**Last Updated:** 2025-11-19
