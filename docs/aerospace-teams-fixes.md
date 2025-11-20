# Microsoft Teams + AeroSpace Configuration Guide

## The Problems with Teams & Tiling Window Managers

Microsoft Teams has several known issues with tiling window managers:

1. **Multiple Windows**: When joining meetings, Teams creates separate windows that interfere with tiling
2. **Fullscreen Issues**: Meeting windows don't handle fullscreen properly in tiled layouts  
3. **Dialog Windows**: Settings and join dialogs get tiled when they should float
4. **Resize Problems**: Teams ignores resize events from window managers
5. **Focus Issues**: Switching between chat and meeting windows causes focus problems

## Solutions Implemented

### 1. **Smart Window Detection**

Added specific rules for Teams windows:

```toml
# Main Teams window goes to workspace 5
[[on-window-detected]]
if.app-id = 'com.microsoft.teams2'
run = "move-node-to-workspace 5"

# Meeting windows automatically float
[[on-window-detected]]
if.app-id = 'com.microsoft.teams2'
if.window-title-regex-substring = '(Meeting|Call|Screen Share|Share)'
run = ['layout floating']

# Dialog windows float
[[on-window-detected]]
if.app-id = 'com.microsoft.teams2'
if.window-title-regex-substring = '(Settings|Options|Preferences|Join|Audio|Video)'
run = ['layout floating']
```

### 2. **Quick Meeting Access**

**Problem**: Hard to quickly access and fullscreen Teams meetings

**Solutions**:
- `Ctrl + Cmd + 5`: Jump to Teams workspace and fullscreen
- Service mode `m`: Same as above (Ctrl+Cmd+; then m)

### 3. **Window Management for Meetings**

When in a Teams meeting:
1. Meeting window automatically floats (no tiling interference)
2. Use `Ctrl + Cmd + Shift + F` for AeroSpace fullscreen
3. Use `Ctrl + Cmd + 5` to quickly jump and fullscreen

## Recommended Teams Workflow

### Before Meeting
1. Teams main window is on workspace 5
2. Join meeting normally - window will auto-float

### During Meeting
1. **Quick fullscreen**: `Ctrl + Cmd + 5`
2. **Toggle fullscreen**: `Ctrl + Cmd + Shift + F`
3. **Exit fullscreen**: `Ctrl + Cmd + Shift + F` again

### Multiple Participants
- Meeting window floats independently
- Chat stays on workspace 5 in tiles
- Use `Alt + Tab` to switch between them

## Common Teams Issues & Fixes

### Issue: Meeting window gets tiled and becomes tiny
**Fix**: Meeting windows now auto-float. If not working:
1. `Ctrl + Cmd + ;` then `f` to toggle floating
2. Or `Ctrl + Cmd + ;` then `r` to reset

### Issue: Can't see screen shares properly
**Fix**: 
1. Use `Ctrl + Cmd + 5` for instant fullscreen
2. Meeting windows are set to auto-float for better screen share viewing

### Issue: Multiple Teams windows mess up workspace
**Fix**: 
- Main chat window goes to workspace 5
- Meeting/call windows auto-float (don't affect tiling)
- Settings dialogs auto-float

### Issue: Teams doesn't respond to window manager
**Fix**: This is a known Teams bug on all platforms. Our config works around it by:
- Floating meeting windows (avoids resize conflicts)
- Using AeroSpace fullscreen instead of native
- Keeping main window tiled but meetings floating

## Alternative Approaches

If you still have issues:

### 1. **Float All Teams Windows**
```toml
[[on-window-detected]]
if.app-id = 'com.microsoft.teams2'
run = ['layout floating']
```

### 2. **Dedicated Teams Workspace**
- Keep workspace 5 just for Teams
- Use tiles for main window
- Let meetings auto-float over it

### 3. **Manual Control**
- Use service mode `f` to toggle any Teams window
- Use `Ctrl + Cmd + 5` when joining meetings

## Testing Your Setup

1. **Join a test meeting**:
   - Meeting window should auto-float
   - Main chat should stay on workspace 5

2. **Try fullscreen**:
   - `Ctrl + Cmd + 5` should jump to workspace 5 and fullscreen
   - `Ctrl + Cmd + Shift + F` should toggle fullscreen

3. **Check dialogs**:
   - Settings should auto-float
   - Join meeting dialog should auto-float

## Troubleshooting

### Teams windows still getting tiled
1. Check the app ID: `aerospace list-windows --all | grep -i teams`
2. Might be `com.microsoft.teams` instead of `com.microsoft.teams2`
3. Update config accordingly

### Meeting quality issues
This is often due to Teams + tiling WM interactions:
- Use the auto-float for meetings (already configured)
- Consider using Teams in browser instead of app
- Browser Teams works better with tiling managers

### Multiple meeting windows
Teams sometimes creates multiple windows:
- They should all auto-float with current config
- Use `Ctrl + 0` to check workspace 0 for lost windows

## Known Limitations

1. **Teams is not optimized for tiling WMs**: Microsoft doesn't test with window managers
2. **Resize events ignored**: Teams has bugs with external resize commands
3. **Native fullscreen conflicts**: Use AeroSpace fullscreen instead
4. **Focus stealing**: Teams aggressively steals focus during calls

## Alternative: Teams in Browser

Consider using Teams in Arc/Chrome:
- Better window manager compatibility
- No app-specific window issues
- Still has meeting functionality
- Can tile normally as browser windows

Browser Teams works at: https://teams.microsoft.com

---

*Teams configuration optimized for AeroSpace on 2025-01-20*