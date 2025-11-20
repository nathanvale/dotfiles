# AeroSpace Quick Reference Guide

## Your Fixed Configuration

### What Changed

1. ✅ **Removed the problematic catch-all rule** that was sending all windows to floating workspace
   0
2. ✅ **Added specific floating rules** for Activity Monitor and system utilities
3. ✅ **Enhanced service mode** with recovery commands
4. ✅ **Added smart detection** for dialog windows (Open/Save/Export/Import)

## Key Bindings Reference

### Workspace Navigation

- `Ctrl + 1-6`: Switch to numbered workspaces
- `Ctrl + 0`: Switch to workspace 0 (utility workspace)
- `Ctrl + Cmd + C`: ChatGPT
- `Ctrl + Cmd + S`: Today (calendar)
- `Ctrl + Cmd + M`: Messages
- `Ctrl + Cmd + F`: Finder
- `Ctrl + Cmd + O`: 1Password
- `Ctrl + Cmd + P`: Podcasts
- `Ctrl + Cmd + N`: Notion
- `Ctrl + Cmd + R`: Reminders
- `Ctrl + Cmd + I`: Music

### Window Management

- `Ctrl + Cmd + -`: Focus left
- `Ctrl + Cmd + =`: Focus right
- `Ctrl + Cmd + .`: Fullscreen toggle
- `Alt + Tab`: Workspace back-and-forth

### Moving Windows

- `Ctrl + Shift + 1-6`: Move window to workspace and follow
- `Ctrl + Alt + Shift + ←/→`: Move to monitor

### Service Mode (Ctrl + Cmd + ;)

- `Esc`: Reload config
- `r`: Reset layout (flatten workspace tree)
- `f`: Toggle floating/tiling
- `t`: Force tiling layout (NEW)
- `l`: Force floating layout (NEW)
- `0`: Go to workspace 0 to check for hidden windows (NEW)
- `Backspace`: Close all windows but current

### Resize Mode (Ctrl + Cmd + ')

- `b`: Balance window sizes
- `-`: Decrease size
- `=`: Increase size
- `Enter/Esc`: Exit mode

## Troubleshooting

### If Activity Monitor Disappears

1. Press `Ctrl + Cmd + ;` to enter service mode
2. Press `0` to go to workspace 0 (where it might be hidden)
3. OR press `r` to reset the layout
4. OR press `c` to center the window

### If Any Window Goes Off-Screen

1. Use `Ctrl + Cmd + ;` then `r` to reset layout
2. Or use `Ctrl + Cmd + ;` then `f` to toggle floating/tiling
3. Or manually focus the window with terminal:
   ```bash
   aerospace list-windows  # Find the window ID
   aerospace focus --window-id <ID>
   ```

### Mission Control Fix

If windows appear tiny in Mission Control:

1. Open System Settings → Desktop & Dock → Mission Control
2. Enable "Group Windows by Application"

## Terminal Commands

### Useful AeroSpace Commands

```bash
# Reload configuration
aerospace reload-config

# List all windows
aerospace list-windows

# List workspace tree
aerospace list-tree

# Focus specific window
aerospace focus --window-id <ID>

# Move window to center
aerospace move center

# Toggle floating/tiling for current window
aerospace layout floating tiling
```

## Apps with Special Handling

### Always Float

- Activity Monitor
- System Preferences/Settings
- System Information
- Calculator
- Color utilities
- CleanMyMac
- Dialog windows (Open/Save/Export/Import)

### Auto-Workspace Assignment

- Ghostty → Workspace 1
- VS Code → Workspace 2
- Arc Browser → Workspace 3
- Teams → Workspace 5
- Outlook → Workspace 6
- Various apps → Letter workspaces

## Pro Tips

1. **Quick Recovery**: `Ctrl + Cmd + ;` then `r` fixes most layout issues
2. **Lost Windows**: Check workspace 0 (`Ctrl + 0`)
3. **Force Floating**: `Ctrl + Cmd + ;` then `l`
4. **Force Tiling**: `Ctrl + Cmd + ;` then `t`
5. **Center Window**: `Ctrl + Cmd + ;` then `c`

## Monitor Setup

Ensure your monitors have free corner space:

- System Settings → Displays → Arrange
- Leave space in bottom-right or bottom-left corners
- This is where AeroSpace hides inactive workspace windows

## Performance Tips

1. Enable "Reduce Motion" in System Settings → Accessibility → Display
2. Keep workspace count reasonable (you're using ~15 which is fine)
3. Restart AeroSpace after config changes: `aerospace reload-config`

---

_Your AeroSpace is now optimized! The Activity Monitor issue should be completely resolved._
