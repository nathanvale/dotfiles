#!/bin/bash

# Emergency script to kill all node/vitest zombie processes
# Run this when your system is overwhelmed with zombies

set -e  # Exit on error

echo "🔍 Finding all node/vitest processes..."

# Count zombies
ZOMBIE_COUNT=$(ps aux | grep -E 'node.*vitest|vitest' | grep -v grep | wc -l | tr -d ' ')

if [ "$ZOMBIE_COUNT" -eq "0" ]; then
    echo "✅ No zombie processes found!"
    exit 0
fi

echo "⚠️  Found $ZOMBIE_COUNT zombie processes"
echo ""
echo "Killing all node/vitest processes..."

# Kill all node processes related to vitest
ps aux | grep -E 'node.*vitest|vitest' | grep -v grep | awk '{print $2}' | while read -r pid; do
    echo "  Killing PID $pid..."
    kill -9 "$pid" 2>/dev/null
done

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "💡 To prevent this in the future, run:"
echo "   pnpm test:safe     # Runs tests with automatic cleanup"
echo "   pnpm zombies:watch # Monitor for zombies in another terminal"
