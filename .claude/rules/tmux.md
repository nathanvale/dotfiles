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

## Templates

| Template | Layout | Use Case |
|----------|--------|----------|
| `standard` | 3 windows: claude, git, shell | Basic projects |
| `fullstack` | 4 windows: + dev, vault | Full-stack apps |
| `nextjs` | + conditional prisma/storybook | Next.js projects |
| `ultrawide` | 3 panes in 1 window | Ultrawide monitors, accordion toggle |

## Key Bindings

**Window switching:**
- `Ctrl-g 1/2/3` = Switch to window 1/2/3
- `Ctrl-g t` = Launch tx picker
- `Ctrl-g \` = Cycle tmux sessions

**Ultrawide/Accordion mode (pane-based layouts):**
- `Ctrl-g Space` = Toggle zoom (accordion ↔ tiled)
- `Ctrl-g F1/F2/F3/F4` = Jump to pane 1/2/3/4 (zoomed)
- `Ctrl-g T` = Tiled layout (all panes equal)
- `Ctrl-g E` = Even-horizontal (side-by-side)
- `Ctrl-g S` = Even-vertical (stacked)

## Development Guidelines

- Edit templates in `config/tmuxinator/` (not project-specific configs)
- Templates use ERB for smart detection (e.g., nextjs.yml checks for Prisma/Storybook)
- Claude window runs `ccdev` alias (25 local plugins for development)
- All scripts use `set -e` for fail-fast behavior
