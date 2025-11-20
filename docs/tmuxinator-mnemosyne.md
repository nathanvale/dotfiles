# 🧠 Mnemosyne Tmuxinator Setup

Smart tmux development environment for Next.js + Prisma + Storybook projects using **pnpm**.

## Quick Start

```bash
# Setup a new mnemosyne project
~/code/dotfiles/bin/setup_mnemosyne.sh ~/code/mnemosyne

# Start the development environment
tmuxinator start mnemosyne
```

## Layout Overview

When you run `tmuxinator start mnemosyne`, you get these windows with **base-index 1**:

| Key | Window    | Command                                                            |
| --- | --------- | ------------------------------------------------------------------ |
| 1   | storybook | `pnpm storybook`                                                   |
| 2   | dev       | `pnpm dev 2>&1 \| tee -a .logs/dev.$(date +%s).log \| pino-pretty` |
| 3   | prisma    | `pnpm prisma studio`                                               |
| 4   | git       | `lazygit`                                                          |
| 5   | logs      | `lnav .logs`                                                       |

## Features

### 🚀 Auto-launch VS Code

- VS Code opens automatically when the session starts
- Only opens once per session (won't spam multiple instances)

### 📊 Smart Logging

- Dev server logs are saved to `.logs/dev.{timestamp}.log`
- Logs are piped through `pino-pretty` for readable output
- Use `lnav .logs` to view logs with syntax highlighting

### 🌿 Session-aware Environment Loading

- Uses **direnv** to automatically load `.env.development`
- Create `.envrc` in your project root:

  ```bash
  # Load .env.development if it exists
  if [ -f .env.development ]; then
    use dotenv .env.development
  fi
  ```

### 🏷️ Auto-named Windows

- Each window automatically shows the current git branch
- Format: `{window}:{branch}` (e.g., `dev:feature/auth`, `storybook:main`)

## Navigation

Use standard tmux keybindings:

- `Ctrl-b 1` → storybook window
- `Ctrl-b 2` → dev server window
- `Ctrl-b 3` → prisma studio window
- `Ctrl-b 4` → git window
- `Ctrl-b 5` → logs window

## Prerequisites

```bash
# Install tmuxinator
gem install tmuxinator

# Install direnv (optional but recommended)
brew install direnv

# Install lnav for log viewing (optional)
brew install lnav

# Install lazygit for git management
brew install lazygit
```

## Project Structure

Your project should have this structure:

```text
mnemosyne/
├── .envrc              # direnv configuration
├── .env.development    # development environment variables
├── .gitignore          # includes .logs/ directory
├── .logs/              # auto-created, stores dev server logs
├── package.json        # with pnpm scripts
└── ... (rest of your Next.js/Prisma project)
```

## Manual Setup

If you prefer manual setup instead of using the script:

1. **Create project directory and logs folder:**

   ```bash
   mkdir -p ~/code/mnemosyne/.logs
   ```

2. **Add .logs/ to .gitignore:**

   ```bash
   echo ".logs/" >> ~/code/mnemosyne/.gitignore
   ```

3. **Create .envrc for direnv:**

   ```bash
   cp ~/code/dotfiles/templates/.envrc ~/code/mnemosyne/.envrc
   direnv allow
   ```

4. **Start the session:**

   ```bash
   tmuxinator start mnemosyne
   ```

## Troubleshooting

### Windows start at index 0 instead of 1

- The config sets `base-index 1` in tmux options
- If this doesn't work, add to your `~/.tmux.conf`:

  ```tmux
  set -g base-index 1
  ```

### VS Code doesn't auto-launch

- Check that `code` command is available in your PATH
- The script uses a temporary file to prevent multiple launches

### Logs window shows "No log files found"

- Wait a moment for the dev server to start creating logs
- The logs window will automatically detect when logs are created

### direnv not working

- Make sure direnv is installed: `brew install direnv`
- Add to your shell profile: `eval "$(direnv hook zsh)"`
- Allow the directory: `direnv allow`

## Customization

Edit `~/.config/tmuxinator/mnemosyne.yml` to customize:

- Change window names
- Add/remove windows
- Modify commands
- Adjust logging behavior

## Related Files

- Configuration: `~/.config/tmuxinator/mnemosyne.yml`
- Setup script: `~/code/dotfiles/bin/setup_mnemosyne.sh`
- Templates: `~/code/dotfiles/templates/`
