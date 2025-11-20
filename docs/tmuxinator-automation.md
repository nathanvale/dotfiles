# Tmuxinator Automation Guide

## Overview
Automated tmuxinator configuration generation that follows your standard template:
1. **claude** window (always first)
2. **git** window with lazygit (always second)  
3. **Project-specific windows** (auto-detected based on project type)

## Quick Commands

### Generate Config for Current Directory
```bash
tmuxnew
# or
tnew
```

### Generate Config for Named Project
```bash
tmuxnew my-project
# or
tnew my-project
```

### Generate and Start Immediately
```bash
tmuxgen [project-name]
```

### Jump to Project and Start
```bash
tcd my-project
# Changes to ~/code/my-project and starts tmuxinator
# Offers to generate config if it doesn't exist
```

### Session Menu (within tmux)
```bash
Ctrl-g T
# Opens fuzzy finder with all projects
# Now offers to auto-generate configs for new projects
```

## Auto-Detection Features

The generator automatically detects project types and adds appropriate windows:

### Next.js Projects
- Detects: `package.json` with "next" dependency
- Adds: `nextjs` window with `pnpm dev`
- Optional: `storybook` window if @storybook detected
- Optional: `prisma` window if prisma detected

### React Projects  
- Detects: `package.json` with "react" dependency
- Adds: `dev` window with `npm run dev`

### Rails Projects
- Detects: `Gemfile` with rails gem
- Adds: `rails` and `console` windows

### Python Projects
- Detects: `requirements.txt`, `pyproject.toml`, or `Pipfile`
- Adds: `python` window with Python REPL

### Rust Projects
- Detects: `Cargo.toml`
- Adds: `cargo` window with `cargo watch`

### Go Projects
- Detects: `go.mod`
- Adds: `go` window with `go run .`

### Default
- If no framework detected, adds generic `shell` window

## Project Name Validation

The generator automatically normalizes project names for tmuxinator/tmux compatibility:

### Common Normalizations
- **Dot files**: `.claude` → `dot-claude` (fixes tmuxinator compatibility)
- **Dots in names**: `my.project` → `my-project` (dots break tmuxinator)
- **Special characters**: `project$test` → `project-test`
- **Spaces**: `My Project` → `my-project`
- **Reserved names**: `default` → `default-project`
- **Long names**: Truncated to 50 characters with ellipsis

### Why This Matters
- **Critical**: Tmuxinator silently fails when project names contain dots
- **Shell safety**: Special characters can break tmux session management  
- **Display**: Long names cause tmux interface issues
- **Consistency**: Predictable naming across all projects

When normalization occurs, you'll see a clear message explaining what changed and why.

## Manual Editing

After generation, you can:
- Edit immediately when prompted
- Edit later: `tmuxinator edit project-name`
- The YAML files are in `~/.config/tmuxinator/`

## All Tmuxinator Aliases

```bash
mux          # tmuxinator
tl           # tmuxinator list
ts           # tmuxinator start
te           # tmuxinator edit
tn           # tmuxinator new
td           # tmuxinator delete
tmuxnew      # Generate new config
tnew         # Generate new config (short)
tmuxgen      # Generate and start
tcd          # Jump to project and start
```

## Example Workflow

1. Clone or create a new project:
   ```bash
   cd ~/code
   git clone https://github.com/user/new-project
   cd new-project
   ```

2. Generate tmuxinator config:
   ```bash
   tmuxnew
   # Detects project type automatically
   # Offers to edit if needed
   # Offers to start immediately
   ```

3. Or do it all in one command:
   ```bash
   tcd new-project
   # Changes directory, generates config, and starts session
   ```

## Files Created

- **Generator Script**: `bin/tmuxinator-new-project.sh`
- **Enhanced Menu**: `bin/tmux-session-menu.sh`  
- **Aliases**: `config/zsh/tmuxinator-aliases.zsh`
- **Configs**: `~/.config/tmuxinator/[project].yml`