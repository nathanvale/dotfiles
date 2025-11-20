# Template System Scripts Documentation

## Overview

This directory contains scripts for managing, validating, and discovering templates in the Template
System. All scripts are written in TypeScript and run via Bun.

---

## Scripts Index

| Script                             | Purpose                                        | Usage                        |
| ---------------------------------- | ---------------------------------------------- | ---------------------------- |
| `template-enrichment-validator.ts` | Core validation logic for template enrichments | Imported by other scripts    |
| `validate-templates.ts`            | CLI tool for validating templates              | `bun validate-templates.ts`  |
| `template-registry.ts`             | Template discovery API                         | Imported by other scripts    |
| `list-templates.ts`                | CLI tool for listing templates                 | `bun list-templates.ts`      |
| `get-template.ts`                  | CLI tool for retrieving template content       | `bun get-template.ts <name>` |

---

## template-enrichment-validator.ts

### Purpose

Provides core validation logic for verifying that templates contain all 10 universal enrichments.

### Exports

```typescript
// Enrichment definition
interface EnrichmentDefinition {
  id: number;
  name: string;
  requiredFields: string[];
  requiredHeadings: string[];
}

// Array of 10 required enrichments
const REQUIRED_ENRICHMENTS: readonly EnrichmentDefinition[];

// Validation result
interface ValidationResult {
  passed: boolean;
  missing: string[];
}

// Validation function
function validateTemplateHasAllEnrichments(templateContent: string): ValidationResult;
```

### Usage

**Import and use in code:**

```typescript
import {
  validateTemplateHasAllEnrichments,
  REQUIRED_ENRICHMENTS,
} from "./template-enrichment-validator.js";

const templateContent = await readFile("template.md", "utf-8");
const result = validateTemplateHasAllEnrichments(templateContent);

if (result.passed) {
  console.log("✓ Template is valid");
} else {
  console.log("✗ Template has issues:");
  for (const issue of result.missing) {
    console.log(`  - ${issue}`);
  }
}
```

### Validation Rules

Checks for all 10 enrichments:

1. **File Locations**: `**Location:**`
2. **Effort Estimation**: `**Estimated Effort:**`
3. **Complexity**: `**Complexity:**`
4. **Acceptance Criteria**: `## Acceptance Criteria` + `**Acceptance Criteria:**`
5. **Regression Risk (5D)**: `## Regression Risk Analysis` + 5 fields
   - `**Regression Risk Details:**`
   - `**Impact:**`
   - `**Blast Radius:**`
   - `**Dependencies:**`
   - `**Testing Gaps:**`
   - `**Rollback Risk:**`
6. **Implementation Steps**: `## Implementation Plan` + `**Implementation Steps:**`
7. **Code Examples**: `## Code Examples`
8. **File Changes (3C)**: `## File Changes` + 3 fields
   - `**Files to Create:**`
   - `**Files to Modify:**`
   - `**Files to Delete:**`
9. **Testing Table**: `## Testing Requirements` + `**Required Testing:**`
10. **Dependencies**: `## Dependencies` + 3 fields
    - `**Blocking Dependencies:**`
    - `**Blocks:**`
    - `**Prerequisites:**`

### Output Format

```typescript
{
  passed: true,      // true if all enrichments present
  missing: []        // empty if valid, else list of missing enrichments
}

// Example invalid result:
{
  passed: false,
  missing: [
    'Enrichment #5 (Regression Risk): Missing field "**Impact:**"',
    'Enrichment #9 (Testing Table): Missing heading "## Testing Requirements"'
  ]
}
```

---

## validate-templates.ts

### Purpose

CLI tool for validating all templates in the templates directory. Exits with code 0 if all valid,
code 1 if any invalid.

### Usage

```bash
# Validate all templates in default directory
bun scripts/validate-templates.ts

# Validate all templates in custom directory
bun scripts/validate-templates.ts --dir=/path/to/templates

# Validate single template by name
bun scripts/validate-templates.ts --template=bug-findings

# Validate with verbose output
bun scripts/validate-templates.ts --verbose
```

### Command-Line Arguments

| Argument            | Description                     | Default                                  |
| ------------------- | ------------------------------- | ---------------------------------------- |
| `--dir=<path>`      | Template directory path         | `.claude-plugins/task-streams/templates` |
| `--template=<name>` | Validate single template        | All templates                            |
| `--verbose`         | Show detailed validation output | `false`                                  |
| `--json`            | Output JSON format              | `false`                                  |

### Output Format

**Standard output (human-readable):**

```
Validating templates in: .claude-plugins/task-streams/templates/

✓ bug-findings.template.md
  All 10 enrichments present

✓ generic.template.md
  All 10 enrichments present

✗ incomplete.template.md
  Missing enrichments:
  - Enrichment #5 (Regression Risk): Missing field "**Impact:**"
  - Enrichment #9 (Testing Table): Missing heading "## Testing Requirements"

Results:
  Valid: 2
  Invalid: 1

Validation failed: 1 template(s) invalid
```

**JSON output (`--json`):**

```json
{
  "invalid": [
    {
      "missing": [
        "Enrichment #5 (Regression Risk): Missing field \"**Impact:**\"",
        "Enrichment #9 (Testing Table): Missing heading \"## Testing Requirements\""
      ],
      "passed": false,
      "template": "incomplete.template.md"
    }
  ],
  "summary": {
    "invalid": 1,
    "total": 3,
    "valid": 2
  },
  "valid": [
    {
      "missing": [],
      "passed": true,
      "template": "bug-findings.template.md"
    },
    {
      "missing": [],
      "passed": true,
      "template": "generic.template.md"
    }
  ]
}
```

### Exit Codes

- **0**: All templates valid
- **1**: One or more templates invalid or error occurred

### Examples

**Validate all templates:**

```bash
bun scripts/validate-templates.ts
```

**Validate specific template:**

```bash
bun scripts/validate-templates.ts --template=bug-findings
```

**Integrate with CI/CD:**

```yaml
# .github/workflows/validate.yml
- name: Validate Templates
  run: bun scripts/validate-templates.ts
```

**Pre-commit hook:**

```bash
#!/bin/sh
# .git/hooks/pre-commit
bun scripts/validate-templates.ts
exit $?
```

---

## template-registry.ts

### Purpose

Template discovery API for managing and querying task templates. Provides programmatic access to
template metadata, content, and validation.

### Exports

```typescript
// Template metadata interface
interface TemplateMetadata {
  templateName: string;
  templateVersion: string;
  description: string;
  requiredEnrichments: number;
  formatSkill: string;
  path: string;
}

// Template registry class
class TemplateRegistry {
  static async listTemplates(templatesDir?: string): Promise<TemplateMetadata[]>;
  static async getTemplate(name: string, templatesDir?: string): Promise<string>;
  static async getTemplateMetadata(name: string, templatesDir?: string): Promise<TemplateMetadata>;
  static async validateTemplate(name: string, templatesDir?: string): Promise<boolean>;
}
```

### Usage

**Import and use in code:**

```typescript
import { TemplateRegistry } from "./template-registry.js";

// List all templates
const templates = await TemplateRegistry.listTemplates();
console.log(`Found ${templates.length} templates`);

// Get template content
const content = await TemplateRegistry.getTemplate("bug-findings");
console.log(content);

// Get metadata only (faster)
const metadata = await TemplateRegistry.getTemplateMetadata("bug-findings");
console.log(metadata.description);

// Validate template
const isValid = await TemplateRegistry.validateTemplate("bug-findings");
console.log(isValid ? "✓ Valid" : "✗ Invalid");
```

### API Methods

#### listTemplates(templatesDir?)

Returns array of all template metadata, sorted by templateName.

```typescript
const templates = await TemplateRegistry.listTemplates()

// Output:
[
  {
    templateName: 'bug-findings',
    templateVersion: '1.0.0',
    description: 'Template for bug findings',
    requiredEnrichments: 10,
    formatSkill: 'format-bug-findings',
    path: '/absolute/path/to/bug-findings.template.md'
  },
  ...
]
```

#### getTemplate(name, templatesDir?)

Returns full template content as string.

```typescript
const content = await TemplateRegistry.getTemplate("bug-findings");

// Output:
// ---
// templateName: bug-findings
// templateVersion: 1.0.0
// ...
// ---
//
// # Bug Findings Template
// ...
```

**Throws:** Error if template not found

#### getTemplateMetadata(name, templatesDir?)

Returns template metadata only (faster than getTemplate).

```typescript
const metadata = await TemplateRegistry.getTemplateMetadata('bug-findings')

// Output:
{
  templateName: 'bug-findings',
  templateVersion: '1.0.0',
  description: 'Template for bug findings',
  requiredEnrichments: 10,
  formatSkill: 'format-bug-findings',
  path: '/absolute/path/to/bug-findings.template.md'
}
```

**Throws:** Error if template not found

#### validateTemplate(name, templatesDir?)

Returns true if template has all 10 enrichments, false otherwise.

```typescript
const isValid = await TemplateRegistry.validateTemplate("bug-findings");

if (isValid) {
  console.log("✓ Template is valid");
} else {
  console.log("✗ Template is invalid");
}
```

**Throws:** Error if template not found

### Custom Directory

All methods accept optional `templatesDir` parameter:

```typescript
const customTemplates = await TemplateRegistry.listTemplates("/path/to/templates");
```

---

## list-templates.ts

### Purpose

CLI tool for listing all templates in the templates directory. Outputs JSON to stdout for easy
consumption by external tools.

### Usage

```bash
# List all templates in default directory
bun scripts/list-templates.ts

# List templates in custom directory
bun scripts/list-templates.ts --dir=/path/to/templates

# Pretty-print JSON output
bun scripts/list-templates.ts | jq .

# Filter by formatSkill using jq
bun scripts/list-templates.ts | jq '.[] | select(.formatSkill == "format-bug-findings")'
```

### Command-Line Arguments

| Argument       | Description              | Default                                  |
| -------------- | ------------------------ | ---------------------------------------- |
| `--dir=<path>` | Template directory path  | `.claude-plugins/task-streams/templates` |
| `--pretty`     | Pretty-print JSON output | `false`                                  |

### Output Format

**Default (compact JSON):**

```json
[
  {
    "description": "Template for bug findings",
    "formatSkill": "format-bug-findings",
    "path": "/absolute/path/bug-findings.template.md",
    "requiredEnrichments": 10,
    "templateName": "bug-findings",
    "templateVersion": "1.0.0"
  },
  {
    "description": "Generic template",
    "formatSkill": "format-generic",
    "path": "/absolute/path/generic.template.md",
    "requiredEnrichments": 10,
    "templateName": "generic",
    "templateVersion": "1.0.0"
  }
]
```

**Pretty-printed (`--pretty` or pipe to `jq`):**

```json
[
  {
    "description": "Template for bug findings from code reviews",
    "formatSkill": "format-bug-findings",
    "path": "/Users/username/project/.claude-plugins/task-streams/templates/bug-findings.template.md",
    "requiredEnrichments": 10,
    "templateName": "bug-findings",
    "templateVersion": "1.0.0"
  },
  {
    "description": "Generic template for general tasks",
    "formatSkill": "format-generic",
    "path": "/Users/username/project/.claude-plugins/task-streams/templates/generic.template.md",
    "requiredEnrichments": 10,
    "templateName": "generic",
    "templateVersion": "1.0.0"
  }
]
```

### Examples

**List all templates:**

```bash
bun scripts/list-templates.ts
```

**Find templates by format skill:**

```bash
bun scripts/list-templates.ts | jq '.[] | select(.formatSkill == "format-security")'
```

**Count templates:**

```bash
bun scripts/list-templates.ts | jq 'length'
```

**Get all template names:**

```bash
bun scripts/list-templates.ts | jq '.[].templateName'
```

**External plugin integration (Python):**

```python
import subprocess
import json

result = subprocess.run(
    ['bun', 'scripts/list-templates.ts'],
    capture_output=True,
    text=True
)

templates = json.loads(result.stdout)
for template in templates:
    print(f"Template: {template['templateName']}")
```

**External plugin integration (Node.js):**

```javascript
import { exec } from "child_process";
import { promisify } from "util";

const execAsync = promisify(exec);

const { stdout } = await execAsync("bun scripts/list-templates.ts");
const templates = JSON.parse(stdout);

for (const template of templates) {
  console.log(`Template: ${template.templateName}`);
}
```

---

## get-template.ts

### Purpose

CLI tool for retrieving full template content by name. Outputs template content to stdout.

### Usage

```bash
# Get template content
bun scripts/get-template.ts bug-findings

# Get template from custom directory
bun scripts/get-template.ts bug-findings --dir=/path/to/templates

# Save to file
bun scripts/get-template.ts bug-findings > my-template.md

# View in pager
bun scripts/get-template.ts bug-findings | less
```

### Command-Line Arguments

| Argument       | Description                          | Required |
| -------------- | ------------------------------------ | -------- |
| `<name>`       | Template name (without .template.md) | Yes      |
| `--dir=<path>` | Template directory path              | No       |

### Output Format

Outputs full template content to stdout:

```markdown
---
templateName: bug-findings
templateVersion: 1.0.0
description: Template for bug findings from code reviews
requiredEnrichments: 10
formatSkill: format-bug-findings
---

# Bug Findings Template

**Location:** **Estimated Effort:** **Complexity:**

## Acceptance Criteria

**Acceptance Criteria:**

## Regression Risk Analysis

**Regression Risk Details:** **Impact:** **Blast Radius:** **Dependencies:** **Testing Gaps:**
**Rollback Risk:**

...
```

### Error Handling

**Template not found:**

```bash
$ bun scripts/get-template.ts non-existent
Error: Template "non-existent" not found at path: /path/to/non-existent.template.md
Make sure the file non-existent.template.md exists in the templates directory.
```

Exit code: 1

### Examples

**Get template content:**

```bash
bun scripts/get-template.ts bug-findings
```

**Save template to file:**

```bash
bun scripts/get-template.ts spec > my-spec.md
```

**Count lines in template:**

```bash
bun scripts/get-template.ts generic | wc -l
```

**External plugin integration (Python):**

```python
import subprocess

result = subprocess.run(
    ['bun', 'scripts/get-template.ts', 'bug-findings'],
    capture_output=True,
    text=True
)

template_content = result.stdout
print(f"Template length: {len(template_content)} chars")
```

**External plugin integration (Bash):**

```bash
#!/bin/bash
TEMPLATE=$(bun scripts/get-template.ts security)
echo "$TEMPLATE" | grep "## Acceptance Criteria"
```

---

## Development Workflows

### Adding a New Script

1. **Create script file:**

   ```bash
   touch scripts/my-new-script.ts
   ```

2. **Add shebang and imports:**

   ```typescript
   #!/usr/bin/env bun

   import { TemplateRegistry } from "./template-registry.js";
   ```

3. **Implement functionality:**

   ```typescript
   async function main() {
     // Your code here
   }

   main().catch(console.error);
   ```

4. **Make executable:**

   ```bash
   chmod +x scripts/my-new-script.ts
   ```

5. **Add to this README:** Update the scripts index table and add full documentation

### Testing Scripts

All scripts should have corresponding tests in `../tests/`:

```typescript
// tests/scripts/my-script.test.ts
import { describe, it, expect } from "vitest";

describe("my-new-script", () => {
  it("should do something", async () => {
    // Test your script
  });
});
```

Run tests:

```bash
pnpm vitest run .claude-plugins/task-streams/tests/
```

### Script Best Practices

1. **Exit codes**: Return 0 for success, 1 for failure
2. **Error handling**: Catch errors and log helpful messages
3. **Arguments**: Support `--help` flag
4. **Output**: JSON to stdout, logs to stderr
5. **Documentation**: Keep this README updated

---

## Integration Examples

### CI/CD Pipeline

```yaml
# .github/workflows/template-validation.yml
name: Validate Templates

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Setup Bun
        uses: oven-sh/setup-bun@v1

      - name: Validate Templates
        run: bun scripts/validate-templates.ts

      - name: List Templates
        run: bun scripts/list-templates.ts --pretty
```

### Pre-commit Hook

```bash
#!/bin/sh
# .git/hooks/pre-commit

# Validate templates before allowing commit
bun scripts/validate-templates.ts

# Exit with validation result
exit $?
```

### External Tool Integration

**Python script using templates:**

```python
#!/usr/bin/env python3

import subprocess
import json

def get_all_templates():
    """Get all available templates"""
    result = subprocess.run(
        ['bun', 'scripts/list-templates.ts'],
        capture_output=True,
        text=True,
        check=True
    )
    return json.loads(result.stdout)

def get_template_content(name):
    """Get template content by name"""
    result = subprocess.run(
        ['bun', 'scripts/get-template.ts', name],
        capture_output=True,
        text=True,
        check=True
    )
    return result.stdout

def validate_template(name):
    """Validate template has all enrichments"""
    result = subprocess.run(
        ['bun', 'scripts/validate-templates.ts', f'--template={name}'],
        capture_output=True
    )
    return result.returncode == 0

# Example usage
templates = get_all_templates()
print(f"Found {len(templates)} templates")

for template in templates:
    name = template['templateName']
    is_valid = validate_template(name)
    print(f"{name}: {'✓ Valid' if is_valid else '✗ Invalid'}")
```

---

## Troubleshooting

### Script won't run

**Error:** `command not found: bun`

**Solution:** Install Bun: `curl -fsSL https://bun.sh/install | bash`

### Permission denied

**Error:** `Permission denied: ./my-script.ts`

**Solution:** Make script executable: `chmod +x scripts/my-script.ts`

### Template not found

**Error:** `Template "xyz" not found`

**Solution:**

1. Check template exists: `ls .claude-plugins/task-streams/templates/`
2. Use correct name (without `.template.md` extension)
3. Check you're in correct directory

### Validation always fails

**Error:** All templates show as invalid

**Solution:**

1. Check enrichment validator is up to date
2. Run with `--verbose` to see specific issues
3. Compare template with `generic.template.md`

---

## Additional Resources

- **Template Documentation**: `../templates/README.md`
- **Template Spec**: `../SPEC-TEMPLATE-SYSTEM.md`
- **Test Files**: `../tests/templates/`
- **Integration Tests**: `../tests/templates/integration.test.ts`
