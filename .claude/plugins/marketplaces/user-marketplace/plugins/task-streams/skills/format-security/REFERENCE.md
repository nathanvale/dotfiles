# Format Security Reference

Complete reference for transforming security audits and vulnerability assessments into prioritized
remediation tasks.

---

## 10 Required Enrichments

**For complete enrichment patterns and templates, see @../SHARED_ENRICHMENTS.md**

Every security remediation task MUST include all 10 enrichments:

1. Specific file locations with line numbers
2. Effort estimates in hours
3. Complexity classification
4. Concrete acceptance criteria (3-5 items)
5. Regression risk assessment (5 dimensions)
6. Actionable remediation steps
7. Code examples (vulnerable vs secure)
8. File change scope (Create/Modify/Delete)
9. Required testing table
10. Dependencies and blocking information

---

## Input: Security Audit Structures

This skill handles three common security audit formats:

### Structure 1: CVSS-Based Vulnerability Report

```markdown
# Security Audit Report

## Critical Vulnerabilities (CVSS 9.0-10.0)

### VULN-001: SQL Injection in User Search

**CVSS Score:** 9.8 (Critical) **CVE:** CVE-2024-5678 **OWASP:** A03:2021 - Injection

{Description}

**Remediation:**

1. Use parameterized queries
2. Implement input validation
```

### Structure 2: OWASP Top 10 Assessment

```markdown
# OWASP Top 10 Assessment

## A01: Broken Access Control

### Finding 1: Missing authorization checks

**Severity:** High **Affected endpoints:** /api/admin/\*

{Description}

## A03: Injection

### Finding 2: SQL Injection vulnerability

**Severity:** Critical
```

### Structure 3: Penetration Test Results

```markdown
# Penetration Test Report

## Executive Summary

{High-level findings}

## Technical Findings

### 1. Authentication Bypass

**Risk Rating:** Critical **Attack Complexity:** Low **Proof of Concept:** {PoC details}

**Recommendation:**

- Implement MFA
- Enforce session timeout
```

---

## Priority Mapping: CVSS → Priority

### CVSS Score Mapping

| CVSS Score | Severity      | Priority | Rationale                                       |
| ---------- | ------------- | -------- | ----------------------------------------------- |
| 9.0-10.0   | Critical      | P0       | Immediate threat to system                      |
| 7.0-8.9    | High          | P0       | Security high always P0 (stricter than general) |
| 4.0-6.9    | Medium        | P1       | Significant security risk                       |
| 0.1-3.9    | Low           | P2       | Minor security concern                          |
| 0.0        | Informational | P3       | No direct security impact                       |

**Key difference from general priority:** Security "High" = P0 (not P1)

### Risk-Based Priority Escalation

Even if base severity is "medium", escalate to P0 if:

- **Exploitable remotely without authentication**
- **Affects sensitive data** (PII, credentials, financial)
- **Active exploitation detected** in wild
- **Compliance violation** (GDPR, HIPAA, PCI-DSS, SOC 2)

```typescript
function adjustSecurityPriority(basePriority: string, finding: SecurityFinding): string {
  // Escalation rules
  if (finding.exploitable && finding.dataExposure === "PII") {
    return "P0"; // Always P0 for exploitable PII exposure
  }
  if (finding.compliance === "PCI-DSS") {
    return "P0"; // Compliance violations are P0
  }
  if (finding.activeExploitation) {
    return "P0"; // Zero-day or active attacks are P0
  }
  return basePriority;
}
```

### Priority Examples

| Vulnerability                 | CVSS | Base Priority | Escalation          | Final | Rationale                  |
| ----------------------------- | ---- | ------------- | ------------------- | ----- | -------------------------- |
| SQL Injection (auth bypass)   | 9.8  | P0            | None                | P0    | Critical CVSS              |
| XSS (requires auth)           | 6.5  | P1            | None                | P1    | Medium CVSS                |
| XSS (steals admin session)    | 6.5  | P1            | Sensitive data      | P0    | Escalated for admin access |
| Missing rate limiting         | 5.3  | P1            | None                | P1    | Medium CVSS                |
| Exposed API key in logs       | 7.5  | P0            | Active exploitation | P0    | Already P0 + active threat |
| Outdated library (no exploit) | 3.9  | P2            | None                | P2    | Low CVSS                   |

---

## Extraction Strategy

### Phase 1: Extract Vulnerabilities

Each vulnerability becomes a separate remediation task:

```markdown
## Critical Vulnerabilities

### VULN-001: SQL Injection

### VULN-002: XSS in Comment Form

### VULN-003: Insecure Direct Object Reference

→ Creates 3 tasks: T0001, T0002, T0003
```

### Phase 2: Extract Security-Specific Fields

#### Vulnerability Identification

Extract all security identifiers:

```markdown
**Vulnerability ID:** VULN-001 **CVE:** CVE-2024-5678 **CVSS Score:** 9.8 (Critical) **CWE:** CWE-89
(SQL Injection) **OWASP:** A03:2021 - Injection
```

#### Attack Vector Analysis

Extract CVSS attack vector components:

```markdown
**Attack Vector:** Network (remotely exploitable) **Attack Complexity:** Low (easy to exploit)
**Privileges Required:** None (unauthenticated) **User Interaction:** None (no user action needed)
**Scope:** Changed (affects other components) **Confidentiality Impact:** High **Integrity Impact:**
High **Availability Impact:** High
```

#### Affected Assets

```markdown
**Affected:**

- Endpoint: `/api/users/search?query=`
- File: `src/api/users.ts:145-167`
- Data at risk: User PII (name, email, phone, SSN)
- Systems: Database server, API layer, authentication
```

#### Proof of Concept (Sanitized)

If PoC provided in audit, include (sanitized):

````markdown
**Proof of Concept (Sanitized):**

```http
GET /api/users/search?query=' OR '1'='1' --
```

**Result:** Returns all user records including sensitive data

⚠️ **WARNING: Do not execute in production**
````

#### Compliance Impact

```markdown
**Compliance Impact:**

- **GDPR:** Article 32 - Security of processing violated
- **HIPAA:** PHI exposure risk (164.312(a)(1))
- **PCI-DSS:** Requirement 6.5.1 - Injection flaws
- **SOC 2:** CC6.1 - Logical and physical access controls

**Potential penalties:**

- GDPR: Up to €20M or 4% annual revenue
- HIPAA: $100-$50,000 per violation
- PCI-DSS: Fines + loss of card processing ability
```

### Phase 3: Priority Classification

Apply security-specific priority mapping:

1. **Check CVSS score** → Map to base priority
2. **Check escalation factors** → Escalate if needed
3. **Check compliance impact** → Escalate if violation
4. **Final priority** → P0/P1/P2/P3

### Phase 4: Security-Focused Acceptance Criteria

Generate security-specific ACs:

```markdown
**Acceptance Criteria:**

- [ ] All SQL queries use parameterized statements (no string concatenation)
- [ ] Input validation rejects SQL injection patterns
- [ ] Manual penetration test confirms vulnerability fixed
- [ ] Automated security tests added to CI/CD pipeline
- [ ] Code review confirms secure coding practices followed
- [ ] Security documentation updated with fix details
- [ ] Compliance team notified of remediation
```

### Phase 5: Testing Requirements (Security Focus)

```markdown
**Required Testing:** | Test Type | Validates AC | Description | Location |
|-----------|--------------|-------------|----------| | Static Analysis (SAST) | AC1 | Scan confirms
no SQL concat | CI/CD pipeline | | Input Fuzzing | AC2 | Fuzz test with SQL injection vectors |
`tests/security/sqli.test.ts` | | Penetration Test | AC3 | Manual retest by security team | External
pentest | | Integration Test | AC4 | Verify queries work with valid input |
`tests/api/users.test.ts` | | Security Regression | AC5 | Automated SQL injection test suite |
`tests/security/regression.ts` |
```

### Phase 6: Remediation Steps

Structure audit recommendations into implementation steps:

```markdown
**Remediation Steps:**

1. **Immediate Mitigation**
   - Disable vulnerable endpoint (if critical)
   - Apply WAF rules to block attack patterns
   - Monitor logs for exploitation attempts

2. **Code Fixes**
   - Replace string concatenation with parameterized queries
   - Implement whitelist-based input validation
   - Add SQL injection detection middleware
   - Apply principle of least privilege to database user

3. **Testing**
   - Add comprehensive input sanitization tests
   - Perform security regression testing
   - Schedule penetration test revalidation

4. **Documentation**
   - Update secure coding guidelines
   - Document fix in security advisory
   - Notify compliance team of remediation

5. **Monitoring**
   - Add security event logging
   - Set up alerts for injection attempts
   - Track fix effectiveness metrics
```

### Phase 7: Effort Estimation

**Security remediation base estimates:**

| Vulnerability Type                    | Base Effort | Multipliers                     |
| ------------------------------------- | ----------- | ------------------------------- |
| Injection (SQL/XSS/Command)           | 12h         | Endpoints affected: ×1.3 per 5  |
| Broken Authentication                 | 20h         | Auth flows: ×1.5 per flow       |
| Sensitive Data Exposure               | 16h         | Data types: ×1.2 per type       |
| XML External Entities (XXE)           | 8h          | Parsers: ×1.5 per parser        |
| Broken Access Control                 | 16h         | Endpoints: ×1.2 per 10          |
| Security Misconfiguration             | 8h          | Services: ×1.3 per service      |
| Cross-Site Scripting (XSS)            | 10h         | Input points: ×1.2 per 10       |
| Insecure Deserialization              | 14h         | Complexity: ×1.5 if distributed |
| Components with Known Vulnerabilities | 6h          | Dependencies: ×1.1 per 5        |
| Insufficient Logging & Monitoring     | 12h         | Systems: ×1.2 per system        |

**Security-specific overhead:**

- Penetration test revalidation: +8h
- Compliance documentation: +4h
- Security team review: +2h

**Example:**

- SQL injection in 15 endpoints → 12h × 3.9 multiplier + 14h overhead = 61h

### Phase 8: Component Classification

Invoke **component-manager skill** to classify vulnerability:

**Example:**

- Vulnerability relates to: "API Authentication"
- Component-manager returns: C05 (Authentication & Authorization)
- Use in task: **Component:** C05: Authentication & Authorization

### Phase 9: Task ID Generation

Invoke **id-generator skill**:

**Example:**

- Component: C05
- Priority: P0 (Critical CVSS)
- Sequence: 1
- Generated ID: C05-P0-001

### Phase 10: Create Remediation Task Files

Output security remediation tasks with all enrichments.

---

## Integration with Convert Command

```bash
/convert docs/security/Q4-security-audit.md

# detect-input-type detects "security" type
# Routes to format-security skill
# Extracts vulnerabilities with CVSS mapping
# Output: tasks/C05-P0-001.md, tasks/C07-P1-002.md, etc.
```

---

## Quality Checks

Before finalizing remediation tasks:

- [ ] CVSS score mapped to priority correctly
- [ ] Escalation factors considered (PII, compliance, exploitation)
- [ ] Vulnerability ID, CVE, CWE, OWASP references included
- [ ] Attack vector analysis complete
- [ ] Compliance impact documented
- [ ] Proof of concept sanitized (if included)
- [ ] Security-focused acceptance criteria (penetration test, SAST)
- [ ] Testing includes security regression tests
- [ ] Remediation steps include monitoring/logging
- [ ] All 10 enrichments present (see SHARED_ENRICHMENTS.md)
- [ ] Component classification applied
- [ ] Task IDs generated

---

## Special Cases

### Zero-Day Vulnerabilities

If active exploitation detected:

1. Mark as P0 immediately (regardless of CVSS)
2. Add "Immediate Mitigation" phase to remediation
3. Include incident response coordination
4. Fast-track security review

### Compliance-Critical Vulnerabilities

If compliance violation:

1. Escalate priority (minimum P1, usually P0)
2. Document compliance impact with article/requirement references
3. Add compliance team notification to steps
4. Include regulatory timeline constraints

### Vendor-Reported Vulnerabilities

If reported by third-party scanner/vendor:

1. Verify vulnerability manually (false positives common)
2. If confirmed, follow standard process
3. If false positive, document why and close
4. Update scanner configuration to prevent recurrence

---

## Notes

- Security "High" severity = P0 (stricter than general priority mapping)
- Always consider compliance impact for priority escalation
- Include penetration test revalidation in testing requirements
- Sanitize any proof-of-concept code before including in tasks
- Security remediation effort includes overhead (pentest, compliance, review)
- CVSS scores guide priority but escalation factors override
- Always reference SHARED_ENRICHMENTS.md for complete enrichment patterns
- Component classification enables tracking vulnerabilities by system area
- Monitor for active exploitation during remediation process
