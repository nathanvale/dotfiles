#!/usr/bin/env bash
# Test Claude Code plugins without symlink
# This script temporarily removes the ~/.claude symlink to test if
# plugins work correctly with a normal directory.

set -e

DOTFILES_CLAUDE="/Users/nathanvale/code/dotfiles/.claude"
HOME_CLAUDE="/Users/nathanvale/.claude"
BACKUP_LINK="/Users/nathanvale/.claude-symlink-backup"

echo "╭─────────────────────────────────────────────────────────╮"
echo "│  Claude Code Plugin Test (Without Symlink)              │"
echo "╰─────────────────────────────────────────────────────────╯"
echo ""

case "${1:-}" in
  setup)
    echo "📋 Setting up test environment..."

    # Check no Claude processes are running
    if pgrep -f "claude" > /dev/null 2>&1; then
      echo "❌ ERROR: Claude Code is still running!"
      echo "   Please exit all Claude Code sessions first."
      echo "   Run: pkill -f claude"
      exit 1
    fi

    # Check current state
    if [ -L "$HOME_CLAUDE" ]; then
      echo "✓ Found symlink: $HOME_CLAUDE -> $(readlink "$HOME_CLAUDE")"

      # Backup the symlink target
      echo "📦 Backing up symlink..."
      rm "$HOME_CLAUDE"
      echo "$DOTFILES_CLAUDE" > "$BACKUP_LINK"

      # Create real directory
      echo "📁 Creating real ~/.claude directory..."
      mkdir -p "$HOME_CLAUDE"

      # Copy essential files
      echo "📄 Copying essential configuration..."
      cp "$DOTFILES_CLAUDE/settings.json" "$HOME_CLAUDE/" 2>/dev/null || true
      cp "$DOTFILES_CLAUDE/config.json" "$HOME_CLAUDE/" 2>/dev/null || true
      cp "$DOTFILES_CLAUDE/CLAUDE.md" "$HOME_CLAUDE/" 2>/dev/null || true
      cp -r "$DOTFILES_CLAUDE/commands" "$HOME_CLAUDE/" 2>/dev/null || true
      cp -r "$DOTFILES_CLAUDE/skills" "$HOME_CLAUDE/" 2>/dev/null || true
      cp -r "$DOTFILES_CLAUDE/hooks" "$HOME_CLAUDE/" 2>/dev/null || true
      mkdir -p "$HOME_CLAUDE/plugins"

      # Clear plugin state for fresh test
      echo "🧹 Creating clean plugin state..."
      echo '{"version":1,"plugins":{}}' > "$HOME_CLAUDE/plugins/installed_plugins.json"
      echo '{}' > "$HOME_CLAUDE/plugins/known_marketplaces.json"

      # Remove superpowers entries from enabledPlugins for clean test
      if [ -f "$HOME_CLAUDE/settings.json" ]; then
        # Keep settings but remove plugin-specific entries
        cat "$HOME_CLAUDE/settings.json" | \
          sed 's/"superpowers[^"]*":[^,}]*,//g' | \
          sed 's/,}/}/g' > "$HOME_CLAUDE/settings.json.tmp"
        mv "$HOME_CLAUDE/settings.json.tmp" "$HOME_CLAUDE/settings.json"
      fi

      echo ""
      echo "✅ Test environment ready!"
      echo ""
      echo "Now run these steps:"
      echo "  1. Start Claude Code: claude"
      echo "  2. Add marketplace:   /plugin marketplace add obra/superpowers-marketplace"
      echo "  3. Install plugin:    /plugin install superpowers@superpowers-marketplace"
      echo "  4. Restart Claude Code"
      echo "  5. Test if /superpowers:brainstorm works"
      echo ""
      echo "When done testing, run:"
      echo "  $0 restore"

    else
      echo "❌ ~/.claude is not a symlink. Nothing to do."
      exit 1
    fi
    ;;

  restore)
    echo "🔄 Restoring symlink..."

    # Check no Claude processes are running
    if pgrep -f "claude" > /dev/null 2>&1; then
      echo "❌ ERROR: Claude Code is still running!"
      echo "   Please exit all Claude Code sessions first."
      exit 1
    fi

    if [ -f "$BACKUP_LINK" ]; then
      ORIGINAL=$(cat "$BACKUP_LINK")

      # Remove test directory
      if [ -d "$HOME_CLAUDE" ] && [ ! -L "$HOME_CLAUDE" ]; then
        echo "🗑️  Removing test directory..."
        rm -rf "$HOME_CLAUDE"
      fi

      # Restore symlink
      echo "🔗 Restoring symlink to $ORIGINAL..."
      ln -s "$ORIGINAL" "$HOME_CLAUDE"

      # Clean up backup
      rm "$BACKUP_LINK"

      echo ""
      echo "✅ Symlink restored!"
      echo "   ~/.claude -> $ORIGINAL"
    else
      echo "❌ No backup found at $BACKUP_LINK"
      echo "   Cannot restore automatically."
      exit 1
    fi
    ;;

  status)
    echo "📊 Current status:"
    echo ""
    if [ -L "$HOME_CLAUDE" ]; then
      echo "   ~/.claude is a SYMLINK -> $(readlink "$HOME_CLAUDE")"
    elif [ -d "$HOME_CLAUDE" ]; then
      echo "   ~/.claude is a REAL DIRECTORY"
    else
      echo "   ~/.claude does not exist"
    fi

    if [ -f "$BACKUP_LINK" ]; then
      echo "   Backup exists: $(cat "$BACKUP_LINK")"
    fi
    ;;

  *)
    echo "Usage: $0 {setup|restore|status}"
    echo ""
    echo "Commands:"
    echo "  setup   - Remove symlink and create test directory"
    echo "  restore - Restore the original symlink"
    echo "  status  - Show current state"
    exit 1
    ;;
esac
