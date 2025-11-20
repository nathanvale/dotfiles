/**
 * list-templates CLI Tests
 *
 * Tests for the list-templates.ts CLI script
 */

import { execSync } from 'node:child_process'
import { join } from 'node:path'

import { describe, it, expect } from 'vitest'

describe('list-templates CLI', () => {
  const cliPath = join(__dirname, '../../scripts/list-templates.ts')

  it('should list all templates as JSON', () => {
    const output = execSync(`pnpm tsx ${cliPath}`, {
      encoding: 'utf-8',
      cwd: join(__dirname, '../../../..'),
    })

    // Parse JSON output
    const templates = JSON.parse(output)

    // Should be an array
    expect(Array.isArray(templates)).toBe(true)

    // Should have 5 templates
    expect(templates).toHaveLength(5)

    // Check template names
    const templateNames = templates.map((t: any) => t.templateName)
    expect(templateNames).toContain('bug-findings')
    expect(templateNames).toContain('spec')
    expect(templateNames).toContain('tech-debt')
    expect(templateNames).toContain('security')
    expect(templateNames).toContain('generic')
  })

  it('should include all required fields in output', () => {
    const output = execSync(`pnpm tsx ${cliPath}`, {
      encoding: 'utf-8',
      cwd: join(__dirname, '../../../..'),
    })

    const templates = JSON.parse(output)

    for (const template of templates) {
      expect(template).toHaveProperty('templateName')
      expect(template).toHaveProperty('templateVersion')
      expect(template).toHaveProperty('description')
      expect(template).toHaveProperty('requiredEnrichments')
      expect(template).toHaveProperty('formatSkill')
      expect(template).toHaveProperty('path')

      // Verify types
      expect(typeof template.templateName).toBe('string')
      expect(typeof template.templateVersion).toBe('string')
      expect(typeof template.description).toBe('string')
      expect(typeof template.requiredEnrichments).toBe('number')
      expect(typeof template.formatSkill).toBe('string')
      expect(typeof template.path).toBe('string')

      // Verify requiredEnrichments is 10
      expect(template.requiredEnrichments).toBe(10)
    }
  })

  it('should support custom --dir flag', () => {
    const customDir = join(__dirname, '../../templates')

    const output = execSync(`pnpm tsx ${cliPath} --dir=${customDir}`, {
      encoding: 'utf-8',
      cwd: join(__dirname, '../../../..'),
    })

    const templates = JSON.parse(output)

    // Should still return 5 templates
    expect(templates).toHaveLength(5)
  })

  it('should output valid JSON', () => {
    const output = execSync(`pnpm tsx ${cliPath}`, {
      encoding: 'utf-8',
      cwd: join(__dirname, '../../../..'),
    })

    // Should not throw when parsing
    expect(() => JSON.parse(output)).not.toThrow()
  })

  it('should exit with code 0 on success', () => {
    const result = execSync(`pnpm tsx ${cliPath}`, {
      encoding: 'utf-8',
      cwd: join(__dirname, '../../../..'),
    })

    // No exception means exit code 0
    expect(result).toBeTruthy()
  })
})
