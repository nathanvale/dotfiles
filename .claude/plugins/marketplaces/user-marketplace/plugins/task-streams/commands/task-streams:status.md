---
description:
  Inspect state files, task registry, and plugin health - shows task counter, component registry,
  and TASKS.md statistics
---

# Status Command

Provides health check and statistics for the task-streams plugin, including state file contents,
task registry stats, and component usage.

## Usage

```bash
/task-streams:status [--verbose]
```

**Parameters:**

- `--verbose`: Show detailed state file contents (default: summary only)

**Examples:**

```bash
# Quick status check
/task-streams:status

# Detailed inspection with full state
/task-streams:status --verbose
```

---

## Phase 1: State File Inspection

### Step 1.1: Locate State Files

Check for existence of state files:

**Expected Locations:**

- `.claude/state/task-streams/task-counter.json`
- `.claude/state/task-streams/component-registry.json`
- `TASKS.md` (project root)
- `docs/tasks/` (task directory)

### Step 1.2: Read State Files

```typescript
interface StateFiles {
  taskCounter: {
    exists: boolean;
    path: string;
    content?: {
      counter: number;
      tasks: Record<string, TaskMetadata>;
    };
  };
  componentRegistry: {
    exists: boolean;
    path: string;
    content?: {
      nextCode: number;
      components: Record<string, ComponentMetadata>;
    };
  };
  tasksIndex: {
    exists: boolean;
    path: string;
    lastModified?: string;
    taskCount?: number;
  };
  taskDirectory: {
    exists: boolean;
    path: string;
    fileCount?: number;
  };
}
```

---

## Phase 2: Generate Status Report

### Section: Overview

```
📊 Task-Streams Status

🔌 Plugin: task-streams v1.0.0
📍 Project: {project root path}
🕐 Timestamp: {current ISO timestamp}

═══════════════════════════════════════════════════════
```

### Section: Task Counter

```
📋 Task Counter

Status: ✅ Initialized | ⚠️ Not initialized
Path: .claude/state/task-streams/task-counter.json
Last task generated: T{counter - 1}
Next task ID: T{counter}
Total tasks created: {Object.keys(tasks).length}

{if verbose}
Recent tasks:
  • T0164: Add migration guide (2025-02-20T14:30:00Z)
    Source: docs/specs/auth-redesign-spec.md
  • T0163: Update API docs (2025-02-20T13:15:00Z)
    Source: docs/reviews/R015-api-review.md
  • T0162: Fix null checks (2025-02-19T16:45:00Z)
    Source: docs/reviews/R014-code-quality.md
{endif}
```

### Section: Component Registry

```
🏗️  Component Registry

Status: ✅ Initialized | ⚠️ Not initialized
Path: .claude/state/task-streams/component-registry.json
Total components: {Object.keys(components).length}
Next component code: C{nextCode}

Active components:
  • C00: General / Cross-Cutting (12 tasks)
  • C01: CLI & User Interface (8 tasks)
  • C02: Service Factory & Mode Selection (23 tasks)
  • C05: Authentication & Authorization (6 tasks)
  • C07: Testing & QA (15 tasks)
  • C09: Documentation (4 tasks)

{if verbose}
Component details:

C02: Service Factory & Mode Selection
  • Created: 2025-01-15T10:10:00Z
  • Description: Service factory pattern, fixture vs live mode switching
  • Tasks: 23
  • Recent: T0145, T0092, T0043

C05: Authentication & Authorization
  • Created: 2025-02-20T14:30:00Z
  • Description: OAuth, MFA, session management, access control
  • Tasks: 6
  • Recent: T0164, T0158, T0152
{endif}
```

### Section: TASKS.md Index

```
📑 Tasks Index (TASKS.md)

Status: ✅ Up to date | ⚠️ Out of sync | ❌ Missing
Path: TASKS.md
Last updated: {timestamp from TASKS.md}
Tasks indexed: {taskCount}

Priority breakdown:
  • P0 (Critical): {count} tasks
  • P1 (High):     {count} tasks
  • P2 (Medium):   {count} tasks
  • P3 (Low):      {count} tasks

Status breakdown:
  • READY:       {count} tasks
  • IN_PROGRESS: {count} tasks
  • BLOCKED:     {count} tasks
  • DONE:        {count} tasks
```

### Section: Task Directory

```
📁 Task Directory (docs/tasks/)

Status: ✅ Exists | ❌ Missing
Path: docs/tasks/
Total task files: {fileCount}

{if fileCount != taskCount}
⚠️  Warning: Task file count ({fileCount}) doesn't match TASKS.md index ({taskCount})
   • Missing in index: {count} files
   • Missing files: {count} entries
   • Run /task-streams:validate to identify discrepancies
{endif}

{if verbose}
Recent task files:
  • T0164-add-migration-guide.md (2.4 KB, 2025-02-20)
  • T0163-update-api-docs.md (1.8 KB, 2025-02-20)
  • T0162-fix-null-checks.md (3.1 KB, 2025-02-19)
{endif}
```

---

## Phase 3: Health Checks

### Check 1: State File Integrity

```typescript
const checks = {
  taskCounterValid: {
    check: "Task counter is valid JSON",
    status: taskCounter.exists && isValidJSON(taskCounter.content),
    severity: taskCounter.exists ? "OK" : "ERROR",
  },
  componentRegistryValid: {
    check: "Component registry is valid JSON",
    status: componentRegistry.exists && isValidJSON(componentRegistry.content),
    severity: componentRegistry.exists ? "OK" : "ERROR",
  },
  tasksIndexExists: {
    check: "TASKS.md index file exists",
    status: tasksIndex.exists,
    severity: tasksIndex.exists ? "OK" : "WARNING",
  },
  taskDirectoryExists: {
    check: "Task directory exists",
    status: taskDirectory.exists,
    severity: taskDirectory.exists ? "OK" : "ERROR",
  },
};
```

### Check 2: Data Consistency

```typescript
const consistency = {
  taskCountMatch: {
    check: "Task counter matches actual tasks",
    status: taskCounter.content.counter === taskDirectory.fileCount,
    severity: status ? "OK" : "WARNING",
    details: `Counter: ${taskCounter.content.counter}, Files: ${taskDirectory.fileCount}`,
  },
  indexSync: {
    check: "TASKS.md in sync with task files",
    status: tasksIndex.taskCount === taskDirectory.fileCount,
    severity: status ? "OK" : "WARNING",
  },
  componentTaskCounts: {
    check: "Component task counts accurate",
    status: validateComponentTaskCounts(),
    severity: status ? "OK" : "WARNING",
  },
};
```

### Health Check Report

```
🏥 Health Check

✅ All checks passed ({passCount}/{totalCount})
⚠️  Warnings: {warningCount}
❌ Errors: {errorCount}

Results:
  ✅ Task counter is valid JSON
  ✅ Component registry is valid JSON
  ✅ TASKS.md index file exists
  ✅ Task directory exists
  ✅ Task counter matches actual tasks (164 = 164)
  ⚠️  TASKS.md slightly out of sync (162 indexed, 164 files)
  ✅ Component task counts accurate

{if warningCount > 0 || errorCount > 0}
📋 Recommended Actions:

{if tasksIndex out of sync}
1. Update TASKS.md index:
   • Manually regenerate from task files
   • Or run /task-streams:convert to regenerate

{endif}
{if componentTaskCounts mismatch}
2. Rebuild component task counts:
   • Run component-manager skill to recalculate
{endif}
{endif}
```

---

## Phase 4: Usage Statistics

### Statistics Report

```
📈 Usage Statistics

Task creation rate:
  • Last 7 days:  {count} tasks
  • Last 30 days: {count} tasks
  • All time:     {count} tasks

Most active components:
  1. C02: Service Factory (23 tasks, 14.0%)
  2. C07: Testing & QA (15 tasks, 9.1%)
  3. C00: General (12 tasks, 7.3%)

Priority distribution:
  • P0: {count} ({percent}%)
  • P1: {count} ({percent}%)
  • P2: {count} ({percent}%)
  • P3: {count} ({percent}%)

Task sources:
  • Code reviews:    {count} tasks ({percent}%)
  • Tech specs:      {count} tasks ({percent}%)
  • ADRs:            {count} tasks ({percent}%)
  • Tech debt docs:  {count} tasks ({percent}%)
  • Security audits: {count} tasks ({percent}%)
  • Generic:         {count} tasks ({percent}%)

Completion rate:
  • DONE:        {count} ({percent}%)
  • IN_PROGRESS: {count} ({percent}%)
  • READY:       {count} ({percent}%)
  • BLOCKED:     {count} ({percent}%)
```

---

## Phase 5: System Information

### System Info Report

```
💻 System Information

Plugin installation:
  • Location: .claude-plugins/task-streams/
  • Commands: 4 (convert, validate, capabilities, status)
  • Skills: 6 (id-generator, component-manager, detect-input-type, format-*)

State storage:
  • Base path: .claude/state/task-streams/
  • Task counter: {fileSize} KB
  • Component registry: {fileSize} KB
  • Total state size: {totalSize} KB

Output directories:
  • Tasks: docs/tasks/ ({fileCount} files, {totalSize} MB)
  • Index: TASKS.md ({fileSize} KB)

Integration points:
  • Capabilities API: /task-streams:capabilities
  • Validation API: /task-streams:validate
  • Conversion API: /task-streams:convert
```

---

## Phase 6: Error States and Troubleshooting

### Error State: Task Counter Missing

```
❌ Task Counter Not Initialized

The task counter state file is missing. This is normal for first use.

📋 To initialize:
   1. Run /task-streams:convert <document> to create your first task
   2. Or manually create .claude/state/task-streams/task-counter.json:
      {
        "counter": 0,
        "tasks": {}
      }

The counter will auto-initialize on first task creation.
```

### Error State: Component Registry Missing

```
❌ Component Registry Not Initialized

The component registry state file is missing.

📋 To initialize:
   1. Run /task-streams:convert <document> to auto-initialize with defaults
   2. Or manually create .claude/state/task-streams/component-registry.json:
      {
        "nextCode": 1,
        "components": {
          "C00": {
            "name": "General / Cross-Cutting",
            "description": "Tasks that span multiple components",
            "created": "{timestamp}",
            "taskCount": 0
          }
        }
      }
```

### Warning State: Index Out of Sync

```
⚠️  TASKS.md Out of Sync

The index file has {indexedCount} tasks but {actualCount} task files exist.

📋 To fix:
   1. Regenerate TASKS.md by scanning task files
   2. Or update index manually
   3. Validate with: /task-streams:validate
```

### Warning State: Orphaned Task Files

```
⚠️  Orphaned Task Files Detected

Found {count} task files not tracked in task counter:
  • T0150-orphaned-task.md
  • T0155-another-orphan.md

Possible causes:
  • Task files created manually
  • State file was regenerated
  • Files copied from another project

📋 To fix:
   1. Delete orphaned files if unneeded
   2. Or add entries to task counter state file
   3. Run /task-streams:validate to identify all orphans
```

---

## Success Criteria

Status check is successful when:

- ✅ All state files located and readable
- ✅ Health checks complete
- ✅ Statistics calculated
- ✅ Warnings and errors clearly reported
- ✅ Actionable fix guidance provided for issues
- ✅ Verbose mode shows detailed state contents

---

## Notes

- **Idempotent**: Safe to run multiple times
- **No side effects**: Read-only operation
- **Fast**: Completes in <1 second
- **Diagnostic tool**: Primary use is debugging and health monitoring
- **Integration health**: Shows plugin ecosystem status
- **State inspection**: Reveals internal state without modifying
