# Execution Context Debugging Guide

## Why This Matters

When code-analyzer can't find PROJECT_INDEX.json, the Python graph scripts fail, forcing expensive fallback to ripgrep searches. This burns 3-4x more tokens.

**Without execution context**: "Scripts failed, no idea why"
**With execution context**: "Agent ran from /wrong/dir, PROJECT_INDEX.json at /right/dir/PROJECT_INDEX.json"

---

## What Gets Captured

Every report MUST include this in `observability.execution_context`:

```json
{
  "execution_context": {
    "cwd": "/Users/nathanvale/code/MPCU-Build-and-Deliver",
    "project_root": "/Users/nathanvale/code/MPCU-Build-and-Deliver",
    "git_root": "/Users/nathanvale/code/MPCU-Build-and-Deliver",
    "project_index_path": "/Users/nathanvale/code/MPCU-Build-and-Deliver/PROJECT_INDEX.json",
    "project_index_exists": false,
    "reports_dir": "/Users/nathanvale/code/MPCU-Build-and-Deliver/docs/reports",
    "working_directory_at_start": "/Users/nathanvale/code/MPCU-Build-and-Deliver"
  }
}
```

---

## How to Diagnose Issues

### Scenario 1: Graph Scripts Fail

**Symptom**: Python scripts return `"PROJECT_INDEX.json not found"`

**Check execution_context**:
```json
{
  "project_index_exists": false,  // ← Problem identified!
  "project_index_path": "/Users/nathanvale/code/MPCU-Build-and-Deliver/PROJECT_INDEX.json"
}
```

**Solution**: Run `/index` command in that project first

---

### Scenario 2: Agent Started in Wrong Directory

**Symptom**: Reports saved to wrong location, scripts can't find files

**Check execution_context**:
```json
{
  "cwd": "/Users/nathanvale/code/dotfiles",  // ← Started here
  "project_root": "/Users/nathanvale/code/MPCU-Build-and-Deliver"  // ← But analyzing this
}
```

**Solution**: Agent invocation issue - main Claude session should cd to project first

---

### Scenario 3: Git Root Mismatch

**Symptom**: Reports saved to unexpected location

**Check execution_context**:
```json
{
  "cwd": "/Users/nathanvale/code/project/apps/backend",
  "git_root": "/Users/nathanvale/code/project",  // ← Git root is parent
  "project_index_path": "/Users/nathanvale/code/project/PROJECT_INDEX.json"
}
```

**Solution**: This is fine - agent correctly uses git root for PROJECT_INDEX.json

---

## Token Impact

| Scenario | Graph Queries | Fallback Method | Token Difference |
|----------|---------------|-----------------|------------------|
| **PROJECT_INDEX.json exists** | 500 tokens | N/A | Baseline |
| **PROJECT_INDEX.json missing** | ❌ Can't use | 2000 tokens (ripgrep) | **+300% tokens** |

**Without execution_context**: You'll never know why it fell back to ripgrep
**With execution_context**: Instantly see `project_index_exists: false`

---

## How Agent Collects This

At the start of Step 4 (Save Report), agent runs:

```bash
echo "{\"cwd\":\"$(pwd)\",\"git_root\":\"$(git rev-parse --show-toplevel 2>/dev/null || echo 'N/A')\",\"project_index_exists\":$(test -f PROJECT_INDEX.json && echo 'true' || test -f $(git rev-parse --show-toplevel 2>/dev/null || pwd)/PROJECT_INDEX.json && echo 'true' || echo 'false'),\"project_index_path\":\"$(git rev-parse --show-toplevel 2>/dev/null || pwd)/PROJECT_INDEX.json\"}"
```

**Output**:
```json
{
  "cwd": "/Users/nathanvale/code/MPCU-Build-and-Deliver",
  "git_root": "/Users/nathanvale/code/MPCU-Build-and-Deliver",
  "project_index_exists": false,
  "project_index_path": "/Users/nathanvale/code/MPCU-Build-and-Deliver/PROJECT_INDEX.json"
}
```

Agent copies this into `observability.execution_context` in the JSON report.

---

## Example: Debugging R0007

**R0007 observability showed**:
```json
{
  "execution_context": {
    "project_index_exists": false,
    "project_index_path": "/Users/nathanvale/code/MPCU-Build-and-Deliver/PROJECT_INDEX.json"
  }
}
```

**Diagnosis**: PROJECT_INDEX.json doesn't exist
**Solution**: Run `/index` in MPCU-Build-and-Deliver
**Token savings**: Future analyses will use 500 token graph queries instead of 2K token ripgrep searches

---

## For Future Reports

Every code-analyzer report should include execution_context showing:
- ✅ Where agent started (cwd)
- ✅ Where git root is
- ✅ Whether PROJECT_INDEX.json exists in cwd AND git_root
- ✅ Full path where agent expected to find PROJECT_INDEX.json
- ✅ `ls` output showing if file actually exists
- ✅ For index-graph-navigator calls: sample of actual script output received

This makes debugging issues **100x easier** and prevents "why didn't it work?" mysteries.

---

## Debugging R0007 Mystery

**User observation**: "There IS a PROJECT_INDEX.json in MPCU-Build-and-Deliver, but scripts still failed"

**Possible causes with new diagnostics**:

1. **Agent never called the scripts**
   ```json
   {
     "tool_usage": [
       {
         "tool": "index-graph-navigator",
         "calls": 0,  // ← Agent skipped it entirely!
         "notes": "Did not use graph queries, went straight to ripgrep"
       }
     ]
   }
   ```

2. **Scripts were called but failed silently**
   ```json
   {
     "tool_usage": [
       {
         "tool": "index-graph-navigator",
         "calls": 1,
         "script_output_sample": "{\"status\":\"error\",\"error\":\"PROJECT_INDEX.json not found\"}",
         "notes": "Script failed, fell back to ripgrep. Check execution_context for cwd mismatch."
       }
     ]
   }
   ```

3. **Agent ran from wrong directory (monorepo subdirectory)**
   ```json
   {
     "execution_context": {
       "cwd": "/Users/nathanvale/code/MPCU-Build-and-Deliver/apps/migration-cli",
       "project_index_exists_in_cwd": false,
       "project_index_exists_in_git_root": true,
       "ls_cwd": "ls: PROJECT_INDEX.json: No such file",
       "ls_git_root": "-rw-r--r-- ... PROJECT_INDEX.json"
     }
   }
   ```
   **BUT**: Scripts search upward, so this shouldn't cause failure!

4. **Scripts work, but agent chose not to use them** (workflow violation)
   ```json
   {
     "execution_context": {
       "project_index_exists_in_git_root": true
     },
     "tool_usage": [
       {
         "tool": "index-graph-navigator",
         "calls": 0,
         "notes": "PROJECT_INDEX.json exists but agent skipped graph queries - WORKFLOW VIOLATION"
       }
     ]
   }
   ```

**Next time R0010+ runs**: Check execution_context and tool_usage to identify which scenario occurred!
