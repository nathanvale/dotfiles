# Vault System Documentation

## Overview

The vault system is an ADHD-friendly repository management system that auto-discovers and registers projects containing `.agent-os` (Agent OS vault) or `docs` folders, creating symlinks to a unified Obsidian vault structure.

**Key principle:** "Registry as source of truth" - A JSON registry tracks all registered repositories with fingerprints (vault ID, git remote, components) allowing the system to survive repository moves and renames.

## Architecture

### Components

```
bin/vault/
├── vault                           # Main CLI entry point (573 lines)
├── vault-discover.sh              # Auto-discovery of repositories (unused)
├── vault-interactive-manager.sh   # Old interactive interface (unused)
├── vault-manager.sh               # Legacy manager (unused)
├── vault-quick-menu.sh            # Quick menu (unused)
├── vault-smart-manager.sh         # Smart manager (unused)
├── vault-open-current.sh          # Current project opener (unused)
└── vault-register-obsidian.sh     # Obsidian registration (unused)

config/tmux/tmux.conf              # Vault tmux bindings (lines 116-118)
bin/tmux/
├── startup.sh                     # Terminal startup menu (84 lines)
├── new-project.sh                 # Tmuxinator config generator (434 lines)
└── [other tmux utilities]
```

### Data Flow

```
Registry File
├── ~/.config/vault-manager/registry.json
│   └── Contains version, vaults config, repositories array
│       └── Each repo has: name, path, fingerprint (vault_id, git_remote, components)
│
symlink Structure
├── $REPOS_VAULT = /Users/nathanvale/Documents/ObsidianVaults/Repos/repos
│   └── {repo_name}/
│       ├── .agent-os → /path/to/repo/.agent-os (symlink)
│       └── docs → /path/to/repo/docs (symlink)
│
Auto-discovery
├── Scans $VAULT_SEARCH_PATHS (default: $HOME/code)
├── Finds directories with .agent-os or docs folders
└── Detects project type (Node.js, Ruby, Python, Rust, Go)
```

## Main Features

### 1. **Interactive Vault Manager** (`vault manage`)

**Purpose:** ADHD-friendly checkbox interface for bulk registration

**How it works:**
1. Scans $VAULT_SEARCH_PATHS for directories with `.agent-os` or `docs`
2. Shows fzf interactive selection with checkmarks
3. Compares selected repos against registry
4. Registers unchecked repos, unregisters checked repos not selected
5. Shows feedback for each operation

**Key functions:**
- `interactive_manage()` - Main orchestrator (lines 362-468)
- Uses fzf with multi-select, space to toggle, Ctrl-A/Ctrl-D to select all/none
- Stores repo metadata: name, path, fingerprint, components, registration timestamp

**Issue identified:** Subshell variable scope bug (line 448-467) - success message never shown

### 2. **Health Check & Auto-Repair** (`vault health`)

**Purpose:** Detect and fix broken vaults when repositories are moved/renamed/deleted

**How it works:**
1. Loads registry and iterates through registered repos
2. For each repo:
   - ✅ **Exists at recorded path** → Check if symlinks are valid, recreate if needed
   - ⚠️ **Moved** → Use `.vault-id` to find new location, update paths and symlinks
   - ❌ **Deleted** → Remove from registry and vault
3. Auto-repairs broken symlinks, moved repos, renamed repos
4. Reports missing repos that need manual intervention

**Key function:** `health_check()` (lines 208-356)

**Features:**
- Vault ID matching using `find_repo_by_id()` to relocate moved repos
- Atomic registry updates
- Clear user feedback with color coding

### 3. **Open Current Project Vault** (`vault open`)

**Purpose:** Open Obsidian vault for current project with auto-registration

**How it works:**
1. Gets current directory
2. Checks if registered in vault system
3. If not registered:
   - Auto-creates `.agent-os` folder if missing
   - Registers with `register_repo()`
4. Opens Obsidian "Repos" vault using obsidian:// protocol

**Key function:** `open_current()` (lines 475-502)

### 4. **Repository Registration** (`vault register [path]`)

**Purpose:** Manually register a repository

**How it works:**
1. Normalizes path to absolute
2. Generates/retrieves vault ID from `.vault-id` file
3. Creates `.vault-id` if missing
4. Adds to .gitignore
5. Creates symlinks in Repos vault
6. Updates registry with fingerprint

**Key function:** `register_repo()` (lines 125-175)

**Fingerprint includes:**
- `vault_id` - UUID or generated ID
- `git_remote` - Git origin URL
- `has_agent_os` - Boolean
- `has_docs` - Boolean
- `name` - Repo basename

## Tmux Integration

### Startup Menu (`tx` command)

**File:** `bin/tmux/startup.sh` (84 lines)

**What happens when you open a terminal:**
1. Checks if already in tmux session (exits if yes)
2. Lists existing tmux sessions
3. Shows options:
   - `[1-9]` - Attach to numbered session
   - `[n]` - Create new session from tmuxinator projects
   - `[s]` - Skip and use shell
4. Auto-skips after 5 seconds

**Entry point:** `~/.zshrc` sources `bin/tmux/startup.sh` on startup

### New Project Setup (`tmuxnew` command)

**File:** `bin/tmux/new-project.sh` (434 lines)

**What happens when you run `tmuxnew`:**
1. **Project name normalization** - Sanitizes name for tmux/tmuxinator compatibility
   - Removes leading dots (`.foo` → `dot-foo`)
   - Removes special chars, spaces, uppercase
   - Enforces length limit (50 chars)
2. **Project type detection** - Identifies framework/stack:
   - Node.js/Next.js/React → npm/pnpm dev command
   - Ruby/Rails → rails server
   - Python → python REPL
   - Rust → cargo watch
   - Go → go run
3. **Vault detection** - Looks for:
   - `.agent-os` folder → registers with vault system
   - `docs/` folder → registers as docs vault
4. **Generates tmuxinator config** with windows:
   - `claude` - Claude Code editor
   - `git` - Lazygit for version control
   - `[project-specific]` - nextjs, storybook, rails, etc.
   - `vault` - Vault management shortcut (optional)
5. **Prompts to edit** the generated config
6. **Starts session** if user confirms

**Key functions:**
- `detect_project_type()` (lines 120-182) - Framework detection
- `detect_vaults()` (lines 185-216) - Vault discovery
- `normalize_project_name()` (lines 32-83) - Name sanitization with 8-step process

**Issue identified:** Calls old `vault-manager.sh register-aos/register-docs` commands (line 192-207) - should use unified `vault register`

### Vault Tmux Bindings

**File:** `config/tmux/tmux.conf` (lines 116-118)

```bash
bind V display-popup -w 90% -h 85% -E "~/code/dotfiles/bin/vault/vault manage"
bind H display-popup -w 70% -h 60% -E "~/code/dotfiles/bin/vault/vault health"
bind v run-shell "~/code/dotfiles/bin/vault/vault open"
```

**Prefix:** Ctrl-g (set in tmux.conf line 6)

**Usage:**
- `Ctrl-g V` - Open interactive vault manager in popup
- `Ctrl-g H` - Run health check in popup
- `Ctrl-g v` - Open current project's vault (simpler, no popup)

## Data Structures

### Registry JSON

```json
{
  "version": "3.0.0",
  "vaults": {
    "personal": {
      "type": "personal",
      "path": "/Users/nathanvale/code/my-second-brain"
    },
    "repos": {
      "type": "unified",
      "path": "/Users/nathanvale/Documents/ObsidianVaults/Repos",
      "repositories": [
        {
          "name": "my-project",
          "path": "/Users/nathanvale/code/my-project",
          "fingerprint": {
            "vault_id": "abc-123-def",
            "git_remote": "https://github.com/user/my-project",
            "has_agent_os": true,
            "has_docs": true,
            "name": "my-project"
          },
          "components": {
            "agentOS": true,
            "docs": true
          },
          "registered": "2025-11-14T12:30:00Z"
        }
      ]
    }
  },
  "lastUpdated": "2025-11-14T12:30:00Z"
}
```

### .vault-id File

```
abc-123-def-456-ghi
```

Simple UUID or generated ID, stored in repo root, added to .gitignore.

## Configuration

### Environment Variables

**`VAULT_SEARCH_PATHS`** (default: `$HOME/code`)
- Colon-separated paths to scan for repositories
- Example: `export VAULT_SEARCH_PATHS="$HOME/code:$HOME/projects:$HOME/work"`

### Hardcoded Paths (Portability Issue)

- **Registry:** `~/.config/vault-manager/registry.json`
- **Repos vault:** `/Users/nathanvale/Documents/ObsidianVaults/Repos/repos` (hardcoded user)
- **tmuxinator scripts:** `~/.config/tmuxinator/scripts/common-setup.sh`

**Issue:** User path hardcoded in `bin/vault/vault:18` - breaks on other machines

## Known Issues & Improvements

### Critical (P0)
1. **Shell injection vulnerability** (line 195, 371)
   - `find $SEARCH_PATHS` vulnerable to command injection
   - **Fix:** Quote: `find "$SEARCH_PATHS"`

2. **Silent path resolution failure** (line 127)
   - `repo_path=$(cd "$repo_path" && pwd)` silently returns current directory on failure
   - **Fix:** Add error handling: `cd "$repo_path" || return 1`

### High (P1)
3. **Race condition in registry updates**
   - No file locking - concurrent operations corrupt JSON
   - **Fix:** Use `flock` and atomic writes (temp file → mv)

4. **Performance: Inefficient directory scanning**
   - Find commands traverse node_modules, .git (30+ sec on large codebases)
   - **Fix:** Add `-path '*/node_modules' -prune -path '*/.git' -prune`

5. **Broken vault integration in new-project.sh**
   - Calls old vault-manager.sh commands (lines 192-207)
   - **Fix:** Update to: `~/code/dotfiles/bin/vault/vault register "$PROJECT_PATH"`

6. **No write operation validation**
   - .vault-id, .gitignore, registry writes have no error checks
   - **Fix:** Add `|| { log_error "..."; return 1; }`

### Medium (P2)
7. **Code duplication** - Symlink creation pattern repeated 3× (lines 152, 242, 275)
8. **Subshell variable scope bug** - success message never shown (line 448-467)
9. **Hardcoded user paths** - Breaks portability (line 18, startup.sh:53, 82)

### Low (P3)
10. **Inefficient subprocess spawning** - dirname/cat in loops (100+ repos = 300+ processes)

## Auto-Discovery Flow

```
User runs: vault manage
↓
Find all directories with .agent-os or docs in $VAULT_SEARCH_PATHS
↓
Load current registry
↓
Build fzf input with status [✓] or [ ] for each repo
↓
Show fzf multi-select interface
↓
User selects/deselects repos with space
↓
Compare selections against current registry
↓
For each unselected-but-registered: call unregister_repo()
For each selected-but-unregistered: call register_repo()
↓
Save updated registry
↓
Show summary of changes
```

## Dead Code Analysis

**Unused scripts (133 total functions found as dead code):**
- `vault-discover.sh` - Old discovery script
- `vault-manager.sh` - Legacy manager
- `vault-smart-manager.sh` - Smart manager
- `vault-interactive-manager.sh` - Old interactive
- `vault-quick-menu.sh` - Quick menu
- `vault-open-current.sh` - Current opener
- `vault-register-obsidian.sh` - Obsidian registration

All functionality consolidated into `bin/vault/vault` main script.

## Usage Examples

### Open vault for current project
```bash
# In any project directory
vault open

# If not registered:
# - Creates .agent-os if missing
# - Auto-registers
# - Opens Obsidian Repos vault
```

### Bulk register repositories
```bash
# Show checkbox interface
vault manage

# Select repos with space, Ctrl-A/Ctrl-D for all/none
# Press Enter to apply changes
```

### Run health check
```bash
# Check vault health
vault health

# Outputs:
# ✅ Repos automatically located when moved
# ✅ Symlinks recreated when broken
# ✅ Registry updated when repos renamed
# ❌ Reports missing repos for manual action
```

### Register specific repo
```bash
vault register /path/to/repo
```

### Show registered repos
```bash
vault status
```

## Improvements Roadmap

**Phase 1 (Critical):**
- [ ] Fix shell injection vulnerability (quote $SEARCH_PATHS)
- [ ] Add error handling for path resolution
- [ ] Update new-project.sh to use unified vault API

**Phase 2 (Performance):**
- [ ] Add -prune to find commands
- [ ] Implement file locking for registry
- [ ] Add write operation error handling

**Phase 3 (Refactoring):**
- [ ] Extract symlink creation to function
- [ ] Fix subshell variable scope
- [ ] Replace hardcoded paths with variables

**Phase 4 (Testing):**
- [ ] Add unit tests for registry operations
- [ ] Test race conditions
- [ ] Test on different systems
