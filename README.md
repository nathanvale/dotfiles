# Nathan's Dotfiles

A comprehensive macOS development environment setup featuring terminal tools, window management, and productivity extensions.

## Features

- **Terminal Environment**: Custom tmux configuration with Night Owl theme
- **Package Management**: Automated Homebrew package installation
- **Window Management**: AeroSpace tiling window manager
- **Productivity**: Raycast extensions for enhanced workflows
- **Development Tools**: Git, Lazygit, and shell configurations
- **Keyboard Customization**: Karabiner-Elements key remapping

## Quick Start

```bash
git clone https://github.com/nathanvale/dotfiles.git
cd dotfiles
./install.sh
```

## Installation Options

### Full Installation
```bash
./install.sh
```

### Individual Components
```bash
# Install specific components
./bin/brew_install.sh          # Homebrew packages
./bin/symlinks_install.sh      # Configuration symlinks
./bin/nerd_fonts_install.sh    # Nerd Fonts
./bin/iterm_preferences_install.sh  # iTerm2 settings
./bin/macos_preferences_install.sh  # macOS preferences
```

### Uninstallation
```bash
./bin/uninstall-dotfiles.sh
```

## Key Components

### Terminal Configuration
- **tmux**: Custom configuration with Ctrl-g prefix
- **tmuxinator**: Project session templates
- **Night Owl theme**: Consistent theming across terminal tools

### Development Tools
- **Git**: Custom configurations and ignore patterns
- **Lazygit**: Terminal UI for git operations
- **Homebrew**: Package management with curated Brewfile

### Productivity Extensions
- **Raycast**: Custom extensions for workflow automation
- **AeroSpace**: Tiling window manager for macOS
- **Karabiner-Elements**: Advanced keyboard customization

### Key Bindings
- **tmux prefix**: Ctrl-g
- **Vi-style navigation**: Throughout terminal applications
- **Custom key mappings**: Via Karabiner-Elements

## Project Structure

```
config/           # Configuration files
   tmux/         # Tmux configuration and themes
   tmuxinator/   # Project session templates
   brew/         # Homebrew package definitions
   karabiner/    # Keyboard remapping rules
   raycast/      # Raycast extension configurations
   git/          # Git configuration
   ...

bin/              # Installation and utility scripts
   install-dotfiles.sh      # Main installation script
   uninstall-dotfiles.sh    # Main uninstallation script
   *.sh          # Individual component scripts

misc/             # Fonts, themes, and assets
```

## Customization

### Adding Packages
Edit `config/brew/Brewfile` to add new Homebrew packages:
```ruby
brew "package-name"
cask "application-name"
```

### Tmux Projects
Create new tmuxinator projects in `config/tmuxinator/`:
```yaml
name: my-project
root: ~/code/my-project
windows:
  - editor: vim
  - console: 
```

### Raycast Extensions
Custom extensions are located in `config/raycast/extensions/`

## Development

### Individual Scripts
All installation scripts can be run independently:
- `brew_install.sh` - Homebrew installation
- `dotfiles_install.sh` - Main dotfiles setup
- `symlinks_install.sh` - Configuration symlinks
- `nerd_fonts_install.sh` - Font installation
- `iterm_preferences_install.sh` - iTerm2 setup
- `macos_preferences_install.sh` - System preferences

### Script Guidelines
- All scripts use `set -e` for immediate exit on errors
- Scripts are idempotent and can be run multiple times
- Individual components can be installed/uninstalled independently

## Requirements

- macOS (tested on recent versions)
- Internet connection for package downloads
- Administrator privileges for system modifications

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the installation process
5. Submit a pull request

## License

MIT License - see LICENSE file for details