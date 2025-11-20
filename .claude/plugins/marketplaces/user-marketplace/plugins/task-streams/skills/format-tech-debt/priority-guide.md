# Priority Classification Guide for Technical Debt

Maps technical debt items to P0-P3 priorities for proper remediation planning.

## Priority Classification Rules

### P0 (Critical - Must Address Immediately)

**Characteristics:**

- Security vulnerabilities in dependencies (CVE with exploit)
- Critical architectural flaws (scalability blockers)
- Production instability risks (frequent crashes, data corruption)
- Compliance violations (audit failures, regulatory breaches)

**Examples:**

- Dependency with known remote code execution vulnerability
- Database connection pool exhaustion causing outages
- Missing encryption for sensitive data
- Architecture pattern causing cascading failures

**Timeline:** Address before next release

---

### P1 (High Priority - Address Soon)

**Characteristics:**

- Significant maintainability issues (high change cost)
- Performance bottlenecks (user-facing slowness)
- Outdated frameworks/libraries (approaching end-of-life)
- Testing gaps in critical paths (P0/P1 features untested)

**Examples:**

- Monolithic codebase preventing parallel development
- N+1 query patterns causing slow page loads
- Framework version 2 years behind current
- No integration tests for payment processing

**Timeline:** Address within 1-2 sprints

---

### P2 (Medium Priority - Improve Over Time)

**Characteristics:**

- Code quality issues (duplication, complexity)
- Minor outdated dependencies (security updates available)
- Documentation debt (missing or outdated docs)
- Test coverage gaps (non-critical paths)

**Examples:**

- Duplicate validation logic across 5 files
- Function with cyclomatic complexity > 20
- API documentation 6 months out of date
- Missing unit tests for utility functions

**Timeline:** Address when capacity allows

---

### P3 (Low Priority - Nice to Have)

**Characteristics:**

- Style inconsistencies (formatting, naming)
- Minor refactoring opportunities (slight improvements)
- Optional tooling upgrades (non-critical updates)
- Convenience improvements (DX enhancements)

**Examples:**

- Inconsistent variable naming conventions
- Opportunity to extract small helper function
- Linter configuration updates
- IDE configuration improvements

**Timeline:** Address if time permits or during related work

---

## Priority Decision Tree

```
Is there an active security vulnerability?
├─ YES → P0
└─ NO → Continue

Does it cause production incidents?
├─ YES → P0
└─ NO → Continue

Does it significantly slow development?
├─ YES → P1
└─ NO → Continue

Does it impact code quality measurably?
├─ YES → P2
└─ NO → P3
```

---

## Special Cases

### Escalation Rules

Escalate priority if:

- **Incident frequency**: Caused > 2 production incidents → P0
- **Development velocity**: Blocks > 3 teams → Increase by 1 level
- **Compounding debt**: Gets worse with each change → Increase by 1 level
- **End-of-life**: Framework/library sunset in < 6 months → P1

### De-escalation Rules

De-escalate priority if:

- **Low change frequency**: File rarely modified (< 1/year) → Decrease by 1 level
- **Isolated scope**: Affects single module only → Decrease by 1 level
- **Workaround exists**: Clean abstraction available → Decrease by 1 level

---

## Priority Distribution Guidelines

**Healthy debt distribution:**

- P0: < 5% (critical vulnerabilities, stability risks)
- P1: 15-25% (maintainability, performance)
- P2: 50-60% (code quality, documentation)
- P3: 20-30% (style, minor improvements)

**Warning signs:**

- > 15% P0: System has serious stability/security issues
- > 60% P3: Assessment lacks substance or critical thinking
- All same priority: Assessment lacks severity discrimination

---

## Remediation Strategy

### P0 Technical Debt

- **Stop the line**: Pause new features until addressed
- **Dedicated resources**: Assign senior engineers
- **Time-boxed**: Must resolve within current sprint

### P1 Technical Debt

- **Planned sprints**: Allocate 20-30% capacity
- **Incremental**: Break into smaller tasks
- **Measured**: Track metrics (build time, error rates)

### P2/P3 Technical Debt

- **Boy Scout Rule**: Fix when touching nearby code
- **Dedicated days**: Monthly "debt day" for team
- **Long-term**: Address over 2-3 quarters
