---
templateName: adhoc-task
templateVersion: 1.0.0
description: Unified task template for /start-review command - AI fills all sections
---

# Task Template Structure

This template is used by `/start-review` to generate complete, actionable tasks from code reviews or
requirements documents.

## Frontmatter Fields

```yaml
---
# === IDENTITY ===
id: { { TASK_ID } } # MPCU-NNN (auto-generated)
title: { { TITLE } } # Brief task description

# === PRIORITY & CLASSIFICATION ===
priority: { { PRIORITY } } # P0, P1, P2, P3
component: { { COMPONENT } } # C## code from component-manager (optional)

# === LIFECYCLE STATUS ===
status: READY # Always READY when created
created: { { CREATED_ISO } } # ISO 8601 timestamp
started: # Filled by create-worktree.sh
completed: # Filled on task completion
completion_date: # Filled on task completion
actual_effort: # Filled on task completion (e.g., "4h")

# === GIT INTEGRATION ===
branch: # Filled by create-worktree.sh
worktree: # Filled by create-worktree.sh

# === REVIEW LIFECYCLE (future use) ===
review_id: # R-MPCU-NNN (if from /review command)
review_status: # PENDING, APPROVED, REJECTED
review_required: false # Quality gate flag
reviewed: # ISO 8601 review date
review_report: # Path to review report

# === PROVENANCE ===
source: { { SOURCE } } # adhoc, docs/reviews/R-*.md, etc.

# === DEPENDENCIES ===
depends_on: [] # List of blocking task IDs
---
```

## Task Body Structure

```markdown
# {{PRIORITY}}: {{TITLE}}

## Core Metadata

**Component:** {{COMPONENT_NAME}} **Location:** {{FILE_PATH}}:{{LINE_NUMBER}} **Estimated Effort:**
{{EFFORT_ESTIMATE}} **Complexity:** LOW | MEDIUM | HIGH | CRITICAL **Regression Risk:** LOW | MEDIUM
| HIGH | CRITICAL

## Description

{{DESCRIPTION}}

(AI: Provide clear, concise description of what needs to be done and why)

## Regression Risk Analysis

**Regression Risk Details:**

- **Impact:** {{IMPACT}}
- **Blast Radius:** {{BLAST_RADIUS}}
- **Dependencies:** {{DEPENDENCIES}}
- **Testing Gaps:** {{TESTING_GAPS}}
- **Rollback Risk:** {{ROLLBACK_RISK}}

(AI: Analyze what could go wrong and how widespread the impact would be)

## Acceptance Criteria

- [ ] {{AC_1}}
- [ ] {{AC_2}}
- [ ] {{AC_3}}

(AI: Generate 3-5 specific, testable acceptance criteria. What must be true for this task to be
considered complete?)

## Implementation Plan

**Implementation Steps:**

1. {{STEP_1}}
2. {{STEP_2}}
3. {{STEP_3}}

(AI: Break down the work into clear, sequential steps. Be specific about what code changes are
needed where.)

## Code Examples

**Current Code (BUGGY):**

\`\`\`{{LANGUAGE}} {{CURRENT_CODE}} \`\`\`

**Proposed Fix:**

\`\`\`{{LANGUAGE}} {{PROPOSED_FIX}} \`\`\`

(AI: Extract code from review if present, or create examples based on description. Show
before/after.)

## File Changes

**Files to Create:**

- {{FILE_TO_CREATE}}

**Files to Modify:**

- {{FILE_TO_MODIFY}}:{{LINE_RANGE}} - {{DESCRIPTION}}

**Files to Delete:**

- {{FILE_TO_DELETE}}

(AI: List specific files that will be affected. Include line ranges if known.)

## Testing Requirements

**Required Testing:** | Test Type | Validates AC | Description | Location |
|-----------|--------------|-------------|----------| | {{TEST_TYPE}} | AC{{NUM}} | {{TEST_DESC}} |
{{TEST_LOCATION}} |

(AI: Create a test matrix. Map each test to specific acceptance criteria.)

## Dependencies

**Blocking Dependencies:** {{BLOCKING_DEPS}}

**Blocks:** {{BLOCKED_TASKS}}

**Prerequisites:**

- [ ] {{PREREQ_1}}

(AI: List what must be completed first, and what this task blocks)

---

## Root Cause

**Bug Type:** {{BUG_TYPE}}

**Root Cause (5 Whys):**

1. Why did this happen? {{WHY_1}}
2. Why {{WHY_1}}? {{WHY_2}}
3. Why {{WHY_2}}? {{WHY_3}}
4. Why {{WHY_3}}? {{WHY_4}}
5. Why {{WHY_4}}? {{WHY_5}}

**Contributing Factors:** {{FACTORS}}

**First Introduced:** {{WHEN_INTRODUCED}}

(AI: For bugs, perform 5 Whys analysis. For features, mark as N/A.)

## Impact Analysis

**Users Affected:** {{USERS_AFFECTED}}

**Financial:** {{FINANCIAL_IMPACT}}

**Data Corruption:** {{DATA_CORRUPTION_RISK}}

**SLA Breach:** {{SLA_IMPACT}}

(AI: Assess business impact. Who is affected and how severely?)

## Reproduction

\`\`\`bash

# Reproduction steps

{{REPRO_STEPS}} \`\`\`

(AI: For bugs, provide exact steps to reproduce. For features, provide usage examples.)

## Hotfix Decision

**Decision:** {{HOTFIX_DECISION}} **Timeline:** {{TIMELINE}} **Approach:** {{APPROACH}} **Risk:**
{{RISK}}

(AI: Assess urgency. Is this hotfix-worthy? What's the safest approach?)

## Pattern Detection

\`\`\`bash

# Search for similar patterns

{{PATTERN_SEARCH_COMMAND}} \`\`\`

(AI: Provide grep/rg commands to find similar issues in the codebase)
```

## AI Generation Guidelines

When generating a task from this template:

1. **Read the requirements carefully** - Extract all relevant information
2. **Fill ALL sections** - No section should be empty or just have placeholders
3. **Be specific** - Use actual file paths, line numbers, code snippets when available
4. **Make it actionable** - Someone should be able to implement this task without asking questions
5. **Infer intelligently** - If information is missing, make reasonable assumptions based on context
6. **Use proper formatting** - Code blocks, tables, lists should be correctly formatted
7. **Mark unknowns** - If you truly can't determine something, use "TBD" or "Unknown" rather than
   guessing
8. **Keep it concise** - Detailed but not verbose. Every section should add value.

## Example Placeholders Reference

- `{{TASK_ID}}`: MPCU-001, MPCU-002, etc.
- `{{TITLE}}`: Brief title (50 chars max)
- `{{PRIORITY}}`: P0, P1, P2, P3
- `{{COMPONENT}}`: C10, C12, etc. (from component codes)
- `{{CREATED_ISO}}`: 2025-11-18T12:34:56Z
- `{{SOURCE}}`: adhoc, docs/reviews/R-MPCU-001.md, etc.
- `{{DESCRIPTION}}`: Multi-paragraph description
- `{{FILE_PATH}}`: src/commands/migrate-referrals.ts
- `{{LINE_NUMBER}}`: 104 or 104-133 (range)
- `{{EFFORT_ESTIMATE}}`: 2h, 4h, 1d, etc.
- `{{LANGUAGE}}`: typescript, python, bash, etc.
- `{{AC_N}}`: Specific, testable acceptance criterion
- `{{STEP_N}}`: Implementation step
- `{{TEST_TYPE}}`: Unit, Integration, E2E, Manual
