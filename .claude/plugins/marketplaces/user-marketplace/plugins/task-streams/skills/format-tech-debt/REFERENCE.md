# Format Tech Debt Reference

Complete reference for transforming technical debt assessments into prioritized refactoring tasks.

---

## 10 Required Enrichments

**For complete enrichment patterns and templates, see @../SHARED_ENRICHMENTS.md**

Every tech debt task MUST include all 10 enrichments:

1. Specific file locations with line numbers
2. Effort estimates in hours
3. Complexity classification
4. Concrete acceptance criteria (3-5 items)
5. Regression risk assessment (5 dimensions)
6. Actionable refactoring steps
7. Code examples (current vs refactored)
8. File change scope (Create/Modify/Delete)
9. Required testing table
10. Dependencies and blocking information

---

## Input: Tech Debt Document Structures

This skill handles three common tech debt formats:

### Structure 1: Debt Inventory

```markdown
# Q4 Technical Debt Assessment

## High Priority Debt

### 1. Legacy Authentication System

**Type:** Deprecated technology **Impact:** Security risk, blocks new features **Effort:** 40h
**ROI:** High - enables OAuth2, improves security

### 2. Outdated Express v4

**Type:** Dependency upgrade **EOL Date:** 2025-06-30 **Effort:** 16h
```

### Structure 2: Code Quality Report

```markdown
# Code Quality Analysis

## Critical Issues

- **Cyclomatic Complexity:** 15 functions over threshold
- **Code Duplication:** 23% duplication in auth module
- **Test Coverage:** Only 42% coverage in API layer
- **Technical Debt Ratio:** 18.5% (target: <10%)

## Refactoring Priorities

1. Extract duplicate auth logic
2. Simplify complex payment processor
3. Add missing unit tests
```

### Structure 3: Architecture Debt

```markdown
# Architecture Technical Debt

## Database Layer

### Issue: N+1 Query Problem

**Files Affected:** 47 files **Performance Impact:** 3-5s page load times **User Impact:** 10K users
affected daily

**Solution:** Implement dataloader pattern **Estimated Effort:** 24h
```

---

## Priority Mapping: ROI-Based Prioritization

Tech debt prioritization uses **Return on Investment (ROI)** analysis:

### ROI Formula

```typescript
ROI = (Development Velocity Impact + Business Risk Impact) / Effort Hours

Where:
- Development Velocity Impact: blocking (100), high (50), medium (20), low (5)
- Business Risk Impact: critical (100), high (50), medium (20), low (5)
- Effort Hours: Estimated refactoring time
```

### Priority Thresholds

| ROI Score | Priority | Description                            |
| --------- | -------- | -------------------------------------- |
| > 5.0     | P0       | High ROI - Critical impact, low effort |
| 2.0-5.0   | P1       | Medium ROI - Significant impact        |
| 1.0-2.0   | P2       | Positive ROI - Worth doing             |
| < 1.0     | P3       | Low ROI - Consider deferring           |

**Override rules:**

- `businessRisk === "critical"` → P0 (regardless of ROI)
- `developmentVelocity === "blocking"` → P0 (regardless of ROI)

### Priority Examples

| Debt Item                   | Impact   | Effort | ROI  | Priority | Rationale                      |
| --------------------------- | -------- | ------ | ---- | -------- | ------------------------------ |
| Security library EOL        | Critical | 16h    | 6.25 | P0       | Critical business risk         |
| Blocking dependency upgrade | Blocking | 8h     | 12.5 | P0       | Blocks development             |
| N+1 queries (10K users)     | High     | 24h    | 2.1  | P1       | High impact, reasonable effort |
| Code duplication            | Medium   | 40h    | 0.5  | P2       | Positive ROI but low           |
| Variable naming             | Low      | 8h     | 0.6  | P3       | Low impact                     |

---

## Extraction Strategy

### Phase 1: Identify Debt Items

Each debt item becomes a task:

```markdown
## High Priority Debt

1. Legacy auth system
2. Outdated Express v4
3. N+1 query problem
4. Missing test coverage

→ Creates 4 tasks: T0001, T0002, T0003, T0004
```

### Phase 2: Extract Debt-Specific Fields

#### Debt Classification

Extract debt type from keywords:

| Keywords                                                  | Debt Type     |
| --------------------------------------------------------- | ------------- |
| "code smell", "duplication", "complexity"                 | Code Quality  |
| "architecture violation", "design pattern", "n+1 queries" | Architecture  |
| "outdated dependency", "deprecated library", "EOL"        | Dependencies  |
| "missing docs", "outdated docs"                           | Documentation |
| "low coverage", "flaky tests", "missing tests"            | Testing       |
| "slow queries", "memory leak", "performance"              | Performance   |

#### Business Impact

Extract or infer business impact:

```markdown
**Business Impact:**

- Blocks OAuth2 feature (10 PM days delayed)
- Security risk: EOL library has known vulnerabilities
- Development velocity: 30% slower due to legacy patterns
- User impact: 10K users experience 5s page loads
- Compliance: SOC 2 audit flagged outdated dependencies
```

**Quantify where possible:**

- User count affected
- Performance degradation (seconds, %)
- Development time lost (hours/day, %)
- Revenue impact if known

#### Current State vs Desired State

**Current State:**

```markdown
## Current State

- Using legacy JWT library (v2.x, EOL 2024-12-31)
- Manual token validation in 15+ routes
- No refresh token support
- Security scan flagged 3 CVEs
```

**Desired State:**

```markdown
## Desired State

- Upgrade to modern OAuth2 library (v5.x)
- Centralized auth middleware
- Refresh token support implemented
- All CVEs resolved
```

#### Risk of Deferring

```markdown
**Risk of NOT Fixing:**

- Security vulnerability window grows
- More code couples to legacy pattern (harder to fix later)
- Compliance audit failure risk
- Developer frustration increases (morale impact)

**Break-even calculation:**

- Current: 2h/week lost to workarounds (100h/year)
- Fix effort: 40h
- Break-even: 20 weeks
- ROI after 1 year: 60h saved
```

### Phase 3: Priority Classification

Use ROI-based prioritization:

```typescript
function classifyTechDebtPriority(debt: TechDebt): Priority {
  const impact = calculateImpact(debt);
  const effort = debt.estimatedEffortHours;
  const roi = impact / effort;

  // Override rules
  if (debt.businessRisk === "critical") return "P0";
  if (debt.developmentVelocity === "blocking") return "P0";
  if (debt.hasSecurityVulnerability) return "P0";
  if (debt.eolDate && isWithin6Months(debt.eolDate)) return "P0";

  // ROI-based
  if (roi > 5.0) return "P0";
  if (roi > 2.0) return "P1";
  if (roi > 1.0) return "P2";
  return "P3";
}
```

### Phase 4: Effort Estimation

**Base estimates by debt type:**

| Debt Type                 | Base Effort | Multipliers                       |
| ------------------------- | ----------- | --------------------------------- |
| Dependency upgrade        | 8h          | Files affected: ×1.2 per 10 files |
| Code duplication removal  | 16h         | Duplication %: ×1.5 if > 25%      |
| Architecture refactor     | 24h         | Components affected: ×2 if > 5    |
| Test coverage improvement | 12h         | Coverage gap %: ×1.3 per 10%      |
| Performance optimization  | 20h         | Complexity: ×1.5 if critical path |

**Testing overhead:** Always add 30% for regression testing

**Examples:**

- Upgrade Express v4→v5 (50 files) → 8h × 6 multiplier × 1.3 = 62h
- Remove duplicate auth logic (30% dup) → 16h × 1.5 × 1.3 = 31h
- Fix N+1 queries (3 models) → 24h × 1.3 = 31h

### Phase 5: Refactoring Steps

Generate refactoring workflow:

```markdown
**Refactoring Steps:**

1. **Preparation**
   - Create feature branch
   - Document current behavior with characterization tests
   - Identify all usages of legacy pattern

2. **Implementation**
   - Implement new pattern in parallel (strangler fig)
   - Migrate usages incrementally (one module at a time)
   - Run regression tests after each migration
   - Update documentation

3. **Validation**
   - Run full test suite
   - Performance benchmarks (before/after)
   - Security scan
   - Code review with team

4. **Deployment**
   - Deploy behind feature flag if possible
   - Monitor error rates and performance
   - Gradual rollout (canary/blue-green)
   - Remove old code after 1 week success

5. **Cleanup**
   - Delete legacy code
   - Update architecture documentation
   - Share learnings with team
```

### Phase 6: Success Metrics

```markdown
**Success Metrics:**

- [ ] All CVEs resolved (security scan clean)
- [ ] Page load time reduced from 5s → <2s
- [ ] Test coverage increased from 42% → 80%
- [ ] Development velocity: story points/sprint +20%
- [ ] Zero regressions in production
- [ ] Team satisfaction score improved
```

### Phase 7: Migration Strategy

For large refactoring efforts:

```markdown
**Migration Strategy:**

**Phase 1: Proof of Concept (Week 1)**

- Migrate 1 small module (auth/token-validator.ts)
- Validate approach
- Measure effort accuracy

**Phase 2: Core Modules (Weeks 2-3)**

- Migrate high-traffic routes (10 files)
- Deploy behind feature flag
- Monitor metrics

**Phase 3: Long Tail (Week 4)**

- Migrate remaining 40 files
- Remove feature flag
- Delete legacy code

**Rollback Plan:**

- Feature flag toggle (instant rollback)
- Git revert commits (5 minute rollback)
- Database migrations reversible
```

### Phase 8: Component Classification

Invoke **component-manager skill** to classify tech debt:

**Example:**

- Tech debt relates to: "Authentication System"
- Component-manager returns: C05 (Authentication & Authorization)
- Use in task: **Component:** C05: Authentication & Authorization

### Phase 9: Task ID Generation

Invoke **id-generator skill**:

**Example:**

- Component: C05
- Priority: P0
- Sequence: 1
- Generated ID: C05-P0-001

### Phase 10: Create Task Files

Output refactoring tasks with all enrichments.

---

## Integration with Convert Command

```bash
/convert docs/tech-debt/Q4-debt-assessment.md

# detect-input-type detects "tech-debt" type
# Routes to format-tech-debt skill
# Extracts debt items with ROI analysis
# Output: tasks/C05-P0-001.md, tasks/C03-P1-002.md, etc.
```

---

## Quality Checks

Before finalizing tasks:

- [ ] ROI calculated for all debt items
- [ ] Priority reflects business impact (not just technical)
- [ ] Current state vs desired state documented
- [ ] Risk of deferring quantified
- [ ] Success metrics defined
- [ ] Migration strategy for large refactors
- [ ] All 10 enrichments present (see SHARED_ENRICHMENTS.md)
- [ ] Break-even analysis included
- [ ] Component classification applied
- [ ] Task IDs generated

---

## Notes

- Tech debt prioritization is ROI-driven, not severity-driven
- Business impact > technical purity
- Break-even analysis helps justify effort to stakeholders
- Migration strategy critical for large refactors (avoid big-bang rewrites)
- Success metrics must be measurable
- Risk of deferring helps prevent "we'll fix it later" syndrome
- Always reference SHARED_ENRICHMENTS.md for complete enrichment patterns
- Component classification enables tracking debt by system area
