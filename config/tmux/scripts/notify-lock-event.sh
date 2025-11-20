#!/bin/bash
# Send tmux notifications for lock events

set -euo pipefail

EVENT_TYPE="${1:-}"
TASK_ID="${2:-}"
MESSAGE="${3:-}"

if [ -z "$EVENT_TYPE" ] || [ -z "$TASK_ID" ]; then
    echo "Usage: $0 <EVENT_TYPE> <TASK_ID> [MESSAGE]" >&2
    exit 1
fi

# Only send notification if inside tmux
if [ -z "${TMUX:-}" ]; then
    exit 0
fi

case "$EVENT_TYPE" in
    locked)
        tmux display-message "🔒 Locked: $TASK_ID ${MESSAGE:+- $MESSAGE}"
        ;;
    unlocked)
        tmux display-message "🔓 Unlocked: $TASK_ID ${MESSAGE:+- $MESSAGE}"
        ;;
    stale)
        tmux display-message "⚠️  Stale lock reclaimed: $TASK_ID ${MESSAGE:+- $MESSAGE}"
        ;;
    heartbeat)
        # Silent - too noisy
        # tmux display-message "💓 Heartbeat: $TASK_ID"
        ;;
    error)
        tmux display-message "❌ Error: $TASK_ID ${MESSAGE:+- $MESSAGE}"
        ;;
    *)
        tmux display-message "ℹ️  $TASK_ID: $MESSAGE"
        ;;
esac
