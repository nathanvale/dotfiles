#!/bin/bash
# Tmux startup script - shows project selector when terminal starts

# If already in tmux, show helpful session info instead
if [ -n "$TMUX" ]; then
    current_session=$(tmux display-message -p '#S')
    echo "📍 Current session: $current_session"
    echo ""
    echo "🚀 Available sessions:"
    tmux list-sessions | nl -w2 -s': '
    echo ""
    echo "💡 Quick actions:"
    echo "  Ctrl+g s    → Switch session"
    echo "  Ctrl+g d    → Detach from tmux"
    echo "  Ctrl+g c    → New window"
    echo "  Ctrl+g ,    → Rename window"
    echo "  txnew       → Create new tmuxinator project"
    echo ""
    exit 0
fi

# Don't run if not in an interactive shell
if [ ! -t 0 ]; then
    exit 0
fi

# Check if any tmux sessions exist
existing_sessions=$(tmux list-sessions 2>/dev/null)

if [ -n "$existing_sessions" ]; then
    # Sessions exist - show them with option to create new
    echo "🚀 Tmux sessions available:"
    echo ""
    echo "$existing_sessions" | nl -w2 -s': '
    echo ""
    echo "Options:"
    echo "  [1-9] Attach to session by number"
    echo "  [n]   Create new session from tmuxinator projects"
    echo "  [s]   Skip and use regular shell"
    echo ""
    read -n1 -t 5 -p "Choose option (auto-skip in 5s): " choice
    echo ""
    
    # Clear any remaining input buffer
    read -t 0.1 -n 100 discard 2>/dev/null || true
    
    # Show hint if skipped
    if [ -z "$choice" ] || [ "$choice" = "s" ] || [ "$choice" = "S" ] || [ "$choice" = "c" ] || [ "$choice" = "C" ]; then
        echo "💡 Tips:"
        echo "  • Type 'tx' anytime to show this menu again"
        echo "  • Type 'tmuxnew' to generate a new project config"
        echo "  • Type 'tcd <project>' to jump to a project directory"
        echo ""
    fi
    
    case "$choice" in
        [1-9])
            # Attach to numbered session
            session_name=$(echo "$existing_sessions" | sed -n "${choice}p" | cut -d: -f1)
            if [ -n "$session_name" ]; then
                exec tmux attach-session -t "$session_name"
            fi
            ;;
        n|N)
            # Show project menu
            exec "$HOME/code/dotfiles/bin/tmux/session-menu.sh"
            ;;
        c|C|s|S|*)
            # Skip - do nothing (c for claude, s for skip, or timeout/other)
            ;;
    esac
else
    # No sessions exist - offer to create one
    echo "🚀 No tmux sessions running. Start a project?"
    echo ""
    echo "  [y] Show tmuxinator projects"
    echo "  [n] Skip and use regular shell"
    echo ""
    read -n1 -t 5 -p "Choose option [y/n] (auto-skip in 5s): " choice
    echo ""
    
    # Clear any remaining input buffer
    read -t 0.1 -n 100 discard 2>/dev/null || true
    
    # Show hint if skipped
    if [ -z "$choice" ] || [ "$choice" = "n" ] || [ "$choice" = "N" ] || [ "$choice" = "c" ] || [ "$choice" = "C" ]; then
        echo "💡 Tips:"
        echo "  • Type 'tx' anytime to show this menu again"
        echo "  • Type 'tmuxnew' to generate a new project config"
        echo "  • Type 'tcd <project>' to jump to a project directory"
        echo ""
    fi
    
    if [ "$choice" = "y" ] || [ "$choice" = "Y" ]; then
        exec "$HOME/code/dotfiles/bin/tmux/session-menu.sh"
    fi
fi