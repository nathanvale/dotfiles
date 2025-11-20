---
name: format-tech-debt
description:
  Transforms technical debt assessments into prioritized refactoring tasks with 15 enrichments (10
  universal + 5 tech debt-specific including ROI analysis). Use when user says 'format tech debt',
  'convert technical debt', 'process refactoring needs', 'prioritize tech debt', or when
  detect-input-type returns 'tech-debt'. Handles refactoring assessments and debt inventories in .md
  files. (plugin:task-streams)
---

# Format Tech Debt Skill

Converts technical debt assessments, code quality reports, and refactoring proposals into actionable
tasks with proper prioritization based on debt impact and remediation ROI.

## When to Use

Use this skill when you need to:

- Process technical debt assessment documents
- Convert code quality reports into refactoring tasks
- Transform SonarQube/CodeClimate findings into actionable items
- Extract debt items from architecture review documents
- Create tasks from dependency upgrade backlogs

## Purpose

Tech debt documents identify **quality issues** that slow development. This skill extracts debt
items, prioritizes by business impact (ROI analysis), and creates refactoring tasks with all 10
enrichments.

## Core Capabilities

1. **Debt Extraction** - Identifies technical debt items from various document formats
2. **ROI-Based Prioritization** - Maps debt impact to P0-P3 priorities using business value analysis
3. **10 Enrichments** - Adds file locations, effort estimates, acceptance criteria, testing
   requirements, etc.
4. **Component Classification** - Invokes component-manager skill for consistent categorization
5. **Task ID Generation** - Invokes id-generator skill with metadata tracking

## Output Template

**Reference**: @../../templates/tech-debt.template.md

This skill generates enriched output that MUST conform to the template structure above. All output
must include:

- All 10 universal enrichments (see template for details)
- Proper frontmatter metadata (id, title, priority, component, status, created, source)
- All required sections and field names exactly as shown in template
- No placeholder content

The template defines the structural contract. Your implementation fills in the actual values.

**Integration with Validator**: Use `validate-tech-debt` to verify your output matches this template
before deploying.

## Supporting Documentation

**See @../shared-enrichments.md** for the 10 universal enrichment patterns (common to all formats)

**See @tech-debt-enrichments.md** for the 5 tech debt-specific enrichments (metrics, refactoring
strategy, ROI analysis, quality improvements, safety mechanisms)

**See @priority-guide.md** for ROI-based P0-P3 prioritization rules

**See @examples.md** for complete enriched tech debt task examples

**See @workflow.md** for the detailed ROI calculation and extraction process

**See @reference.md** for debt-specific extraction strategies

**See @validation-checklist.md** for quality checks before finalizing tasks

**See @troubleshooting.md** for common tech debt extraction issues

## Quick Reference

**Skills Invoked:**

- `id-generator` - Sequential task IDs with metadata
- `component-manager` - Component classification

**Typical Output:** Task files in tasks/ directory with all enrichments

## Version History

- v2.0.0 (2025-11-05): Split into multi-file structure for token efficiency
- v1.1.0 (2025-11-05): Added SHARED_ENRICHMENTS.md reference
- v1.0.0 (2025-11-04): Initial release with ROI-based prioritization
