# VS Code Configuration

Complete VS Code setup integrated with dotfiles architecture, including Copilot prompts, settings,
and task management workflow.

## Architecture Overview

All VS Code configuration is symlinked from dotfiles, mirroring the standard `.vscode` folder
structure from Git repositories:

```
~/code/dotfiles/config/vscode/
├── settings.json        → ~/Library/Application Support/Code/User/settings.json
├── tasks.json           → ~/Library/Application Support/Code/User/tasks.json
├── prompts/             → ~/Library/Application Support/Code/User/prompts/
│   ├── Next.prompt.md
│   ├── Merge.prompt.md
│   ├── SETTINGS.md
│   └── README.md
└── README.md            → this file
```

This structure matches the standard `.vscode` folder layout used in Git repositories.

**Benefits:**

- ✅ Version controlled in git
- ✅ Easy restoration on new machines
- ✅ Single source of truth
- ✅ Consistent with dotfiles architecture
- ✅ Auto-approval settings persist across reinstalls

## Installation

### Automatic (Recommended)

All symlinks are created automatically by the dotfiles installation script:

```bash
cd ~/code/dotfiles/bin/dotfiles/symlinks
./symlinks_install.sh
```

This creates symlinks for:

- ✅ `settings.json` (includes Copilot auto-approval)
- ✅ `tasks.json` (VS Code tasks)
- ✅ `prompts/` (Copilot prompt files)

### Manual Installation

If needed, create symlinks manually:

```bash
# Create VS Code User directory
mkdir -p ~/Library/Application\ Support/Code/User

# Symlink settings and tasks
ln -sf ~/code/dotfiles/config/vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json
ln -sf ~/code/dotfiles/config/vscode/tasks.json ~/Library/Application\ Support/Code/User/tasks.json

# Symlink prompts directory
ln -sf ~/code/dotfiles/config/vscode/prompts ~/Library/Application\ Support/Code/User/prompts
```

### Enable Prompt Files

After symlinks are created:

1. Open VS Code Settings (Cmd+,)
2. Search for `chat.promptFiles`
3. Enable the setting
4. Reload VS Code: Cmd+Shift+P → `Developer: Reload Window`

## Settings Configuration

The symlinked `settings.json` includes all required configuration:

```json
{
  "chat.agent.maxRequests": 300,
  "chat.promptFiles": true,

  // Copilot Auto-Approval (Required for /merge and /next prompts)
  "chat.tools.global.autoApprove": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": "explicit"
  },
  // Editor
  "editor.formatOnSave": true
}
```

### What These Settings Do

**`chat.tools.global.autoApprove: true`**

- Enables "YOLO mode" - auto-approves all tool operations
- Eliminates confirmation dialogs for terminal commands
- **Required** for `/merge` and `/next` prompts to work
- Security warning: Not recommended for untrusted workspaces

**`chat.agent.maxRequests: 300`**

- Maximum requests an agent can make before asking to continue
- Default: 25
- Prevents "continue iteration" interruptions during complex tasks

**`chat.promptFiles: true`**

- Enables the prompt files feature
- Required to use `/merge` and `/next` commands

### Alternative: Selective Auto-Approval

For more control, enable auto-approval only for specific commands:

```json
{
  "chat.tools.terminal.autoApprove": {
    "chmod": false,
    "chown": false,
    "curl": false,
    "del": false,
    "eval": false,
    "kill": false,
    "rm": false,
    "rmdir": false,
    "wget": false
  },
  "chat.tools.terminal.enableAutoApprove": true
}
```

## Copilot Prompt Files

### Available Prompts

#### `/next` - Start Next Task

Atomically selects, locks, and starts the next highest-priority task.

**Usage:**

```
/next
```

**Workflow:**

1. Finds READY tasks sorted by priority
2. Atomically locks task (prevents race conditions)
3. Reads task requirements
4. Creates git worktree
5. Sets up development environment
6. Guides implementation
7. Creates PR when complete

**Delegation:** Reads `~/.claude/commands/next.md` for instructions

#### `/merge` - Merge PR and Cleanup

Merges a completed PR and performs complete cleanup.

**Usage:**

```
/merge              # Merge PR from current worktree
/merge 123          # Merge PR #123
/merge T0030        # Merge task T0030
/merge MPCU-0005    # Merge task MPCU-0005
```

**What it does:**

- Executes `~/.claude/scripts/merge-pr.sh`
- Detects git provider (GitHub/Azure DevOps)
- Verifies PR status
- Merges to main branch
- Deletes remote and local branches
- Removes worktree
- Cleans up task locks
- Updates local main branch

**Performance:**

- Optimized with batched API calls (2 instead of 4-5)
- 40-50% faster than manual workflow

**Delegation:** Reads `~/.claude/commands/merge.md` for instructions

### Complete Task Lifecycle

```
/next → Implementation → PR Review → /merge → Repeat
  ↓           ↓              ↓           ↓
Lock       Worktree      Approval    Cleanup
Task       Changes       Process     Everything
```

### Prompt Design Philosophy

Both prompts follow the **delegation pattern**:

- Minimal prompt files that reference command files
- Single source of truth in `~/.claude/commands/`
- No duplication of workflow logic
- Automatic updates when command files change
- Works with both Claude Code and VS Code Copilot

## Testing the Configuration

After installation:

1. Reload VS Code: Cmd+Shift+P → `Developer: Reload Window`
2. Open Chat view (Cmd+Alt+I)
3. Type `/next` or `/merge`
4. Commands should execute without confirmation dialogs

If you still see permission prompts, verify:

- `settings.json` symlink points to dotfiles
- `chat.tools.global.autoApprove` is `true` in settings
- VS Code was reloaded after changing settings

## Syncing Across Devices

To sync prompt files across multiple devices:

1. Enable **Settings Sync** in VS Code
2. Run **Settings Sync: Configure** (Cmd+Shift+P)
3. Select **Prompts and Instructions** from sync options

Your prompt files will now sync across all VS Code installations.

**Note:** Settings Sync also syncs `settings.json`, but the symlink approach ensures you have a
local backup in your dotfiles.

## Directory Structure

```
config/vscode/               # Mirrors standard .vscode folder from Git
├── settings.json            # VS Code settings (symlinked)
├── tasks.json               # VS Code tasks (symlinked)
├── prompts/                 # Copilot prompt files (symlinked)
│   ├── Next.prompt.md       # /next command
│   ├── Merge.prompt.md      # /merge command
│   ├── SETTINGS.md          # Detailed settings guide
│   └── README.md            # Prompts documentation
├── CODE_SHOTGUNS.md         # Shotgun CLI + Shotgun Surgery concepts
└── README.md                # This file - complete documentation
```

## Troubleshooting

### Prompts not found

```bash
# Verify symlink
readlink ~/Library/Application\ Support/Code/User/prompts

# Should output:
# /Users/nathanvale/code/dotfiles/config/vscode/prompts
```

### Permission prompts still appear

```bash
# Check settings.json content
cat ~/code/dotfiles/config/Code/User/settings.json | grep autoApprove

# Should include:
# "chat.tools.global.autoApprove": true
```

### Settings not taking effect

1. Verify symlink points to vscode folder:
   ```bash
   readlink ~/Library/Application\ Support/Code/User/settings.json
   # Should output: /Users/nathanvale/code/dotfiles/config/vscode/settings.json
   ```
2. Reload VS Code: Cmd+Shift+P → `Developer: Reload Window`
3. Check for syntax errors in settings.json

## Related Documentation

**Local Documentation:**
- [CODE_SHOTGUNS.md](./CODE_SHOTGUNS.md) - Comprehensive guide to Shotgun CLI (spec-driven development tool) and Shotgun Surgery (anti-pattern to avoid). Essential reading for AI-powered development workflows.

## References

- [VS Code Prompt Files Documentation](https://code.visualstudio.com/docs/copilot/customization/prompt-files)
- [VS Code 1.104 - Global Auto Approve](https://code.visualstudio.com/updates/v1_104#_global-auto-approve)
- [GitHub Copilot Custom Instructions](https://docs.github.com/en/copilot/concepts/prompting/response-customization)
- [Community Prompt Examples](https://github.com/github/awesome-copilot/tree/main)
- [Stack Overflow: Auto-approve Copilot Commands](https://stackoverflow.com/questions/79720577/)

**External Resources:**
- [Shotgun CLI Official Site](https://shotgun.sh/)
- [Shotgun CLI GitHub](https://github.com/shotgun-sh/shotgun)
- [Shotgun Surgery - Wikipedia](https://en.wikipedia.org/wiki/Shotgun_surgery)
