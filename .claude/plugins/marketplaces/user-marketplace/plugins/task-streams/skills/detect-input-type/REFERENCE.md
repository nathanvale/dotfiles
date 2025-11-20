## Supported Types

1. **review** - Code review findings (routes to format-bug-findings)
2. **spec** - Technical specifications (routes to format-spec)
3. **adr** - Architecture Decision Records (routes to format-generic)
4. **tech-debt** - Technical debt assessments (routes to format-tech-debt)
5. **security** - Security audits (routes to format-security)
6. **generic** - Unknown/mixed content (routes to format-generic)

## Detection Algorithm

### Input

```typescript
interface DetectionInput {
  content: string // Full document content
  filename: string // Document filename
  firstLines: string[] // First 50 lines (for efficiency)
  headings: string[] // All markdown headings
  hasFrontmatter: boolean // YAML frontmatter present
  frontmatter?: any // Parsed frontmatter if present
}
```

### Output

```typescript
interface DetectionResult {
  type: "review" | "spec" | "adr" | "tech-debt" | "security" | "generic"
  confidence: "high" | "medium" | "low"
  signals: string[] // List of detection signals found
  formatSkill: string // Which format skill to use
}
```

## Detection Heuristics

### Type: Review (Code Review Findings)

**Confidence: HIGH** - Must match 3+ signals:

**Strong Signals (weight: 3):**

- Contains review ID pattern: `R\d{3}` (e.g., R001, R015)
- Contains "Review Type:" or "Reviewer:" metadata
- Has P0-P3 classifications in findings (e.g., "P0-001:", "### P1:")
- Contains "Findings Summary" heading
- Contains "Review Readiness" or "Review Verdict" section

**Medium Signals (weight: 2):**

- Multiple sections with "Finding", "Issue", "Bug" in headings
- Contains "Regression Risk" subsections
- Contains "Remediation Steps" with numbered lists
- File path matches `docs/reviews/R\d{3}-*.md`
- Contains "Blocking Dependencies:" pattern

**Weak Signals (weight: 1):**

- Contains "buggy code" or "proposed fix"
- Has code blocks with language specifiers
- Contains "Files to Modify/Create/Delete" sections

**Example Detection:**

```markdown
# Code Review - R015

**Review ID:** R015
**Review Type:** Security & Performance

## Findings Summary

### P0-001: SQL Injection vulnerability
```

**Result:** `type: 'review', confidence: 'high'`

### Type: Spec (Technical Specification)

**Confidence: HIGH** - Must match 3+ signals:

**Strong Signals (weight: 3):**

- Contains "Requirements" or "Functional Requirements" heading
- Contains "User Stories" or "Use Cases" section
- Has "Acceptance Criteria" with multiple checkbox lists
- Contains "Technical Specification" or "Feature Spec" in title
- Has "System Requirements" or "Non-Functional Requirements"

**Medium Signals (weight: 2):**

- Contains "Background" or "Context" followed by "Solution"
- Has "API Endpoints" or "Data Model" sections
- Contains "Assumptions" and "Constraints" sections
- File path matches `docs/specs/*-spec.md` or `docs/features/prd-*.md`
- Contains "Out of Scope" section

**Weak Signals (weight: 1):**

- Multiple "As a [user], I want..." patterns
- Contains "Success Metrics" or "KPIs"
- Has architecture diagrams or mockups

**Example Detection:**

```markdown
# Authentication Redesign Specification

## Background

Current auth system uses legacy password-based auth...

## Requirements

### Functional Requirements

FR1: System shall support OAuth2 authentication
FR2: Users shall be able to...

## Acceptance Criteria

- [ ] OAuth2 flow implemented
- [ ] Token refresh works
```

**Result:** `type: 'spec', confidence: 'high'`

### Type: ADR (Architecture Decision Record)

**Confidence: HIGH** - Must match 2+ signals:

**Strong Signals (weight: 3):**

- Contains "Status: Accepted" or "Status: Proposed" or "Status: Deprecated"
- Has "Context", "Decision", "Consequences" sections (ADR format)
- Filename matches `adr-\d{3}-*.md` pattern
- Contains "Decision:" heading
- File path matches `docs/adrs/` or `docs/decisions/`

**Medium Signals (weight: 2):**

- Contains "Alternatives Considered" section
- Has "Rationale" section explaining decision
- Contains "Trade-offs" or "Pros and Cons" analysis

**Weak Signals (weight: 1):**

- Contains "Supersedes ADR-" or "Related ADRs:"
- Has structured decision documentation format

**Example Detection:**

```markdown
# ADR-005: Adopt OAuth2 for Authentication

**Status:** Accepted
**Date:** 2025-11-05

## Context

We need to modernize our authentication system...

## Decision

We will adopt OAuth2 with Azure AD B2C...

## Consequences

### Positive

- Improved security
- Single sign-on

### Negative

- Migration complexity
```

**Result:** `type: 'adr', confidence: 'high'`

### Type: Tech Debt (Technical Debt Assessment)

**Confidence: HIGH** - Must match 3+ signals:

**Strong Signals (weight: 3):**

- Contains "Technical Debt" in title or first heading
- Has "Debt Items" or "Tech Debt Inventory" section
- Contains "Refactor" or "Legacy Code" in multiple headings
- Contains "Technical Debt Assessment" or "Code Quality Analysis"

**Medium Signals (weight: 2):**

- Multiple mentions of "deprecated", "outdated", "legacy"
- Contains "Code Smells" or "Anti-patterns" sections
- Has "Refactoring Priority" or "Debt Priority" classification
- Contains "Estimated Effort to Fix" for multiple items
- File path matches `docs/tech-debt/` or `docs/quality/`

**Weak Signals (weight: 1):**

- Contains "Test Coverage" gaps
- Has "Duplication" or "Complexity" analysis
- Contains "Upgrade Path" or "Migration Strategy"

**Example Detection:**

```markdown
# Q4 Technical Debt Assessment

## Debt Inventory

### High Priority Debt

1. **Legacy Authentication System**
   - Status: Deprecated
   - Impact: Security risk
   - Refactor effort: 40h

2. **Outdated dependency: Express v4**
   - Status: EOL in 6 months
   - Migration path: Express v5
```

**Result:** `type: 'tech-debt', confidence: 'high'`

### Type: Security (Security Audit/Vulnerability Assessment)

**Confidence: HIGH** - Must match 3+ signals:

**Strong Signals (weight: 3):**

- Contains CVE references (e.g., "CVE-2024-1234")
- Has "Vulnerabilities" or "Security Findings" heading
- Contains OWASP references or CVSS scores
- Contains "Security Audit" or "Penetration Test" in title
- Has "Critical", "High", "Medium", "Low" severity classifications for security issues

**Medium Signals (weight: 2):**

- Multiple mentions of "vulnerability", "exploit", "attack vector"
- Contains "Security Controls" or "Mitigations" sections
- Has "Threat Model" or "Attack Surface" analysis
- Contains "SQL injection", "XSS", "CSRF", or other OWASP Top 10 terms
- File path matches `docs/security/` or contains "pentest", "audit"

**Weak Signals (weight: 1):**

- Contains "Security recommendations"
- Has "Compliance" (GDPR, HIPAA, SOC2) mentions
- Contains "Authentication" and "Authorization" together

**Example Detection:**

```markdown
# Security Audit Report - 2025 Q4

## Critical Vulnerabilities

### VULN-001: SQL Injection in User Search

**Severity:** Critical (CVSS 9.8)
**CVE:** CVE-2024-5678
**OWASP:** A03:2021 - Injection

The user search endpoint is vulnerable to SQL injection...

## Recommendations

1. Use parameterized queries
2. Implement input validation
```

**Result:** `type: 'security', confidence: 'high'`

### Type: Generic (Fallback)

**When to use:**

- No strong signals for any specific type (all scores < threshold)
- Mixed content from multiple types
- Unknown/novel document structure
- User-provided custom documentation

**Confidence:** Always 'low' (since it's a fallback)

**Strategy:**

- Extract headings and structure
- Identify action items and todos
- Look for any checkbox lists → potential tasks
- Parse numbered lists → potential implementation steps
- Fall back to section-by-section conversion

## Detection Process

### Step 1: Parse Document

```typescript
function parseDocument(content: string, filename: string) {
  return {
    content,
    filename,
    firstLines: content.split("\n").slice(0, 50),
    headings: extractMarkdownHeadings(content),
    hasFrontmatter: content.startsWith("---"),
    frontmatter: parseFrontmatter(content),
  }
}
```

### Step 2: Calculate Type Scores

```typescript
interface TypeScores {
  review: number
  spec: number
  adr: number
  techDebt: number
  security: number
}

function calculateScores(input: DetectionInput): TypeScores {
  const scores = {
    review: 0,
    spec: 0,
    adr: 0,
    techDebt: 0,
    security: 0,
  }

  // Check each signal and add weights
  // Strong signals: +3, Medium: +2, Weak: +1

  return scores
}
```

### Step 3: Determine Winner

```typescript
function determineType(scores: TypeScores): DetectionResult {
  const sortedScores = Object.entries(scores)
    .sort(([, a], [, b]) => b - a)

  const [winner, winnerScore] = sortedScores[0]
  const [runnerUp, runnerUpScore] = sortedScores[1]

  // High confidence: winner score >= 6 AND at least 3 points ahead
  // Medium confidence: winner score >= 4 AND at least 2 points ahead
  // Low confidence: fallback to generic

  if (winnerScore >= 6 && (winnerScore - runnerUpScore) >= 3) {
    return { type: winner, confidence: 'high', ... }
  } else if (winnerScore >= 4 && (winnerScore - runnerUpScore) >= 2) {
    return { type: winner, confidence: 'medium', ... }
  } else {
    return { type: 'generic', confidence: 'low', ... }
  }
}
```

### Step 4: Route to Format Skill

```typescript
const SKILL_ROUTING = {
  review: "format-bug-findings",
  spec: "format-spec",
  adr: "format-generic",
  "tech-debt": "format-tech-debt",
  security: "format-security",
  generic: "format-generic",
}

function getFormatSkill(type: string): string {
  return SKILL_ROUTING[type]
}
```

## Output Format

```
🔍 Document Type Detection

📄 Analyzing: docs/specs/auth-redesign-spec.md

Signals detected:
  ✅ [STRONG] Contains "Requirements" heading
  ✅ [STRONG] Contains "Acceptance Criteria" section
  ✅ [MEDIUM] File path matches spec pattern
  ✅ [WEAK] Contains "Success Metrics"

📊 Type Scores:
   • spec:      9 points ⭐ (winner)
   • review:    2 points
   • adr:       1 point
   • tech-debt: 0 points
   • security:  0 points

🎯 Detection Result:
   • Type: spec
   • Confidence: high
   • Format Skill: format-spec

Routing to format-spec skill...
```

## Edge Cases

### Ambiguous Documents

When document has signals from multiple types:

```
📊 Type Scores:
   • review:    7 points (code quality findings)
   • tech-debt: 6 points (legacy system refactor)

🤔 Ambiguous classification (close scores)
   • Treating as: review (higher score)
   • Note: Document has tech debt characteristics
```

**Strategy:** Use winner, but note ambiguity in output

### Empty or Minimal Documents

```markdown
# TODO

- Fix bug
- Add feature
```

**Strategy:**

- Detect as 'generic' with 'low' confidence
- format-generic will create simple task structure

### Novel Document Types

User creates custom documentation format not matching any pattern.

**Strategy:**

- Fallback to 'generic' type
- format-generic extracts structure best-effort
- User can validate/fix with /validate command

## Integration with Convert Command

```typescript
// In convert command
const input = parseDocument(content, filename)
const detection = detectInputType(input)

console.log(
  `Detected type: ${detection.type} (${detection.confidence} confidence)`
)
console.log(`Using format skill: ${detection.formatSkill}`)

// Route to appropriate format skill
const formatSkill = loadSkill(detection.formatSkill)
const formattedTasks = formatSkill.format(content, detection)
```

## Testing Strategy

### Test Cases

1. **Clear review document** → type: review, confidence: high
2. **Tech spec with requirements** → type: spec, confidence: high
3. **ADR with standard format** → type: adr, confidence: high
4. **Tech debt inventory** → type: tech-debt, confidence: high
5. **Security audit with CVEs** → type: security, confidence: high
6. **Mixed content** → type: generic, confidence: low
7. **Empty document** → type: generic, confidence: low
8. **Ambiguous (review + tech-debt)** → winner based on score, note ambiguity

## Notes

- **Fast detection**: First 50 lines analyzed for efficiency
- **Extensible**: Easy to add new types by adding signals
- **Transparent**: Shows signals and scores for debugging
- **Graceful degradation**: Falls back to generic when unsure
- **No false positives**: High threshold for confidence levels
