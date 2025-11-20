#!/usr/bin/env bun

/**
 * Component Manager - Manage component registry for task categorization
 *
 * Usage:
 *   bun manage.ts --list                      # Show component map
 *   bun manage.ts --list --json               # JSON output
 *   bun manage.ts --find="Service Factory"    # Output: C02 (exit 0) or exit 1
 *   bun manage.ts --add="API Gateway"         # Output: C09 (creates new)
 *
 * Configuration:
 *   Single state file: .claude/state/task-streams/component-manager.json (gitignored)
 *   Initialized with C00 "General / Cross-Cutting" on first use
 */

import { existsSync, readFileSync, writeFileSync, mkdirSync } from 'fs'
import { join } from 'path'
import { execSync } from 'child_process'

interface Config {
  componentPadding: number
  components: Record<string, string>
}

/**
 * Get state directory using CLAUDE_PROJECT_DIR or current working directory + .claude/state/task-streams/
 *
 * Priority order:
 * 1. CLAUDE_PROJECT_DIR env var (set by Claude Code for hooks)
 * 2. Current working directory (where Claude Code runs Task agents - this is the project directory)
 *
 * This ensures state is always project-specific, not stored in the plugin's directory.
 */
function getStateDir(): string {
  // Priority 1: Use CLAUDE_PROJECT_DIR if set (for hooks)
  const projectDir = process.env.CLAUDE_PROJECT_DIR
  if (projectDir) {
    const stateDir = join(projectDir, '.claude/state/task-streams')
    if (!existsSync(stateDir)) {
      mkdirSync(stateDir, { recursive: true })
    }
    return stateDir
  }

  // Priority 2: Use current working directory (Task agents run in project context)
  // This is the project directory when called from Claude Code
  const stateDir = join(process.cwd(), '.claude/state/task-streams')
  if (!existsSync(stateDir)) {
    mkdirSync(stateDir, { recursive: true })
  }
  return stateDir

  // Note: Git root fallback removed because it caused issues when the plugin
  // itself is in a git repo (e.g., dotfiles). The current working directory
  // is always the correct project directory when called from Claude Code.
}

const STATE_DIR = getStateDir()
const STATE_FILE = join(STATE_DIR, 'component-manager.json')

/**
 * Load config - creates default with C00 on first use
 */
function loadConfig(): Config {
  if (!existsSync(STATE_FILE)) {
    // Initialize with single default component
    const defaultConfig: Config = {
      componentPadding: 2,
      components: {
        C00: 'General / Cross-Cutting',
      },
    }
    writeFileSync(STATE_FILE, JSON.stringify(defaultConfig, null, 2))
    return defaultConfig
  }

  return JSON.parse(readFileSync(STATE_FILE, 'utf-8'))
}

/**
 * Save config
 */
function saveConfig(config: Config): void {
  writeFileSync(STATE_FILE, JSON.stringify(config, null, 2))
}

/**
 * Show component map
 */
function showComponents(json: boolean = false): void {
  const config = loadConfig()

  if (json) {
    console.log(JSON.stringify(config.components))
  } else {
    console.log('Component Map:')
    console.log('=============')
    for (const [code, name] of Object.entries(config.components).sort()) {
      console.log(`${code}: ${name}`)
    }
  }
}

/**
 * Find component code by name
 */
function findComponent(name: string): void {
  const config = loadConfig()

  for (const [code, componentName] of Object.entries(config.components)) {
    if (
      componentName.toLowerCase() === name.toLowerCase() ||
      componentName.toLowerCase().includes(name.toLowerCase())
    ) {
      console.log(code)
      process.exit(0)
    }
  }

  // Not found
  process.exit(1)
}

/**
 * Add new component and return its code
 */
function addComponent(name: string): void {
  const config = loadConfig()

  // Check if component already exists
  for (const [code, componentName] of Object.entries(config.components)) {
    if (componentName.toLowerCase() === name.toLowerCase()) {
      console.error(`Component "${name}" already exists as ${code}`)
      process.exit(1)
    }
  }

  // Find next available component code
  const existingCodes = Object.keys(config.components)
    .map((code) => parseInt(code.replace('C', ''), 10))
    .filter((num) => !isNaN(num))

  const nextNum = existingCodes.length > 0 ? Math.max(...existingCodes) + 1 : 1
  const newCode = `C${nextNum.toString().padStart(config.componentPadding, '0')}`

  // Add new component
  config.components[newCode] = name

  // Save config
  saveConfig(config)

  console.log(newCode)
}

// Parse command line arguments
const args = process.argv.slice(2)
const flags = {
  list: false,
  find: '',
  add: '',
  json: false,
}

for (const arg of args) {
  if (arg.startsWith('--find=')) {
    flags.find = arg.split('=')[1]
  } else if (arg.startsWith('--add=')) {
    flags.add = arg.split('=')[1]
  } else if (arg === '--list') {
    flags.list = true
  } else if (arg === '--json') {
    flags.json = true
  }
}

// Main execution
if (flags.list) {
  showComponents(flags.json)
} else if (flags.find) {
  findComponent(flags.find)
} else if (flags.add) {
  addComponent(flags.add)
} else {
  console.error('Usage:')
  console.error('  bun manage.ts --list')
  console.error('  bun manage.ts --list --json')
  console.error('  bun manage.ts --find="Component Name"')
  console.error('  bun manage.ts --add="New Component"')
  process.exit(1)
}
