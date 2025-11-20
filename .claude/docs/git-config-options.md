# Git Config Options for Parallel Claude Agents

Git configuration options that control parallel agent behavior, worktree management, and resource
limits. Compatible with git-worktree-runner (gtr) naming conventions.

---

## Quick Reference

```bash
# Parallel agent configuration
git config --local gtr.parallel.default 4      # Default number of agents
git config --local gtr.parallel.max 10         # Max concurrent agents
git config --local gtr.parallel.stagger 2      # Delay between launches (seconds)
git config --local gtr.parallel.auto true      # Auto-launch Claude in panes

# Worktree configuration
git config --local gtr.worktree.path "./.worktrees"  # Worktree base directory

# Dependency installation (NEW)
git config --local claude.worktree.autoInstall true   # Auto-install dependencies
git config --local claude.hook.postCreate "npm test"  # Post-create hook command

# Tmux integration (future use)
git config --local gtr.tmux.enabled true       # Enable tmux integration
git config --local gtr.tmux.mode manual        # Tmux launch mode
```

---

## Configuration Options

### `gtr.parallel.default`

**Type:** Integer **Default:** `4` **Scope:** Local or global

Default number of parallel agents to launch when not specified on command line.

**Usage:**

```bash
# Set default to 6 agents
git config --local gtr.parallel.default 6

# Launch with default (6 agents)
~/code/dotfiles/bin/tmux/parallel-claude.sh

# Override default with command line
~/code/dotfiles/bin/tmux/parallel-claude.sh 10  # Launches 10 agents
```

**When to use:**

- Set per-project based on typical workload
- Larger projects → higher default
- Resource-constrained systems → lower default

**Examples:**

```bash
# Small project with few concurrent tasks
git config --local gtr.parallel.default 2

# Large enterprise monorepo
git config --local gtr.parallel.default 8

# Personal laptop
git config --global gtr.parallel.default 4
```

---

### `gtr.parallel.max`

**Type:** Integer **Default:** `50` **Scope:** Local or global

Maximum number of concurrent agents allowed. Prevents resource exhaustion.

**Usage:**

```bash
# Limit to 6 agents max
git config --local gtr.parallel.max 6

# Try to launch 10 agents
~/code/dotfiles/bin/tmux/parallel-claude.sh 10
# Output: Warning: Requested 10 agents exceeds max (6). Using 6.
```

**Resource-based recommendations:**

| System    | Max Agents | Rationale                 |
| --------- | ---------- | ------------------------- |
| 8GB RAM   | 2-4        | Prevent memory exhaustion |
| 16GB RAM  | 4-8        | Moderate parallel work    |
| 32GB RAM  | 8-16       | High parallel capacity    |
| 64GB+ RAM | 16-50      | Max throughput            |

**Usage in find-next-task.sh:**

If `gtr.parallel.max` is set, `find-next-task.sh` will refuse to select a new task when max
concurrent agents are running:

```bash
# Set max to 4
git config --local gtr.parallel.max 4

# Launch 4 agents - all get tasks
# Try to launch 5th agent - find-next-task.sh returns:
# "Max parallel agents reached (4/4)"
```

**Examples:**

```bash
# Laptop development
git config --global gtr.parallel.max 4

# Workstation for CI/CD
git config --local gtr.parallel.max 20

# Prevent accidents on resource-constrained systems
git config --global gtr.parallel.max 6
```

---

### `gtr.parallel.stagger`

**Type:** Integer (seconds) **Default:** `2` **Scope:** Local or global

Delay in seconds between launching each agent to prevent race conditions.

**Usage:**

```bash
# Increase stagger to 3 seconds
git config --local gtr.parallel.stagger 3

# Launch 4 agents:
# Agent 1: 0s
# Agent 2: 3s
# Agent 3: 6s
# Agent 4: 9s
```

**Why stagger matters:**

Without stagger, all agents run `find-next-task.sh` simultaneously and may select the same task
before locks are created.

**Recommended values:**

| Filesystem Speed | Stagger | Reason                   |
| ---------------- | ------- | ------------------------ |
| Fast SSD         | 1-2s    | Quick lock file creation |
| Network mount    | 3-5s    | Slower lock propagation  |
| Slow HDD         | 2-4s    | Moderate I/O latency     |

**Examples:**

```bash
# Fast local SSD
git config --local gtr.parallel.stagger 1

# Network-mounted project directory
git config --local gtr.parallel.stagger 5

# Default (safe for most systems)
git config --local gtr.parallel.stagger 2
```

---

### `gtr.parallel.auto`

**Type:** Boolean **Default:** `true` **Scope:** Local or global

Automatically launch Claude in each pane, or require manual launch.

**Usage:**

```bash
# Disable auto-launch
git config --local gtr.parallel.auto false

# Launch agents
~/code/dotfiles/bin/tmux/parallel-claude.sh 4
# Creates 4 panes but doesn't run 'claude' - user must manually start
```

**When to disable:**

- Want to review task list before launching
- Need to prepare environment variables first
- Debugging worktree setup issues
- Running pre-flight checks

**Examples:**

```bash
# Auto-launch enabled (default)
git config --local gtr.parallel.auto true
# Ctrl-g P → 4 → agents launch automatically

# Manual launch
git config --local gtr.parallel.auto false
# Ctrl-g P → 4 → panes created, manually run 'claude' in each
```

---

### `gtr.worktree.path`

**Type:** String (path) **Default:** `./.worktrees` **Scope:** Local or global

Base directory for creating task worktrees.

**Usage:**

```bash
# Use different path
git config --local gtr.worktree.path "../worktrees"

# Create worktree for T0001
~/.claude/scripts/create-worktree.sh T0001
# Creates: ../worktrees/T0001/
```

**Common patterns:**

```bash
# Default: Inside repo
gtr.worktree.path = "./.worktrees"
# Result: /Users/you/code/myproject/.worktrees/T0001/

# Sibling directory
gtr.worktree.path = "../worktrees"
# Result: /Users/you/code/worktrees/T0001/

# Absolute path
gtr.worktree.path = "/tmp/worktrees"
# Result: /tmp/worktrees/T0001/
```

**Examples:**

```bash
# Keep worktrees with main repo (default)
git config --local gtr.worktree.path "./.worktrees"

# Organize all worktrees in parent directory
git config --local gtr.worktree.path "../${PWD##*/}-worktrees"
# For project "myapp": ../myapp-worktrees/T0001/

# Use temp directory (ephemeral work)
git config --local gtr.worktree.path "/tmp/worktrees"
```

---

### `claude.worktree.autoInstall`

**Type:** Boolean **Default:** `true` **Scope:** Local or global

Automatically install dependencies when creating a worktree. When disabled, dependency installation
is skipped unless explicitly requested.

**Usage:**

```bash
# Disable auto-install for this project
git config --local claude.worktree.autoInstall false

# Create worktree without installing dependencies
~/.claude/scripts/create-worktree.sh T0001

# Override with flag (works even if config says true)
~/.claude/scripts/create-worktree.sh T0001 --no-install
```

**When to disable:**

- Working on documentation-only changes
- Using CI-centric workflow (rely on CI for builds)
- Testing worktree creation speed
- Working in environment without network access

**Benefits of pnpm with worktrees:**

- **Global store with symlinks** - pnpm maintains a single content-addressable store at
  `~/.pnpm-store`
- **No duplicate installs** - Worktrees symlink to global store instead of copying node_modules
- **Instant installs** - If packages already in global store, install is nearly instant
- **Disk space savings** - Multiple worktrees share the same physical packages

**Examples:**

```bash
# Default: auto-install enabled
git config --local claude.worktree.autoInstall true
~/.claude/scripts/create-worktree.sh T0001
# Output: Installing dependencies...
#         ✓ Dependencies installed

# Disable auto-install
git config --local claude.worktree.autoInstall false
~/.claude/scripts/create-worktree.sh T0002
# Output: ⏭️  Skipping dependency installation (disabled via config)

# Override config with flag
git config --local claude.worktree.autoInstall true
~/.claude/scripts/create-worktree.sh T0003 --no-install
# Output: ⏭️  Skipping dependency installation (disabled via --no-install flag)
```

---

### `claude.hook.postCreate`

**Type:** String (shell command) **Default:** `""` **Scope:** Local or global

Execute custom shell command after worktree creation completes. Similar to GTR's hook system, but
Claude-specific.

**Usage:**

```bash
# Simple hook: show message
git config --local claude.hook.postCreate 'echo "Worktree ready for $TASK_ID"'

# Multiple commands
git config --local claude.hook.postCreate 'npm run build && npm test'

# Hook script
git config --local claude.hook.postCreate '~/.claude/hooks/post-create.sh'
```

**Available environment variables:**

```bash
WORKTREE_PATH       # Relative path (e.g., ./.worktrees/T0001)
WORKTREE_ABS_PATH   # Absolute path (e.g., /Users/you/project/.worktrees/T0001)
TASK_ID             # Task ID (e.g., T0001)
BRANCH_NAME         # Git branch name (e.g., task/T0001)
TASK_FILE_PATH      # Relative path to task file
PKG_MGR             # Package manager (npm, yarn, pnpm, bun)
IS_MONOREPO         # "true" or "false"
```

**Example hook script** (`~/.claude/hooks/post-create.sh`):

```bash
#!/bin/bash
# Post-create hook example

echo "🎯 Task: $TASK_ID"
echo "📦 Using: $PKG_MGR"
echo "📁 Path: $WORKTREE_PATH"

# Conditional logic based on monorepo
if [ "$IS_MONOREPO" = "true" ] && [ "$PKG_MGR" = "pnpm" ]; then
    echo "Running build in monorepo package..."
    pnpm build --filter "$PACKAGE_NAME"
fi

# Create .env from template
if [ -f ".env.template" ]; then
    cp .env.template .env
    echo "✓ Created .env from template"
fi
```

**Common use cases:**

- Run initial build or tests
- Copy environment files (.env)
- Notify team via Slack/Discord
- Update project-specific metadata
- Warm up caches

**Error handling:**

- Hook failures are non-fatal - worktree is still created
- Exit code and error message are displayed
- Worktree remains usable even if hook fails

**Examples:**

```bash
# Build after creation (monorepo)
git config --local claude.hook.postCreate 'pnpm build'

# Setup environment + build
git config --local claude.hook.postCreate 'cp .env.example .env && npm run build'

# Team notification
git config --local claude.hook.postCreate 'curl -X POST $SLACK_WEBHOOK -d "{\"text\":\"Started $TASK_ID\"}"'

# Script with error handling
cat > ~/.claude/hooks/post-create.sh <<'EOF'
#!/bin/bash
set -e

echo "Setting up worktree for $TASK_ID..."

# Copy secrets
[ -f ../.env.secrets ] && cp ../.env.secrets .env

# Build if needed
if [ -f "package.json" ]; then
    echo "Running build..."
    $PKG_MGR run build
fi

echo "✓ Hook completed successfully"
EOF

chmod +x ~/.claude/hooks/post-create.sh
git config --local claude.hook.postCreate '~/.claude/hooks/post-create.sh'
```

---

### `gtr.tmux.enabled` (Future)

**Type:** Boolean **Default:** `false` **Scope:** Local or global

Enable tmux-specific integrations (currently read but not actively used).

**Usage:**

```bash
git config --local gtr.tmux.enabled true
```

**Future planned features:**

- Auto-create tmux window after worktree creation
- Launch Claude in new tmux pane automatically
- Integrate with tmux session management

---

### `gtr.tmux.mode` (Future)

**Type:** String **Default:** `manual` **Scope:** Local or global **Values:** `manual`, `new-pane`,
`new-window`, `background`

Control how worktrees integrate with tmux (currently read but not actively used).

**Planned modes:**

- `manual` - No automatic tmux integration
- `new-pane` - Open worktree in new pane
- `new-window` - Open worktree in new window
- `background` - Create worktree without switching focus

---

## Configuration Scope

### Local vs Global

**Local config** (per-project):

```bash
# Applies only to current repository
git config --local gtr.parallel.max 10
```

**Global config** (user-wide defaults):

```bash
# Applies to all repositories for current user
git config --global gtr.parallel.default 4
```

**Precedence:** Local overrides global.

### Recommended Setup

**Global defaults** (in `~/.gitconfig`):

```bash
git config --global gtr.parallel.default 4
git config --global gtr.parallel.max 8
git config --global gtr.parallel.stagger 2
git config --global gtr.parallel.auto true
```

**Project-specific overrides**:

```bash
# Large monorepo
cd ~/code/enterprise-monorepo
git config --local gtr.parallel.default 10
git config --local gtr.parallel.max 20

# Small hobby project
cd ~/code/personal-blog
git config --local gtr.parallel.default 2
git config --local gtr.parallel.max 4
```

---

## Usage Examples

### Example 1: High-Performance Workstation

```bash
# ~/.gitconfig
[gtr "parallel"]
    default = 8
    max = 20
    stagger = 1
    auto = true

[gtr "worktree"]
    path = ./.worktrees
```

**Result:**

- Default 8 agents per launch
- Can scale up to 20 if needed
- Fast stagger (1s) on SSD
- Auto-launches Claude

### Example 2: Resource-Constrained Laptop

```bash
# ~/.gitconfig
[gtr "parallel"]
    default = 2
    max = 4
    stagger = 3
    auto = true

[gtr "worktree"]
    path = ./.worktrees
```

**Result:**

- Conservative 2 agents default
- Hard limit at 4 agents
- Slower stagger for safety
- Still auto-launches

### Example 3: Manual Control Mode

```bash
# ~/code/sensitive-project/.git/config
[gtr "parallel"]
    default = 4
    max = 6
    stagger = 2
    auto = false  # Manual launch

[gtr "worktree"]
    path = ../worktrees
```

**Result:**

- Standard agent count
- Panes created but not auto-launched
- User must manually start Claude
- Worktrees in sibling directory

---

## Checking Current Configuration

### View all gtr settings:

```bash
git config --get-regexp gtr
```

### View specific setting:

```bash
git config --get gtr.parallel.max
```

### View with scope:

```bash
# Local only
git config --local --get gtr.parallel.max

# Global only
git config --global --get gtr.parallel.max
```

---

## Unsetting Configuration

### Remove local setting:

```bash
git config --local --unset gtr.parallel.max
```

### Remove global setting:

```bash
git config --global --unset gtr.parallel.default
```

### Remove entire section:

```bash
git config --remove-section gtr.parallel
```

---

## Troubleshooting

### Issue: "Max parallel agents reached"

**Cause:** `gtr.parallel.max` limit hit

**Check:**

```bash
git config --get gtr.parallel.max
```

**Fix:**

```bash
# Increase limit
git config --local gtr.parallel.max 12

# Or remove limit
git config --local --unset gtr.parallel.max
```

### Issue: Agents selecting same task

**Cause:** Stagger delay too short

**Fix:**

```bash
# Increase stagger delay
git config --local gtr.parallel.stagger 3
```

### Issue: Too many agents launched by default

**Cause:** High `gtr.parallel.default` value

**Fix:**

```bash
# Lower default
git config --local gtr.parallel.default 2
```

---

## Integration with Tools

### Scripts that read git config:

1. **parallel-claude.sh**
   - Reads: `gtr.parallel.default`, `gtr.parallel.max`, `gtr.parallel.stagger`, `gtr.parallel.auto`
   - Purpose: Configure number of agents, resource limits, stagger delays, and auto-launch behavior

2. **find-next-task.sh**
   - Reads: `gtr.parallel.max`
   - Purpose: Enforce max parallel agents by counting active PIDs and refusing new tasks when limit
     reached

3. **create-worktree.sh**
   - Reads: `gtr.worktree.path`, `gtr.tmux.enabled`, `gtr.tmux.mode`, `claude.worktree.autoInstall`,
     `claude.hook.postCreate`
   - Purpose: Configure worktree location, dependency installation behavior, and post-creation hooks

---

## Best Practices

1. **Set global defaults** for your typical workflow
2. **Override per-project** for special cases
3. **Use max limits** to prevent resource exhaustion
4. **Start conservative** (2-4 agents) and scale up
5. **Monitor first runs** with task monitor (`Ctrl-g M`)
6. **Document project settings** in README for team
7. **Use pnpm for worktrees** - Global store with symlinks provides best performance
8. **Test hooks thoroughly** - Ensure post-create hooks are idempotent and handle failures
   gracefully
9. **Disable auto-install for docs** - Set `claude.worktree.autoInstall=false` for
   documentation-only projects
10. **Use --no-install for speed** - Skip installation when testing worktree creation workflows

---

## Related Documentation

- **Parallel Agents Guide:** `.claude/docs/parallel-claude-agents.md`
- **Quick Start:** `.claude/docs/parallel-agents-quickstart.md`
- **Research:** `.claude/docs/research/parallel-claude-agents-tmux-worktrees.md`
