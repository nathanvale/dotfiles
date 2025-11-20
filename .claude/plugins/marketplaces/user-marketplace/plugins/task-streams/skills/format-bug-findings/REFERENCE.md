# Format Bug Findings Reference

Complete reference for transforming code review findings into task-decomposable output.

---

## 10 Required Enrichments

**For complete enrichment patterns and templates, see @../SHARED_ENRICHMENTS.md**

Every finding MUST include all 10 enrichments:

1. Specific file locations with line numbers
2. Effort estimates in hours
3. Complexity classification
4. Concrete acceptance criteria (3-5 items)
5. Regression risk assessment (5 dimensions)
6. Actionable remediation steps
7. Code examples (buggy vs fixed)
8. File change scope (Create/Modify/Delete)
9. Required testing table
10. Dependencies and blocking information

---

## Priority Classification Guidelines

### P0 (Critical - Must Fix)

- Security vulnerabilities
- Data loss risks
- System-breaking bugs
- Production blockers
- Silent failures

**Example:** "Service factory doesn't validate fixture mode, allowing accidental production writes"

### P1 (High Priority)

- Significant functionality issues
- Performance problems
- Error handling gaps
- Missing validation

**Example:** "Batch operation failures leave partial data without rollback"

### P2 (Medium Priority)

- Code quality issues
- Technical debt
- Missing tests
- Documentation gaps

**Example:** "Repository methods missing override keyword, risking silent bugs"

### P3 (Low Priority)

- Minor improvements
- Style inconsistencies
- Optional optimizations
- Nice-to-have features

**Example:** "Extract magic numbers into named constants for clarity"

---

## Component Classification

**Use component-manager skill for classification:**

When formatting a finding, invoke the **component-manager skill** to find or create the appropriate component code. The component-manager skill will:

1. Search existing components for a match (e.g., "Service Factory" → C02)
2. Create a new component if no match found
3. Return the component code for use in the Component field

**Example workflow:**

- Finding relates to: "Service Factory"
- Component-manager skill returns: C02 (Service Factory & Mode Selection)
- Use in finding: **Component:** C02: Service Factory & Mode Selection

The component-manager skill manages the component registry and ensures consistent component codes across all findings and tasks.

---

## Example: Complete Enriched Finding

````markdown
### P0-001: Service Factory Missing Fixture Mode Validation

**Component:** C02: Service Factory & Mode Selection
**Location:** `src/lib/services/service-factory.ts:125-145`
**Estimated Effort:** 8h
**Complexity:** CRITICAL
**Regression Risk:** HIGH

**Issue:**
Service factory doesn't validate fixture mode properly, allowing real Azure API calls during development. This could result in accidental production writes when USE_FIXTURES flag is misconfigured. Without validation, developers could unknowingly connect to live Dataverse during local testing.

**Regression Risk Details:**

- **Impact:** Could write test data to production Dataverse
- **Blast Radius:** Entire migration pipeline affected
- **Dependencies:** All repositories, mock services
- **Testing Gaps:** No integration tests verify fixture mode enforcement
- **Rollback Risk:** Low - no schema changes

**Acceptance Criteria:**

- [ ] Add fixture mode validation in service factory constructor
- [ ] Throw error if USE_FIXTURES=false but no Azure credentials
- [ ] Test with missing fixture mode flag
- [ ] Test with invalid fixture mode value
- [ ] Verify no Azure SDK initialization in fixture mode

**Remediation Steps:**

1. Add `validateFixtureMode()` method to ServiceFactory
2. Check `USE_FIXTURES` environment variable on initialization
3. Throw clear error if mode is misconfigured
4. Add integration test for fixture mode enforcement
5. Update documentation with fixture mode requirements

**Current Code (BUGGY):**

```typescript
export class ServiceFactory {
  constructor() {
    // No validation - dangerous!
    this.mode = process.env.USE_FIXTURES === "true"
  }
}
```

**Proposed Fix:**

```typescript
export class ServiceFactory {
  constructor() {
    const fixtureMode = process.env.USE_FIXTURES
    if (fixtureMode === undefined) {
      throw new Error("USE_FIXTURES environment variable required")
    }
    if (fixtureMode !== "true" && fixtureMode !== "false") {
      throw new Error(`Invalid USE_FIXTURES value: ${fixtureMode}`)
    }
    this.mode = fixtureMode === "true"
  }
}
```

**Files to Create:**

- None

**Files to Modify:**

- `src/lib/services/service-factory.ts:15-25` - Add fixture mode validation
- `src/lib/services/service-factory.ts:45-67` - Add validateFixtureMode method
- `tests/integration/service-factory.test.ts:12-45` - Add fixture mode tests

**Files to Delete:**

- None

**Required Testing:**
| Test Type | Validates AC | Description | Location |
|-------------|--------------|----------------------------------------|---------------------------------------------------|
| Unit | AC1, AC2 | Test fixture mode validation logic | `src/__tests__/service-factory.test.ts` |
| Integration | AC3, AC4, AC5| Verify Azure SDK not initialized | `tests/integration/fixture-mode-guard.test.ts` |

**Blocking Dependencies:** None
**Blocks:** P1-003, P1-007

**Prerequisites:**

- [ ] .env.local file exists
- [ ] USE_FIXTURES variable documented in README
````

---

## Notes

- This skill is format-agnostic at the domain level - works for bugs, features, security, tech debt, etc.
- The 10 enrichments are universal across all finding types (see SHARED_ENRICHMENTS.md)
- Component classification enables cross-review task tracking
- Three file categories (Create/Modify/Delete) are critical for accurate work estimation
- Testing table ensures traceability to acceptance criteria
- Dependency tracking enables proper task sequencing
- Output is directly compatible with decompose-review-to-tasks skill
