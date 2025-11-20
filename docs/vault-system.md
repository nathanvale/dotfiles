# 🗂️ Vault System - ADHD-Friendly Repository Management

A streamlined, smart vault system that automatically organizes your code repositories in Obsidian without the mental overhead.

## 🎯 Quick Start

**In Tmux:**
- `Ctrl-g V` → Interactive manager (checkboxes to select repos)
- `Ctrl-g H` → Health check (finds moved repos, fixes problems)
- `Ctrl-g v` → Open current project's vault

**Command Line:**
```bash
vault manage    # Interactive checkbox interface
vault health    # Check and fix all vaults
vault open      # Open current project vault
vault status    # Show registered repos
```

## ✨ How It Works

### Auto-Registration 🤖
- **New tmux sessions automatically register** if they contain `.agent-os` or `docs` folders
- **Manual registration**: Run `vault register` in any project directory
- **No .agent-os folder?** The system creates one automatically

### Smart Tracking 🧠
- Each repo gets a unique `.vault-id` file (auto-gitignored)
- **Rename repos freely** - system finds them by ID
- **Move repos anywhere** - health check reconnects everything
- **Multiple clones?** Git remote URLs provide backup identification

### Health Check 🩺
- Automatically finds moved/renamed repositories
- Fixes broken symlinks
- Updates Obsidian vault connections
- **Run after reorganizing projects**: `vault health`

## 📦 Vault Structure

Your repositories appear in **one unified Obsidian vault**:

```
📖 Obsidian Vaults
├── 📁 Personal (your personal notes)
└── 📁 Repos (all code projects)
    ├── 📁 dotfiles/
    │   ├── 🔗 .agent-os → ~/code/dotfiles/.agent-os
    │   └── 🔗 docs → ~/code/dotfiles/docs
    ├── 📁 my-api/
    │   └── 🔗 docs → ~/code/my-api/docs
    └── 📁 awesome-app/
        └── 🔗 .agent-os → ~/code/awesome-app/.agent-os
```

## 🎮 Interactive Manager

**Checkbox Interface** (`vault manage` or `Ctrl-g V`):
- ✅ Checked = Registered in vault
- ⬜ Unchecked = Not in vault
- **Space** = Toggle selection
- **Enter** = Apply changes
- **Ctrl-A** = Select all

## 🔧 Troubleshooting

### "Repository moved/renamed?"
```bash
vault health
# → Automatically finds and reconnects
```

### "Want to see what's registered?"
```bash
vault status
# → Lists all registered repositories
```

### "Obsidian shows wrong repos?"
```bash
vault health
# → Fixes Obsidian vault connections
```

### "Started new project, want it in vault?"
```bash
cd ~/code/new-project
vault register
# → Or just create a tmux session, it auto-registers
```

## 🧠 ADHD-Friendly Features

### ✅ **Zero Mental Overhead**
- Auto-registration when creating tmux sessions
- Smart health checks fix problems automatically
- Repositories survive any reorganization

### ✅ **Visual Management**
- Checkbox interface for bulk operations
- Clear status indicators
- Simple, memorable tmux bindings

### ✅ **Forgiving System**
- Move/rename repos freely
- Health check fixes everything
- No broken connections

### ✅ **Minimal Commands**
- Only 4 main commands to remember
- Intuitive tmux bindings
- Everything "just works"

## 📁 File Structure

```
bin/
├── vault                        # 🎯 Main script (everything you need)
└── tmux-auto-register-hook.sh   # 🤖 Auto-registration hook

~/.config/vault-manager/
└── registry.json                # 📊 Repository database

~/Documents/ObsidianVaults/
├── Personal/                    # 📝 Your personal vault
└── Repos/                       # 📦 Code repositories vault
```

## 🚀 Advanced Usage

### Custom Search Paths
```bash
export VAULT_SEARCH_PATHS="$HOME/code:$HOME/projects"
```

### Manual Health Check
```bash
vault health
# Runs after moving/renaming multiple repos
```

### Register Specific Directory
```bash
vault register ~/path/to/project
```

## 🔄 Migration from Old System

The old vault scripts have been archived to `bin/archive/vault-old-scripts/`. The new unified system automatically handles existing registrations.

**No action needed** - your existing vaults continue working with the new system.

## 💡 Tips

1. **After reorganizing projects**: Run `vault health`
2. **Weekly maintenance**: `vault health` (optional, system is self-healing)
3. **New team member setup**: Just run `vault manage` once
4. **Forgot what's registered?**: `vault status`

---

**🎯 TL;DR**: Use `Ctrl-g V` for management, `Ctrl-g H` for health checks, and `Ctrl-g v` to open vaults. Everything else happens automatically.