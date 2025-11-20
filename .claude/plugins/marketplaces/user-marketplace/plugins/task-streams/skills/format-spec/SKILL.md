---
name: format-spec
description: Transforms technical specifications into task files with 15 enrichments (10 universal + 5 spec-specific including UX flow and success metrics). Use when user says 'format specification', 'convert spec to tasks', 'process requirements', 'extract tasks from spec', or when detect-input-type returns 'spec'. Handles PRDs, feature specs, and technical requirements in .md files. (plugin:task-streams)
---

# Format Spec Skill

Converts technical specifications (feature specs, PRDs, design docs) into standardized task files with all 10 required enrichments.

## When to Use

Use this skill when you need to:

- Process technical specification documents
- Convert PRDs (Product Requirements Documents) into implementation tasks
- Extract requirements from design documents
- Transform user stories into actionable tasks
- Create tasks from feature specifications

## Purpose

Technical specs describe **what** to build. This skill extracts requirements, user stories, and acceptance criteria from specs and transforms them into implementation tasks.

## Core Capabilities

1. **Requirement Extraction** - Identifies functional and non-functional requirements from various spec formats
2. **Priority Classification** - Maps requirement language to P0-P3 priorities
3. **10 Enrichments** - Adds file locations, effort estimates, acceptance criteria, testing requirements, etc.
4. **Component Classification** - Invokes component-manager skill for consistent categorization
5. **Task ID Generation** - Invokes id-generator skill with metadata tracking

## Output Template

**Reference**: @../../templates/spec.template.md

This skill generates enriched output that MUST conform to the template structure above. All output must include:

- All 10 universal enrichments (see template for details)
- Proper frontmatter metadata (id, title, priority, component, status, created, source)
- All required sections and field names exactly as shown in template
- No placeholder content

The template defines the structural contract. Your implementation fills in the actual values.

**Integration with Validator**: Use `validate-spec` to verify your output matches this template before deploying.

## Supporting Documentation

**See @../shared-enrichments.md** for the 10 universal enrichment patterns (common to all formats)

**See @spec-enrichments.md** for the 5 spec-specific enrichments (user flow, API contract, feature flags, data model, success metrics)

**See @priority-guide.md** for spec language → P0-P3 mapping rules

**See @examples.md** for complete enriched task examples from specs

**See @workflow.md** for the detailed 11-step extraction process

**See @reference.md** for format-specific extraction strategies

**See @validation-checklist.md** for quality checks before finalizing tasks

**See @troubleshooting.md** for common spec extraction issues

## Quick Reference

**Skills Invoked:**

- `id-generator` - Sequential task IDs with metadata
- `component-manager` - Component classification

**Typical Output:** Task files in tasks/ directory with all enrichments

## Version History

- v2.0.0 (2025-11-05): Split into multi-file structure for token efficiency
- v1.1.0 (2025-11-05): Added SHARED_ENRICHMENTS.md reference
- v1.0.0 (2025-11-04): Initial release with spec-specific extraction
