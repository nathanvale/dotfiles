---
paths:
  - "bin/**"
  - "apps/**"
  - "config/**"
---

# Dotfiles Architecture Rules

## Core Architecture Pattern

**Modular Installation System:**
- Each component (brew, symlinks, preferences) has dedicated `install`/`uninstall`/`manage` scripts
- Critical hotspots: `execute_scripts` (orchestration), `get_config` (configuration), `log_error` (error handling)
- Domain organization: `bin/dotfiles/`, `bin/system/`, `bin/tmux/`, `bin/utils/`
- Major applications: `apps/taskdock/`, `apps/hyperflow/`, `apps/vault/`
- **All scripts use `set -e` (fail-fast) and are idempotent (safe to run multiple times)**

## Symlink Strategy

- **Root dotfiles** (`.zshrc`, `.npmrc`, `.gitconfig`) → symlinked from `$HOME` to repo root
- **Config directories** (`config/<tool>/`) → symlinked to `$HOME/.config/<tool>/`
- **Management tool:** `bin/dotfiles/symlinks/symlinks_manage.sh` (single source of truth)

## Secrets Pattern

1. Store sensitive data in `.env.secrets` (git-ignored)
2. Source in `.zshrc` to export variables
3. Config files use `${VAR_NAME}` substitution (e.g., `.npmrc` uses `${NPM_TOKEN}`)
4. **Never hardcode secrets** — always use environment variable references

## Key Scripts Reference

| Script | Purpose |
|--------|---------|
| `bin/dotfiles/symlinks/symlinks_manage.sh` | Manage all configuration symlinks |
| `bin/dev/homebrew/brew_remote_bundle.sh` | Install/update Homebrew packages from Brewfile |
| `config/macos/defaults.common.sh` | Configure macOS user-domain preferences |
| `config/macos/defaults.server.sh` | Configure macOS server-specific settings (sudo) |
| `bin/tmux/tx` | Universal tmux session launcher (replaces 20+ project configs) |
| `bin/utils/colour_log.sh` | Standardized logging utilities (source in all scripts) |

## Script Development Rules

1. **Always** start scripts with `set -e` for fail-fast behavior
2. **Always** source `bin/utils/colour_log.sh` for consistent logging
3. Keep scripts **modular** — prefer multiple small scripts over monoliths
4. Test scripts **independently** before integrating into orchestration workflows
5. For tmux work, edit **universal templates** (`config/tmuxinator/`) — avoid project-specific configs

## File Organization Pattern

```
bin/          → Installation system, utilities, CLI shims (→ apps/)
apps/         → Major applications (taskdock, hyperflow, vault)
config/       → All configuration files (tmux, git, karabiner, etc.)
.claude/      → Claude Code configuration (commands, agents, skills)
misc/         → Fonts, themes, assets
Root dotfiles → Symlinked from $HOME to repo root
```
