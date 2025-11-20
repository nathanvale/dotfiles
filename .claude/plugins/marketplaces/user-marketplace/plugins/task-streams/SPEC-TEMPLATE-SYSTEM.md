# Template System - Technical Specification

**Version**: 1.0.0
**Status**: Approved
**Last Updated**: 2025-01-06

---

## Executive Summary

This specification defines a template system for the task-streams plugin that provides structure-only output templates for each document format type. Templates define the output contract that enriched tasks must conform to, enable external plugin discovery, and ensure all 10 universal enrichments are included.

**Key Principle**: Templates show ONLY structure (headings, sections, field names) with NO placeholder content. The format skills are responsible for generating actual content.

**🔴 CRITICAL**: See `templates/TEMPLATE-ENRICHMENT-MAPPING.md` for the EXACT mapping of how templates include all 10 enrichments from `SHARED_ENRICHMENTS.md`. This mapping document shows:

- Each of the 10 enrichments
- What field/heading in the template it corresponds to
- How the validator checks for it
- Complete example template with all enrichments annotated

---

## 1. Template File Structure

### 1.1 Directory Organization

```
.claude-plugins/task-streams/templates/
├── bug-findings.template.md
├── spec.template.md
├── tech-debt.template.md
├── security.template.md
├── generic.template.md
└── README.md
```

### 1.2 How Templates Include All 10 Enrichments

**See `templates/TEMPLATE-ENRICHMENT-MAPPING.md` for complete mapping.**

Quick reference - each template MUST include:

1. **File Locations** → `**Location:**` field
2. **Effort Estimation** → `**Estimated Effort:**` field
3. **Complexity** → `**Complexity:**` field
4. **Acceptance Criteria** → `## Acceptance Criteria` heading + `**Acceptance Criteria:**` field + checkboxes
5. **Regression Risk (5 dimensions)** → `## Regression Risk Analysis` heading + 5 sub-fields (Impact, Blast Radius, Dependencies, Testing Gaps, Rollback Risk)
6. **Implementation Steps** → `## Implementation Plan` heading + `**Implementation Steps:**` field + numbered list
7. **Code Examples** → `## Code Examples` heading + code blocks
8. **File Changes (3 categories)** → `## File Changes` heading + 3 sub-fields (Files to Create, Files to Modify, Files to Delete)
9. **Testing Table** → `## Testing Requirements` heading + table structure
10. **Dependencies** → `## Dependencies` heading + 3 sub-fields (Blocking Dependencies, Blocks, Prerequisites)

**Total validator checks**: ~25-30 individual fields/headings across the 10 enrichments.

### 1.3 Template File Format

Each template file contains:

1. **Template Metadata Frontmatter** (YAML)
2. **Task Output Frontmatter Structure** (YAML comments showing structure)
3. **Output Structure** (Markdown headings and sections with all 10 enrichments)

**Example: bug-findings.template.md**

````markdown
---
templateName: bug-findings
templateVersion: 1.0.0
description: Structure for enriched bug findings and code review issues
requiredEnrichments: 10
formatSkill: format-bug-findings
---

## <!-- TASK OUTPUT FRONTMATTER STRUCTURE -->

id: # T#### format (auto-generated)
title: # Brief task description
priority: # P0, P1, P2, or P3
component: # C## code from component-manager
status: # READY, IN_PROGRESS, BLOCKED, DONE
created: # ISO 8601 timestamp
source: # Original document path

---

# [Priority]: [Title]

## Core Metadata

**Component:**
**Location:**
**Estimated Effort:**
**Complexity:**
**Regression Risk:**

## Description

**Description:**

## Regression Risk Analysis

**Regression Risk Details:**

- **Impact:**
- **Blast Radius:**
- **Dependencies:**
- **Testing Gaps:**
- **Rollback Risk:**

## Acceptance Criteria

**Acceptance Criteria:**

- [ ]
- [ ]
- [ ]

## Implementation Plan

**Implementation Steps:**

1.
2.
3.

## Code Examples

**Current Code (BUGGY):**

```typescript

```
````

**Proposed Fix:**

```typescript

```

## File Changes

## **Files to Create:**

## **Files to Modify:**

## **Files to Delete:**

## Testing Requirements

**Required Testing:**
| Test Type | Validates AC | Description | Location |
|-----------|--------------|-------------|----------|
| | | | |

## Dependencies

**Blocking Dependencies:**

**Blocks:**

**Prerequisites:**

- [ ]

````

---

## 2. Template Content Guidelines

### 2.1 Structure-Only Principle

Templates MUST show only:
- ✅ Heading hierarchy (`#`, `##`, `###`)
- ✅ Section markers
- ✅ Field labels (`**Component:**`, `**Location:**`)
- ✅ List structures (`- [ ]`, `1.`, `-`)
- ✅ Table structures with column headers
- ✅ Code block markers with language tags

Templates MUST NOT include:
- ❌ Placeholder content (`[Title]`, `TODO`, `[file.ts]`)
- ❌ Example data (`"Fix the bug"`, `"8h"`, `"P0"`)
- ❌ Instructions to plugin owners (`"Fill this in"`)
- ❌ Explanatory comments in output sections

### 2.2 Correct vs Incorrect Examples

**❌ INCORRECT - Has placeholder content:**
```markdown
**Component:** [C## code from component-manager]
**Location:** [file.ts:start-end]
**Estimated Effort:** [X]h
````

**✅ CORRECT - Pure structure:**

```markdown
**Component:**
**Location:**
**Estimated Effort:**
```

**❌ INCORRECT - Has example data:**

```markdown
**Acceptance Criteria:**

- [ ] Fix the bug
- [ ] Add tests
- [ ] Update documentation
```

**✅ CORRECT - Empty structure:**

```markdown
**Acceptance Criteria:**

- [ ]
- [ ]
- [ ]
```

### 2.3 Frontmatter Structure

Templates include TWO frontmatter blocks:

**1. Template Metadata** (actual YAML):

```yaml
---
templateName: bug-findings
templateVersion: 1.0.0
description: Structure for enriched bug findings and code review issues
requiredEnrichments: 10
formatSkill: format-bug-findings
---
```

**2. Task Output Structure** (YAML comment showing expected structure):

```markdown
## <!-- TASK OUTPUT FRONTMATTER STRUCTURE -->

id: # T#### format (auto-generated)
title: # Brief task description
priority: # P0, P1, P2, or P3
component: # C## code from component-manager
status: # READY, IN_PROGRESS, BLOCKED, DONE
created: # ISO 8601 timestamp
source: # Original document path

---
```

This shows the contract without being actual output.

---

## 3. Template Discovery API

### 3.1 Programmatic Access

```typescript
// .claude-plugins/task-streams/scripts/template-registry.ts

export interface TemplateMetadata {
  templateName: string
  templateVersion: string
  description: string
  requiredEnrichments: number
  formatSkill: string
  path: string
}

export class TemplateRegistry {
  /**
   * List all available templates
   */
  static async listTemplates(): Promise<TemplateMetadata[]> {
    const templatesDir = join(__dirname, "../templates")
    const files = await readdir(templatesDir)
    const templateFiles = files.filter((f) => f.endsWith(".template.md"))

    const templates: TemplateMetadata[] = []
    for (const file of templateFiles) {
      const content = await readFile(join(templatesDir, file), "utf-8")
      const metadata = extractFrontmatter(content)
      templates.push({
        ...metadata,
        path: join(templatesDir, file),
      })
    }

    return templates
  }

  /**
   * Get template content by name
   */
  static async getTemplate(name: string): Promise<string> {
    const templatePath = join(__dirname, "../templates", `${name}.template.md`)
    return readFile(templatePath, "utf-8")
  }

  /**
   * Get template metadata only
   */
  static async getTemplateMetadata(name: string): Promise<TemplateMetadata> {
    const content = await this.getTemplate(name)
    const metadata = extractFrontmatter(content)
    return {
      ...metadata,
      path: join(__dirname, "../templates", `${name}.template.md`),
    }
  }

  /**
   * Validate template structure
   */
  static async validateTemplate(name: string): Promise<boolean> {
    const content = await this.getTemplate(name)
    const validation = validateTemplateHasAllEnrichments(content)
    return validation.passed
  }
}
```

### 3.2 CLI Commands

```bash
# List all available templates
pnpm tsx .claude-plugins/task-streams/scripts/list-templates.ts

# Output (JSON):
[
  {
    "templateName": "bug-findings",
    "templateVersion": "1.0.0",
    "description": "Structure for enriched bug findings and code review issues",
    "requiredEnrichments": 10,
    "formatSkill": "format-bug-findings",
    "path": ".claude-plugins/task-streams/templates/bug-findings.template.md"
  },
  ...
]

# Get template content
pnpm tsx .claude-plugins/task-streams/scripts/get-template.ts bug-findings

# Get template metadata only
pnpm tsx .claude-plugins/task-streams/scripts/get-template.ts spec --metadata-only

# Validate template
pnpm tsx .claude-plugins/task-streams/scripts/validate-templates.ts
```

### 3.3 CLI Implementation

```typescript
// .claude-plugins/task-streams/scripts/list-templates.ts
#!/usr/bin/env tsx

import { TemplateRegistry } from './template-registry'

async function main() {
  const templates = await TemplateRegistry.listTemplates()
  console.log(JSON.stringify(templates, null, 2))
}

main().catch(console.error)
```

```typescript
// .claude-plugins/task-streams/scripts/get-template.ts
#!/usr/bin/env tsx

import { TemplateRegistry } from './template-registry'

async function main() {
  const [templateName, flag] = process.argv.slice(2)

  if (!templateName) {
    console.error('Usage: get-template.ts <template-name> [--metadata-only]')
    process.exit(1)
  }

  if (flag === '--metadata-only') {
    const metadata = await TemplateRegistry.getTemplateMetadata(templateName)
    console.log(JSON.stringify(metadata, null, 2))
  } else {
    const content = await TemplateRegistry.getTemplate(templateName)
    console.log(content)
  }
}

main().catch(console.error)
```

---

## 4. Integration with Format Skills

### 4.1 Skill Reference to Template

Each format skill's SKILL.md should reference its template:

```markdown
# format-bug-findings Skill

**Output Template**: @../templates/bug-findings.template.md

Use this template as the structural contract for all enriched bug findings.
All sections and enrichments shown in the template MUST be included in output.
```

### 4.2 Skill Validation Against Template

Format skills should validate their output matches template structure:

```typescript
// Pseudo-code in skill implementation
const template = await TemplateRegistry.getTemplate("bug-findings")
const requiredSections = extractSections(template)

// Validate output has all sections
for (const section of requiredSections) {
  if (!output.includes(section)) {
    throw new Error(`Missing required section: ${section}`)
  }
}
```

---

## 5. Shared Enrichments Enforcement

### 5.1 The Problem

All templates must include the 10 universal enrichments defined in `SHARED_ENRICHMENTS.md`. Without enforcement, templates can drift from this contract.

### 5.2 REQUIRED_ENRICHMENTS Array

```typescript
// .claude-plugins/task-streams/scripts/template-enrichment-validator.ts

export const REQUIRED_ENRICHMENTS = [
  {
    id: 1,
    name: "Component Classification",
    requiredFields: ["**Component:**"],
    requiredHeadings: [],
  },
  {
    id: 2,
    name: "File Locations",
    requiredFields: ["**Location:**"],
    requiredHeadings: [],
  },
  {
    id: 3,
    name: "Effort Estimation",
    requiredFields: ["**Estimated Effort:**"],
    requiredHeadings: [],
  },
  {
    id: 4,
    name: "Complexity Classification",
    requiredFields: ["**Complexity:**"],
    requiredHeadings: [],
  },
  {
    id: 5,
    name: "Regression Risk (5 Dimensions)",
    requiredFields: [
      "**Regression Risk:**",
      "**Impact:**",
      "**Blast Radius:**",
      "**Dependencies:**",
      "**Testing Gaps:**",
      "**Rollback Risk:**",
    ],
    requiredHeadings: ["## Regression Risk Analysis"],
  },
  {
    id: 6,
    name: "Acceptance Criteria",
    requiredFields: ["**Acceptance Criteria:**"],
    requiredHeadings: ["## Acceptance Criteria"],
  },
  {
    id: 7,
    name: "Implementation Steps",
    requiredFields: ["**Implementation Steps:**"],
    requiredHeadings: ["## Implementation Plan"],
  },
  {
    id: 8,
    name: "Code Examples",
    requiredFields: [],
    requiredHeadings: ["## Code Examples"],
  },
  {
    id: 9,
    name: "File Change Scope",
    requiredFields: [
      "**Files to Create:**",
      "**Files to Modify:**",
      "**Files to Delete:**",
    ],
    requiredHeadings: ["## File Changes"],
  },
  {
    id: 10,
    name: "Testing Table",
    requiredFields: ["**Required Testing:**"],
    requiredHeadings: ["## Testing Requirements"],
  },
] as const

export function validateTemplateHasAllEnrichments(templateContent: string): {
  passed: boolean
  missing: string[]
} {
  const missing: string[] = []

  for (const enrichment of REQUIRED_ENRICHMENTS) {
    // Check headings
    for (const heading of enrichment.requiredHeadings || []) {
      if (!templateContent.includes(heading)) {
        missing.push(`${enrichment.name}: Missing heading "${heading}"`)
      }
    }

    // Check fields
    for (const field of enrichment.requiredFields || []) {
      if (!templateContent.includes(field)) {
        missing.push(`${enrichment.name}: Missing field "${field}"`)
      }
    }
  }

  return {
    passed: missing.length === 0,
    missing,
  }
}
```

### 5.3 Validation CLI

```typescript
// .claude-plugins/task-streams/scripts/validate-templates.ts
#!/usr/bin/env tsx

import { readdir, readFile } from 'fs/promises'
import { join } from 'path'
import { validateTemplateHasAllEnrichments } from './template-enrichment-validator'

async function main() {
  const templatesDir = join(__dirname, '../templates')
  const templateFiles = (await readdir(templatesDir))
    .filter(f => f.endsWith('.template.md'))

  console.log('=== Template Validation ===\n')

  let allPassed = true

  for (const file of templateFiles) {
    const content = await readFile(join(templatesDir, file), 'utf-8')
    const validation = validateTemplateHasAllEnrichments(content)

    if (validation.passed) {
      console.log(`✅ ${file} - All 10 enrichments present`)
    } else {
      console.log(`❌ ${file} - Missing enrichments:`)
      validation.missing.forEach(m => console.log(`   - ${m}`))
      allPassed = false
    }
  }

  console.log()
  process.exit(allPassed ? 0 : 1)
}

main().catch(console.error)
```

Usage:

```bash
# Validate all templates
pnpm tsx .claude-plugins/task-streams/scripts/validate-templates.ts

# Output:
=== Template Validation ===

✅ bug-findings.template.md - All 10 enrichments present
✅ spec.template.md - All 10 enrichments present
❌ tech-debt.template.md - Missing enrichments:
   - Regression Risk (5 Dimensions): Missing field "**Blast Radius:**"
   - File Change Scope: Missing heading "## File Changes"

Exit code: 1
```

---

## 6. Testing Strategy

### 6.1 Three Test Suites

**1. Template Structure Tests** (`tests/templates/structure.test.ts`)

- Each template has all 10 enrichments
- Each template validates against REQUIRED_ENRICHMENTS array
- Frontmatter metadata is valid
- File naming convention followed

**2. Template Discovery Tests** (`tests/templates/discovery.test.ts`)

- listTemplates() returns all templates
- getTemplate() retrieves correct content
- getTemplateMetadata() returns valid metadata
- validateTemplate() detects invalid templates

**3. Template-Validator Alignment Tests** (`tests/templates/alignment.test.ts`)

- Each validator checks what its template defines
- No validator checks missing from template
- No template section missing from validator

### 6.2 Test Implementation

```typescript
// tests/templates/structure.test.ts

import { describe, it, expect } from "vitest"
import { readFile, readdir } from "fs/promises"
import { join } from "path"
import {
  validateTemplateHasAllEnrichments,
  REQUIRED_ENRICHMENTS,
} from "../../scripts/template-enrichment-validator"

describe("Template Structure Tests", () => {
  const templatesDir = join(__dirname, "../../templates")
  const templates = ["bug-findings", "spec", "tech-debt", "security", "generic"]

  templates.forEach((templateName) => {
    describe(`${templateName}.template.md`, () => {
      let content: string

      beforeAll(async () => {
        content = await readFile(
          join(templatesDir, `${templateName}.template.md`),
          "utf-8"
        )
      })

      it("should include all 10 universal enrichments", () => {
        const validation = validateTemplateHasAllEnrichments(content)
        expect(validation.passed).toBe(true)
        expect(validation.missing).toHaveLength(0)
      })

      it("should include enrichment 5 with all 5 risk dimensions", () => {
        const riskDimensions = [
          "**Impact:**",
          "**Blast Radius:**",
          "**Dependencies:**",
          "**Testing Gaps:**",
          "**Rollback Risk:**",
        ]
        riskDimensions.forEach((dimension) => {
          expect(content).toContain(dimension)
        })
      })

      it("should have valid frontmatter metadata", () => {
        const frontmatterMatch = content.match(/^---\n([\s\S]+?)\n---/)
        expect(frontmatterMatch).toBeTruthy()

        const frontmatter = frontmatterMatch![1]
        expect(frontmatter).toContain(`templateName: ${templateName}`)
        expect(frontmatter).toContain("templateVersion:")
        expect(frontmatter).toContain("description:")
        expect(frontmatter).toContain("requiredEnrichments: 10")
      })

      it("should NOT contain placeholder content", () => {
        // Remove frontmatter and comments
        const outputContent = content
          .replace(/^---[\s\S]+?---/, "")
          .replace(/<!-- [\s\S]+? -->/g, "")

        // No bracket placeholders
        const bracketPlaceholders = outputContent.match(/\[[\w\s]+\]/g) || []
        expect(bracketPlaceholders).toHaveLength(0)

        // No TODO markers
        expect(outputContent).not.toContain("TODO")

        // No example data in field values
        const fieldValuePattern = /\*\*\w+:\*\* .+/g
        const fieldValues = outputContent.match(fieldValuePattern) || []
        expect(fieldValues).toHaveLength(0) // All fields should be empty
      })
    })
  })

  it("should have exactly 5 template files", async () => {
    const files = await readdir(templatesDir)
    const templateFiles = files.filter((f) => f.endsWith(".template.md"))
    expect(templateFiles).toHaveLength(5)
  })
})
```

```typescript
// tests/templates/discovery.test.ts

import { describe, it, expect } from "vitest"
import { TemplateRegistry } from "../../scripts/template-registry"

describe("Template Discovery Tests", () => {
  it("should list all templates", async () => {
    const templates = await TemplateRegistry.listTemplates()

    expect(templates).toHaveLength(5)
    expect(templates.map((t) => t.templateName)).toEqual(
      expect.arrayContaining([
        "bug-findings",
        "spec",
        "tech-debt",
        "security",
        "generic",
      ])
    )
  })

  it("should retrieve template content", async () => {
    const content = await TemplateRegistry.getTemplate("bug-findings")

    expect(content).toContain("templateName: bug-findings")
    expect(content).toContain("## Core Metadata")
    expect(content).toContain("**Component:**")
  })

  it("should retrieve template metadata", async () => {
    const metadata = await TemplateRegistry.getTemplateMetadata("spec")

    expect(metadata.templateName).toBe("spec")
    expect(metadata.templateVersion).toMatch(/^\d+\.\d+\.\d+$/)
    expect(metadata.requiredEnrichments).toBe(10)
    expect(metadata.formatSkill).toBe("format-spec")
  })

  it("should validate template structure", async () => {
    const isValid = await TemplateRegistry.validateTemplate("security")
    expect(isValid).toBe(true)
  })

  it("should throw error for non-existent template", async () => {
    await expect(TemplateRegistry.getTemplate("non-existent")).rejects.toThrow()
  })
})
```

```typescript
// tests/templates/alignment.test.ts

import { describe, it, expect } from "vitest"
import { TemplateRegistry } from "../../scripts/template-registry"
import { FindingValidator } from "../../validators/validate-finding"
import { SpecValidator } from "../../validators/validate-spec"
// ... import other validators

describe("Template-Validator Alignment Tests", () => {
  it("bug-findings template matches FindingValidator checks", async () => {
    const template = await TemplateRegistry.getTemplate("bug-findings")
    const validator = new FindingValidator(template)

    // Validator should pass on minimal valid structure
    const result = validator.validate()

    // All checks present (11 enrichment checks + 1 overall)
    expect(result.results).toHaveLength(12)
  })

  it("spec template matches SpecValidator checks", async () => {
    const template = await TemplateRegistry.getTemplate("spec")
    const validator = new SpecValidator(template)

    const result = validator.validate()
    expect(result.results).toHaveLength(12)
  })

  it("validator checks are not stricter than template", async () => {
    // This tests that validators don't require fields not in template
    const template = await TemplateRegistry.getTemplate("bug-findings")
    const validator = new FindingValidator(template)

    // Extract required fields from validator
    const validatorRequirements = validator.getRequiredFields()

    // All validator requirements should be in template
    for (const req of validatorRequirements) {
      expect(template).toContain(req)
    }
  })
})
```

---

## 7. Implementation Phases

### Phase 1: Template Creation (Week 1)

**Deliverables:**

- Create `templates/` directory
- Create 5 template files:
  - `bug-findings.template.md`
  - `spec.template.md`
  - `tech-debt.template.md`
  - `security.template.md`
  - `generic.template.md`
- Each template includes:
  - Frontmatter metadata
  - Task output structure comment
  - All 10 enrichments
  - Pure structure (no placeholders)

**Success Criteria:**

- All templates validate via `validate-templates.ts`
- Templates are structure-only (no placeholder content)
- Each template has all 5 risk dimensions

**Tasks:**

1. Create templates directory
2. Write bug-findings.template.md
3. Write spec.template.md
4. Write tech-debt.template.md
5. Write security.template.md
6. Write generic.template.md
7. Validate all templates pass enrichment check

### Phase 2: Validation Infrastructure (Week 1-2)

**Deliverables:**

- `scripts/template-enrichment-validator.ts` with REQUIRED_ENRICHMENTS array
- `scripts/validate-templates.ts` CLI tool
- Exit code 0 on success, 1 on failure

**Success Criteria:**

- Validator detects missing enrichments
- Validator detects missing risk dimensions
- CLI tool provides clear error messages

**Tasks:**

1. Create template-enrichment-validator.ts
2. Define REQUIRED_ENRICHMENTS array (maps to SHARED_ENRICHMENTS.md)
3. Implement validateTemplateHasAllEnrichments()
4. Create validate-templates.ts CLI
5. Test validator against all templates
6. Document validator usage

### Phase 3: Discovery API (Week 2)

**Deliverables:**

- `scripts/template-registry.ts` with TemplateRegistry class
- `scripts/list-templates.ts` CLI
- `scripts/get-template.ts` CLI
- JSON output format for programmatic access

**Success Criteria:**

- listTemplates() returns all 5 templates
- getTemplate() retrieves content
- CLI outputs valid JSON
- External plugins can discover templates

**Tasks:**

1. Create template-registry.ts
2. Implement TemplateRegistry.listTemplates()
3. Implement TemplateRegistry.getTemplate()
4. Implement TemplateRegistry.getTemplateMetadata()
5. Create list-templates.ts CLI
6. Create get-template.ts CLI
7. Test discovery API

### Phase 4: Testing Suite (Week 2-3)

**Deliverables:**

- `tests/templates/structure.test.ts` (5 tests per template)
- `tests/templates/discovery.test.ts` (6 tests)
- `tests/templates/alignment.test.ts` (3 tests per validator)
- All tests passing

**Success Criteria:**

- Structure tests verify all enrichments
- Discovery tests verify API functionality
- Alignment tests ensure validator-template consistency

**Tasks:**

1. Create tests/templates/ directory
2. Write structure.test.ts
3. Write discovery.test.ts
4. Write alignment.test.ts
5. Run all tests and fix failures
6. Document test coverage

### Phase 5: Skill Integration (Week 3)

**Deliverables:**

- Update all 5 SKILL.md files to reference templates
- Add template validation to skill outputs
- Documentation on template usage

**Success Criteria:**

- All skills reference their templates
- Skills validate against template structure
- Documentation complete

**Tasks:**

1. Update format-bug-findings/SKILL.md
2. Update format-spec/SKILL.md
3. Update format-tech-debt/SKILL.md
4. Update format-security/SKILL.md
5. Update format-generic/SKILL.md
6. Document template integration pattern

### Phase 6: Pre-Commit Hook (Week 3)

**Deliverables:**

- Pre-commit hook runs validate-templates.ts
- Prevents commits with invalid templates
- Clear error messages on failure

**Success Criteria:**

- Hook blocks invalid template commits
- Hook runs fast (< 1 second)
- Hook provides actionable error messages

**Tasks:**

1. Add validate-templates.ts to pre-commit hook
2. Test hook with valid templates
3. Test hook with invalid templates (should block)
4. Document hook behavior

---

## 8. CLI Command Reference

```bash
# List all available templates (JSON output)
pnpm tsx .claude-plugins/task-streams/scripts/list-templates.ts

# Get template content
pnpm tsx .claude-plugins/task-streams/scripts/get-template.ts bug-findings

# Get template metadata only
pnpm tsx .claude-plugins/task-streams/scripts/get-template.ts spec --metadata-only

# Validate all templates
pnpm tsx .claude-plugins/task-streams/scripts/validate-templates.ts

# Run template tests
pnpm test tests/templates/
pnpm test tests/templates/structure.test.ts
pnpm test tests/templates/discovery.test.ts
pnpm test tests/templates/alignment.test.ts
```

---

## 9. Package.json Scripts

```json
{
  "scripts": {
    "templates:list": "tsx .claude-plugins/task-streams/scripts/list-templates.ts",
    "templates:get": "tsx .claude-plugins/task-streams/scripts/get-template.ts",
    "templates:validate": "tsx .claude-plugins/task-streams/scripts/validate-templates.ts",
    "test:templates": "vitest run tests/templates/",
    "test:templates:structure": "vitest run tests/templates/structure.test.ts",
    "test:templates:discovery": "vitest run tests/templates/discovery.test.ts",
    "test:templates:alignment": "vitest run tests/templates/alignment.test.ts"
  }
}
```

---

## 10. External Plugin Integration

### 10.1 Discovery Workflow

External plugins can discover available templates:

```typescript
// External plugin code
import { exec } from "child_process"

// Discover available templates
const { stdout } = await exec(
  "pnpm tsx .claude-plugins/task-streams/scripts/list-templates.ts"
)
const templates = JSON.parse(stdout)

console.log(`Found ${templates.length} templates:`)
templates.forEach((t) => {
  console.log(`- ${t.templateName}: ${t.description}`)
})

// Get specific template
const { stdout: templateContent } = await exec(
  "pnpm tsx .claude-plugins/task-streams/scripts/get-template.ts bug-findings"
)
console.log("Template structure:", templateContent)
```

### 10.2 Plugin Manifest Integration

Future enhancement: Plugin manifest declares available templates

```json
{
  "name": "task-streams",
  "version": "1.0.0",
  "templates": [
    {
      "name": "bug-findings",
      "description": "Structure for enriched bug findings and code review issues",
      "command": "pnpm tsx scripts/get-template.ts bug-findings"
    }
  ]
}
```

---

## 11. Success Metrics

- **All 5 templates created** and validated
- **Template validation** runs in < 1 second
- **Discovery API** returns all templates with metadata
- **All template tests pass** (structure, discovery, alignment)
- **Pre-commit hook** prevents invalid templates
- **External plugins** can discover and retrieve templates
- **Documentation complete** for template usage

---

## 12. File Structure

```
.claude-plugins/task-streams/
├── templates/
│   ├── bug-findings.template.md      # NEW
│   ├── spec.template.md              # NEW
│   ├── tech-debt.template.md         # NEW
│   ├── security.template.md          # NEW
│   ├── generic.template.md           # NEW
│   └── README.md                     # NEW
├── scripts/
│   ├── template-registry.ts          # NEW
│   ├── template-enrichment-validator.ts  # NEW
│   ├── validate-templates.ts         # NEW
│   ├── list-templates.ts             # NEW
│   └── get-template.ts               # NEW
├── tests/
│   └── templates/
│       ├── structure.test.ts         # NEW
│       ├── discovery.test.ts         # NEW
│       └── alignment.test.ts         # NEW
├── skills/
│   ├── format-bug-findings/
│   │   └── SKILL.md                  # UPDATED - reference template
│   ├── format-spec/
│   │   └── SKILL.md                  # UPDATED
│   └── ...
└── SPEC-TEMPLATE-SYSTEM.md           # THIS FILE
```

---

## 13. Open Questions

1. **Template Versioning**: How to handle template version updates?
   - Proposed: Semantic versioning in frontmatter, breaking changes increment major version

2. **Format-Specific Extensions**: Can templates have format-specific sections?
   - Proposed: Yes, but all 10 universal enrichments still required

3. **Template Inheritance**: Should templates share common base structure?
   - Proposed: Yes (future enhancement), create base.template.md

---

## 14. Future Enhancements

1. **Template Inheritance**: Base template with format-specific extensions
2. **Template Playground**: Interactive tool to preview template structure
3. **Template Linter**: Check for markdown formatting issues
4. **Template Versioning**: Automated version bump on changes
5. **Multi-Language Templates**: Support for non-English templates

---

## 15. Conclusion

This template system provides a clear, discoverable contract for task-streams output formats. By enforcing structure-only templates with all 10 universal enrichments, we ensure consistent, high-quality enriched tasks across all document types.

The template discovery API enables external plugins to understand available formats and integrate seamlessly with the task-streams pipeline.

**Next Steps**: Begin Phase 1 implementation (Template Creation).
