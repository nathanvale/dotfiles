# AeroSpace Configuration Improvements

## Overview
This document outlines all the improvements made to your AeroSpace configuration to address the accordion mode state issue and enhance your overall workflow.

## Key Problems Solved

### 1. Accordion Mode State Loss
**Problem**: When switching workspaces, accordion mode doesn't remember which window was expanded.

**Solution**: Added DFS (Depth-First Search) navigation and indexed focus commands that allow you to predictably select specific windows by position rather than relying on the unreliable MRU (Most Recently Used) order.

### 2. Limited Navigation Options
**Problem**: Only had left/right navigation, making it difficult to navigate complex layouts.

**Solution**: Added complete directional navigation (up/down/left/right) and sequential DFS navigation.

## New Keybindings

### Layout Management
- `Ctrl + Cmd + T`: Force tiles layout
- `Ctrl + Cmd + A`: Force accordion layout  
- `Ctrl + Cmd + H`: Horizontal accordion layout
- `Ctrl + Cmd + V`: Vertical accordion layout
- `Ctrl + Cmd + /`: Toggle between tiles and accordion (existing)

### Enhanced Navigation
- `Ctrl + Cmd + -`: Focus left (existing)
- `Ctrl + Cmd + =`: Focus right (existing)
- `Ctrl + Cmd + [`: Focus up (NEW)
- `Ctrl + Cmd + ]`: Focus down (NEW)
- `Ctrl + Cmd + ,`: Focus previous window in DFS order (NEW)
- `Ctrl + Cmd + .`: Focus next window in DFS order (NEW)

### Window Movement
- `Ctrl + Cmd + Shift + -`: Move window left (NEW)
- `Ctrl + Cmd + Shift + =`: Move window right (NEW)
- `Ctrl + Cmd + Shift + [`: Move window up (NEW)
- `Ctrl + Cmd + Shift + ]`: Move window down (NEW)

### Workspace Navigation
- `Alt + Tab`: Toggle between last two workspaces (existing)
- `Ctrl + Tab`: Next workspace (NEW)
- `Ctrl + Shift + Tab`: Previous workspace (NEW)

### Quick App Launchers
- `Ctrl + Cmd + Enter`: Launch Ghostty terminal (NEW)
- `Ctrl + Alt + Cmd + C`: Launch VS Code (NEW)
- `Ctrl + Alt + Cmd + B`: Launch Arc browser (NEW)
- `Ctrl + Alt + Cmd + N`: Launch Notion (NEW)

### Fullscreen Controls
- `Ctrl + Cmd + Shift + F`: AeroSpace fullscreen (NEW)
- `Ctrl + Cmd + Shift + .`: macOS native fullscreen (NEW)

## Enhanced Service Mode (Ctrl + Cmd + ;)

### Existing Commands
- `Esc`: Reload config
- `r`: Reset layout (flatten workspace tree)
- `f`: Toggle floating/tiling
- `Backspace`: Close all windows but current

### New Recovery Commands
- `t`: Force tiling layout
- `l`: Force floating layout
- `0`: Go to workspace 0 (recovery workspace)

### New Layout Commands
- `a`: Switch to accordion layout
- `h`: Horizontal accordion
- `v`: Vertical accordion
- `s`: Switch to tiles layout
- `b`: Balance window sizes

### New Navigation Commands
- `n`: Next workspace
- `p`: Previous workspace
- `1`: Focus first window (by DFS index)
- `2`: Focus second window (by DFS index)
- `3`: Focus third window (by DFS index)

## Enhanced Resize Mode (Ctrl + Cmd + ')

### Existing Commands
- `b`: Balance sizes
- `-`: Decrease size by 150px
- `=`: Increase size by 150px

### New Commands
- `Shift + -`: Decrease size by 50px (fine control)
- `Shift + =`: Increase size by 50px (fine control)
- `h`: Decrease width by 50px
- `l`: Increase width by 50px
- `j`: Increase height by 50px
- `k`: Decrease height by 50px

## Visual Improvements

### Gap Configuration
Updated gaps for better visual separation:
- **Built-in display**: 5px gaps (was 1px)
- **External displays**: 10px gaps (was 8px)
- Applies to both inner (between windows) and outer (screen edges) gaps

## Accordion Mode Workflow

### The Problem
When you have windows in accordion mode and switch workspaces, AeroSpace doesn't remember which window was expanded. It uses MRU (Most Recently Used) to determine focus, which often expands the wrong window.

### The Solution
Use DFS navigation and indexed focusing to predictably control which window expands:

1. **Return to workspace with predictable focus**:
   - Use `Ctrl + Cmd + ;` then `1` to always focus the first window
   - Use `Ctrl + Cmd + ;` then `2` for the second window
   - Use `Ctrl + Cmd + ;` then `3` for the third window

2. **Navigate sequentially**:
   - Use `Ctrl + Cmd + ,` and `Ctrl + Cmd + .` to move through windows in order
   - This gives you predictable navigation regardless of MRU state

3. **Force specific layouts**:
   - Use `Ctrl + Cmd + A` to ensure accordion mode
   - Use `Ctrl + Cmd + H` or `V` for specific accordion orientations

### Example Workflow
You have 3 windows in accordion on workspace 2: Terminal, Browser, Notes

1. Switch to workspace 1: `Ctrl + 1`
2. Do some work
3. Return to workspace 2: `Ctrl + 2`
4. Force focus on Terminal: `Ctrl + Cmd + ;` then `1`
5. Exit service mode and Terminal is expanded

## Tips for Daily Use

### Quick Recovery
If windows get messed up:
1. `Ctrl + Cmd + ;` to enter service mode
2. `r` to reset the layout
3. `b` to balance sizes

### Floating Window Management
If a floating window disappears:
1. `Ctrl + Cmd + ;` then `0` to check workspace 0
2. Or `Ctrl + Cmd + ;` then `f` to toggle floating/tiling

### Consistent Layouts
For predictable window arrangements:
1. Use `Ctrl + Cmd + T` for tiles when you need side-by-side
2. Use `Ctrl + Cmd + A` for accordion when focusing on one task
3. Use service mode numbers (1, 2, 3) to focus specific positions

### Visual Comfort
The increased gaps (5px/10px) provide:
- Better visual separation between windows
- Easier to see window boundaries
- More breathing room for your eyes

## Performance Notes

- DFS navigation is more CPU-efficient than spatial navigation
- The gap increases have minimal performance impact
- Service mode commands are instant (no animation delay)
- App launchers use `exec-and-forget` for non-blocking execution

## Troubleshooting

### If accordion state still seems random
1. Use service mode + number keys for explicit positioning
2. Consider using tiles layout for more predictable behavior
3. Use DFS navigation (`Ctrl + Cmd + ,/.`) for sequential access

### If keybindings conflict
Check for conflicts with:
- System shortcuts (System Settings → Keyboard → Shortcuts)
- Other apps (especially Raycast, Alfred, etc.)
- VS Code shortcuts when focused

### If windows still disappear
1. Check workspace 0: `Ctrl + 0`
2. Use `aerospace list-windows` in terminal
3. Reload config: `Ctrl + Cmd + ;` then `Esc`

## Future Considerations

While these improvements significantly enhance your workflow, be aware:
- True accordion state persistence would require AeroSpace core changes
- The MRU behavior is deeply embedded in AeroSpace's architecture
- These workarounds provide practical solutions until official fixes arrive

---

*Configuration enhanced on 2025-01-20*
*Addresses accordion state issues, adds comprehensive navigation, and improves visual comfort*