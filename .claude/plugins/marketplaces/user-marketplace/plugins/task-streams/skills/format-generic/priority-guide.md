# Priority Classification Guide for Generic Documents

Maps generic task requirements to P0-P3 priorities for proper task prioritization.

## Priority Classification Rules

### P0 (Critical - Must Do First)

**Characteristics:**

- Blocking dependencies (other work cannot proceed)
- Time-sensitive deadlines (external commitments)
- Critical path items (project milestones)
- High-impact decisions (architectural, strategic)

**Examples:**

- Decision required for blocked development team
- External deadline (contract, regulatory)
- Foundation work for major feature
- Critical vendor evaluation

**Timeline:** Must complete immediately

---

### P1 (High Priority - Do Soon)

**Characteristics:**

- Important deliverables (key project goals)
- Significant value add (user or business impact)
- Important dependencies (needed soon by others)
- Strategic initiatives (company priorities)

**Examples:**

- Major feature implementation
- Customer-requested enhancement
- Performance improvement initiative
- Important documentation update

**Timeline:** Complete within 1-2 sprints

---

### P2 (Medium Priority - Do When Possible)

**Characteristics:**

- Quality improvements (refinements, polish)
- Process enhancements (workflow optimization)
- Documentation updates (maintenance)
- Technical improvements (refactoring, optimization)

**Examples:**

- Code refactoring for maintainability
- Process documentation update
- Test coverage improvement
- Build system optimization

**Timeline:** Complete when capacity allows

---

### P3 (Low Priority - Nice to Have)

**Characteristics:**

- Minor improvements (small enhancements)
- Optional features (convenience additions)
- Future considerations (exploratory work)
- Low-impact tasks (minimal value)

**Examples:**

- UI polish and minor styling
- Optional convenience features
- Exploratory research
- Minor tooling improvements

**Timeline:** Complete if time permits

---

## Priority Decision Tree

```
Does other work depend on this?
├─ YES → P0
└─ NO → Continue

Is there an external deadline?
├─ YES → P0
└─ NO → Continue

Is it critical for project success?
├─ YES → P1
└─ NO → Continue

Does it improve quality or efficiency?
├─ YES → P2
└─ NO → P3
```

---

## Special Cases

### Escalation Rules

Escalate priority if:

- **Blocking**: Blocks > 2 people or teams → P0
- **Deadline pressure**: < 1 week to deadline → Increase by 1 level
- **Stakeholder request**: C-level or customer request → Increase by 1 level
- **Risk mitigation**: Addresses known risk → Increase by 1 level

### De-escalation Rules

De-escalate priority if:

- **Low impact**: Affects < 5% of users → Decrease by 1 level
- **Alternative exists**: Workaround available → Decrease by 1 level
- **Low urgency**: No time constraints → Decrease by 1 level
- **Exploratory**: Proof-of-concept only → P3

---

## Priority Distribution Guidelines

**Healthy task distribution:**

- P0: 5-10% (blockers, critical dependencies)
- P1: 30-40% (major deliverables, key work)
- P2: 40-50% (quality, improvements)
- P3: 10-20% (nice-to-have, optional)

**Warning signs:**

- > 20% P0: Too many "urgent" items, lack of planning
- > 50% P3: Work lacks focus or impact
- All same priority: Lacks prioritization discipline

---

## Context-Specific Guidelines

### Architecture Decision Records (ADRs)

- P0: Decision blocks active development
- P1: Decision needed for upcoming sprint
- P2: Documenting past decision
- P3: Future consideration or exploration

### Process Documentation

- P0: Critical onboarding or compliance need
- P1: Frequently referenced, currently outdated
- P2: Nice to have, low frequency access
- P3: Optional supplementary material

### Research Tasks

- P0: Unblocks immediate decision
- P1: Informs near-term planning
- P2: Useful for future work
- P3: Exploratory, no immediate application

### Refactoring

- P0: Blocks feature development
- P1: Significantly impacts velocity
- P2: Improves maintainability
- P3: Minor cleanup or style
