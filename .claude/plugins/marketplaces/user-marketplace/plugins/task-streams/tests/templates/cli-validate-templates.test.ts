import { spawn } from 'node:child_process'
import { writeFileSync, mkdirSync, rmSync } from 'node:fs'
import { join } from 'node:path'

import { describe, it, expect, beforeEach, afterEach } from 'vitest'

const CLI_PATH = join(process.cwd(), '.claude-plugins/task-streams/scripts/validate-templates.ts')
const TEMPLATES_DIR = join(process.cwd(), '.claude-plugins/task-streams/templates')
const TEST_TEMPLATES_DIR = join(process.cwd(), '.claude-plugins/task-streams/test-templates-temp')

/**
 * Helper to run CLI and capture output
 */
async function runCLI(
  templateDir: string = TEMPLATES_DIR
): Promise<{ exitCode: number; stdout: string; stderr: string }> {
  return new Promise((resolve) => {
    const child = spawn('pnpm', ['dlx', 'tsx', CLI_PATH, templateDir], {
      cwd: process.cwd(),
    })

    let stdout = ''
    let stderr = ''

    child.stdout?.on('data', (data) => {
      stdout += data.toString()
    })

    child.stderr?.on('data', (data) => {
      stderr += data.toString()
    })

    child.on('close', (code) => {
      resolve({ exitCode: code ?? 1, stdout, stderr })
    })
  })
}

/**
 * Valid template with all 10 enrichments
 */
const VALID_TEMPLATE = `
---
templateName: test-valid
templateVersion: 1.0.0
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

## Implementation Plan

**Implementation Steps:**
1.
2.

## Code Examples

\`\`\`typescript
\`\`\`

## File Changes

**Files to Create:**
-

**Files to Modify:**
-

**Files to Delete:**
-

## Testing Requirements

**Required Testing:**
| Test Type | Validates AC | Description | Location |
|-----------|--------------|-------------|----------|
|           |              |             |          |

## Dependencies

**Blocking Dependencies:**

**Blocks:**

**Prerequisites:**
- [ ]
`

/**
 * Invalid template missing multiple enrichments
 */
const INVALID_TEMPLATE_MISSING_LOCATION = `
---
templateName: test-invalid-missing-location
templateVersion: 1.0.0
---

## Core Metadata

**Component:**
**Estimated Effort:**
**Complexity:**
`

/**
 * Invalid template missing Enrichment #5 dimension
 */
const INVALID_TEMPLATE_MISSING_BLAST_RADIUS = `
---
templateName: test-invalid-missing-blast-radius
templateVersion: 1.0.0
---

## Core Metadata

**Location:**
**Estimated Effort:**
**Complexity:**

## Regression Risk Analysis

**Regression Risk Details:**
- **Impact:**
- **Dependencies:**
- **Testing Gaps:**
- **Rollback Risk:**
`

describe('validate-templates CLI', () => {
  describe('with all valid templates', () => {
    beforeEach(() => {
      mkdirSync(TEST_TEMPLATES_DIR, { recursive: true })
      writeFileSync(join(TEST_TEMPLATES_DIR, 'valid.template.md'), VALID_TEMPLATE)
    })

    afterEach(() => {
      rmSync(TEST_TEMPLATES_DIR, { recursive: true, force: true })
    })

    it('should exit with code 0', async () => {
      const result = await runCLI(TEST_TEMPLATES_DIR)
      expect(result.exitCode).toBe(0)
    })

    it('should output success message with checkmark', async () => {
      const result = await runCLI(TEST_TEMPLATES_DIR)
      expect(result.stdout).toContain('✅')
      expect(result.stdout).toContain('valid.template.md')
    })

    it('should indicate all enrichments are present', async () => {
      const result = await runCLI(TEST_TEMPLATES_DIR)
      expect(result.stdout).toMatch(/valid\.template\.md.*all.*enrichments|valid\.template\.md.*passed/i)
    })
  })

  describe('with invalid templates', () => {
    beforeEach(() => {
      mkdirSync(TEST_TEMPLATES_DIR, { recursive: true })
      writeFileSync(join(TEST_TEMPLATES_DIR, 'invalid-location.template.md'), INVALID_TEMPLATE_MISSING_LOCATION)
    })

    afterEach(() => {
      rmSync(TEST_TEMPLATES_DIR, { recursive: true, force: true })
    })

    it('should exit with code 1', async () => {
      const result = await runCLI(TEST_TEMPLATES_DIR)
      expect(result.exitCode).toBe(1)
    })

    it('should output failure message with X mark', async () => {
      const result = await runCLI(TEST_TEMPLATES_DIR)
      expect(result.stdout).toContain('❌')
      expect(result.stdout).toContain('invalid-location.template.md')
    })

    it('should list missing enrichments', async () => {
      const result = await runCLI(TEST_TEMPLATES_DIR)
      expect(result.stdout).toContain('Missing enrichments')
      expect(result.stdout).toContain('Enrichment #1')
      expect(result.stdout).toContain('**Location:**')
    })
  })

  describe('with missing Enrichment #5 dimension', () => {
    beforeEach(() => {
      mkdirSync(TEST_TEMPLATES_DIR, { recursive: true })
      writeFileSync(join(TEST_TEMPLATES_DIR, 'invalid-blast-radius.template.md'), INVALID_TEMPLATE_MISSING_BLAST_RADIUS)
    })

    afterEach(() => {
      rmSync(TEST_TEMPLATES_DIR, { recursive: true, force: true })
    })

    it('should exit with code 1', async () => {
      const result = await runCLI(TEST_TEMPLATES_DIR)
      expect(result.exitCode).toBe(1)
    })

    it('should detect missing Blast Radius dimension', async () => {
      const result = await runCLI(TEST_TEMPLATES_DIR)
      expect(result.stdout).toContain('Enrichment #5')
      expect(result.stdout).toContain('**Blast Radius:**')
    })
  })

  describe('with mixed valid and invalid templates', () => {
    beforeEach(() => {
      mkdirSync(TEST_TEMPLATES_DIR, { recursive: true })
      writeFileSync(join(TEST_TEMPLATES_DIR, 'valid.template.md'), VALID_TEMPLATE)
      writeFileSync(join(TEST_TEMPLATES_DIR, 'invalid.template.md'), INVALID_TEMPLATE_MISSING_LOCATION)
    })

    afterEach(() => {
      rmSync(TEST_TEMPLATES_DIR, { recursive: true, force: true })
    })

    it('should exit with code 1', async () => {
      const result = await runCLI(TEST_TEMPLATES_DIR)
      expect(result.exitCode).toBe(1)
    })

    it('should show both valid and invalid templates', async () => {
      const result = await runCLI(TEST_TEMPLATES_DIR)
      expect(result.stdout).toContain('✅')
      expect(result.stdout).toContain('valid.template.md')
      expect(result.stdout).toContain('❌')
      expect(result.stdout).toContain('invalid.template.md')
    })

    it('should list missing enrichments only for invalid templates', async () => {
      const result = await runCLI(TEST_TEMPLATES_DIR)

      // Invalid template should have missing enrichments listed
      expect(result.stdout).toContain('❌ invalid.template.md - Missing')
      expect(result.stdout).toMatch(/invalid\.template\.md.*Missing[\s\S]*Enrichment #/)

      // Valid template should show all enrichments present
      expect(result.stdout).toContain('✅ valid.template.md - All enrichments')
    })
  })

  describe('output format', () => {
    beforeEach(() => {
      mkdirSync(TEST_TEMPLATES_DIR, { recursive: true })
      writeFileSync(join(TEST_TEMPLATES_DIR, 'test1.template.md'), VALID_TEMPLATE)
      writeFileSync(join(TEST_TEMPLATES_DIR, 'test2.template.md'), INVALID_TEMPLATE_MISSING_LOCATION)
    })

    afterEach(() => {
      rmSync(TEST_TEMPLATES_DIR, { recursive: true, force: true })
    })

    it('should output template name with status indicator', async () => {
      const result = await runCLI(TEST_TEMPLATES_DIR)
      expect(result.stdout).toMatch(/[✅❌]\s+test1\.template\.md/)
      expect(result.stdout).toMatch(/[✅❌]\s+test2\.template\.md/)
    })

    it('should include validation summary header', async () => {
      const result = await runCLI(TEST_TEMPLATES_DIR)
      expect(result.stdout).toMatch(/Template Validation|Validating Templates/i)
    })

    it('should list all missing enrichments for invalid templates', async () => {
      const result = await runCLI(TEST_TEMPLATES_DIR)

      // Find the invalid template section
      const lines = result.stdout.split('\n')
      const invalidIndex = lines.findIndex((line) => line.includes('test2.template.md'))
      expect(invalidIndex).toBeGreaterThan(-1)

      // Check that subsequent lines list missing enrichments
      const remainingLines = lines.slice(invalidIndex + 1).join('\n')
      expect(remainingLines).toContain('Enrichment #')
    })
  })

  describe('edge cases', () => {
    it('should handle directory with no template files', async () => {
      mkdirSync(TEST_TEMPLATES_DIR, { recursive: true })

      const result = await runCLI(TEST_TEMPLATES_DIR)

      // Should succeed with no templates found
      expect(result.exitCode).toBe(0)
      expect(result.stdout).toMatch(/no templates found|0 templates/i)

      rmSync(TEST_TEMPLATES_DIR, { recursive: true, force: true })
    })

    it('should only validate *.template.md files', async () => {
      mkdirSync(TEST_TEMPLATES_DIR, { recursive: true })
      writeFileSync(join(TEST_TEMPLATES_DIR, 'valid.template.md'), VALID_TEMPLATE)
      writeFileSync(join(TEST_TEMPLATES_DIR, 'README.md'), '# Not a template')
      writeFileSync(join(TEST_TEMPLATES_DIR, 'other.md'), '# Also not')

      const result = await runCLI(TEST_TEMPLATES_DIR)

      // Should only validate .template.md file
      expect(result.stdout).toContain('valid.template.md')
      expect(result.stdout).not.toContain('README.md')
      expect(result.stdout).not.toContain('other.md')

      rmSync(TEST_TEMPLATES_DIR, { recursive: true, force: true })
    })
  })
})
