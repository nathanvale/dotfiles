---
name: format-bug-findings
description:
  Formats code review findings into task-decomposable output with 15 enrichments (10 universal + 5
  bug-specific including root cause and pattern detection). Use when user says 'format code review',
  'process bug findings', 'convert review to tasks', 'enrich code review findings', or when
  processing .md code review documents. Routes through detect-input-type. (plugin:task-streams)
---

# Format Bug Findings Skill

Transforms raw code review findings into standardized, task-decomposable output format. Ensures each
finding includes all 10 critical enrichments required for task extraction.

## When to Use

Use this skill when you need to:

- Process code review findings into tasks
- Format bug reports with complete metadata
- Enrich review output with file locations and test requirements
- Add acceptance criteria to review findings
- Prepare findings for task decomposition

## Purpose

Code reviews produce **findings** that need fixing. This skill enriches findings with all 10
required elements (file locations, effort estimates, acceptance criteria, testing requirements,
etc.) to enable task extraction.

## Core Capabilities

1. **Finding Enrichment** - Adds all 10 required enrichments to code review findings
2. **Priority Classification** - Maps finding severity to P0-P3 priorities
3. **File Location Extraction** - Adds specific file paths and line numbers
4. **Testing Table Generation** - Maps tests to acceptance criteria
5. **Component Classification** - Invokes component-manager skill for categorization

## Output Templates

### For Task Files (Markdown)

**Reference**: @../../templates/bug-findings.template.md

This skill generates enriched output that MUST conform to the template structure above. All output
must include:

- All 10 universal enrichments (see template for details)
- Proper frontmatter metadata (id, title, priority, component, status, created, source)
- All required sections and field names exactly as shown in template
- No placeholder content

The template defines the structural contract. Your implementation fills in the actual values.

**Integration with Validator**: Use `validate-bug-findings` to verify your output matches this
template before deploying.

### For Report Files (JSON)

**Reference**: `~/.claude/templates/report-output.json` OR `.claude/templates/report-output.json`

When generating JSON reports (e.g., for code-analyzer integration), use the JSON template structure
with all 15 enrichments:

- 10 universal enrichments (location, effort, complexity, acceptance_criteria, etc.)
- 5 bug-specific enrichments (root_cause, impact_analysis, reproduction_steps, hotfix_decision,
  pattern_detection)

**CRITICAL when writing JSON:** Construct fresh JSON string. Never copy Read tool formatted output
(no STDIN, no line numbers).

## Supporting Documentation

**See @../shared-enrichments.md** for the 10 universal enrichment patterns (common to all formats)

**See @bug-enrichments.md** for the 5 bug-specific enrichments (root cause analysis, impact
analysis, reproduction steps, hotfix decision, pattern detection)

**See @priority-guide.md** for detailed P0-P3 classification rules for bugs

**See @examples.md** for complete enriched finding examples

**See @workflow.md** for the detailed 12-step enrichment process

**See @reference.md** for format-specific extraction strategies

**See @validation-checklist.md** for quality checks before finalizing findings

**See @troubleshooting.md** for common issues and solutions

## Quick Reference

**Skills Invoked:**

- `component-manager` - Component classification for findings

**Typical Output:** Enriched findings ready for task decomposition

## Version History

- v2.0.0 (2025-11-05): Split into multi-file structure for token efficiency
- v1.1.0 (2025-11-05): Added SHARED_ENRICHMENTS.md reference
- v1.0.0 (2025-11-04): Initial release with format-specific extraction
