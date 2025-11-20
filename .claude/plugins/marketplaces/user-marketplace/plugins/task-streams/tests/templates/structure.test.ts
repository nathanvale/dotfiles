/**
 * Template Structure Tests
 *
 * Validates that all templates include all 10 universal enrichments
 * and follow structure-only guidelines (no placeholder content)
 *
 * TDD: RED phase - Write tests first, then create templates
 */

import { readFileSync, readdirSync } from 'node:fs'
import { join } from 'node:path'

import { describe, it, expect } from 'vitest'

import {
  validateTemplateHasAllEnrichments,
  validateRiskDimensions,
  validateFileChangeCategories,
  validateDependencyFields,
  validateFrontmatter,
  checkForPlaceholders,
} from '../../../../scripts/template-enrichment-validator.js'

const TEMPLATES_DIR = join(__dirname, '../../templates')

const TEMPLATE_NAMES = ['bug-findings', 'spec', 'tech-debt', 'security', 'generic']

describe('Template Structure Tests', () => {
  describe('Template Files Existence', () => {
    it('should have exactly 5 template files', () => {
      const files = readdirSync(TEMPLATES_DIR)
      const templateFiles = files.filter((f) => f.endsWith('.template.md'))

      expect(templateFiles).toHaveLength(5)
      expect(templateFiles.sort()).toEqual([
        'bug-findings.template.md',
        'generic.template.md',
        'security.template.md',
        'spec.template.md',
        'tech-debt.template.md',
      ])
    })
  })

  describe.each(TEMPLATE_NAMES)('Template: %s', (templateName) => {
    const templatePath = join(TEMPLATES_DIR, `${templateName}.template.md`)
    let templateContent: string

    // Read template once for all tests
    try {
      templateContent = readFileSync(templatePath, 'utf-8')
    } catch {
      // If file doesn't exist, tests will fail with clear message
      templateContent = ''
    }

    describe('All 10 Enrichments Present', () => {
      it('should include all 10 universal enrichments', () => {
        const result = validateTemplateHasAllEnrichments(templateContent)

        expect(result.passed).toBe(true)
        expect(result.missing).toEqual([])
      })
    })

    describe('Enrichment #5: Risk Dimensions', () => {
      it('should have all 5 risk dimensions', () => {
        const result = validateRiskDimensions(templateContent)

        expect(result.passed).toBe(true)
        expect(result.missing).toEqual([])

        // Verify each dimension explicitly
        expect(templateContent).toContain('**Impact:**')
        expect(templateContent).toContain('**Blast Radius:**')
        expect(templateContent).toContain('**Dependencies:**')
        expect(templateContent).toContain('**Testing Gaps:**')
        expect(templateContent).toContain('**Rollback Risk:**')
      })
    })

    describe('Enrichment #8: File Change Categories', () => {
      it('should have all 3 file change categories', () => {
        const result = validateFileChangeCategories(templateContent)

        expect(result.passed).toBe(true)
        expect(result.missing).toEqual([])

        // Verify each category explicitly
        expect(templateContent).toContain('**Files to Create:**')
        expect(templateContent).toContain('**Files to Modify:**')
        expect(templateContent).toContain('**Files to Delete:**')
      })
    })

    describe('Enrichment #10: Dependency Fields', () => {
      it('should have all 3 dependency fields', () => {
        const result = validateDependencyFields(templateContent)

        expect(result.passed).toBe(true)
        expect(result.missing).toEqual([])

        // Verify each field explicitly
        expect(templateContent).toContain('**Blocking Dependencies:**')
        expect(templateContent).toContain('**Blocks:**')
        expect(templateContent).toContain('**Prerequisites:**')
      })
    })

    describe('Frontmatter Metadata', () => {
      it('should have valid frontmatter with all required fields', () => {
        const result = validateFrontmatter(templateContent)

        expect(result.passed).toBe(true)
        expect(result.missing).toEqual([])

        // Verify frontmatter contains expected values
        expect(templateContent).toMatch(/^---\n/)
        expect(templateContent).toContain(`templateName: ${templateName}`)
        expect(templateContent).toMatch(/templateVersion: \d+\.\d+\.\d+/)
        expect(templateContent).toContain('description:')
        expect(templateContent).toContain('requiredEnrichments: 10')
        expect(templateContent).toContain(`formatSkill: format-${templateName}`)
      })

      it('should have semver version format', () => {
        const versionMatch = templateContent.match(/templateVersion:\s*(\S+)/)
        expect(versionMatch).toBeTruthy()

        const version = versionMatch?.[1]
        expect(version).toMatch(/^\d+\.\d+\.\d+$/)
      })
    })

    describe('No Placeholder Content', () => {
      it('should NOT contain bracket placeholders', () => {
        const result = checkForPlaceholders(templateContent)

        // Filter out only bracket placeholder issues
        const bracketIssues = result.missing.filter(
          (m) => m.includes('bracket placeholder') && !m.includes('[Priority]') && !m.includes('[Title]')
        )

        expect(bracketIssues).toEqual([])
      })

      it('should NOT contain TODO markers', () => {
        const result = checkForPlaceholders(templateContent)

        const todoIssues = result.missing.filter((m) => m.includes('TODO'))

        expect(todoIssues).toEqual([])
      })

      it('should NOT have example data in field values', () => {
        const result = checkForPlaceholders(templateContent)

        const contentIssues = result.missing.filter((m) => m.includes('Field has content'))

        expect(contentIssues).toEqual([])
      })

      it('should have empty field values (structure only)', () => {
        // Fields should be empty: "**Location:**" with newline or nothing after
        const lines = templateContent.split('\n')

        const fieldLines = lines.filter(
          (line) => line.match(/\*\*[^*]+:\*\*$/) // Field label ending with nothing
        )

        // Should have multiple empty fields
        expect(fieldLines.length).toBeGreaterThan(0)
      })
    })

    describe('Required Headings Hierarchy', () => {
      it('should have Core Metadata section', () => {
        expect(templateContent).toContain('## Core Metadata')
      })

      it('should have Description section', () => {
        expect(templateContent).toContain('## Description')
      })

      it('should have Regression Risk Analysis section', () => {
        expect(templateContent).toContain('## Regression Risk Analysis')
      })

      it('should have Acceptance Criteria section', () => {
        expect(templateContent).toContain('## Acceptance Criteria')
      })

      it('should have Implementation Plan section', () => {
        expect(templateContent).toContain('## Implementation Plan')
      })

      it('should have Code Examples section', () => {
        expect(templateContent).toContain('## Code Examples')
      })

      it('should have File Changes section', () => {
        expect(templateContent).toContain('## File Changes')
      })

      it('should have Testing Requirements section', () => {
        expect(templateContent).toContain('## Testing Requirements')
      })

      it('should have Dependencies section', () => {
        expect(templateContent).toContain('## Dependencies')
      })
    })

    describe('Task Output Frontmatter Structure', () => {
      it('should include task output frontmatter comment block', () => {
        expect(templateContent).toContain('<!-- TASK OUTPUT FRONTMATTER STRUCTURE -->')
      })

      it('should define task frontmatter fields', () => {
        // Should have commented frontmatter showing structure
        expect(templateContent).toContain('id:')
        expect(templateContent).toContain('title:')
        expect(templateContent).toContain('priority:')
        expect(templateContent).toContain('component:')
        expect(templateContent).toContain('status:')
        expect(templateContent).toContain('created:')
        expect(templateContent).toContain('source:')
      })
    })
  })
})
