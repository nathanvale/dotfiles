# Migration Prompt: Dotfiles to SideQuest Plugin

## Objective

Migrate the specified functionality from the dotfiles repository (`~/code/dotfiles`) to a new plugin in the SideQuest repository (`~/code/sidequest`).

## Source Repository

- **Location**: `~/code/dotfiles`
- **Architecture**: Modular shell scripts, symlinked configs, tmux integration
- **Key directories**:
  - `apps/` - Standalone applications (hyperflow, taskdock, vault)
  - `bin/` - Scripts organized by domain (dotfiles, system, tmux, utils)
  - `config/` - Tool configurations symlinked to `~/.config/`
  - `.claude/` - Claude Code configuration (commands, agents, skills, rules)

## Target Repository

- **Location**: `~/code/sidequest`
- **Plugin structure**: Use `/plugin-template:create` skill to scaffold
- **Plugin location**: `plugins/<plugin-name>/`

## Migration Steps

### 1. Analyze Source

First, thoroughly analyze the source functionality:

```
Read the relevant files in ~/code/dotfiles
Understand the dependencies and integrations
Identify what needs to be ported vs what stays in dotfiles
```

### 2. Create Plugin Scaffold

Use the SideQuest plugin template:

```
cd ~/code/sidequest
/plugin-template:create
```

Follow the wizard to create the plugin structure with:
- Plugin name (kebab-case)
- Description
- Whether it needs TypeScript MCP tools
- Whether it needs slash commands/skills

### 3. Port Functionality

**For shell scripts** → Convert to TypeScript MCP tools or keep as shell scripts called by tools

**For configurations** → Move to plugin's `config/` directory or create MCP tools to manage them

**For Claude Code commands/skills** → Port to plugin's `.claude/commands/` or `.claude/skills/`

**For documentation** → Update to reflect new plugin context

### 4. Update Dependencies

- Add any required npm packages to the plugin's `package.json`
- Update any hardcoded paths to use environment variables or configuration
- Ensure the plugin is self-contained and doesn't require dotfiles repo

### 5. Test Migration

- Run the plugin's MCP tools to verify functionality
- Test any slash commands or skills
- Verify no broken references to dotfiles repo

### 6. Update Dotfiles

After successful migration:
- Remove migrated code from dotfiles (or mark as deprecated)
- Add reference to new plugin location
- Update any cross-references

## What to Migrate

Specify what functionality should be migrated:

```
[ ] Describe the specific feature/functionality here
[ ] List the source files/directories
[ ] Note any special considerations
```

## What Stays in Dotfiles

Core dotfiles functionality that should NOT be migrated:
- `.zshrc`, `.gitconfig`, `.npmrc` (personal shell config)
- Symlink management scripts
- macOS/system preference scripts
- Homebrew Brewfile
- Personal Claude Code config (`config/claude/`)

## Notes

- Preserve git history where possible (consider `git subtree` for large moves)
- Update CLAUDE.md in both repos after migration
- Test in isolation before removing from dotfiles
- Consider backwards compatibility if other tools depend on dotfiles paths
