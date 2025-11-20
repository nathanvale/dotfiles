# Security-Specific Enrichments

These 5 enrichments are unique to security tasks and complement the 10 universal enrichments from
SHARED_ENRICHMENTS.md.

---

## 1. CVSS Score

**Purpose**: Standardized severity scoring for prioritization and compliance

**Format**:

```markdown
## CVSS Score

**CVSS v3.1**: 8.6 (HIGH) **Vector**: CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:L **CWE**: CWE-89
(SQL Injection) **OWASP**: A03:2021 - Injection
```

**Guidelines**:

- Use CVSS v3.1 calculator
- Include full vector string for audit trail
- Map to CWE (Common Weakness Enumeration)
- Reference OWASP Top 10 when applicable

---

## 2. Threat Actors & Attack Vector

**Purpose**: Understand who might exploit this and how

**Format**:

```markdown
## Threat Model

**Threat Actor**: External (unauthenticated) **Attack Path**: Public API → SQL injection → Data
exfiltration **Exploitability**: HIGH (automated tools available)
```

**Guidelines**:

- Identify threat actor type: External, Malicious insider, Opportunistic
- Document attack path step-by-step
- Rate exploitability: LOW, MEDIUM, HIGH, CRITICAL
- Note if exploit code is publicly available

---

## 3. Compliance Impact

**Purpose**: Regulatory and audit implications

**Format**:

```markdown
## Compliance Impact

**Frameworks Affected**: SOC 2 (CC6.1 FAIL), GDPR (Article 32), PCI-DSS (6.5.1) **Reporting
Required**: GDPR breach notification (72h) **Audit Impact**: Material weakness in SOC 2 audit
```

**Guidelines**:

- List all affected compliance frameworks
- Note specific controls that fail
- Document mandatory reporting requirements
- Identify audit implications (material weakness, observation, etc.)

---

## 4. Security Controls

**Purpose**: Defense-in-depth strategy

**Format**:

```markdown
## Security Controls

**Preventive**: Parameterized queries, input validation, WAF **Detective**: SIEM alerts, query
logging, anomaly detection **Compensating** (temp): Rate limiting, IP blocking, manual review
```

**Guidelines**:

- **Preventive**: Stop attack before it happens
- **Detective**: Detect attack in progress
- **Compensating**: Temporary measures until full fix deployed
- List 2-4 controls per category

---

## 5. Security Verification

**Purpose**: Prove vulnerability fixed and won't regress

**Format**:

```markdown
## Verification

**Pre-fix**: Reproduce with sqlmap, document exploit **Post-fix**: Re-test with sqlmap (should
fail), OWASP ZAP scan **Pentest**: External firm verification required for SOC 2
```

**Guidelines**:

- **Pre-fix**: Document how to reproduce vulnerability
- **Post-fix**: Specific tests that should now fail
- **Pentest**: Note if external verification required for compliance
- Include automated tests to prevent regression

---

## Quick Reference

All security tasks must include:

- ✅ 10 universal enrichments (SHARED_ENRICHMENTS.md)
- ✅ 5 security-specific enrichments (this file)
- ✅ Total: 15 enrichments per task
