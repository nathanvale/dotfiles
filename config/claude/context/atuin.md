# Atuin Plugin

Shell history search and insights via MCP tools. Captures all Bash commands with context.

## MCP Tools (4 Total)

| Tool | When to Use |
|------|-------------|
| `atuin_search_history` | Fuzzy/prefix/full-text search with filters (time, dir, exit code) |
| `atuin_get_recent_history` | Get N most recent commands |
| `atuin_search_by_context` | Filter by git branch or Claude session ID |
| `atuin_history_insights` | Stats on frequent commands and failure patterns |

## Common Patterns

```typescript
// Find recent failed commands
atuin_search_history({ query: "", exitCode: 1, limit: 10 })

// Search by directory
atuin_search_history({ query: "docker", directory: "~/code/project" })

// Get commands from current branch
atuin_search_by_context({ gitBranch: "feature/auth" })

// Frequency analysis
atuin_history_insights({ type: "frequent", limit: 20 })
```

## Automatic Capture

**PostToolUse hook** captures all `Bash` commands Claude executes:
- Command text and exit code
- Git branch context
- Claude session ID
- Stored in `~/.claude/atuin-context.jsonl`

## Fallback Behavior

If Atuin unavailable, falls back to: `fc -l | grep [query]`

## Location

Plugin: `~/code/side-quest-marketplace/atuin/`
