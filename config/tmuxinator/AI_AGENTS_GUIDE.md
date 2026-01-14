# AI Agent Spawning Guide

**Multi-agent AI workflows in tmux** - spawn and navigate between AI agents with ease!

## Quick Reference

### Default Setup (All Templates)

All templates (standard, fullstack, nextjs) now start with **4 Claude agents** in a tiled 2x2 grid.

### Accordion Navigation (Ctrl-g + number)

Focus on one agent at a time while keeping others ready:

```
Ctrl-g 1    →  Jump to pane 1 + zoom (accordion mode)
Ctrl-g 2    →  Jump to pane 2 + zoom
Ctrl-g 3    →  Jump to pane 3 + zoom
Ctrl-g 4    →  Jump to pane 4 + zoom
Ctrl-g Space →  Toggle zoom (switch tiled ↔ accordion)
Ctrl-g T    →  Force tiled layout (see all 4)
```

### Dynamic Agent Spawning (Ctrl-g A then letter)

Add more agents on-demand:

```
Ctrl-g A c  →  Spawn Claude (horizontal split)
Ctrl-g A g  →  Spawn Gemini (horizontal split)
Ctrl-g A x  →  Spawn Codex (horizontal split)
Ctrl-g A o  →  Spawn OpenAI (legacy, horizontal)
Ctrl-g A n  →  Create new AI window with Claude
Ctrl-g A v  →  Spawn Claude (vertical split)
```

**Example workflow:**
1. Start your project: `tx ~/code/my-webapp`
2. You have 4 Claude agents in tiled layout
3. Press `Ctrl-g 1` to focus on agent 1 (accordion mode)
4. Press `Ctrl-g Space` to see all 4 again
5. Need Gemini? Press `Ctrl-g A g` to spawn one
6. Now you have 5 agents in tiled layout!

## How It Works

### The Magic: Spawn Script

The `spawn-ai-agent.sh` script:
- ✅ Runs in your current repository directory
- ✅ Each agent has full read access to your codebase
- ✅ Automatically applies tiled layout for equal space
- ✅ Checks if CLI tools are installed
- ✅ Provides helpful setup instructions if missing

### Repository Access

**All spawned agents start in your current project directory:**

```bash
# If you're in /Users/nathanvale/code/my-webapp
# And you spawn Gemini, it starts with:
cd /Users/nathanvale/code/my-webapp
gemini  # Can access all your project files
```

### Auto-Layout

The script automatically uses **tiled layout**, which means:
- 2 panes = side-by-side (50/50)
- 3 panes = one large, two small (grid)
- 4 panes = perfect 2x2 grid
- 5+ panes = evenly distributed grid

## Supported AI Agents

### 1. Claude ✅ (Already Installed)
```bash
claude      # Standard Claude Code
ccdev       # Claude with 25 local plugins (Nathan's alias)
```
Your primary AI assistant. All templates use `ccdev` by default.

### 2. Gemini 🔷

Google's Gemini CLI - free tier: 60 requests/min, 1,000 requests/day.

```bash
# Install globally
npm i -g @google/gemini-cli

# Or run without installing
npx @google/gemini-cli

# Then just run:
gemini
```

Features: 1M token context, Google Search grounding, MCP support.

### 3. Codex 🔶

OpenAI's Codex CLI - requires ChatGPT Plus/Pro/Business/Edu/Enterprise.

```bash
# Install globally
npm i -g @openai/codex

# Then just run:
codex
```

Features: GPT-5-Codex model, code review, web search, approval modes.

### 4. OpenAI (Legacy) 🔶

For shell-gpt or other OpenAI integrations:

```bash
brew install shell-gpt
export OPENAI_API_KEY="your-api-key"
sgpt  # Interactive mode
```

## Advanced Usage

### Manual Spawning

You can also spawn agents manually from the command line:

```bash
# From within a tmux session
~/.config/tmuxinator/scripts/spawn-ai-agent.sh claude
~/.config/tmuxinator/scripts/spawn-ai-agent.sh gemini current vertical
~/.config/tmuxinator/scripts/spawn-ai-agent.sh openai new
```

**Arguments:**
1. `agent_type`: `claude`, `gemini`, `openai`, `codex`
2. `window_name`: `current`, `new`, or specific window name (default: `current`)
3. `split_direction`: `horizontal`, `vertical` (default: `horizontal`)

### Create AI-First Projects

Use the AI project templates when creating new projects:

```bash
# Multi-AI project (Claude + Gemini + Codex + Shell)
~/.config/tmuxinator/scripts/create-project.sh ai-experiment ai ~/code/ai-test

# Dual-AI project (Claude + Gemini side-by-side)
~/.config/tmuxinator/scripts/create-project.sh stimulus-app dual-ai ~/code/stimulus-app
```

### Example: Multi-Agent Code Review

**Scenario:** You want three AI agents to review your code simultaneously.

1. Start your project:
   ```bash
   tmuxinator start my-webapp
   ```

2. Spawn Gemini:
   ```
   Ctrl-g + A + g
   ```

3. Spawn OpenAI:
   ```
   Ctrl-g + A + o
   ```

4. Now you have:
   - **Claude** (top-left): Primary development
   - **Gemini** (top-right): Security review
   - **OpenAI** (bottom): Performance optimization

All three can read your entire repository!

## Configuration Files

### Tmux Key Bindings
`~/.config/tmux/tmux.conf:127-137`
```tmux
# AI Agent Spawning
bind A switch-client -T ai-agents
bind -T ai-agents c run-shell "...spawn-ai-agent.sh claude..."
bind -T ai-agents g run-shell "...spawn-ai-agent.sh gemini..."
# ... etc
```

### Spawn Script
`~/.config/tmuxinator/scripts/spawn-ai-agent.sh`

The script handles:
- Detecting if in tmux session
- Creating splits in current window
- Applying tiled layout
- Running agent CLI with proper setup

## Troubleshooting

### Agent CLI Not Found

If you get "command not found" errors:

**1. Check if installed:**
```bash
which claude  # Should show: /usr/local/bin/claude or similar
which gemini
which openai
```

**2. Check PATH:**
```bash
echo $PATH
# Should include: /usr/local/bin, ~/.local/bin, etc.
```

**3. Install missing CLIs:**
See "Supported AI Agents" section above for installation commands.

### Pane Too Small

If panes become too small with many agents:

**Option 1: Create new window**
```
Ctrl-g + A + w  # Creates dedicated AI agents window
```

**Option 2: Manual layout**
```
Ctrl-g + :     # Enter tmux command mode
select-layout tiled
```

**Option 3: Zoom a pane**
```
Ctrl-g + z     # Toggle zoom on current pane
```

### Agent Not in Correct Directory

If an agent spawns in wrong directory:

**Fix:** The script uses `#{pane_current_path}`, which should preserve your directory. Check if you've `cd`'d recently.

**Workaround:**
```bash
# In the agent pane:
cd /path/to/your/project
```

## Environment Variables

Add to your `~/.zshrc` or `~/.env.secrets`:

```bash
# Google Gemini
export GOOGLE_API_KEY="your-gemini-api-key"

# OpenAI (GPT-4, Codex)
export OPENAI_API_KEY="your-openai-api-key"

# Claude (if using API)
export ANTHROPIC_API_KEY="your-claude-api-key"
```

## Integration with Existing Templates

All tmuxinator templates automatically support dynamic spawning:

### Basic Template
```yaml
# Start with: Claude + Git
# Spawn: Gemini with Ctrl-g + A + g
```

### Standard Template
```yaml
# Start with: Claude + Git + Shell
# Spawn: OpenAI with Ctrl-g + A + o
```

### Fullstack Template
```yaml
# Start with: Claude + Git + Dev + Vault
# Spawn: Gemini + OpenAI for multi-agent review
```

## Real-World Workflows

### Workflow 1: Pair Programming with Multiple AIs

```bash
# Start fullstack project
tmuxinator start my-nextjs-app

# Layout: Claude (primary), Gemini (reviewer), OpenAI (debugger)
Ctrl-g + A + g   # Add Gemini
Ctrl-g + A + o   # Add OpenAI

# Now:
# - Claude: Implement feature
# - Gemini: Review for security
# - OpenAI: Optimize performance
```

### Workflow 2: Rapid Prototyping

```bash
# Start AI project template (pre-configured with 3 agents)
tmuxinator start ai-proto

# Already have: Claude, Gemini, Codex
# All can read your repo
# All in tiled layout
```

### Workflow 3: On-Demand Consultation

```bash
# Working solo in Claude
tmuxinator start my-lib

# Need second opinion?
Ctrl-g + A + g   # Quick Gemini spawn

# Done with consultation?
Ctrl-g + x       # Close pane (standard tmux)
```

## Keyboard Shortcuts Summary

### Accordion Navigation
| Keys | Action |
|------|--------|
| `Ctrl-g 1` | Jump to pane 1 + zoom |
| `Ctrl-g 2` | Jump to pane 2 + zoom |
| `Ctrl-g 3` | Jump to pane 3 + zoom |
| `Ctrl-g 4` | Jump to pane 4 + zoom |
| `Ctrl-g Space` | Toggle zoom (tiled ↔ accordion) |
| `Ctrl-g T` | Force tiled layout |

### Agent Spawning (A-prefix)
| Keys | Action |
|------|--------|
| `Ctrl-g A c` | Spawn Claude |
| `Ctrl-g A g` | Spawn Gemini |
| `Ctrl-g A x` | Spawn Codex |
| `Ctrl-g A o` | Spawn OpenAI (legacy) |
| `Ctrl-g A n` | New AI window |
| `Ctrl-g A v` | Spawn Claude (vertical) |

### General Tmux
| Keys | Action |
|------|--------|
| `Ctrl-g z` | Zoom/unzoom pane |
| `Ctrl-g x` | Kill pane (with confirm) |
| `Ctrl-g o` | Cycle through panes |
| `Alt-1/2/3...` | Switch to window 1/2/3... |

## Next Steps

1. **Install AI CLIs** - See "Supported AI Agents" section
2. **Test spawning** - Press `Ctrl-g + A + c` in any tmux session
3. **Add API keys** - Export environment variables
4. **Try multi-agent** - Spawn multiple agents for code review

---

**Last Updated:** 2025-11-21
**Related Files:**
- `~/.config/tmux/tmux.conf` (key bindings)
- `~/.config/tmuxinator/scripts/spawn-ai-agent.sh` (spawn logic)
- `~/.config/tmuxinator/README.md` (project templates)
