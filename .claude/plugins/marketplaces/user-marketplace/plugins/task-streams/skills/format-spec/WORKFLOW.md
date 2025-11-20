# Spec Enrichment Workflow

Detailed 12-step process for transforming raw code review specs into fully enriched task-decomposable output.

---

## Complete Workflow

### Step 1: Extract Spec Metadata

**Input:** Raw code review spec (title, description, location hint)

**Actions:**

- Parse spec priority/severity keywords
- Extract approximate file location
- Identify complexity indicators

**Output:** Basic spec structure with initial metadata

**Example:**

```
Input: "Batch operation fails without rollback"
Output:
- Priority: P0 (keyword "fails")
- Location: Likely in migration/batch code
- Complexity: HIGH (batch processing)
```

---

### Step 2: Add Specific File Locations

**Input:** Approximate location from Step 1

**Actions:**

- Search codebase for exact file and line ranges
- Use `@file.ts:lineStart-lineEnd` format
- Verify location with code inspection

**Output:** Precise file locations with line numbers

**Example:**

```
Location: `src/lib/migration/referral.ts:233-267`
```

---

### Step 3: Estimate Effort

**Input:** Spec complexity and scope

**Actions:**

- Calculate base effort from complexity
- Add research overhead (20-30%)
- Add testing overhead (30%)
- Round to nearest 0.5h

**Effort Formula:**

```typescript
baseEffort = {
  CRITICAL: 16h,
  HIGH: 8h,
  MEDIUM: 4h,
  LOW: 2h
}

totalEffort = baseEffort * (1 + researchOverhead + testingOverhead)
```

**Output:** Realistic effort estimate in hours

**Example:**

```
HIGH spec → 8h base
+ 20% research → 9.6h
+ 30% testing → 12.5h
Rounded → 12h
```

---

### Step 4: Generate Acceptance Criteria

**Input:** Spec description and requirements

**Actions:**

- Create minimum 3-5 specific, testable criteria
- Use checkbox format: `- [ ]`
- Each criterion must be verifiable
- Avoid vague statements

**Quality Check:**

- ✅ "Add null check before accessing property"
- ✅ "Test with undefined input returns default value"
- ❌ "Improve code quality" (too vague)

**Output:** 3-5 concrete acceptance criteria

**Example:**

```markdown
**Acceptance Criteria:**

- [ ] Add null check before accessing row.email
- [ ] Use default value if email missing
- [ ] Test with CSV missing email column
- [ ] Update error message to be user-friendly
- [ ] Add test coverage for missing fields
```

---

### Step 5: Assess Regression Risk

**Input:** Spec scope and dependencies

**Actions:**

- Analyze **5 dimensions** of regression risk:
  1. Impact (what breaks if this goes wrong)
  2. Blast radius (how much of system affected)
  3. Dependencies (what depends on this)
  4. Testing gaps (what isn't tested)
  5. Rollback risk (how risky to revert)

**Output:** Complete regression risk assessment

**Example:**

```markdown
**Regression Risk Details:**

- **Impact:** Migration crashes midway through processing
- **Blast Radius:** Affects all 79,995 rows if email column missing
- **Dependencies:** All contact creation flows depend on this mapper
- **Testing Gaps:** No tests for missing CSV fields
- **Rollback Risk:** Low - safe to revert, no data committed yet
```

---

### Step 6: Create Remediation Steps

**Input:** Spec description and technical approach

**Actions:**

- Create numbered list (minimum 3-5 steps)
- Each step is concrete and actionable
- Include testing and validation steps
- Specify order of operations

**Quality Check:**

- ✅ "Add try-catch wrapper around batch operation"
- ✅ "Create quarantine file for failed batch tracking"
- ❌ "Fix the code" (not specific)
- ❌ "Make it better" (not actionable)

**Output:** Step-by-step implementation guide

**Example:**

```markdown
**Implementation Steps:**

1. Add null/undefined check for row.email
2. Provide default value or conditional handling
3. Update error messages with field name
4. Add unit test for missing email field
5. Run regression tests with real CSV data
```

---

### Step 7: Add Code Examples

**Input:** Current buggy code and proposed fix

**Actions:**

- Show BOTH current and proposed code
- Use proper markdown code blocks with language tags
- Add comments explaining the issue/fix
- Keep examples concise (< 20 lines each)

**Output:** Before/after code comparison

**Example:**

````markdown
**Current Code (BUGGY):**

```typescript
function mapContactDto(row: CsvRow): ContactDto {
  return {
    email: row.email.toLowerCase(), // No null check!
  }
}
```

**Proposed Fix:**

```typescript
function mapContactDto(row: CsvRow): ContactDto {
  return {
    email: row.email ? row.email.toLowerCase() : "noemail@example.com",
  }
}
```
````

---

### Step 8: Specify File Change Scope

**Input:** Implementation approach from remediation steps

**Actions:**

- Separate into **THREE categories**:
  1. Files to Create (with estimated line counts)
  2. Files to Modify (with line ranges)
  3. Files to Delete (with deletion rationale)
- Provide justification for each change

**Output:** Complete file change manifest

**Example:**

```markdown
**Files to Create:**

- `src/lib/utils/batch-rollback.ts` (~200 lines) - Rollback compensation logic
- `src/__tests__/batch-rollback.test.ts` (~150 lines) - Unit tests

**Files to Modify:**

- `src/lib/migration/referral.ts:233-267` - Add rollback on batch failure
- `src/lib/utils/dry-run-context.ts:45-67` - Track failed batches

**Files to Delete:**

- None
```

---

### Step 9: Generate Testing Table

**Input:** Acceptance criteria and test requirements

**Actions:**

- Map each test type to specific ACs
- Include test file locations
- Cover unit, integration, and E2E levels where appropriate
- Describe what each test validates

**Table Format:**

```markdown
| Test Type | Validates AC | Description | Location |
| --------- | ------------ | ----------- | -------- |
```

**Output:** Complete testing coverage table

**Example:**

```markdown
| Test Type   | Validates AC | Description                              | Location                                       |
| ----------- | ------------ | ---------------------------------------- | ---------------------------------------------- |
| Unit        | AC1, AC2     | Test rollback compensation logic         | `src/__tests__/batch-rollback.test.ts`         |
| Integration | AC3, AC4     | Test with mock service failures          | `tests/integration/batch-failure.test.ts`      |
| E2E         | AC5          | Full migration with intentional failures | `tests/integration/referral-migration.test.ts` |
```

---

### Step 10: Extract Dependencies

**Input:** Spec context and related work

**Actions:**

- Identify tasks that must complete first (Blocking Dependencies)
- Identify tasks waiting on this one (Blocks)
- List prerequisite setup items with checkboxes
- Use task IDs (P0-001, P1-005, etc.) for traceability

**Output:** Dependency graph information

**Example:**

```markdown
**Blocking Dependencies:** P0-001 (Service factory refactoring)
**Blocks:** P1-005 (Batch retry mechanism), P2-012 (Error reporting dashboard)

**Prerequisites:**

- [ ] Mock service supports failure injection
- [ ] Dry-run context supports error tracking
- [ ] Quarantine file structure defined
```

---

### Step 11: Classify Component

**Input:** Spec subject matter and codebase area

**Actions:**

- Invoke **component-manager skill** to classify spec
- Component-manager searches existing components for match
- Creates new component if no match found
- Returns component code (C##) for use in spec

**Component-Manager Workflow:**

1. Search: "Batch processing migration" → Finds C03
2. Return: C03: Migration & Batch Processing
3. Use in spec: **Component:** C03: Migration & Batch Processing

**Output:** Component code and name

**Example:**

```markdown
**Component:** C03: Migration & Batch Processing
```

---

### Step 12: Output Enriched Spec

**Input:** All enrichments from Steps 1-11

**Actions:**

- Combine all enrichments into complete spec format
- Validate all 10 required enrichments present
- Use proper markdown formatting
- Verify template completeness

**Validation Checklist:**

- [ ] Component code from component-manager
- [ ] File locations with line ranges
- [ ] Effort estimate realistic
- [ ] Complexity classification assigned
- [ ] Regression risk (5 dimensions)
- [ ] Acceptance criteria (3-5 items with checkboxes)
- [ ] Implementation steps (numbered list)
- [ ] Code examples (current + proposed)
- [ ] File changes (3 categories)
- [ ] Testing table (maps to ACs)
- [ ] Dependencies (task IDs + prerequisites)

**Output:** Complete enriched spec ready for task decomposition

**Example:** See @EXAMPLES.md for complete enriched specs

---

## Workflow Shortcuts

### For Simple Specs (P2/P3)

Some steps can be simplified for low-priority specs:

- **Step 3 (Effort)**: Use standard estimates (P2: 4h, P3: 2h)
- **Step 5 (Regression Risk)**: Brief assessment (LOW risk for isolated changes)
- **Step 7 (Code Examples)**: Optional if fix is obvious
- **Step 8 (File Changes)**: Often just 1-2 file modifications

### For Complex Specs (P0/P1)

Expand certain steps for critical specs:

- **Step 4 (Acceptance Criteria)**: Add 6-8 criteria for comprehensive coverage
- **Step 5 (Regression Risk)**: Detailed analysis with impact quantification
- **Step 6 (Remediation Steps)**: Break into sub-phases (Preparation, Implementation, Validation, Deployment)
- **Step 9 (Testing)**: Add security tests, performance tests, compliance tests

---

## Quality Gates

Before proceeding to next step, verify:

**After Step 6 (Remediation Steps)**:

- [ ] Steps are concrete and actionable
- [ ] Order of operations is logical
- [ ] Testing/validation included

**After Step 9 (Testing Table)**:

- [ ] All ACs mapped to at least one test
- [ ] Critical ACs have multiple test types
- [ ] Test locations are specific

**After Step 12 (Output)**:

- [ ] All 10 enrichments present (see @../SHARED_ENRICHMENTS.md)
- [ ] Validation checklist passes (see @VALIDATION_CHECKLIST.md)
- [ ] Format matches template (see @EXAMPLES.md)
