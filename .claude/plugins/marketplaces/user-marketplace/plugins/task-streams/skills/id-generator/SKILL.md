---
name: id-generator
description: Generate task (T####) and report (R####) IDs with rich metadata tracking. Stores creation date, source document, type, and notes for every ID. State in .claude/state/task-streams/id-generator.json (gitignored). Auto-initializes. (project, gitignored)
---

# ID Generator Skill

Deterministic TypeScript script for generating sequential task IDs and report IDs with comprehensive metadata tracking.

## Purpose

Generates IDs with full audit trail:

- **Task IDs:** T0001, T0002, T0003, ... (for extracted tasks)
- **Report IDs:** R0001, R0002, R0003, ... (for code analysis reports, bug hunts, reviews)

Each generated ID stores:

- Creation timestamp
- Source document path
- Document type (spec, adr, tech-debt, security, review, generic)
- Optional notes

## Architecture

**Embedded deterministic script** (not natural language):

- `generate.ts` - Bun/TypeScript script with operations: `--task`, `--report`, `--show`, `--reset`
- **State file:** `.claude/state/task-streams/id-generator.json` (project-specific, gitignored)
- **State location:** Uses `process.cwd()` when called from Claude Code Task agents (always the project directory)
- **Auto-initialization:** Creates state file with counter=0 on first use
- **Exit codes:** 0 (success), 1 (error/limit exceeded/missing args)
- **Output:** Returns just IDs (e.g., "T0001" or "R0001") for automation
- **Metadata tracking:** Every ID stored with creation context
- **Project isolation:** Each project maintains separate counters for tasks and reports
- **Dual counters:** Tasks and reports use independent counters (T0001, T0002 / R0001, R0002)

## Usage

### Generate Task ID

```bash
# From skill directory: .claude-plugins/task-streams/skills/id-generator/

# Minimal (source required)
bun generate.ts --task --source="docs/specs/feature.md"
# Output: T0001

# With type classification
bun generate.ts --task --source="docs/specs/api-redesign.md" --source-type="spec"
# Output: T0002

# With notes
bun generate.ts --task --source="docs/tech-debt/legacy-refactor.md" --source-type="tech-debt" --notes="High-priority refactor"
# Output: T0003
```

### Generate Report ID

```bash
# From skill directory: .claude-plugins/task-streams/skills/id-generator/

# Minimal (source required)
bun generate.ts --report --source="docs/reports/bug-hunt.json"
# Output: R0001

# With type classification
bun generate.ts --report --source="docs/reports/code-quality.json" --source-type="review"
# Output: R0002

# With notes
bun generate.ts --report --source="docs/reports/security-scan.json" --source-type="security" --notes="SQL injection findings"
# Output: R0003
```

### Show State

```bash
# Show all task and report history
bun generate.ts --show
# Output:
# Task IDs:
# =========
# Current counter: 3
# Next task ID: T0004
# Total tasks: 3
#
# Recent tasks:
#   T0003 - docs/tech-debt/legacy-refactor.md
#     Type: tech-debt
#     Notes: High-priority refactor
#     Created: 2025-11-05T10:52:18.789Z
#   ...
#
# Report IDs:
# ===========
# Current counter: 2
# Next report ID: R0003
# Total reports: 2
#
# Recent reports:
#   R0002 - docs/reports/code-quality.json
#     Type: review
#     Notes: Code quality analysis
#     Created: 2025-11-10T14:30:45.123Z
#   ...
```

### Reset State

```bash
bun generate.ts --reset
# Output: State reset (task counter = 0, report counter = 0, all history cleared)
```

## State File Structure

**Location:** `.claude/state/task-streams/id-generator.json`

**Auto-created on first use:**

```json
{
  "paddingWidth": 4,
  "counter": 0,
  "history": [],
  "reportCounter": 0,
  "reportHistory": [],
  "lastUpdated": "2025-11-05T10:49:37.631Z"
}
```

**After generating IDs:**

```json
{
  "paddingWidth": 4,
  "counter": 5,
  "history": [
    {
      "id": "T0001",
      "created": "2025-11-05T10:50:15.223Z",
      "sourceDocument": "docs/specs/auth-feature.md",
      "sourceType": "spec",
      "notes": ""
    },
    {
      "id": "T0002",
      "created": "2025-11-05T10:51:03.456Z",
      "sourceDocument": "docs/specs/api-redesign.md",
      "sourceType": "spec",
      "notes": ""
    },
    {
      "id": "T0003",
      "created": "2025-11-05T10:52:18.789Z",
      "sourceDocument": "docs/tech-debt/legacy-refactor.md",
      "sourceType": "tech-debt",
      "notes": "High-priority refactor"
    },
    {
      "id": "T0004",
      "created": "2025-11-05T10:53:45.012Z",
      "sourceDocument": "docs/security/sql-injection.md",
      "sourceType": "security",
      "notes": ""
    },
    {
      "id": "T0005",
      "created": "2025-11-05T10:54:30.234Z",
      "sourceDocument": "docs/adrs/adr-005-oauth.md",
      "sourceType": "adr",
      "notes": ""
    }
  ],
  "reportCounter": 2,
  "reportHistory": [
    {
      "id": "R0001",
      "created": "2025-11-10T14:25:12.456Z",
      "sourceDocument": "docs/reports/bug-hunt.json",
      "sourceType": "review",
      "notes": "Bug hunt: role creation failures"
    },
    {
      "id": "R0002",
      "created": "2025-11-10T14:30:45.123Z",
      "sourceDocument": "docs/reports/code-quality.json",
      "sourceType": "review",
      "notes": "Code quality analysis"
    }
  ],
  "lastUpdated": "2025-11-10T14:30:45.123Z"
}
```

## ID Format

### Task ID Format

```
T0001
│ │
│ └─ 4-digit padded sequence (0001-9999)
└─── Prefix: T (Task)
```

**Format Details:**

- **Prefix:** Always `T` (for Task)
- **Padding:** 4 digits with leading zeros
- **Range:** 0001 to 9999 (supports 9,999 tasks)
- **Sequential:** Always increments by 1

### Report ID Format

```
R0001
│ │
│ └─ 4-digit padded sequence (0001-9999)
└─── Prefix: R (Report)
```

**Format Details:**

- **Prefix:** Always `R` (for Report)
- **Padding:** 4 digits with leading zeros
- **Range:** 0001 to 9999 (supports 9,999 reports)
- **Sequential:** Always increments by 1
- **Independent:** Report counter is separate from task counter

## Integration Patterns

### With convert command

**Generate task ID when extracting from documents:**

```typescript
// In convert command

// Step 1: Extract findings/requirements from document
const findings = extractFindings(document)

// Step 2: Generate task ID for each finding
for (const finding of findings) {
  const taskId = await execBun("generate.ts", [
    "--task",
    "--source=" + sourceDocPath,
    "--source-type=" + detectedType,
    "--notes=" + finding.title,
  ])
  // taskId = "T0001", "T0002", etc.

  // Create task file with metadata
  createTaskFile(taskId, finding, {
    sourceDocument: sourceDocPath,
    sourceType: detectedType,
  })
}
```

### With format-\* skills

**Each format skill generates task IDs during extraction:**

```bash
# Example: format-bug-findings processing code review

# Extract 5 findings, generate task ID for each
for FINDING in "${FINDINGS[@]}"; do
  TASK_ID=$(bun ../id-generator/generate.ts --task --source="$SOURCE_DOC" --source-type="review" --notes="$FINDING_TITLE")
  echo "Created $TASK_ID"
done

# Output:
# Created T0001
# Created T0002
# Created T0003
# Created T0004
# Created T0005
```

### Metadata Tracking Benefits

**Full audit trail for every ID:**

```bash
# After conversion, query state to see what was created
bun generate.ts --show

# Output shows:
#   T0001 - docs/reviews/security-audit.md
#     Type: review
#     Notes: SQL injection vulnerability
#     Created: 2025-11-05T10:49:43.050Z
#
#   T0002 - docs/reviews/security-audit.md
#     Type: review
#     Notes: XSS in comment form
#     Created: 2025-11-05T10:49:47.280Z

# This provides:
# ✅ Which document each task came from
# ✅ When each task was created
# ✅ What type of document (review, spec, tech-debt, etc.)
# ✅ Optional context notes
```

## Source Types

**Supported --source-type values:**

- `review` - Code review findings
- `spec` - Technical specifications
- `adr` - Architecture Decision Records
- `tech-debt` - Technical debt assessments
- `security` - Security audits
- `generic` - Unknown/mixed content

**Type is optional but recommended for metadata tracking.**

## Exit Codes (For Automation)

```bash
# Success cases
bun generate.ts --task --source="..."   # Exit 0 (generated ID)
bun generate.ts --show                  # Exit 0 (showed state)
bun generate.ts --reset                 # Exit 0 (reset state)

# Error cases
bun generate.ts --task                  # Exit 1 (missing --source)
# Counter exceeded 9999                 # Exit 1 (limit exceeded)
bun generate.ts                         # Exit 1 (no operation specified)
```

## First Use Behavior

**When you run ANY command for the first time:**

1. Script checks for `.claude/state/task-streams/id-generator.json`
2. If not found, creates it with default:
   ```json
   {
     "paddingWidth": 4,
     "counter": 0,
     "history": [],
     "lastUpdated": "2025-11-05T..."
   }
   ```
3. Executes your command (task/show/reset)

**This means:**

- ✅ No manual setup required
- ✅ Same behavior in any project
- ✅ Clean, predictable initialization

## Counter Management

### When to Reset

**Reset counter when:**

- ✅ Starting a new project
- ✅ Testing/development iterations
- ✅ Want to restart numbering from T0001

**DON'T reset if:**

- ❌ Tasks already exist with IDs (causes duplicates)
- ❌ In production/real workflow (preserves history)

### Counter Limits

**Maximum IDs:**

- Task IDs: T0001 to T9999 (9,999 tasks)
- Report IDs: R0001 to R9999 (9,999 reports)

**If limit reached:**

- Script exits with error
- Solution: Reset counter or manually edit state file

### State File Corruption Recovery

**If state file corrupted:**

- Delete `.claude/state/task-streams/id-generator.json`
- Script will auto-recreate with counter=0 on next run
- **Warning:** This resets counter and **clears history**, may cause duplicate IDs

**Better recovery:**

- Edit state file manually
- Set counter to highest existing ID
- Preserve history array for audit trail
- Example: If highest task is T0042, set counter to 42

## History Querying Patterns

**Audit trail for generated IDs:**

```bash
# Find all tasks from a specific document
cat .claude/state/task-streams/id-generator.json | \
  jq '.history[] | select(.sourceDocument | contains("security-audit"))'

# Count tasks by source type
cat .claude/state/task-streams/id-generator.json | \
  jq '.history | group_by(.sourceType) | map({type: .[0].sourceType, count: length})'

# Find tasks created in specific date range
cat .claude/state/task-streams/id-generator.json | \
  jq '.history[] | select(.created | . >= "2025-11-05" and . < "2025-11-06")'
```

## Code Analyzer Integration

**For code-analyzer agent to generate report IDs:**

```bash
# CORRECT: Use --report flag for code analysis reports
Skill(task-streams:id-generator): "Generate a REPORT ID (use --report flag) for a code analysis report that will be saved to docs/reports/bug-hunt.json. The report type is 'review' and the notes should be 'Bug hunt: role creation failures'."

# Returns: R0001, R0002, R0003, etc.
```

**IMPORTANT:**
- Code analyzer MUST use `--report` flag (NOT `--task`)
- Report IDs use R#### prefix (NOT T####)
- Report counter is independent from task counter
- Type should typically be 'review' for code analysis

## Notes

For detailed state file architecture, jq querying patterns, recovery scenarios, and integration examples, see @reference.md.

- **Deterministic:** Script-based, not LLM-generated responses
- **Sequential:** Always increments, never skips
- **Stateful:** Every generation increments counter and stores metadata
- **Audit trail:** Full history of every ID with context
- **Automation-friendly:** Exit codes + stdout for scripting
- **Self-contained:** No external dependencies beyond Bun runtime
- **Git-friendly:** State file in .gitignore (project-specific)
- **Rich metadata:** Tracks creation date, source, type, notes for every ID
- **Dual counters:** Separate task and report tracking for different workflows
