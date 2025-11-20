#!/bin/bash
# Display active lock count in tmux status bar

set -euo pipefail

get_lock_count() {
    # Try to find git root
    local git_root
    git_root=$(git rev-parse --show-toplevel 2>/dev/null || echo "")

    if [ -z "$git_root" ]; then
        echo "0"
        return
    fi

    # Check for taskdock locks
    local lock_dir="$git_root/.git/taskdock-locks"

    if [ ! -d "$lock_dir" ]; then
        echo "0"
        return
    fi

    # Count lock files (directories ending in .lock)
    local count
    count=$(find "$lock_dir" -name "*.lock" -type d 2>/dev/null | wc -l | xargs)
    echo "$count"
}

LOCK_COUNT=$(get_lock_count)

if [ "$LOCK_COUNT" -eq 0 ]; then
    # Green - no active locks
    echo "#[fg=#82aaff,bg=#112630]🔓 $LOCK_COUNT"
elif [ "$LOCK_COUNT" -le 4 ]; then
    # Blue - normal operation
    echo "#[fg=#82aaff,bg=#112630]🔒 $LOCK_COUNT"
else
    # Yellow - high concurrency
    echo "#[fg=#f78c6c,bg=#112630]🔒 $LOCK_COUNT"
fi
