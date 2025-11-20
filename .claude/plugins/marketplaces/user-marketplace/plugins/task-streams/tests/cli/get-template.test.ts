/**
 * get-template CLI Tests
 *
 * Tests for the get-template.ts CLI script
 */

import { execSync } from 'node:child_process'
import { join } from 'node:path'

import { describe, it, expect } from 'vitest'

describe('get-template CLI', () => {
  const cliPath = join(__dirname, '../../scripts/get-template.ts')
  const cwd = join(__dirname, '../../../..')

  describe('Full template content', () => {
    it('should return full template markdown content', () => {
      const output = execSync(`pnpm tsx ${cliPath} bug-findings`, {
        encoding: 'utf-8',
        cwd,
      })

      // Should contain frontmatter
      expect(output).toContain('---')
      expect(output).toContain('templateName: bug-findings')
      expect(output).toContain('templateVersion:')
      expect(output).toContain('description:')
      expect(output).toContain('requiredEnrichments: 10')
      expect(output).toContain('formatSkill: format-bug-findings')

      // Should contain template structure
      expect(output).toContain('## Core Metadata')
      expect(output).toContain('**Component:**')
      expect(output).toContain('**Location:**')
      expect(output).toContain('## Regression Risk Analysis')
      expect(output).toContain('## Acceptance Criteria')
    })

    it('should work with different template names', () => {
      const templates = ['spec', 'tech-debt', 'security', 'generic']

      for (const name of templates) {
        const output = execSync(`pnpm tsx ${cliPath} ${name}`, {
          encoding: 'utf-8',
          cwd,
        })

        // Should contain corresponding frontmatter
        expect(output).toContain(`templateName: ${name}`)
      }
    })

    it('should support custom --dir flag', () => {
      const customDir = join(__dirname, '../../templates')

      const output = execSync(`pnpm tsx ${cliPath} bug-findings --dir=${customDir}`, {
        encoding: 'utf-8',
        cwd,
      })

      expect(output).toContain('templateName: bug-findings')
    })
  })

  describe('Metadata only mode', () => {
    it('should return metadata as JSON with --metadata-only flag', () => {
      const output = execSync(`pnpm tsx ${cliPath} bug-findings --metadata-only`, {
        encoding: 'utf-8',
        cwd,
      })

      // Should be valid JSON
      const metadata = JSON.parse(output)

      expect(metadata).toHaveProperty('templateName', 'bug-findings')
      expect(metadata).toHaveProperty('templateVersion')
      expect(metadata).toHaveProperty('description')
      expect(metadata).toHaveProperty('requiredEnrichments', 10)
      expect(metadata).toHaveProperty('formatSkill', 'format-bug-findings')
      expect(metadata).toHaveProperty('path')

      // Should NOT contain full template content
      expect(output).not.toContain('## Core Metadata')
      expect(output).not.toContain('## Regression Risk Analysis')
    })

    it('should work with all templates in metadata mode', () => {
      const templates = ['bug-findings', 'spec', 'tech-debt', 'security', 'generic']

      for (const name of templates) {
        const output = execSync(`pnpm tsx ${cliPath} ${name} --metadata-only`, {
          encoding: 'utf-8',
          cwd,
        })

        const metadata = JSON.parse(output)
        expect(metadata.templateName).toBe(name)
      }
    })
  })

  describe('Error handling', () => {
    it('should show usage when no template name provided', () => {
      try {
        execSync(`pnpm tsx ${cliPath}`, {
          encoding: 'utf-8',
          cwd,
          stdio: 'pipe',
        })
        // Should not reach here
        expect(true).toBe(false)
      } catch (error: any) {
        expect(error.status).toBe(1)
        expect(error.stderr).toContain('Usage:')
      }
    })

    it('should error on non-existent template', () => {
      try {
        execSync(`pnpm tsx ${cliPath} non-existent-template`, {
          encoding: 'utf-8',
          cwd,
          stdio: 'pipe',
        })
        // Should not reach here
        expect(true).toBe(false)
      } catch (error: any) {
        expect(error.status).toBe(1)
      }
    })
  })

  describe('Exit codes', () => {
    it('should exit with code 0 on success', () => {
      const result = execSync(`pnpm tsx ${cliPath} bug-findings`, {
        encoding: 'utf-8',
        cwd,
      })

      // No exception means exit code 0
      expect(result).toBeTruthy()
    })

    it('should exit with code 0 for metadata-only mode', () => {
      const result = execSync(`pnpm tsx ${cliPath} bug-findings --metadata-only`, {
        encoding: 'utf-8',
        cwd,
      })

      // No exception means exit code 0
      expect(result).toBeTruthy()
    })
  })

  describe('Output format', () => {
    it('should output raw markdown for full template', () => {
      const output = execSync(`pnpm tsx ${cliPath} bug-findings`, {
        encoding: 'utf-8',
        cwd,
      })

      // Should start with frontmatter delimiter
      expect(output.trim().startsWith('---')).toBe(true)

      // Should be markdown, not JSON
      expect(() => JSON.parse(output)).toThrow()
    })

    it('should output valid JSON for metadata-only', () => {
      const output = execSync(`pnpm tsx ${cliPath} bug-findings --metadata-only`, {
        encoding: 'utf-8',
        cwd,
      })

      // Should not throw when parsing
      expect(() => JSON.parse(output)).not.toThrow()

      // Should be JSON, not markdown
      expect(output.trim().startsWith('---')).toBe(false)
    })
  })
})
