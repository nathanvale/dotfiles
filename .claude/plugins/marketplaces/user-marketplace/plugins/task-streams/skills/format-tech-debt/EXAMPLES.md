# Enriched Tech Debt Examples

Complete examples of properly enriched tech debts with all 10 required elements.

---

## Example 1: P0 - Silent Batch Failure

### P0: Batch operation fails silently without rollback

**Component:** C03: Migration & Batch Processing
**Location:** `src/lib/migration/referral.ts:233-267`
**Estimated Effort:** 8h
**Complexity:** HIGH
**Regression Risk:** HIGH

**Description:**

The `migrateBatch()` function does not properly handle partial failures. If a batch of 100 referrals fails at record 50, the first 49 records are committed to Dataverse but there's no rollback mechanism. This causes data inconsistency and silent failures that are difficult to debug.

**Regression Risk Details:**

- **Impact:** Data inconsistency in production - partial batches committed without compensation
- **Blast Radius:** Affects all 79,995 referrals in migration pipeline
- **Dependencies:** Repository layer depends on this for all create operations
- **Testing Gaps:** No integration tests for batch failure scenarios
- **Rollback Risk:** Medium - requires careful testing of compensation logic

**Acceptance Criteria:**

- [ ] Add try-catch wrapper around batch operation
- [ ] Implement rollback compensation for partial failures
- [ ] Log failed batch IDs to quarantine file
- [ ] Test with intentional failures (mock service)
- [ ] Update dry-run context to track failed batches

**Implementation Steps:**

1. Wrap batch operation in try-catch block
2. Add rollback compensation logic for partial failures
3. Create quarantine file for failed batch tracking
4. Add error logging with batch context
5. Test with mock service failure injection
6. Update dry-run context to record failed batches

**Current Code (BUGGY):**

```typescript
async function migrateBatch(records: CsvRecord[]) {
  for (const record of records) {
    await repository.create(record) // No error handling!
  }
}
```

**Proposed Fix:**

```typescript
async function migrateBatch(records: CsvRecord[]) {
  const committed: string[] = []
  try {
    for (const record of records) {
      const result = await repository.create(record)
      committed.push(result.id)
    }
  } catch (error) {
    // Rollback committed records
    for (const id of committed) {
      await repository.delete(id)
    }
    // Quarantine failed batch
    await fs.appendFile(
      "quarantine.log",
      JSON.stringify({ batchIds: committed, error })
    )
    throw error
  }
}
```

**Files to Create:**

- `src/lib/utils/batch-rollback.ts` (~200 lines) - Rollback compensation logic
- `src/__tests__/batch-rollback.test.ts` (~150 lines) - Unit tests for rollback

**Files to Modify:**

- `src/lib/migration/referral.ts:233-267` - Add rollback on batch failure
- `src/lib/utils/dry-run-context.ts:45-67` - Track failed batches
- `src/lib/mocks/mock-dataverse.ts:123-145` - Add failure simulation

**Files to Delete:**

- None

**Required Testing:**

| Test Type   | Validates AC | Description                              | Location                                       |
| ----------- | ------------ | ---------------------------------------- | ---------------------------------------------- |
| Unit        | AC1, AC2     | Test rollback compensation logic         | `src/__tests__/batch-rollback.test.ts`         |
| Integration | AC3, AC4     | Test with mock service failures          | `tests/integration/batch-failure.test.ts`      |
| E2E         | AC5          | Full migration with intentional failures | `tests/integration/referral-migration.test.ts` |

**Blocking Dependencies:** None
**Blocks:** P1-002 (Batch retry mechanism)

**Prerequisites:**

- [ ] Mock service supports failure injection
- [ ] Dry-run context supports error tracking
- [ ] Quarantine file structure defined

---

## Example 2: P1 - Missing Null Check

### P1: Missing null check before property access

**Component:** C02: CSV Parsing & Validation
**Location:** `src/lib/adapters/worker-csv-adapter.ts:145-167`
**Estimated Effort:** 2h
**Complexity:** LOW
**Regression Risk:** MEDIUM

**Description:**

The `mapContactDto()` function accesses `row.email` without checking if the field exists, causing crashes when processing CSV files with missing email columns.

**Regression Risk Details:**

- **Impact:** Migration crashes midway through processing
- **Blast Radius:** Affects all 79,995 rows if email column missing
- **Dependencies:** All contact creation flows depend on this mapper
- **Testing Gaps:** No tests for missing CSV fields
- **Rollback Risk:** Low - safe to revert, no data committed yet

**Acceptance Criteria:**

- [ ] Add null check before accessing row.email
- [ ] Use default value or skip field if missing
- [ ] Test with CSV missing email column
- [ ] Update error message to be user-friendly
- [ ] Add test coverage for missing fields

**Implementation Steps:**

1. Add null/undefined check for row.email
2. Provide default value or conditional handling
3. Update error messages with field name
4. Add unit test for missing email field
5. Run regression tests with real CSV data

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

**Files to Create:**

- None

**Files to Modify:**

- `src/lib/adapters/worker-csv-adapter.ts:145-167` - Add null check
- `tests/unit/adapters/worker-csv-adapter.test.ts:50-70` - Add test case

**Files to Delete:**

- None

**Required Testing:**

| Test Type   | Validates AC  | Description                        | Location                                         |
| ----------- | ------------- | ---------------------------------- | ------------------------------------------------ |
| Unit        | AC1, AC2, AC5 | Test with missing email field      | `tests/unit/adapters/worker-csv-adapter.test.ts` |
| Integration | AC3           | Full CSV parse with missing column | `tests/integration/csv-parse.test.ts`            |

**Blocking Dependencies:** None
**Blocks:** None

**Prerequisites:**

- [ ] Test CSV fixture with missing email column
- [ ] Error message format agreed upon

---

## Example 3: P2 - Code Duplication

### P2: Duplicate validation logic across 3 CSV adapters

**Component:** C02: CSV Parsing & Validation
**Location:** Multiple files (see Files to Modify)
**Estimated Effort:** 4h
**Complexity:** MEDIUM
**Regression Risk:** LOW

**Description:**

Email validation logic is duplicated across worker, claimant, and contact CSV adapters. This violates DRY principles and makes maintenance difficult (bugs must be fixed in 3 places).

**Regression Risk Details:**

- **Impact:** Inconsistent validation behavior across CSV types
- **Blast Radius:** Limited - only affects CSV parsing layer
- **Dependencies:** No other components depend on this
- **Testing Gaps:** No shared validation tests
- **Rollback Risk:** Very low - isolated refactoring

**Acceptance Criteria:**

- [ ] Extract email validation into shared utility
- [ ] Update all 3 adapters to use shared function
- [ ] Ensure all tests still pass
- [ ] Add shared validation tests
- [ ] Document shared validation API

**Implementation Steps:**

1. Create `src/lib/utils/csv-validators.ts`
2. Extract `validateEmail()` function
3. Update worker-csv-adapter to use shared function
4. Update claimant-csv-adapter to use shared function
5. Update contact-csv-adapter to use shared function
6. Add unit tests for shared validator
7. Run full test suite to verify

**Current Code (BUGGY - Duplicated 3x):**

```typescript
// In worker-csv-adapter.ts
function validateEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)
}

// Same function duplicated in claimant-csv-adapter.ts
// Same function duplicated in contact-csv-adapter.ts
```

**Proposed Fix:**

```typescript
// src/lib/utils/csv-validators.ts
export function validateEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)
}

// In all 3 adapters
import { validateEmail } from "lib/utils/csv-validators.js"
```

**Files to Create:**

- `src/lib/utils/csv-validators.ts` (~100 lines) - Shared validation functions
- `tests/unit/utils/csv-validators.test.ts` (~80 lines) - Shared validation tests

**Files to Modify:**

- `src/lib/adapters/worker-csv-adapter.ts:45-67` - Use shared validator
- `src/lib/adapters/claimant-csv-adapter.ts:50-72` - Use shared validator
- `src/lib/adapters/contact-csv-adapter.ts:38-60` - Use shared validator

**Files to Delete:**

- None

**Required Testing:**

| Test Type   | Validates AC  | Description                             | Location                                  |
| ----------- | ------------- | --------------------------------------- | ----------------------------------------- |
| Unit        | AC1, AC4      | Test shared validation logic            | `tests/unit/utils/csv-validators.test.ts` |
| Integration | AC2, AC3, AC5 | Test all adapters with shared validator | `tests/unit/adapters/*.test.ts`           |

**Blocking Dependencies:** None
**Blocks:** None

**Prerequisites:**

- [ ] Code review approval for refactoring approach
- [ ] Regression test suite passes

---

## Template for New Tech Debts

Use this template when creating new enriched tech debt items:

````markdown
### [Priority]: [Concise title]

**Component:** [C##: Component Name from component-manager]
**Location:** `file.ts:lineStart-lineEnd`
**Estimated Effort:** [X]h
**Complexity:** [CRITICAL | HIGH | MEDIUM | LOW]
**Regression Risk:** [HIGH | MEDIUM | LOW]

**Description:**
[2-4 sentences explaining what needs to be done and why it matters]

**Regression Risk Details:**

- **Impact:** [What breaks if this goes wrong]
- **Blast Radius:** [How much of the system is affected]
- **Dependencies:** [What other systems/components depend on this]
- **Testing Gaps:** [What isn't currently tested]
- **Rollback Risk:** [How risky is reverting this change]

**Acceptance Criteria:**

- [ ] [Specific, testable criterion 1]
- [ ] [Specific, testable criterion 2]
- [ ] [Specific, testable criterion 3]
- [ ] [Specific, testable criterion 4]
- [ ] [Specific, testable criterion 5]

**Implementation Steps:**

1. [First concrete step]
2. [Second concrete step]
3. [Third concrete step]
4. [Fourth concrete step]
5. [Fifth concrete step]

**Current Code (BUGGY):**

```typescript
// Problematic code
```
````

**Proposed Fix:**

```typescript
// Corrected code
```

**Files to Create:**

- `path/to/new/file.ts` (~200 lines) - Description

**Files to Modify:**

- `path/to/existing/file.ts:233-267` - Description

**Files to Delete:**

- `path/to/obsolete/file.ts` - Reason for deletion

**Required Testing:**
| Test Type | Validates AC | Description | Location |
|-------------|--------------|-------------------------------------|-----------------------------------------------|
| Unit | AC1, AC2 | [What this tests] | `tests/unit/...` |
| Integration | AC3, AC4 | [What this tests] | `tests/integration/...` |

**Blocking Dependencies:** [P0-001, P0-003, or "None"]
**Blocks:** [P1-005, P2-012, or "None"]

**Prerequisites:**

- [ ] [Required setup item 1]
- [ ] [Required setup item 2]

```

```
