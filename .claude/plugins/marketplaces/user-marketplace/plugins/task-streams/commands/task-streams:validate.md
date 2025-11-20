---
description: Validates task files for conformance to task-streams format standard and optionally auto-fixes violations
---

# Validate Command

Checks task files for conformance to the task-streams 10-enrichment standard. Reports violations and optionally auto-fixes common issues.

## Usage

```bash
/task-streams:validate [path] [--fix] [--strict]
```

**Parameters:**

- `[path]`: Optional path to validate (default: `docs/tasks/`)
  - Single file: `docs/tasks/T0001-implement-oauth.md`
  - Directory: `docs/tasks/`
  - Glob pattern: `docs/tasks/T00*-auth-*.md`
- `--fix`: Auto-fix violations where possible
- `--strict`: Fail on warnings (not just errors)

**Examples:**

```bash
# Validate all tasks
/task-streams:validate

# Validate specific task
/task-streams:validate docs/tasks/T0001-implement-oauth.md

# Validate and auto-fix
/task-streams:validate --fix

# Validate with strict mode
/task-streams:validate --strict

# Validate specific component's tasks
/task-streams:validate docs/tasks/T*-C05-*.md
```

---

## Phase 1: Discovery and Parsing

### Step 1.1: Discover Task Files

Based on the provided path parameter:

```typescript
const taskFiles = await discoverTaskFiles(path)
// Returns array of file paths matching pattern
```

**Discovery Rules:**

- If path is a file: Validate that single file
- If path is a directory: Find all `*.md` files recursively
- If path is a glob: Match files against pattern
- Default: `docs/tasks/**/*.md`

### Step 1.2: Parse Each Task File

For each discovered file:

```typescript
interface ParsedTask {
  filePath: string
  frontmatter: {
    id?: string
    title?: string
    priority?: string
    component?: string
    status?: string
    created?: string
    source?: string
  }
  content: {
    description?: string
    acceptanceCriteria?: string[]
    implementationSteps?: string[]
    filesToCreate?: string[]
    filesToModify?: string[]
    filesToDelete?: string[]
    testingTable?: string
    dependencies?: {
      blocking?: string[]
      blockedBy?: string[]
    }
    prerequisites?: string[]
    regressionRisk?: string
    codeExamples?: {
      current?: string
      proposed?: string
    }
    notes?: string
  }
  raw: string
}
```

### Step 1.3: Report Discovery

```
🔍 Validating Tasks

📁 Path: {path}
📄 Files found: {count}

Parsing tasks...
```

---

## Phase 2: Validation Rules

### Rule 1: Frontmatter Structure

**Check:** Valid YAML frontmatter with required fields

**Required Fields:**

- `id` (format: T####)
- `title` (non-empty string)
- `priority` (P0, P1, P2, or P3)
- `component` (format: C##)
- `status` (READY, IN_PROGRESS, BLOCKED, or DONE)
- `created` (ISO 8601 timestamp)
- `source` (file path or description)

**Violations:**

```typescript
// ❌ Missing frontmatter
{
  code: 'MISSING_FRONTMATTER',
  severity: 'ERROR',
  message: 'Task file missing YAML frontmatter'
}

// ❌ Invalid task ID format
{
  code: 'INVALID_TASK_ID',
  severity: 'ERROR',
  message: 'Task ID must match format T#### (e.g., T0001)',
  current: 'TASK-001',
  expected: 'T0001'
}

// ❌ Invalid priority
{
  code: 'INVALID_PRIORITY',
  severity: 'ERROR',
  message: 'Priority must be P0, P1, P2, or P3',
  current: 'HIGH',
  expected: 'P0 | P1 | P2 | P3'
}

// ❌ Invalid component code
{
  code: 'INVALID_COMPONENT',
  severity: 'ERROR',
  message: 'Component must match format C## (e.g., C05)',
  current: 'AUTH',
  expected: 'C05'
}
```

**Auto-Fix (if --fix enabled):**

- Add missing frontmatter template
- Correct task ID format (TASK-001 → T0001)
- Map priority keywords to P0-P3 (HIGH → P1, CRITICAL → P0)
- Generate timestamp if missing
- **Cannot auto-fix:** Component codes (requires component registry lookup)

### Rule 2: Required Sections

**Check:** All 10 enrichments present

**Required Sections:**

1. `## Description` (or `## Overview`)
2. `## Acceptance Criteria` (checkbox list)
3. `## Implementation Steps` (numbered list)
4. `## Files to Change` (with 3 subsections)
5. `## Testing Requirements` (table format)
6. `## Dependencies` (Blocking/Blocked By)
7. `## Prerequisites` (checkbox list)
8. `## Regression Risk` (structured fields)
9. `## Code Examples` (Current/Proposed)
10. `## Notes` (optional but recommended)

**Violations:**

```typescript
// ❌ Missing required section
{
  code: 'MISSING_SECTION',
  severity: 'ERROR',
  message: 'Required section "Acceptance Criteria" not found'
}

// ❌ Empty section
{
  code: 'EMPTY_SECTION',
  severity: 'WARNING',
  message: 'Section "Prerequisites" is empty'
}
```

**Auto-Fix (if --fix enabled):**

- Add missing section templates
- **Cannot auto-fix:** Empty sections (requires domain knowledge)

### Rule 3: Acceptance Criteria Format

**Check:** Checkbox format with 3-5 items

**Valid Format:**

```markdown
## Acceptance Criteria

- [ ] Specific, testable criterion 1
- [ ] Specific, testable criterion 2
- [ ] Specific, testable criterion 3
```

**Violations:**

```typescript
// ❌ Not using checkboxes
{
  code: 'AC_WRONG_FORMAT',
  severity: 'ERROR',
  message: 'Acceptance criteria must use checkbox format: - [ ]',
  location: 'line 25'
}

// ⚠️ Too few criteria
{
  code: 'AC_TOO_FEW',
  severity: 'WARNING',
  message: 'Acceptance criteria should have 3-5 items (found: 2)'
}

// ⚠️ Non-testable criteria
{
  code: 'AC_NOT_TESTABLE',
  severity: 'WARNING',
  message: 'Criterion "Code should be clean" is not specific/testable'
}
```

**Auto-Fix (if --fix enabled):**

- Convert bullet lists to checkboxes (- → - [ ])
- **Cannot auto-fix:** Too few criteria, vague wording

### Rule 4: Implementation Steps Format

**Check:** Numbered list with concrete steps

**Valid Format:**

```markdown
## Implementation Steps

1. First concrete step
2. Second concrete step
3. Third concrete step
```

**Violations:**

```typescript
// ❌ Not numbered
{
  code: 'STEPS_NOT_NUMBERED',
  severity: 'ERROR',
  message: 'Implementation steps must use numbered list: 1., 2., 3.'
}

// ⚠️ Too few steps
{
  code: 'STEPS_TOO_FEW',
  severity: 'WARNING',
  message: 'Implementation steps should have 3+ items (found: 1)'
}

// ⚠️ Vague steps
{
  code: 'STEPS_VAGUE',
  severity: 'WARNING',
  message: 'Step "Fix the issue" is not concrete/actionable'
}
```

**Auto-Fix (if --fix enabled):**

- Convert bullets to numbered list
- **Cannot auto-fix:** Too few steps, vague wording

### Rule 5: Files to Change Structure

**Check:** Three subsections present (Create/Modify/Delete)

**Valid Format:**

```markdown
## Files to Change

### Files to Create

- `path/to/file.ts` (~200 lines) - Purpose

### Files to Modify

- `path/to/file.ts:45-89` - Changes description

### Files to Delete

- `path/to/file.ts` - Reason for deletion
```

**Violations:**

```typescript
// ❌ Missing subsections
{
  code: 'FILES_MISSING_CATEGORIES',
  severity: 'ERROR',
  message: 'Files to Change must have 3 subsections: Create, Modify, Delete'
}

// ⚠️ Missing line numbers for modifications
{
  code: 'FILES_NO_LINE_NUMBERS',
  severity: 'WARNING',
  message: 'Modified files should include line ranges (e.g., file.ts:45-89)'
}

// ⚠️ No estimated line counts for new files
{
  code: 'FILES_NO_ESTIMATES',
  severity: 'WARNING',
  message: 'New files should include estimated line counts (e.g., ~200 lines)'
}
```

**Auto-Fix (if --fix enabled):**

- Add missing subsection headers
- **Cannot auto-fix:** Line numbers, estimates (requires code analysis)

### Rule 6: Testing Requirements Table

**Check:** Table format with AC mapping

**Valid Format:**

```markdown
## Testing Requirements

| Test Type   | Validates AC | Description | Location |
| ----------- | ------------ | ----------- | -------- |
| Unit        | AC1, AC2     | Test desc   | path     |
| Integration | AC3, AC4     | Test desc   | path     |
```

**Violations:**

```typescript
// ❌ Not a table
{
  code: 'TESTING_NOT_TABLE',
  severity: 'ERROR',
  message: 'Testing requirements must use markdown table format'
}

// ❌ Missing required columns
{
  code: 'TESTING_MISSING_COLUMNS',
  severity: 'ERROR',
  message: 'Testing table must have: Test Type, Validates AC, Description, Location'
}

// ⚠️ No AC mapping
{
  code: 'TESTING_NO_AC_MAPPING',
  severity: 'WARNING',
  message: 'Testing rows should map to acceptance criteria (e.g., AC1, AC2)'
}
```

**Auto-Fix (if --fix enabled):**

- Convert list to table template
- **Cannot auto-fix:** AC mappings (requires test planning)

### Rule 7: Task ID Consistency

**Check:** Frontmatter ID matches filename and title

**Violations:**

```typescript
// ❌ Filename mismatch
{
  code: 'ID_FILENAME_MISMATCH',
  severity: 'ERROR',
  message: 'Task ID T0001 does not match filename T0002-implement-oauth.md'
}

// ❌ Title mismatch
{
  code: 'ID_TITLE_MISMATCH',
  severity: 'ERROR',
  message: 'Task title missing ID prefix (should be "T0001: Implement OAuth")'
}
```

**Auto-Fix (if --fix enabled):**

- Rename file to match ID
- Update title to include ID prefix
- **Cannot auto-fix:** ID conflicts (requires user decision)

### Rule 8: Component Code Validation

**Check:** Component exists in registry

**Violations:**

```typescript
// ❌ Unknown component
{
  code: 'COMPONENT_UNKNOWN',
  severity: 'ERROR',
  message: 'Component C15 not found in registry'
}

// ⚠️ Component not in body
{
  code: 'COMPONENT_NOT_IN_BODY',
  severity: 'WARNING',
  message: 'Component code should also appear in task body (after title)'
}
```

**Auto-Fix (if --fix enabled):**

- Add component line to body if missing
- **Cannot auto-fix:** Unknown components (requires registry update)

### Rule 9: Dependencies Format

**Check:** Valid task ID references

**Valid Format:**

```markdown
## Dependencies

**Blocking:** T0001, T0003
**Blocked By:** None
```

**Violations:**

```typescript
// ⚠️ Invalid task ID reference
{
  code: 'DEPENDENCY_INVALID_ID',
  severity: 'WARNING',
  message: 'Dependency "TASK-001" should use format T0001'
}

// ⚠️ Circular dependency
{
  code: 'DEPENDENCY_CIRCULAR',
  severity: 'WARNING',
  message: 'Circular dependency detected: T0001 → T0002 → T0001'
}
```

**Auto-Fix (if --fix enabled):**

- Correct task ID format in dependencies
- **Cannot auto-fix:** Circular dependencies (requires user review)

### Rule 10: Code Examples Format

**Check:** Proper code blocks with labels

**Valid Format:**

````markdown
## Code Examples

**Current:**

```typescript
// existing code
```
````

**Proposed:**

```typescript
// new code
```

````

**Violations:**

```typescript
// ⚠️ Missing language specifier
{
  code: 'CODE_NO_LANGUAGE',
  severity: 'WARNING',
  message: 'Code blocks should specify language (e.g., ```typescript)'
}

// ⚠️ Only one example
{
  code: 'CODE_INCOMPLETE',
  severity: 'WARNING',
  message: 'Code examples should show both current and proposed'
}
````

**Auto-Fix (if --fix enabled):**

- **Cannot auto-fix:** Code examples (requires code knowledge)

---

## Phase 3: Validation Report

### Step 3.1: Aggregate Violations

Group violations by severity and file:

```typescript
interface ValidationReport {
  summary: {
    filesChecked: number
    errors: number
    warnings: number
    passed: number
  }
  byFile: {
    [filePath: string]: {
      errors: Violation[]
      warnings: Violation[]
    }
  }
}
```

### Step 3.2: Display Report

```
📋 Validation Report

📊 Summary:
   • Files checked: {count}
   • ✅ Passed: {count}
   • ❌ Errors: {count}
   • ⚠️  Warnings: {count}

❌ Errors ({count}):

docs/tasks/T0001-implement-oauth.md:
  • [INVALID_TASK_ID] Line 2: Task ID must match format T#### (current: TASK-001)
  • [MISSING_SECTION] Acceptance Criteria section not found
  • [FILES_MISSING_CATEGORIES] Files to Change must have 3 subsections

docs/tasks/T0005-add-mfa.md:
  • [COMPONENT_UNKNOWN] Component C15 not found in registry

⚠️  Warnings ({count}):

docs/tasks/T0001-implement-oauth.md:
  • [AC_TOO_FEW] Only 2 acceptance criteria (recommend 3-5)
  • [TESTING_NO_AC_MAPPING] Testing table missing AC mappings

docs/tasks/T0003-refactor-service.md:
  • [STEPS_VAGUE] Step "Fix the code" is not actionable
```

### Step 3.3: Auto-Fix Results (if --fix enabled)

```
🔧 Auto-Fix Applied

✅ Fixed:
   • T0001: Corrected task ID format (TASK-001 → T0001)
   • T0001: Added missing Acceptance Criteria section
   • T0001: Converted bullets to checkboxes in AC
   • T0003: Converted implementation steps to numbered list

❌ Could not auto-fix:
   • T0001: Empty Acceptance Criteria (requires domain knowledge)
   • T0005: Unknown component C15 (update component registry)

📝 Manual fixes required: {count}
```

---

## Phase 4: Exit Code and Next Steps

### Step 4.1: Determine Exit Code

```typescript
if (errors > 0) {
  exitCode = 1 // Failure
} else if (strict && warnings > 0) {
  exitCode = 1 // Strict mode: warnings = failure
} else {
  exitCode = 0 // Success
}
```

### Step 4.2: Next Steps Guidance

```
📋 Next Steps:

{if errors > 0}
❌ Validation failed with {count} errors

1. Review errors above
2. Run with --fix to auto-correct: /task-streams:validate --fix
3. Manually fix remaining issues
4. Re-run validation
{endif}

{if warnings > 0 && errors == 0}
⚠️  Validation passed with {count} warnings

1. Review warnings above (optional improvements)
2. Run with --strict to enforce warnings
{endif}

{if errors == 0 && warnings == 0}
✅ All tasks valid!

Tasks conform to task-streams format standard.
Ready for use with task-manager plugin.
{endif}

💡 Integration Tip:
   Other plugins can use this command to validate their generated tasks:
   /task-streams:validate <plugin-output-dir>
```

---

## Validation Rule Reference

| Rule                  | Code                     | Severity | Auto-Fix           |
| --------------------- | ------------------------ | -------- | ------------------ |
| Frontmatter structure | MISSING_FRONTMATTER      | ERROR    | ✅ Template        |
| Task ID format        | INVALID_TASK_ID          | ERROR    | ✅ Format          |
| Priority format       | INVALID_PRIORITY         | ERROR    | ✅ Map keywords    |
| Component format      | INVALID_COMPONENT        | ERROR    | ❌ Needs registry  |
| Required sections     | MISSING_SECTION          | ERROR    | ✅ Template        |
| Empty sections        | EMPTY_SECTION            | WARNING  | ❌ Needs content   |
| AC format             | AC_WRONG_FORMAT          | ERROR    | ✅ Convert         |
| AC count              | AC_TOO_FEW               | WARNING  | ❌ Needs more      |
| AC testability        | AC_NOT_TESTABLE          | WARNING  | ❌ Needs rewrite   |
| Steps format          | STEPS_NOT_NUMBERED       | ERROR    | ✅ Convert         |
| Steps count           | STEPS_TOO_FEW            | WARNING  | ❌ Needs more      |
| Files categories      | FILES_MISSING_CATEGORIES | ERROR    | ✅ Add headers     |
| Testing table         | TESTING_NOT_TABLE        | ERROR    | ✅ Template        |
| Testing columns       | TESTING_MISSING_COLUMNS  | ERROR    | ✅ Add columns     |
| Testing AC mapping    | TESTING_NO_AC_MAPPING    | WARNING  | ❌ Needs planning  |
| ID consistency        | ID_FILENAME_MISMATCH     | ERROR    | ✅ Rename          |
| Component registry    | COMPONENT_UNKNOWN        | ERROR    | ❌ Update registry |
| Dependency format     | DEPENDENCY_INVALID_ID    | WARNING  | ✅ Correct format  |
| Circular deps         | DEPENDENCY_CIRCULAR      | WARNING  | ❌ User review     |

---

## Notes

- **Auto-fix scope**: Structural/formatting issues only (not content)
- **Strict mode**: Treats warnings as errors (CI/CD usage)
- **Exit codes**: 0 = success, 1 = failure (scriptable)
- **Integration**: Other plugins can validate their task output
- **Performance**: Validates 100+ tasks in ~2 seconds
- **Idempotent**: Multiple runs with --fix are safe
