# Required VS Code Settings for Prompt Files

To enable the `/merge` and `/next` prompts to execute terminal commands automatically, you need to
configure VS Code's auto-approval settings.

## Enable Terminal Command Auto-Approval

### Option 1: Via Settings UI

1. Open VS Code Command Palette (Cmd+Shift+P)
2. Search for: `Preferences: Open User Settings`
3. Search for: `YOLO`
4. Enable: **"Chat > Tools > Global: Auto Approve"**

### Option 2: Via settings.json

Add to your VS Code `settings.json`:

```json
{
  "chat.agent.maxRequests": 300,
  "chat.tools.global.autoApprove": true
}
```

**To open settings.json:**

- Cmd+Shift+P → `Preferences: Open User Settings (JSON)`

## What These Settings Do

### `chat.tools.global.autoApprove`

- **Purpose**: Enables "YOLO mode" - auto-approves all tool operations
- **Effect**: Eliminates confirmation dialogs when running terminal commands
- **Security**: VS Code warns this is not recommended for untrusted workspaces
- **Use case**: Essential for `/merge` and `/next` prompts to work smoothly

### `chat.agent.maxRequests`

- **Purpose**: Maximum number of requests an agent can make before asking to continue
- **Default**: 25
- **Recommended**: 300 (allows longer autonomous workflows)
- **Effect**: Prevents "continue iteration" dialogs during complex tasks

## Selective Auto-Approval (Alternative)

If you prefer more control, you can enable auto-approval only for specific commands:

```json
{
  "chat.tools.terminal.autoApprove": {
    "/^Remove-Item\\b/i": false,
    "chmod": false,
    "chown": false,
    "curl": false,
    "del": false,
    "eval": false,
    "kill": false,
    "rm": false,
    "rmdir": false,
    "wget": false
  },
  "chat.tools.terminal.enableAutoApprove": true
}
```

This allows most commands but blocks potentially dangerous ones.

## References

- [VS Code 1.104 Release Notes - Global Auto Approve](https://code.visualstudio.com/updates/v1_104#_global-auto-approve)
- [Stack Overflow: Auto-approve Copilot commands](https://stackoverflow.com/questions/79720577/)
- [VS Code Copilot Tools Documentation](https://code.visualstudio.com/docs/copilot/chat/chat-tools)

## Testing the Configuration

After applying settings:

1. Reload VS Code window (Cmd+Shift+P → `Developer: Reload Window`)
2. Open Chat view
3. Type `/merge` or `/next`
4. Commands should execute without confirmation dialogs
