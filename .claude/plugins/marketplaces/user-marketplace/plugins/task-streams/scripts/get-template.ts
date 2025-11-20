#!/usr/bin/env tsx
/**
 * get-template CLI
 *
 * Gets template content or metadata
 *
 * Usage:
 *   # Get full template content
 *   pnpm tsx .claude-plugins/task-streams/scripts/get-template.ts <template-name> [--dir=/path/to/templates]
 *
 *   # Get metadata only
 *   pnpm tsx .claude-plugins/task-streams/scripts/get-template.ts <template-name> --metadata-only [--dir=/path/to/templates]
 *
 * Examples:
 *   pnpm tsx .claude-plugins/task-streams/scripts/get-template.ts bug-findings
 *   pnpm tsx .claude-plugins/task-streams/scripts/get-template.ts bug-findings --metadata-only
 *   pnpm tsx .claude-plugins/task-streams/scripts/get-template.ts spec --dir=./custom/templates
 */

import { TemplateRegistry } from './template-registry.js'

function showUsage() {
  console.error(
    'Usage: get-template.ts <template-name> [--metadata-only] [--dir=/path/to/templates]'
  )
  console.error('')
  console.error('Examples:')
  console.error('  pnpm tsx get-template.ts bug-findings')
  console.error('  pnpm tsx get-template.ts bug-findings --metadata-only')
  console.error('  pnpm tsx get-template.ts spec --dir=./custom/templates')
}

async function main() {
  try {
    // Parse command line arguments
    const args = process.argv.slice(2)

    if (args.length === 0) {
      showUsage()
      process.exit(1)
    }

    let templateName: string | undefined
    let metadataOnly = false
    let templatesDir: string | undefined

    for (const arg of args) {
      if (arg === '--metadata-only') {
        metadataOnly = true
      } else if (arg.startsWith('--dir=')) {
        templatesDir = arg.substring('--dir='.length)
      } else if (!arg.startsWith('--')) {
        // First non-flag argument is the template name
        templateName = arg
      }
    }

    if (!templateName) {
      console.error('Error: Template name is required')
      console.error('')
      showUsage()
      process.exit(1)
    }

    if (metadataOnly) {
      // Get metadata only and output as JSON
      const metadata = await TemplateRegistry.getTemplateMetadata(templateName, templatesDir)
      console.log(JSON.stringify(metadata, null, 2))
    } else {
      // Get full template content and output as markdown
      const content = await TemplateRegistry.getTemplate(templateName, templatesDir)
      console.log(content)
    }

    process.exit(0)
  } catch (error) {
    console.error('Error:', error instanceof Error ? error.message : String(error))
    process.exit(1)
  }
}

main()
