# Claude Code Templates

This directory contains standardized templates for agents, skills, and commands to reference.

## Purpose

- **Single source of truth** for output formats
- **Prevents duplication** across multiple files
- **Ensures consistency** in JSON structure
- **Easy maintenance** - update once, applies everywhere

## Available Templates

### report-output.json

**Used by:**

- `code-analyzer` agent
- `format-bug-findings` skill
- Any other code analysis agents/skills

**Structure:**

- 15 enrichments (10 universal + 5 bug-specific)
- Task-streams compatible
- Observability metadata included

**Usage in agents/skills:**

```markdown
Write( file_path="docs/reports/R001-description.json", content='<JSON matching
.claude/templates/report-output.json structure>' )
```

**Important:** When writing JSON files:

- Construct JSON object fresh as a string
- Never copy Read tool formatted output (no line numbers, no STDIN header)
- Use the template as a structure reference, fill with actual data

## Adding New Templates

When creating a new template:

1. Create the template file in `.claude/templates/`
2. Document it in this README
3. Reference it from agents/skills that use it
4. Include inline comments explaining each field

## Template Guidelines

- Use inline comments (`"// ---"`) for section headers
- Show all possible values for enums (e.g., `"P0 | P1 | P2 | P3"`)
- Include descriptive placeholder text
- Keep examples concise but complete
- Document required vs optional fields
