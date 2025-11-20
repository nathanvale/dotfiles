# task-streams Plugin

Pure document-to-tasks converter with intelligent type detection. Transforms any
planning document (specs, reviews, ADRs, tech debt, security audits) into
standardized task files. Platform design with discovery API for plugin ecosystem
integration.

## Overview

**Problem:** Tasks come from many sources (specs, reviews, ADRs, tech debt docs,
security audits), but each has different structure and format.

**Solution:** task-streams is a **generic conversion tool** that:

- Intelligently detects input document type
- Applies appropriate format transformation
- Outputs standardized task files (T0001, T0002, T0003...)
- Provides discovery API for other plugins to integrate
- Validates conformance to task format standard

**Key Principle:** ONE tool that converts ANY document to tasks, not separate
tools for each input type.

## Architecture

### Pure Conversion Tool

```
┌─────────────────────┐
│  Input Documents    │
├─────────────────────┤
│ • Tech Specs        │
│ • Code Reviews      │
│ • ADRs              │──→ /convert ──→ Detect Type ──→ Format Skill
│ • Tech Debt Docs    │                                       │
│ • Security Audits   │                                       ↓
│ • Generic Markdown  │                              Task Files (T####)
└─────────────────────┘
```

### Platform Design

```
┌──────────────────────────────────────────────┐
│          task-streams Platform               │
├──────────────────────────────────────────────┤
│ /convert      │ Document → Tasks             │
│ /validate     │ Check conformance + auto-fix │
│ /capabilities │ Discovery API (JSON schema)  │
│ /status       │ Health check + statistics    │
└──────────────────────────────────────────────┘
         ↑                    ↑
         │                    │
    Other Plugins         task-manager
    (integrate)           (execute tasks)
```

## Commands

### /task-streams:convert

**Pure conversion:** Document → Task files

Intelligently detects input type (spec, review, ADR, tech debt, security) and
generates standardized task files with all 10 enrichments.

**Usage:**

```bash
/task-streams:convert <document-path>
```

**Examples:**

```bash
# Convert technical spec
/task-streams:convert docs/specs/auth-redesign-spec.md

# Convert code review
/task-streams:convert docs/reviews/R001-security-audit.md

# Convert ADR to implementation tasks
/task-streams:convert docs/adrs/adr-005-migration-strategy.md

# Convert tech debt analysis
/task-streams:convert docs/tech-debt/q4-assessment.md
```

**What it does:**

1. **Detects type** (spec, review, ADR, tech debt, security, generic)
2. **Routes to format skill** (format-spec, format-bug-findings, etc.)
3. **Generates task IDs** (T0001, T0002, T0003...)
4. **Assigns component codes** (C00-C99 from registry)
5. **Creates task files** (docs/tasks/T0001-implement-oauth.md)
6. **Updates index** (TASKS.md)
7. **Updates state** (task counter, component registry)

**Output:** Individual task files compatible with task-manager plugin

### /task-streams:validate

**Conformance checker:** Validates task files + auto-fix

Checks task files for conformance to the 10-enrichment standard and optionally
auto-fixes violations.

**Usage:**

```bash
/task-streams:validate [path] [--fix] [--strict]
```

**Examples:**

```bash
# Validate all tasks
/task-streams:validate

# Validate specific task
/task-streams:validate docs/tasks/T0001-implement-oauth.md

# Validate and auto-fix
/task-streams:validate --fix

# Strict mode (warnings = errors)
/task-streams:validate --strict
```

**What it checks:**

- ✅ Valid YAML frontmatter with required fields (id, title, priority,
  component, status, created, source)
- ✅ All 10 enrichments present (description, acceptance criteria,
  implementation steps, etc.)
- ✅ Correct formats (checkboxes for AC, numbered lists for steps, table for
  testing)
- ✅ Valid task IDs (T####), component codes (C##), priorities (P0-P3)
- ✅ Three file change categories (Create/Modify/Delete)
- ✅ Testing table maps to acceptance criteria

**Auto-fix capabilities:**

- ✅ Add missing frontmatter template
- ✅ Correct task ID format (TASK-001 → T0001)
- ✅ Map priority keywords (HIGH → P1, CRITICAL → P0)
- ✅ Convert bullets to checkboxes
- ✅ Convert lists to numbered format
- ❌ Cannot auto-fix content (requires domain knowledge)

### /task-streams:capabilities

**Discovery API:** Returns task format schema

Provides machine-readable (JSON) and human-readable (Markdown) specification of
the task format, enabling other plugins to generate conformant tasks without
knowing implementation details.

**Usage:**

```bash
/task-streams:capabilities [--format=json|yaml|markdown] [--section=<name>]
```

**Examples:**

```bash
# Get full capabilities (markdown)
/task-streams:capabilities

# Get JSON schema for programmatic integration
/task-streams:capabilities --format=json

# Get only frontmatter spec
/task-streams:capabilities --section=frontmatter --format=yaml

# Get validation rules
/task-streams:capabilities --section=validation
```

**Sections available:**

- `schema`: Complete task file structure
- `frontmatter`: Field definitions (id, title, priority, etc.)
- `enrichments`: 10 required enrichments
- `validation`: Validation rules with auto-fix info
- `examples`: Complete example task files
- `all`: Everything (default)

**Integration patterns:**

1. **Direct task generation:** Query schema, generate conformant tasks
2. **Convert-based:** Generate intermediate doc, use /convert
3. **Validation-only:** Generate tasks, validate with /validate

### /task-streams:status

**Health check:** Inspect state files + statistics

Shows plugin health, state file contents, task registry stats, and component
usage.

**Usage:**

```bash
/task-streams:status [--verbose]
```

**What it shows:**

- 📋 Task counter (current count, next ID, total created)
- 🏗️ Component registry (components, task counts)
- 📑 TASKS.md index (priorities, statuses, sync status)
- 📁 Task directory (file count, recent tasks)
- 🏥 Health checks (state file validity, data consistency)
- 📈 Usage statistics (creation rate, active components, completion rate)

## Task Format (10 Enrichments)

Every task file includes:

1. **File Locations** - Files to Create/Modify/Delete with line ranges
2. **Effort Estimates** - Realistic time (e.g., "8h", "2h")
3. **Complexity** - CRITICAL | HIGH | MEDIUM | LOW
4. **Acceptance Criteria** - 3-5 testable checkboxes `- [ ]`
5. **Regression Risk** - Impact, Blast Radius, Testing Gaps, Rollback Risk
6. **Implementation Steps** - Numbered list of concrete actions
7. **Code Examples** - Current and proposed (when applicable)
8. **Testing Table** - Maps test types to acceptance criteria
9. **Dependencies** - Blocking/blocked tasks, prerequisites
10. **Component Classification** - C## code from registry

## Task ID Format

**Format:** T#### (T0001, T0002, T0003...)

**Why simple IDs?**

- ✅ Globally unique
- ✅ Immutable (no renaming when priority/component changes)
- ✅ Sequential (easy chronological reference)
- ✅ Industry standard (like GitHub #1234, Jira PROJ-123)
- ✅ All metadata in file content, not filename

**Counter state:** `.claude/state/task-streams/task-counter.json`

## Component Codes

**Format:** C## (C00-C99)

**Purpose:** Categorize tasks by system module/component

**Examples:**

- C00: General / Cross-Cutting
- C01: CLI & User Interface
- C02: Service Factory & Mode Selection
- C05: Authentication & Authorization
- C07: Testing & QA
- C09: Documentation

**Registry state:** `.claude/state/task-streams/component-registry.json`

**Workflow:**

1. Convert detects component from document
2. Searches component registry (fuzzy match)
3. Uses existing code if found (e.g., "Auth" → C05)
4. Creates new component if needed (returns new code like C10)
5. Includes code in task metadata

**Benefits:**

- Consistent categorization across all tasks
- Filter tasks by component
- Track work distribution
- Map components to teams

## Embedded Skills

All utility skills embedded in plugin (no external dependencies):

### id-generator

Generates unique task IDs (T0001, T0002, T0003...) with rich metadata tracking.
Stores creation date, source document, type, and notes for every generated ID.

**State file:** `.claude/state/task-streams/id-generator.json`

### component-manager

Manages component registry (C00-C99) for categorizing tasks.

**State file:** `.claude/state/task-streams/component-registry.json`

### detect-input-type

Intelligently detects document type from content and filename.

**Detection heuristics:**

- **Review**: P0-P3 classifications, "findings", review ID (R###)
- **Spec**: "Requirements", "Acceptance Criteria", user stories
- **ADR**: "Status: Accepted/Proposed", "Context", "Decision"
- **Tech Debt**: "debt", "refactor", "legacy"
- **Security**: CVE references, OWASP, vulnerabilities
- **Generic**: Fallback for unknown types

### format-bug-findings

Formats code review findings to task structure.

### format-spec

Formats technical specs to task structure.

### format-security

Formats security audits to task structure.

### format-tech-debt

Formats tech debt docs to task structure.

### format-generic

Formats generic documents to task structure (fallback).

## Integration with task-manager Plugin

**task-streams produces:**

- Individual task files (docs/tasks/T####-slug.md)
- TASKS.md index for fast queries
- Component categorization
- P0-P3 priorities
- Dependency tracking

**task-manager consumes:**

- Reads TASKS.md index
- Executes tasks with /next-task
- Filters with /list-tasks
- Updates status with /mark-task

**Separation of concerns:**

- task-streams: Convert documents → tasks
- task-manager: Execute tasks → completion

## Plugin Integration Example

Other plugins can integrate with task-streams:

### Pattern 1: Query Schema, Generate Tasks

```typescript
// Your plugin code
const schema = await queryCapabilities() // /task-streams:capabilities --format=json
const task = generateTaskFollowingSchema(schema)
await writeTaskFile(task)
await validate() // /task-streams:validate <your-output>
```

### Pattern 2: Generate Doc, Convert

```typescript
// Your plugin code
await generateIntermediateDoc("my-output.md")
await convert("my-output.md") // /task-streams:convert
```

### Pattern 3: Validate Only

```typescript
// Your plugin code (custom task generation)
await generateTasks()
await validate() // /task-streams:validate
// Fix violations
```

## Workflow Example

### 1. Convert Document to Tasks

```bash
# Convert technical spec
/task-streams:convert docs/specs/auth-redesign-spec.md
```

**Output:**

```
✅ Document Conversion Complete

📄 Input Document: docs/specs/auth-redesign-spec.md
📋 Type Detected: spec
🏷️  Tasks Generated: 8

📊 Priority Breakdown:
   • P0 (Critical):  2 tasks
   • P1 (High):      3 tasks
   • P2 (Medium):    2 tasks
   • P3 (Low):       1 task

🏗️  Components:
   • 2 existing components used (C05: Auth, C07: Testing)
   • 1 new component created (C10: API Gateway)

📁 Output Location: docs/tasks/
📑 Index Updated: TASKS.md
```

### 2. Validate Tasks (Optional)

```bash
/task-streams:validate --fix
```

**Output:**

```
📋 Validation Report

📊 Summary:
   • Files checked: 8
   • ✅ Passed: 7
   • ❌ Errors: 1
   • ⚠️  Warnings: 2

🔧 Auto-Fix Applied:
   • T0002: Converted bullets to checkboxes in AC
```

### 3. Review Tasks

Check TASKS.md or individual files:

```bash
cat TASKS.md
cat docs/tasks/T0001-implement-oauth-flow.md
```

### 4. Start Implementation

Use task-manager plugin to execute:

```bash
/next-task  # From task-manager plugin
```

## Priority Classification

- **P0 (Critical)**: Security vulnerabilities, data loss risks, system-breaking
  bugs
- **P1 (High)**: Significant functionality issues, performance problems
- **P2 (Medium)**: Code quality issues, technical debt, missing tests
- **P3 (Low)**: Minor improvements, style inconsistencies

## Installation

### Local Marketplace (Development)

1. Plugin in `.claude-plugins/task-streams/` directory
2. Claude Code auto-discovers plugins
3. Commands immediately available

### Team Marketplace (Distribution)

```bash
# Package
cd .claude-plugins/task-streams
tar -czf task-streams-v1.0.0.tar.gz .

# Install
claude plugin install task-streams-v1.0.0.tar.gz
```

## Project-Specific Wrapper Pattern

Live code analysis should stay in **project-specific commands**, not in this
plugin. This plugin is a **pure conversion tool** for documents.

**Example:** `/review-referral-migration` (project command)

```markdown
## Phase 1: Pre-Flight Checks

- Verify fixture mode enabled
- Check PROJECT_INDEX.json exists
- Validate test fixtures available

## Phase 2: Run Live Analysis

- Use comprehensive-review plugin to analyze src/
- Pass domain-specific context

## Phase 3: Convert to Tasks

- Save review output to docs/reviews/
- Use /task-streams:convert to generate tasks
```

**Benefits:**

- Domain logic in project commands
- Generic conversion in plugin
- No duplication
- Clean separation of concerns

## State Files

All state stored in `.claude/state/task-streams/`:

- `task-counter.json` - Task ID counter and metadata
- `component-registry.json` - Component codes and counts

## Output Files

- `docs/tasks/T####-slug.md` - Individual task files
- `TASKS.md` - Master index for fast queries

## Validation Checklist

Before task files are complete, verify:

- [ ] All 10 enrichments present
- [ ] File changes in 3 categories (Create/Modify/Delete)
- [ ] Acceptance criteria use checkboxes (`- [ ]`)
- [ ] Implementation steps use numbered list (`1.`, `2.`)
- [ ] Testing table maps to ACs (AC1, AC2, etc.)
- [ ] Component code from registry (C##: Name)
- [ ] Valid task ID (T####)
- [ ] P0-P3 priority
- [ ] Status (READY/IN_PROGRESS/BLOCKED/DONE)

## Contributing

To extend task-streams:

1. **Add format skill** in `skills/` (must be flat, not subdirectories)
2. **Update detect-input-type** to recognize new type
3. **Update README** with examples
4. **Test with /validate**

## Notes

- **Pure conversion**: No live code analysis (that's for project commands)
- **Platform design**: Discovery API enables plugin ecosystem integration
- **Self-contained**: All skills embedded, no external dependencies
- **State persistence**: .claude/state/task-streams/ stores counters/registries
- **Task directory**: Default docs/tasks/ (configurable)
- **Index file**: TASKS.md provides fast queries without reading all files
- **Token efficient**: Reusable format skills, not duplicated per input type
- **Validation**: Auto-fix structural issues, manual fix for content
- **Integration-friendly**: Other plugins can query capabilities and validate

## License

MIT

## Version

1.0.0

## Author

Nathan Vale
