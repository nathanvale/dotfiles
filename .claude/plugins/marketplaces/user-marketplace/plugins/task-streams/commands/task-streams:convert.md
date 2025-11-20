---
description: Generic document-to-tasks converter - intelligently detects input types (specs, reviews, ADRs, tech debt, security audits) and generates standardized task files
---

# Convert Command

Pure conversion tool that transforms any planning document into standardized task files. Intelligently detects input type and applies appropriate formatting.

## Usage

```bash
/task-streams:convert <document-path>
```

**Parameters:**

- `<document-path>`: Path to document file (markdown, PDF, or text)

**Examples:**

```bash
# Convert technical spec to tasks
/task-streams:convert docs/specs/auth-redesign-spec.md

# Convert code review to tasks
/task-streams:convert docs/reviews/R001-security-audit.md

# Convert ADR to implementation tasks
/task-streams:convert docs/adrs/adr-005-migration-strategy.md

# Convert tech debt analysis
/task-streams:convert docs/tech-debt/q4-assessment.md
```

---

## Phase 1: Read and Detect Input Type

### Step 1.1: Read Document

Read the provided document path:

```typescript
const content = await readFile(documentPath)
```

### Step 1.2: Detect Input Type

Use the `detect-input-type` skill to identify document type:

```typescript
const inputType = detectInputType(content, documentPath)
// Returns: 'review' | 'spec' | 'adr' | 'tech-debt' | 'security' | 'generic'
```

**Detection Heuristics:**

- **Review**: Contains P0-P3 classifications, "findings", review ID (R###)
- **Spec**: Contains "Requirements", "Acceptance Criteria", user stories, features
- **ADR**: Contains "Status: Accepted/Proposed", "Context", "Decision", "Consequences"
- **Tech Debt**: Contains "debt", "refactor", "legacy", technical quality analysis
- **Security**: Contains CVE references, OWASP, vulnerabilities, security controls
- **Generic**: Fallback for unknown types

### Step 1.3: Report Detection

```
✅ Document Type Detected
   • Path: {documentPath}
   • Type: {inputType}
   • Size: {fileSize}
   • Format skill: format-{inputType}

Parsing document...
```

---

## Phase 2: Route to Format Skill

Based on detected type, invoke the appropriate format skill:

### Format Skill Routing

```typescript
const formatSkill = {
  review: "format-bug-findings",
  spec: "format-spec",
  adr: "format-generic",
  "tech-debt": "format-tech-debt",
  security: "format-security",
  generic: "format-generic",
}[inputType]
```

### Invoke Format Skill

```
Applying {formatSkill} skill...
```

Each format skill extracts domain-specific information and transforms it into the universal task structure with 10 enrichments.

---

## Phase 3: Extract Task Metadata

### Step 3.1: Component Classification

For each extracted finding/task, invoke the **component-manager skill** to classify with component code:

**Component Classification Workflow:**

1. **Invoke component-manager skill** for each extracted item
2. **Skill performs**:
   - Searches existing components for match (fuzzy match on name)
   - If match found, returns component code (e.g., "Authentication" → C05)
   - If no match, creates new component and returns new code (e.g., C10)
3. **Use returned code** in task metadata

**Example:**

- Finding relates to: "Service Factory"
- Invoke component-manager skill
- Skill returns: C02 (Service Factory & Mode Selection)
- Include in task:

```markdown
**Component:** C02: Service Factory & Mode Selection
```

The component-manager skill manages the component registry and ensures consistent component codes across all tasks.

### Step 3.2: Generate Task IDs

For each extracted finding/task, invoke the **id-generator skill** to generate unique task IDs with metadata tracking:

**ID Generation Workflow:**

1. **Invoke id-generator skill** for each extracted item
2. **Provide metadata**:
   - `--task` flag for task ID generation
   - `--source` path to source document
   - `--source-type` document type (review, spec, adr, tech-debt, security)
   - `--notes` optional context (finding title)
3. **Skill performs**:
   - Generates sequential task ID (T0001, T0002, T0003...)
   - Stores full metadata (creation date, source, type, notes)
   - Returns task ID
4. **Use returned ID** in task frontmatter

**Example:**

- Invoke: `id-generator skill --task --source="docs/reviews/R001-audit.md" --source-type="review" --notes="SQL injection fix"`
- Returns: T0001
- Full audit trail stored in id-generator state

**Task ID Format:** T#### (T0001, T0002, T0003...)

The id-generator skill manages task ID sequencing and provides complete audit trail of all generated IDs.

### Step 3.3: Priority Classification

Ensure each task has P0-P3 priority:

- **P0 (Critical)**: Security vulnerabilities, data loss risks, system-breaking bugs
- **P1 (High)**: Significant functionality issues, performance problems
- **P2 (Medium)**: Code quality issues, technical debt, missing tests
- **P3 (Low)**: Minor improvements, style inconsistencies

If input doesn't have priorities, format skill assigns based on severity/impact.

---

## Phase 4: Generate Task Files

### Step 4.1: Create Task Files

For each extracted item, create individual task file:

**Filename Format:** `{taskId}-{slug}.md`

**Example:** `T0001-implement-oauth-flow.md`

**Location:** `docs/tasks/`

### Step 4.2: Task File Structure

````markdown
---
id: T0001
title: Implement OAuth2 authentication flow
priority: P0
component: C05
status: READY
created: 2025-11-05T14:30:22Z
source: docs/specs/auth-redesign-spec.md
---

# T0001: Implement OAuth2 authentication flow

**Component:** C05: Authentication & Authorization
**Priority:** P0 (Critical)
**Status:** READY
**Estimated Effort:** 12h
**Complexity:** CRITICAL

## Description

{Clear description of what needs to be done}

## Acceptance Criteria

- [ ] {Specific, testable criterion 1}
- [ ] {Specific, testable criterion 2}
- [ ] {Specific, testable criterion 3}
- [ ] {Specific, testable criterion 4}
- [ ] {Specific, testable criterion 5}

## Implementation Steps

1. {Concrete step 1}
2. {Concrete step 2}
3. {Concrete step 3}
4. {Concrete step 4}
5. {Concrete step 5}

## Files to Change

### Files to Create

- `src/lib/auth/oauth-client.ts` (~200 lines) - OAuth2 client implementation
- `src/lib/auth/token-manager.ts` (~150 lines) - Token storage and refresh

### Files to Modify

- `src/lib/services/auth-service.ts:45-89` - Add OAuth flow
- `src/config/auth-config.ts:12-25` - OAuth configuration

### Files to Delete

- `src/lib/auth/legacy-auth.ts` - Replaced by OAuth2

## Testing Requirements

| Test Type   | Validates AC | Description            | Location                              |
| ----------- | ------------ | ---------------------- | ------------------------------------- |
| Unit        | AC1, AC2     | Token validation tests | `tests/unit/auth/oauth.test.ts`       |
| Integration | AC3, AC4     | Full OAuth flow test   | `tests/integration/auth-flow.test.ts` |
| E2E         | AC5          | End-to-end login test  | `tests/e2e/login.spec.ts`             |

## Dependencies

**Blocking:** None
**Blocked By:** None

## Prerequisites

- [ ] Azure AD B2C tenant configured
- [ ] OAuth client credentials obtained
- [ ] Redirect URLs registered

## Regression Risk

**Impact:** High - Core authentication mechanism
**Blast Radius:** All authenticated users
**Testing Gaps:** No current OAuth tests
**Rollback Risk:** Medium - Can revert to legacy auth

## Code Examples

**Current (if applicable):**

```typescript
// Legacy authentication code
```

**Proposed:**

```typescript
// New OAuth2 implementation
```

## Notes

{Additional context, warnings, references}
````

---

## Phase 5: Update TASKS.md Index

### Step 5.1: Create or Update TASKS.md

Create a master index file at project root:

**Location:** `TASKS.md`

**Purpose:** Fast query index without reading all task files

**Structure:**

```markdown
# Tasks Index

Last updated: 2025-11-05T14:30:22Z
Total tasks: 18

## Statistics

- P0 (Critical): 3 tasks
- P1 (High): 5 tasks
- P2 (Medium): 7 tasks
- P3 (Low): 3 tasks

## Components

- C02: Service Factory (8 tasks)
- C05: Authentication (4 tasks)
- C07: Testing (3 tasks)
- C09: Documentation (3 tasks)

## Tasks

### T0001: Implement OAuth2 authentication flow

- **Priority:** P0
- **Component:** C05
- **Status:** READY
- **Effort:** 12h
- **File:** docs/tasks/T0001-implement-oauth-flow.md
- **Created:** 2025-11-05T14:30:22Z
- **Source:** docs/specs/auth-redesign-spec.md

### T0002: Add MFA support

- **Priority:** P1
- **Component:** C05
- **Status:** BLOCKED
- **Effort:** 8h
- **File:** docs/tasks/T0002-add-mfa-support.md
- **Blocked By:** T0001
- **Created:** 2025-11-05T14:30:22Z
- **Source:** docs/specs/auth-redesign-spec.md

{... rest of tasks}
```

### Step 5.2: State File Update

Update task counter state:

**Location:** `.claude/state/task-streams/task-counter.json`

```json
{
  "counter": 18,
  "tasks": {
    "T0001": {
      "created": "2025-11-05T14:30:22Z",
      "source": "docs/specs/auth-redesign-spec.md",
      "title": "Implement OAuth2 authentication flow"
    }
  }
}
```

---

## Phase 6: Report Summary

Display concise conversion summary:

```
✅ Document Conversion Complete

📄 Input Document: {documentPath}
📋 Type Detected: {inputType}
🏷️  Tasks Generated: {taskCount}

📊 Priority Breakdown:
   • P0 (Critical):  {count} tasks
   • P1 (High):      {count} tasks
   • P2 (Medium):    {count} tasks
   • P3 (Low):       {count} tasks

🏗️  Components:
   • {count} existing components used
   • {count} new components created

📁 Output Location: docs/tasks/
📑 Index Updated: TASKS.md

📋 Next Steps:
   1. Review tasks: TASKS.md
   2. Start implementing: Use task-manager plugin
   3. Validate format: /task-streams:validate

💡 Integration Tip:
   Other plugins can query task format capabilities via
   /task-streams:capabilities and validate conformance via
   /task-streams:validate
```

---

## Success Criteria

Conversion is successful when:

- ✅ Input type correctly detected
- ✅ All extracted items have task IDs (T####)
- ✅ All tasks have component codes (C##)
- ✅ All tasks have P0-P3 priorities
- ✅ **Each task includes all 10 enrichments** (description, acceptance criteria, implementation steps, files to change in 3 categories, testing requirements, dependencies, prerequisites, regression risk, code examples where applicable, notes)
- ✅ Individual task files created in docs/tasks/
- ✅ TASKS.md index updated
- ✅ State files updated (task counter, component registry)
- ✅ Output compatible with task-manager plugin

---

## 10 Required Enrichments

Every generated task must include:

1. **File Locations**: Files to Create/Modify/Delete with line ranges
2. **Effort Estimates**: Realistic time estimates (e.g., "8h", "2h")
3. **Complexity**: CRITICAL | HIGH | MEDIUM | LOW
4. **Acceptance Criteria**: 3-5 testable checkbox items `- [ ]`
5. **Regression Risk**: Impact, Blast Radius, Testing Gaps, Rollback Risk
6. **Implementation Steps**: Numbered list of concrete actions
7. **Code Examples**: Current and proposed (when applicable)
8. **Testing Table**: Maps test types to acceptance criteria
9. **Dependencies**: Blocking tasks, blocked tasks, prerequisites
10. **Component Classification**: C## code from component registry

---

## Input Type Support Matrix

| Input Type     | Status   | Format Skill        | Example Source             |
| -------------- | -------- | ------------------- | -------------------------- |
| Code Review    | ✅ Ready | format-bug-findings | `docs/reviews/R001.md`     |
| Tech Spec      | ✅ Ready | format-spec         | `docs/specs/auth-spec.md`  |
| ADR            | ✅ Ready | format-generic      | `docs/adrs/adr-005.md`     |
| Tech Debt      | ✅ Ready | format-tech-debt    | `docs/tech-debt/q4.md`     |
| Security Audit | ✅ Ready | format-security     | `docs/security/pentest.md` |
| Generic        | ✅ Ready | format-generic      | Any markdown/text          |

---

## Notes

- **Task ID format**: T0001, T0002, T0003... (managed by task-id-generator skill)
- **Component codes**: C00-C99 (managed by component-manager skill)
- **Output location**: Default docs/tasks/ (where task-manager expects files)
- **Index file**: TASKS.md provides fast queries without reading all task files
- **State persistence**: .claude/state/task-streams/ stores counters and registries
- **Pure conversion**: No live code analysis - that belongs in project-specific commands
- **Plugin integration**: Other plugins query capabilities and validate via dedicated commands
