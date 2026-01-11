# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this
repository.

## Core Commands

**Installation:**

- Individual component scripts in `bin/dotfiles/`, `bin/system/`, `bin/utils/`, etc. - Run scripts
  independently for modular setup
- All scripts are executable and can be run in any order (they're idempotent)
- Scripts handle: symlinks, preferences, fonts, package management, iTerm2 settings, macOS
  preferences

**Package Management:**

- `brew bundle --file=config/brew/Brewfile` - Install all Homebrew dependencies
- `brew bundle cleanup --file=config/brew/Brewfile` - Remove packages not in Brewfile

**Development Environment:**

- `tmux` - Terminal multiplexer (prefix: Ctrl-g)
- `tx` - Universal tmux session launcher (press `Ctrl-g t` or run `tx` to launch)
- `lazygit` - Terminal UI for git operations (Ctrl-g g)

**Testing and Validation:**

- All installation scripts use `set -e` for immediate failure on errors
- Scripts are idempotent and can be run multiple times safely
- Individual components can be tested in isolation

## Claude Code Slash Commands

This project includes custom slash commands in `.claude/commands/` for productivity:

- `/index` - Generate PROJECT_INDEX.json for architectural codebase awareness
- `/review-code` - Comprehensive code review across 7 quality dimensions
- `/cc-create-agent`, `/cc-create-command`, `/cc-create-skill` - Create new Claude Code tools
- `/cc-review-*` - Review agents, commands, and skills for quality and efficiency
- `/sw-mode`, `/sw-integrate`, `/sw-fix` - SuperWhisper AI dictation integration
- `/migrate-debug`, `/migrate-rollback` - Migration utilities (if working with referral systems)

## HyperFlow Keyboard Orchestration

**HyperFlow** is a keyboard-driven productivity system using the **Hyper Key** (Right Command =
Ctrl+Opt+Cmd+Shift) as a conflict-free namespace for custom shortcuts. It orchestrates
Karabiner-Elements (keyboard remapping), hyperflow.sh (app launching), SuperWhisper (context-aware
voice dictation), and Raycast (window management).

**Quick Facts:**

- **Right Command** = Hyper Key (Ctrl+Opt+Cmd+Shift) - used for letter shortcuts only
- **Caps Lock** = Control (Escape if tapped alone) - preserves muscle memory for Ctrl+C, Ctrl+E,
  etc.
- **Control+1-5**: Primary apps (Ghostty, VS Code, Arc, Obsidian, Teams)
- **Hyper+Letters**: Secondary apps and actions
- **Hyper+H/J/K/L**: Arrow navigation (Vim-style)
- **Hyper+\\**: Cycle tmux sessions

**For all HyperFlow modifications** (adding shortcuts, configuring modes, debugging), refer to the
**hf-orchestrator** skill which contains comprehensive architecture documentation, procedural
guides, and helper scripts. The skill automatically triggers when you mention: "hyperflow", "hyper
key", "karabiner", "add shortcut", or related keyboard workflow topics.

## Architecture

This is a comprehensive macOS dotfiles system built around modular shell scripts that orchestrate
the setup of development environments.

### Core Architecture Pattern

**Modular Installation System:**

- Each component (brew, symlinks, preferences, fonts) has its own install/uninstall/manage scripts
- Critical hotspots: `execute_scripts` (orchestration), `get_config` (configuration loading), `log_error` (error handling)
- Scripts organized by domain: `bin/dotfiles/`, `bin/system/`, `bin/tmux/`, `bin/utils/`
- All scripts use `set -e` for fail-fast behavior and are idempotent

**Symlink Strategy:**

- Dotfiles in root symlinked from `$HOME` to repo
- Configuration directories symlinked from `config/` to `$HOME/.config/`
- Managed via `bin/dotfiles/symlinks/symlinks_manage.sh`

**Environment Variables & Secrets:**

- Sensitive data stored in `.env.secrets` (git-ignored), sourced in `.zshrc`
- Config files use variable substitution (e.g., `${NPM_TOKEN}`)

**Tmux Integration:**

- Custom tmux configuration with Ctrl-g prefix
- Universal templates (3 templates replace 20+ project-specific configs)
- Smart template detection based on project type

**Raycast Integration:**

- Custom TypeScript-based extensions for productivity workflows
- Native window management hotkeys

### File Organization

```
.                            # macOS dotfiles system
├── apps/                    # Major standalone applications
│   ├── hyperflow/          # Hyper key orchestration (Karabiner + Raycast + SuperWhisper)
│   ├── taskdock/           # Agentic task orchestration and git worktree management
│   └── vault/              # Vault management for secrets
├── bin/                     # Scripts and CLI shims
│   ├── dotfiles/           # Symlink and preference management
│   ├── system/             # macOS/iTerm2 preferences
│   ├── tmux/               # Tmux utilities (tx launcher, monitors)
│   ├── dev/                # Development tools (homebrew)
│   ├── env/                # API key and secrets management
│   └── templates/          # CLI script templates
├── config/                  # Tool configurations (symlinked to ~/.config/)
│   ├── tmux/               # Tmux config + Night Owl theme
│   ├── tmuxinator/         # Universal session templates (standard, fullstack, nextjs)
│   ├── karabiner/          # Keyboard remapping (Hyper key)
│   ├── ghostty/            # Terminal emulator config
│   ├── superwhisper/       # Voice dictation modes
│   ├── claude/             # Claude Code personal config
│   ├── vscode/             # VS Code settings + MCP config
│   └── brew/               # Brewfile package definitions
├── .claude/                 # Claude Code project configuration
│   ├── commands/           # Slash commands (/index, /review-code)
│   ├── agents/             # Custom subagents
│   ├── skills/             # Skill implementations
│   └── rules/              # Path-scoped rules (code-style, architecture, tmux)
├── docs/                    # Project documentation
├── misc/                    # Fonts, themes, assets
└── Root dotfiles           # .zshrc, .gitconfig, .npmrc (symlinked from $HOME)
```

### Rules Directory

Path-scoped rules in `.claude/rules/` provide focused guidance:
- `code-style.md` - Shell script and TypeScript conventions
- `architecture.md` - Core patterns and critical hotspots
- `tmux.md` - Session management and templates

## Development Notes

- All bash scripts use `set -e` for immediate exit on errors
- Installation scripts are executed locally from the `bin/` directory
- Configuration changes should be made in the `config/` directory
- The system supports both installation and uninstallation workflows
- Individual scripts can be run manually for specific tasks
- Tmux sessions are configured with vi-style keybindings and system clipboard integration

## Key Configuration Files

**Core Package Management:**

- `config/brew/Brewfile` - Homebrew package definitions (brew, casks, taps)
- Includes essential tools: tmux, lazygit, zoxide, fzf, bat, eza, jq, etc.

**Terminal and Shell:**

- `config/tmux/tmux.conf` - Tmux configuration with Night Owl theme and `tx` launcher
- `config/tmuxinator/` - Universal templates: standard.yml, fullstack.yml, nextjs.yml
- `bin/tmux/tx` - Smart session launcher with fzf picker and template selection
- Shell configurations support zsh with various productivity tools

**Personal Claude Code Setup:**

- `config/claude/` - Contains personal Claude Code configuration
- Instructions, commands, and project-specific settings
- Integrated with the overall dotfiles system

**Raycast Extensions:**

- Each extension in `config/raycast/extensions/` has its own package.json
- Custom TypeScript-based extensions for productivity workflows
- Includes Bluetooth management, color tools, JSON formatting, and more

**VS Code Configuration:**

- `config/vscode/` - Settings, keybindings, tasks, MCP config, and prompt templates
- Symlinked to `~/Library/Application Support/Code/User/`
- MCP servers configured in `mcp.json` for Claude Code integration

## Working with This Codebase

### Understanding the Structure

Run `/index` to generate `PROJECT_INDEX.json`, which gives Claude architectural awareness:

- Identifies function/script locations and call graphs
- Helps prevent code duplication
- Ensures scripts are placed in appropriate directories
- Reference with `@PROJECT_INDEX.json` in future conversations

### Adding New Dotfiles

When adding a new dotfile (e.g., `.npmrc`, `.gitignore_global`):

1. Place the file in the root of this repo (or `config/<tool>/` for app-specific configs)
2. Add symlink entry to `bin/dotfiles/symlinks/symlinks_manage.sh`
3. If the file contains secrets, use environment variable substitution (e.g., `${TOKEN_NAME}`)
4. Add the variable to `.env.secrets` and ensure `.zshrc` sources it
5. Exclude the dotfile from git only if it contains hardcoded secrets; otherwise it's safe to commit

### Tmux Session Management

**Launch a session:**
```bash
tx                          # Interactive fzf picker (running sessions + ~/code projects)
tx paicc-1                  # Start with standard template (default)
tx ~/code/my-app fullstack  # Use specific template
tx .                        # Current directory
Ctrl-g t                    # Same as 'tx' (tmux popup binding)
```

**Available templates:**
- `standard` - claude (ccdev) + git (lazygit) + shell — basic projects
- `fullstack` - standard + dev server + vault — full-stack apps
- `nextjs` - claude + git + dev + conditional prisma/storybook + shell — Next.js projects

**Key bindings in templates:**
- `Ctrl-g g` - Switch to git (lazygit) window
- `Ctrl-g c` - Switch to claude window
- Window "claude" pane runs `ccdev` alias (25 local plugins for development)

**How it works:**
1. `tx` resolves project path (supports `~/code/name`, `.`, `~/.claude`, or full paths)
2. Generates session name from path (my-project → my-project, .claude → dot-claude)
3. Creates session if new, reattaches if exists
4. Auto-detects template or uses specified one
5. Templates use ERB for smart detection (nextjs.yml checks for Prisma/Storybook)

### Script Development Patterns

- Always use `set -e` at the top of installation/uninstallation scripts
- Source `bin/utils/colour_log.sh` for consistent error/warning/success logging
- Keep scripts modular: prefer multiple small scripts over monolithic ones
- Test individual scripts independently before integrating into orchestration
- For tmux/tmuxinator work, edit universal templates in `config/tmuxinator/` instead of creating project-specific configs

## Code Style Rules

### Code Formatting

- No semicolons (enforced)
- Single quotes (enforced)
- No unnecessary curly braces (enforced)
- 2-space indentation
- Import order: external → internal → types
