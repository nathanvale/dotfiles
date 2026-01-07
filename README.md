# Nathan's Dotfiles

A comprehensive macOS development environment setup featuring terminal tools, keyboard orchestration, and productivity extensions.

## Quick Start (Fresh Mac)

**One-liner:**
```bash
curl -fsSL https://raw.githubusercontent.com/nathanvale/dotfiles/main/setup.sh | bash
```

**Or step by step:**
```bash
# 1. Clone the repo
git clone git@github.com:nathanvale/dotfiles.git ~/code/dotfiles
cd ~/code/dotfiles

# 2. Install Homebrew + packages (one-time)
./bootstrap.sh

# 3. Create symlinks + apply preferences
./install.sh
```

**Update existing installation:**
```bash
cd ~/code/dotfiles
git pull
./install.sh
```

## What Gets Installed

### bootstrap.sh (run once)
- Xcode Command Line Tools
- Homebrew
- All packages from `config/brew/Brewfile`

### install.sh (run anytime)
- Symlinks for dotfiles (`.zshrc`, `.gitconfig`, etc.)
- Symlinks for config directories (`.config` → `config/`)
- VS Code settings and keybindings
- Claude Code personal settings
- macOS preferences

## Features

- **HyperFlow**: Hyper key (Right Cmd) orchestration for app switching and keyboard shortcuts
- **Terminal**: Custom tmux config with Night Owl theme, Ctrl-g prefix
- **Shell**: Zsh with syntax highlighting, autosuggestions, and fzf
- **Git**: Lazygit, delta for diffs, conventional commits
- **Productivity**: Raycast, Karabiner-Elements, SuperWhisper voice dictation

## Key Bindings

| Key | Action |
|-----|--------|
| `Ctrl-g` | tmux prefix |
| `Hyper+1-5` | Switch to workspace apps |
| `Hyper+H/J/K/L` | Arrow navigation (Vim-style) |
| `Hyper+\\` | Cycle tmux sessions |

## Project Structure

```
~/code/dotfiles/
├── bootstrap.sh          # One-time Homebrew setup
├── install.sh            # Symlinks + preferences
├── setup.sh              # Curl-able installer
├── config/               # All configuration files
│   ├── brew/Brewfile     # Homebrew packages
│   ├── tmux/             # Tmux configuration
│   ├── karabiner/        # Keyboard remapping
│   ├── vscode/           # VS Code settings
│   ├── claude/           # Claude Code settings
│   └── ...
├── bin/                  # Scripts and utilities
│   ├── dotfiles/         # Symlink management
│   └── ...
└── .zshrc, .gitconfig    # Root dotfiles
```

## Symlinks Created

| Link | Target |
|------|--------|
| `~/.config` | `dotfiles/config` |
| `~/.zshrc` | `dotfiles/.zshrc` |
| `~/.gitconfig` | `dotfiles/.gitconfig` |
| `~/.tmux.conf` | `dotfiles/config/tmux/tmux.conf` |
| `~/.claude/CLAUDE.md` | `dotfiles/config/claude/CLAUDE.md` |
| `~/bin` | `dotfiles/bin` |
| VS Code settings | `dotfiles/config/vscode/` |

Run `./install.sh status` to see all symlinks and their status.

## Post-Install

1. **Restart terminal** or `source ~/.zshrc`
2. **Copy secrets**: `cp .env.example .env` and fill in API keys
3. **Start tmux**: `tmux` or use tmuxinator projects

## Customization

### Add Homebrew packages
```bash
# Edit config/brew/Brewfile
brew "new-package"
cask "new-app"

# Then run
brew bundle --file=config/brew/Brewfile
```

### Add new symlinks
Edit `bin/dotfiles/symlinks/symlinks_manage.sh` and add to the `symlinks` array.

## Requirements

- macOS (Apple Silicon or Intel)
- Internet connection
- Admin privileges for Homebrew

## License

MIT
