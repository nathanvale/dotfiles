/**
 * Tests for tech-debt validation
 */

import { describe, it, expect } from "vitest";

import { TechDebtValidator } from "./validate-tech-debt";

describe("TechDebtValidator", () => {
  describe("Complete valid techDebt", () => {
    it("should pass all validations for properly enriched techDebt", () => {
      const validTechDebt = `
### P0: Batch operation fails without rollback

**Component:** C03: Migration & Batch Processing
**Location:** \`src/lib/migration/referral.ts:233-267\`
**Estimated Effort:** 8h
**Complexity:** HIGH
**Regression Risk:** HIGH

**Description:**
The migrateBatch() function does not properly handle partial failures.

**Regression Risk Details:**
- **Impact:** Data inconsistency in production
- **Blast Radius:** Affects all 79,995 referrals
- **Dependencies:** Repository layer depends on this
- **Testing Gaps:** No integration tests for batch failures
- **Rollback Risk:** Medium - requires careful testing

**Acceptance Criteria:**
- [ ] Add try-catch wrapper around batch operation
- [ ] Implement rollback compensation for partial failures
- [ ] Log failed batch IDs to quarantine file

**Implementation Steps:**
1. Wrap batch operation in try-catch block
2. Add rollback compensation logic
3. Test with mock service failure injection

**Current Code (BUGGY):**
\`\`\`typescript
async function migrateBatch(records: CsvRecord[]) {
  for (const record of records) {
    await repository.create(record)
  }
}
\`\`\`

**Proposed Fix:**
\`\`\`typescript
async function migrateBatch(records: CsvRecord[]) {
  const committed: string[] = []
  try {
    for (const record of records) {
      const result = await repository.create(record)
      committed.push(result.id)
    }
  } catch (error) {
    for (const id of committed) {
      await repository.delete(id)
    }
    throw error
  }
}
\`\`\`

**Files to Create:**
- \`src/lib/utils/batch-rollback.ts\` (~200 lines)

**Files to Modify:**
- \`src/lib/migration/referral.ts:233-267\`

**Files to Delete:**
- None

**Required Testing:**
| Test Type | Validates AC | Description | Location |
|-----------|--------------|-------------|----------|
| Unit | AC1, AC2 | Test rollback logic | \`src/__tests__/batch-rollback.test.ts\` |

**Blocking Dependencies:** None
**Blocks:** P1-002

**Prerequisites:**
- [ ] Mock service supports failure injection
`;
      const validator = new TechDebtValidator(validTechDebt);
      const result = validator.validate();

      expect(result.passed).toBe(true);
      expect(result.errors).toBe(0);
    });
  });

  describe("Component validation", () => {
    it("should fail when component code is missing", () => {
      const techDebt = `
### P0: Test techDebt
**Location:** \`file.ts:1-10\`
      `;
      const validator = new TechDebtValidator(techDebt);
      const result = validator.validate();

      const componentResult = result.results.find((r) => r.message.includes("component"));
      expect(componentResult?.passed).toBe(false);
      expect(result.errors).toBeGreaterThan(0);
    });

    it("should pass when component code is present", () => {
      const techDebt = `
**Component:** C03: Migration & Batch Processing
      `;
      const validator = new TechDebtValidator(techDebt);
      const result = validator.validate();

      const componentResult = result.results.find((r) =>
        r.message.toLowerCase().includes("component")
      );
      expect(componentResult?.passed).toBe(true);
    });
  });

  describe("File location validation", () => {
    it("should fail when location is missing line numbers", () => {
      const techDebt = `
**Location:** src/lib/migration/referral.ts
      `;
      const validator = new TechDebtValidator(techDebt);
      const result = validator.validate();

      const locationResult = result.results.find((r) => r.message.includes("location"));
      expect(locationResult?.passed).toBe(false);
    });

    it("should pass when location has proper format with line ranges", () => {
      const techDebt = `
**Location:** \`src/lib/migration/referral.ts:233-267\`
      `;
      const validator = new TechDebtValidator(techDebt);
      const result = validator.validate();

      const locationResult = result.results.find((r) => r.message.includes("location"));
      expect(locationResult?.passed).toBe(true);
    });
  });

  describe("Effort estimate validation", () => {
    it("should fail when effort estimate is missing", () => {
      const techDebt = `
**Estimated Effort:**
      `;
      const validator = new TechDebtValidator(techDebt);
      const result = validator.validate();

      const effortResult = result.results.find((r) => r.message.includes("effort"));
      expect(effortResult?.passed).toBe(false);
    });

    it("should pass with various effort formats", () => {
      const testCases = ["8h", "0.5h", "12h", "2.5h"];

      for (const effort of testCases) {
        const techDebt = `**Estimated Effort:** ${effort}`;
        const validator = new TechDebtValidator(techDebt);
        const result = validator.validate();

        const effortResult = result.results.find((r) => r.message.toLowerCase().includes("effort"));
        expect(effortResult?.passed).toBe(true);
      }
    });
  });

  describe("Complexity validation", () => {
    it("should pass with all valid complexity levels", () => {
      const levels = ["CRITICAL", "HIGH", "MEDIUM", "LOW"];

      for (const level of levels) {
        const techDebt = `**Complexity:** ${level}`;
        const validator = new TechDebtValidator(techDebt);
        const result = validator.validate();

        const complexityResult = result.results.find((r) =>
          r.message.toLowerCase().includes("complexity")
        );
        expect(complexityResult?.passed).toBe(true);
      }
    });

    it("should fail with invalid complexity level", () => {
      const techDebt = `**Complexity:** SUPER_HIGH`;
      const validator = new TechDebtValidator(techDebt);
      const result = validator.validate();

      const complexityResult = result.results.find((r) => r.message.includes("complexity"));
      expect(complexityResult?.passed).toBe(false);
    });
  });

  describe("Regression risk validation", () => {
    it("should fail when regression risk details are incomplete", () => {
      const techDebt = `
**Regression Risk Details:**
- **Impact:** Something bad
- **Blast Radius:** Large
      `;
      const validator = new TechDebtValidator(techDebt);
      const result = validator.validate();

      const riskResult = result.results.find((r) => r.message.includes("risk dimensions"));
      expect(riskResult?.passed).toBe(false);
    });

    it("should pass when all 5 dimensions are present", () => {
      const techDebt = `
**Regression Risk Details:**
- **Impact:** Data inconsistency
- **Blast Radius:** Affects all records
- **Dependencies:** Repository layer
- **Testing Gaps:** No integration tests
- **Rollback Risk:** Medium
      `;
      const validator = new TechDebtValidator(techDebt);
      const result = validator.validate();

      const riskResult = result.results.find((r) => r.message.includes("risk dimensions"));
      expect(riskResult?.passed).toBe(true);
    });
  });

  describe("Acceptance criteria validation", () => {
    it("should fail with insufficient criteria", () => {
      const techDebt = `
**Acceptance Criteria:**
- [ ] First criterion
- [ ] Second criterion
      `;
      const validator = new TechDebtValidator(techDebt);
      const result = validator.validate();

      const acResult = result.results.find((r) => r.message.includes("criteria"));
      expect(acResult?.passed).toBe(false);
    });

    it("should pass with 3 or more criteria", () => {
      const techDebt = `
**Acceptance Criteria:**
- [ ] First criterion
- [ ] Second criterion
- [ ] Third criterion
- [ ] Fourth criterion
      `;
      const validator = new TechDebtValidator(techDebt);
      const result = validator.validate();

      const acResult = result.results.find((r) => r.message.includes("criteria"));
      expect(acResult?.passed).toBe(true);
    });
  });

  describe("Implementation steps validation", () => {
    it("should fail with insufficient steps", () => {
      const techDebt = `
**Implementation Steps:**
1. First step
2. Second step
      `;
      const validator = new TechDebtValidator(techDebt);
      const result = validator.validate();

      const stepsResult = result.results.find((r) => r.message.includes("steps"));
      expect(stepsResult?.passed).toBe(false);
    });

    it("should pass with 3 or more steps", () => {
      const techDebt = `
**Implementation Steps:**
1. First step
2. Second step
3. Third step
4. Fourth step
      `;
      const validator = new TechDebtValidator(techDebt);
      const result = validator.validate();

      const stepsResult = result.results.find((r) => r.message.includes("steps"));
      expect(stepsResult?.passed).toBe(true);
    });
  });

  describe("File change scope validation", () => {
    it("should fail when missing file change categories", () => {
      const techDebt = `
**Files to Create:**
- file1.ts

**Files to Modify:**
- file2.ts
      `;
      const validator = new TechDebtValidator(techDebt);
      const result = validator.validate();

      const fileResult = result.results.find((r) => r.message.includes("file change categories"));
      expect(fileResult?.passed).toBe(false);
    });

    it("should pass when all 3 categories present", () => {
      const techDebt = `
**Files to Create:**
- file1.ts

**Files to Modify:**
- file2.ts

**Files to Delete:**
- None
      `;
      const validator = new TechDebtValidator(techDebt);
      const result = validator.validate();

      const fileResult = result.results.find((r) => r.message.includes("file change categories"));
      expect(fileResult?.passed).toBe(true);
    });
  });

  describe("Testing table validation", () => {
    it("should fail when testing table is missing", () => {
      const techDebt = `
**Required Testing:**
Some text but no table
      `;
      const validator = new TechDebtValidator(techDebt);
      const result = validator.validate();

      const testResult = result.results.find((r) => r.message.includes("testing table"));
      expect(testResult?.passed).toBe(false);
    });

    it("should pass when testing table with rows exists", () => {
      const techDebt = `
**Required Testing:**
| Test Type | Validates AC | Description | Location |
|-----------|--------------|-------------|----------|
| Unit | AC1 | Test something | \`tests/unit/test.ts\` |
| Integration | AC2 | Test more | \`tests/integration/test.ts\` |
      `;
      const validator = new TechDebtValidator(techDebt);
      const result = validator.validate();

      const testResult = result.results.find((r) => r.message.includes("table"));
      expect(testResult?.passed).toBe(true);
    });
  });

  describe("Dependencies validation", () => {
    it("should fail when dependency sections are missing", () => {
      const techDebt = `
**Blocking Dependencies:** None
      `;
      const validator = new TechDebtValidator(techDebt);
      const result = validator.validate();

      const depResult = result.results.find((r) => r.message.includes("dependency sections"));
      expect(depResult?.passed).toBe(false);
    });

    it("should pass when all dependency sections present", () => {
      const techDebt = `
**Blocking Dependencies:** None
**Blocks:** P1-005
**Prerequisites:**
- [ ] Setup complete
      `;
      const validator = new TechDebtValidator(techDebt);
      const result = validator.validate();

      const depResult = result.results.find((r) => r.message.includes("dependency sections"));
      expect(depResult?.passed).toBe(true);
    });
  });
});
