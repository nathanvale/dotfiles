# Parallel Claude Agent System

A dynamic parallel agent launcher that enables running multiple Claude Code instances simultaneously in tmux, each working on different tasks with automatic lock coordination to prevent conflicts.

## Overview

This system addresses the "Scenario 3" vision: running multiple Claude agents in parallel on a widescreen monitor, watching them work on different tasks simultaneously while automatically preventing duplicate work through PID-based lock coordination.

**Key Features:**
- 🔢 **Dynamic Agent Count**: Launch 2, 4, 10, or any number of agents
- 🔒 **Automatic Lock Coordination**: Prevents agents from selecting the same task
- ⏱️ **Staggered Execution**: Delays agent launches to avoid race conditions
- 📊 **Real-Time Monitoring**: Dashboard shows active locks, PIDs, and worktrees
- 🎨 **Seamless Integration**: Works with existing tmux/tmuxinator setup

## Architecture

### Components

```
bin/tmux/
├── parallel-claude.sh         # Core dynamic launcher
├── parallel-claude-menu.sh    # Interactive menu (Ctrl-g P)
└── task-monitor.sh            # Real-time dashboard (Ctrl-g M)

config/tmuxinator/scripts/
└── common-setup.sh            # Reusable functions for tmuxinator templates
```

### Lock Coordination Flow

```
Agent 1: Launch → find-next-task.sh → Lock T0001 → Create worktree → Run /next
Agent 2: Launch → (2s delay) → find-next-task.sh → Skip T0001 (locked) → Lock T0002 → Run /next
Agent 3: Launch → (4s delay) → find-next-task.sh → Skip T0001, T0002 → Lock T0003 → Run /next
Agent 4: Launch → (6s delay) → find-next-task.sh → Skip T0001-T0003 → Lock T0004 → Run /next
```

**Lock File Structure** (`.claude/state/task-locks/T0001.lock`):
```json
{
  "taskId": "T0001",
  "agentId": "nathanvale-agent-12345",
  "pid": 67890
}
```

**Lock Validation**:
- `find-next-task.sh` checks for active locks before selecting tasks
- PID validation ensures stale locks (dead processes) are cleaned up
- Each agent skips tasks with valid locks from running processes

## Usage

### Quick Start (Tmux Keybindings)

From within tmux:

| Keybinding | Action |
|------------|--------|
| `Ctrl-g P` | Launch parallel agents (interactive menu) |
| `Ctrl-g M` | Open task monitor dashboard |

**Interactive Menu Options:**
- `2` - Launch 2 agents (side-by-side)
- `4` - Launch 4 agents (2x2 grid)
- `8` - Launch 8 agents (4x2 grid)
- `10` - Launch 10 agents (5x2 grid)
- `c` - Custom number (1-50)
- Append `n` for new session (e.g., `4n`)

### Command Line Usage

**Launch in current session:**
```bash
~/code/dotfiles/bin/tmux/parallel-claude.sh 4
```

**Launch in dedicated session:**
```bash
~/code/dotfiles/bin/tmux/parallel-claude.sh 10 new
```

**Monitor tasks:**
```bash
~/code/dotfiles/bin/tmux/task-monitor.sh
```

### Tmuxinator Integration

Add to your `.yml` template:

```yaml
name: my-project
root: ~/code/my-project
windows:
  - claude:
      panes:
        - claude
  - git:
      panes:
        - lazygit
  - tasks:
      layout: tiled
      panes:
        - source ~/code/dotfiles/config/tmuxinator/scripts/common-setup.sh && setup_parallel_task_pane tasks 0 true
        - source ~/code/dotfiles/config/tmuxinator/scripts/common-setup.sh && setup_parallel_task_pane tasks 1 true
        - source ~/code/dotfiles/config/tmuxinator/scripts/common-setup.sh && setup_parallel_task_pane tasks 2 true
        - source ~/code/dotfiles/config/tmuxinator/scripts/common-setup.sh && setup_parallel_task_pane tasks 3 true
```

**Or use the helper function:**

```yaml
  - tasks:
      panes:
        - source ~/code/dotfiles/config/tmuxinator/scripts/common-setup.sh && create_parallel_task_window 4 true
```

## Task Monitor Dashboard

Real-time monitoring of all parallel agents:

```
╔════════════════════════════════════════════════════════════════╗
║         🔍 Claude Agent Task Monitor                          ║
╚════════════════════════════════════════════════════════════════╝

Refresh: 2s | Press Ctrl-C to exit
Updated: 2025-11-17 19:30:45

📋 Active Task Locks:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  TASK       PID        AGENT                STATUS
  ────       ───        ─────                ──────
  T0033      67890      nathanvale-agent     ALIVE
  T0034      67891      nathanvale-agent     ALIVE
  T0035      67892      nathanvale-agent     ALIVE

🌳 Git Worktrees:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  PATH                                              BRANCH
  ────                                              ──────
  /Users/nathanvale/code/dotfiles/worktrees/T0033   T0033
  /Users/nathanvale/code/dotfiles/worktrees/T0034   T0034

📊 Task Statistics:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Ready:               12
  In Progress:         3
  Completed:           45
  Blocked:             2
```

## Workflow Examples

### Scenario 1: Quick 4-Agent Burst

**Goal**: Process 4 high-priority tasks quickly

1. Press `Ctrl-g P` in tmux
2. Select `4` (default)
3. Wait for agents to launch (0s, 2s, 4s, 6s delays)
4. Each agent runs `claude` and executes `/next` automatically
5. Monitor progress with `Ctrl-g M`

**Expected Result**: 4 tasks completed in parallel, ~4x faster than sequential

### Scenario 2: Large-Scale Parallel Processing

**Goal**: Process 10 tasks simultaneously

1. Press `Ctrl-g P`
2. Select `10`
3. Watch 10 agents launch in staggered sequence
4. Each picks different READY task with dependencies met
5. All work in isolated worktrees with no conflicts

**Expected Result**: Massive parallelization with automatic coordination

### Scenario 3: Dedicated Session for Parallel Work

**Goal**: Keep parallel agents separate from main workflow

1. Press `Ctrl-g P`
2. Select `4n` (4 agents in new session)
3. New `parallel-claude` session created
4. Agents run independently
5. Switch between sessions with `Ctrl-\` or `Ctrl-g L`

**Expected Result**: Clean separation between regular work and parallel agents

## How It Works

### 1. Staggered Launch Strategy

```bash
# Agent 1: Immediate launch
tmux send-keys -t pane.0 "claude" C-m

# Agent 2: 2-second delay
tmux send-keys -t pane.1 "sleep 2 && claude" C-m

# Agent 3: 4-second delay
tmux send-keys -t pane.2 "sleep 4 && claude" C-m

# Agent 4: 6-second delay
tmux send-keys -t pane.3 "sleep 6 && claude" C-m
```

**Why stagger?**
- Prevents race conditions in task selection
- Ensures sequential lock creation
- Gives `find-next-task.sh` time to create locks
- Each agent sees previous locks before selecting

### 2. Dynamic Pane Layout

```bash
# For N agents:
# - Create N-1 splits (first pane exists from window creation)
# - Alternate horizontal/vertical splits
# - Apply 'tiled' layout for clean grid

for i in 2..N:
    if i is even: split horizontal
    if i is odd: split vertical
tmux select-layout tiled  # Auto-arranges into grid
```

**Result**: Clean grid layout regardless of agent count (2, 4, 8, 10, etc.)

### 3. Lock Coordination Integration

The system seamlessly integrates with existing `find-next-task.sh` logic:

```bash
# From find-next-task.sh (no modifications needed!)
for task_file in $TASK_DIR/T[0-9][0-9][0-9][0-9]-*.md; do
    STATUS=$(grep "^status:" "$task_file")
    if [ "$STATUS" != "READY" ]; then continue; fi

    # Check for active lock
    LOCK_FILE=".claude/state/task-locks/${TASK_ID}.lock"
    if [ -f "$LOCK_FILE" ]; then
        LOCK_PID=$(grep '"pid"' "$LOCK_FILE")
        if is_process_running "$LOCK_PID"; then
            continue  # Skip locked task ✅
        else
            rm -f "$LOCK_FILE"  # Clean stale lock
        fi
    fi

    # Check dependencies...
    # Select highest priority unlocked task with deps met
done
```

**Key Insight**: No changes needed to `/next` or task scripts. Lock system "just works" with parallel agents!

## Production Validation

This pattern is validated by:

1. **incident.io**: Runs 4-5 parallel Claude agents in production
2. **Anthropic Docs**: Official recommendation for git worktree pattern
3. **claude-code-agent-farm**: Scales to 20-50 agents simultaneously

**Research**: See `.claude/docs/research/parallel-claude-agents-tmux-worktrees.md`

## Troubleshooting

### Issue: Agents selecting same task

**Cause**: Stagger delay too short for slow filesystems

**Fix**: Increase `STAGGER_DELAY` in `parallel-claude.sh`:
```bash
STAGGER_DELAY=3  # Default: 2
```

### Issue: "No tasks available" despite READY tasks

**Cause**: All READY tasks have unmet dependencies

**Fix**: Check task dependencies with monitor:
```bash
~/code/dotfiles/bin/tmux/task-monitor.sh
```

### Issue: Stale locks blocking tasks

**Cause**: Agent crashed without cleaning lock

**Fix**: Locks auto-clean on next selection (PID validation), or manually:
```bash
rm .claude/state/task-locks/*.lock
```

### Issue: Too many agents for screen space

**Cause**: Launched more agents than fits comfortably

**Fix**:
- Use `Ctrl-g z` to zoom individual panes
- Launch fewer agents
- Use external monitor for more space

## Best Practices

### Agent Count Guidelines

| Screen Size | Recommended Agents | Max Agents |
|-------------|-------------------|------------|
| 13" Laptop | 2-4 | 6 |
| 15" Laptop | 4-6 | 8 |
| 27" Monitor | 6-10 | 12 |
| Ultra-wide | 8-12 | 16 |
| Multi-monitor | 10-20 | 50 |

### Task Organization

**For optimal parallel processing:**

1. **Use proper dependencies** - Ensure `depends_on` is accurate
2. **Set correct status** - Mark tasks as READY when truly ready
3. **Write atomic tasks** - Each task should be independent
4. **Balance priority** - Mix P0-P3 for diverse work
5. **Monitor locks** - Use dashboard to verify no conflicts

### Performance Tips

- **Start small**: Test with 2 agents before scaling to 10
- **Watch first run**: Monitor with `Ctrl-g M` to verify coordination
- **Stagger wisely**: Increase delay for large task lists
- **Clean worktrees**: Remove completed task worktrees regularly
- **Use dedicated session**: Keep parallel agents separate for clarity

## Integration with Existing Workflow

### Does NOT replace:
- Single `/next` command for focused work
- Manual task selection
- PR review workflow
- Git management with lazygit

### Enhances:
- ✅ High-priority sprint completion
- ✅ Batch processing of similar tasks
- ✅ Parallel feature development
- ✅ Multi-task experimentation
- ✅ Large refactoring efforts

### Complements:
- Works alongside regular tmuxinator sessions
- Respects existing vault management (`Ctrl-g V`)
- Uses same task directory structure
- Follows same git worktree patterns

## Future Enhancements

**Potential additions:**
- [ ] GPU/CPU monitoring per agent
- [ ] Task completion notifications
- [ ] Auto-scaling based on available tasks
- [ ] Per-agent log aggregation
- [ ] PR batch creation from completed agents
- [ ] Git config for agent-specific settings

## References

- **Research**: `.claude/docs/research/parallel-claude-agents-tmux-worktrees.md`
- **Core Scripts**: `bin/tmux/parallel-claude.sh`, `task-monitor.sh`
- **Helper Functions**: `config/tmuxinator/scripts/common-setup.sh`
- **Tmux Config**: `config/tmux/tmux.conf` (keybindings)
- **Task System**: `.claude/scripts/find-next-task.sh`, `create-worktree.sh`

## Credits

Inspired by:
- **git-worktree-runner** (gtr) - Editor/AI integration patterns
- **incident.io** - Production parallel agent validation
- **Anthropic** - Official worktree recommendations
- **Your vision** - "Scenario 3" parallel agent dream ✨
