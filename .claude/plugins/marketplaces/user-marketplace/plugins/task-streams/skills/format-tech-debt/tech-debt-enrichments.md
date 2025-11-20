# Tech Debt-Specific Enrichments

These 5 enrichments are unique to tech debt tasks and complement the 10 universal enrichments from
SHARED_ENRICHMENTS.md.

---

## 1. Code Metrics

**Purpose**: Quantify the debt to justify refactoring investment

**Format**:

```markdown
## Code Metrics

**Cyclomatic Complexity**: 42 (target: <10) **Test Coverage**: 34% (target: 80%) **Maintainability
Index**: 42/100 (LOW) **Technical Debt Ratio**: 8.2% (SonarQube) **Duplicated Code**: 456 lines
(8.3%)
```

**Guidelines**:

- Include cyclomatic complexity with target
- Document current vs target test coverage
- Add maintainability index from SonarQube/CodeClimate
- Note technical debt ratio if available
- Identify duplicated code blocks

---

## 2. Refactoring Strategy

**Purpose**: Clear migration path from legacy to modern

**Format**:

```markdown
## Refactoring Strategy

**Approach**: Strangler Fig Pattern (incremental migration) **Timeline**: 8 weeks **Phases**:

- Wk 1-2: Facade layer
- Wk 3-6: New implementation (shadow mode)
- Wk 7-10: Gradual rollout (5% → 100%)
```

**Guidelines**:

- Name the pattern: Strangler Fig, Big Bang, Branch by Abstraction
- Provide realistic timeline with phases
- Explain why chosen approach (vs alternatives)
- Include rollback strategy

---

## 3. ROI Analysis

**Purpose**: Justify investment with business value

**Format**:

```markdown
## ROI Analysis

**Current Cost**: $197k/quarter (bug fixes, incidents, velocity loss) **Investment**: $65k
(one-time) **Savings**: $163k/quarter **Payback Period**: 1.6 months **3-Year ROI**: 900%
```

**Guidelines**:

- Quantify current state costs (developer time, incidents, opportunity cost)
- Estimate one-time investment
- Calculate quarterly savings
- Include payback period and multi-year ROI
- Be realistic, not optimistic

---

## 4. Quality Improvements

**Purpose**: Document what "good" looks like after refactoring

**Format**:

```markdown
## Quality Improvements

**Design Patterns**: Strategy, Factory, Observer **SOLID Violations Fixed**: Single Responsibility,
Dependency Injection **Test Coverage**: 34% → 95% **Complexity**: 42 → 8 (cyclomatic)
```

**Guidelines**:

- List design patterns being introduced
- Note SOLID principles violations being fixed
- Show before/after metrics
- Include architectural improvements

---

## 5. Safety Mechanisms

**Purpose**: Refactoring risks and safeguards

**Format**:

```markdown
## Safety Mechanisms

**Parallel Run**: Compare old vs new (shadow mode) **Rollback Plan**: Feature flag flip (<5 min)
**Rollout**: Canary 5% → 25% → 50% → 100% **Auto-rollback If**: Error rate >0.5%, latency >500ms
```

**Guidelines**:

- Describe parallel run/shadow mode strategy
- Document instant rollback mechanism
- Define gradual rollout phases
- Set automated rollback triggers (error rate, latency, etc.)
- Assess rollback complexity: LOW, MEDIUM, HIGH

---

## Quick Reference

All tech debt tasks must include:

- ✅ 10 universal enrichments (SHARED_ENRICHMENTS.md)
- ✅ 5 tech debt-specific enrichments (this file)
- ✅ Total: 15 enrichments per task
