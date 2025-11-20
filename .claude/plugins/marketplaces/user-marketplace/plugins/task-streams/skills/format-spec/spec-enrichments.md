# Spec-Specific Enrichments

These 5 enrichments are unique to spec/feature tasks and complement the 10 universal enrichments
from SHARED_ENRICHMENTS.md.

---

## 1. User Flow

**Purpose**: Document user experience and journey

**Format**:

```markdown
## User Flow

**Persona**: Sarah - SMB owner, mobile-first **Current**: 12 steps, 8 min, error-prone **Proposed**:
5 steps, 2 min, automated **Key Interactions**: Long-press to select, swipe for bulk, optimistic UI
```

**Guidelines**:

- Define primary user persona with context
- Compare current vs proposed experience (steps, time)
- Highlight key interaction patterns
- Note accessibility requirements (WCAG 2.1 Level AA)
- Include mobile/desktop/tablet considerations

---

## 2. API Contract

**Purpose**: Backend integration specification

**Format**:

```markdown
## API Contract

**Endpoint**: POST /api/v1/orders/bulk-process **Auth**: Bearer token (OAuth2) **Rate Limit**: 100
req/min, 5k orders/hour **Idempotency**: Via Idempotency-Key header (24h TTL) **Versioning**: v1
(sunset policy: 12 months after deprecation)
```

**Guidelines**:

- Document new/modified endpoints
- Specify authentication method
- Define rate limits
- Note idempotency strategy
- Include versioning and deprecation policy
- Reference OpenAPI spec if available

---

## 3. Feature Flags

**Purpose**: Gradual rollout strategy

**Format**:

```markdown
## Feature Flags

**Flag**: bulk-order-processing **Rollout**:

- Wk1: Internal (0.5%)
- Wk2: Beta (5%)
- Wk3: Gradual (25% → 50%)
- Wk4: Full (100%) **Kill Switch**: If error rate >1% or latency >10s
```

**Guidelines**:

- Name the feature flag
- Define rollout phases with percentages
- Set kill switch criteria (auto-rollback triggers)
- Include A/B testing hypothesis if applicable
- Note monitoring requirements

---

## 4. Data Model

**Purpose**: Database schema changes

**Format**:

```markdown
## Data Model

**New Table**: bulk_operations (id, user_id, order_ids[], status, results) **Modified**:
orders.bulk_operation_id (nullable) **Migration**: Expand-contract pattern (zero downtime)
**Indexes**: idx_orders_bulk_operation_id, idx_bulk_ops_user_created
```

**Guidelines**:

- List new tables with key fields
- Document modified tables/columns
- Specify migration strategy (expand-contract, etc.)
- Note new indexes required
- Include data retention policy if applicable

---

## 5. Success Metrics

**Purpose**: Measure feature success and iterate

**Format**:

```markdown
## Success Metrics

**North Star**: Orders processed per hour (8 → 12, +50%) **KPIs**:

- Adoption: >60% of power users
- Time savings: 8min → 3min per 10 orders
- Error rate: <0.5%
- NPS: >8 **Instrumentation**: Segment events for discovery, selection, completion
```

**Guidelines**:

- Define North Star metric (primary success indicator)
- List 3-5 key KPIs with targets
- Specify analytics instrumentation
- Include A/B test results format
- Define alert conditions for metric degradation

---

## Quick Reference

All spec tasks must include:

- ✅ 10 universal enrichments (SHARED_ENRICHMENTS.md)
- ✅ 5 spec-specific enrichments (this file)
- ✅ Total: 15 enrichments per task
