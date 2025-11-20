# Priority Classification Guide for Security Findings

Maps security vulnerabilities to P0-P3 priorities using industry-standard severity frameworks (CVSS, OWASP).

## Priority Classification Rules

### P0 (Critical - Patch Immediately)

**Characteristics:**

- Remote code execution (RCE) vulnerabilities
- Authentication/authorization bypasses
- SQL injection, command injection
- Sensitive data exposure (PII, credentials in logs)
- Known exploits in the wild

**Examples:**

- Unauthenticated admin API endpoint
- SQL injection in user search allowing database access
- JWT secret hardcoded in repository
- User passwords stored in plaintext
- Deserialization vulnerability allowing RCE

**CVSS Score:** 9.0-10.0 (Critical)
**OWASP Risk:** Critical
**Timeline:** Patch within 24-48 hours

---

### P1 (High - Patch Within Week)

**Characteristics:**

- Cross-site scripting (XSS) vulnerabilities
- Cross-site request forgery (CSRF) gaps
- Insecure cryptography (weak algorithms)
- Missing security headers
- Insufficient rate limiting

**Examples:**

- Reflected XSS in search results
- Missing CSRF protection on sensitive actions
- Using MD5 for password hashing
- Missing Content-Security-Policy header
- API allows unlimited requests (DoS risk)

**CVSS Score:** 7.0-8.9 (High)
**OWASP Risk:** High
**Timeline:** Patch within 1 week

---

### P2 (Medium - Patch Within Month)

**Characteristics:**

- Information disclosure (stack traces, version info)
- Session management weaknesses
- Insufficient logging/monitoring
- Outdated dependencies with known CVEs (low severity)
- Missing input validation (non-exploitable)

**Examples:**

- Detailed error messages exposing file paths
- Session timeout set too long (24 hours)
- No audit logging for admin actions
- Dependency with CVE-2023-XXXX (CVSS 5.0)
- Missing input length validation

**CVSS Score:** 4.0-6.9 (Medium)
**OWASP Risk:** Medium
**Timeline:** Patch within 30 days

---

### P3 (Low - Patch When Convenient)

**Characteristics:**

- Security best practice violations
- Hardening opportunities
- Defense-in-depth improvements
- Documentation gaps (security runbooks)
- Minor configuration improvements

**Examples:**

- Using HTTP instead of HTTPS for internal service
- Missing HttpOnly flag on non-sensitive cookie
- No automated security scanning in CI/CD
- Missing security incident response plan
- Overly permissive file permissions

**CVSS Score:** 0.1-3.9 (Low)
**OWASP Risk:** Low
**Timeline:** Patch within next quarter

---

## Priority Decision Tree

```
Is there remote code execution possible?
├─ YES → P0
└─ NO → Continue

Can attacker bypass authentication?
├─ YES → P0
└─ NO → Continue

Can attacker access/modify sensitive data?
├─ YES → P0 (if direct) or P1 (if requires conditions)
└─ NO → Continue

Is there a working exploit available?
├─ YES → Increase by 1 level
└─ NO → Continue

Does it violate compliance requirements?
├─ YES → P0 or P1
└─ NO → Continue

Is it a configuration or best practice issue?
├─ YES → P2 or P3
└─ NO → P2
```

---

## OWASP Top 10 (2021) Mapping

| OWASP Category                    | Typical Priority |
| --------------------------------- | ---------------- |
| A01: Broken Access Control        | P0-P1            |
| A02: Cryptographic Failures       | P0-P1            |
| A03: Injection                    | P0-P1            |
| A04: Insecure Design              | P1-P2            |
| A05: Security Misconfiguration    | P1-P2            |
| A06: Vulnerable Components        | P1-P2            |
| A07: Identification/Auth Failures | P0-P1            |
| A08: Software/Data Integrity      | P1-P2            |
| A09: Logging/Monitoring Failures  | P2-P3            |
| A10: Server-Side Request Forgery  | P1-P2            |

---

## Special Cases

### Escalation Rules

Escalate priority if:

- **Public disclosure**: Vulnerability publicly documented → P0
- **Active exploitation**: Evidence of exploitation attempts → P0
- **Regulatory impact**: Violates PCI-DSS, HIPAA, GDPR → P0
- **Privileged access**: Affects admin/root accounts → Increase by 1 level
- **Production exposure**: Internet-facing system → Increase by 1 level

### De-escalation Rules

De-escalate priority if:

- **Requires authentication**: Already authenticated users only → Decrease by 1 level
- **Internal only**: Not internet-facing → Decrease by 1 level
- **Compensating controls**: WAF, network segmentation in place → Decrease by 1 level
- **Low impact data**: No PII or sensitive data → Decrease by 1 level

---

## Priority Distribution Guidelines

**Healthy security assessment:**

- P0: < 5% (critical vulnerabilities only)
- P1: 10-20% (high severity issues)
- P2: 40-50% (medium severity issues)
- P3: 30-40% (low severity, hardening)

**Warning signs:**

- > 15% P0: System has severe security posture issues
- > 60% P3: Assessment lacks depth or missed critical issues
- All same priority: Assessment lacks severity discrimination

---

## Response Time Targets

| Priority | Discovery → Patch | Patch → Deploy | Total Window |
| -------- | ----------------- | -------------- | ------------ |
| P0       | 4-8 hours         | 2-4 hours      | 24-48 hours  |
| P1       | 2-4 days          | 1-2 days       | 1 week       |
| P2       | 1-2 weeks         | 1 week         | 30 days      |
| P3       | 1-2 months        | 2 weeks        | 90 days      |

---

## Compliance Considerations

### PCI-DSS

- All P0/P1 vulnerabilities must be addressed immediately
- Quarterly vulnerability scans required
- P2 vulnerabilities acceptable with compensating controls

### HIPAA

- P0 vulnerabilities constitute breach notification trigger
- Risk analysis must document all P1+ findings
- Security incident response plan required

### GDPR

- P0 data exposure requires 72-hour breach notification
- Data protection impact assessment for P0/P1 findings
- Regular security assessments required
