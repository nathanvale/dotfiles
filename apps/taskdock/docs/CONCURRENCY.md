# TaskDock Concurrency Safety

TaskDock implements comprehensive concurrency safety mechanisms to prevent race conditions and data
corruption when multiple agents or processes access shared resources simultaneously.

## Overview

TaskDock uses file-based locking (flock) to protect critical sections across:

- Task lock creation and updates
- Configuration file writes
- Log file appends
- Lock file deletions

## Locking Strategy

### Unified Repo-Level Locking

TaskDock uses a unified locking strategy rooted in the repository's git directory:

- **Location**: `.git/taskdock-locks/*.flock`
- **Scope**: Repository-wide (shared across all worktrees)
- **Mechanism**: `flock` (or atomic `mkdir` fallback)

This ensures that:

1. Locks are respected across all worktrees (which share the same `.git` dir).
2. Locks are isolated per repository (no cross-repo interference).
3. No global user-level locks are required, reducing permission issues.

### Why This Matters

In multi-agent workflows, several operations can conflict:

- **Task selection**: Two agents selecting the same task simultaneously
- **Lock updates**: Concurrent heartbeat updates corrupting lock files
- **Config changes**: Multiple agents modifying configuration
- **Log writes**: Interleaved log entries becoming corrupted

## Protected Operations

### Task Lock Operations

**Location**: `taskdock/tasks/selector.sh`, `taskdock/lib/locks.sh`

```bash
# Protected: Task lock creation
try_create_task_lock() {
  # Uses with_repo_flock to ensure only one agent can check/create lock
  with_repo_flock "task-lock-${task_id}" _try_create_task_lock_impl "$task_id" "$lock_path"
}

# Protected: Lock heartbeat update
update_lock_heartbeat() {
  with_repo_flock "task-lock-${task_id}" _update_lock_heartbeat_impl "$task_id"
}

# Protected: Lock deletion
delete_lock() {
  with_repo_flock "task-lock-${task_id}" _delete_lock_impl "$task_id"
}
```

**Guarantees**:

- ✅ Atomic task selection (no duplicate assignments)
- ✅ Safe heartbeat updates (no data corruption)
- ✅ Race-free lock cleanup

### Config Operations

**Location**: `taskdock/commands/config.sh`

```bash
# Protected: Config file writes
cmd_set() {
  with_repo_flock "config-write" _update_config_impl "$repo_config" "$key" "$value"
}
```

**Guarantees**:

- ✅ Serialized config updates (no lost writes)
- ✅ Consistent config state across agents

### Log Operations

**Location**: `taskdock/lib/logging.sh`

```bash
# Protected: Log file appends
log_entry() {
  # User logs
  with_flock "log-write" bash -c "echo '$log_entry' >> '$TASKDOCK_LOG_DIR/taskdock.log'"

  # Repo logs
  with_repo_flock "log-write" bash -c "echo '$log_entry' >> '$repo_log_dir/taskdock.log'"
}
```

**Guarantees**:

- ✅ Complete log entries (no partial writes)
- ✅ Correct chronological ordering within same resource

## Flock API

### Core Functions

#### `with_flock <resource> <command> [args...]`

Acquire exclusive lock on user-level resource, execute command, release lock.

```bash
with_flock "my-resource" ./my-script.sh arg1 arg2
```

- **Timeout**: 30 seconds (configurable)
- **Scope**: User-level (~/.taskdock/locks/)
- **Returns**: Command exit code or EXIT_LOCK_TIMEOUT (70)

#### `with_repo_flock <resource> <command> [args...]`

Acquire exclusive lock on repo-level resource (shared across worktrees).

```bash
with_repo_flock "task-selection" ./select-task.sh
```

- **Timeout**: 30 seconds (configurable)
- **Scope**: Repository-level (.git/taskdock-locks/)
- **Returns**: Command exit code or EXIT_LOCK_TIMEOUT (70)

#### `with_flock_timeout <timeout> <resource> <command> [args...]`

Same as `with_flock` but with custom timeout in seconds.

```bash
with_flock_timeout 60 "long-operation" ./slow-task.sh
```

#### `try_flock <resource> <command> [args...]`

Try to acquire lock without blocking. Returns immediately if locked.

```bash
if try_flock "quick-check" ./check-status.sh; then
  echo "Success"
else
  echo "Resource busy"
fi
```

- **Returns**: EXIT_LOCK_BUSY (20) if lock unavailable

### Helper Functions

#### `cleanup_stale_flocks`

Remove flock files older than 1 hour (handles crashed processes).

```bash
cleanup_stale_flocks
```

Called automatically by `taskdock doctor`.

## Exit Codes

| Code | Constant          | Meaning                                  |
| ---- | ----------------- | ---------------------------------------- |
| 20   | EXIT_LOCK_BUSY    | Lock is held by another process          |
| 70   | EXIT_LOCK_TIMEOUT | Timeout waiting for lock                 |
| 80   | EXIT_NOT_IN_REPO  | Not in a git repository (for repo locks) |

## Performance Characteristics

### Lock Acquisition Time

- **Uncontended**: < 1ms
- **Contended**: Up to timeout (default 30s)
- **Overhead**: ~2-5ms per lock operation

### Scalability

- **Concurrent agents**: Tested up to 10 agents
- **Lock contention**: Minimal for typical workflows
- **Worktree isolation**: Excellent (separate working directories)

## Testing Concurrency

### Simulate Concurrent Task Selection

```bash
# Terminal 1
taskdock next --json

# Terminal 2 (immediately)
taskdock next --json

# Result: Different tasks assigned, no conflicts
```

### Stress Test Lock System

```bash
# Run 5 agents in parallel
for i in {1..5}; do
  (taskdock next && echo "Agent $i: $(date)") &
done
wait

# Check locks
taskdock locks list
# Should show 5 different tasks locked
```

### Verify Config Safety

```bash
# Terminal 1
for i in {1..100}; do
  taskdock config set test_key "value_$i"
done

# Terminal 2 (simultaneously)
for i in {1..100}; do
  taskdock config set test_key "other_$i"
done

# Verify no corruption
taskdock config show | grep test_key
# Should show either "value_*" or "other_*", not corrupted
```

## Limitations

### Not Protected

The following operations do **not** have flock protection:

1. **Task file reads**: Multiple agents can read task files simultaneously (safe)
2. **Git operations**: Uses git's internal locking (safe)
3. **Worktree creation**: Protected by git (safe)
4. **File system traversal**: Read-only operations (safe)

### Known Edge Cases

1. **Network file systems**: flock may not work reliably on NFS/SMB
   - **Solution**: Use local disk for `.git/taskdock-locks/`

2. **Cross-platform**: flock behavior differs slightly
   - **Linux**: Full POSIX compliance
   - **macOS**: Full support (BSD flock)
   - **Windows**: Not supported (WSL required)

3. **Lock cleanup**: Stale locks from crashed processes
   - **Mitigation**: `cleanup_stale_flocks()` removes locks > 1 hour old
   - **Manual**: `rm ~/.taskdock/locks/*.flock`

## Best Practices

### For Script Authors

1. **Use repo locks for shared resources**:

   ```bash
   with_repo_flock "my-resource" ./my-command.sh
   ```

2. **Use user locks for local resources**:

   ```bash
   with_flock "my-cache" ./update-cache.sh
   ```

3. **Keep critical sections short**:

   ```bash
   # Good: Lock only the write operation
   with_flock "data" echo "$result" >> data.txt

   # Bad: Lock the entire computation
   with_flock "data" ./expensive-computation.sh  # Don't do this
   ```

4. **Handle timeouts gracefully**:
   ```bash
   if ! with_flock "resource" ./command.sh; then
     error "Failed to acquire lock"
     # Retry or fail gracefully
   fi
   ```

### For Users

1. **Check for stale locks**:

   ```bash
   taskdock doctor  # Includes lock health check
   ```

2. **Monitor lock contention**:

   ```bash
   taskdock locks list  # Shows all active locks
   ```

3. **Clean up after crashes**:
   ```bash
   # If agent crashes, locks remain until cleaned up
   taskdock locks cleanup --max-age 30
   ```

## Debugging

### Enable Lock Debugging

```bash
# Set environment variable
export TASKDOCK_DEBUG_LOCKS=true

# Run command
taskdock next

# Output shows lock acquisition/release:
# [DEBUG] Acquiring lock: task-selection
# [DEBUG] Lock acquired: task-selection (2ms)
# [DEBUG] Releasing lock: task-selection
```

### Check Lock File Status

```bash
# User-level locks
ls -lh ~/.taskdock/locks/

# Repo-level locks
ls -lh .git/taskdock-locks/

# Check if lock is held
flock -n ~/.taskdock/locks/my-resource.flock echo "Not locked" || echo "Locked"
```

### Monitor Lock Wait Times

```bash
# Add timing to commands
time taskdock next

# If slow, check for contention:
taskdock locks list
```

## Implementation Details

### flock vs Other Locking Mechanisms

| Mechanism    | Pros                                           | Cons                            | Used In TaskDock?           |
| ------------ | ---------------------------------------------- | ------------------------------- | --------------------------- |
| **flock**    | Fast, kernel-level, automatic cleanup on crash | Not portable to all filesystems | ✅ Yes (primary)            |
| **lockfile** | Portable                                       | Manual cleanup, race conditions | ❌ No                       |
| **mkdir**    | Atomic                                         | Requires manual cleanup         | ❌ No (used for task locks) |
| **ln**       | Atomic                                         | Manual cleanup, less portable   | ✅ Yes (task locks only)    |

### Why Two Lock Types?

**Task locks** (`.git/task-locks/*.lock`):

- Business logic: "This task is assigned to agent X"
- Persisted: Survives process crashes (intentional)
- Manually managed: Requires explicit cleanup

**Flock locks** (`.git/taskdock-locks/*.flock`):

- Concurrency primitive: "Only one process can modify this file"
- Ephemeral: Automatically released on process exit
- Kernel-managed: No manual cleanup needed

### Lock Hierarchies

TaskDock avoids deadlocks by using a consistent lock ordering:

1. Config locks (lowest priority)
2. Log locks
3. Task locks (highest priority)

All operations follow this order, preventing circular dependencies.

## Future Improvements

### Planned (v0.2+)

- [ ] Lock metrics and monitoring dashboard
- [ ] Configurable lock timeouts per command
- [ ] Lock contention alerts
- [ ] Distributed lock coordination (for remote teams)
- [ ] Lock priority system (urgent operations jump queue)

### Under Consideration

- Advisory locks for file reads (prevent read-during-write)
- Lock pooling (reduce lock file proliferation)
- Lock leasing (automatic timeout + renewal)
- Cross-platform locking abstraction

## References

- **flock(1)** man page: `man flock`
- **flock(2)** system call: `man 2 flock`
- **Advisory vs Mandatory locking**:
  https://www.kernel.org/doc/Documentation/filesystems/mandatory-locking.txt

---

**Last Updated**: 2025-11-19 **TaskDock Version**: 0.1.0+concurrency
