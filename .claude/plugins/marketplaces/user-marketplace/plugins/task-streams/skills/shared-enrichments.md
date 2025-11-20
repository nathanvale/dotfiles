# 10 Required Enrichments for All Task Formats

This document defines the 10 universal enrichments required for all task output, regardless of
source format (code reviews, specs, security audits, tech debt, or generic documents).

**Used by:** format-bug-findings, format-spec, format-tech-debt, format-security, format-generic

---

## 1. Specific File Locations with Line Numbers

**Format:** `` `file.ts:lineStart-lineEnd` ``

**Example:**

```markdown
**Location:** `src/lib/services/service-factory.ts:125-145`
```

**Requirements:**

- Use backtick formatting for parseability
- Include line ranges, not just line numbers
- Be specific to exact file locations

---

## 2. Effort Estimates in Hours

**Format:** `{number}h`

**Examples:**

- `0.5h` - Quick fix (under 1 hour)
- `4h` - Half day task
- `8h` - Full day task
- `16h` - Multi-day task

**Guidance:**

- Include research/testing time
- Round to nearest 0.5h
- Be realistic, not optimistic

---

## 3. Complexity Classification

**Values:** `CRITICAL | HIGH | MEDIUM | LOW`

**Criteria:**

- **CRITICAL**: System-breaking, data loss risk, security vulnerability
- **HIGH**: Significant functionality impact, complex changes
- **MEDIUM**: Moderate impact, straightforward implementation
- **LOW**: Minor improvements, simple changes

---

## 4. Concrete Acceptance Criteria

**Requirements:**

- Minimum 3-5 specific, testable criteria
- Use checkbox format: `- [ ]`
- Each criterion must be verifiable
- Avoid vague statements

**Example:**

```markdown
**Acceptance Criteria:**

- [ ] Add null check before accessing property
- [ ] Test with undefined input
- [ ] Verify error message is clear
- [ ] Update tests to cover edge case
- [ ] Document behavior in README
```

---

## 5. Regression Risk Assessment

**Required Fields:**

```markdown
**Regression Risk Details:**

- **Impact:** {What breaks if this goes wrong}
- **Blast Radius:** {How much of the system is affected}
- **Dependencies:** {What other systems/components depend on this}
- **Testing Gaps:** {What isn't currently tested}
- **Rollback Risk:** {How risky is reverting this change}
```

**Example:**

```markdown
**Regression Risk Details:**

- **Impact:** Batch processing could fail silently
- **Blast Radius:** 80K records affected
- **Dependencies:** Repository layer, mock services
- **Testing Gaps:** No integration tests for batch failures
- **Rollback Risk:** Safe to revert, no data loss
```

---

## 6. Actionable Remediation Steps

**Requirements:**

- Use numbered list format
- Step-by-step implementation guide
- Concrete actions, not vague suggestions
- Minimum 3-5 steps

**Example:**

```markdown
**Remediation Steps:**

1. Wrap batch operation in try-catch
2. Add rollback compensation for partial failures
3. Log failed batch IDs to quarantine file
4. Test with intentional failures
5. Update dry-run context to track failed batches
```

---

## 7. Code Examples (When Possible)

**Requirements:**

- Show BOTH buggy and fixed code (or current vs proposed)
- Use proper markdown code blocks
- Include language tag for syntax highlighting
- Add comments explaining the issue/improvement

**Example:**

````markdown
**Current Code (BUGGY):**

```typescript
const result = data[0].field; // No bounds check!
```

**Proposed Fix:**

```typescript
if (data.length > 0) {
  const result = data[0].field;
} else {
  throw new Error("No data available");
}
```
````

---

## 8. File Change Scope (THREE CATEGORIES)

**CRITICAL:** Always separate into these three categories:

### Files to Create

```markdown
**Files to Create:**

- `src/lib/utils/batch-rollback.ts` (~200 lines) - Rollback compensation logic
- `src/__tests__/batch-rollback.test.ts` (~150 lines) - Unit tests
```

### Files to Modify

```markdown
**Files to Modify:**

- `src/lib/migration/referral.ts:233-267` - Add rollback on batch failure
- `src/lib/utils/dry-run-context.ts:45-67` - Track failed batches
- `src/lib/mocks/mock-dataverse.ts:123-145` - Add failure simulation
```

### Files to Delete

```markdown
**Files to Delete:**

- `src/lib/migration/legacy-batch-handler.ts` - Replaced by new rollback logic
```

**Guidelines:**

- Estimate line counts for new files
- Include line ranges for modifications
- Provide deletion rationale
- If a category is empty, explicitly state: `- None`

---

## 9. Required Testing Table

**Format:**

```markdown
| **Required Testing:** | Test Type | Validates AC                  | Description                                    | Location |
| --------------------- | --------- | ----------------------------- | ---------------------------------------------- | -------- |
| Unit                  | AC1, AC2  | Test fixture mode guard       | `src/__tests__/service-factory.test.ts`        |          |
| Integration           | AC3, AC4  | Verify no real API calls made | `tests/integration/fixture-mode.test.ts`       |
| E2E                   | AC5       | Full migration dry-run test   | `tests/integration/referral-migration.test.ts` |
```

**Requirements:**

- Map test types to acceptance criteria
- Include test file locations with backticks
- Describe what each test validates
- Cover unit, integration, and E2E levels where appropriate

---

## 10. Dependencies and Blocking Information

**Format:**

```markdown
**Blocking Dependencies:** P0-001, P0-003 **Blocks:** P1-005, P2-012

**Prerequisites:**

- [ ] Fixture mode environment variable set
- [ ] Mock service infrastructure available
- [ ] Test CSV data sanitized
```

**Requirements:**

- List tasks that must complete first (Blocking Dependencies)
- List tasks waiting on this one (Blocks)
- Include prerequisite setup items with checkboxes
- Use task IDs (P0-001, P1-005, etc.) for traceability

---

## Complete Task Template

Use this template for EVERY task:

````markdown
### {Priority}: {Task Title}

**Component:** {C##: Component Name from component-manager skill} **Location:**
`{file.ts:lineStart-lineEnd}` **Estimated Effort:** {X}h **Complexity:** {CRITICAL | HIGH | MEDIUM |
LOW} **Regression Risk:** {HIGH | MEDIUM | LOW}

**Description:** {Clear description of the work. 2-4 sentences explaining what needs to be done and
why it matters.}

**Regression Risk Details:**

- **Impact:** {What breaks if this goes wrong}
- **Blast Radius:** {How much of the system is affected}
- **Dependencies:** {What other systems/components depend on this}
- **Testing Gaps:** {What isn't currently tested}
- **Rollback Risk:** {How risky is reverting this change}

**Acceptance Criteria:**

- [ ] {Specific, testable criterion 1}
- [ ] {Specific, testable criterion 2}
- [ ] {Specific, testable criterion 3}
- [ ] {Specific, testable criterion 4}
- [ ] {Specific, testable criterion 5}

**Implementation Steps:**

1. {First concrete step}
2. {Second concrete step}
3. {Third concrete step}
4. {Fourth concrete step}
5. {Fifth concrete step}

**Current Code (if applicable):**

```{language}
// Current implementation or problematic code
```

**Proposed Implementation:**

```{language}
// Corrected or new implementation
```

**Files to Create:**

- `path/to/new/file.ts` (~200 lines) - Description of purpose
- `path/to/another/new/file.ts` (~100 lines) - Description of purpose

**Files to Modify:**

- `path/to/existing/file.ts:233-267` - Description of changes
- `path/to/another/file.ts:45-67` - Description of changes
- `path/to/third/file.ts:123-145` - Description of changes

**Files to Delete:**

- `path/to/obsolete/file.ts` - Reason for deletion
- `path/to/another/obsolete/file.ts` - Reason for deletion

| **Required Testing:** | Test Type | Validates AC                  | Description                                    | Location |
| --------------------- | --------- | ----------------------------- | ---------------------------------------------- | -------- |
| Unit                  | AC1, AC2  | Test fixture mode guard       | `src/__tests__/service-factory.test.ts`        |          |
| Integration           | AC3, AC4  | Verify no real API calls made | `tests/integration/fixture-mode.test.ts`       |
| E2E                   | AC5       | Full migration dry-run test   | `tests/integration/referral-migration.test.ts` |

**Blocking Dependencies:** {P0-001, P0-003, or "None"} **Blocks:** {P1-005, P2-012, or "None"}

**Prerequisites:**

- [ ] {Required setup item 1}
- [ ] {Required setup item 2}
- [ ] {Required setup item 3}
````

---

## Validation Checklist

Before finalizing a task, verify:

- [ ] **All 10 enrichments present** (location, effort, complexity, acceptance criteria, regression
      risk, implementation steps, code examples, file changes, testing table, dependencies)
- [ ] **File changes separated into 3 categories** (Create, Modify, Delete)
- [ ] **Acceptance criteria use checkboxes** (`- [ ]`)
- [ ] **Implementation steps use numbered list** (`1.`, `2.`, etc.)
- [ ] **Testing table maps to ACs** (AC1, AC2, etc.)
- [ ] **Component code from component-manager skill** (C##: Name)
- [ ] **Location uses backticks** (`` `file.ts:start-end` ``)
- [ ] **Effort estimate realistic** (includes research/testing)
- [ ] **Code examples show current AND proposed** (when applicable)
- [ ] **Dependencies use task IDs** (P0-001, P1-005, etc.)

---

## Component Classification

**Use component-manager skill for classification:**

When formatting a task, invoke the **component-manager skill** to find or create the appropriate
component code. The component-manager skill will:

1. Search existing components for a match (e.g., "Service Factory" → C02)
2. Create a new component if no match found
3. Return the component code for use in the Component field

**Example workflow:**

- Task relates to: "Service Factory"
- Component-manager skill returns: C02 (Service Factory & Mode Selection)
- Use in task: **Component:** C02: Service Factory & Mode Selection

The component-manager skill manages the component registry and ensures consistent component codes
across all tasks.

---

## Notes

- These 10 enrichments are universal across ALL task types (bugs, features, security, tech debt,
  specs, generic)
- Component classification enables cross-review task tracking
- Three file categories (Create/Modify/Delete) are critical for accurate work estimation
- Testing table ensures traceability to acceptance criteria
- Dependency tracking enables proper task sequencing
- Output is directly compatible with task decomposition workflows
