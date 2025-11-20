---
name: format-generic
description:
  Fallback formatter that extracts tasks from any document structure using best-effort pattern
  matching. Use when user says 'format unknown document', 'extract tasks from any document',
  'process mixed content', 'handle custom format', or when detect-input-type returns 'generic'.
  Handles ADRs, custom docs, and novel structures in .md files. (plugin:task-streams)
---

# Format Generic Skill

Fallback formatter that handles documents not matching specific types (spec, review, ADR, tech debt,
security). Uses best-effort extraction to create tasks from any structured content.

## When to Use

Use this skill when you need to:

- Process documents that don't match standard formats
- Extract tasks from mixed-content documents
- Handle custom documentation formats
- Process ADRs (Architecture Decision Records)
- Create tasks from novel document structures

## Purpose

When document type is unclear or mixed, this skill provides **graceful degradation** - extract
what's possible, mark unclear items as TBD, and let users refine via validation.

## Core Capabilities

1. **Structural Analysis** - Identifies task boundaries in any document format
2. **Best-Effort Extraction** - Extracts titles, descriptions, and ACs using heuristics
3. **TBD Marking** - Clearly marks uncertain/missing information
4. **Component Classification** - Invokes component-manager skill for categorization
5. **Task ID Generation** - Invokes id-generator skill with metadata tracking

## Output Template

**Reference**: @../../templates/generic.template.md

This skill generates enriched output that MUST conform to the template structure above. All output
must include:

- All 10 universal enrichments (see template for details)
- Proper frontmatter metadata (id, title, priority, component, status, created, source)
- All required sections and field names exactly as shown in template
- No placeholder content

The template defines the structural contract. Your implementation fills in the actual values.

**Integration with Validator**: Use `validate-generic` to verify your output matches this template
before deploying.

## Supporting Documentation

**See @../shared-enrichments.md** for the 10 universal enrichment patterns (common to all formats)

**See @priority-guide.md** for keyword-based P0-P3 inference rules

**See @examples.md** for complete task examples with TBD markers

**See @workflow.md** for the detailed best-effort extraction process

**See @reference.md** for structural analysis and heuristic patterns

**See @validation-checklist.md** for quality checks before finalizing tasks

**See @troubleshooting.md** for handling ambiguous documents

## Quick Reference

**Skills Invoked:**

- `id-generator` - Sequential task IDs with metadata
- `component-manager` - Component classification (C00 fallback if unclear)

**Typical Output:** Task files with TBD markers for uncertain content

## Version History

- v2.0.0 (2025-11-05): Split into multi-file structure for token efficiency
- v1.1.0 (2025-11-05): Added SHARED_ENRICHMENTS.md reference
- v1.0.0 (2025-11-04): Initial release with best-effort extraction
