# Component Manager Reference

## State File Architecture

**Single source of truth**: `.claude/state/task-streams/component-manager.json` (in project root)

**Design principles**:

- No config in skill directory (skill is pure code)
- State only in project (not user directory)
- Auto-initializes with C00 on first use
- Simple and predictable
- Namespaced for task-streams plugin

**State file structure:**

```json
{
  "componentPadding": 2,
  "components": {
    "C00": "General / Cross-Cutting",
    "C01": "CLI Entry & Argument Parsing",
    "C02": "Service Factory & Mode Selection"
  }
}
```

## First Use Behavior

**When you run any command for the first time:**

1. Script checks for `.claude/state/task-streams/component-manager.json`
2. If not found, creates it with default:
   ```json
   {
     "componentPadding": 2,
     "components": {
       "C00": "General / Cross-Cutting"
     }
   }
   ```
3. Executes your command (list/find/add)

**This means:**

- No manual setup required
- Same behavior in any project
- Clean, predictable initialization

## Operations

### List Components

**Human-readable output:**

```bash
bun manage.ts --list
# Output:
# Component Map:
# =============
# C00: General / Cross-Cutting
# C01: CLI Entry & Argument Parsing
# ...
```

**JSON output (for scripts):**

```bash
bun manage.ts --list --json
# Output: {"C00":"General / Cross-Cutting","C01":"CLI Entry & Argument Parsing",...}
```

### Find Component

**Exact or partial match by name:**

```bash
# Exact match
bun manage.ts --find="Service Factory"
# Output: C02
# Exit code: 0

# Partial match (case-insensitive)
bun manage.ts --find="service"
# Output: C02
# Exit code: 0

# Not found
bun manage.ts --find="Unknown"
# Output: (none)
# Exit code: 1
```

**Exit codes for automation:**

- `0` = Component found (code printed to stdout)
- `1` = Component not found

### Add Component

**Creates new component in state file:**

```bash
bun manage.ts --add="API Gateway Layer"
# Output: C09
# Saved to: .claude/state/task-streams/component-manager.json
```

**Duplicate detection:**

```bash
bun manage.ts --add="Service Factory"
# Error: Component "Service Factory" already exists as C02
# Exit code: 1
```

**Auto-incrementing codes:**

- Finds highest existing code (e.g., C03)
- Assigns next available (e.g., C04)
- Updates state file

## Integration with id-generator

The component manager works alongside the id-generator skill:

```bash
# Step 1: Get component code
COMPONENT=$(bun manage.ts --find="Service Factory")
# COMPONENT="C02"

# Step 2: Generate task ID (sequential, independent of component)
TASK_ID=$(bun ../id-generator/generate.ts --task --source="docs/review.md" --source-type="review")
# TASK_ID="T0001"

# Step 3: Use both in task frontmatter
# ---
# id: T0001
# component: C02
# ---
```

Task IDs (T0001, T0002...) are sequential and independent of component codes. Component codes (C01,
C02...) classify tasks by functional area.

## File Locations

| File                                                              | Purpose                              | Gitignored |
| ----------------------------------------------------------------- | ------------------------------------ | ---------- |
| `.claude-plugins/task-streams/skills/component-manager/manage.ts` | Component manager script (code only) | No         |
| `.claude/state/task-streams/component-manager.json`               | Component registry (project state)   | Yes        |

**Why no config in skill directory?**

- Skill is pure code (portable, reusable)
- All state belongs to the project
- Simpler mental model
- Easier to understand and debug

## Namespace Separation

**Plugin version (this):**

- State: `.claude/state/task-streams/component-manager.json`
- Scope: task-streams plugin workflows only
- Isolation: Separate from user-level component manager

**User-level version (dotfiles):**

- State: `.claude/state/component-manager.json`
- Scope: All user skills
- Usage: General-purpose component management

**Why separate?**

- Avoid conflicts between plugin and user components
- Plugin components specific to task conversion workflows
- Clear separation of concerns
