# TaskDock Tests

This directory contains test fixtures and integration tests for TaskDock.

## Structure

```
tests/
├── fixtures/                    # Sample data for testing
│   ├── T0001-fix-login-bug.md  # READY task (P0)
│   ├── T0002-improve-error-handling.md  # READY task (P1, depends on T0001)
│   ├── T0003-add-rate-limiting.md       # BLOCKED task (depends on T0002)
│   ├── T0004-refactor-profile-component.md  # IN_PROGRESS task
│   ├── T0005-update-auth-docs.md        # COMPLETED task
│   ├── locks/
│   │   └── T0004.lock           # Sample lock file
│   ├── sample-config.yaml       # Example configuration
│   └── README.md                # Fixture documentation
├── integration-test.sh          # End-to-end integration tests
└── README.md                    # This file
```

## Running Tests

### Integration Tests

Run the full integration test suite:

```bash
cd ~/code/dotfiles/apps/taskdock/tests
chmod +x integration-test.sh
./integration-test.sh
```

**What it tests:**
- Repository initialization
- Task selection algorithm
- Lock creation and management
- Configuration retrieval
- Worktree creation
- Health checks

**Expected output:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TaskDock Integration Test
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Setting up test environment...
✓ Test environment created

Test 1: Repository initialization
✓ taskdock init succeeds
✓ Creates .taskdock/config.yaml

...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Test Results
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Passed: 10
Failed: 0

✓ All tests passed!
```

### Manual Testing

Test individual commands with fixtures:

```bash
# Create a test repo
mkdir -p /tmp/test-taskdock
cd /tmp/test-taskdock
git init
taskdock init --ticket-prefix TEST

# Copy fixtures
cp ~/code/dotfiles/apps/taskdock/tests/fixtures/T*.md docs/tasks/

# Test task selection
taskdock next

# Test lock management
taskdock locks list

# Test worktree creation
taskdock worktree create T0001

# Test validation (will fail - no package.json)
taskdock validate || echo "Expected to fail"

# Cleanup
cd /
rm -rf /tmp/test-taskdock
```

## Test Scenarios

### Scenario 1: Task Selection Priority

**Setup:**
- T0001 (P0, READY)
- T0002 (P1, READY, depends on T0001)
- T0003 (P1, BLOCKED, depends on T0002)
- T0004 (P2, IN_PROGRESS)
- T0005 (P2, COMPLETED)

**Expected behavior:**
1. First `next`: Selects T0001 (highest priority, no dependencies)
2. Second `next`: Selects T0002 (T0001 locked, T0002 is next priority)
3. Mark T0001 COMPLETED: Now T0002 dependencies met
4. T0003 still blocked until T0002 completed
5. T0004 never selected (IN_PROGRESS)
6. T0005 never selected (COMPLETED)

### Scenario 2: Dependency Resolution

**Setup:**
- All tasks at READY status
- T0002 depends_on: [T0001]
- T0003 depends_on: [T0002]

**Expected behavior:**
1. Can only select T0001 (no dependencies)
2. After T0001 → COMPLETED, can select T0002
3. After T0002 → COMPLETED, can select T0003

### Scenario 3: Lock Management

**Setup:**
- T0004 has active lock
- Lock has recent heartbeat

**Expected behavior:**
1. `locks list` shows T0004 as locked
2. Cannot select T0004 for new work
3. `locks cleanup` with recent heartbeat keeps lock
4. `locks cleanup` with stale heartbeat removes lock
5. `locks unlock T0004` manually removes lock

### Scenario 4: Concurrent Agents

**Setup:**
- Multiple agents running simultaneously
- All agents call `next` at same time

**Expected behavior:**
1. Each agent gets different task
2. No two agents get same task
3. Atomic lock creation prevents race conditions
4. Heartbeat prevents stale locks

## Test Data Details

### Task Priorities

Tasks are prioritized P0 (highest) → P3 (lowest):

- **P0**: Critical bugs, production issues
- **P1**: High priority features, important bugs
- **P2**: Medium priority work
- **P3**: Low priority, nice-to-haves

### Task Statuses

- **READY**: Available for selection
- **BLOCKED**: Waiting on dependencies
- **IN_PROGRESS**: Currently being worked on
- **COMPLETED**: Finished and merged

### Lock File Format

```json
{
  "taskId": "T0004",
  "agentId": "agent-1-12345",
  "hostname": "macbook-pro.local",
  "lockedAt": "2025-11-19T09:00:00Z",
  "lastHeartbeat": "2025-11-19T09:45:00Z",
  "status": "IN_PROGRESS",
  "pid": 98765,
  "branch": "feat/T0004-refactor-profile-component",
  "worktree": "/path/to/.worktrees/T0004",
  "taskFile": "/path/to/docs/tasks/T0004-refactor-profile-component.md"
}
```

## Adding New Tests

To add a new integration test:

1. Edit `integration-test.sh`
2. Add new test function:
   ```bash
   echo -e "${BLUE}Test N: Description${NC}"
   OUTPUT=$(taskdock command --json 2>&1)
   RESULT=$(echo "$OUTPUT" | jq -r '.data.field')
   assert_equals "expected" "$RESULT" "Test description"
   ```
3. Run test suite to verify

## CI/CD Integration

### GitHub Actions

```yaml
name: TaskDock Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y jq
      - name: Run integration tests
        run: |
          cd taskdock/tests
          chmod +x integration-test.sh
          ./integration-test.sh
```

## Known Limitations

1. **No unit tests yet** - Only integration tests exist
2. **No performance tests** - Lock contention not tested under load
3. **No error injection** - Happy path only
4. **No cross-platform tests** - macOS/Linux only
5. **No concurrent agent tests** - Single agent only

## Future Improvements

- [ ] Add unit tests for lib functions
- [ ] Add performance benchmarks
- [ ] Add error injection tests
- [ ] Add multi-agent concurrent tests
- [ ] Add cross-platform compatibility tests
- [ ] Add test coverage reporting
- [ ] Add mutation testing
- [ ] Add snapshot tests for JSON output
- [ ] Add load testing for lock contention
- [ ] Add chaos testing (process kills, file corruption)

## Troubleshooting

### Tests fail with "command not found"

Ensure TaskDock is in your PATH:
```bash
export PATH="$HOME/code/dotfiles/bin:$PATH"
```

### Tests fail with "jq not found"

Install jq:
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq
```

### Tests leave artifacts

The integration test should clean up automatically, but if it fails:
```bash
rm -rf /tmp/taskdock-integration-test-*
```

---

**Last Updated:** 2025-11-19
