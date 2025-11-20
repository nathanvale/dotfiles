#!/usr/bin/env bun

/**
 * ID Generator - Generates task IDs with rich metadata tracking
 *
 * Usage:
 *   bun generate.ts --task --source="docs/specs/feature.md"          # Generate T0001
 *   bun generate.ts --show                                            # Show state
 *   bun generate.ts --reset                                           # Reset counter
 *
 * State file: .claude/state/task-streams/id-generator.json (gitignored)
 * Tracks full metadata for every generated task ID
 */

import { existsSync, readFileSync, writeFileSync, mkdirSync } from 'fs'
import { join } from 'path'
import { execSync } from 'child_process'

interface IdMetadata {
  id: string
  created: string
  sourceDocument: string
  sourceType?: string // 'spec' | 'adr' | 'tech-debt' | 'security' | 'review' | 'generic'
  notes?: string
}

interface IdGeneratorState {
  paddingWidth: number
  counter: number
  history: IdMetadata[]
  reportCounter: number
  reportHistory: IdMetadata[]
  lastUpdated: string
}

/**
 * Get state directory using CLAUDE_PROJECT_DIR or current working directory + .claude/state/task-streams/
 *
 * Priority order:
 * 1. CLAUDE_PROJECT_DIR env var (set by Claude Code for hooks)
 * 2. Current working directory (where Claude Code runs Task agents - this is the project directory)
 * 3. Git root (fallback only if neither above work)
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
const STATE_FILE = join(STATE_DIR, 'id-generator.json')

/**
 * Load state - creates default on first use
 */
function loadState(): IdGeneratorState {
  if (!existsSync(STATE_FILE)) {
    const defaultState: IdGeneratorState = {
      paddingWidth: 4,
      counter: 0,
      history: [],
      reportCounter: 0,
      reportHistory: [],
      lastUpdated: new Date().toISOString(),
    }
    writeFileSync(STATE_FILE, JSON.stringify(defaultState, null, 2))
    return defaultState
  }
  const state = JSON.parse(readFileSync(STATE_FILE, 'utf-8'))
  // Backward compatibility: add report fields if missing
  if (!state.reportCounter) state.reportCounter = 0
  if (!state.reportHistory) state.reportHistory = []
  return state
}

/**
 * Save state
 */
function saveState(state: IdGeneratorState): void {
  state.lastUpdated = new Date().toISOString()
  writeFileSync(STATE_FILE, JSON.stringify(state, null, 2))
}

/**
 * Generate task ID with metadata
 */
function generateTaskId(sourceDocument: string, sourceType?: string, notes?: string): string {
  const state = loadState()

  // Increment counter
  state.counter++

  // Check limit
  const maxValue = Math.pow(10, state.paddingWidth) - 1
  if (state.counter > maxValue) {
    console.error(
      `Task counter exceeded maximum value (${maxValue}). Consider resetting or increasing padding width.`
    )
    process.exit(1)
  }

  // Generate ID
  const paddedNumber = state.counter.toString().padStart(state.paddingWidth, '0')
  const taskId = `T${paddedNumber}`

  // Store metadata
  const metadata: IdMetadata = {
    id: taskId,
    created: new Date().toISOString(),
    sourceDocument,
    sourceType,
    notes,
  }
  state.history.push(metadata)

  saveState(state)

  return taskId
}

/**
 * Generate report ID with metadata
 */
function generateReportId(sourceDocument: string, sourceType?: string, notes?: string): string {
  const state = loadState()

  // Increment report counter
  state.reportCounter++

  // Check limit
  const maxValue = Math.pow(10, state.paddingWidth) - 1
  if (state.reportCounter > maxValue) {
    console.error(
      `Report counter exceeded maximum value (${maxValue}). Consider resetting or increasing padding width.`
    )
    process.exit(1)
  }

  // Generate ID
  const paddedNumber = state.reportCounter.toString().padStart(state.paddingWidth, '0')
  const reportId = `R${paddedNumber}`

  // Store metadata
  const metadata: IdMetadata = {
    id: reportId,
    created: new Date().toISOString(),
    sourceDocument,
    sourceType,
    notes,
  }
  state.reportHistory.push(metadata)

  saveState(state)

  return reportId
}

/**
 * Show current state
 */
function showState(): void {
  const state = loadState()

  console.log('Task IDs:')
  console.log('=========')
  console.log(`Current counter: ${state.counter}`)
  console.log(`Next task ID: T${(state.counter + 1).toString().padStart(state.paddingWidth, '0')}`)
  console.log(`Total tasks: ${state.history.length}`)

  if (state.history.length > 0) {
    console.log('\nRecent tasks:')
    const recent = state.history.slice(-5).reverse()
    for (const task of recent) {
      console.log(`  ${task.id} - ${task.sourceDocument}`)
      if (task.sourceType) console.log(`    Type: ${task.sourceType}`)
      if (task.notes) console.log(`    Notes: ${task.notes}`)
      console.log(`    Created: ${task.created}`)
    }
  }

  console.log('')
  console.log('Report IDs:')
  console.log('===========')
  console.log(`Current counter: ${state.reportCounter}`)
  console.log(`Next report ID: R${(state.reportCounter + 1).toString().padStart(state.paddingWidth, '0')}`)
  console.log(`Total reports: ${state.reportHistory.length}`)

  if (state.reportHistory.length > 0) {
    console.log('\nRecent reports:')
    const recent = state.reportHistory.slice(-5).reverse()
    for (const report of recent) {
      console.log(`  ${report.id} - ${report.sourceDocument}`)
      if (report.sourceType) console.log(`    Type: ${report.sourceType}`)
      if (report.notes) console.log(`    Notes: ${report.notes}`)
      console.log(`    Created: ${report.created}`)
    }
  }

  console.log('')
  console.log(`Last updated: ${state.lastUpdated}`)
}

/**
 * Reset state
 */
function resetState(): void {
  const defaultState: IdGeneratorState = {
    paddingWidth: 4,
    counter: 0,
    history: [],
    reportCounter: 0,
    reportHistory: [],
    lastUpdated: new Date().toISOString(),
  }
  writeFileSync(STATE_FILE, JSON.stringify(defaultState, null, 2))
  console.log('State reset (task counter = 0, report counter = 0, all history cleared)')
}

// Parse command line arguments
const args = process.argv.slice(2)
const flags = {
  task: false,
  report: false,
  source: '',
  sourceType: '',
  notes: '',
  show: false,
  reset: false,
}

for (const arg of args) {
  if (arg === '--task') {
    flags.task = true
  } else if (arg === '--report') {
    flags.report = true
  } else if (arg.startsWith('--source=')) {
    flags.source = arg.split('=')[1]
  } else if (arg.startsWith('--source-type=')) {
    flags.sourceType = arg.split('=')[1]
  } else if (arg.startsWith('--notes=')) {
    flags.notes = arg.split('=')[1]
  } else if (arg === '--show') {
    flags.show = true
  } else if (arg === '--reset') {
    flags.reset = true
  }
}

// Main execution
if (flags.reset) {
  resetState()
} else if (flags.show) {
  showState()
} else if (flags.task) {
  if (!flags.source) {
    console.error('Error: --source required when generating task ID')
    console.error('Usage: bun generate.ts --task --source="docs/specs/spec.md"')
    process.exit(1)
  }
  const taskId = generateTaskId(flags.source, flags.sourceType, flags.notes)
  console.log(taskId)
} else if (flags.report) {
  if (!flags.source) {
    console.error('Error: --source required when generating report ID')
    console.error('Usage: bun generate.ts --report --source="docs/reports/bug-hunt.json"')
    process.exit(1)
  }
  const reportId = generateReportId(flags.source, flags.sourceType, flags.notes)
  console.log(reportId)
} else {
  console.error('Usage:')
  console.error('  Generate task ID:')
  console.error(
    '    bun generate.ts --task --source="docs/specs/spec.md" [--source-type=spec] [--notes="..."]'
  )
  console.error('')
  console.error('  Generate report ID:')
  console.error(
    '    bun generate.ts --report --source="docs/reports/report.json" [--source-type=review] [--notes="..."]'
  )
  console.error('')
  console.error('  Show state:')
  console.error('    bun generate.ts --show')
  console.error('')
  console.error('  Reset:')
  console.error('    bun generate.ts --reset             # Reset all counters and clear history')
  process.exit(1)
}
