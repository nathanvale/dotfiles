# Bash History MCP Server

MCP server for searching and retrieving bash command history using
[atuin](https://github.com/atuinsh/atuin).

## Features

- **Search command history** - Find commands using fuzzy search with atuin
- **Get recent commands** - Retrieve the most recent commands from your history
- **Exit code filtering** - Filter by successful commands or include failed ones
- **Rich formatting** - Displays timestamps, exit codes, and full command text
- **Fallback support** - Falls back to zsh history if atuin is unavailable

## Installation

This MCP server is already configured in your dotfiles at `.mcp.json`:

```json
{
  "mcpServers": {
    "bash-history": {
      "args": ["/Users/nathanvale/code/dotfiles/.claude/mcp-servers/bash-history/index.js"],
      "command": "node"
    }
  }
}
```

## Dependencies

Install dependencies:

```bash
npm install
# or
bun install
```

The server requires:

- `mcpez` - Minimal ESM wrapper for building MCP servers
- `@modelcontextprotocol/sdk` - MCP SDK
- `atuin` - Command-line tool (install via brew: `brew install atuin`)

## Tools

### search_history

Search command history using atuin with fuzzy matching.

**Parameters:**

- `query` (string, required) - Search query to find matching commands
- `limit` (number, optional, default: 10) - Maximum number of results to return
- `include_failed` (boolean, optional, default: false) - Include commands that failed (non-zero exit
  code)

**Example:**

```javascript
{
  "query": "git commit",
  "limit": 5,
  "include_failed": false
}
```

### get_recent_history

Get recent command history from atuin with timestamps and exit codes.

**Parameters:**

- `limit` (number, optional, default: 10) - Number of recent commands to retrieve
- `include_failed` (boolean, optional, default: false) - Include commands that failed (non-zero exit
  code)

**Example:**

```javascript
{
  "limit": 20,
  "include_failed": true
}
```

## Output Format

Both tools return formatted results with:

- ✅ Exit: 0 - Successful commands
- ❌ Exit: N - Failed commands (where N is the exit code)
- ❓ Exit: N/A - Fallback mode (zsh history)
- Timestamp - When the command was executed
- Full command text

**Example output:**

```
Found 3 commands:

1. ✅ Exit: 0 | Time: 2025-11-17 19:45:23
   git commit -m "feat: add new feature"

2. ✅ Exit: 0 | Time: 2025-11-17 19:42:10
   npm install mcpez

3. ❌ Exit: 1 | Time: 2025-11-17 19:40:05
   npm test
```

## Testing

Test the server manually:

```bash
node index.js
```

The server will start and communicate via stdio. Press Ctrl+C to stop.

## Built With

- [mcpez](https://github.com/johnlindquist/mcpez) - Minimal ESM wrapper for MCP servers
- [atuin](https://github.com/atuinsh/atuin) - Magical shell history

## License

MIT
