# Window Management with Raycast

HyperFlow now includes integrated window management using Raycast + Karabiner.

## Keyboard Shortcuts

**Hyper Key = Ctrl + Option + Command (all held together)**

### Window Positioning (Vim-style)
- **Hyper + H**: Move window to left half
- **Hyper + J**: Move window to bottom half
- **Hyper + K**: Move window to top half
- **Hyper + L**: Move window to right half

### Other Window Commands
- **Hyper + M**: Maximize window
- **Hyper + F**: Toggle fullscreen
- **Hyper + C**: Center window

## How It Works

1. **Karabiner** intercepts Hyper+Key combinations
2. Triggers Raycast window management via deeplinks
3. Raycast moves/resizes the focused window instantly

## Setup Requirements

### 1. Enable Raycast Window Management

Open Raycast → Extensions → Window Management → Enable

### 2. Grant Accessibility Permissions

Raycast will prompt for Accessibility permissions on first use.

**System Settings → Privacy & Security → Accessibility → Enable Raycast**

### 3. Karabiner Configuration

Already configured in `config/karabiner/karabiner.json`

Rule: "Window Management - Hyper Key (Ctrl+Opt+Cmd) + Vim Keys"

## Testing

Try these combinations:
1. Open any app (e.g., Chrome)
2. Press **Ctrl+Opt+Cmd+H** → Window moves to left half
3. Press **Ctrl+Opt+Cmd+L** → Window moves to right half
4. Press **Ctrl+Opt+Cmd+M** → Window maximizes
5. Press **Ctrl+Opt+Cmd+K** → Window moves to top half

## Troubleshooting

### Shortcuts not working

1. **Check Karabiner is running**:
   ```bash
   ps aux | grep karabiner
   ```

2. **Check Raycast has Accessibility permissions**:
   System Settings → Privacy & Security → Accessibility

3. **Test Raycast deeplink manually**:
   ```bash
   open 'raycast://extensions/raycast/window-management/left-half'
   ```

### Wrong window gets resized

- Ensure the window you want to resize is focused (clicked)
- Raycast operates on the frontmost window

## Available Raycast Window Management Commands

You can add more shortcuts by using these deeplinks:

```bash
# Halves
raycast://extensions/raycast/window-management/left-half
raycast://extensions/raycast/window-management/right-half
raycast://extensions/raycast/window-management/top-half
raycast://extensions/raycast/window-management/bottom-half

# Corners (quarters)
raycast://extensions/raycast/window-management/top-left-quarter
raycast://extensions/raycast/window-management/top-right-quarter
raycast://extensions/raycast/window-management/bottom-left-quarter
raycast://extensions/raycast/window-management/bottom-right-quarter

# Thirds
raycast://extensions/raycast/window-management/first-third
raycast://extensions/raycast/window-management/center-third
raycast://extensions/raycast/window-management/last-third

# Other
raycast://extensions/raycast/window-management/maximize
raycast://extensions/raycast/window-management/center
raycast://extensions/raycast/window-management/toggle-fullscreen
raycast://extensions/raycast/window-management/reasonable-size
raycast://extensions/raycast/window-management/restore
```

## Customization

### Add More Shortcuts

Edit `config/karabiner/karabiner.json` and add new manipulators:

```json
{
  "from": { "key_code": "u", "modifiers": { "mandatory": ["control", "option", "command"] } },
  "to": [{ "shell_command": "open 'raycast://extensions/raycast/window-management/top-left-quarter'" }],
  "type": "basic"
}
```

### Change Hyper Key Combination

Modify the `"mandatory"` array to use different modifiers:
- `"control"` = Ctrl
- `"option"` = Option/Alt
- `"command"` = Cmd
- `"shift"` = Shift

## Migration from AeroSpace

If you were using AeroSpace before:

✅ **Removed**: AeroSpace workspace management
✅ **Kept**: SuperWhisper mode switching (still works!)
✅ **Added**: Raycast window management
✅ **Simplified**: One less background daemon

### What Changed

**Before (with AeroSpace):**
- AeroSpace managed workspaces + windows
- Custom keybindings in `aerospace.toml`
- app-launcher.sh triggered by AeroSpace

**Now (without AeroSpace):**
- Karabiner triggers app launches directly
- Raycast handles window positioning
- No tiling manager needed

## Performance

- **Startup**: No heavy daemons (Raycast is already running)
- **Memory**: Minimal (no AeroSpace)
- **Speed**: Instant window snapping
- **Reliability**: Raycast is battle-tested

## Notes

- Hyper key (Ctrl+Opt+Cmd) is ergonomic when using left hand on keyboard
- Vim keys (H/J/K/L) provide muscle memory for direction
- Works with any app that has windows
- Raycast respects macOS window management APIs
