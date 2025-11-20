# AeroSpace Window Manager - Deep Dive Assessment & Research Report

## Executive Summary

AeroSpace is an i3-like tiling window manager for macOS that has gained significant traction as a
superior alternative to Yabai and Amethyst, particularly for users who prefer not to disable System
Integrity Protection (SIP). After extensive research and analysis of your configuration, I've
identified the root cause of your floating window issues and compiled a comprehensive guide for
optimization.

## Current Configuration Analysis

### Your Setup

- **Workspaces**: 1 (Terminal), 2 (Code), 3-4 (Browsers), 5 (Note-taking), plus letter-based
  workspaces
- **Key Bindings**: Control+[1-6] for workspace switching, Control+Cmd+[letters] for specific apps
- **Window Detection Rules**: Automatic workspace assignment for various apps
- **Critical Issue**: Line 238 contains a catch-all rule making ALL windows float and move to
  workspace 0

### The Root Problem

```toml
[[on-window-detected]]
run = ['layout floating', 'move-node-to-workspace 0']
```

This catch-all rule at the end of your config is causing:

1. Activity Monitor and other apps to be forced into floating mode
2. Windows being moved to workspace 0 (which may not be visible)
3. Windows appearing "off-screen" because AeroSpace hides inactive workspace windows in corners

## Community Insights & Best Practices

### Why Users Love AeroSpace

1. **No SIP Disabling Required** - Unlike Yabai, works with full system security
2. **Superior Stability** - More reliable than Amethyst with fewer window tracking issues
3. **Better Floating Window Handling** - Floating windows remain navigable with keyboard
4. **Excellent Multi-Monitor Support** - i3-like paradigm works well across displays
5. **Simple Configuration** - Single TOML file, no GUI needed

### Common Issues & Solutions

#### 1. Floating Windows Disappearing (Your Issue)

**Problem**: Windows appear off-screen or in corners **Cause**: AeroSpace hides inactive workspace
windows by placing them outside visible area **Solutions**:

- Remove catch-all floating rules
- Use specific app detection for floating
- Add recovery keybindings
- Ensure monitors have free corner space

#### 2. Mission Control Issues

**Problem**: Windows appear tiny in Mission Control **Solution**: Enable "Group Windows by
Application" in System Settings → Desktop & Dock → Mission Control

#### 3. Native macOS Tabs

**Problem**: Each tab treated as separate window **Affected Apps**: Terminal apps with native tabs
**Solution**: Disable native tabs in affected applications

#### 4. Window Position Tracking

**Known Issue**: Floating window positions not always tracked properly (Issue #1519) **Workaround**:
Use service mode reset commands

## Comparison with Alternatives

### vs Yabai

| Feature          | AeroSpace          | Yabai                   |
| ---------------- | ------------------ | ----------------------- |
| SIP Required     | No                 | Yes (for full features) |
| Stability        | Excellent          | Good                    |
| Performance      | Fast               | Fast                    |
| Floating Windows | Better integration | Separate handling       |
| Learning Curve   | Moderate           | Steep                   |
| Community        | Growing rapidly    | Established             |

### vs Amethyst

| Feature            | AeroSpace   | Amethyst                   |
| ------------------ | ----------- | -------------------------- |
| Configuration      | File-based  | GUI + File                 |
| Reliability        | More stable | Occasional tracking issues |
| Flexibility        | High        | Moderate                   |
| Resource Usage     | Light       | Light                      |
| Active Development | Very active | Active                     |

## User Testimonials

- "After struggling with Yabai and Amethyst, AeroSpace has been a breath of fresh air" - Josean
  Martinez
- "It's already better than Yabai and Amethyst" - Reddit user
- "AeroSpace is probably the best tiling manager I've ever used on macOS" - DevOps Toolbox
- "Makes macOS usable when using big displays" - HackerNews user

## Known Limitations

1. **Ricing Support** - Minimal support for visual customization
2. **macOS Spaces** - Doesn't acknowledge native Spaces, uses own workspace implementation
3. **Floating Window Tracking** - Position/size tracking needs improvement
4. **Performance** - Window detection can be slow with many windows

## Recommended Configuration Patterns

### 1. Floating Window Management

```toml
# Good: Specific app rules
[[on-window-detected]]
if.app-id = 'com.apple.ActivityMonitor'
run = ['layout floating']

# Bad: Catch-all rules
[[on-window-detected]]
run = ['layout floating']  # Affects everything!
```

### 2. Service Mode for Recovery

```toml
[mode.service.binding]
r = ['flatten-workspace-tree', 'mode main']  # Reset layout
f = ['layout floating tiling', 'mode main']   # Toggle floating
c = ['move-node-to-monitor center', 'mode main']  # Center window
```

### 3. Workspace Organization

```toml
# Numeric for primary apps
ctrl-1 = 'workspace 1'  # Terminal
ctrl-2 = 'workspace 2'  # Code

# Letters for secondary apps
ctrl-cmd-c = 'workspace C'  # ChatGPT
ctrl-cmd-n = 'workspace N'  # Notion
```

## Performance Tips

1. **Reduce Workspace Count** - Fewer workspaces = better performance
2. **Disable Animations** - Enable "Reduce Motion" in macOS settings
3. **Monitor Arrangement** - Ensure free corner space for window hiding
4. **Limit on-window-detected Rules** - Too many rules slow detection

## Troubleshooting Guide

### Window Recovery Commands

```bash
# List all windows
aerospace list-windows

# Focus specific window
aerospace focus --window-id <id>

# Reset workspace layout
aerospace flatten-workspace-tree

# Toggle floating/tiling
aerospace layout floating tiling
```

### Debug Commands

```bash
# View window tree
aerospace list-tree

# Check current workspace
aerospace list-workspaces --focused

# Reload configuration
aerospace reload-config
```

## Future Development

### Upcoming Features (from GitHub issues)

- Sticky floating windows (Issue #2)
- Better floating window position tracking (Issue #1519)
- Conditional per-app bindings (Issue #1454)
- Socket protocol API (Issue #1513)

### Community Requests

- Better integration with Sketchybar
- Improved multi-monitor workspace management
- Enhanced floating window controls
- More granular window detection rules

## Recommendations for Your Setup

### Immediate Fixes

1. **Remove line 237-239** - The catch-all floating rule
2. **Add specific rules** for Activity Monitor and other system apps
3. **Implement recovery keybindings** in service mode
4. **Enable "Group Windows by Application"** in Mission Control

### Optimization Suggestions

1. **Consolidate workspace rules** - Group similar apps
2. **Add focus callbacks** for better mouse integration
3. **Configure gaps** appropriately for your monitor setup
4. **Set up workspace-to-monitor assignments** if using multiple displays

### Advanced Configurations

1. **Binding modes** for different contexts
2. **Custom scripts** via exec-on-workspace-change
3. **Integration with launcher** (Raycast/Alfred)
4. **Automated app launching** on startup

## Conclusion

AeroSpace represents the current best-in-class tiling window manager for macOS, especially for users
prioritizing stability and security. Your floating window issues stem from an overly broad
configuration rule that can be easily fixed. The community consensus is overwhelmingly positive,
with most users finding it superior to both Yabai and Amethyst.

The main trade-offs are minimal ricing support and some quirks with floating window positioning, but
these are far outweighed by the benefits of stability, ease of use, and excellent keyboard-driven
workflow support.

## Resources

- [Official Documentation](https://nikitabobko.github.io/AeroSpace/guide)
- [GitHub Repository](https://github.com/nikitabobko/AeroSpace)
- [Configuration Examples](https://github.com/nikitabobko/AeroSpace/tree/main/docs/config-examples)
- [Community Discussions](https://github.com/nikitabobko/AeroSpace/discussions)

---

_Generated: 2025-01-20_ _Research Sources: GitHub Issues, Reddit, HackerNews, YouTube tutorials,
Official documentation_
