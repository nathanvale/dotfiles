# AI Agent Spawning Guide

**Dynamically spawn AI agents in any tmux session** - no need to restart your tmuxinator project!

## Quick Reference

### Keyboard Shortcuts

While in **any tmux session**, press:

```
Ctrl-g + A + c    →  Spawn Claude (horizontal split)
Ctrl-g + A + g    →  Spawn Gemini (horizontal split)
Ctrl-g + A + o    →  Spawn OpenAI (horizontal split)
Ctrl-g + A + x    →  Spawn Codex (horizontal split)
Ctrl-g + A + w    →  Create new AI window
Ctrl-g + A + v    →  Spawn Claude (vertical split)
```

**Example workflow:**
1. Start your fullstack project: `tmuxinator start my-webapp`
2. You're in Claude window, working on code
3. Need Gemini for review? Press: `Ctrl-g` then `A` then `g`
4. Gemini pane appears, split horizontally
5. Need OpenAI too? Press: `Ctrl-g` then `A` then `o`
6. Now you have Claude, Gemini, and OpenAI all in one window!

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
claude
```
Your primary AI assistant.

### 2. Gemini 🔷

**Option A: Google Generative AI CLI**
```bash
pip install google-generativeai
export GOOGLE_API_KEY="your-api-key"
gemini
```

**Option B: gcloud AI**
```bash
brew install google-cloud-sdk
gcloud ai models generate-content --model=gemini-pro
```

**Option C: Shell wrapper** (create your own)
```bash
# ~/.local/bin/gemini
#!/bin/bash
python3 -c "import google.generativeai as genai; genai.configure(api_key='$GOOGLE_API_KEY'); ..."
```

### 3. OpenAI 🔶

**Option A: OpenAI Official CLI**
```bash
pip install openai
export OPENAI_API_KEY="your-api-key"
openai
```

**Option B: shell-gpt (Recommended)**
```bash
brew install shell-gpt
export OPENAI_API_KEY="your-api-key"
sgpt  # Interactive mode
```

**Option C: ChatGPT CLI**
```bash
npm install -g @j178/chatgpt
export OPENAI_API_KEY="your-api-key"
chatgpt
```

### 4. Codex 🔷

**Option A: GitHub Copilot CLI**
```bash
npm install -g @githubnext/github-copilot-cli
github-copilot-cli auth
copilot
```

**Option B: OpenAI Codex API**
```bash
# Use OpenAI's Codex models via API
pip install openai
# Create custom script using openai.Completion.create(engine="code-davinci-002")
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

| Keys | Action |
|------|--------|
| `Ctrl-g + A + c` | Spawn Claude |
| `Ctrl-g + A + g` | Spawn Gemini |
| `Ctrl-g + A + o` | Spawn OpenAI |
| `Ctrl-g + A + x` | Spawn Codex |
| `Ctrl-g + A + w` | New AI window |
| `Ctrl-g + A + v` | Spawn Claude (vertical) |
| `Ctrl-g + z` | Zoom/unzoom pane |
| `Ctrl-g + x` | Kill pane |
| `Ctrl-g + o` | Cycle through panes |

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
