---
paths:
  - "bin/tmux/**"
  - "config/tmux/**"
  - "config/tmuxinator/**"
---

# Tmux Session Management

## TX Session Launcher

```bash
tx                          # Interactive fzf picker
tx project-name             # Start with standard template
tx ~/code/app fullstack     # Use specific template
tx .                        # Current directory
Ctrl-g t                    # Same as 'tx' (tmux binding)
```

## Templates (3 Universal Templates)

| Template | Windows | Use Case |
|----------|---------|----------|
| `standard` | claude + git + shell | Basic projects |
| `fullstack` | + dev server + vault | Full-stack apps |
| `nextjs` | + conditional prisma/storybook | Next.js projects |

## Key Bindings

- `Ctrl-g` = tmux prefix
- `Ctrl-g g` = Switch to git (lazygit)
- `Ctrl-g c` = Switch to claude window
- `Ctrl-g t` = Launch tx picker
- `Ctrl-g \` = Cycle tmux sessions

## Development Guidelines

- Edit templates in `config/tmuxinator/` (not project-specific configs)
- Templates use ERB for smart detection (e.g., nextjs.yml checks for Prisma/Storybook)
- Claude window runs `ccdev` alias (25 local plugins for development)
- All scripts use `set -e` for fail-fast behavior
