#!/usr/bin/env tsx
/**
 * list-templates CLI
 *
 * Lists all available templates as JSON
 *
 * Usage:
 *   pnpm tsx .claude-plugins/task-streams/scripts/list-templates.ts [--dir=/path/to/templates]
 *
 * Output (JSON):
 *   [
 *     {
 *       "templateName": "bug-findings",
 *       "templateVersion": "1.0.0",
 *       "description": "Structure for enriched bug findings and code review issues",
 *       "requiredEnrichments": 10,
 *       "formatSkill": "format-bug-findings",
 *       "path": "/path/to/bug-findings.template.md"
 *     },
 *     ...
 *   ]
 */

import { TemplateRegistry } from "./template-registry.js";

async function main() {
  try {
    // Parse command line arguments
    const args = process.argv.slice(2);
    let templatesDir: string | undefined;

    for (const arg of args) {
      if (arg.startsWith("--dir=")) {
        templatesDir = arg.substring("--dir=".length);
      }
    }

    // List templates
    const templates = await TemplateRegistry.listTemplates(templatesDir);

    // Output as JSON
    console.log(JSON.stringify(templates, null, 2));

    process.exit(0);
  } catch (error) {
    console.error(
      "Error listing templates:",
      error instanceof Error ? error.message : String(error)
    );
    process.exit(1);
  }
}

main();
