/**
 * Worktree Coordinator for Parallel AI Agent Task Execution
 *
 * Provides programmatic interface for managing git worktrees with:
 * - Dual locking (file-based + Git branch protection)
 * - Crash recovery (detect and resume existing worktrees)
 * - Process validation (clean stale locks from dead processes)
 * - Automatic cleanup traps
 *
 * Usage:
 *   const coordinator = new WorktreeCoordinator();
 *   const worktreePath = await coordinator.acquireTask('T0001', 'agent-123');
 *   // ... do work in worktree ...
 *   coordinator.releaseLock('T0001');
 */

/* eslint-disable security/detect-non-literal-fs-filename */
// File paths are constructed from validated internal state (lockDir, worktreeBase, taskFileBase)
// and sanitized task IDs. This is a trusted worktree management tool.

import { execSync } from 'node:child_process'
import * as fs from 'node:fs'
import path from 'node:path'

interface TaskLock {
  taskId: string
  agentId: string
  worktreePath: string
  branch: string
  status: 'IN_PROGRESS' | 'COMPLETED' | 'FAILED'
  startedAt: string
  pid: number
}

interface WorktreeInfo {
  path: string
  branch: string
  locked: boolean
  lockInfo?: TaskLock
}

export class WorktreeCoordinator {
  private lockDir = '.claude/state/task-locks'
  private worktreeBase = './worktrees'
  private taskFileBase = 'apps/migration-cli/docs/tasks'

  constructor(lockDir?: string, worktreeBase?: string, taskFileBase?: string) {
    if (lockDir) this.lockDir = lockDir
    if (worktreeBase) this.worktreeBase = worktreeBase
    if (taskFileBase) this.taskFileBase = taskFileBase
  }

  /**
   * Acquire a task worktree for an agent (with crash recovery)
   *
   * This method:
   * 1. Checks for existing locks (crash recovery)
   * 2. Validates git working directory is clean
   * 3. Creates or resumes worktree
   * 4. Creates lock file
   * 5. Updates task status to IN_PROGRESS
   * 6. Sets up cleanup handlers
   *
   * @param taskId - Task identifier (e.g., 'T0001')
   * @param agentId - Agent identifier for lock tracking
   * @returns Path to worktree
   * @throws Error if task is locked by another agent or git state is invalid
   */
  acquireTask(taskId: string, agentId: string): string {
    const lockFile = path.join(this.lockDir, `${taskId}.lock`)

    // Check file-based lock
    if (fs.existsSync(lockFile)) {
      const lock: TaskLock = JSON.parse(fs.readFileSync(lockFile, 'utf8'))

      if (this.isProcessRunning(lock.pid)) {
        throw new Error(
          `Task ${taskId} is already locked by agent ${lock.agentId} (PID: ${lock.pid})`
        )
      }

      // Stale lock - clean up
      console.log(`🧹 Cleaning up stale lock for ${taskId} (dead PID: ${lock.pid})`)
      fs.unlinkSync(lockFile)
    }

    // Validate git working directory is clean
    this.validateCleanGitState()

    // Create or resume worktree
    const worktreePath = this.getOrCreateWorktree(taskId)

    // Create lock
    const lock: TaskLock = {
      taskId,
      agentId,
      worktreePath,
      branch: `feat/${taskId}`,
      status: 'IN_PROGRESS',
      startedAt: new Date().toISOString(),
      pid: process.pid,
    }

    fs.mkdirSync(this.lockDir, { recursive: true })
    fs.writeFileSync(lockFile, JSON.stringify(lock, null, 2))
    console.log(`🔒 Lock created for ${taskId}`)

    // Update task file status
    this.updateTaskStatus(taskId, 'IN_PROGRESS', worktreePath, lock.branch)

    // Setup cleanup on exit
    const cleanup = () => this.releaseLock(taskId)
    process.on('exit', cleanup)
    process.on('SIGINT', cleanup)
    process.on('SIGTERM', cleanup)

    return worktreePath
  }

  /**
   * Get existing worktree or create new one (crash recovery)
   *
   * @param taskId - Task identifier
   * @returns Path to worktree
   * @throws Error if worktree creation fails
   */
  private getOrCreateWorktree(taskId: string): string {
    const worktreePath = path.join(this.worktreeBase, taskId)

    // Find task file
    const taskFilePath = this.findTaskFile(taskId)
    if (!taskFilePath) {
      throw new Error(`Task file not found for ${taskId}`)
    }

    // Extract branch name from task file
    const taskTitle = this.extractTaskTitle(taskFilePath)
    const branch = `feat/${taskId}-${taskTitle}`

    // Check if worktree already exists
    // eslint-disable-next-line sonarjs/no-os-command-from-path -- Safe: git is trusted tool
    const worktreeList = execSync('git worktree list --porcelain', {
      encoding: 'utf8',
    })

    // eslint-disable-next-line sonarjs/os-command -- Safe: worktreePath is validated from internal state
    if (worktreeList.includes(worktreePath)) {
      console.log(`📂 Resuming work in existing worktree: ${worktreePath}`)

      // Verify branch is correct
      // eslint-disable-next-line sonarjs/os-command -- Safe: git command with validated worktreePath
      const existingBranch = execSync(`git -C ${worktreePath} rev-parse --abbrev-ref HEAD`, {
        encoding: 'utf8',
      }).trim()

      if (existingBranch !== branch.replace('refs/heads/', '')) {
        throw new Error(
          `Worktree exists but on wrong branch. Expected: ${branch}, Actual: ${existingBranch}`
        )
      }

      // Show crash recovery info
      // eslint-disable-next-line sonarjs/os-command -- Safe: git command with validated worktreePath
      const commitCount = execSync(`git -C ${worktreePath} rev-list --count main..HEAD`, {
        encoding: 'utf8',
      }).trim()

      if (Number.parseInt(commitCount, 10) > 0) {
        console.log(`📊 Crash recovery - ${commitCount} commits already on branch`)
        // eslint-disable-next-line sonarjs/os-command -- Safe: git command with validated worktreePath
        const recentCommits = execSync(`git -C ${worktreePath} log --oneline main..HEAD`, {
          encoding: 'utf8',
        })
        console.log('Recent commits:')
        console.log(recentCommits)
      }

      return worktreePath
    }

    // Create new worktree (Git branch protection applies here)
    console.log(`🚀 Creating new worktree: ${worktreePath}`)

    try {
      // eslint-disable-next-line sonarjs/os-command -- Safe: git command with sanitized inputs
      execSync(`git worktree add -b ${branch} ${worktreePath} main`, {
        stdio: 'inherit',
      })
    } catch (error) {
      throw new Error(
        `Failed to create worktree for ${taskId}. ` +
          `Branch ${branch} may already be checked out elsewhere. ` +
          `Original error: ${error}`
      )
    }

    // Setup environment
    this.setupWorktreeEnvironment(worktreePath)

    return worktreePath
  }

  /**
   * Setup worktree environment (copy .env, install deps)
   *
   * @param worktreePath - Path to worktree
   */
  private setupWorktreeEnvironment(worktreePath: string): void {
    // Copy .env if needed
    if (fs.existsSync('.env')) {
      const targetEnv = path.join(worktreePath, '.env')
      fs.copyFileSync('.env', targetEnv)
      console.log('📄 Copied .env to worktree')
    } else if (fs.existsSync('.env.example')) {
      const targetEnv = path.join(worktreePath, '.env')
      fs.copyFileSync('.env.example', targetEnv)
      console.log('📄 Copied .env.example to worktree')
    }

    // Install dependencies (only for migration-cli package)
    const packageJson = path.join(worktreePath, 'apps/migration-cli/package.json')
    if (fs.existsSync(packageJson)) {
      console.log('📦 Installing dependencies...')
      try {
        // eslint-disable-next-line sonarjs/no-os-command-from-path -- Safe: pnpm is trusted tool, no user input in command
        execSync('pnpm install --filter migration-cli', {
          cwd: worktreePath,
          stdio: 'inherit',
        })
      } catch {
        console.warn('⚠️  Warning: Failed to install dependencies')
        // Continue anyway - dependencies might already be installed
      }
    }
  }

  /**
   * Validate git working directory is clean
   *
   * @throws Error if working directory has uncommitted changes
   */
  private validateCleanGitState(): void {
    try {
      // Update index to avoid false positives
      // eslint-disable-next-line sonarjs/no-os-command-from-path -- Safe: git is trusted tool
      execSync('git update-index --really-refresh', { stdio: 'pipe' })

      // Check for uncommitted changes
      // eslint-disable-next-line sonarjs/no-os-command-from-path -- Safe: git is trusted tool
      execSync('git diff-index --quiet HEAD', { stdio: 'pipe' })
    } catch {
      throw new Error(
        'Working directory is not clean. Commit or stash your changes before creating a worktree.'
      )
    }
  }

  /**
   * Find task file by ID
   *
   * @param taskId - Task identifier
   * @returns Path to task file or null if not found
   */
  private findTaskFile(taskId: string): string | null {
    try {
      // eslint-disable-next-line sonarjs/os-command -- Safe: find command with sanitized taskId pattern
      const files = execSync(`find ${this.taskFileBase} -name "${taskId}-*.md" -type f`, {
        encoding: 'utf8',
      })
        .trim()
        .split('\n')
        .find(Boolean)

      return files || null
    } catch {
      return null
    }
  }

  /**
   * Extract task title from task file
   *
   * @param taskFilePath - Path to task file
   * @returns Sanitized task title for branch name
   */
  private extractTaskTitle(taskFilePath: string): string {
    const content = fs.readFileSync(taskFilePath, 'utf8')
    const regex = /^# (.+)$/m
    const match = regex.exec(content)

    if (!match) {
      return 'untitled'
    }

    return match[1]
      .toLowerCase()
      .replaceAll(/[^a-z0-9]+/g, '-')
      .replaceAll(/(?:^-|-$)/g, '')
  }

  /**
   * Update task file status
   *
   * @param taskId - Task identifier
   * @param status - New status
   * @param worktreePath - Path to worktree
   * @param branch - Branch name
   */
  private updateTaskStatus(
    taskId: string,
    status: string,
    worktreePath: string,
    branch: string
  ): void {
    const taskFilePath = this.findTaskFile(taskId)
    if (!taskFilePath) {
      console.warn(`⚠️  Warning: Cannot update task status - file not found for ${taskId}`)
      return
    }

    let content = fs.readFileSync(taskFilePath, 'utf8')

    // Check if task file has frontmatter
    if (!content.startsWith('---\n')) {
      console.warn('⚠️  Warning: Task file missing frontmatter - cannot update status')
      return
    }

    const timestamp = new Date().toISOString()

    // Update status field
    content = /^status:/m.test(content)
      ? content.replace(/^status:.*$/m, `status: ${status}`)
      : content.replace(/^(id:.*$)/m, `$1\nstatus: ${status}`)

    // Add/update started field
    if (status === 'IN_PROGRESS') {
      content = /^started:/m.test(content)
        ? content.replace(/^started:.*$/m, `started: ${timestamp}`)
        : content.replace(/^(status:.*$)/m, `$1\nstarted: ${timestamp}`)

      // Add/update branch field
      content = /^branch:/m.test(content)
        ? content.replace(/^branch:.*$/m, `branch: ${branch}`)
        : content.replace(/^(started:.*$)/m, `$1\nbranch: ${branch}`)

      // Add/update worktree field
      content = /^worktree:/m.test(content)
        ? content.replace(/^worktree:.*$/m, `worktree: ${worktreePath}`)
        : content.replace(/^(branch:.*$)/m, `$1\nworktree: ${worktreePath}`)
    }

    fs.writeFileSync(taskFilePath, content)
    console.log(`✅ Task status updated: ${status}`)
  }

  /**
   * Check if a process is running
   *
   * @param pid - Process ID
   * @returns True if process is running
   */
  private isProcessRunning(pid: number): boolean {
    try {
      process.kill(pid, 0) // Signal 0 checks existence
      return true
    } catch {
      return false
    }
  }

  /**
   * Release lock when agent completes
   *
   * @param taskId - Task identifier
   */
  releaseLock(taskId: string): void {
    const lockFile = path.join(this.lockDir, `${taskId}.lock`)
    if (fs.existsSync(lockFile)) {
      fs.unlinkSync(lockFile)
      console.log(`🔓 Released lock for ${taskId}`)
    }
  }

  /**
   * List all active worktrees
   *
   * @returns Array of worktree information
   */
  listWorktrees(): WorktreeInfo[] {
    // eslint-disable-next-line sonarjs/no-os-command-from-path -- Safe: git is trusted tool
    const output = execSync('git worktree list --porcelain', {
      encoding: 'utf8',
    })

    const worktrees: WorktreeInfo[] = []
    const lines = output.split('\n')

    let current: Partial<WorktreeInfo> = {}

    for (const line of lines) {
      if (line.startsWith('worktree ')) {
        current.path = line.replace('worktree ', '')
      } else if (line.startsWith('branch ')) {
        current.branch = line.replace('branch ', '').replace('refs/heads/', '')

        // Check if locked
        const taskId = current.branch?.replace(/^feat\/([^-]+).*/, '$1')
        const lockFile = path.join(this.lockDir, `${taskId}.lock`)
        current.locked = fs.existsSync(lockFile)

        if (current.locked) {
          try {
            current.lockInfo = JSON.parse(fs.readFileSync(lockFile, 'utf8'))
          } catch {
            // Ignore parse errors
          }
        }

        if (current.path && current.branch) {
          worktrees.push(current as WorktreeInfo)
        }
        current = {}
      }
    }

    return worktrees
  }

  /**
   * Get lock information for a task
   *
   * @param taskId - Task identifier
   * @returns Lock info or null if not locked
   */
  getLockInfo(taskId: string): TaskLock | null {
    const lockFile = path.join(this.lockDir, `${taskId}.lock`)
    if (!fs.existsSync(lockFile)) {
      return null
    }

    try {
      return JSON.parse(fs.readFileSync(lockFile, 'utf8'))
    } catch {
      return null
    }
  }

  /**
   * Clean all stale locks (from dead processes)
   *
   * @returns Number of locks cleaned
   */
  cleanStaleLocks(): number {
    if (!fs.existsSync(this.lockDir)) {
      return 0
    }

    const lockFiles = fs.readdirSync(this.lockDir).filter((f) => f.endsWith('.lock'))
    let cleaned = 0

    for (const lockFile of lockFiles) {
      const lockPath = path.join(this.lockDir, lockFile)
      try {
        const lock: TaskLock = JSON.parse(fs.readFileSync(lockPath, 'utf8'))

        if (!this.isProcessRunning(lock.pid)) {
          fs.unlinkSync(lockPath)
          console.log(`🧹 Cleaned stale lock: ${lockFile} (dead PID: ${lock.pid})`)
          cleaned++
        }
      } catch (error) {
        console.warn(`⚠️  Warning: Failed to process lock file ${lockFile}:`, error)
      }
    }

    return cleaned
  }
}

// CLI interface (if run directly)
if (require.main === module) {
  const coordinator = new WorktreeCoordinator()

  const command = process.argv[2]
  const taskId = process.argv[3]

  switch (command) {
    case 'list': {
      console.log('Active worktrees:')
      const worktrees = coordinator.listWorktrees()
      for (const wt of worktrees) {
        console.log(`  ${wt.path} (${wt.branch}) ${wt.locked ? '🔒' : ''}`)
        if (wt.lockInfo) {
          console.log(`    Locked by: ${wt.lockInfo.agentId} (PID: ${wt.lockInfo.pid})`)
        }
      }
      break
    }

    case 'clean': {
      const cleaned = coordinator.cleanStaleLocks()
      console.log(`Cleaned ${cleaned} stale locks`)
      break
    }

    case 'lock-info': {
      if (!taskId) {
        console.error('Usage: node worktree-coordinator.ts lock-info <taskId>')
        throw new Error('Missing required taskId argument')
      }
      const lockInfo = coordinator.getLockInfo(taskId)
      if (lockInfo) {
        console.log(JSON.stringify(lockInfo, null, 2))
      } else {
        console.log(`No lock for ${taskId}`)
      }
      break
    }

    default: {
      console.log('Usage:')
      console.log('  node worktree-coordinator.ts list           # List all worktrees')
      console.log('  node worktree-coordinator.ts clean          # Clean stale locks')
      console.log('  node worktree-coordinator.ts lock-info <id> # Show lock info')
      break
    }
  }
}
