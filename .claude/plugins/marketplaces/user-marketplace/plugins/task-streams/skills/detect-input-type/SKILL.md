---
name: detect-input-type
description: Intelligently detects document type (review, spec, ADR, tech-debt, security, generic) from content and filename to route to appropriate format skill. Use when user says 'detect document type', 'what type of document is this', 'analyze document', 'classify document', or when converting documents without specifying type. Analyzes .md files for type indicators and structural patterns. (plugin:task-streams)
---

# Detect Input Type Skill

Analyzes document content and metadata to determine document type, enabling the convert command to route to the appropriate format skill.

## When to Use

Use this skill when you need to:

- Automatically detect document type before processing
- Route documents to the correct format skill
- Classify documents as review, spec, ADR, tech-debt, security, or generic
- Analyze document structure for type indicators
- Handle unknown or mixed-content documents

## Purpose

Provides intelligent type detection so the convert command can handle ANY document without manual type specification. Uses content heuristics, filename patterns, and structural markers to classify documents.

## Supported Types

1. **review** - Code review findings (routes to format-bug-findings)
2. **spec** - Technical specifications (routes to format-spec)
3. **adr** - Architecture Decision Records (routes to format-generic)
4. **tech-debt** - Technical debt assessments (routes to format-tech-debt)
5. **security** - Security audits (routes to format-security)
6. **generic** - Unknown/mixed content (routes to format-generic)

## Supporting Documentation

**See @reference.md** for:
- Complete scoring and classification logic
- Keyword patterns and structural markers per type
- Example documents and their detected types
- Detailed 8-step detection process
- Confidence scoring and threshold tuning
- Handling ambiguous or edge-case documents

## Quick Reference

**Detection Process:**

1. Filename analysis
2. Content heuristics
3. Structural analysis
4. Scoring and classification
5. Confidence verification (0.6 threshold)

**Typical Output:** Document type with confidence score for routing decisions

## Version History

- v2.0.0 (2025-11-05): Split into multi-file structure for token efficiency
- v1.0.0 (2025-11-04): Initial release with 6-type classification
