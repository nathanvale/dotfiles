# Bun-Runner Plugin

Smart test runner and linter integration for Bun/Biome with token-efficient output.

## Why Use MCP Tools Over CLI

| Direct CLI | Problem | MCP Tool | Benefit |
|------------|---------|----------|---------|
| `bun test` | Verbose output, all tests shown | `bun_runTests` | Failures only |
| `biome check` | Raw terminal output | `bun_lintCheck` | Structured errors |
| `biome check --write` | No summary | `bun_lintFix` | Fixed count + remaining |

**MCP tools are token-efficient** — They filter output to show only what matters.

## MCP Tools (6 Total)

### Testing
| Tool | When to Use |
|------|-------------|
| `bun_runTests` | Run all tests or filter by pattern |
| `bun_testFile` | Run tests for a specific file |
| `bun_testCoverage` | Check coverage (summary + low-coverage files) |

### Linting
| Tool | When to Use |
|------|-------------|
| `bun_lintCheck` | Check for issues (read-only, no changes) |
| `bun_lintFix` | Auto-fix issues (uses `--write`) |
| `bun_formatCheck` | Check formatting only |

## Hooks (Automatic)

**You don't need to call these** — they run automatically:

- **PostToolUse**: After every Write/Edit, Biome auto-fixes and tsc type-checks
- **Stop**: Before session ends, full project lint and type check

If hooks report errors, address them before continuing.

## When to Use Direct CLI

Only use direct CLI when:
- MCP tools aren't available (check with `/tools`)
- You need specific CLI flags not exposed by MCP tools
- Debugging hook behavior

## Common Patterns

```typescript
// Run tests for current file
bun_testFile({ filePath: "src/utils.test.ts" })

// Run tests matching pattern
bun_runTests({ testPattern: "auth" })

// Check lint without fixing (safe)
bun_lintCheck({ path: "src/" })

// Fix lint issues (modifies files)
bun_lintFix({ path: "src/utils.ts" })
```

## Exit Code Contract (Hooks)

- **0** — Success
- **2** — Blocking error (Claude must address)

## Location

Plugin: `~/code/side-quest-marketplace/bun-runner/`
