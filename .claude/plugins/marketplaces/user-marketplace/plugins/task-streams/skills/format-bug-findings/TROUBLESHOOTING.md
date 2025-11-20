# Troubleshooting Guide

Common issues when enriching bug findings and their solutions.

---

## Issue 1: Cannot Determine File Location

**Symptom**: Finding description mentions issue but doesn't specify file/line numbers

**Causes**:

- Generic code review comment ("batch processing has issues")
- Multi-file issue without specifics
- High-level architectural concern

**Solutions**:

1. **Search codebase** for relevant keywords:

   ```bash
   grep -r "batch" src/lib/migration/
   ```

2. **Analyze code structure** to infer location:
   - Batch processing → likely `src/lib/migration/`
   - CSV parsing → likely `src/lib/adapters/`
   - API calls → likely `src/lib/services/`

3. **Use multiple locations** if issue spans files:

   ```markdown
   **Location:**

   - `src/lib/migration/referral.ts:233-267`
   - `src/lib/utils/dry-run-context.ts:45-67`
   ```

4. **Mark as TBD** if truly unknown:
   ```markdown
   **Location:** `TBD - requires codebase analysis`
   ```

---

## Issue 2: Effort Estimation Too Uncertain

**Symptom**: Can't determine realistic hours for complex/vague findings

**Causes**:

- Unclear scope ("refactor the migration code")
- Dependencies unknown
- Research phase needed

**Solutions**:

1. **Break down into phases**:

   ```markdown
   **Estimated Effort:** 12h (4h research + 6h implementation + 2h testing)
   ```

2. **Use complexity-based defaults**:
   - CRITICAL: 16h base
   - HIGH: 8h base
   - MEDIUM: 4h base
   - LOW: 2h base

3. **Add uncertainty buffer**:

   ```markdown
   **Estimated Effort:** 8-12h (depends on depth of refactoring needed)
   ```

4. **Flag for tech lead review**:
   ```markdown
   **Estimated Effort:** TBD - requires architecture review
   ```

---

## Issue 3: Acceptance Criteria Too Vague

**Symptom**: ACs generated but not specific/testable

**Bad Example**:

```markdown
- [ ] Fix the bug
- [ ] Improve performance
- [ ] Add tests
```

**Solutions**:

1. **Make criteria measurable**:

   ```markdown
   - [ ] Reduce batch processing time from 5s to <2s
   - [ ] Add unit test for null email field
   - [ ] Verify no crashes with missing CSV columns
   ```

2. **Reference specific code**:

   ```markdown
   - [ ] Add null check in `mapContactDto()` before accessing `row.email`
   - [ ] Return default value "noemail@example.com" when email missing
   ```

3. **Include verification steps**:
   ```markdown
   - [ ] Manual test with CSV missing email column confirms no crash
   - [ ] Automated test `worker-csv-adapter.test.ts` passes with 100% coverage
   ```

---

## Issue 4: Cannot Generate Code Examples

**Symptom**: No code context provided in finding, can't show current/proposed

**Causes**:

- High-level architectural issue
- Cross-cutting concern
- Conceptual problem (not code-specific)

**Solutions**:

1. **Show pseudocode** if real code unavailable:

   ````markdown
   **Current Approach (Conceptual):**

   ```typescript
   // No error handling in batch loop
   for (const record of batch) {
     await create(record) // Throws on failure
   }
   ```

   **Proposed Approach:**

   ```typescript
   // Wrap with rollback compensation
   try {
     for (const record of batch) {
       await create(record)
       committed.push(record.id)
     }
   } catch (error) {
     await rollback(committed)
     throw error
   }
   ```
   ````

2. **Use architectural diagrams** (markdown format):

   ```markdown
   **Current Architecture:**
   CSV → Parser → Direct DB Write (no rollback)

   **Proposed Architecture:**
   CSV → Parser → Transaction Manager → DB Write (with rollback)
   ```

3. **Skip code examples** if truly not applicable:
   ```markdown
   **Code Examples:** N/A (architectural change, not code-specific)
   ```

---

## Issue 5: File Change Scope Unclear

**Symptom**: Don't know which files need to be created/modified/deleted

**Causes**:

- New feature (no existing code to modify)
- Large refactoring (many files affected)
- Uncertainty about implementation approach

**Solutions**:

1. **Start with known files**:

   ```markdown
   **Files to Modify (Confirmed):**

   - `src/lib/migration/referral.ts:233-267` - Add error handling

   **Files to Create (Likely):**

   - `src/lib/utils/batch-rollback.ts` (~200 lines) - TBD exact design
   ```

2. **Use conditional language**:

   ```markdown
   **Files to Modify:**

   - `src/lib/migration/referral.ts` - Primary change location
   - `src/lib/utils/dry-run-context.ts` - If dry-run tracking needed
   ```

3. **Mark investigation needed**:

   ```markdown
   **Files to Modify:**

   - TBD - requires investigation of current batch processing implementation
   ```

---

## Issue 6: Testing Table Incomplete

**Symptom**: Can't map all ACs to test types or don't know test locations

**Causes**:

- Test infrastructure unknown
- Test strategy not defined
- New testing approach needed

**Solutions**:

1. **Infer from project structure**:
   - Unit tests: `src/__tests__/` or `tests/unit/`
   - Integration tests: `tests/integration/`
   - E2E tests: `tests/e2e/`

2. **Use pattern-based paths**:

   ```markdown
   | Test Type   | Validates AC | Description         | Location                                       |
   | ----------- | ------------ | ------------------- | ---------------------------------------------- |
   | Unit        | AC1, AC2     | Test rollback logic | `src/__tests__/batch-rollback.test.ts`         |
   | Integration | AC3          | Full batch failure  | `tests/integration/referral-migration.test.ts` |
   ```

3. **Mark test strategy as TBD**:
   ```markdown
   | Test Type | Validates AC | Description         | Location                                  |
   | --------- | ------------ | ------------------- | ----------------------------------------- |
   | Unit      | AC1, AC2     | Test rollback logic | TBD - test file location to be determined |
   ```

---

## Issue 7: Dependencies Unknown

**Symptom**: Can't determine what must be done first or what this blocks

**Causes**:

- Isolated change (no dependencies)
- Complex dependency graph (many interdependencies)
- New feature area (no existing tasks)

**Solutions**:

1. **For isolated changes**:

   ```markdown
   **Blocking Dependencies:** None
   **Blocks:** None
   ```

2. **For known dependencies**:

   ```markdown
   **Blocking Dependencies:** P0-001 (Service factory refactoring must complete first)
   **Blocks:** P1-005 (Batch retry depends on this rollback logic)
   ```

3. **For uncertain dependencies**:
   ```markdown
   **Blocking Dependencies:** TBD - requires review of current task graph
   **Blocks:** Potentially P1-005, P1-006 (batch-related tasks)
   ```

---

## Issue 8: Priority Classification Ambiguous

**Symptom**: Finding could be P0 or P1, P1 or P2, etc.

**Decision Tree**:

```
Is it a security vulnerability or data loss risk?
├─ YES → P0
└─ NO → Continue

Does it break core functionality for all users?
├─ YES → P0
└─ NO → Continue

Does it break functionality for specific user groups?
├─ YES → P1
└─ NO → Continue

Is it a code quality or technical debt issue?
├─ YES → P2
└─ NO → P3
```

**Escalation Factors** (increase priority by 1):

- Production impact (affects live users)
- High blast radius (> 10 components)
- No workaround available
- Compliance violation

**De-escalation Factors** (decrease priority by 1):

- Edge case only (< 1% users)
- Simple workaround exists
- Low usage feature

---

## Issue 9: Component Classification Unclear

**Symptom**: Don't know which component code (C##) to assign

**Solutions**:

1. **Invoke component-manager skill**:
   - Describe subject: "batch processing migration"
   - Component-manager returns: C03 (Migration & Batch Processing)
   - Use in finding: **Component:** C03: Migration & Batch Processing

2. **Use fallback if component-manager unavailable**:

   ```markdown
   **Component:** C00: General / Cross-Cutting (requires component classification)
   ```

3. **Create new component** if genuinely new area:
   - Invoke component-manager with: "new component for X"
   - Component-manager creates and returns code

---

## Issue 10: Finding Too Complex to Enrich in One Pass

**Symptom**: Finding involves multiple unrelated issues or massive refactoring

**Solutions**:

1. **Split into multiple findings**:

   ```markdown
   ### P0: Batch operation fails without rollback

   [Full enrichment for rollback issue]

   ### P1: Batch operation has poor error messages

   [Separate enrichment for error message issue]
   ```

2. **Create parent/child relationship**:

   ```markdown
   ### P0: Refactor batch processing (Parent)

   **Blocks:** P1-005 (Add rollback), P1-006 (Improve errors), P2-007 (Add logging)
   ```

3. **Mark as epic requiring decomposition**:
   ```markdown
   **Note:** This finding represents an epic-level change. Recommend decomposing into 3-5 sub-tasks before implementation.
   ```

---

## Quick Reference: When to Mark TBD

**Always include TBD marker when:**

- File location requires codebase investigation
- Effort estimate depends on architectural decisions
- Testing strategy not yet defined
- Dependencies require task graph analysis
- Component classification needs manual review

**Never use TBD for:**

- Priority (use decision tree to classify)
- Acceptance criteria (generate from description)
- Implementation steps (infer from context)
- Code examples (use pseudocode or skip)

---

## Getting Help

If stuck after trying solutions above:

1. **Review @EXAMPLES.md** for similar finding patterns
2. **Check @WORKFLOW.md** for step-by-step guidance
3. **Consult @VALIDATION_CHECKLIST.md** to identify what's missing
4. **Ask for clarification** from code review author or tech lead
