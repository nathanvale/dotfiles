# Validation Checklist

Complete quality checklist to verify enriched findings before finalizing. Every item must pass
before outputting tasks.

---

## Pre-Output Checklist

Before finalizing any enriched finding, verify ALL items below:

### ✅ Core Metadata (Required)

- [ ] **Component code** assigned from component-manager skill (C##: Name format)
- [ ] **File locations** use backtick format with line ranges (`` `file.ts:start-end` ``)
- [ ] **Effort estimate** realistic and includes research/testing overhead (rounded to 0.5h)
- [ ] **Complexity** classification assigned (CRITICAL/HIGH/MEDIUM/LOW)
- [ ] **Regression risk** level assigned (HIGH/MEDIUM/LOW)

### ✅ Regression Risk Details (5 Dimensions)

- [ ] **Impact** - What breaks if this goes wrong (specific consequences)
- [ ] **Blast Radius** - How much of system affected (quantified where possible)
- [ ] **Dependencies** - What other systems/components depend on this
- [ ] **Testing Gaps** - What isn't currently tested (specific gaps)
- [ ] **Rollback Risk** - How risky is reverting this change (assessment)

### ✅ Acceptance Criteria (3-5 Items)

- [ ] **Minimum 3 criteria** present (5 for complex findings)
- [ ] **Checkbox format** used (`- [ ]`)
- [ ] **Each criterion testable** (can be verified objectively)
- [ ] **Each criterion specific** (no vague statements like "improve quality")
- [ ] **Each criterion actionable** (clear what needs to be done)

### ✅ Implementation Steps (3-5 Items)

- [ ] **Numbered list** format used (`1.`, `2.`, etc.)
- [ ] **Minimum 3 steps** present (5+ for complex findings)
- [ ] **Each step concrete** (not vague suggestions)
- [ ] **Each step actionable** (clear what to do)
- [ ] **Order logical** (dependencies respected)
- [ ] **Testing included** (validation steps present)

### ✅ Code Examples (When Applicable)

- [ ] **BOTH current and proposed code** shown (or N/A if no code change)
- [ ] **Proper markdown** code blocks with language tags
- [ ] **Comments explain** issue/fix
- [ ] **Examples concise** (< 20 lines each)

### ✅ File Change Scope (THREE Categories)

- [ ] **Files to Create** section present (with estimated line counts)
- [ ] **Files to Modify** section present (with line ranges like `file.ts:start-end`)
- [ ] **Files to Delete** section present (with deletion rationale)
- [ ] **All three categories** included (use "None" if empty)
- [ ] **Line counts estimated** for new files (~200 lines)
- [ ] **Descriptions provided** for each file change

### ✅ Testing Table (Maps to ACs)

- [ ] **Table format** correct (Test Type | Validates AC | Description | Location)
- [ ] **All ACs mapped** to at least one test type
- [ ] **Critical ACs** have multiple test types (unit + integration)
- [ ] **Test locations** specific (full paths with backticks)
- [ ] **Test descriptions** clear about what's validated
- [ ] **Coverage adequate** (unit, integration, E2E where appropriate)

### ✅ Dependencies and Blocking (Task Relationships)

- [ ] **Blocking Dependencies** listed (using task IDs: P0-001, P1-005, or "None")
- [ ] **Blocks** listed (tasks waiting on this one, or "None")
- [ ] **Prerequisites** section present (with checkboxes)
- [ ] **Prerequisites specific** (clear what needs to be set up)

### ✅ Format and Structure

- [ ] **Markdown formatting** correct (headers, lists, code blocks)
- [ ] **Priority tag** in title (`### P0:`, `### P1:`, etc.)
- [ ] **Description** 2-4 sentences (explains what and why)
- [ ] **Template structure** followed (see @EXAMPLES.md)
- [ ] **No placeholders** left (all [TBD] resolved or explicitly marked)

---

## Priority-Specific Checks

### For P0 (Critical) Findings

Additional rigor required:

- [ ] **Security impact assessed** (if applicable)
- [ ] **Data loss risk quantified** (number of records, data types)
- [ ] **Blast radius measured** (specific components/users affected)
- [ ] **Rollback plan documented** (how to revert if needed)
- [ ] **Monitoring requirements** specified (how to detect if fix works)

### For P1 (High) Findings

- [ ] **Performance impact** quantified where applicable (response times, throughput)
- [ ] **User impact** described (number of users, workflows affected)
- [ ] **Workaround documented** if available (temporary mitigation)

### For P2/P3 (Medium/Low) Findings

- [ ] **Refactoring scope** clear (isolated changes preferred)
- [ ] **Breaking changes** flagged if present
- [ ] **Technical debt context** provided (why this debt exists)

---

## Common Quality Issues to Avoid

### ❌ Vague Acceptance Criteria

**Bad:**

- [ ] Improve code quality
- [ ] Fix the bug
- [ ] Make it better

**Good:**

- [ ] Add null check before accessing row.email
- [ ] Test with CSV missing email column
- [ ] Update error message to include field name

### ❌ Non-Actionable Implementation Steps

**Bad:**

1. Fix the code
2. Test it
3. Deploy

**Good:**

1. Add try-catch wrapper around batch operation
2. Implement rollback compensation for partial failures
3. Add unit tests with mock service failure injection
4. Run integration tests with 100-record batch
5. Update dry-run context to track failed batches

### ❌ Missing File Change Details

**Bad:** **Files to Modify:**

- src/lib/migration/referral.ts - Fix bug

**Good:** **Files to Modify:**

- `src/lib/migration/referral.ts:233-267` - Add rollback on batch failure

### ❌ Incomplete Testing Table

**Bad:** | Test Type | Validates AC | Description | Location |
|-----------|--------------|-------------|----------| | Unit | AC1 | Tests | tests/unit/test.ts |

**Good:** | Test Type | Validates AC | Description | Location |
|-----------|--------------|-------------|----------| | Unit | AC1, AC2 | Test rollback compensation
logic with mock failures | `src/__tests__/batch-rollback.test.ts` | | Integration | AC3, AC4 | Full
batch failure scenario with 100 records | `tests/integration/batch-failure.test.ts` |

---

## Final Verification Steps

Before outputting, perform these final checks:

1. **Read through entire finding** as if you're the implementer
2. **Verify all 10 enrichments** present (see @../SHARED_ENRICHMENTS.md)
3. **Check all links** and file references are valid
4. **Ensure no [TBD]** markers unless intentionally flagged
5. **Validate markdown** renders correctly (preview if possible)
6. **Compare to template** (see @EXAMPLES.md for reference)

---

## Validation Status

After completing all checks:

✅ **PASS** - All items verified, ready to output ⚠️ **NEEDS WORK** - Missing items identified,
requires revision ❌ **FAIL** - Critical issues found, do not output

**If FAIL or NEEDS WORK**: Return to relevant workflow step and address issues before re-validating.
