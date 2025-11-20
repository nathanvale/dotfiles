---
name: format-security
description: Transforms security audits and vulnerability assessments into prioritized remediation tasks with 15 enrichments (10 universal + 5 security-specific). Use when user says 'format security audit', 'process vulnerabilities', 'convert security findings', 'prioritize security issues', or when detect-input-type returns 'security'. Handles CVE reports, penetration test results, and security scans in .md files. (plugin:task-streams)
---

# Format Security Skill

Converts security audit reports, penetration test results, and vulnerability assessments into actionable remediation tasks with proper risk-based prioritization.

## When to Use

Use this skill when you need to:

- Process security audit reports and penetration test results
- Convert vulnerability assessments into remediation tasks
- Transform CVSS-scored findings into prioritized tasks
- Extract vulnerabilities from OWASP Top 10 assessments
- Create tasks from security scanner output (Snyk, SonarQube Security)

## Purpose

Security audits identify **vulnerabilities** that need fixing. This skill extracts vulnerabilities, maps them to P0-P3 priorities based on severity (CVSS/OWASP), and creates remediation tasks with security-specific enrichments.

## Core Capabilities

1. **Vulnerability Extraction** - Identifies security issues from various audit formats
2. **CVSS-Based Prioritization** - Maps CVSS scores and severity to P0-P3 priorities
3. **10 Enrichments** - Adds file locations, effort estimates, acceptance criteria, testing requirements, etc.
4. **Component Classification** - Invokes component-manager skill for consistent categorization
5. **Task ID Generation** - Invokes id-generator skill with metadata tracking

## Output Template

**Reference**: @../../templates/security.template.md

This skill generates enriched output that MUST conform to the template structure above. All output must include:

- All 10 universal enrichments (see template for details)
- Proper frontmatter metadata (id, title, priority, component, status, created, source)
- All required sections and field names exactly as shown in template
- No placeholder content

The template defines the structural contract. Your implementation fills in the actual values.

**Integration with Validator**: Use `validate-security` to verify your output matches this template before deploying.

## Supporting Documentation

**See @../shared-enrichments.md** for the 10 universal enrichment patterns (common to all formats)

**See @security-enrichments.md** for the 5 security-specific enrichments (CVSS, threat model, compliance, controls, verification)

**See @priority-guide.md** for CVSS → P0-P3 mapping with escalation rules

**See @examples.md** for complete enriched security remediation examples

**See @workflow.md** for the detailed vulnerability extraction process

**See @reference.md** for security-specific extraction strategies

**See @validation-checklist.md** for quality checks before finalizing tasks

**See @troubleshooting.md** for common security extraction issues

## Quick Reference

**Skills Invoked:**

- `id-generator` - Sequential task IDs with metadata
- `component-manager` - Component classification

**Typical Output:** Remediation task files in tasks/ directory with all enrichments

## Version History

- v2.0.0 (2025-11-05): Split into multi-file structure for token efficiency
- v1.1.0 (2025-11-05): Added SHARED_ENRICHMENTS.md reference
- v1.0.0 (2025-11-04): Initial release with CVSS-based prioritization
