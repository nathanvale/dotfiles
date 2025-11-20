# Template System Documentation

## Overview

The Template System provides a standardized structure contract for all enriched task formats in the
Task Streams system. Templates define the required sections and metadata that format skills must
include when generating task documentation.

### What is a Template?

A template is a **structure-only** Markdown file that defines:

- Required sections (headings)
- Required fields (metadata placeholders)
- Frontmatter metadata (template name, version, description)
- The 10 universal enrichments that all tasks must include

Templates are **NOT** filled with placeholder content. They serve as a structural contract that
format skills must follow.

### Why Templates Exist

Templates ensure:

1. **Consistency**: All task formats have the same enrichment structure
2. **Completeness**: No format can skip required enrichments
3. **Discoverability**: External plugins can discover and use templates programmatically
4. **Validation**: Automated checks ensure templates maintain quality standards

### Key Principle: Structure-Only, No Placeholders

Templates define structure, not content. Format skills are responsible for generating real content
that follows the template structure.

❌ **Wrong** (placeholder content):

```markdown
**Location:** [FILE PATH HERE]
```

✅ **Correct** (structure only):

```markdown
**Location:**
```

Format skills fill in actual values:

```markdown
**Location:** `apps/migration-cli/src/lib/services/blob-storage.ts`
```

---

## Template Structure

All templates must include the **10 universal enrichments** defined in `SHARED_ENRICHMENTS.md`:

### Quick Reference Table

| #   | Enrichment           | Key Field                                                                                | Template Section            |
| --- | -------------------- | ---------------------------------------------------------------------------------------- | --------------------------- |
| 1   | File Locations       | **Location:**                                                                            | Core Metadata               |
| 2   | Effort Estimation    | **Estimated Effort:**                                                                    | Core Metadata               |
| 3   | Complexity           | **Complexity:**                                                                          | Core Metadata               |
| 4   | Acceptance Criteria  | **Acceptance Criteria:**                                                                 | ## Acceptance Criteria      |
| 5   | Regression Risk (5D) | **Impact:**, **Blast Radius:**, **Dependencies:**, **Testing Gaps:**, **Rollback Risk:** | ## Regression Risk Analysis |
| 6   | Implementation Steps | **Implementation Steps:**                                                                | ## Implementation Plan      |
| 7   | Code Examples        | (Code blocks)                                                                            | ## Code Examples            |
| 8   | File Changes (3C)    | **Files to Create:**, **Files to Modify:**, **Files to Delete:**                         | ## File Changes             |
| 9   | Testing Table        | **Required Testing:**                                                                    | ## Testing Requirements     |
| 10  | Dependencies         | **Blocking Dependencies:**, **Blocks:**, **Prerequisites:**                              | ## Dependencies             |

### Frontmatter Requirements

All templates must include YAML frontmatter with these fields:

```yaml
---
templateName: template-name # Kebab-case name matching filename
templateVersion: 1.0.0 # Semantic versioning
description: Brief description # Human-readable description
requiredEnrichments: 10 # Must be 10 (all enrichments required)
formatSkill: format-skill-name # Associated format skill
---
```

---

## Available Templates

The template system includes 5 production templates:

### 1. Bug Findings Template

**File:** `bug-findings.template.md` **Format Skill:** `format-bug-findings` **Description:**
Template for documenting bug findings from code reviews or testing

Use for: Bug reports, code review findings, defect documentation

### 2. Generic Template

**File:** `generic.template.md` **Format Skill:** `format-generic` **Description:** General-purpose
template for tasks that don't fit other categories

Use for: General tasks, miscellaneous work items, catch-all documentation

### 3. Security Template

**File:** `security.template.md` **Format Skill:** `format-security` **Description:** Template for
security-related tasks and vulnerability documentation

Use for: Security vulnerabilities, security improvements, threat modeling

### 4. Spec Template

**File:** `spec.template.md` **Format Skill:** `format-spec` **Description:** Template for technical
specifications and design documents

Use for: Feature specs, architecture documents, design proposals

### 5. Tech Debt Template

**File:** `tech-debt.template.md` **Format Skill:** `format-tech-debt` **Description:** Template for
technical debt tasks and code quality improvements

Use for: Refactoring, code cleanup, technical debt remediation

---

## Using Templates

### For Format Skills

Format skills **must**:

1. Include all 10 enrichments in their output
2. Follow the section structure defined in the template
3. Provide real content (no placeholder text)
4. Match the frontmatter metadata for their associated template

**Example workflow:**

```typescript
// 1. Retrieve template structure
import { TemplateRegistry } from "./scripts/template-registry.js";

const template = await TemplateRegistry.getTemplate("bug-findings");

// 2. Generate content following template structure
const taskOutput = generateBugFindingsTask(data);

// 3. Validate output matches template
const validation = await TemplateRegistry.validateTemplate("bug-findings");
if (!validation) {
  throw new Error("Template validation failed");
}
```

### Template Structure Contract

All format skill output must include:

```markdown
---
[frontmatter matching template]
---

# Task Title

**Location:** [actual file paths] **Estimated Effort:** [actual estimate] **Complexity:** [actual
complexity level]

## Acceptance Criteria

**Acceptance Criteria:**

- [actual criteria]

## Regression Risk Analysis

**Regression Risk Details:** **Impact:** [actual impact] **Blast Radius:** [actual blast radius]
**Dependencies:** [actual dependencies] **Testing Gaps:** [actual gaps] **Rollback Risk:** [actual
risk]

## Implementation Plan

**Implementation Steps:**

1. [actual steps]

## Code Examples

[actual code examples]

## File Changes

**Files to Create:** [actual files] **Files to Modify:** [actual files] **Files to Delete:** [actual
files]

## Testing Requirements

**Required Testing:** [actual testing requirements]

## Dependencies

**Blocking Dependencies:** [actual blocking items] **Blocks:** [actual items this blocks]
**Prerequisites:** [actual prerequisites]
```

---

## Template Discovery

### Listing All Templates

```typescript
import { TemplateRegistry } from "./scripts/template-registry.js";

const templates = await TemplateRegistry.listTemplates();

console.log(`Found ${templates.length} templates:`);
for (const template of templates) {
  console.log(`- ${template.templateName} (${template.formatSkill})`);
}
```

**Output:**

```json
[
  {
    "templateName": "bug-findings",
    "templateVersion": "1.0.0",
    "description": "Template for bug findings",
    "requiredEnrichments": 10,
    "formatSkill": "format-bug-findings",
    "path": "/absolute/path/to/bug-findings.template.md"
  },
  ...
]
```

### Retrieving a Template

```typescript
import { TemplateRegistry } from "./scripts/template-registry.js";

// Get full template content
const content = await TemplateRegistry.getTemplate("bug-findings");

// Get metadata only (faster)
const metadata = await TemplateRegistry.getTemplateMetadata("bug-findings");
```

### Validating a Template

```typescript
import { TemplateRegistry } from "./scripts/template-registry.js";

const isValid = await TemplateRegistry.validateTemplate("bug-findings");

if (isValid) {
  console.log("✓ Template has all 10 enrichments");
} else {
  console.log("✗ Template is missing enrichments");
}
```

### JSON Output Format

Templates are returned as JSON-compatible objects for external plugin consumption:

```json
{
  "description": "Template for bug findings from code reviews",
  "formatSkill": "format-bug-findings",
  "path": "/Users/username/project/.claude-plugins/task-streams/templates/bug-findings.template.md",
  "requiredEnrichments": 10,
  "templateName": "bug-findings",
  "templateVersion": "1.0.0"
}
```

### External Plugin Examples

#### Python Example

```python
import subprocess
import json

# List all templates
result = subprocess.run(
    ['bun', 'scripts/list-templates.ts'],
    capture_output=True,
    text=True
)

templates = json.loads(result.stdout)

# Find bug findings template
bug_template = next(
    t for t in templates
    if t['templateName'] == 'bug-findings'
)

# Get template content
result = subprocess.run(
    ['bun', 'scripts/get-template.ts', 'bug-findings'],
    capture_output=True,
    text=True
)

template_content = result.stdout
```

#### Node.js Example

```javascript
import { TemplateRegistry } from "./scripts/template-registry.js";

// List all templates
const templates = await TemplateRegistry.listTemplates();

// Filter by format skill
const securityTemplates = templates.filter((t) => t.formatSkill === "format-security");

// Get template content
for (const template of securityTemplates) {
  const content = await TemplateRegistry.getTemplate(template.templateName);
  console.log(`Template: ${template.templateName}`);
  console.log(`Content length: ${content.length} characters`);
}
```

---

## Validation

### What the Validator Checks

The template enrichment validator (`template-enrichment-validator.ts`) verifies:

1. **All 10 enrichments present**: Every template must include all universal enrichments
2. **Required headings**: Checks for `## Acceptance Criteria`, `## Implementation Plan`, etc.
3. **Required fields**: Checks for `**Location:**`, `**Estimated Effort:**`, etc.
4. **Frontmatter completeness**: Ensures all metadata fields are present

### Running Validation CLI

```bash
# Validate all templates
bun scripts/validate-templates.ts

# Validate specific template
bun scripts/validate-templates.ts --template=bug-findings
```

### Exit Codes

- **0**: All templates valid (all 10 enrichments present)
- **1**: One or more templates invalid (missing enrichments)

### Example Validation Output

**✓ Valid Template:**

```
✓ bug-findings.template.md
  All 10 enrichments present
```

**✗ Invalid Template:**

```
✗ incomplete.template.md
  Missing enrichments:
  - Enrichment #5 (Regression Risk): Missing field "**Impact:**"
  - Enrichment #9 (Testing Table): Missing heading "## Testing Requirements"
```

### Detailed Validation

For detailed validation output with enrichment breakdown:

```typescript
import { validateTemplateHasAllEnrichments } from "./scripts/template-enrichment-validator.js";
import { TemplateRegistry } from "./scripts/template-registry.js";

const content = await TemplateRegistry.getTemplate("bug-findings");
const validation = validateTemplateHasAllEnrichments(content);

if (validation.passed) {
  console.log("✓ Template is valid");
} else {
  console.log("✗ Template has issues:");
  for (const issue of validation.missing) {
    console.log(`  - ${issue}`);
  }
}
```

---

## Adding New Templates

### Step-by-Step Guide

1. **Create template file**

   ```bash
   touch .claude-plugins/task-streams/templates/my-new-template.template.md
   ```

2. **Add frontmatter**

   ```yaml
   ---
   templateName: my-new-template
   templateVersion: 1.0.0
   description: Description of what this template is for
   requiredEnrichments: 10
   formatSkill: format-my-new-template
   ---
   ```

3. **Include all 10 enrichments**
   - Copy structure from `generic.template.md` as starting point
   - Ensure all required headings are present
   - Ensure all required fields are present
   - See "Template Structure" section above for complete list

4. **Validate template**

   ```bash
   bun scripts/validate-templates.ts --template=my-new-template
   ```

5. **Run tests**

   ```bash
   pnpm vitest run .claude-plugins/task-streams/tests/templates/
   ```

6. **Commit**
   ```bash
   git add .claude-plugins/task-streams/templates/my-new-template.template.md
   git commit -m "feat: add my-new-template template"
   ```

### Required Enrichments Checklist

When creating a new template, verify it includes:

- [ ] **Enrichment 1**: `**Location:**`
- [ ] **Enrichment 2**: `**Estimated Effort:**`
- [ ] **Enrichment 3**: `**Complexity:**`
- [ ] **Enrichment 4**: `## Acceptance Criteria` + `**Acceptance Criteria:**`
- [ ] **Enrichment 5**: `## Regression Risk Analysis` + 5 fields (Impact, Blast Radius,
      Dependencies, Testing Gaps, Rollback Risk)
- [ ] **Enrichment 6**: `## Implementation Plan` + `**Implementation Steps:**`
- [ ] **Enrichment 7**: `## Code Examples`
- [ ] **Enrichment 8**: `## File Changes` + 3 fields (Create, Modify, Delete)
- [ ] **Enrichment 9**: `## Testing Requirements` + `**Required Testing:**`
- [ ] **Enrichment 10**: `## Dependencies` + 3 fields (Blocking Dependencies, Blocks, Prerequisites)

### Pre-Commit Hook

The template system includes a pre-commit hook that prevents committing invalid templates:

```bash
# .git/hooks/pre-commit
#!/bin/sh
bun scripts/validate-templates.ts
exit $?
```

If validation fails, the commit will be rejected with error details.

---

## FAQ

### Can templates have format-specific sections?

**Yes**, but all 10 universal enrichments are still required.

Templates can include additional sections beyond the 10 enrichments:

```markdown
## Universal Enrichments

[All 10 enrichments here]

## Bug-Specific Sections

**Reproduction Steps:** **Error Messages:** **Stack Traces:**
```

The validator only checks for the presence of the 10 universal enrichments. Additional sections are
allowed and encouraged for format-specific needs.

### Can we skip an enrichment if it's not relevant?

**No**. All 10 enrichments are required for every template and every task.

If an enrichment isn't relevant, include it with a note:

```markdown
## Regression Risk Analysis

**Impact:** None (documentation-only change) **Blast Radius:** Isolated to documentation
**Dependencies:** None **Testing Gaps:** None (no code changes) **Rollback Risk:** None (reversible)
```

This ensures:

1. Every task has the same structure
2. Future readers can see what was considered
3. The contract is never broken

### How are templates versioned?

Templates use **semantic versioning** in the frontmatter:

```yaml
templateVersion: 1.0.0 # MAJOR.MINOR.PATCH
```

**Version bumps:**

- **MAJOR**: Breaking changes to structure (adding/removing required sections)
- **MINOR**: Non-breaking additions (new optional sections, clarifications)
- **PATCH**: Bug fixes, typos, formatting improvements

**Version history:** Track version changes in git commit messages:

```bash
git log --oneline -- templates/bug-findings.template.md
```

### Can external plugins modify templates?

**No**. Templates are **read-only contracts**.

External plugins should:

1. Discover templates via `listTemplates()`
2. Read template structure via `getTemplate()`
3. Generate content that **follows** the template
4. Never modify the template files themselves

Templates are controlled by the template system maintainers to ensure consistency across all format
skills.

### What happens if I add a template without all 10 enrichments?

**The template will fail validation** and:

1. Pre-commit hook will reject the commit
2. `validate-templates.ts` will exit with code 1
3. Tests will fail
4. CI/CD pipeline will block the change

**Example output:**

```
✗ incomplete.template.md
  Missing enrichments:
  - Enrichment #5 (Regression Risk): Missing field "**Impact:**"
  - Enrichment #9 (Testing Table): Missing heading "## Testing Requirements"

Validation failed: 1 template(s) invalid
```

Fix the issues by adding the missing enrichments, then commit again.

### How do I know which template to use for my task?

**Match by purpose:**

| Task Type                                       | Template       | Format Skill          |
| ----------------------------------------------- | -------------- | --------------------- |
| Bug reports, code review findings               | `bug-findings` | `format-bug-findings` |
| Security vulnerabilities, security improvements | `security`     | `format-security`     |
| Feature specs, design documents                 | `spec`         | `format-spec`         |
| Technical debt, refactoring                     | `tech-debt`    | `format-tech-debt`    |
| General tasks, miscellaneous work               | `generic`      | `format-generic`      |

**When in doubt**, use `generic` template - it's the catch-all for tasks that don't fit other
categories.

### Can I create a template for internal use only?

**Yes**. Add templates to any directory and use the `templatesDir` parameter:

```typescript
const templates = await TemplateRegistry.listTemplates("/path/to/my/templates");
```

However, templates in the official `.claude-plugins/task-streams/templates/` directory:

- Must pass validation
- Must have all 10 enrichments
- Are version-controlled
- Are discoverable by all plugins

Internal templates can have looser requirements but won't benefit from:

- Automated validation
- Integration tests
- Official documentation
- Plugin ecosystem support

---

## Additional Resources

- **Template Enrichment Mapping**: `TEMPLATE-ENRICHMENT-MAPPING.md` - Detailed mapping of
  enrichments to template sections
- **Shared Enrichments**: `../SHARED_ENRICHMENTS.md` - Source of truth for the 10 universal
  enrichments
- **Scripts Documentation**: `../scripts/README.md` - Documentation for all template system scripts
- **Integration Tests**: `../tests/templates/integration.test.ts` - Complete integration test suite

---

## Contributing

When contributing new templates or improvements:

1. **Follow TDD**: Write tests first, then implement
2. **Run validation**: Use `bun scripts/validate-templates.ts`
3. **Run tests**: Use `pnpm vitest run .claude-plugins/task-streams/tests/`
4. **Update docs**: Add new templates to this README's "Available Templates" section
5. **Version bump**: Increment `templateVersion` for changes to existing templates

---

## Support

For questions or issues with the template system:

1. Check this README first
2. Review test files in `tests/templates/`
3. Check script documentation in `scripts/README.md`
4. Review the spec: `SPEC-TEMPLATE-SYSTEM.md`
