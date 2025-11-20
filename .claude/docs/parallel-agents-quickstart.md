# Parallel Claude Agents - Quick Start

**TL;DR**: Press `Ctrl-g P` in tmux to launch multiple Claude agents in parallel. Your "Scenario 3"
dream is now real! 🚀

## The 30-Second Version

1. **Launch**: `Ctrl-g P` → Select agent count (2, 4, 8, 10, or custom)
2. **Monitor**: `Ctrl-g M` to watch all agents in real-time
3. **Done**: Agents automatically avoid duplicate work via lock coordination

## Quick Reference

### Tmux Keybindings

| Key        | Action                              |
| ---------- | ----------------------------------- |
| `Ctrl-g P` | Launch parallel agents (popup menu) |
| `Ctrl-g M` | Task monitor dashboard              |
| `Ctrl-g o` | Cycle through agent panes           |
| `Ctrl-g z` | Zoom into single pane               |

### Command Line

```bash
# Launch 4 agents in current session
~/code/dotfiles/bin/tmux/parallel-claude.sh 4

# Launch 10 agents in dedicated session
~/code/dotfiles/bin/tmux/parallel-claude.sh 10 new

# Monitor tasks
~/code/dotfiles/bin/tmux/task-monitor.sh
```

## How Many Agents Should I Run?

| Goal             | Agents | Use Case                                 |
| ---------------- | ------ | ---------------------------------------- |
| Quick burst      | 2-4    | Process a few high-priority tasks        |
| Sprint work      | 4-6    | Complete a feature across multiple tasks |
| Batch processing | 8-12   | Large refactoring or cleanup             |
| Max throughput   | 10-20  | You have many READY tasks and want speed |

**Screen size matters:**

- 13" laptop: 2-4 agents
- 15" laptop: 4-6 agents
- 27" monitor: 6-10 agents
- Ultra-wide/multi-monitor: 10-20 agents

## What You'll See

### After launching 4 agents:

```
╔════════════════════════════════════════════════════════════════╗
║  🚀 Parallel Claude Agent Launcher                            ║
╠════════════════════════════════════════════════════════════════╣
║  Session:        dotfiles
║  Agents:         4
║  Stagger Delay:  2s between launches
╠════════════════════════════════════════════════════════════════╣
║  📋 Next Steps:                                               ║
║                                                                ║
║  1. Wait for all agents to launch (staggered start)           ║
║  2. In each Claude pane, run: /next                           ║
║  3. Monitor progress with: Ctrl-g M                           ║
║                                                                ║
║  💡 Tips:                                                      ║
║  - Use Ctrl-g o to cycle through panes                        ║
║  - Use Ctrl-g z to zoom into a single pane                    ║
║  - Locks prevent duplicate task selection                     ║
║  - Each agent works in isolated worktree                      ║
╚════════════════════════════════════════════════════════════════╝
```

Your tmux window will have 4 panes in a 2x2 grid:

```
┌──────────┬──────────┐
│ Agent 1  │ Agent 2  │
│ claude   │ claude   │
│ /next→   │ /next→   │
├──────────┼──────────┤
│ Agent 3  │ Agent 4  │
│ claude   │ claude   │
│ /next→   │ /next→   │
└──────────┴──────────┘
```

### Task Monitor Dashboard:

```
╔════════════════════════════════════════════════════════════════╗
║         🔍 Claude Agent Task Monitor                          ║
╚════════════════════════════════════════════════════════════════╝

📋 Active Task Locks:
  TASK       PID        AGENT                STATUS
  ────       ───        ─────                ──────
  T0033      67890      nathanvale-agent     ALIVE
  T0034      67891      nathanvale-agent     ALIVE
  T0035      67892      nathanvale-agent     ALIVE
  T0036      67893      nathanvale-agent     ALIVE

🌳 Git Worktrees:
  PATH                                              BRANCH
  ────                                              ──────
  /Users/nathanvale/code/dotfiles/worktrees/T0033   T0033
  /Users/nathanvale/code/dotfiles/worktrees/T0034   T0034
  /Users/nathanvale/code/dotfiles/worktrees/T0035   T0035
  /Users/nathanvale/code/dotfiles/worktrees/T0036   T0036

📊 Task Statistics:
  Ready:               8
  In Progress:         4
  Completed:           45
  Blocked:             2
```

## Magic Behind the Scenes

### How Agents Avoid Duplicate Work

1. **Agent 1** launches immediately:
   - Runs `find-next-task.sh`
   - Finds T0033 (highest priority READY task)
   - Creates lock file with PID
   - Starts work in `worktrees/T0033/`

2. **Agent 2** launches 2 seconds later:
   - Runs `find-next-task.sh`
   - Sees T0033 lock file with active PID
   - Skips T0033 ✅
   - Finds T0034 (next highest priority)
   - Creates lock and starts work

3. **Agent 3** launches 4 seconds later:
   - Sees locks for T0033, T0034
   - Skips both ✅
   - Picks T0035

4. **Agent 4** launches 6 seconds later:
   - Sees locks for T0033, T0034, T0035
   - Skips all ✅
   - Picks T0036

**Result**: 4 agents working on 4 different tasks simultaneously with ZERO conflicts!

### Why the Stagger Delay?

**Without stagger** (all launch at once):

```
Agent 1 → find-next-task → T0033 ❌ (race condition)
Agent 2 → find-next-task → T0033 ❌ (same task!)
Agent 3 → find-next-task → T0033 ❌ (collision!)
Agent 4 → find-next-task → T0033 ❌ (disaster!)
```

**With 2-second stagger**:

```
Agent 1 → find-next-task → T0033 → Lock created ✅
(2s delay)
Agent 2 → find-next-task → Skip T0033 → T0034 → Lock created ✅
(2s delay)
Agent 3 → find-next-task → Skip T0033, T0034 → T0035 ✅
(2s delay)
Agent 4 → find-next-task → Skip T0033-T0035 → T0036 ✅
```

**Perfect coordination!** 🎯

## Common Workflows

### Workflow 1: Sprint Mode (Process 4 tasks fast)

```bash
1. Ctrl-g P
2. Select: 4
3. Watch agents launch
4. Each automatically runs /next
5. Come back in 20 minutes
6. All 4 tasks completed!
```

### Workflow 2: Massive Batch (10 tasks)

```bash
1. Ctrl-g P
2. Select: 10
3. Optional: Ctrl-g M (monitor in split pane)
4. Watch all 10 agents work
5. Process 10 tasks in parallel
```

### Workflow 3: Dedicated Session

```bash
1. Ctrl-g P
2. Select: 4n (new session)
3. New "parallel-claude" session created
4. Work continues in dedicated space
5. Switch back: Ctrl-\ or Ctrl-g L
```

### Workflow 4: Add to Tmuxinator Template

```yaml
# ~/.config/tmuxinator/my-project.yml
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
        - source ~/code/dotfiles/config/tmuxinator/scripts/common-setup.sh &&
          setup_parallel_task_pane tasks 0 true
        - source ~/code/dotfiles/config/tmuxinator/scripts/common-setup.sh &&
          setup_parallel_task_pane tasks 1 true
        - source ~/code/dotfiles/config/tmuxinator/scripts/common-setup.sh &&
          setup_parallel_task_pane tasks 2 true
        - source ~/code/dotfiles/config/tmuxinator/scripts/common-setup.sh &&
          setup_parallel_task_pane tasks 3 true
```

## Troubleshooting

### "No tasks available"

→ All READY tasks have unmet dependencies. Check `Ctrl-g M` for task stats.

### Agents selecting same task

→ Increase stagger delay in `bin/tmux/parallel-claude.sh`:

```bash
STAGGER_DELAY=3  # Default: 2
```

### Stale locks blocking tasks

→ Auto-cleaned by PID validation, or manually:

```bash
rm .claude/state/task-locks/*.lock
```

### Too many agents for screen

→ Use `Ctrl-g z` to zoom individual panes, or launch fewer agents

## What NOT to Do

❌ **Don't** manually run `/next` in each pane (it's automatic with `auto_launch=true`) ❌ **Don't**
launch more agents than you have READY tasks ❌ **Don't** launch agents if tasks have complex
interdependencies ❌ **Don't** forget to monitor first few runs with `Ctrl-g M`

## What to Do Instead

✅ **Do** use parallel agents for independent tasks ✅ **Do** monitor first run to verify
coordination ✅ **Do** start with 2-4 agents before scaling to 10 ✅ **Do** use task monitor
dashboard to track progress ✅ **Do** set proper task dependencies in frontmatter

## Your "Scenario 3" is Real! 🎉

Remember when you said:

> "I'd have four running at once, and I could see four cloud agents in four different Tmux terminals
> working away, stopping starting, and handling conflicts"

**That's exactly what this does!** Press `Ctrl-g P`, select `4`, and watch your vision come to life.

Want 10 agents instead? No problem. Just press `Ctrl-g P` → `10`.

**Dynamic, scalable, and perfectly integrated with your existing tmux setup.** 🚀

## Full Documentation

For detailed architecture, integration patterns, and advanced usage: →
`.claude/docs/parallel-claude-agents.md`

For the research that validates this approach: →
`.claude/docs/research/parallel-claude-agents-tmux-worktrees.md`

---

**Now go forth and parallelize!** ⚡
