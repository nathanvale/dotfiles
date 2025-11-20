# Bug Findings-Specific Enrichments

These 5 enrichments are unique to bug/defect tasks and complement the 10 universal enrichments from SHARED_ENRICHMENTS.md.

---

## 1. Root Cause Analysis

**Purpose**: Understand why the bug exists and prevent recurrence

**Format**:
```markdown
## Root Cause

**Bug Type**: Race Condition
**Root Cause** (5 Whys): No distributed lock when scaling to multiple workers
**Contributing Factors**: No concurrency tests, single-worker assumption undocumented
**First Introduced**: Commit 3c8a9f2a (2022-03-15, 18 months ago)
```

**Guidelines**:
- Classify bug type: Race Condition, Null Pointer, Logic Error, etc.
- Use 5 Whys technique to find true root cause
- List contributing factors (not just proximate cause)
- Use `git blame` to find when introduced
- Note reproducibility: Always, Intermittent (%), Never in dev

---

## 2. Impact Analysis

**Purpose**: Quantify user, data, and business impact

**Format**:
```markdown
## Impact Analysis

**Users Affected**: 12,450 (8.3% of active)
**Financial**: $55k direct costs, $188k total with churn
**Data Corruption**: 87,340 records processed 2+ times
**SLA Breach**: 99.9% target → 97.2% actual (3 weeks)
```

**Guidelines**:
- Count affected users (absolute and percentage)
- Calculate financial impact (direct costs + indirect)
- Document data corruption/loss if applicable
- Note SLA breaches with duration
- Assess blast radius (how many services affected)

---

## 3. Reproduction Steps

**Purpose**: Enable engineers to quickly reproduce and debug

**Format**:
```markdown
## Reproduction

```bash
# Scale to 3 workers, trigger simultaneously
kubectl scale deployment batch-worker --replicas=3
kubectl exec -it batch-worker-{1,2,3} -- node trigger-batch.js

# Result: Duplicate key violations within 5s
# Reproduction rate: 100% with 3+ workers
```
```

**Guidelines**:
- Provide exact command sequence
- Include expected result
- Note reproduction rate (100%, 50%, intermittent)
- Explain why it doesn't reproduce in dev (if applicable)
- Include minimal reproduction test case

---

## 4. Hotfix Decision

**Purpose**: Justify emergency fix vs regular sprint work

**Format**:
```markdown
## Hotfix Decision

**Decision**: HOTFIX (4/6 criteria met)
**Timeline**: 3.5 hours (dev 1.5h, test 0.5h, deploy 0.5h, validate 1h)
**Approach**: Redis distributed lock (skip staging)
**Risk**: MEDIUM (canary + instant rollback)
```

**Guidelines**:
- Score against hotfix criteria (data corruption, revenue impact, SLA breach)
- Estimate timeline for hotfix vs regular fix
- Document approach and shortcuts taken
- Assess risk level: LOW, MEDIUM, HIGH
- Define rollback plan

---

## 5. Pattern Detection

**Purpose**: Fix bug everywhere it exists, prevent recurrence

**Format**:
```markdown
## Pattern Detection

```bash
# Found 3 similar vulnerable patterns:
rg "await getUnprocessed\(\)" --type ts
# - src/jobs/email-sender.ts:89 (apply same fix)
# - src/jobs/report-generator.ts:134 (apply same fix)
# - src/batch/invoice-processor.ts:56 (preventive fix)

# Add linting rule: @company/no-unguarded-batch-processing
```
```

**Guidelines**:
- Search codebase for similar patterns
- List all vulnerable locations
- Create linting rule to prevent recurrence
- Add concurrency/security tests to CI
- Document in architecture decision record (ADR)

---

## Quick Reference

All bug finding tasks must include:
- ✅ 10 universal enrichments (SHARED_ENRICHMENTS.md)
- ✅ 5 bug-specific enrichments (this file)
- ✅ Total: 15 enrichments per task
