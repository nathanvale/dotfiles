# Tmuxinator Project Configuration

Streamlined tmuxinator setup with template-based project generation for fast, consistent development environment creation.

## Quick Start

### Create a New Project

```bash
# Navigate to the scripts directory
cd ~/.config/tmuxinator/scripts

# Create a basic project (Claude + Git)
./create-project.sh my-cli-tool basic ~/code/my-cli-tool

# Create a standard project (Claude + Git + Shell)
./create-project.sh my-lib standard ~/code/my-lib

# Create a fullstack project (Claude + Git + Dev + Vault)
./create-project.sh my-webapp fullstack ~/code/my-webapp

# Create an AI-powered project (Multi-AI agents + tools)
./create-project.sh ai-experiment ai ~/experiments/ai-test

# Create a dual-AI project (Claude + Gemini + tools)
./create-project.sh stimulus-app dual-ai ~/code/stimulus-app
```

### Start Your Project

```bash
tmuxinator start my-webapp
```

## Project Templates

### Basic (2 windows)
**Use for:** Simple CLI tools, libraries, utility projects
- **Windows:** Claude + Git
- **Example:** `dotfiles`, `orchestr8-legacy`

### Standard (3 windows)
**Use for:** Most development projects
- **Windows:** Claude + Git + Shell
- **Example:** `capture-bridge`, `paicc-1`, `vtm-cli`

### Fullstack (4 windows)
**Use for:** Web applications with dev servers
- **Windows:** Claude + Git + Dev + Vault
- **Dev window:** Runs `npm run dev` automatically
- **Vault window:** Shows vault status and shortcuts
- **Example:** `entain-next-to-go`, `mpcu-build-and-deliver`

### AI (4+ windows)
**Use for:** Experimental projects with multiple AI agents
- **Windows:** AI Agents (tiled layout) + Git + Dev + Vault
- **AI panes:** Claude + Gemini + Codex + Shell
- **Layout:** Tiled (4-quadrant grid)

### Dual-AI (4 windows)
**Use for:** Projects using two AI agents side-by-side
- **Windows:** AI Agents (vertical split) + Git + Dev + Vault
- **AI panes:** Claude + Gemini
- **Layout:** Main-vertical (side-by-side)

## File Structure

```
~/.config/tmuxinator/
├── README.md                    # This file
├── _templates.yml               # Template library (reference only)
├── _base.yml                    # Legacy base configuration
├── scripts/
│   ├── common-setup.sh          # Shared functions
│   └── create-project.sh        # Project generator
├── *.yml                        # Project configurations
└── tmuxinator-backup-*.tar.gz   # Automatic backups
```

## Common Customizations

### Override Dev Command

If your project uses a different dev command (e.g., `bun run dev` instead of `npm run dev`):

```yaml
# Edit your project's .yml file
windows:
  # ... other windows ...
  - dev:
      panes:
        - |
          source ~/.config/tmuxinator/scripts/common-setup.sh
          pane_setup "dev"
          bun run dev  # Custom command
```

### Add Custom Windows

Add project-specific windows after the standard ones:

```yaml
windows:
  # Standard windows (from template)
  - claude:
      panes:
        - |
          source ~/.config/tmuxinator/scripts/common-setup.sh
          pane_setup "claude"
          claude
  - git:
      panes:
        - |
          source ~/.config/tmuxinator/scripts/common-setup.sh
          pane_setup "git"
          lazygit

  # Custom window
  - storybook:
      panes:
        - |
          source ~/.config/tmuxinator/scripts/common-setup.sh
          pane_setup "storybook"
          npm run storybook
```

### Change Startup Window

By default, projects start in the `claude` window. To change this:

```yaml
startup_window: git  # Start in git window instead
startup_pane: 1
```

## VS Code Integration

All templates include automatic VS Code opening:

- **First window load:** VS Code opens automatically
- **Marker file:** `/tmp/tmux_<project-name>_vscode_opened`
- **Cleanup:** Marker is removed when project stops

To disable auto-open for a specific project, remove the `pre_window` hook.

## Available Functions

From `scripts/common-setup.sh`:

### Core Functions
- `pane_setup <window_name>` - Sets up pane with proper naming
- `setup_vscode_marker <project>` - Initializes VS Code auto-open
- `cleanup_vscode_marker <project>` - Removes VS Code marker
- `open_vscode_once <project>` - Opens VS Code once per session

### Vault Functions
- `vault_check [project]` - Check vault registration status
- `open_project_vault [project]` - Open project vault
- `auto_register_vaults` - Auto-register vaults for current directory

### Parallel Task Functions
- `setup_parallel_task_pane <window> <index> <auto_launch>` - Setup parallel agent pane
- `create_parallel_task_window <num_agents> <auto_launch>` - Create multi-agent window

## Troubleshooting

### Validate YAML Syntax

```bash
yamllint ~/.config/tmuxinator/<project>.yml
```

### Debug Project Configuration

```bash
tmuxinator debug <project>
```

### List All Projects

```bash
tmuxinator list
```

### Test Without Starting

```bash
tmuxinator start --dry-run <project>
```

### Check for Duplicates

```bash
# Count lines to identify unnecessarily large configs
wc -l ~/.config/tmuxinator/*.yml
```

## Best Practices

### 1. Use Templates
Always start with `create-project.sh` instead of copying existing files.

### 2. Keep It Simple
Don't add custom complexity unless necessary. The templates handle 90% of use cases.

### 3. Project Naming
Use kebab-case for project names: `my-awesome-project`

### 4. Root Paths
Use absolute paths for project roots:
- ✅ `/Users/nathanvale/code/my-project`
- ✅ `~/code/my-project`
- ❌ `./my-project` (relative paths don't work)

### 5. Version Control
Project `.yml` files should be committed to dotfiles repo for portability.

## What Changed (Refactoring Summary)

### ✅ Removed
- All `.logs/` directory creation and management
- `setup_logs()` function calls
- `cleanup_logs()` function calls
- Log file piping (`| tee -a .logs/...`)
- 85% of duplicate code across projects

### ✅ Added
- `create-project.sh` generator script
- Template-based approach with 5 project types
- Comprehensive documentation (this file)
- Streamlined configuration (average 30-40 lines vs 60-70 lines)

### ✅ Kept
- VS Code auto-open functionality
- Vault integration
- Pane naming and setup
- Parallel task functions
- All custom window configurations

## Examples

### Simple CLI Tool
```bash
./scripts/create-project.sh my-cli basic ~/code/my-cli
tmuxinator start my-cli
```

### Next.js Web App
```bash
./scripts/create-project.sh my-nextjs-app fullstack ~/code/my-nextjs-app
# Edit dev command if needed (e.g., change to 'bun run dev')
tmuxinator start my-nextjs-app
```

### AI Experimentation
```bash
./scripts/create-project.sh ai-proto ai ~/experiments/ai-proto
tmuxinator start ai-proto
# Claude, Gemini, and Codex panes ready in tiled layout
```

## Resources

- [Tmuxinator Official Repo](https://github.com/tmuxinator/tmuxinator)
- [Thoughtbot: Templating tmux with tmuxinator](https://thoughtbot.com/blog/templating-tmux-with-tmuxinator)
- [Tmux Manual](https://man.openbsd.org/tmux)

---

**Last Updated:** 2025-11-21
**Maintained By:** nathanvale
