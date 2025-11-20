#!/usr/bin/env tsx

/**
 * CLI tool to validate all template files contain the required 10 enrichments
 *
 * Usage:
 *   pnpm tsx validate-templates.ts [templates-directory]
 *
 * Exit codes:
 *   0 - All templates valid
 *   1 - One or more templates invalid
 */

import { readdirSync, readFileSync, existsSync } from 'node:fs'
import { join } from 'node:path'
import { validateTemplateHasAllEnrichments } from './template-enrichment-validator.js'

const TEMPLATES_DIR =
  process.argv[2] || join(process.cwd(), '.claude-plugins/task-streams/templates')

interface TemplateValidationResult {
  filename: string
  passed: boolean
  missing: string[]
}

function validateAllTemplates(templatesDir: string): {
  results: TemplateValidationResult[]
  allPassed: boolean
} {
  if (!existsSync(templatesDir)) {
    console.error(`Error: Templates directory not found: ${templatesDir}`)
    process.exit(1)
  }

  const files = readdirSync(templatesDir).filter((f) => f.endsWith('.template.md'))

  if (files.length === 0) {
    console.log(`No templates found in ${templatesDir}`)
    return { results: [], allPassed: true }
  }

  const results: TemplateValidationResult[] = []

  for (const filename of files) {
    const filepath = join(templatesDir, filename)
    const content = readFileSync(filepath, 'utf-8')
    const validation = validateTemplateHasAllEnrichments(content)

    results.push({
      filename,
      passed: validation.passed,
      missing: validation.missing,
    })
  }

  const allPassed = results.every((r) => r.passed)

  return { results, allPassed }
}

function printResults(results: TemplateValidationResult[]): void {
  console.log('\n=== Template Validation ===\n')

  if (results.length === 0) {
    return
  }

  for (const result of results) {
    const icon = result.passed ? '✅' : '❌'
    const status = result.passed ? 'All enrichments present' : 'Missing enrichments'

    console.log(`${icon} ${result.filename} - ${status}`)

    if (!result.passed && result.missing.length > 0) {
      console.log('  Missing:')
      for (const missing of result.missing) {
        console.log(`    - ${missing}`)
      }
      console.log()
    }
  }
}

function main(): void {
  const { results, allPassed } = validateAllTemplates(TEMPLATES_DIR)

  printResults(results)

  if (!allPassed) {
    console.log(
      `❌ Validation failed: ${results.filter((r) => !r.passed).length} template(s) missing required enrichments\n`
    )
    process.exit(1)
  } else if (results.length > 0) {
    console.log(`✅ All ${results.length} template(s) passed validation\n`)
  }

  process.exit(0)
}

main()
