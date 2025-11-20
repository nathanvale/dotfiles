#!/usr/bin/env bash
set -e

# Raycast Extension Installer
# This script opens Raycast store pages for missing extensions
# You'll need to click "Install" on each page

echo "🚀 Opening Raycast Store pages for missing extensions..."
echo "Note: You'll need to click 'Install' on each page that opens"
echo ""

# Missing extensions based on preferences
extensions=(
    "Port Manager (killport)|https://www.raycast.com/lucaschultz/port-manager"
    "Tmux Sessioner|https://www.raycast.com/louishuyng/tmux-sessioner"
    "Cursor Recent Projects|https://www.raycast.com/degouville/cursor-recent-projects"
    "Microsoft Teams|https://www.raycast.com/microsoft/microsoft-teams"
    "Apple Reminders|https://www.raycast.com/raycast/apple-reminders"
    "Arc|https://www.raycast.com/the-browser-company/arc"
    "Messages|https://www.raycast.com/raycast/messages"
)

count=1
total=${#extensions[@]}

for ext in "${extensions[@]}"; do
    name="${ext%%|*}"
    url="${ext#*|}"
    echo "[$count/$total] Opening: $name"
    open "$url"
    sleep 2  # Delay to prevent overwhelming the browser
    ((count++))
done

echo ""
echo "✅ All store pages opened!"
echo "📝 Next steps:"
echo "   1. Click 'Install' on each browser tab"
echo "   2. Raycast will prompt for confirmation"
echo "   3. Choose 'Install Extension' for each"
echo ""
echo "Tip: Store extensions install to:"
echo "   ~/Library/Application Support/com.raycast.macos/extensions/"
