# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Core Commands

**Installation and Setup:**
- `./install.sh` - Downloads and installs the complete dotfiles system via the Genie installer
- `genie/bin/genie --install` - Installs dotfiles after downloading scripts
- `genie/bin/genie --uninstall` - Uninstalls dotfiles

**Package Management:**
- `brew bundle --file=config/brew/Brewfile` - Install all Homebrew dependencies
- `brew bundle cleanup --file=config/brew/Brewfile` - Remove packages not in Brewfile

**Development Environment:**
- `tmux` - Terminal multiplexer (prefix: Ctrl-g)
- `tmuxinator start <project>` - Start tmuxinator project sessions
- `lazygit` - Terminal UI for git operations

## Architecture

This is a comprehensive macOS dotfiles system built around a custom installer called "Genie" that orchestrates the setup of development environments.

### Key Components

**Genie Installer (`genie/`):**
- Modular bash script system for installing/uninstalling dotfiles
- Downloads scripts from GitHub and executes them in order
- Handles brew packages, symlinks, macOS preferences, fonts, and iTerm2 settings

**Configuration Structure (`config/`):**
- Each tool has its own subdirectory (tmux, git, karabiner, etc.)
- Configs are symlinked to their proper locations during installation
- Supports both local and remote configuration management

**Installation Scripts (`genie/scripts/`):**
- Modular installation scripts for different components
- `installation_scripts.sh` - Defines script execution order
- Each script handles a specific aspect (brew, symlinks, fonts, etc.)

**Tmux Integration:**
- Custom tmux configuration with Ctrl-g prefix
- Tmuxinator project templates for different development environments
- Night Owl theme integration across terminal tools

**Raycast Extensions:**
- Custom Raycast extensions for productivity workflows
- Bluetooth device management, color tools, JSON formatting, etc.

### File Organization

```
config/           # All configuration files
├── tmux/         # Tmux configuration and themes
├── tmuxinator/   # Project session templates
├── brew/         # Homebrew package definitions
├── karabiner/    # Keyboard remapping rules
├── raycast/      # Raycast extension configurations
└── ...

genie/            # Installation system
├── bin/genie     # Main installer script
└── scripts/      # Individual installation modules

bin/              # Custom utilities and scripts
misc/             # Fonts, themes, and other assets
```

## Testing

The system includes Bats (Bash Automated Testing System) tests for critical installation scripts:
- `genie/scripts/ssh_config_remove.bats`
- `genie/scripts/uninstallation_scripts.bats`

Run tests with: `bats <test_file>`

## Development Notes

- All bash scripts use `set -e` for immediate exit on errors
- Installation scripts are downloaded from GitHub and executed in `/tmp/genie-*` directories
- Configuration changes should be made in the `config/` directory
- The system supports both installation and uninstallation workflows
- Tmux sessions are configured with vi-style keybindings and system clipboard integration