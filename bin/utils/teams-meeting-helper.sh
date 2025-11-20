#!/bin/bash

# Teams Meeting Helper
# Quick reference for Teams meeting shortcuts and controls

set -e  # Exit on error

show_help() {
    echo "📞 Teams Meeting Controls"
    echo "========================"
    echo
    echo "🔧 Updated shortcuts (to avoid conflicts with typing):"
    echo
    echo "   ctrl-cmd-shift-f12     - Full Teams meeting mode"
    echo "                            (workspace M + close others + fullscreen)"
    echo
    echo "   ctrl-alt-f12           - Quick Teams join"
    echo "                            (same as above, easier to press)"
    echo
    echo "   ctrl-cmd-semicolon     - Service mode"
    echo "   then f12               - Teams meeting mode from service menu"
    echo
    echo "📍 Regular workspace access:"
    echo "   ctrl-cmd-m             - Just go to workspace M (no closing/fullscreen)"
    echo
    echo "⚠️  What was changed:"
    echo "   • Removed ctrl-alt-m (was conflicting with typing 'ctrl-m')"
    echo "   • Removed ctrl-cmd-shift-m (was conflicting with typing)"
    echo "   • Now using F12 key to avoid text input conflicts"
    echo
    echo "💡 Pro tip: ctrl-alt-f12 is probably the easiest for quick Teams access!"
}

# Function to check if a Teams meeting window exists in workspace M and fullscreen it
check_and_fullscreen_teams() {
    # Get current workspace
    current_workspace=$(aerospace list-workspaces --focused)
    
    # Check if we're in workspace M and if there's a Teams window there
    if [[ "$current_workspace" == "M" ]]; then
        # Get the focused window app-id
        focused_window=$(aerospace list-windows --workspace M --format "%{app-id}")
        
        # If it's a Teams window, make it fullscreen
        if [[ "$focused_window" == "com.microsoft.teams2" ]]; then
            aerospace fullscreen
        fi
    fi
}

# Handle different modes
case "$1" in
    "--help"|"-h"|"")
        show_help
        ;;
    "--monitor")
        echo "Monitoring workspace M for Teams meetings..."
        while true; do
            check_and_fullscreen_teams
            sleep 2
        done
        ;;
    "--check")
        check_and_fullscreen_teams
        ;;
    *)
        echo "Usage: $0 [--help|--monitor|--check]"
        echo "       $0           Show help (default)"
        echo "       $0 --monitor Monitor and auto-fullscreen Teams"
        echo "       $0 --check   Single check for Teams fullscreen"
        ;;
esac
