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

# 2. Run full setup (Homebrew + packages + symlinks + preferences)
./setup.sh
```

**Update existing installation:**
```bash
cd ~/code/dotfiles
git pull
./setup.sh symlinks   # Recreate symlinks
./setup.sh prefs      # Reapply macOS preferences
```

## What Gets Installed

### setup.sh (7 phases)
- **Phase 0:** Preflight checks (macOS, arch, network, disk)
- **Phase 1:** Xcode CLT + Homebrew + repo clone
- **Phase 2:** Claude Code (AI rescue — enables debugging for later phases)
- **Phase 3:** 16+ essential CLI tools (git, tmux, fzf, ripgrep, etc.)
- **Phase 4:** Development runtimes (Bun, Python, Node via fnm)
- **Phase 5:** All GUI apps from `config/brew/Brewfile`
- **Phase 6:** Symlinks for dotfiles + macOS preferences

Supports `--resume` to pick up where it left off and `--start-phase N` to skip ahead.

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
├── setup.sh              # Unified installer (full setup + subcommands)
├── verify_install.sh     # Post-install verification
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

Run `./setup.sh status` to see all symlinks and their status.

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
