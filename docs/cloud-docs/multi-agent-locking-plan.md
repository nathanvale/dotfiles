# Multi-Agent Locking & Monitoring Plan

**Updated:** 2025-11-19
**Owner:** nathanvale
**Scope:** Short-term hardening for local multi-agent (tmux + VS Code) workflows

## Objectives

1. Prevent double-assignment when multiple agents call `/next` concurrently.
2. Auto-recover from crashed agents that never reach `/merge`.
3. Keep lock visibility simple enough for tmux dashboards.
4. Require zero external infrastructure so it works offline on this Mac.

## Key Upgrades

| Area | Current State | Target State |
| --- | --- | --- |
| Lock creation | `if [ -f lock ]; then` write file | Use `flock` to guarantee atomic lock writes |
| Liveness | None; PID stored once | Heartbeat timestamps updated every few minutes |
| Cleanup | Manual `unlock` or `/merge` | Automated stale-lock cleanup on every `/next` |
| Visibility | `locks` lists files | `locks` shows age + heartbeat lag + stale flag |
| Monitoring | Manual `ls` | Dedicated tmux pane running watchdog + alerts |

## Implementation Steps

1. **Atomic Locking**
   - Wrap writes in `exec {fd}>"$LOCK_FILE"` + `flock -n "$fd"`.
   - Treat lock acquisition + JSON write as a single critical section.
   - Abort immediately if lock exists (no overwrite) unless `--force` set.

2. **Heartbeat Metadata**
   - Extend lock JSON:
     ```json
     {
       "taskId": "MPCU-0038",
       "agentId": "tmux-pane-2",
       "pid": 8641,
       "worktreePath": "/repo/.worktrees/MPCU-0038",
       "branch": "feat/MPCU-0038",
       "lockedAt": "2025-11-19T01:03:33Z",
       "heartbeatAt": "2025-11-19T01:07:12Z"
     }
     ```
   - Add `~/.claude/scripts/update-lock-heartbeat.sh TASK_ID` and call it at the end of long-running scripts (`create-worktree`, validation, PR creation) and optionally via tmux hooks every N minutes.

3. **Automatic Cleanup (`cleanup-stale-locks.sh`)**
   - Run at the start of `parse-next-task.sh` (every `/next`).
   - For each lock:
     1. Check if task file status is `COMPLETED` or if branch merged into `main`; if so, delete lock.
     2. If `heartbeatAt` older than threshold (e.g., 20 minutes) and no git activity on branch, mark stale → delete lock and log event to `.git/task-locks/history.log`.
     3. Emit tmux notification via `tmux display-message "Reclaimed lock MPCU-0038"`.

4. **Enhanced `locks` Command**
   - Show columns: Task | Agent | Locked ago | Heartbeat ago | Status (`OK`, `STALE`, `MERGED`).
   - Optionally add `--watch` mode (uses `watch` or repeated loop) for tmux pane.

5. **Tmux Integration**
    - Helper scripts:
       - `bin/tmux/monitor-locks.sh` → wraps `list-task-locks.sh --watch` for dashboard panes.
       - `tmux/workers/next-worker.sh` → sample loop that runs `/next`, sets up the worktree, then waits for manual implementation.
    - Recommended layout:
       - Pane 1: `bin/tmux/monitor-locks.sh`
       - Pane 2..N: `tmux/workers/next-worker.sh`
    - Heartbeats: `tmux run-shell 'while sleep 120; do ~/.claude/scripts/update-lock-heartbeat.sh --quiet "$TASK_ID"; done'` or rely on the new helper pulses in scripts.
    - Notifications: `tmux display-message` on lock cleanup or failure.

6. **Merge-Aware Cleanup**
   - `/merge` records `{ taskId, mergedSha, mergedAt }` into `.git/task-locks/history.json`.
   - Cleanup script cross-references git history; if the "chore(TASK): start task" commit appears on `main`, any leftover lock for TASK is safe to delete.

## Rollout Checklist

- [ ] Implement `flock`-based locking in `select-and-lock-task.sh`.
- [ ] Add heartbeat writes to `create-worktree.sh`, validation script, and optional tmux hook.
- [ ] Build `cleanup-stale-locks.sh` and invoke from `/next`.
- [ ] Extend `locks` command with age/heartbeat info.
- [ ] Create tmux helper scripts:
  - `tmux/workers/next-worker.sh`
  - `tmux/workers/monitor-locks.sh`
- [ ] Smoke-test with 3 concurrent tmux panes + 1 VS Code terminal.
- [ ] Document recovery SOP (if cleanup quarantines a lock, how to inspect history).

## Open Questions

1. Heartbeat interval vs. acceptable stale threshold (recommend 120s heartbeat, 15m stale).
2. Whether to auto-retry `/next` when selection fails due to temporary lock contention.
3. Persisting lock history beyond `.git` (e.g., `logs/locks/YYYY-MM-DD.log`).

## Next Steps

1. Implement locking + heartbeat changes in scripts.
2. Add cleanup + monitoring tooling.
3. Run tmux session dry run and iterate on UX.

## Tmux Setup Guide

Follow these steps to spin up a multi-agent tmux session that keeps locks healthy and visible, even if some workers run outside tmux.

### 1. Create/attach session

```bash
tmux new-session -s cloud-agents -n monitor
```

### 2. Monitoring pane

In pane 1 (window `monitor`):

```bash
bin/tmux/monitor-locks.sh
```

This wraps `~/.claude/scripts/list-task-locks.sh --watch 2`, showing task/agent/status plus heartbeat age.

### 3. Worker panes

Split additional panes (or create a new window) and run:

```bash
tmux/workers/next-worker.sh
```

Each worker pane:
1. Runs `/next` (which now auto-cleans stale locks).
2. Calls `create-worktree.sh TASK_ID` to set up the worktree + heartbeat pulses.
3. Leaves you inside the repo ready to implement/validate/merge.

Launch as many panes as needed; the atomic locking prevents double assignment.

### 4. Optional background heartbeat

For very long manual edits/tests, you can run a periodic heartbeat loop per pane:

```bash
tmux run-shell 'while sleep 120; do ~/.claude/scripts/update-lock-heartbeat.sh --quiet "$TASK_ID"; done'
```

The core scripts already pulse after key steps, so this is only needed for unusually long pauses.

### 5. Notifications

Add a tmux hook or manual command to surface cleanup events:

```bash
tmux display-message "Lock $(basename $LOCK_FILE .lock) reclaimed"
```

Because locks live in `.git/task-locks/`, workers started from VS Code terminals still appear in the dashboard pane—tmux is optional for execution but ideal for monitoring.
