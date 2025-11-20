# Atuin Integration for Claude Code

## Overview

This document details the atuin shell history integration with Claude Code, including architecture decisions, implementation options, and rationale for our approach.

## Problem Statement

**Original Goals:**
1. **Write**: Bash commands executed by Claude Code should appear in your shell history
2. **Read**: Claude Code should be able to query and learn from your command history patterns

## Architecture

### Current Implementation: Hybrid Approach

```
┌─────────────────────────────────────────────────────────────┐
│                     Claude Code Session                      │
│                                                               │
│  User: "What kubectl commands have I run?"                   │
│     │                                                         │
│     ├─► bash-history-assistant skill triggers                │
│     │   (natural language → atuin CLI)                       │
│     │                                                         │
│     └─► Claude runs: atuin search "kubectl" --cmd-only       │
└─────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    │   Bash Tool Call   │
                    └─────────┬─────────┘
                              │
                    ┌─────────▼─────────┐
                    │  PostToolUse Hook  │
                    │(atuin-post-tool.sh)│
                    └─────────┬─────────┘
                              │
                    ┌─────────▼─────────┐
                    │  Write to         │
                    │  ~/.zsh_history   │
                    └─────────┬─────────┘
                              │
                    ┌─────────▼─────────┐
                    │  Atuin Auto-Import │
                    │  (on shell start)  │
                    └─────────┬─────────┘
                              │
                    ┌─────────▼─────────┐
                    │  Atuin Database    │
                    │  (queryable via    │
                    │   Skill → CLI)     │
                    └───────────────────┘
```

### Component 1: Write Hook (✅ Implemented)

**File:** `.claude/hooks/atuin-post-tool.sh`

**How it works:**
1. Receives JSON from Claude Code after each Bash command execution
2. Parses command and exit code
3. Writes to `~/.zsh_history` in standard zsh format: `: <timestamp>:<duration>;<command>`
4. Atuin automatically imports from zsh history (either on next shell start or via `atuin import auto`)

**Key Features:**
- No external dependencies (pure bash)
- Works without `$ATUIN_SESSION` environment variable
- Idempotent (safe to run multiple times)
- Lightweight and fast

### Component 2: Query Interface (✅ Implemented via Skill)

**File:** `~/.claude/skills/bash-history-assistant/SKILL.md`

**How it works:**
1. Claude Code skill that guides Claude on using Atuin CLI directly
2. No MCP server required (no ATUIN_SESSION dependency issues)
3. Uses standard `atuin search`, `atuin stats`, and `atuin history` commands
4. Automatically triggered by natural language queries about command history

## Integration Options Analysis

### Option A: bash-history-mcp MCP Server ❌ NOT WORKING

**Repository:** https://github.com/nitsanavni/bash-history-mcp

**What it provides:**

1. **MCP Server Tools:**
   - `search_history(query, limit, include_failed)` - Search commands by pattern
   - `get_recent_history(limit, include_failed)` - Get recent commands with metadata

2. **Features:**
   - Fuzzy search with atuin's powerful search engine
   - Filter by exit code (successful commands only by default)
   - Returns actual atuin command used (helps Claude learn atuin CLI)
   - Clean MCP integration with Claude Code

**Installation:**

```bash
claude mcp add -s user bash-history bunx -- github:nitsanavni/bash-history-mcp mcp
```

Or manually add to `~/.claude/settings.json`:

```json
{
  "mcpServers": {
    "bash-history": {
      "command": "bunx",
      "args": ["github:nitsanavni/bash-history-mcp", "mcp"]
    }
  }
}
```

**Pros:**
- ✅ Zero maintenance (external dependency via bunx)
- ✅ Well-designed MCP interface
- ✅ Includes both search and recent history tools
- ✅ Filters failed commands by default
- ✅ Returns the actual atuin command for learning
- ✅ Easy to upgrade (just restart Claude Code)
- ✅ Automatically benefits from upstream improvements

**Cons:**
- ❌ **FAILS IN CLAUDE CODE**: Requires `$ATUIN_SESSION` environment variable which doesn't exist in Claude Code
- ❌ External dependency (requires network on first run)
- ❌ Requires bun runtime
- ❌ MCP tools don't work without active shell session

**Example Usage in Claude Code:**

```typescript
// Search for git commands
mcp__bash-history__search_history({
  query: "git commit",
  limit: 5,
  include_failed: false
})

// Get recent successful commands
mcp__bash-history__get_recent_history({
  limit: 10,
  include_failed: false
})
```

### Option B: Custom CLI Script

**Create a simple wrapper script:**

```bash
#!/bin/bash
# bin/atuin-query.sh

LIMIT="${2:-10}"

case "$1" in
  search)
    atuin search --limit "$LIMIT" --format "{command}" "$3"
    ;;
  recent)
    atuin search --limit "$LIMIT" --format "{command}" ""
    ;;
  *)
    echo "Usage: $0 {search|recent} [limit] [query]"
    exit 1
    ;;
esac
```

**Pros:**
- ✅ No external dependencies
- ✅ Full control over implementation
- ✅ Simple bash script
- ✅ Easy to customize

**Cons:**
- ❌ Requires manual Bash tool calls (less ergonomic)
- ❌ No MCP integration (Claude can't discover it)
- ❌ Need to maintain yourself
- ❌ No structured responses
- ❌ Manual filtering required

**Example Usage in Claude Code:**

```bash
# Claude would need to use Bash tool directly
bash bin/atuin-query.sh search 5 "git commit"
bash bin/atuin-query.sh recent 10
```

### Option C: Direct Atuin CLI

**Just use atuin directly via Bash tool:**

```bash
atuin search --limit 5 --search-mode fuzzy --format "{exit}\t{command}" "git"
```

**Pros:**
- ✅ No dependencies
- ✅ Maximum flexibility
- ✅ Direct access to all atuin features
- ✅ Works in Claude Code (no environment variable requirements)

**Cons:**
- ❌ Claude needs to learn atuin CLI syntax
- ❌ Verbose command syntax
- ❌ No automatic discovery
- ❌ Manual parsing required

### Option D: Claude Code Skill (Direct Atuin CLI) ⭐ RECOMMENDED & IMPLEMENTED

**Create a skill that teaches Claude how to use Atuin CLI:**

**File:** `~/.claude/skills/bash-history-assistant/SKILL.md`

**How it works:**
1. Skill provides comprehensive documentation on atuin CLI usage
2. Includes common search patterns, formatting options, and examples
3. Automatically triggers on natural language queries about command history
4. No MCP server or environment variables required

**Pros:**
- ✅ **Works reliably in Claude Code** (no ATUIN_SESSION required)
- ✅ No external dependencies (just atuin CLI)
- ✅ Natural language triggers ("what command did I use...")
- ✅ Comprehensive examples and patterns built-in
- ✅ Maximum flexibility - full atuin CLI access
- ✅ Easy to maintain and customize
- ✅ No network dependency
- ✅ Automatic skill discovery by Claude

**Cons:**
- ❌ Not an MCP server (but this is actually a benefit - no environment issues)
- ❌ Requires creating and maintaining skill file (already done)

**Example Usage in Claude Code:**

Natural language queries automatically trigger the skill:
- "What kubectl commands have I run?"
- "Show me failed git commands from today"
- "What's my most common docker command?"

Or invoke directly:
```bash
/skill bash-history-assistant
```

## Recommendation: Claude Code Skill (Option D)

**Recommended Approach:** Use bash-history-assistant skill with direct Atuin CLI

**Rationale:**

1. **Reliability First:**
   - ✅ No ATUIN_SESSION environment variable dependency
   - ✅ Works consistently in Claude Code subprocess environment
   - ✅ No MCP server startup failures
   - ✅ No external network dependencies

2. **Best User Experience:**
   - ✅ Natural language triggers work automatically
   - ✅ Comprehensive examples and patterns built-in
   - ✅ Claude learns atuin CLI for direct use when needed
   - ✅ Skill is always available (no server to start)

3. **Low Maintenance:**
   - ✅ Single markdown file to maintain
   - ✅ No external service dependencies
   - ✅ Easy to customize for specific workflows
   - ✅ No version compatibility issues

4. **Maximum Flexibility:**
   - ✅ Full access to all atuin CLI features
   - ✅ Can use latest atuin features immediately
   - ✅ Custom formatting and filtering options
   - ✅ Direct control over search modes and parameters

## Implementation Status

### ✅ Completed

1. **Write Hook:** `.claude/hooks/atuin-post-tool.sh`
   - Commands are written to `~/.zsh_history`
   - Atuin imports from zsh history automatically
   - No `$ATUIN_SESSION` errors
   - Clean, simple implementation

2. **Query Interface:** `~/.claude/skills/bash-history-assistant/SKILL.md`
   - Comprehensive skill for querying command history
   - Natural language triggers configured
   - Examples for common search patterns
   - No MCP server required (uses direct Atuin CLI)

3. **Settings Updated:** `.claude/settings.json`
   - Removed broken bash-history-mcp PostToolUse hook
   - Kept atuin-post-tool.sh for writing to history
   - Clean configuration

### ✅ Testing

Try these queries in your next Claude Code session:
- "What kubectl commands have I run?"
- "Show me git commands from this week"
- "What's my most common docker command?"
- "Find that curl command I used"

Or invoke the skill directly:
```bash
/skill bash-history-assistant
```

### 🔧 Optional Enhancements

1. **Enable debug logging for write hook:**
   ```bash
   export CLAUDE_ATUIN_DEBUG=1
   ```

2. **Customize the skill:**
   - Edit `~/.claude/skills/bash-history-assistant/SKILL.md`
   - Add project-specific search patterns
   - Add custom trigger phrases

## Debugging

### Write Hook Logs

**Log file:** `.claude/hooks/atuin-hook.log`

**Enable debug logging:**
```bash
export CLAUDE_ATUIN_DEBUG=1
```

**Verify commands are being logged:**
```bash
tail -f .claude/hooks/atuin-hook.log
```

**Verify commands in zsh history:**
```bash
tail ~/.zsh_history | grep -a "command-to-find"
```

**Verify commands in atuin:**
```bash
atuin search "command-to-find"
```

**Force import from zsh:**
```bash
atuin import auto
```

### MCP Server Debugging

**Test MCP server directly:**
```bash
bunx github:nitsanavni/bash-history-mcp mcp
```

**Check Claude Code MCP configuration:**
```bash
cat ~/.claude/settings.json | jq '.mcpServers'
```

## FAQ

### Q: Why not use bash-history-mcp's hook implementation?

**A:** The bash-history-mcp hook uses `atuin history start/end` which requires the `$ATUIN_SESSION` environment variable. This variable only exists in active shell sessions, not in Claude Code's subprocess environment. Our custom hook writes directly to `~/.zsh_history`, which atuin imports automatically.

### Q: Will this work with bash instead of zsh?

**A:** Yes, but you need to modify `.claude/hooks/atuin-post-tool.sh` to write to `~/.bash_history` instead and adjust the format. The zsh format is: `: <timestamp>:<duration>;<command>`

### Q: Can I query atuin from within Claude Code?

**A:** Yes! We use the bash-history-assistant skill which:
1. **Skill-based (Implemented):** Uses `~/.claude/skills/bash-history-assistant/`
   - Automatically triggers on natural language queries
   - Uses direct atuin CLI (no environment variables needed)
   - Works reliably in Claude Code subprocess environment

Alternative approaches (not recommended):
2. **MCP Server:** Doesn't work - requires ATUIN_SESSION environment variable
3. **Direct atuin:** Works but requires manual Bash tool calls

### Q: How do I clear the atuin database?

**A:**
```bash
# Clear all history
atuin history clear

# Or delete the database
rm -rf ~/.local/share/atuin/history.db
```

### Q: Does this sync across machines?

**A:** If you have atuin sync enabled (via `atuin register` or `atuin login`), yes! Commands added to your local database will sync to other machines.

## References

- [Atuin GitHub](https://github.com/atuinsh/atuin)
- [bash-history-mcp GitHub](https://github.com/nitsanavni/bash-history-mcp)
- [Claude Code MCP Documentation](https://code.claude.com/docs/en/mcp)
- [Post Tool Use Hooks](https://code.claude.com/docs/en/hooks)

## File Locations

- **Query Skill:** `~/.claude/skills/bash-history-assistant/SKILL.md`
- **Write Hook:** `.claude/hooks/atuin-post-tool.sh`
- **Hook Logs:** `.claude/hooks/atuin-hook.log`
- **Zsh History:** `~/.zsh_history`
- **Atuin Database:** `~/.local/share/atuin/history.db`
- **Claude Settings:** `~/.claude/settings.json`
