# TaskDock Test Fixtures

This directory contains sample data for testing and validating TaskDock functionality.

## Contents

### Task Files

Sample task markdown files demonstrating different states and scenarios:

- **T0001-fix-login-bug.md** - `READY` task, P0 priority, no dependencies
- **T0002-improve-error-handling.md** - `READY` task, P1 priority, depends on T0001
- **T0003-add-rate-limiting.md** - `BLOCKED` task, depends on T0002
- **T0004-refactor-profile-component.md** - `IN_PROGRESS` task, P2 priority
- **T0005-update-auth-docs.md** - `COMPLETED` task, was dependent on T0001 & T0002

### Task Statuses

- **READY** - Available for selection (T0001, T0002)
- **BLOCKED** - Waiting on dependencies (T0003)
- **IN_PROGRESS** - Currently being worked on (T0004)
- **COMPLETED** - Finished and merged (T0005)

### Priority Levels

- **P0** - Critical (T0001)
- **P1** - High (T0002, T0003)
- **P2** - Medium (T0004, T0005)
- **P3** - Low (none in fixtures)

### Dependency Graph

```
T0001 (READY, P0) ─┬─> T0002 (READY, P1) ──> T0003 (BLOCKED, P1)
                   │
                   └─> T0005 (COMPLETED, P2)

T0004 (IN_PROGRESS, P2) - No dependencies
```

### Lock Files

Sample lock files in `locks/` subdirectory:

- **T0004.lock** - Active lock with heartbeat

## Usage

### Testing Task Selection

The fixture set is designed to test task selection logic:

1. **Expected selection order:**
   - T0001 (P0, READY, no deps)
   - T0002 (P1, READY, after T0001)
   - T0003 (P1, BLOCKED until T0002)

2. **T0004** should not be selected (already IN_PROGRESS)
3. **T0005** should not be selected (COMPLETED)

### Testing Dependency Resolution

- T0002 should only be selectable after T0001 is COMPLETED
- T0003 should only be selectable after T0002 is COMPLETED
- T0005 demonstrates a completed task that had dependencies

### Testing Lock Validation

- T0004.lock shows an active lock with recent heartbeat
- Use to test stale lock detection by modifying lastHeartbeat

### Manual Testing Commands

```bash
# Copy fixtures to a test repo
cp taskdock/tests/fixtures/T*.md /path/to/test-repo/docs/tasks/

# Test task selection
cd /path/to/test-repo
taskdock next --json

# Expected: T0001 (highest priority, no dependencies)

# Mark T0001 as completed manually
sed -i '' 's/status: READY/status: COMPLETED/' docs/tasks/T0001-fix-login-bug.md

# Test again
taskdock next --json

# Expected: T0002 (next priority, dependencies met)
```

### Testing Lock Behavior

```bash
# Copy lock fixture
mkdir -p /path/to/test-repo/.git/task-locks
cp taskdock/tests/fixtures/locks/T0004.lock /path/to/test-repo/.git/task-locks/

# List locks
taskdock locks list

# Test stale detection (modify lock age in file)
# Then run cleanup
taskdock locks cleanup --max-age 30
```

## Fixture Scenarios

### Scenario 1: Fresh Start

All tasks are in initial state, T0001 should be selected.

### Scenario 2: Sequential Progress

- T0001 → COMPLETED
- T0002 should now be selectable
- T0003 still BLOCKED

### Scenario 3: Active Lock

- T0004 has active lock
- Should not be selectable by another agent
- Test heartbeat updates and stale detection

### Scenario 4: Complex Dependencies

- Multiple tasks depend on same parent
- T0002 and T0005 both depended on T0001
- T0005 completed, T0002 still available

## Extending Fixtures

To add new test scenarios:

1. Create new task file with unique ID (T0006+)
2. Follow the YAML frontmatter format
3. Set appropriate status, priority, dependencies
4. Add to dependency graph diagram above
5. Document expected behavior

## Validation

These fixtures should validate:

- ✅ Task parsing from markdown
- ✅ Status filtering (READY vs BLOCKED vs IN_PROGRESS)
- ✅ Priority sorting (P0 > P1 > P2 > P3)
- ✅ Dependency resolution
- ✅ Lock file format
- ✅ Concurrent task prevention
- ✅ Heartbeat tracking
- ✅ Stale lock detection

## Integration with CI

Future integration test harness can:

1. Create temporary git repo
2. Copy fixtures to `docs/tasks/`
3. Run taskdock commands
4. Assert expected outcomes
5. Cleanup

Example test pseudo-code:

```bash
#!/bin/bash
# Integration test

# Setup
mkdir -p /tmp/taskdock-test
cd /tmp/taskdock-test
git init
taskdock init --ticket-prefix TEST

# Copy fixtures
cp $FIXTURES_DIR/T*.md docs/tasks/

# Test 1: Select highest priority
RESULT=$(taskdock next --json)
SELECTED=$(echo "$RESULT" | jq -r '.data.taskId')
assert_equals "$SELECTED" "T0001"

# Test 2: Cannot select locked task
echo "$RESULT" # Should error if T0001 already locked

# Cleanup
cd /
rm -rf /tmp/taskdock-test
```

## Notes

- All timestamps are in UTC (ISO 8601 format)
- Lock PIDs are fictional (98765)
- File paths assume macOS structure
- GitHub URLs are examples (github.com/example/repo)

---

**Last Updated:** 2025-11-19
