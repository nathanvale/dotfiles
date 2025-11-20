/**
 * Discovery API Tests (Task 1.7 - RED Phase)
 *
 * Tests for TemplateRegistry class that discovers and manages templates
 * Following TDD: Write tests FIRST, then implement to make them pass
 */

import { mkdtemp, rm, writeFile, mkdir } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'

import { describe, it, expect, beforeAll, afterAll } from 'vitest'

import { TemplateRegistry } from '../../scripts/template-registry.js'

import type { TemplateMetadata } from '../../scripts/template-registry.js'

const TEMPLATES_DIR = join(process.cwd(), '.claude-plugins/task-streams/templates')

describe('TemplateRegistry', () => {
  describe('listTemplates()', () => {
    it('should return array of 5 templates', async () => {
      const templates = await TemplateRegistry.listTemplates(TEMPLATES_DIR)

      expect(templates).toHaveLength(5)
      expect(Array.isArray(templates)).toBe(true)
    })

    it('each template should have required metadata fields', async () => {
      const templates = await TemplateRegistry.listTemplates(TEMPLATES_DIR)

      for (const template of templates) {
        expect(template).toHaveProperty('templateName')
        expect(template).toHaveProperty('templateVersion')
        expect(template).toHaveProperty('description')
        expect(template).toHaveProperty('requiredEnrichments')
        expect(template).toHaveProperty('formatSkill')
        expect(template).toHaveProperty('path')

        expect(typeof template.templateName).toBe('string')
        expect(typeof template.templateVersion).toBe('string')
        expect(typeof template.description).toBe('string')
        expect(typeof template.requiredEnrichments).toBe('number')
        expect(typeof template.formatSkill).toBe('string')
        expect(typeof template.path).toBe('string')
      }
    })

    it('templateNames should include all 5 expected templates', async () => {
      const templates = await TemplateRegistry.listTemplates(TEMPLATES_DIR)
      const names = templates.map((t) => t.templateName).sort()

      expect(names).toEqual(['bug-findings', 'generic', 'security', 'spec', 'tech-debt'])
    })

    it('all templates should have requiredEnrichments: 10', async () => {
      const templates = await TemplateRegistry.listTemplates(TEMPLATES_DIR)

      for (const template of templates) {
        expect(template.requiredEnrichments).toBe(10)
      }
    })

    it('should return templates sorted by templateName', async () => {
      const templates = await TemplateRegistry.listTemplates(TEMPLATES_DIR)
      const names = templates.map((t) => t.templateName)

      const sortedNames = [...names].sort()
      expect(names).toEqual(sortedNames)
    })

    it('should handle custom templatesDir parameter', async () => {
      const templates = await TemplateRegistry.listTemplates(TEMPLATES_DIR)

      expect(templates.length).toBeGreaterThan(0)
    })
  })

  describe('getTemplate(name)', () => {
    it('should retrieve template content by name', async () => {
      const content = await TemplateRegistry.getTemplate('bug-findings', TEMPLATES_DIR)

      expect(typeof content).toBe('string')
      expect(content.length).toBeGreaterThan(0)
    })

    it('content should start with frontmatter (---)', async () => {
      const content = await TemplateRegistry.getTemplate('bug-findings', TEMPLATES_DIR)

      expect(content.trimStart().startsWith('---')).toBe(true)
    })

    it('content should include templateName in frontmatter', async () => {
      const content = await TemplateRegistry.getTemplate('bug-findings', TEMPLATES_DIR)

      expect(content).toContain('templateName: bug-findings')
    })

    it('content should include all 10 enrichment sections', async () => {
      const content = await TemplateRegistry.getTemplate('bug-findings', TEMPLATES_DIR)

      // Check for key enrichment indicators
      expect(content).toContain('**Location:**') // Enrichment 1
      expect(content).toContain('**Estimated Effort:**') // Enrichment 2
      expect(content).toContain('**Complexity:**') // Enrichment 3
      expect(content).toContain('## Acceptance Criteria') // Enrichment 4
      expect(content).toContain('## Regression Risk Analysis') // Enrichment 5
      expect(content).toContain('## Implementation Plan') // Enrichment 6
      expect(content).toContain('## Code Examples') // Enrichment 7
      expect(content).toContain('## File Changes') // Enrichment 8
      expect(content).toContain('## Testing Requirements') // Enrichment 9
      expect(content).toContain('## Dependencies') // Enrichment 10
    })

    it('should work for all 5 templates', async () => {
      const templateNames = ['bug-findings', 'generic', 'security', 'spec', 'tech-debt']

      for (const name of templateNames) {
        const content = await TemplateRegistry.getTemplate(name, TEMPLATES_DIR)
        expect(content.length).toBeGreaterThan(0)
        expect(content).toContain(`templateName: ${name}`)
      }
    })

    it('should throw error for non-existent template', async () => {
      await expect(TemplateRegistry.getTemplate('non-existent', TEMPLATES_DIR)).rejects.toThrow(
        /Template "non-existent" not found/
      )
    })

    it('should throw helpful error message with path', async () => {
      await expect(TemplateRegistry.getTemplate('missing', TEMPLATES_DIR)).rejects.toThrow(/missing\.template\.md/)
    })
  })

  describe('getTemplateMetadata(name)', () => {
    it('should return metadata object only (not full content)', async () => {
      const metadata = await TemplateRegistry.getTemplateMetadata('bug-findings', TEMPLATES_DIR)

      expect(metadata).toHaveProperty('templateName')
      expect(metadata).toHaveProperty('templateVersion')
      expect(metadata).toHaveProperty('description')
      expect(metadata).toHaveProperty('requiredEnrichments')
      expect(metadata).toHaveProperty('formatSkill')
      expect(metadata).toHaveProperty('path')
    })

    it('should have correct metadata for bug-findings template', async () => {
      const metadata = await TemplateRegistry.getTemplateMetadata('bug-findings', TEMPLATES_DIR)

      expect(metadata.templateName).toBe('bug-findings')
      expect(metadata.templateVersion).toMatch(/^\d+\.\d+\.\d+$/) // semver
      expect(metadata.description).toContain('bug')
      expect(metadata.requiredEnrichments).toBe(10)
      expect(metadata.formatSkill).toBe('format-bug-findings')
      expect(metadata.path).toContain('bug-findings.template.md')
    })

    it('templateVersion should match semver pattern', async () => {
      const templates = await TemplateRegistry.listTemplates(TEMPLATES_DIR)

      for (const template of templates) {
        const metadata = await TemplateRegistry.getTemplateMetadata(template.templateName, TEMPLATES_DIR)
        expect(metadata.templateVersion).toMatch(/^\d+\.\d+\.\d+$/)
      }
    })

    it('all templates should have requiredEnrichments: 10', async () => {
      const templateNames = ['bug-findings', 'generic', 'security', 'spec', 'tech-debt']

      for (const name of templateNames) {
        const metadata = await TemplateRegistry.getTemplateMetadata(name, TEMPLATES_DIR)
        expect(metadata.requiredEnrichments).toBe(10)
      }
    })

    it('should throw error for non-existent template', async () => {
      await expect(TemplateRegistry.getTemplateMetadata('non-existent', TEMPLATES_DIR)).rejects.toThrow(
        /Template "non-existent" not found/
      )
    })

    it('path field should be absolute path', async () => {
      const metadata = await TemplateRegistry.getTemplateMetadata('bug-findings', TEMPLATES_DIR)

      expect(metadata.path).toMatch(/^\//) // Starts with /
      expect(metadata.path).toContain('bug-findings.template.md')
    })
  })

  describe('validateTemplate(name)', () => {
    it('should return true for valid templates', async () => {
      const isValid = await TemplateRegistry.validateTemplate('bug-findings', TEMPLATES_DIR)

      expect(isValid).toBe(true)
    })

    it('should validate all 5 templates as valid', async () => {
      const templateNames = ['bug-findings', 'generic', 'security', 'spec', 'tech-debt']

      for (const name of templateNames) {
        const isValid = await TemplateRegistry.validateTemplate(name, TEMPLATES_DIR)
        expect(isValid).toBe(true)
      }
    })

    it('should return false for invalid template (missing enrichments)', async () => {
      // Create temporary invalid template
      const tempDir = await mkdtemp(join(tmpdir(), 'template-test-'))
      const invalidPath = join(tempDir, 'invalid.template.md')

      await writeFile(
        invalidPath,
        `---
templateName: invalid
templateVersion: 1.0.0
description: Invalid template
requiredEnrichments: 10
formatSkill: format-invalid
---

# Incomplete Template
Missing most enrichments
`
      )

      try {
        const isValid = await TemplateRegistry.validateTemplate('invalid', tempDir)
        expect(isValid).toBe(false)
      } finally {
        await rm(tempDir, { recursive: true })
      }
    })

    it('should throw error for non-existent template', async () => {
      await expect(TemplateRegistry.validateTemplate('non-existent', TEMPLATES_DIR)).rejects.toThrow(
        /Template "non-existent" not found/
      )
    })

    it('should validate against REQUIRED_ENRICHMENTS from validator', async () => {
      // This test ensures integration with template-enrichment-validator
      const isValid = await TemplateRegistry.validateTemplate('bug-findings', TEMPLATES_DIR)

      // Valid templates should pass all 10 enrichment checks
      expect(isValid).toBe(true)
    })
  })

  describe('Error Handling', () => {
    it('getTemplate() should throw for non-existent template', async () => {
      await expect(TemplateRegistry.getTemplate('does-not-exist', TEMPLATES_DIR)).rejects.toThrow()
    })

    it('getTemplateMetadata() should throw for non-existent template', async () => {
      await expect(TemplateRegistry.getTemplateMetadata('does-not-exist', TEMPLATES_DIR)).rejects.toThrow()
    })

    it('validateTemplate() should throw for non-existent template', async () => {
      await expect(TemplateRegistry.validateTemplate('does-not-exist', TEMPLATES_DIR)).rejects.toThrow()
    })
  })

  describe('Edge Cases', () => {
    let tempDir: string

    beforeAll(async () => {
      tempDir = await mkdtemp(join(tmpdir(), 'template-edge-'))
    })

    afterAll(async () => {
      await rm(tempDir, { recursive: true })
    })

    it('should handle empty template directory', async () => {
      const emptyDir = join(tempDir, 'empty')
      await mkdir(emptyDir, { recursive: true })

      const templates = await TemplateRegistry.listTemplates(emptyDir)
      expect(templates).toEqual([])
    })

    it('should handle directory with no *.template.md files', async () => {
      const noTemplatesDir = join(tempDir, 'no-templates')
      await mkdir(noTemplatesDir, { recursive: true })

      // Create non-template files
      await writeFile(join(noTemplatesDir, 'README.md'), '# Not a template')
      await writeFile(join(noTemplatesDir, 'file.txt'), 'Just text')

      const templates = await TemplateRegistry.listTemplates(noTemplatesDir)
      expect(templates).toEqual([])
    })

    it('should only process *.template.md files (mixed directory)', async () => {
      const mixedDir = join(tempDir, 'mixed')
      await mkdir(mixedDir, { recursive: true })

      // Create one valid template
      await writeFile(
        join(mixedDir, 'valid.template.md'),
        `---
templateName: valid
templateVersion: 1.0.0
description: Valid template
requiredEnrichments: 10
formatSkill: format-valid
---

**Location:**
**Estimated Effort:**
**Complexity:**
## Acceptance Criteria
**Acceptance Criteria:**
## Regression Risk Analysis
**Regression Risk Details:**
**Impact:**
**Blast Radius:**
**Dependencies:**
**Testing Gaps:**
**Rollback Risk:**
## Implementation Plan
**Implementation Steps:**
## Code Examples
## File Changes
**Files to Create:**
**Files to Modify:**
**Files to Delete:**
## Testing Requirements
**Required Testing:**
## Dependencies
**Blocking Dependencies:**
**Blocks:**
**Prerequisites:**
`
      )

      // Create non-template files that should be ignored
      await writeFile(join(mixedDir, 'README.md'), '# Ignore me')
      await writeFile(join(mixedDir, 'notes.txt'), 'Ignore me too')
      await writeFile(join(mixedDir, 'template.md'), 'Missing .template suffix')

      const templates = await TemplateRegistry.listTemplates(mixedDir)

      expect(templates).toHaveLength(1)
      expect(templates[0]!.templateName).toBe('valid')
    })

    it('should handle template with malformed YAML frontmatter gracefully', async () => {
      const malformedDir = join(tempDir, 'malformed')
      await mkdir(malformedDir, { recursive: true })

      await writeFile(
        join(malformedDir, 'broken.template.md'),
        `---
templateName: broken
this is not valid YAML: [[[
---

Content
`
      )

      // Should either skip or throw descriptive error
      await expect(TemplateRegistry.listTemplates(malformedDir)).rejects.toThrow()
    })
  })
})
