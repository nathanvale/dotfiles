# Priority Classification Guide for Bug Findings

Maps finding severity to P0-P3 priorities for proper task prioritization.

## Priority Classification Rules

### P0 (Critical - Must Fix Immediately)

**Characteristics:**

- Security vulnerabilities (SQL injection, XSS, auth bypass)
- Data loss risks (silent data corruption, missing transactions)
- System-breaking bugs (crashes, hangs, infinite loops)
- Silent failures (errors not logged, failures not reported)

**Examples:**

- SQL injection vulnerability in user search
- Batch operation fails silently without rollback
- Authentication bypass in admin panel
- Database transaction missing commit causing data loss

**Timeline:** Must fix before next release

---

### P1 (High Priority - Fix Soon)

**Characteristics:**

- Significant functionality issues (features broken or unusable)
- Performance problems (slow queries, memory leaks)
- Error handling gaps (unhandled exceptions, poor error messages)
- Data integrity issues (validation missing, constraints violated)

**Examples:**

- API endpoint returns 500 error for valid input
- Memory leak in long-running process
- Missing null checks causing crashes
- Incorrect data validation allowing invalid records

**Timeline:** Fix within 1-2 sprints

---

### P2 (Medium Priority - Improve Quality)

**Characteristics:**

- Code quality issues (duplication, complexity, maintainability)
- Technical debt (outdated patterns, deprecated APIs)
- Missing tests (untested code paths, low coverage)
- Documentation gaps (missing docs, outdated comments)

**Examples:**

- Duplicate code across 3 files
- Complex function with cyclomatic complexity > 15
- Missing unit tests for critical logic
- Outdated API usage (deprecated methods)

**Timeline:** Fix when capacity allows

---

### P3 (Low Priority - Nice to Have)

**Characteristics:**

- Minor improvements (style consistency, naming)
- Optional optimizations (premature optimization)
- Style inconsistencies (formatting, conventions)
- Low-impact suggestions (minor refactoring)

**Examples:**

- Inconsistent variable naming
- Missing semicolons (if auto-fixed by linter)
- Opportunity for slightly better algorithm
- Cosmetic code improvements

**Timeline:** Fix if time permits or during related work

---

## Priority Decision Tree

```
Is it a security vulnerability?
├─ YES → P0
└─ NO → Continue

Does it cause data loss or corruption?
├─ YES → P0
└─ NO → Continue

Does it break core functionality?
├─ YES → P0 (if system-wide) or P1 (if feature-specific)
└─ NO → Continue

Does it impact performance significantly?
├─ YES → P1
└─ NO → Continue

Is it a code quality issue?
├─ YES → P2
└─ NO → P3
```

---

## Special Cases

### Escalation Rules

Escalate priority if:

- **Production impact**: Issue affects live users → Increase by 1 level
- **Blast radius**: Affects > 10 components → Increase by 1 level
- **Compliance violation**: Breaks regulatory requirements → P0
- **No workaround**: No way to mitigate → Increase by 1 level

### De-escalation Rules

De-escalate priority if:

- **Edge case**: Only affects rare scenarios → Decrease by 1 level
- **Simple workaround**: Easy mitigation available → Decrease by 1 level
- **Low usage**: Affects < 1% of users → Decrease by 1 level

---

## Priority Distribution Guidelines

**Healthy finding distribution:**

- P0: < 10% (security, data loss, system-breaking)
- P1: 20-30% (functionality, performance)
- P2: 40-50% (code quality, technical debt)
- P3: 20-30% (minor improvements, style)

**Warning signs:**

- > 20% P0: Review is too harsh or codebase has serious issues
- > 50% P3: Review is too lenient or missing critical issues
- All same priority: Review lacks nuance in severity assessment
