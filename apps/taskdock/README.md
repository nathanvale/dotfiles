# TaskDock

**TaskDock** is an agentic task orchestration and worktree management system for multi-agent
workflows. It provides a unified CLI for managing tasks, locks, worktrees, validation, merges, and
observability—designed to be both human- and AI-agent-friendly.

## Quick Start

```bash
# Initialize TaskDock in your repo
taskdock init

# Get next available task
taskdock next

# Create worktree for a task
taskdock worktree create MPCU-0017

# Validate your work
taskdock validate

# Merge when done
taskdock merge --current
```

## Features

- **Task Intake**: Atomic lock-based task selection with dependency resolution
- **Worktree Management**: Isolated development environments per task
- **Validation Pipeline**: Consistent format/type/lint/test across mono and single repos
- **Git Integration**: Provider-aware merge automation (GitHub/Azure DevOps)
- **Health Monitoring**: Lock cleanup, status dashboards, and observability
- **Telemetry**: Correlation IDs and structured JSON logging for agent debugging
- **Config Hierarchy**: Layered defaults → user → repo → env → CLI flags
- **Concurrency Safety**: flock-based protection for multi-agent workflows

## Documentation

- [Full Documentation](docs/README.md)
- [Configuration Guide](docs/config.md)
- [Command Reference](docs/commands.md)
- [Concurrency Safety](docs/CONCURRENCY.md)
- [Shell Compatibility](docs/SHELL_COMPATIBILITY.md)
- [Future Plans](docs/future-plans.md)

## Requirements

- **Bash 4.0+** (5.0+ recommended) - [See compatibility guide](docs/SHELL_COMPATIBILITY.md)
- **Git 2.25+**
- **jq** (for JSON processing)
- **yq** (for YAML config)
- **flock** (for concurrency safety)
- **Optional**: gh (GitHub), az (Azure DevOps), pnpm (validation)

## Architecture

```
taskdock/
├── bin/taskdock          # Front-door CLI dispatcher
├── commands/             # Command implementations (validate, merge, health)
├── lib/                  # Shared utilities (config, logging, UI, git)
├── tasks/                # Task intake & locking
├── worktrees/            # Worktree lifecycle management
├── review/               # Task generation from reviews
├── ux/                   # Editor/tmux integrations
├── config/               # Default configurations
└── docs/                 # Documentation
```

## Version

TaskDock v0.1.0

---

**Note**: TaskDock is designed for agentic workflows. All commands support `--json` output and
provide actionable error messages with correlation IDs for debugging.
