---
name: component-manager
description: Manage component registry for task categorization. List, find, and add components. State stored in .claude/state/task-streams/component-manager.json (gitignored). Auto-initializes with C00 "General / Cross-Cutting" on first use. Returns component codes like C01, C02. Use when user says 'list components', 'add component', 'find component', 'categorize tasks by component', or when organizing tasks by system module. (project, gitignored)
---

# Component Manager Skill

Deterministic TypeScript script for managing component registry (C00-C99) to categorize tasks by system module.

## Purpose

Maintains consistent component classification system for:

- **Filtering:** "Show me all Authentication tasks (C05)"
- **Ownership:** "These 15 tasks belong to Frontend team (C08)"
- **Planning:** "How much work in Service Factory component (C02)?"
- **Metrics:** "Which components have most tech debt?"

## Architecture

**Embedded deterministic script** (not natural language):

- `manage.ts` - Bun/TypeScript script with operations: `--list`, `--find`, `--add`
- **State file:** `.claude/state/task-streams/component-manager.json` (project-specific, gitignored)
- **State location:** Uses `process.cwd()` when called from Claude Code Task agents (always the project directory)
- **Auto-initialization:** Creates state file with C00 on first use
- **Exit codes:** 0 (success), 1 (error/not found)
- **Output:** Returns just component codes (e.g., "C02") for automation
- **Project isolation:** Each project maintains its own component registry

## Usage

**All operations use the embedded manage.ts script:**

```bash
# From skill directory: .claude-plugins/task-streams/skills/component-manager/

# List all components (human-readable)
bun manage.ts --list
# Output:
# Component Map:
# =============
# C00: General / Cross-Cutting
# C01: CLI Entry & Argument Parsing
# ...

# List components (JSON for scripts)
bun manage.ts --list --json
# Output: {"C00":"General / Cross-Cutting","C01":"CLI Entry & Argument Parsing",...}

# Find component by name (exact or partial match)
bun manage.ts --find="Service Factory"
# Output: C02
# Exit code: 0 (found)

bun manage.ts --find="Auth"
# Output: C05
# Exit code: 0 (partial match)

bun manage.ts --find="Unknown"
# Output: (none)
# Exit code: 1 (not found)

# Add new component (auto-increments code)
bun manage.ts --add="API Gateway Layer"
# Output: C09
# Saves to: .claude/state/task-streams/component-manager.json

# Duplicate detection
bun manage.ts --add="Service Factory"
# Error: Component "Service Factory" already exists as C02
# Exit code: 1
```

## State File Structure

**Location:** `.claude/state/task-streams/component-manager.json`

**Auto-created on first use:**

```json
{
  "componentPadding": 2,
  "components": {
    "C00": "General / Cross-Cutting"
  }
}
```

**After adding components:**

```json
{
  "componentPadding": 2,
  "components": {
    "C00": "General / Cross-Cutting",
    "C01": "CLI Entry & Argument Parsing",
    "C02": "Service Factory & Mode Selection",
    "C03": "Data Layer / Repositories"
  }
}
```

## Integration Patterns

### With format-\* skills

**During task extraction, classify with component:**

```typescript
// In format-spec, format-bug-findings, etc.

// 1. Extract component name from finding
const componentName = extractComponentName(finding)
// Example: "Authentication service" → "Authentication"

// 2. Find or create component
const componentCode = await execBun("manage.ts", ["--find=" + componentName])
// If exit code 1 (not found):
const newCode = await execBun("manage.ts", ["--add=" + componentName])

// 3. Include in task metadata
task.component = componentCode
task.componentName = componentName
```

### With id-generator

**Component codes used in task metadata:**

```bash
# Step 1: Get component code
COMPONENT=$(bun manage.ts --find="Service Factory")
# COMPONENT="C02"

# Step 2: Generate task ID (sequential, independent of component)
TASK_ID=$(bun ../id-generator/generate.ts --task --source="docs/review.md" --source-type="review")
# TASK_ID="T0001"

# Step 3: Use component code in task frontmatter
# ---
# id: T0001
# component: C02
# ---
```

### With validate command

**Validate component references in task files:**

```bash
# Extract component from task frontmatter
COMPONENT=$(grep 'component:' task.md | cut -d' ' -f2)

# Verify component exists
if ! bun manage.ts --find="$COMPONENT" > /dev/null 2>&1; then
  echo "❌ Component $COMPONENT not in registry"
  echo "💡 Add with: bun manage.ts --add='Component Name'"
fi
```

## Component Code Format

- **Format:** C## (C with 2 digits)
- **Range:** C00-C99 (supports 100 components)
- **Reserved:** C00 always = "General / Cross-Cutting"
- **Padding:** Always 2 digits with leading zero
- **Sequential:** Auto-assigned C01, C02, C03...
- **Permanent:** Codes never reused after deletion

## Exit Codes (For Automation)

```bash
# Success cases
bun manage.ts --list           # Exit 0 (always)
bun manage.ts --find="Name"    # Exit 0 (found)
bun manage.ts --add="New"      # Exit 0 (created)

# Error cases
bun manage.ts --find="Unknown" # Exit 1 (not found)
bun manage.ts --add="Exists"   # Exit 1 (duplicate)
bun manage.ts                  # Exit 1 (no operation specified)
```

## First Use Behavior

**When you run ANY command for the first time:**

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

- ✅ No manual setup required
- ✅ Same behavior in any project
- ✅ Clean, predictable initialization

## Best Practices

### Component Granularity

**Too broad:**

```
❌ C01: Backend (hundreds of tasks)
```

**Too narrow:**

```
❌ C15: UserService.validateEmail() method (1-2 tasks)
```

**Just right:**

```
✅ C02: User Management (reasonable number of tasks)
✅ C05: Authentication (logical grouping)
```

### Naming Conventions

**Good names:**

- Clear: "Authentication & Authorization"
- Specific: "Service Factory & Mode Selection"
- Descriptive: "CSV Parsing & Validation"

**Avoid:**

- Vague: "Utilities", "Helpers", "Misc"
- Too long: "The authentication and authorization subsystem including OAuth2 and MFA"
- Abbreviations without context: "DI Container"

### When to Create New Components

**Create new component when:**

- ✅ Multiple tasks (3+) share same area
- ✅ Logical architectural boundary exists
- ✅ Different team/person owns it
- ✅ Filtering by this would be useful

**Don't create for:**

- ❌ One-off tasks (use C00: General)
- ❌ Temporary concepts
- ❌ Sub-components (part of larger component)

## Error Handling

**Component limit reached (C99):**

```
⚠️  Component registry approaching limit (C99)
💡 Consider consolidating similar components
```

**State file corrupted:**

- Delete `.claude/state/task-streams/component-manager.json`
- Script will auto-recreate with C00 on next run
- Re-add components as needed

## Comparison with User-Level Component Manager

**This plugin version:**

- State: `.claude/state/task-streams/component-manager.json`
- Scope: task-streams plugin only
- Namespace: task-streams/ subdirectory

**User-level version (dotfiles):**

- State: `.claude/state/component-manager.json`
- Scope: All user skills
- Namespace: No subdirectory

**Why separate?**

- Avoid conflicts between plugin and user components
- Plugin components specific to task-streams workflow
- User components for general-purpose use

## Notes

For detailed state file architecture, component naming conventions, querying patterns, and integration examples, see @reference.md.

- **Deterministic:** Script-based, not LLM-generated responses
- **Idempotent:** Same input always produces same output
- **Automation-friendly:** Exit codes + stdout for scripting
- **Self-contained:** No external dependencies beyond Bun runtime
- **Git-friendly:** State file in .gitignore (project-specific)
