# ID Generator Reference

## State File Architecture

**Single source of truth**: `.claude/state/task-streams/id-generator.json` (in project root)

**Design principles**:

- Tracks task IDs with rich metadata
- Full audit trail with creation timestamps
- Auto-initializes on first use
- Namespaced for task-streams plugin

## Metadata Fields

Every generated ID stores:

| Field            | Type     | Description                                         | Required |
| ---------------- | -------- | --------------------------------------------------- | -------- |
| `id`             | string   | Generated ID (T0001)                                | Yes      |
| `created`        | ISO 8601 | Creation timestamp                                  | Yes      |
| `sourceDocument` | string   | Path to source document                             | Yes      |
| `sourceType`     | string   | Document type (spec/adr/tech-debt/security/generic) | No       |
| `notes`          | string   | Optional context notes                              | No       |

## State File Format

```json
{
  "counter": 5,
  "history": [
    {
      "created": "2025-11-05T10:50:15.223Z",
      "id": "T0001",
      "notes": "",
      "sourceDocument": "docs/specs/auth-feature.md",
      "sourceType": "spec"
    },
    {
      "created": "2025-11-05T10:51:03.456Z",
      "id": "T0002",
      "notes": "",
      "sourceDocument": "docs/specs/api-redesign.md",
      "sourceType": "spec"
    },
    {
      "created": "2025-11-05T10:52:18.789Z",
      "id": "T0003",
      "notes": "High-priority refactor",
      "sourceDocument": "docs/tech-debt/legacy-refactor.md",
      "sourceType": "tech-debt"
    }
  ],
  "lastUpdated": "2025-11-05T10:54:30.234Z",
  "paddingWidth": 4
}
```

## Operations

### Generate Task ID

```bash
# Minimal
bun generate.ts --task --source="docs/specs/feature.md"
# Output: T0001
# Exit code: 0

# With metadata
bun generate.ts --task --source="docs/specs/api.md" --source-type="spec" --notes="API redesign task"
# Output: T0002
# Exit code: 0

# Missing source
bun generate.ts --task
# Error: --source required when generating task ID
# Exit code: 1
```

### Show State

```bash
# Show all task history
bun generate.ts --show
# Displays full state with recent history
# Exit code: 0
```

### Reset State

```bash
bun generate.ts --reset
# Output: State reset (counter = 0, history cleared)
# Exit code: 0
```

## History Querying with jq

**Find all tasks from specific document:**

```bash
cat .claude/state/task-streams/id-generator.json | \
  jq '.history[] | select(.sourceDocument | contains("security"))'
```

**Count tasks by source type:**

```bash
cat .claude/state/task-streams/id-generator.json | \
  jq '.history | group_by(.sourceType) | map({type: .[0].sourceType, count: length})'
```

**Find tasks created today:**

```bash
TODAY=$(date +%Y-%m-%d)
cat .claude/state/task-streams/id-generator.json | \
  jq --arg today "$TODAY" '.history[] | select(.created | startswith($today))'
```

**List all task IDs:**

```bash
cat .claude/state/task-streams/id-generator.json | \
  jq -r '.history[].id'
```

**Get latest 10 tasks:**

```bash
cat .claude/state/task-streams/id-generator.json | \
  jq '.history | .[-10:]'
```

## Integration with Convert Command

```bash
# Example: Convert specification document

# Step 1: Extract requirements from document
# (format-spec skill does this)

# Step 2: Generate task ID for each requirement
for REQUIREMENT in "${REQUIREMENTS[@]}"; do
  TASK_ID=$(bun ../id-generator/generate.ts --task \
    --source="docs/specs/feature-spec.md" \
    --source-type="spec" \
    --notes="$REQUIREMENT_TITLE")

  # Create task file
  create_task_file "$TASK_ID" "$REQUIREMENT"
done
```

## Audit Trail Benefits

**Question:** Which tasks came from the security audit?

```bash
cat .claude/state/task-streams/id-generator.json | \
  jq '.history[] | select(.sourceDocument | contains("security-audit"))'
```

**Question:** When was task T0042 created?

```bash
cat .claude/state/task-streams/id-generator.json | \
  jq '.history[] | select(.id == "T0042")'
```

**Question:** How many tasks were generated from specs vs reviews?

```bash
cat .claude/state/task-streams/id-generator.json | \
  jq '[.history[] | .sourceType] | group_by(.) | map({type: .[0], count: length})'
```

## File Locations

| File                                                           | Purpose                                 | Gitignored |
| -------------------------------------------------------------- | --------------------------------------- | ---------- |
| `.claude-plugins/task-streams/skills/id-generator/generate.ts` | ID generator script (code only)         | No         |
| `.claude/state/task-streams/id-generator.json`                 | ID registry with history (project state | Yes        |

**Why no config in skill directory?**

- Skill is pure code (portable, reusable)
- All state belongs to the project
- Simpler mental model
- Easier to understand and debug

## Namespace Separation

**Plugin version (this):**

- State: `.claude/state/task-streams/id-generator.json`
- Scope: task-streams plugin workflows only
- IDs: T#### (tasks only)
- History: Full metadata for every ID

**User-level version (dotfiles):**

- State: `.claude/state/ticket-generator.json`
- Scope: All user skills
- IDs: R###, TASK-###, BUG-### (multiple prefixes)
- History: Counter-only (no metadata)

**Why separate?**

- Avoid conflicts between plugin IDs and user ticket IDs
- Plugin tracks rich metadata (source document, type, notes)
- User tickets are simple counters for general use
- Clear separation of concerns

## Padding Configuration

**Current default:**

```json
{
  "paddingWidth": 4
}
```

**Modifying padding:**

- Edit state file manually
- Change `paddingWidth` value
- Future IDs will use new padding
- **Warning:** Existing IDs remain unchanged (no migration)

**Example:** Increase task padding to 5 digits

```json
{
  "paddingWidth": 5
}
```

Next task ID will be `T00001` instead of `T0001`.

## Recovery Scenarios

**Scenario 1: State file deleted**

- Script auto-recreates with counter=0
- **Problem:** History lost, may create duplicate IDs
- **Solution:** Restore from backup if available

**Scenario 2: Counter drift**

- Manual task creation without using generator
- Counter is lower than actual highest ID
- **Problem:** May generate duplicate IDs
- **Solution:** Edit state file, set counter to highest existing ID

**Scenario 3: Corrupted JSON**

- Invalid JSON in state file
- **Problem:** Script fails to load state
- **Solution:** Fix JSON syntax or delete and restart

**Scenario 4: Counter at limit (T9999)**

- Counter exceeded maximum value
- **Problem:** Script exits with error
- **Solution:** Reset counter or increase padding width (requires manual state edit)
