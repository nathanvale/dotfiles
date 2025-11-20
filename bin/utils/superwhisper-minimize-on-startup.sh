#!/bin/bash

# SuperWhisper Auto-Minimize on Startup
# This script waits for SuperWhisper to launch, then minimizes it once
# After that, it stays minimized for all mode switches

# Wait for SuperWhisper to be running
set -e  # Exit on error

echo "Waiting for SuperWhisper to launch..."
while ! pgrep -x "SuperWhisper" > /dev/null; do
    sleep 1
done

echo "SuperWhisper detected, waiting for window..."

# Wait a bit for the window to appear
sleep 2

# Minimize the SuperWhisper window using Cmd+M
echo "Minimizing SuperWhisper window..."
osascript <<'EOF' 2>/dev/null
tell application "System Events"
    tell process "SuperWhisper"
        try
            keystroke "m" using command down
        end try
    end tell
end tell
EOF

echo "SuperWhisper minimized to dock. It will stay minimized for all mode switches."
exit 0
