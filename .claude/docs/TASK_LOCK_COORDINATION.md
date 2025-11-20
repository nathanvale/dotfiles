# Task Lock Coordination System

## Overview

Two-tier locking system for coordinating task execution across multiple terminals (local) and team
members (distributed).

## Architecture

### Tier 1: Local Lock Coordination

**Purpose:** Fast coordination for multiple terminal sessions on the same machine

**Location:** `~/.claude/projects/<project-id>/task-locks/`

**Example:**

```
~/.claude/projects/-Users-nathanvale-code-myproject/task-locks/
  ├── T0030.lock
  ├── T0031.lock
  └── T0032.lock
```

**Speed:** Instant (no network calls) **Scope:** Single developer, same machine

### Tier 2: GitHub Assignment (Optional)

**Purpose:** Distributed team coordination across machines

**Mechanism:** GitHub issue assignee field

**Example task file:**

```yaml
---
id: T0033
title: Add retry logic to API client
priority: P1
status: READY
created: 2025-11-17
github: https://github.com/myorg/myrepo/issues/145
---
## Description
Implement exponential backoff retry logic...
```

**Speed:** ~100-500ms (GitHub API call) **Scope:** All team members globally

## Usage

### Single Developer (Local Only)

**Task file (no GitHub field):**

```yaml
---
id: T0033
title: Add retry logic
priority: P1
status: READY
---
```

**Behavior:**

- ✅ Uses local locks only
- ✅ Coordinates multiple terminals on your machine
- ✅ Works offline
- ✅ No external dependencies

### Distributed Team (GitHub Integration)

**Task file (with GitHub field):**

```yaml
---
id: T0033
title: Add retry logic
priority: P1
status: READY
github: https://github.com/myorg/myrepo/issues/145
---
```

**Behavior:**

- ✅ Checks GitHub assignee before starting
- ✅ Self-assigns on GitHub when starting work
- ✅ Visible to all team members
- ✅ Also creates local lock for terminal coordination
- ✅ Unassigns on GitHub when task completes

**Requirements:**

```bash
# Install GitHub CLI
brew install gh

# Authenticate
gh auth login
```

## Lock Check Priority

When finding the next task, the system checks in this order:

1. **GitHub Assignment Check** (if `github:` field exists)

   ```bash
   gh issue view 145 --json assignees
   ```

   - If assigned to someone else → Skip task
   - If unassigned or assigned to you → Continue

2. **Local Lock Check**

   ```bash
   cat ~/.claude/projects/<id>/task-locks/T0033.lock
   ```

   - Extract PID, check if process is running
   - If locked by active process → Skip task
   - If stale lock (dead PID) → Remove and continue

3. **If both checks pass** → Task is available

## Workflow Examples

### Example 1: Solo Developer, Multiple Terminals

```bash
# Terminal 1
cd ~/code/myproject
/next
→ Finds T0030 (P0)
→ Checks local lock: None
→ Creates lock: ~/.claude/projects/.../T0030.lock
→ Creates worktree: .worktrees/T0030
→ Starts work...

# Terminal 2 (same time)
cd ~/code/myproject
/next
→ Finds T0030 (P0)
→ Checks local lock: Locked by PID 12345 (active) ✗
→ Skips to T0031 (P1)
→ Creates lock: ~/.claude/projects/.../T0031.lock
→ Creates worktree: .worktrees/T0031
```

**Result:** Zero conflicts, both terminals working on different tasks

### Example 2: Distributed Team with GitHub

```bash
# Developer A (New York) - 9am EST
cd ~/code/myproject
/next
→ Finds T0030 (P0)
→ Checks GitHub: Issue #145 unassigned ✓
→ Checks local lock: None ✓
→ Self-assigns GitHub issue #145
→ Creates local lock
→ Starts work...

# Developer B (London) - 2pm GMT (same moment)
cd ~/code/myproject
/next
→ Finds T0030 (P0)
→ Checks GitHub: Issue #145 assigned to Developer A ✗
→ Skips to T0031 (P1)
→ Checks GitHub: Issue #146 unassigned ✓
→ Self-assigns GitHub issue #146
→ Starts work...

# Developer C (Tokyo) - 11pm JST (same moment)
cd ~/code/myproject
/next
→ Finds T0030, T0031 both assigned on GitHub ✗
→ Selects T0032 (P2)
→ Checks GitHub: Issue #147 unassigned ✓
→ Self-assigns GitHub issue #147
→ Starts work...
```

**Result:** Perfect global coordination, zero duplicate work

## Lock File Format

```json
{
  "agentId": "nathanvale-agent-12345",
  "branch": "feat/T0033-add-retry-logic",
  "pid": 12345,
  "startedAt": "2025-11-17T20:30:00Z",
  "status": "IN_PROGRESS",
  "taskId": "T0033",
  "worktreePath": "./.worktrees/T0033"
}
```

## Lock Lifecycle

### 1. Selection Phase

- `find-next-task.sh` checks GitHub + local locks
- Skips tasks that are locked by either mechanism

### 2. Creation Phase

- `create-worktree.sh` creates local lock file
- If `github:` field exists → self-assigns on GitHub

### 3. Execution Phase

- Both locks remain active
- Other developers/terminals see task as unavailable

### 4. Completion Phase

- `/next` command Step 6.3:
  - Removes local lock file
  - Unassigns GitHub issue (if applicable)

### 5. Stale Lock Cleanup

- Dead PIDs automatically cleaned up
- Prevents indefinite blocking

## Benefits

| Feature                   | Local Only | With GitHub | Hybrid (Both)     |
| ------------------------- | ---------- | ----------- | ----------------- |
| Multi-terminal (same dev) | ✅ Fast    | ❌ Slow API | ✅ Fast local     |
| Distributed team          | ❌         | ✅          | ✅                |
| Works offline             | ✅         | ❌          | ✅ Fallback       |
| Team visibility           | ❌         | ✅          | ✅                |
| Performance               | ⚡ Instant | 🐌 ~200ms   | ⚡ Local, 🌐 Sync |

## Migration Path

### Phase 1: Start with Local Locks (No Changes Needed)

```yaml
---
id: T0033
status: READY
# No github field
---
```

Works immediately for single developer

### Phase 2: Add GitHub When Team Grows

```yaml
---
id: T0033
status: READY
github: https://github.com/myorg/myrepo/issues/145 # ← Add this line
---
```

Progressive enhancement, no breaking changes

## Troubleshooting

### Lock file won't remove

```bash
# Manually remove stale lock
source ~/.claude/scripts/lib/get-project-lock-dir.sh
LOCK_DIR=$(get_project_lock_dir)
rm -f "$LOCK_DIR/T0033.lock"
```

### GitHub CLI not authenticated

```bash
gh auth status
gh auth login
```

### Task assigned but developer not working on it

```bash
# Unassign on GitHub
gh issue edit 145 --remove-assignee @username
```

### Can't self-assign on GitHub

- Check repository permissions
- You may need write access
- Falls back to local locks only

## Industry Standard Pattern

This implements the pattern recommended by:

- **nginx/unit team**: "Use assignee field as a lock"
- **Stack Overflow consensus**: "Assign issue to yourself when working on it"
- **CCPM project**: Bidirectional sync with GitHub issues

## References

- Local lock location: `~/.claude/projects/<project-id>/task-locks/`
- Helper script: `~/.claude/scripts/lib/get-project-lock-dir.sh`
- Create worktree: `~/.claude/scripts/create-worktree.sh`
- Find next task: `~/.claude/scripts/find-next-task.sh`
- Command: `.claude/commands/next.md`
