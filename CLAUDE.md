# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Core Commands

**Installation:**
- Individual component scripts in `bin/dotfiles/`, `bin/system/`, `bin/utils/`, etc. - Run scripts independently for modular setup
- All scripts are executable and can be run in any order (they're idempotent)
- Scripts handle: symlinks, preferences, fonts, package management, iTerm2 settings, macOS preferences

**Package Management:**
- `brew bundle --file=config/brew/Brewfile` - Install all Homebrew dependencies
- `brew bundle cleanup --file=config/brew/Brewfile` - Remove packages not in Brewfile

**Development Environment:**
- `tmux` - Terminal multiplexer (prefix: Ctrl-g)
- `tmuxinator start <project>` - Start tmuxinator project sessions
- `lazygit` - Terminal UI for git operations

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

**HyperFlow** is a keyboard-driven productivity system using the **Hyper Key** (Right Command = Ctrl+Opt+Cmd+Shift) as a conflict-free namespace for custom shortcuts. It orchestrates Karabiner-Elements (keyboard remapping), hyperflow.sh (app launching), SuperWhisper (context-aware voice dictation), and Raycast (window management).

**Quick Facts:**
- **Right Command** = Hyper Key (Ctrl+Opt+Cmd+Shift) - used for letter shortcuts only
- **Caps Lock** = Control (Escape if tapped alone) - preserves muscle memory for Ctrl+C, Ctrl+E, etc.
- **Control+1-7**: Primary apps (Ghostty, VS Code, Arc, Obsidian, Teams, Outlook, Messages)
- **Hyper+Letters**: Secondary apps and actions
- **Hyper+H/J/K/L**: Arrow navigation (Vim-style)
- **Hyper+\\**: Cycle tmux sessions

**For all HyperFlow modifications** (adding shortcuts, configuring modes, debugging), refer to the **hf-orchestrator** skill which contains comprehensive architecture documentation, procedural guides, and helper scripts. The skill automatically triggers when you mention: "hyperflow", "hyper key", "karabiner", "add shortcut", or related keyboard workflow topics.

## Architecture

This is a comprehensive macOS dotfiles system built around modular shell scripts that orchestrate the setup of development environments.

### Core Architecture Pattern

**Modular Installation System:**
- Each component (brew, symlinks, preferences, fonts) has its own install/uninstall/manage scripts
- Critical hotspots: `execute_scripts` (orchestration), `get_config` (configuration loading), `log_error` (error handling)
- Scripts are organized by domain: `bin/dotfiles/`, `bin/system/`, `bin/tmux/`, `bin/utils/`
- Major applications in `apps/`: `apps/taskdock/`, `apps/hyperflow/`, `apps/vault/`
- All scripts use `set -e` for fail-fast behavior and are idempotent (safe to run multiple times)

**Symlink Strategy:**
- Dotfiles in root (e.g., `.zshrc`, `.npmrc`, `.gitconfig`) are symlinked from `$HOME` to the repo
- Configuration directories are symlinked from `config/` subdirectories to `$HOME/.config/`
- Use `bin/dotfiles/symlinks/symlinks_manage.sh` to manage all symlinks

**Environment Variables & Secrets:**
- Sensitive data (API tokens, auth credentials) stored in `.env.secrets` (git-ignored)
- `.env.secrets` is sourced in `.zshrc` and auto-exports variables to shell environment
- Config files use variable substitution (e.g., `${NPM_TOKEN}`) to reference secrets without hardcoding
- Example: `.npmrc` uses `${NPM_TOKEN}` which resolves from exported environment variables

### Key Components

**Installation Scripts (`bin/`):**
- Modular bash script system for installing/uninstalling dotfiles
- Local scripts that handle brew packages, symlinks, macOS preferences, fonts, and iTerm2 settings
- Individual scripts can be run manually for specific tasks

**Configuration Structure (`config/`):**
- Each tool has its own subdirectory (tmux, git, karabiner, etc.)
- Configs are symlinked to their proper locations during installation
- Supports both local and remote configuration management
- Contains environment variable references for secrets instead of hardcoded credentials

**Individual Scripts (`bin/`):**
- `brew_install.sh` - Installs Homebrew package manager
- `brew_remote_bundle.sh` - Installs packages from Brewfile
- `brew_uninstall.sh` - Uninstalls Homebrew packages
- `check_shell.sh` - Validates shell configuration
- `colour_log.sh` - Logging utilities with color support
- `dotfiles_install.sh` - Main dotfiles installation
- `dotfiles_uninstall.sh` - Removes dotfiles configuration
- `iterm_preferences_install.sh` - Configures iTerm2 settings
- `iterm_preferences_uninstall.sh` - Removes iTerm2 settings
- `macos_preferences_install.sh` - Applies macOS system preferences
- `macos_preferences_uninstall.sh` - Resets macOS preferences
- `nerd_fonts_install.sh` - Installs Nerd Fonts
- `nerd_fonts_uninstall.sh` - Removes Nerd Fonts
- `ssh_config_remove.sh` - Cleans SSH configuration
- `symlinks_install.sh` - Creates configuration symlinks
- `symlinks_uninstall.sh` - Removes configuration symlinks

**Tmux Integration:**
- Custom tmux configuration with Ctrl-g prefix
- Tmuxinator project templates for different development environments
- Night Owl theme integration across terminal tools

**Raycast Integration:**
- Custom Raycast extensions for productivity workflows
- Bluetooth device management, color tools, JSON formatting, etc.
- Extensions are TypeScript-based with individual package.json configurations
- Native window management hotkeys (replaces AeroSpace tiling manager for simplicity)

### File Organization

```
config/                    # All configuration files
├── tmux/                 # Tmux configuration and themes
├── tmuxinator/           # Project session templates
├── brew/                 # Homebrew package definitions
├── karabiner/            # Keyboard remapping rules (Hyper key + shortcuts)
├── raycast/              # Raycast extension configurations
├── claude/               # Claude Code personal configuration
├── git/                  # Git configuration and settings
├── superwhisper/         # SuperWhisper AI dictation modes
└── ...

bin/                      # Installation system, custom utilities, and app shims
├── dotfiles/             # Symlink and preference management
├── system/               # macOS system and iTerm2 preferences
├── tmux/                 # Tmux-specific utilities
├── utils/                # General utility functions
├── taskdock              # TaskDock CLI shim → apps/taskdock/
├── taskdock-vscode       # TaskDock VS Code shim → apps/taskdock/
├── hyperflow             # HyperFlow CLI shim → apps/hyperflow/
└── vault                 # Vault CLI shim → apps/vault/

apps/                     # Major applications
├── taskdock/             # Agentic task orchestration and worktree management
├── hyperflow/            # Hyper key orchestration (app launcher + mode switcher)
└── vault/                # Vault management system

.claude/                   # Claude Code local configuration
├── commands/             # Custom slash commands (e.g., /index, /review-code)
├── agents/               # Custom subagents for specialized tasks
├── skills/               # Reusable skill implementations
├── instructions/         # Custom instruction sets
└── state/                # Plugin state and metadata (git-ignored)

misc/                      # Fonts, themes, and other assets
├── iterm2/               # iTerm2 settings and profiles
├── mesloLGS_NF/          # Nerd Font files
└── via/                  # Keyboard layout configurations

Dotfiles in Root:
├── .npmrc                # Node package manager (uses ${NPM_TOKEN})
├── .zshrc                # Shell configuration (sources .env.secrets)
├── .gitconfig            # Git configuration
├── .env.secrets          # Secrets and environment variables (git-ignored)
└── ...
```


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
- `config/tmux/tmux.conf` - Tmux configuration with Night Owl theme
- `config/tmuxinator/` - Project session templates for different codebases
- Shell configurations support zsh with various productivity tools

**Personal Claude Code Setup:**
- `config/claude/` - Contains personal Claude Code configuration
- Instructions, commands, and project-specific settings
- Integrated with the overall dotfiles system

**Raycast Extensions:**
- Each extension in `config/raycast/extensions/` has its own package.json
- Custom TypeScript-based extensions for productivity workflows
- Includes Bluetooth management, color tools, JSON formatting, and more

## Working with This Codebase

### Understanding the Structure
Run `/index` to generate `PROJECT_INDEX.json`, which gives Claude architectural awareness:
- Identifies function/script locations and call graphs
- Helps prevent code duplication
- Ensures scripts are placed in appropriate directories
- Reference with `@PROJECT_INDEX.json` in future conversations

### Adding New Dotfiles
When adding a new dotfile (e.g., `.npmrc`, `.gitignore_global`):
1. Place the file in the root of this repo
2. Add symlink creation to `bin/dotfiles/symlinks/symlinks_install.sh`
3. If the file contains secrets, use environment variable substitution (e.g., `${TOKEN_NAME}`)
4. Add the variable to `.env.secrets` and ensure `.zshrc` sources it
5. Exclude the dotfile from git only if it contains hardcoded secrets; otherwise it's safe to commit

### Tmux Configuration
- Main config: `config/tmux/tmux.conf` (prefix: Ctrl-g)
- Custom keybindings are at the bottom of tmux.conf
- Any bindings using `-n` flag work globally (no prefix needed)
- Project sessions defined in `config/tmuxinator/` are auto-loaded with `tmuxinator start <project>`

### Script Development Patterns
- Always use `set -e` at the top of installation/uninstallation scripts
- Source `bin/utils/colour_log.sh` for consistent error/warning/success logging
- Keep scripts modular: prefer multiple small scripts over monolithic ones
- Test individual scripts independently before integrating into orchestration
