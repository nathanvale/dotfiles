import { describe, it, expect } from 'vitest'

import { REQUIRED_ENRICHMENTS, validateTemplateHasAllEnrichments } from '../../scripts/template-enrichment-validator.js'

describe('REQUIRED_ENRICHMENTS array', () => {
  it('should have exactly 10 enrichments', () => {
    expect(REQUIRED_ENRICHMENTS).toHaveLength(10)
  })

  it('should have IDs from 1 to 10', () => {
    const ids = REQUIRED_ENRICHMENTS.map((e) => e.id)
    expect(ids).toEqual([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
  })

  it('should have required structure for each enrichment', () => {
    for (const enrichment of REQUIRED_ENRICHMENTS) {
      expect(enrichment).toHaveProperty('id')
      expect(enrichment).toHaveProperty('name')
      expect(enrichment).toHaveProperty('requiredFields')
      expect(enrichment).toHaveProperty('requiredHeadings')
      expect(typeof enrichment.id).toBe('number')
      expect(typeof enrichment.name).toBe('string')
      expect(Array.isArray(enrichment.requiredFields)).toBe(true)
      expect(Array.isArray(enrichment.requiredHeadings)).toBe(true)
    }
  })

  it('should have correct enrichment names', () => {
    const expectedNames = [
      'File Locations',
      'Effort Estimation',
      'Complexity Classification',
      'Acceptance Criteria',
      'Regression Risk (5 Dimensions)',
      'Implementation Steps',
      'Code Examples',
      'File Change Scope (3 Categories)',
      'Testing Table',
      'Dependencies and Blocking',
    ]

    for (const [index, enrichment] of REQUIRED_ENRICHMENTS.entries()) {
      expect(enrichment.name).toBe(expectedNames[index])
    }
  })

  describe('Enrichment #1: File Locations', () => {
    it('should require **Location:** field', () => {
      const enrichment = REQUIRED_ENRICHMENTS[0]
      expect(enrichment.requiredFields).toContain('**Location:**')
      expect(enrichment.requiredHeadings).toHaveLength(0)
    })
  })

  describe('Enrichment #2: Effort Estimation', () => {
    it('should require **Estimated Effort:** field', () => {
      const enrichment = REQUIRED_ENRICHMENTS[1]
      expect(enrichment.requiredFields).toContain('**Estimated Effort:**')
      expect(enrichment.requiredHeadings).toHaveLength(0)
    })
  })

  describe('Enrichment #3: Complexity Classification', () => {
    it('should require **Complexity:** field', () => {
      const enrichment = REQUIRED_ENRICHMENTS[2]
      expect(enrichment.requiredFields).toContain('**Complexity:**')
      expect(enrichment.requiredHeadings).toHaveLength(0)
    })
  })

  describe('Enrichment #4: Acceptance Criteria', () => {
    it('should require heading and field', () => {
      const enrichment = REQUIRED_ENRICHMENTS[3]
      expect(enrichment.requiredHeadings).toContain('## Acceptance Criteria')
      expect(enrichment.requiredFields).toContain('**Acceptance Criteria:**')
    })
  })

  describe('Enrichment #5: Regression Risk (5 Dimensions)', () => {
    it('should require heading and all 6 fields (parent + 5 dimensions)', () => {
      const enrichment = REQUIRED_ENRICHMENTS[4]
      expect(enrichment.requiredHeadings).toContain('## Regression Risk Analysis')
      expect(enrichment.requiredFields).toContain('**Regression Risk Details:**')
      expect(enrichment.requiredFields).toContain('**Impact:**')
      expect(enrichment.requiredFields).toContain('**Blast Radius:**')
      expect(enrichment.requiredFields).toContain('**Dependencies:**')
      expect(enrichment.requiredFields).toContain('**Testing Gaps:**')
      expect(enrichment.requiredFields).toContain('**Rollback Risk:**')
      // Total: 6 fields + 1 heading
      expect(enrichment.requiredFields).toHaveLength(6)
      expect(enrichment.requiredHeadings).toHaveLength(1)
    })
  })

  describe('Enrichment #6: Implementation Steps', () => {
    it('should require heading and field', () => {
      const enrichment = REQUIRED_ENRICHMENTS[5]
      expect(enrichment.requiredHeadings).toContain('## Implementation Plan')
      expect(enrichment.requiredFields).toContain('**Implementation Steps:**')
    })
  })

  describe('Enrichment #7: Code Examples', () => {
    it('should require heading only (code blocks are structure)', () => {
      const enrichment = REQUIRED_ENRICHMENTS[6]
      expect(enrichment.requiredHeadings).toContain('## Code Examples')
      expect(enrichment.requiredFields).toHaveLength(0)
    })
  })

  describe('Enrichment #8: File Change Scope (3 Categories)', () => {
    it('should require heading and all 3 category fields', () => {
      const enrichment = REQUIRED_ENRICHMENTS[7]
      expect(enrichment.requiredHeadings).toContain('## File Changes')
      expect(enrichment.requiredFields).toContain('**Files to Create:**')
      expect(enrichment.requiredFields).toContain('**Files to Modify:**')
      expect(enrichment.requiredFields).toContain('**Files to Delete:**')
      expect(enrichment.requiredFields).toHaveLength(3)
      expect(enrichment.requiredHeadings).toHaveLength(1)
    })
  })

  describe('Enrichment #9: Testing Table', () => {
    it('should require heading and field', () => {
      const enrichment = REQUIRED_ENRICHMENTS[8]
      expect(enrichment.requiredHeadings).toContain('## Testing Requirements')
      expect(enrichment.requiredFields).toContain('**Required Testing:**')
    })
  })

  describe('Enrichment #10: Dependencies and Blocking', () => {
    it('should require heading and all 3 dependency fields', () => {
      const enrichment = REQUIRED_ENRICHMENTS[9]
      expect(enrichment.requiredHeadings).toContain('## Dependencies')
      expect(enrichment.requiredFields).toContain('**Blocking Dependencies:**')
      expect(enrichment.requiredFields).toContain('**Blocks:**')
      expect(enrichment.requiredFields).toContain('**Prerequisites:**')
      expect(enrichment.requiredFields).toHaveLength(3)
      expect(enrichment.requiredHeadings).toHaveLength(1)
    })
  })
})

describe('validateTemplateHasAllEnrichments()', () => {
  describe('with valid template (all 10 enrichments present)', () => {
    it('should return passed: true and empty missing array', () => {
      const validTemplate = `
---
templateName: bug-findings
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

      const result = validateTemplateHasAllEnrichments(validTemplate)
      expect(result.passed).toBe(true)
      expect(result.missing).toHaveLength(0)
    })
  })

  describe('with missing enrichment field', () => {
    it('should detect missing **Location:** field (Enrichment #1)', () => {
      const invalidTemplate = `
## Core Metadata

**Component:**
**Estimated Effort:**
**Complexity:**
`

      const result = validateTemplateHasAllEnrichments(invalidTemplate)
      expect(result.passed).toBe(false)
      expect(result.missing.length).toBeGreaterThan(0)

      const locationError = result.missing.find((msg) => msg.includes('Enrichment #1'))
      expect(locationError).toBeDefined()
      expect(locationError).toContain('File Locations')
      expect(locationError).toContain('**Location:**')
    })

    it('should detect missing **Estimated Effort:** field (Enrichment #2)', () => {
      const invalidTemplate = `
## Core Metadata

**Component:**
**Location:**
**Complexity:**
`

      const result = validateTemplateHasAllEnrichments(invalidTemplate)
      expect(result.passed).toBe(false)

      const effortError = result.missing.find((msg) => msg.includes('Enrichment #2'))
      expect(effortError).toBeDefined()
      expect(effortError).toContain('Effort Estimation')
      expect(effortError).toContain('**Estimated Effort:**')
    })
  })

  describe('with missing enrichment heading', () => {
    it('should detect missing ## Acceptance Criteria heading (Enrichment #4)', () => {
      const invalidTemplate = `
## Core Metadata

**Location:**
**Estimated Effort:**
**Complexity:**

**Acceptance Criteria:**
- [ ]
`

      const result = validateTemplateHasAllEnrichments(invalidTemplate)
      expect(result.passed).toBe(false)

      const headingError = result.missing.find(
        (msg) => msg.includes('Enrichment #4') && msg.includes('## Acceptance Criteria')
      )
      expect(headingError).toBeDefined()
      expect(headingError).toContain('Acceptance Criteria')
      expect(headingError).toContain('heading')
    })
  })

  describe('with missing Enrichment #5 dimension', () => {
    it('should detect missing **Blast Radius:** field', () => {
      const invalidTemplate = `
## Regression Risk Analysis

**Regression Risk Details:**
- **Impact:**
- **Dependencies:**
- **Testing Gaps:**
- **Rollback Risk:**
`

      const result = validateTemplateHasAllEnrichments(invalidTemplate)
      expect(result.passed).toBe(false)

      const blastRadiusError = result.missing.find(
        (msg) => msg.includes('Enrichment #5') && msg.includes('**Blast Radius:**')
      )
      expect(blastRadiusError).toBeDefined()
      expect(blastRadiusError).toContain('Regression Risk')
      expect(blastRadiusError).toContain('**Blast Radius:**')
    })

    it('should detect missing **Regression Risk Details:** parent field', () => {
      const invalidTemplate = `
## Regression Risk Analysis

- **Impact:**
- **Blast Radius:**
- **Dependencies:**
- **Testing Gaps:**
- **Rollback Risk:**
`

      const result = validateTemplateHasAllEnrichments(invalidTemplate)
      expect(result.passed).toBe(false)

      const parentFieldError = result.missing.find(
        (msg) => msg.includes('Enrichment #5') && msg.includes('**Regression Risk Details:**')
      )
      expect(parentFieldError).toBeDefined()
    })

    it('should detect missing ## Regression Risk Analysis heading', () => {
      const invalidTemplate = `
**Regression Risk Details:**
- **Impact:**
- **Blast Radius:**
- **Dependencies:**
- **Testing Gaps:**
- **Rollback Risk:**
`

      const result = validateTemplateHasAllEnrichments(invalidTemplate)
      expect(result.passed).toBe(false)

      const headingError = result.missing.find(
        (msg) => msg.includes('Enrichment #5') && msg.includes('## Regression Risk Analysis')
      )
      expect(headingError).toBeDefined()
    })
  })

  describe('with missing Enrichment #8 category', () => {
    it('should detect missing **Files to Delete:** field', () => {
      const invalidTemplate = `
## File Changes

**Files to Create:**
-

**Files to Modify:**
-
`

      const result = validateTemplateHasAllEnrichments(invalidTemplate)
      expect(result.passed).toBe(false)

      const deleteError = result.missing.find(
        (msg) => msg.includes('Enrichment #8') && msg.includes('**Files to Delete:**')
      )
      expect(deleteError).toBeDefined()
      expect(deleteError).toContain('File Change Scope')
      expect(deleteError).toContain('**Files to Delete:**')
    })

    it('should detect all missing categories', () => {
      const invalidTemplate = `
## File Changes

**Files to Create:**
-
`

      const result = validateTemplateHasAllEnrichments(invalidTemplate)
      expect(result.passed).toBe(false)

      const enrichment8Errors = result.missing.filter((msg) => msg.includes('Enrichment #8'))
      expect(enrichment8Errors.length).toBeGreaterThanOrEqual(2)
      expect(enrichment8Errors.some((msg) => msg.includes('**Files to Modify:**'))).toBe(true)
      expect(enrichment8Errors.some((msg) => msg.includes('**Files to Delete:**'))).toBe(true)
    })
  })

  describe('return type and structure', () => {
    it('should return object with passed and missing properties', () => {
      const result = validateTemplateHasAllEnrichments('')
      expect(result).toHaveProperty('passed')
      expect(result).toHaveProperty('missing')
      expect(typeof result.passed).toBe('boolean')
      expect(Array.isArray(result.missing)).toBe(true)
    })

    it('should include enrichment number in error messages', () => {
      const invalidTemplate = `
## Core Metadata
`

      const result = validateTemplateHasAllEnrichments(invalidTemplate)
      expect(result.passed).toBe(false)

      for (const msg of result.missing) {
        expect(msg).toMatch(/Enrichment #\d+/)
      }
    })

    it('should include enrichment name in error messages', () => {
      const invalidTemplate = `
## Core Metadata
`

      const result = validateTemplateHasAllEnrichments(invalidTemplate)
      expect(result.passed).toBe(false)

      const expectedNames = [
        'File Locations',
        'Effort Estimation',
        'Complexity Classification',
        'Acceptance Criteria',
        'Regression Risk',
        'Implementation Steps',
        'Code Examples',
        'File Change Scope',
        'Testing Table',
        'Dependencies',
      ]

      const hasExpectedNames = result.missing.some((msg) => expectedNames.some((name) => msg.includes(name)))
      expect(hasExpectedNames).toBe(true)
    })

    it('should include exact missing field name in error messages', () => {
      const invalidTemplate = `
## Core Metadata

**Estimated Effort:**
**Complexity:**
`

      const result = validateTemplateHasAllEnrichments(invalidTemplate)
      expect(result.passed).toBe(false)

      const locationError = result.missing.find((msg) => msg.includes('**Location:**'))
      expect(locationError).toBeDefined()
      expect(locationError).toContain('"**Location:**"')
    })
  })

  describe('with completely empty template', () => {
    it('should detect all missing enrichments', () => {
      const result = validateTemplateHasAllEnrichments('')
      expect(result.passed).toBe(false)
      expect(result.missing.length).toBeGreaterThan(10) // Many fields missing

      // Check that all 10 enrichment IDs are represented
      for (let i = 1; i <= 10; i++) {
        const hasEnrichmentError = result.missing.some((msg) => msg.includes(`Enrichment #${i}`))
        expect(hasEnrichmentError).toBe(true)
      }
    })
  })
})
