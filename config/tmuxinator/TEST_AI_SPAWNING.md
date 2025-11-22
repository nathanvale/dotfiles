# Testing AI Agent Spawning

## Quick Test Instructions

### 1. Reload Tmux Config

From **within any tmux session**:

```
Ctrl-g + r
```

You should see: "Config reloaded!"

### 2. Test the New Bindings

The bindings have been simplified! Now use:

| Old (didn't work) | New (simpler) | What it does |
|-------------------|---------------|--------------|
| `Ctrl-g + A + c` | `Ctrl-g + Shift+C` | Spawn Claude |
| `Ctrl-g + A + g` | `Ctrl-g + Shift+G` | Spawn Gemini |
| `Ctrl-g + A + o` | `Ctrl-g + Shift+O` | Spawn OpenAI |
| `Ctrl-g + A + x` | `Ctrl-g + Shift+X` | Spawn Codex |
| `Ctrl-g + A + w` | `Ctrl-g + Shift+N` | New AI window |

**How to press `Ctrl-g + Shift+C`:**
1. Press and hold `Ctrl+g`
2. Release both
3. Press and hold `Shift+c` (produces uppercase C)

### 3. Manual Test

If the keybindings still don't work, you can test the script directly:

```bash
# From within a tmux session, run in a terminal pane:
~/.config/tmuxinator/scripts/spawn-ai-agent.sh claude

# Or specify details:
~/.config/tmuxinator/scripts/spawn-ai-agent.sh gemini current horizontal
```

### 4. Verify Bindings Are Loaded

From within tmux, enter command mode and list bindings:

```
Ctrl-g + :
list-keys | grep spawn-ai-agent
```

You should see output like:
```
bind-key    -T prefix       C                 run-shell "$HOME/.config/tmuxinator/scripts/spawn-ai-agent.sh claude current horizontal"
bind-key    -T prefix       G                 run-shell "$HOME/.config/tmuxinator/scripts/spawn-ai-agent.sh gemini current horizontal"
...
```

### 5. Common Issues

**Issue: "Config reloaded!" doesn't appear**
- Solution: You're not in a tmux session. Start one first: `tmuxinator start dotfiles`

**Issue: Binding does nothing**
- Solution 1: Make sure you released Ctrl-g before pressing the next key
- Solution 2: Check if another binding is using that key: `Ctrl-g + : list-keys`
- Solution 3: Use manual spawning: `~/.config/tmuxinator/scripts/spawn-ai-agent.sh claude`

**Issue: "Not in a tmux session" error**
- Solution: You must be inside tmux for this to work. Start: `tmuxinator start <project>`

**Issue: "spawn-ai-agent.sh: Permission denied"**
- Solution: `chmod +x ~/.config/tmuxinator/scripts/spawn-ai-agent.sh`

### 6. Complete Example Workflow

```bash
# Step 1: Start a tmuxinator project
tmuxinator start dotfiles

# Step 2: You're now in Claude window

# Step 3: Reload tmux config
Ctrl-g + r
# → Should see "Config reloaded!"

# Step 4: Spawn Gemini
Ctrl-g + (release) + Shift+G
# → Should see new pane appear with Gemini setup

# Step 5: Spawn OpenAI
Ctrl-g + (release) + Shift+O
# → Should see another pane appear with OpenAI setup

# Step 6: Verify layout
# → Should see all panes in tiled layout (evenly distributed)
```

## Debugging Commands

### Check if script exists and is executable
```bash
ls -lh ~/.config/tmuxinator/scripts/spawn-ai-agent.sh
# Should show: -rwxr-xr-x (executable)
```

### Test script help
```bash
~/.config/tmuxinator/scripts/spawn-ai-agent.sh --help
```

### Check tmux config syntax
```bash
tmux source-file ~/.config/tmux/tmux.conf
# Should have no errors
```

### List all prefix bindings
```bash
# From within tmux:
Ctrl-g + :
list-keys -T prefix
```

## Updated Keyboard Reference

**New Simplified Bindings:**

```
Ctrl-g + C    →  Spawn Claude (horizontal)
Ctrl-g + G    →  Spawn Gemini (horizontal)
Ctrl-g + O    →  Spawn OpenAI (horizontal)
Ctrl-g + X    →  Spawn Codex (horizontal)
Ctrl-g + N    →  New AI window
```

**Remember:**
- `Ctrl-g` is your prefix (like pressing Escape in Vim)
- After pressing `Ctrl-g`, release it
- Then press `Shift+letter` (uppercase)

**Example for Gemini:**
1. Press `Ctrl` and `g` together
2. Release both
3. Press `Shift` and `g` together (produces `G`)
4. Gemini pane spawns!

## Success Indicators

When spawning works correctly, you'll see:

1. **Screen splits** - New pane appears
2. **Loading message** - "🔷 Gemini AI Agent" (or similar)
3. **Repository path** - Shows your current directory
4. **Tiled layout** - Panes resize to equal sizes
5. **Prompt or error** - Either AI CLI starts, or you see installation instructions

## Next Steps After Testing

1. ✅ If it works: Install AI CLIs (see AI_AGENTS_GUIDE.md)
2. ❌ If it doesn't work: Report what you see, we'll debug further
3. 📚 Read full guide: `~/.config/tmuxinator/AI_AGENTS_GUIDE.md`

---

**Quick Manual Test (No Keybinding):**

```bash
# Start tmux
tmuxinator start dotfiles

# From any pane, run:
~/.config/tmuxinator/scripts/spawn-ai-agent.sh claude

# Expected: New pane appears with Claude
```

If manual spawning works but keybindings don't, the issue is with tmux config loading.
If manual spawning doesn't work, the issue is with the script itself.
