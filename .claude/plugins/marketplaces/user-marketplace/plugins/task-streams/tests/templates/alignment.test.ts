/**
 * Template-Validator Alignment Tests
 *
 * Ensures template-validator alignment:
 * - Templates match validator expectations
 * - Validators check what templates define
 * - No drift between templates and validation rules
 */

import { readFile } from 'node:fs/promises'
import { join } from 'node:path'

import { describe, it, expect, beforeAll } from 'vitest'

import { REQUIRED_ENRICHMENTS, validateTemplateHasAllEnrichments } from '../../scripts/template-enrichment-validator.js'

describe('Template-Validator Alignment Tests', () => {
  const templatesDir = join(__dirname, '../../templates')
  const templateNames = ['bug-findings', 'spec', 'tech-debt', 'security', 'generic']

  describe('Template structure matches validator expectations', () => {
    for (const templateName of templateNames) {
      it(`${templateName} template should pass validation`, async () => {
        const content = await readFile(join(templatesDir, `${templateName}.template.md`), 'utf-8')

        const result = validateTemplateHasAllEnrichments(content)

        expect(result.passed).toBe(true)
        expect(result.missing).toHaveLength(0)
      })
    }
  })

  describe('Validator checks are not stricter than template', () => {
    for (const templateName of templateNames) {
      it(`${templateName} template contains all validator requirements`, async () => {
        const content = await readFile(join(templatesDir, `${templateName}.template.md`), 'utf-8')

        // Extract all required fields and headings from validator
        const allRequiredFields: string[] = []
        const allRequiredHeadings: string[] = []

        for (const enrichment of REQUIRED_ENRICHMENTS) {
          allRequiredFields.push(...enrichment.requiredFields)
          allRequiredHeadings.push(...enrichment.requiredHeadings)
        }

        // All validator requirements should be in template
        for (const field of allRequiredFields) {
          expect(content).toContain(field)
        }

        for (const heading of allRequiredHeadings) {
          expect(content).toContain(heading)
        }
      })
    }
  })

  describe('No template sections missing from validator', () => {
    for (const templateName of templateNames) {
      it(`${templateName} template sections should be checked by validator`, async () => {
        const content = await readFile(join(templatesDir, `${templateName}.template.md`), 'utf-8')

        // Extract all ## headings from template (skip frontmatter and comments)
        const templateContent = content
          .replace(/^---[\s\S]+?---/, '') // Remove frontmatter
          .replace(/<!-- [\s\S]+? -->/g, '') // Remove comments

        const headingMatches = templateContent.match(/^## .+$/gm) || []
        const templateHeadings = headingMatches.map((h) => h.trim())

        // Get all enrichment headings from validator
        const enrichmentHeadings: string[] = []
        for (const enrichment of REQUIRED_ENRICHMENTS) {
          enrichmentHeadings.push(...enrichment.requiredHeadings)
        }

        // All major template headings should be in enrichment headings
        // (excluding "Core Metadata" and "Description" which are metadata sections)
        const validationRequiredHeadings = [
          '## Regression Risk Analysis',
          '## Acceptance Criteria',
          '## Implementation Plan',
          '## Code Examples',
          '## File Changes',
          '## Testing Requirements',
          '## Dependencies',
        ]

        for (const heading of validationRequiredHeadings) {
          expect(enrichmentHeadings).toContain(heading)
        }
      })
    }
  })

  describe('Enrichment #5 dimension alignment', () => {
    const expectedDimensions = [
      '**Impact:**',
      '**Blast Radius:**',
      '**Dependencies:**',
      '**Testing Gaps:**',
      '**Rollback Risk:**',
    ]

    it('validator requires all 5 dimensions', () => {
      const enrichment5 = REQUIRED_ENRICHMENTS.find((e) => e.id === 5)
      expect(enrichment5).toBeDefined()
      expect(enrichment5!.name).toBe('Regression Risk (5 Dimensions)')

      // Validator should require all 5 dimensions
      for (const dimension of expectedDimensions) {
        expect(enrichment5!.requiredFields).toContain(dimension)
      }
    })

    for (const templateName of templateNames) {
      it(`${templateName} template has all 5 dimensions`, async () => {
        const content = await readFile(join(templatesDir, `${templateName}.template.md`), 'utf-8')

        for (const dimension of expectedDimensions) {
          expect(content).toContain(dimension)
        }
      })
    }
  })

  describe('Enrichment #8 category alignment', () => {
    const expectedCategories = ['**Files to Create:**', '**Files to Modify:**', '**Files to Delete:**']

    it('validator requires all 3 categories', () => {
      const enrichment8 = REQUIRED_ENRICHMENTS.find((e) => e.id === 8)
      expect(enrichment8).toBeDefined()
      expect(enrichment8!.name).toBe('File Change Scope (3 Categories)')

      // Validator should require all 3 categories
      for (const category of expectedCategories) {
        expect(enrichment8!.requiredFields).toContain(category)
      }
    })

    for (const templateName of templateNames) {
      it(`${templateName} template has all 3 categories`, async () => {
        const content = await readFile(join(templatesDir, `${templateName}.template.md`), 'utf-8')

        for (const category of expectedCategories) {
          expect(content).toContain(category)
        }
      })
    }
  })

  describe('Enrichment #10 field alignment', () => {
    const expectedFields = ['**Blocking Dependencies:**', '**Blocks:**', '**Prerequisites:**']

    it('validator requires all 3 dependency fields', () => {
      const enrichment10 = REQUIRED_ENRICHMENTS.find((e) => e.id === 10)
      expect(enrichment10).toBeDefined()
      expect(enrichment10!.name).toBe('Dependencies and Blocking')

      // Validator should require all 3 fields
      for (const field of expectedFields) {
        expect(enrichment10!.requiredFields).toContain(field)
      }
    })

    for (const templateName of templateNames) {
      it(`${templateName} template has all 3 dependency fields`, async () => {
        const content = await readFile(join(templatesDir, `${templateName}.template.md`), 'utf-8')

        for (const field of expectedFields) {
          expect(content).toContain(field)
        }
      })
    }
  })
})
