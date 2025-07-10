# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Core Commands

**Installation and Setup:**
- `./install.sh` - Installs the complete dotfiles system
- `./bin/install-dotfiles.sh` - Installs dotfiles using local scripts
- `./bin/uninstall-dotfiles.sh` - Uninstalls dotfiles using local scripts

**Individual Script Usage:**
- `./bin/<script-name>.sh` - Run any individual installation script
- All scripts are executable and can be run independently

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

**Management Scripts (`bin/`):**
- `*_manage.sh` scripts - Individual component management utilities
- `installation_scripts.sh` / `uninstallation_scripts.sh` - Script orchestration
- `preferences_backup.sh` / `preferences_restore.sh` - Configuration backup/restore

## Architecture

This is a comprehensive macOS dotfiles system built around modular shell scripts that orchestrate the setup of development environments.

### Key Components

**Installation Scripts (`bin/`):**
- Modular bash script system for installing/uninstalling dotfiles
- Local scripts that handle brew packages, symlinks, macOS preferences, fonts, and iTerm2 settings
- Individual scripts can be run manually for specific tasks

**Configuration Structure (`config/`):**
- Each tool has its own subdirectory (tmux, git, karabiner, etc.)
- Configs are symlinked to their proper locations during installation
- Supports both local and remote configuration management

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

**Raycast Extensions:**
- Custom Raycast extensions for productivity workflows
- Bluetooth device management, color tools, JSON formatting, etc.
- Extensions are TypeScript-based with individual package.json configurations

**AeroSpace Window Management:**
- Tiling window manager configuration in `config/aerospace/`
- Custom keybindings and workspace management
- Integration scripts in `bin/aerospace_*.sh`

### File Organization

```
config/           # All configuration files
├── tmux/         # Tmux configuration and themes
├── tmuxinator/   # Project session templates
├── brew/         # Homebrew package definitions
├── karabiner/    # Keyboard remapping rules
├── raycast/      # Raycast extension configurations
├── aerospace/    # AeroSpace window manager config
├── claude/       # Claude Code personal configuration
├── git/          # Git configuration and settings
└── ...

bin/              # Installation system and custom utilities
├── install-dotfiles.sh   # Main installation script
├── uninstall-dotfiles.sh # Main uninstallation script
├── *_manage.sh   # Individual component management
└── *.sh          # Individual installation modules

misc/             # Fonts, themes, and other assets
├── iterm2/       # iTerm2 settings and profiles
├── mesloLGS_NF/  # Nerd Font files
└── via/          # Keyboard layout configurations
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