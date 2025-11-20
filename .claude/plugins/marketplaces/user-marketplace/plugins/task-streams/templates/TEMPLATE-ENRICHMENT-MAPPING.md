# Template ↔ Enrichment Mapping

**Purpose**: This document shows EXACTLY how each template includes all 10 universal enrichments
from SHARED_ENRICHMENTS.md

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    SHARED_ENRICHMENTS.md                        │
│              (Source of Truth - 10 Enrichments)                 │
│                                                                 │
│  1. File Locations                                              │
│  2. Effort Estimation                                           │
│  3. Complexity Classification                                   │
│  4. Acceptance Criteria                                         │
│  5. Regression Risk (5 dimensions!)                             │
│  6. Implementation Steps                                        │
│  7. Code Examples                                               │
│  8. File Change Scope (3 categories!)                           │
│  9. Testing Table                                               │
│  10. Dependencies & Blocking                                    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ defines
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    REQUIRED_ENRICHMENTS Array                   │
│           (template-enrichment-validator.ts)                    │
│                                                                 │
│  Maps each enrichment to:                                       │
│  - Required headings (e.g., "## Regression Risk Analysis")     │
│  - Required fields (e.g., "**Location:**")                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ validates
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                         Templates/                              │
│              (Structure-only, no content)                       │
│                                                                 │
│  bug-findings.template.md ──┐                                   │
│  spec.template.md          ├─ All include 10 enrichments        │
│  tech-debt.template.md     │  (validated by REQUIRED_ENRICHMENTS)│
│  security.template.md      │                                    │
│  generic.template.md     ──┘                                    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ guides
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Format Skills                               │
│          (Generate actual enriched content)                     │
│                                                                 │
│  format-bug-findings  ──┐                                       │
│  format-spec           ├─ Use templates as structure guide      │
│  format-tech-debt      │  Fill with actual content             │
│  format-security       │                                        │
│  format-generic      ──┘                                        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ produces
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Enriched Task Output                        │
│              (Actual content + all 10 enrichments)              │
│                                                                 │
│  Example:                                                       │
│  ### P0: Batch operation fails without rollback                │
│  **Location:** `src/lib/migration/referral.ts:233-267`         │
│  **Estimated Effort:** 8h                                       │
│  **Complexity:** HIGH                                           │
│  ... (all 10 enrichments with actual data)                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ validated by
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Output Validators                            │
│         (Check output matches template structure)               │
│                                                                 │
│  validate-finding.ts  ──┐                                       │
│  validate-spec.ts      ├─ All use REQUIRED_ENRICHMENTS          │
│  validate-tech-debt.ts │  to verify output structure            │
│  validate-security.ts  │                                        │
│  validate-generic.ts ──┘                                        │
└─────────────────────────────────────────────────────────────────┘
```

**Flow**: SHARED_ENRICHMENTS.md → Validator Array → Templates → Skills → Output → Validators

**Key Insight**: The REQUIRED_ENRICHMENTS array is the SINGLE SOURCE OF TRUTH that connects
everything!

---

## The 10 Required Enrichments

Every template MUST include these 10 enrichments. Here's how they map to template structure:

### ✅ Enrichment 1: Specific File Locations with Line Numbers

**From SHARED_ENRICHMENTS.md:**

```markdown
**Location:** `src/lib/services/service-factory.ts:125-145`
```

**In Template (Structure Only):**

```markdown
## Core Metadata

**Location:**
```

**Validator Checks For:**

- Field present: `**Location:**`
- Template has structure to hold file paths

---

### ✅ Enrichment 2: Effort Estimates in Hours

**From SHARED_ENRICHMENTS.md:**

```markdown
**Estimated Effort:** 8h
```

**In Template (Structure Only):**

```markdown
## Core Metadata

**Estimated Effort:**
```

**Validator Checks For:**

- Field present: `**Estimated Effort:**`

---

### ✅ Enrichment 3: Complexity Classification

**From SHARED_ENRICHMENTS.md:**

```markdown
**Complexity:** HIGH
```

**In Template (Structure Only):**

```markdown
## Core Metadata

**Complexity:**
```

**Validator Checks For:**

- Field present: `**Complexity:**`

---

### ✅ Enrichment 4: Concrete Acceptance Criteria

**From SHARED_ENRICHMENTS.md:**

```markdown
**Acceptance Criteria:**

- [ ] Add null check before accessing property
- [ ] Test with undefined input
- [ ] Verify error message is clear
```

**In Template (Structure Only):**

```markdown
## Acceptance Criteria

**Acceptance Criteria:**

- [ ]
- [ ]
- [ ]
```

**Validator Checks For:**

- Heading present: `## Acceptance Criteria`
- Field present: `**Acceptance Criteria:**`
- Checkbox format: `- [ ]`

---

### ✅ Enrichment 5: Regression Risk Assessment (5 DIMENSIONS!)

**From SHARED_ENRICHMENTS.md:**

```markdown
**Regression Risk Details:**

- **Impact:** Batch processing could fail silently
- **Blast Radius:** 80K records affected
- **Dependencies:** Repository layer, mock services
- **Testing Gaps:** No integration tests for batch failures
- **Rollback Risk:** Safe to revert, no data loss
```

**In Template (Structure Only):**

```markdown
## Regression Risk Analysis

**Regression Risk Details:**

- **Impact:**
- **Blast Radius:**
- **Dependencies:**
- **Testing Gaps:**
- **Rollback Risk:**
```

**Validator Checks For:**

- Heading present: `## Regression Risk Analysis`
- Field present: `**Regression Risk Details:**`
- ALL 5 dimensions present:
  - `**Impact:**`
  - `**Blast Radius:**`
  - `**Dependencies:**`
  - `**Testing Gaps:**`
  - `**Rollback Risk:**`

**⚠️ CRITICAL**: This is enrichment #5 but has 5 sub-fields that MUST all be present!

---

### ✅ Enrichment 6: Actionable Remediation Steps

**From SHARED_ENRICHMENTS.md:**

```markdown
**Implementation Steps:**

1. Wrap batch operation in try-catch
2. Add rollback compensation for partial failures
3. Log failed batch IDs to quarantine file
```

**In Template (Structure Only):**

```markdown
## Implementation Plan

**Implementation Steps:**

1.
2.
3.
```

**Validator Checks For:**

- Heading present: `## Implementation Plan`
- Field present: `**Implementation Steps:**`
- Numbered list format: `1.`, `2.`, `3.`

---

### ✅ Enrichment 7: Code Examples

**From SHARED_ENRICHMENTS.md:**

````markdown
**Current Code (BUGGY):**

```typescript
const result = data[0].field; // No bounds check!
```

**Proposed Fix:**

```typescript
if (data.length > 0) {
  const result = data[0].field;
}
```
````

**In Template (Structure Only):**

````markdown
## Code Examples

**Current Code (BUGGY):**

```typescript

```

**Proposed Fix:**

```typescript

```
````

**Validator Checks For:**

- Heading present: `## Code Examples`
- Code block markers present (even if empty)

---

### ✅ Enrichment 8: File Change Scope (3 CATEGORIES!)

**From SHARED_ENRICHMENTS.md:**

```markdown
**Files to Create:**

- `src/lib/utils/batch-rollback.ts` (~200 lines) - Rollback logic

**Files to Modify:**

- `src/lib/migration/referral.ts:233-267` - Add rollback

**Files to Delete:**

- `src/lib/migration/legacy-batch-handler.ts` - Replaced
```

**In Template (Structure Only):**

```markdown
## File Changes

## **Files to Create:**

## **Files to Modify:**

## **Files to Delete:**
```

**Validator Checks For:**

- Heading present: `## File Changes`
- ALL 3 categories present:
  - `**Files to Create:**`
  - `**Files to Modify:**`
  - `**Files to Delete:**`

**⚠️ CRITICAL**: All 3 categories MUST be present even if empty (use "- None")

---

### ✅ Enrichment 9: Required Testing Table

**From SHARED_ENRICHMENTS.md:**

```markdown
| **Required Testing:** | Test Type | Validates AC             | Description                              | Location |
| --------------------- | --------- | ------------------------ | ---------------------------------------- | -------- |
| Unit                  | AC1, AC2  | Test fixture mode guard  | `src/__tests__/service-factory.test.ts`  |          |
| Integration           | AC3, AC4  | Verify no real API calls | `tests/integration/fixture-mode.test.ts` |
```

**In Template (Structure Only):**

```markdown
## Testing Requirements

**Required Testing:** | Test Type | Validates AC | Description | Location |
|-----------|--------------|-------------|----------| | | | | |
```

**Validator Checks For:**

- Heading present: `## Testing Requirements`
- Field present: `**Required Testing:**`
- Table structure present with column headers

---

### ✅ Enrichment 10: Dependencies and Blocking Information

**From SHARED_ENRICHMENTS.md:**

```markdown
**Blocking Dependencies:** P0-001, P0-003 **Blocks:** P1-005, P2-012

**Prerequisites:**

- [ ] Fixture mode environment variable set
- [ ] Mock service infrastructure available
```

**In Template (Structure Only):**

```markdown
## Dependencies

**Blocking Dependencies:**

**Blocks:**

**Prerequisites:**

- [ ]
```

**Validator Checks For:**

- Heading present: `## Dependencies`
- Field present: `**Blocking Dependencies:**`
- Field present: `**Blocks:**`
- Field present: `**Prerequisites:**`

---

## Complete Template Example with All 10 Enrichments

Here's a COMPLETE template showing all 10 enrichments in pure structure form:

````markdown
---
templateName: bug-findings
templateVersion: 1.0.0
description: Structure for enriched bug findings and code review issues
requiredEnrichments: 10
formatSkill: format-bug-findings
---

## TASK OUTPUT FRONTMATTER STRUCTURE

- `id:` T#### format (auto-generated)
- `title:` Brief task description
- `priority:` P0, P1, P2, or P3
- `component:` C## code from component-manager
- `status:` READY, IN_PROGRESS, BLOCKED, DONE
- `created:` ISO 8601 timestamp
- `source:` Original document path

---

# [Priority]: [Title]

## Core Metadata

**Component:** `[component code]` ← NOT one of the 10 (but required)

**Location:** `[file:line]` ← ENRICHMENT #1

**Estimated Effort:** `[hours]` ← ENRICHMENT #2

**Complexity:** `[HIGH/MEDIUM/LOW]` ← ENRICHMENT #3

**Regression Risk:** `[HIGH/MEDIUM/LOW]` ← Overall level

## Description

**Description:** [task description] ← NOT one of the 10 (but required)

## Regression Risk Analysis

← ENRICHMENT #5 (Heading)

**Regression Risk Details:**

← ENRICHMENT #5 (Field)

- **Impact:** [description] ← ENRICHMENT #5 (Dimension 1/5)
- **Blast Radius:** [description] ← ENRICHMENT #5 (Dimension 2/5)
- **Dependencies:** [description] ← ENRICHMENT #5 (Dimension 3/5)
- **Testing Gaps:** [description] ← ENRICHMENT #5 (Dimension 4/5)
- **Rollback Risk:** [description] ← ENRICHMENT #5 (Dimension 5/5)

## Acceptance Criteria

← ENRICHMENT #4 (Heading)

**Acceptance Criteria:**

← ENRICHMENT #4 (Field)

- [ ] [criterion 1] ← ENRICHMENT #4 (Checkbox format)
- [ ] [criterion 2]
- [ ] [criterion 3]

## Implementation Plan

← ENRICHMENT #6 (Heading)

**Implementation Steps:**

← ENRICHMENT #6 (Field)

1. [step 1] ← ENRICHMENT #6 (Numbered list)
2. [step 2]
3. [step 3]

## Code Examples

← ENRICHMENT #7 (Heading)

**Current Code (BUGGY):**

```typescript
[buggy code here]
```

**Proposed Fix:**

```typescript
[fixed code here]
```

## File Changes

← ENRICHMENT #8 (Heading)

**Files to Create:**

← ENRICHMENT #8 (Category 1/3)

- None

**Files to Modify:**

← ENRICHMENT #8 (Category 2/3)

- None

**Files to Delete:**

← ENRICHMENT #8 (Category 3/3)

- None

## Testing Requirements

← ENRICHMENT #9 (Heading)

**Required Testing:**

← ENRICHMENT #9 (Field)

| Test Type | Validates AC | Description | Location |
| --------- | ------------ | ----------- | -------- |
|           |              |             |          |

## Dependencies

← ENRICHMENT #10 (Heading)

**Blocking Dependencies:**

← ENRICHMENT #10 (Field 1/3)

[none]

**Blocks:**

← ENRICHMENT #10 (Field 2/3)

[none]

**Prerequisites:**

← ENRICHMENT #10 (Field 3/3)

- [ ] [prerequisite]

---

## Validator Implementation

Here's how the validator checks for all 10 enrichments:

```typescript
// template-enrichment-validator.ts

export const REQUIRED_ENRICHMENTS = [
  {
    id: 1,
    name: "File Locations",
    requiredFields: ["**Location:**"],
    requiredHeadings: [],
  },
  {
    id: 2,
    name: "Effort Estimation",
    requiredFields: ["**Estimated Effort:**"],
    requiredHeadings: [],
  },
  {
    id: 3,
    name: "Complexity Classification",
    requiredFields: ["**Complexity:**"],
    requiredHeadings: [],
  },
  {
    id: 4,
    name: "Acceptance Criteria",
    requiredFields: ["**Acceptance Criteria:**"],
    requiredHeadings: ["## Acceptance Criteria"],
  },
  {
    id: 5,
    name: "Regression Risk (5 Dimensions)",
    requiredFields: [
      "**Regression Risk Details:**",
      "**Impact:**",
      "**Blast Radius:**",
      "**Dependencies:**",
      "**Testing Gaps:**",
      "**Rollback Risk:**",
    ],
    requiredHeadings: ["## Regression Risk Analysis"],
  },
  {
    id: 6,
    name: "Implementation Steps",
    requiredFields: ["**Implementation Steps:**"],
    requiredHeadings: ["## Implementation Plan"],
  },
  {
    id: 7,
    name: "Code Examples",
    requiredFields: [],
    requiredHeadings: ["## Code Examples"],
  },
  {
    id: 8,
    name: "File Change Scope (3 Categories)",
    requiredFields: ["**Files to Create:**", "**Files to Modify:**", "**Files to Delete:**"],
    requiredHeadings: ["## File Changes"],
  },
  {
    id: 9,
    name: "Testing Table",
    requiredFields: ["**Required Testing:**"],
    requiredHeadings: ["## Testing Requirements"],
  },
  {
    id: 10,
    name: "Dependencies and Blocking",
    requiredFields: ["**Blocking Dependencies:**", "**Blocks:**", "**Prerequisites:**"],
    requiredHeadings: ["## Dependencies"],
  },
] as const;

export function validateTemplateHasAllEnrichments(templateContent: string): {
  passed: boolean;
  missing: string[];
} {
  const missing: string[] = [];

  for (const enrichment of REQUIRED_ENRICHMENTS) {
    // Check headings
    for (const heading of enrichment.requiredHeadings || []) {
      if (!templateContent.includes(heading)) {
        missing.push(
          `Enrichment #${enrichment.id} (${enrichment.name}): Missing heading "${heading}"`
        );
      }
    }

    // Check fields
    for (const field of enrichment.requiredFields || []) {
      if (!templateContent.includes(field)) {
        missing.push(`Enrichment #${enrichment.id} (${enrichment.name}): Missing field "${field}"`);
      }
    }
  }

  return {
    passed: missing.length === 0,
    missing,
  };
}
```

---

## Validation Example

When you run the validator:

```bash
pnpm tsx .claude-plugins/task-streams/scripts/validate-templates.ts
```

**Output for VALID template:**

```
=== Template Validation ===

✅ bug-findings.template.md - All 10 enrichments present
   ✓ Enrichment #1: File Locations
   ✓ Enrichment #2: Effort Estimation
   ✓ Enrichment #3: Complexity Classification
   ✓ Enrichment #4: Acceptance Criteria
   ✓ Enrichment #5: Regression Risk (5 Dimensions)
   ✓ Enrichment #6: Implementation Steps
   ✓ Enrichment #7: Code Examples
   ✓ Enrichment #8: File Change Scope (3 Categories)
   ✓ Enrichment #9: Testing Table
   ✓ Enrichment #10: Dependencies and Blocking

Exit code: 0
```

**Output for INVALID template (missing enrichment #5 dimension):**

```
=== Template Validation ===

❌ bug-findings.template.md - Missing enrichments:
   ✓ Enrichment #1: File Locations
   ✓ Enrichment #2: Effort Estimation
   ✓ Enrichment #3: Complexity Classification
   ✓ Enrichment #4: Acceptance Criteria
   ✗ Enrichment #5 (Regression Risk): Missing field "**Blast Radius:**"
   ✓ Enrichment #6: Implementation Steps
   ✓ Enrichment #7: Code Examples
   ✓ Enrichment #8: File Change Scope (3 Categories)
   ✓ Enrichment #9: Testing Table
   ✓ Enrichment #10: Dependencies and Blocking

Exit code: 1
```

---

## Critical Points

### 🔴 Enrichment #5 has 6 fields total:

1. Heading: `## Regression Risk Analysis`
2. Field: `**Regression Risk Details:**`
3. Dimension 1: `**Impact:**`
4. Dimension 2: `**Blast Radius:**`
5. Dimension 3: `**Dependencies:**`
6. Dimension 4: `**Testing Gaps:**`
7. Dimension 5: `**Rollback Risk:**`

**ALL 7 must be present** for enrichment #5 to pass validation!

### 🔴 Enrichment #8 has 4 fields total:

1. Heading: `## File Changes`
2. Category 1: `**Files to Create:**`
3. Category 2: `**Files to Modify:**`
4. Category 3: `**Files to Delete:**`

**ALL 4 must be present** for enrichment #8 to pass validation!

### 🔴 Enrichment #10 has 4 fields total:

1. Heading: `## Dependencies`
2. Field 1: `**Blocking Dependencies:**`
3. Field 2: `**Blocks:**`
4. Field 3: `**Prerequisites:**`

**ALL 4 must be present** for enrichment #10 to pass validation!

---

## Summary Checklist

When creating a template, verify:

- [ ] **Enrichment #1**: `**Location:**` field present
- [ ] **Enrichment #2**: `**Estimated Effort:**` field present
- [ ] **Enrichment #3**: `**Complexity:**` field present
- [ ] **Enrichment #4**: `## Acceptance Criteria` heading + `**Acceptance Criteria:**` field +
      checkbox format
- [ ] **Enrichment #5**: `## Regression Risk Analysis` heading + `**Regression Risk Details:**`
      field + ALL 5 dimensions (Impact, Blast Radius, Dependencies, Testing Gaps, Rollback Risk)
- [ ] **Enrichment #6**: `## Implementation Plan` heading + `**Implementation Steps:**` field +
      numbered list
- [ ] **Enrichment #7**: `## Code Examples` heading + code block structure
- [ ] **Enrichment #8**: `## File Changes` heading + ALL 3 categories (Create, Modify, Delete)
- [ ] **Enrichment #9**: `## Testing Requirements` heading + `**Required Testing:**` field + table
      structure
- [ ] **Enrichment #10**: `## Dependencies` heading + ALL 3 fields (Blocking Dependencies, Blocks,
      Prerequisites)

**Total fields to check**: ~25-30 individual fields across 10 enrichments

**Validator runs automatically**: Pre-commit hook prevents invalid templates from being committed!
````
