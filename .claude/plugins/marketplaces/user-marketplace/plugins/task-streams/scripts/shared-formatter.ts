#!/usr/bin/env tsx
/**
 * shared-formatter CLI
 *
 * Validates, formats, and parses task frontmatter
 *
 * Usage:
 *   # Validate frontmatter in a task file
 *   pnpm tsx shared-formatter.ts --validate --file=tasks/T0123.md
 *
 *   # Format/fix frontmatter in a task file
 *   pnpm tsx shared-formatter.ts --format --file=tasks/T0123.md
 *
 *   # Parse and display frontmatter as JSON
 *   pnpm tsx shared-formatter.ts --parse --file=tasks/T0123.md
 *
 *   # Generate new frontmatter template
 *   pnpm tsx shared-formatter.ts --generate --title="Fix bug" --priority=P1 --component=C05 --source=docs/review.md
 */

import { readFileSync, writeFileSync } from "fs";
import { parse as parseYAML, stringify as stringifyYAML } from "yaml";

// Type definitions
interface TaskFrontmatter {
  id: string;
  title: string;
  priority: "P0" | "P1" | "P2" | "P3";
  component: string;
  status: "READY" | "IN_PROGRESS" | "BLOCKED" | "DONE";
  created: string;
  source: string;
}

interface ValidationResult {
  valid: boolean;
  errors: string[];
  warnings: string[];
}

// Constants
const PRIORITY_LEVELS = ["P0", "P1", "P2", "P3"] as const;
const STATUS_VALUES = ["READY", "IN_PROGRESS", "BLOCKED", "DONE"] as const;
const TASK_ID_REGEX = /^T\d{4}$/;
const COMPONENT_CODE_REGEX = /^C\d{2}$/;
const ISO_8601_REGEX = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{3})?Z$/;

/**
 * Extract frontmatter from a markdown file
 */
function extractFrontmatter(content: string): { frontmatter: string; body: string } | null {
  const frontmatterRegex = /^---\n([\s\S]*?)\n---\n([\s\S]*)$/;
  const match = content.match(frontmatterRegex);

  if (!match) {
    return null;
  }

  return {
    frontmatter: match[1],
    body: match[2],
  };
}

/**
 * Validate a task ID
 */
function validateTaskId(id: string): { valid: boolean; error?: string } {
  if (!id) {
    return { valid: false, error: "Task ID is required" };
  }

  if (!TASK_ID_REGEX.test(id)) {
    return {
      valid: false,
      error: `Invalid task ID format: "${id}". Must match T#### (e.g., T0001, T0123)`,
    };
  }

  return { valid: true };
}

/**
 * Validate a priority level
 */
function validatePriority(priority: string): { valid: boolean; error?: string } {
  if (!priority) {
    return { valid: false, error: "Priority is required" };
  }

  if (!PRIORITY_LEVELS.includes(priority as any)) {
    return {
      valid: false,
      error: `Invalid priority: "${priority}". Must be one of: ${PRIORITY_LEVELS.join(", ")}`,
    };
  }

  return { valid: true };
}

/**
 * Validate a component code
 */
function validateComponent(component: string): { valid: boolean; error?: string } {
  if (!component) {
    return { valid: false, error: "Component is required" };
  }

  if (!COMPONENT_CODE_REGEX.test(component)) {
    return {
      valid: false,
      error: `Invalid component code format: "${component}". Must match C## (e.g., C00, C05, C12)`,
    };
  }

  return { valid: true };
}

/**
 * Validate a status value
 */
function validateStatus(status: string): { valid: boolean; error?: string } {
  if (!status) {
    return { valid: false, error: "Status is required" };
  }

  if (!STATUS_VALUES.includes(status as any)) {
    return {
      valid: false,
      error: `Invalid status: "${status}". Must be one of: ${STATUS_VALUES.join(", ")}`,
    };
  }

  return { valid: true };
}

/**
 * Validate an ISO 8601 timestamp
 */
function validateTimestamp(timestamp: string): { valid: boolean; error?: string } {
  if (!timestamp) {
    return { valid: false, error: "Created timestamp is required" };
  }

  if (!ISO_8601_REGEX.test(timestamp)) {
    return {
      valid: false,
      error: `Invalid timestamp format: "${timestamp}". Must be ISO 8601 with UTC (e.g., 2025-11-07T10:30:00Z)`,
    };
  }

  // Additional validation: check if it's a valid date
  const date = new Date(timestamp);
  if (isNaN(date.getTime())) {
    return {
      valid: false,
      error: `Invalid date: "${timestamp}"`,
    };
  }

  return { valid: true };
}

/**
 * Validate task frontmatter
 */
function validateFrontmatter(frontmatter: any): ValidationResult {
  const errors: string[] = [];
  const warnings: string[] = [];

  // Validate required fields exist
  const requiredFields = ["id", "title", "priority", "component", "status", "created", "source"];
  for (const field of requiredFields) {
    if (!(field in frontmatter)) {
      errors.push(`Missing required field: ${field}`);
    }
  }

  // If we have errors from missing fields, return early
  if (errors.length > 0) {
    return { valid: false, errors, warnings };
  }

  // Validate each field
  const idResult = validateTaskId(frontmatter.id);
  if (!idResult.valid) errors.push(idResult.error!);

  const priorityResult = validatePriority(frontmatter.priority);
  if (!priorityResult.valid) errors.push(priorityResult.error!);

  const componentResult = validateComponent(frontmatter.component);
  if (!componentResult.valid) errors.push(componentResult.error!);

  const statusResult = validateStatus(frontmatter.status);
  if (!statusResult.valid) errors.push(statusResult.error!);

  const timestampResult = validateTimestamp(frontmatter.created);
  if (!timestampResult.valid) errors.push(timestampResult.error!);

  // Validate title
  if (!frontmatter.title || frontmatter.title.trim() === "") {
    errors.push("Title cannot be empty");
  } else if (frontmatter.title.length > 100) {
    warnings.push("Title is longer than 100 characters, consider shortening");
  }

  // Validate source
  if (!frontmatter.source || frontmatter.source.trim() === "") {
    errors.push("Source path cannot be empty");
  }

  // Check for extra fields
  const knownFields = new Set(requiredFields);
  for (const field in frontmatter) {
    if (!knownFields.has(field)) {
      warnings.push(`Unknown field in frontmatter: ${field}`);
    }
  }

  return {
    valid: errors.length === 0,
    errors,
    warnings,
  };
}

/**
 * Format frontmatter to proper structure
 */
function formatFrontmatter(frontmatter: Partial<TaskFrontmatter>): string {
  // Ensure proper field order
  const ordered: Partial<TaskFrontmatter> = {};

  if (frontmatter.id) ordered.id = frontmatter.id;
  if (frontmatter.title) ordered.title = frontmatter.title;
  if (frontmatter.priority) ordered.priority = frontmatter.priority;
  if (frontmatter.component) ordered.component = frontmatter.component;
  if (frontmatter.status) ordered.status = frontmatter.status;
  if (frontmatter.created) ordered.created = frontmatter.created;
  if (frontmatter.source) ordered.source = frontmatter.source;

  // Convert to YAML with proper formatting
  const yaml = stringifyYAML(ordered, {
    lineWidth: 0, // Don't wrap lines
    defaultStringType: "PLAIN", // Don't quote simple strings
  });

  return `---\n${yaml.trim()}\n---`;
}

/**
 * Generate a new timestamp in ISO 8601 format (without milliseconds for cleaner output)
 */
function generateTimestamp(): string {
  const now = new Date();
  const year = now.getUTCFullYear();
  const month = String(now.getUTCMonth() + 1).padStart(2, "0");
  const day = String(now.getUTCDate()).padStart(2, "0");
  const hours = String(now.getUTCHours()).padStart(2, "0");
  const minutes = String(now.getUTCMinutes()).padStart(2, "0");
  const seconds = String(now.getUTCSeconds()).padStart(2, "0");

  return `${year}-${month}-${day}T${hours}:${minutes}:${seconds}Z`;
}

/**
 * Generate new frontmatter with defaults
 */
function generateFrontmatter(options: {
  id?: string;
  title: string;
  priority: string;
  component: string;
  status?: string;
  source: string;
}): TaskFrontmatter {
  return {
    id: options.id || "T0000", // Placeholder, should be generated by id-generator
    title: options.title,
    priority: options.priority as any,
    component: options.component,
    status: (options.status as any) || "READY",
    created: generateTimestamp(),
    source: options.source,
  };
}

/**
 * Parse a task file and return frontmatter
 */
function parseTaskFile(filePath: string): TaskFrontmatter | null {
  try {
    const content = readFileSync(filePath, "utf-8");
    const extracted = extractFrontmatter(content);

    if (!extracted) {
      console.error("Error: No frontmatter found in file");
      return null;
    }

    const frontmatter = parseYAML(extracted.frontmatter);
    return frontmatter as TaskFrontmatter;
  } catch (error) {
    console.error("Error reading file:", error instanceof Error ? error.message : String(error));
    return null;
  }
}

/**
 * Format a task file
 */
function formatTaskFile(filePath: string): boolean {
  try {
    const content = readFileSync(filePath, "utf-8");
    const extracted = extractFrontmatter(content);

    if (!extracted) {
      console.error("Error: No frontmatter found in file");
      return false;
    }

    const frontmatter = parseYAML(extracted.frontmatter);
    const formatted = formatFrontmatter(frontmatter);

    // Reconstruct the file
    const newContent = `${formatted}\n${extracted.body}`;

    // Write back to file
    writeFileSync(filePath, newContent, "utf-8");
    console.log("✓ File formatted successfully");
    return true;
  } catch (error) {
    console.error("Error formatting file:", error instanceof Error ? error.message : String(error));
    return false;
  }
}

/**
 * Validate a task file
 */
function validateTaskFile(filePath: string): boolean {
  const frontmatter = parseTaskFile(filePath);

  if (!frontmatter) {
    return false;
  }

  const result = validateFrontmatter(frontmatter);

  if (result.errors.length > 0) {
    console.error("✗ Validation failed:");
    result.errors.forEach((error) => console.error(`  - ${error}`));
  }

  if (result.warnings.length > 0) {
    console.warn("\n⚠ Warnings:");
    result.warnings.forEach((warning) => console.warn(`  - ${warning}`));
  }

  if (result.valid && result.warnings.length === 0) {
    console.log("✓ Frontmatter is valid");
  } else if (result.valid) {
    console.log("✓ Frontmatter is valid (with warnings)");
  }

  return result.valid;
}

/**
 * Show usage information
 */
function showUsage() {
  console.log(`
Task Frontmatter Formatter

Usage:
  pnpm tsx shared-formatter.ts --validate --file=<path>
  pnpm tsx shared-formatter.ts --format --file=<path>
  pnpm tsx shared-formatter.ts --parse --file=<path>
  pnpm tsx shared-formatter.ts --generate --title="..." --priority=P# --component=C## --source="..."
  pnpm tsx shared-formatter.ts --help

Operations:
  --validate    Validate frontmatter in a task file
  --format      Format/fix frontmatter in a task file
  --parse       Parse and display frontmatter as JSON
  --generate    Generate new frontmatter template

Options:
  --file=PATH           Path to task file (required for validate/format/parse)
  --title=TEXT          Task title (required for generate)
  --priority=P#         Priority level: P0, P1, P2, P3 (required for generate)
  --component=C##       Component code (required for generate)
  --status=STATUS       Status: READY, IN_PROGRESS, BLOCKED, DONE (default: READY)
  --source=PATH         Source document path (required for generate)
  --help                Show this help message

Examples:
  # Validate a task file
  pnpm tsx shared-formatter.ts --validate --file=tasks/T0123.md

  # Format a task file
  pnpm tsx shared-formatter.ts --format --file=tasks/T0123.md

  # Parse frontmatter
  pnpm tsx shared-formatter.ts --parse --file=tasks/T0123.md

  # Generate new frontmatter
  pnpm tsx shared-formatter.ts --generate --title="Fix auth bug" --priority=P1 --component=C05 --source=docs/review.md
`);
}

/**
 * Main CLI entry point
 */
async function main() {
  const args = process.argv.slice(2);

  if (args.length === 0 || args.includes("--help")) {
    showUsage();
    process.exit(args.includes("--help") ? 0 : 1);
  }

  // Parse arguments
  const options: Record<string, string> = {};
  const operations: string[] = [];

  for (const arg of args) {
    if (arg.startsWith("--")) {
      const [key, value] = arg.substring(2).split("=");
      if (value) {
        options[key] = value;
      } else {
        operations.push(key);
      }
    }
  }

  try {
    // Handle operations
    if (operations.includes("validate")) {
      if (!options.file) {
        console.error("Error: --file is required for --validate");
        process.exit(1);
      }
      const valid = validateTaskFile(options.file);
      process.exit(valid ? 0 : 1);
    } else if (operations.includes("format")) {
      if (!options.file) {
        console.error("Error: --file is required for --format");
        process.exit(1);
      }
      const success = formatTaskFile(options.file);
      process.exit(success ? 0 : 1);
    } else if (operations.includes("parse")) {
      if (!options.file) {
        console.error("Error: --file is required for --parse");
        process.exit(1);
      }
      const frontmatter = parseTaskFile(options.file);
      if (frontmatter) {
        console.log(JSON.stringify(frontmatter, null, 2));
        process.exit(0);
      } else {
        process.exit(1);
      }
    } else if (operations.includes("generate")) {
      const required = ["title", "priority", "component", "source"];
      const missing = required.filter((field) => !options[field]);

      if (missing.length > 0) {
        console.error(`Error: Missing required fields: ${missing.join(", ")}`);
        process.exit(1);
      }

      const frontmatter = generateFrontmatter({
        title: options.title,
        priority: options.priority,
        component: options.component,
        status: options.status,
        source: options.source,
      });

      // Validate the generated frontmatter
      const validation = validateFrontmatter(frontmatter);
      if (!validation.valid) {
        console.error("Error: Generated frontmatter is invalid:");
        validation.errors.forEach((error) => console.error(`  - ${error}`));
        process.exit(1);
      }

      // Output formatted frontmatter
      console.log(formatFrontmatter(frontmatter));
      process.exit(0);
    } else {
      console.error("Error: Unknown operation. Use --validate, --format, --parse, or --generate");
      showUsage();
      process.exit(1);
    }
  } catch (error) {
    console.error("Error:", error instanceof Error ? error.message : String(error));
    process.exit(1);
  }
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}

// Export functions for use as a library
export {
  validateFrontmatter,
  formatFrontmatter,
  generateFrontmatter,
  generateTimestamp,
  parseTaskFile,
  validateTaskFile,
  formatTaskFile,
  extractFrontmatter,
  validateTaskId,
  validatePriority,
  validateComponent,
  validateStatus,
  validateTimestamp,
};

export type { TaskFrontmatter, ValidationResult };
